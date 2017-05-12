# -*- perl -*-

# Copyright (c) 2009 AdCopy
# Author: Jeff Weisberg
# Created: 2009-May-12 11:06 (EDT)
# Function: 
#
# $Id$

package AC::Yenta::Monitor::Client;
use AC::Yenta::Protocol;
use AC::Yenta::Config;
use AC::Yenta::Debug 'monitor_client';
use AC::Yenta::IO::TCP::Client;
use strict;
our @ISA = 'AC::Yenta::IO::TCP::Client';


my $HDRSIZE = AC::Yenta::Protocol->header_size();
my $TIMEOUT = 2;
my $msgid   = $$;

sub new {
    my $class = shift;

    debug('starting monitor status client');
    my $me = $class->SUPER::new( @_ );
    unless($me){
        return;
    }

    $me->set_callback('timeout',  \&timeout);
    $me->set_callback('read',     \&read);
    $me->set_callback('shutdown', \&shutdown);

    $me->start();

    # build request
    my $yp  = AC::Yenta::Protocol->new( secret => conf_value('secret') );
    my $hdr = $yp->encode_header(
        type		=> 'heartbeat_request',
        data_length	=> 0,
        content_length	=> 0,
        want_reply	=> 1,
        msgid		=> $msgid++,
       );

    # write request
    $me->write( $hdr );

    $me->timeout_rel($TIMEOUT);

    return $me;
}

sub timeout {
    my $me = shift;
    $me->shut();
}

sub shutdown {
    my $me = shift;

    unless( $me->{status_ok} ){
        AC::Yenta::Monitor::isdown( $me->{monitor_peer} );
    }
}

sub read {
    my $me  = shift;
    my $evt = shift;

    debug("recvd reply");

    my $yp = AC::Yenta::Protocol->new();
    my($proto, $data, $content) = $yp->read_protocol( $me, $evt );
    return unless $proto;

    $me->{status_ok} = 1;
    AC::Yenta::Monitor::update( $me->{monitor_peer}, $data );

    $me->shut();
}


1;
