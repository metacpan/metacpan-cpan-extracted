# -*- perl -*-

# Copyright (c) 2009 AdCopy
# Author: Jeff Weisberg
# Created: 2009-Apr-07 11:37 (EDT)
# Function: for other programs to talk to yentad
#
# $Id$

package AC::Yenta::Client;
use AC::Yenta::Conf;
use AC::DC::Protocol;
use AC::Import;
use AC::Misc;
use Sys::Hostname;
use JSON;
use Digest::SHA 'sha1';
use Socket;
use strict;

require 'AC/protobuf/yenta_check.pl';
require 'AC/protobuf/yenta_getset.pl';

our @EXPORT = 'timet_to_yenta_version';	# imported from Y/Conf

my $HOSTNAME = hostname();

my %MSGTYPE =
 (
  yenta_get		=> { num => 7, reqc => 'ACPYentaGetSet',        resc => 'ACPYentaGetSet' },
  yenta_distrib		=> { num => 8, reqc => 'ACPYentaDistRequest',   resc => 'ACPYentaDistReply' },
  yenta_check		=> { num => 9, reqc => 'ACPYentaCheckRequest',  resc => 'ACPYentaCheckReply' },
 );

for my $name (keys %MSGTYPE){
    my $r = $MSGTYPE{$name};
    AC::DC::Protocol->add_msg( $name, $r->{num}, $r->{reqc}, $r->{resc});
}


# one or more of:
#   new( host, port )
#   new( servers => [ { host, port }, ... ] )
#   new( server_file )

sub new {
    my $class = shift;

    my $me = bless {
        debug	=> sub{ },
        host	=> 'localhost',
        proto	=> AC::DC::Protocol->new(),
        copies	=> 1,
        @_,
    }, $class;

    $me->{server_file} ||= $me->{altfile};	# compat

    die "servers or server_file?\n" unless $me->{servers} || $me->{server_file};

    return $me;
}

sub get {
    my $me  = shift;
    my $map = shift;
    my $key = shift;
    my $ver = shift;

    my $req = $me->{proto}->encode_request( {
        type		=> 'yenta_get',
        msgidno		=> rand(0xFFFFFFFF),
        want_reply	=> 1,
    }, {
        data	=> [ {
            map		=> $map,
            key		=> $key,
            version	=> $ver,
        } ]
    } );

    return $me->_send_request($map, $req);
}

sub _shard {
    my $key = shift;

    my $sh = sha1($key);
    my($a, $b) = unpack('NN', $sh);
    return $a<<32 | $b;
}


sub distribute {
    my $me   = shift;
    my $map  = shift;
    my $key  = shift;
    my $ver  = shift;
    my $val  = shift;
    my $file = shift;	# reference
    my $meta = shift;

    return unless $key && $ver;
    $me->{retries} = 25 unless $me->{retries};

    my $req = $me->{proto}->encode_request( {
        type		=> 'yenta_distrib',
        msgidno		=> rand(0xFFFFFFFF),
        want_reply	=> 1,
    }, {
        sender		=> "$HOSTNAME/$$",
        hop		=> 0,
        expire		=> time() + 120,
        datum	=> [ {
            map		=> $map,
            key		=> $key,
            version	=> $ver,
            shard	=> _shard($key),	# NYI
            value	=> $val,
            meta	=> $meta,
        } ]
    }, $file );

    return $me->_send_request($map, $req, $file);
    # return undef | result
}

sub check {
    my $me  = shift;
    my $map = shift;
    my $ver = shift;
    my $lev = shift;

    my $req = $me->{proto}->encode_request( {
        type		=> 'yenta_check',
        msgidno		=> rand(0xFFFFFFFF),
        want_reply	=> 1,
    }, {
        map		=> $map,
        level		=> $lev,
        version		=> $ver,
    } );

    return $me->_send_request($map, $req);
}

################################################################

sub _send_request {
    my $me   = shift;
    my $map  = shift;
    my $req  = shift;
    my $file = shift;	# reference

    my $tries = $me->{retries} + 1;
    my $copy  = $me->{copies} || 1;
    my $delay = 0.25;

    $me->_init_hostlist($map);
    my ($addr, $port) = $me->_next_host($map);

    for (1 .. $tries){
        return unless $addr;
        my $res = $me->_try_server($addr, $port, $req, $file);
        return $res if $res && !--$copy;
        ($addr, $port) = $me->_next_host($map);
        sleep $delay;
        $delay *= 1.414;
    }
}

sub _try_server {
    my $me   = shift;
    my $addr = shift;
    my $port = shift;
    my $req  = shift;
    my $file = shift;	# reference

    my $ipn = inet_aton($addr);
    $req .= $$file if $file;

    $me->{debug}->("trying to contact yenta server $addr:$port");
    my $res;
    eval {
        $res = $me->{proto}->send_request($ipn, $port, $req, $me->{debug}, $me->{timeout});
        $res->{data} = $me->{proto}->decode_reply( $res ) if $res;
    };
    if(my $e = $@){
        $me->{debug}->("yenta request failed: $e");
        $res = undef;
    }
    return $res;
}


################################################################

sub _next_host {
    my $me  = shift;
    my $map = shift;

    $me->_read_serverfile($map) unless $me->{_server};
    return unless $me->{_server} && @{$me->{_server}};
    my $next = shift @{$me->{_server}};
    return( $next->{addr}, $next->{port} );
}

sub _init_hostlist {
    my $me  = shift;
    my $map = shift;

    my @server;
    push @server, {
        addr	=> $me->{host},
        port	=> $me->{port},
    } if $me->{host} && $me->{port};

    push @server, @{$me->{servers}} if $me->{servers};
    $me->{_server} = \@server;

    $me->_read_serverfile($map);
}

# yentad saves a list of alternate peers to try in case it dies
sub _read_serverfile {
    my $me  = shift;
    my $map = shift;

    my $f;
    my @server;
    my @faraway;
    open($f, $me->{server_file});
    local $/ = "\n";
    while(<$f>){
        chop;
        my $data = decode_json( $_ );
        next unless grep { $_ eq $map } @{ $data->{map} };
        if( $data->{is_local} ){
            push @server, { addr => $data->{addr}, port => $data->{port} };
        }else{
            push @faraway, { addr => $data->{addr}, port => $data->{port} };
        }
    }

    # prefer local
    @server = @faraway unless @server;

    shuffle( \@server );
    push @{$me->{_server}}, @server;
}

################################################################

1;
