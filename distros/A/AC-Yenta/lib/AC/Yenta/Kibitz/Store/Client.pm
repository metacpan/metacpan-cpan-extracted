# -*- perl -*-

# Copyright (c) 2009 AdCopy
# Author: Jeff Weisberg
# Created: 2009-Apr-01 16:31 (EDT)
# Function: client side interface for storage subsystem
#
# $Id$

package AC::Yenta::Kibitz::Store::Client;
use AC::Yenta::Debug 'store_client';
use AC::Yenta::Config;
use AC::Yenta::Protocol;
use AC::Yenta::IO::TCP::Client;
require 'AC/protobuf/yenta_getset.pl';
require 'AC/protobuf/yenta_check.pl';
use strict;

our @ISA = 'AC::Yenta::IO::TCP::Client';

my $TIMEOUT = 5;

sub new {
    my $class = shift;
    my $addr  = shift;
    my $port  = shift;
    my $req   = shift;

    debug('starting kibitz store client');
    my $me = $class->SUPER::new( $addr, $port, info => "kibitz store client $addr:$port", @_ );
    return unless $me;

    $me->{_req} = $req;
    $me->set_callback('timeout',  \&timeout);
    $me->set_callback('read',     \&read);
    $me->set_callback('shutdown', \&shutdown);

    return $me;
}

sub start {
    my $me = shift;

    $me->SUPER::start();
    $me->write( $me->{_req} );
    $me->timeout_rel($TIMEOUT);
    return $me;
}

sub shutdown {
    my $me = shift;

    # maybe call error handler
    $me->run_callback('error', undef) unless $me->{_store_ok};
}

sub timeout {
    my $me = shift;

    $me->shut();
}

sub read {
    my $me  = shift;
    my $evt = shift;

    debug("recvd reply");

    my $yp = AC::Yenta::Protocol->new( secret => conf_value('secret') );
    my($proto, $data, $content) = $yp->read_protocol( $me, $evt );
    $me->timeout_rel($TIMEOUT) if $evt->{data} && !$proto;
    return unless $proto;
    $proto->{data}    = $data;
    $proto->{content} = $content;
    eval {
        my $yp = AC::Yenta::Protocol->new();
        $proto->{data} = $yp->decode_reply($proto) if $data;
    };
    if(my $e = $@){
        problem("cannot decode reply: $e");
    }

    # process
    $me->{_store_ok} = 1;
    if( $proto->{is_error} || $@ ){
        my $e = $@ || 'remote error';
        $me->run_callback('error', {
            error	=> $e,
        });
    }else{
        $me->run_callback('load', $proto);
    }

    $me->shut();
}


1;

