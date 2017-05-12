# -*- perl -*-

# Copyright (c) 2010 AdCopy
# Author: Jeff Weisberg
# Created: 2010-Jan-22 14:29 (EST)
# Function: 
#
# $Id: Client.pm,v 1.1 2010/11/01 18:41:59 jaw Exp $

package AC::MrGamoo::Kibitz::Client;
use AC::MrGamoo::Debug 'kibitz_client';
use AC::MrGamoo::Protocol;
use AC::DC::IO::TCP::Client;
use strict;

require "AC/protobuf/mrgamoo_status.pl";

our @ISA = 'AC::DC::IO::TCP::Client';

my $HDRSIZE = AC::MrGamoo::Protocol->header_size();
my $TIMEOUT = 3;
my $msgid   = $$;

sub new {
    my $class = shift;
    # addr, port, ...

    debug('starting kibitz status client');
    my $me = $class->SUPER::new( @_ );
    return unless $me;

    $me->set_callback('timeout',  \&timeout);
    $me->set_callback('read',     \&read);
    $me->set_callback('shutdown', \&shutdown);

    $me->start();

    # build request
    my $req = AC::MrGamoo::Protocol->encode_request( {
        type            => 'mrgamoo_status',
        content_length  => 0,
        want_reply      => 1,
        msgid           => $msgid++,
    }, {
        myself => AC::MrGamoo::Kibitz->about_myself(),
    } );

    # write request
    $me->write( $req );
    $me->timeout_rel($TIMEOUT);

    return $me;
}

sub timeout {
    my $me = shift;
    $me->shut();
}

sub shutdown {
    my $me = shift;

    if( $me->{status_ok} ){
        AC::MrGamoo::Kibitz::Peers->seems_ok( $me->{status_peer} );
    }else{
        AC::MrGamoo::Kibitz::Peers->maybe_down( $me->{status_peer}, 'timeout' );
    }
}

sub read {
    my $me  = shift;
    my $evt = shift;

    debug("recvd reply");

    my($proto, $data, $content) = read_protocol_no_content( $me, $evt );
    return unless $proto;

    $me->{status_ok} = 1;

    eval {
        my $resp = AC::MrGamoo::Protocol->decode_reply( $proto, $data );
        for my $update ( @{$resp->{status}} ){
            AC::MrGamoo::Kibitz::Peers->update( $update );
        }
    };
    if(my $e = $@){
        verbose("error: $e");
    }
    $me->shut();
}

