# -*- perl -*-

# Copyright (c) 2010 AdCopy
# Author: Jeff Weisberg
# Created: 2010-Jan-25 16:32 (EST)
# Function: m/r client
#
# $Id: Client.pm,v 1.5 2011/01/18 17:19:12 jaw Exp $

package AC::MrGamoo::Client;
use AC::MrGamoo::Submit::Compile;
use AC::MrGamoo::Submit::Request;
use AC::MrGamoo::Debug;
use AC::Daemon;
use AC::Conf;
use AC::Misc;
use AC::MrGamoo::Protocol;
use JSON;
use Sys::Hostname;
use Socket;

require 'AC/protobuf/mrgamoo.pl';
require 'AC/protobuf/mrgamoo_status.pl';
require 'AC/protobuf/std_reply.pl';
use strict;


sub new {
    my $class = shift;
    my $from = shift;	# file | text
    my $src  = shift;
    my $cfg  = shift;

    my $host = hostname();
    my $user = getpwuid($<);
    my $trace = "$user/$$\@$host:" . ($from eq 'file' ? $src : 'text');

    my $me   = bless {
        traceinfo	=> $trace,
    }, $class;
    $me->{fdebug} = $cfg->{debug} ? sub{ print STDERR "@_\n" } : sub {};

    # compile job
    my $mr = AC::MrGamoo::Submit::Compile->new( $from => $src );
    $me->{program} = $mr;

    # merge job %config section with passed in config
    $mr->add_config($cfg);

    return $me;
}

sub get_config_param {
    my $me = shift;

    $me->{program}->get_config_param(@_);
}

sub set_config_param {
    my $me = shift;

    $me->{program}->set_config_param(@_);
}

sub open_console {
    my $me = shift;

    my $fd;
    socket($fd, PF_INET, SOCK_DGRAM, 0);
    bind($fd, sockaddr_in(0, INADDR_ANY));
    my $s = getsockname($fd);
    my($port, $addr) = sockaddr_in($s);

    $me->{console_fd}   = $fd;
    $me->{console_port} = $port;
}

sub run_console {
    my $me = shift;
    my $fd = $me->{console_fd};

    while(1){
        my $buf;
        recv $fd, $buf, 65535, 0;
        my $proto = AC::MrGamoo::Protocol->decode_header($buf);
        my $data  = substr($buf, AC::MrGamoo::Protocol->header_size());
        my $req   = AC::MrGamoo::Protocol->decode_request($proto, $data);
        last if $req->{type} eq 'finish';
        print STDERR "$req->{msg}"                        if $req->{type} eq 'stderr';
        print "$req->{msg}"                               if $req->{type} eq 'stdout';
        $me->{fdebug}->("$req->{server_id}\t$req->{msg}") if $req->{type} eq 'debug';
    }
}

sub submit {
    my $me   = shift;
    my $seed = shift;	# [ "ipaddr:port", ... ]

    my $mr = $me->{program};
    my $r = AC::MrGamoo::Submit::Request->new( $mr );
    $r->{eu_print_stderr} = sub { print STDERR "@_\n" };
    $r->{eu_print_stdout} = sub { print STDERR "@_\n" };

    # run init section
    my $h_init   = $mr->get_code( 'init' );
    my $initres  = ($h_init ? $h_init->{code}() : undef) || {};

    $me->{id} = unique();
    my $req = AC::MrGamoo::Protocol->encode_request( {
        type		=> 'mrgamoo_jobcreate',
        msgidno		=> $^T,
        want_reply	=> 1,
    },{
        jobid		=> $me->{id},
        options		=> to_json( $r->{config} ),
        initres		=> to_json( $initres, {allow_nonref => 1} ),
        jobsrc		=> $mr->src(),
        console		=> ($me->{console_port} ? ":$me->{console_port}" : ''),
        traceinfo	=> $me->{traceinfo},
    } );

    my $ok;
    if( my $master = $me->get_config_param('master') ){
        # use specified master (for debugging)
        my($addr, $port) = split /:/, $master;
        $me->_submit_to( $addr, $port, $req );
        $me->{master} = { addr => $addr, port => $port };
        $ok = 1;
    }else{
        # pick server
        $ok = $me->_pick_master_and_send( $req, $seed );
    }

    return $ok ? $me->{id} : undef;
}

sub abort {
    my $me = shift;

    return unless $me->{master};
    my $res = $me->_submit_to( $me->{master}{addr}, $me->{master}{port}, AC::MrGamoo::Protocol->encode_request( {
        type		=> 'mrgamoo_jobabort',
        msgidno		=> $^T,
        want_reply	=> 1,
    }, {
        jobid		=> $me->{id},
    }));

}

################################################################

sub _pick_master_and_send {
    my $me   = shift;
    my $req  = shift;
    my $seed = shift;

    my @serverlist;

    my $listreq = AC::MrGamoo::Protocol->encode_request( {
        type		=> 'mrgamoo_status',
        msgidno		=> $^T,
        want_reply	=> 1,
    }, {});

    # get the full list of servers
    # contact each seed passed in above, until we get a reply
    for my $s ( @$seed ){
        my($addr, $port) = split /:/, $s;
        $me->{fdebug}->("attempting to fetch server list from $addr:$port");
        eval {
            alarm(1);
            my $reply = AC::MrGamoo::Protocol->send_request( inet_aton($addr), $port, $listreq, $me->{fdebug} );
            my $res   = AC::MrGamoo::Protocol->decode_reply($reply);
            alarm(0);
            my $list = $res->{status};
            @serverlist = @$list if $list && @$list;
        };
        last if @serverlist;
    }

    # sort+filter list
    @serverlist = sort { ($a->{sort_metric} <=> $b->{sort_metric}) || int(rand(3)) - 1 }
      grep { $_->{status} == 200 } @serverlist;

    # try all addresses
    # RSN - sort addresslist in a Peers::pick_best_addr_for_peer() like manner?

    my @addrlist = map { @{$_->{ip}} } @serverlist;

    for my $ip (@addrlist){
        my $addr = inet_itoa($ip->{ipv4});
        my $res;
        eval {
            alarm(30);
            $res = $me->_submit_to( $addr, $ip->{port}, $req );
            alarm(0);
        };
        next unless $res && $res->{status_code} == 200;
        $me->{master} = { addr => $addr, port => $ip->{port} };
        return 1;
    }
    return ;
}

sub _submit_to {
    my $me   = shift;
    my $addr = shift;
    my $port = shift;
    my $req  = shift;

    $me->{fdebug}->("sending job to $addr:$port");
    my $reply = AC::MrGamoo::Protocol->send_request( inet_aton($addr), $port, $req, $me->{fdebug}, 120 );
    my $res   = AC::MrGamoo::Protocol->decode_reply($reply);

    return $res;
}

################################################################

sub check_code {
    my $me = shift;

    my $mr = $me->{program};
    my $nr = @{ $mr->{content}{reduce} };

    $me->_check('map');
    $me->_check('reduce', $_) for (0 .. $nr - 1);
    $me->_check('final');

    return 1;
}

sub _check {
    my $me = shift;
    my $mr = $me->{program};

    my $prog = $mr->compile(@_);
    eval "sub $prog";
    die $@ if $@;
}


1;

