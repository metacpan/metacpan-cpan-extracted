# -*- perl -*-

# Copyright (c) 2010 AdCopy
# Author: Jeff Weisberg
# Created: 2010-Jan-14 14:06 (EST)
# Function: send requests to server
#
# $Id: Client.pm,v 1.1 2010/11/01 18:41:50 jaw Exp $

package AC::MrGamoo::API::Client;
use AC::MrGamoo::Debug 'client';
use AC::MrGamoo::Protocol;
use AC::DC::IO::TCP::Client;
use Socket;
our @ISA = 'AC::DC::IO::TCP::Client';

use strict;

my $TIMEOUT  = 15;

sub new {
    my $class = shift;
    my $addr  = shift;
    my $port  = shift;
    my $info  = shift;
    my $req   = shift;
    my $data  = shift;

    debug("new client type: $req->{type} to $addr:$port");
    my $send = AC::MrGamoo::Protocol->encode_request( $req, $data );
    my $me   = $class->SUPER::new( $addr, $port,
                                 info	 => "client $req->{type} to $addr:$port; $info",
                                 request => $send,
                                );

    return $me;
}

sub start {
    my $me = shift;

    $me->set_callback('timeout',  \&_timeout);
    $me->set_callback('read',     \&_read);
    $me->set_callback('shutdown', \&_shutdown);

    $me->SUPER::start();
    $me->timeout_rel($TIMEOUT);
    $me->write( $me->{request} );

    return $me;
}

sub _timeout {
    my $me = shift;
    $me->shut();
}

sub _shutdown {
    my $me = shift;

    if( $me->{status_ok} ){
        $me->run_callback('on_success', { result => $me->{result} } );
    }else{
        $me->run_callback('on_failure');
    }
}

sub _read {
    my $me  = shift;
    my $evt = shift;

    debug("recvd reply to $me->{info}");

    my($proto, $data, $content) = read_protocol_no_content( $me, $evt );
    return unless $proto;

    # check response
    if( $proto->{is_error} ){
        return $me->_uhoh("rcvd error response");
    }

    $proto->{data} = AC::MrGamoo::Protocol->decode_reply($proto, $data);
    debug("recvd reply to $me->{info} - $proto->{data}{status_code} $proto->{data}{status_message}");

    if( $proto->{data}{status_code} != 200 ){
        return $me->_uh_oh("recvd error reply $proto->{data}{status_code} $proto->{data}{status_message}");
    }

    $me->{result}    = $proto;
    $me->{status_ok} = 1;
    $me->shut();
}

sub _uh_oh {
    my $me  = shift;
    my $msg = shift;

    debug("error $msg");
    $me->run_callback('error', { error => $msg } );
    $me->shut();
}


1;

