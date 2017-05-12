# -*- perl -*-

# Copyright (c) 2009 AdCopy
# Author: Jeff Weisberg
# Created: 2009-Mar-30 10:20 (EDT)
# Function: 
#
# $Id$

package AC::Yenta::Kibitz::Status::Client;
use AC::Yenta::Protocol;
use AC::Yenta::Config;
use AC::Yenta::Debug 'status_client';
use AC::Yenta::IO::TCP::Client;
use AC::Dumper;
use AC::Misc;
use strict;
our @ISA = 'AC::Yenta::IO::TCP::Client';


my $HDRSIZE = AC::Yenta::Protocol->header_size();
my $TIMEOUT = 2;
my $msgid   = $$;

sub new {
    my $class = shift;

    debug('starting kibitz status client');
    my $me = $class->SUPER::new( @_ );
    return unless $me;

    $me->set_callback('timeout',  \&timeout);
    $me->set_callback('read',     \&read);
    $me->set_callback('shutdown', \&shutdown);

    return $me;
}

sub use_addr_port {
    my $class = shift;
    my $addr  = shift;
    my $port  = shift;

    # is addr + port => return
    return ($addr, $port) unless ref $addr;

    # addr is array of nat ip info (ACPIPPort)

    my $down;
    my $public;
    my $private;

    for my $i ( @$addr ){
        # usually, skip unreachable networks
        my $ok = AC::Yenta::NetMon::status_dom( $i->{natdom} );
        next unless defined $ok;	# remote private network

        if( $ok == 200 ){
            if( $i->{natdom} ){
                $private = $i;
            }else{
                $public = $i;
            }
        }else{
            $down = $i;
        }
    }

    my $prefer;
    # make sure we use all networks once in a while
    $prefer ||= $down   unless int rand(20);
    $prefer ||= $public unless int rand(20);
    # prefer private addr if available (cheaper)
    $prefer ||= $private || $public || $down;
    return unless $prefer;

    #print STDERR "using ", inet_itoa($prefer->{ipv4}), "\n";
    return ( inet_itoa($prefer->{ipv4}), ($prefer->{port} || $port) );
}


sub start {
    my $me = shift;

    $me->SUPER::start();

    # build request
    my $yp  = AC::Yenta::Protocol->new();
    my $pb  = AC::Yenta::Kibitz::Status::myself();
    my $hdr = $yp->encode_header(
        type		=> 'yenta_status',
        data_length	=> length($pb),
        content_length	=> 0,
        want_reply	=> 1,
        msgid		=> $msgid++,
       );

    # write request
    $me->write( $hdr . $pb );
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
        AC::Yenta::Kibitz::Status::isdown( $me->{status_peer} );
    }
}

sub read {
    my $me  = shift;
    my $evt = shift;

    #debug("recvd reply");

    my $yp = AC::Yenta::Protocol->new( secret => conf_value('secret') );
    my($proto, $data, $content) = $yp->read_protocol( $me, $evt );
    return unless $proto;

    $me->{status_ok} = 1;
    AC::Yenta::Kibitz::Status::update( $data );
    AC::Yenta::NetMon::update( $me );

    $me->shut();
}


1;
