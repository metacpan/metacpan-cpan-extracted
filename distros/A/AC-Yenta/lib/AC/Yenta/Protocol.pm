# -*- perl -*-

# Copyright (c) 2009 AdCopy
# Author: Jeff Weisberg
# Created: 2009-Mar-30 13:22 (EDT)
# Function: read protocol data
#
# $Id$

package AC::Yenta::Protocol;
use AC::Yenta::Debug 'protocol';
use AC::Yenta::Config;
use AC::DC::Protocol;
use AC::Yenta::MySelf;
use AC::Yenta::Crypto;
use AC::Misc;
use AC::Import;
use strict;

require 'AC/protobuf/heartbeat.pl';
require 'AC/protobuf/auth.pl';
require 'AC/protobuf/std_reply.pl';
require 'AC/protobuf/yenta_status.pl';
require 'AC/protobuf/yenta_check.pl';
require 'AC/protobuf/yenta_getset.pl';


our @ISA    = 'AC::DC::Protocol';
our @EXPORT = qw(read_protocol use_encryption);
my $HDRSIZE = __PACKAGE__->header_size();

my %MSGTYPE =
 (
  heartbeat_request	=> { num => 2, reqc => '', 			resc => 'ACPHeartBeat' },

  yenta_status		=> { num => 6, reqc => 'ACPYentaStatusRequest', resc => 'ACPYentaStatusReply' },
  yenta_get		=> { num => 7, reqc => 'ACPYentaGetSet',        resc => 'ACPYentaGetSet' },
  yenta_distrib		=> { num => 8, reqc => 'ACPYentaDistRequest',   resc => 'ACPYentaDistReply' },
  yenta_check		=> { num => 9, reqc => 'ACPYentaCheckRequest',  resc => 'ACPYentaCheckReply' },
 );


for my $name (keys %MSGTYPE){
    my $r = $MSGTYPE{$name};
    __PACKAGE__->add_msg( $name, $r->{num}, $r->{reqc}, $r->{resc});
}


sub read_protocol {
    my $me  = shift;
    my $io  = shift;
    my $evt = shift;

    $io->{rbuffer} .= $evt->{data};

    return _read_http($io, $evt) if $io->{rbuffer} =~ /^GET/;

    if( length($io->{rbuffer}) >= $HDRSIZE && !$io->{proto_header} ){
        # decode header
        eval {
            $io->{proto_header} = $me->decode_header( $io->{rbuffer} );
        };
        if(my $e=$@){
            verbose("cannot decode protocol header: $e");
            $io->run_callback('error', {
                cause	=> 'read',
                error	=> "cannot decode protocol: $e",
            });
            $io->shut();
            return;
        }
    }

    my $p = $io->{proto_header};
    return unless $p; 	# read more

    # do we have everything?
    return unless length($io->{rbuffer}) >= ($p->{auth_length} + $p->{data_length} + $p->{content_length} + $HDRSIZE);

    my $auth    = substr($io->{rbuffer}, $HDRSIZE,  $p->{auth_length});
    my $data    = substr($io->{rbuffer}, $HDRSIZE + $p->{auth_length},  $p->{data_length});
    my $content = substr($io->{rbuffer}, $HDRSIZE + $p->{auth_length} + $p->{data_length}, $p->{content_length});

    # RSN - validate auth

    if( $p->{data_encrypted} && $data ){
        $data = $me->_decrypt_data( $io, $auth, $data );
        return unless $data;
    }

    if( $p->{content_encrypted} && $content ){
        $content = $me->_decrypt_data( $io, $auth, $content );
        return unless $content;
    }

    # content is passed as reference
    return ($p, $data, ($content ? \$content : undef));
}

# for simple status queries, argus, debugging
# this is not an RFC compliant http server
sub _read_http {
    my $io  = shift;
    my $evt = shift;

    return unless $io->{rbuffer} =~ /\r?\n\r?\n/s;
    my($get, $url, $http) = split /\s+/, $io->{rbuffer};

    return ( { type => 'http', method => $get }, $url );
}

################################################################

sub _decrypt_data {
    my $me   = shift;
    my $io   = shift;
    my $auth = shift;
    my $data = shift;

    eval {
        $data = $me->decrypt( $auth, $data );
    };
    if(my $e=$@){
        verbose("cannot decrypt protocol data: $e");
        $io->run_callback('error', {
            cause	=> 'read',
            error	=> "cannot decrypt protocol: $e",
        });
        $io->shut();
        return;
    }

    return $data;
}

sub use_encryption {
    my $peer = shift;

    return unless conf_value('secret');
    # only encrypt far-away traffic, not local
    return $peer->{datacenter} ne my_datacenter();
}

sub encrypt {
    my $me    = shift;
    my $auth  = shift;	# not currently used
    my $buf   = shift;

    my $secret = $me->{secret};
    return $buf unless $secret;
    return unless $buf;
    my $crypto = AC::Yenta::Crypto->new( $secret );
    return $crypto->encrypt( $buf );
}

sub decrypt {
    my $me    = shift;
    my $abuf  = shift;	# not currently used
    my $buf   = shift;

    my $secret = $me->{secret};
    return $buf unless $secret;
    return unless $buf;
    my $crypto = AC::Yenta::Crypto->new( $secret );
    return $crypto->decrypt( $buf );
}

1;
