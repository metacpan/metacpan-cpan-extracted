#!/usr/local/bin/perl
# -*- perl -*-

# Copyright (c) 2010 AdCopy
# Author: Jeff Weisberg
# Created: 2010-Jan-07 17:20 (EST)
# Function: 
#
# $Id: Xfer.pm,v 1.1 2010/11/01 18:41:53 jaw Exp $

package AC::MrGamoo::API::Xfer;
use AC::MrGamoo::Debug 'api_xfer';
use AC::MrGamoo::Config;
use AC::MrGamoo::Protocol;
use AC::MrGamoo::PeerList;

use AC::MrGamoo::API::Simple;

use strict;

my $MSGID = $$;

sub handler {
    my $class   = shift;
    my $io      = shift;
    my $proto   = shift;
    my $req     = shift;
    my $content = shift;

    # validate filename
    if( $req->{filename} =~ m%/\.|^\.% ){
        reply( 500, 'Error', $io, $proto, $req );
        return;
    }

    # new retry
    debug("starting file xfer $req->{copyid} => $req->{filename}");

    # start working on the copy
    my $x = AC::MrGamoo::Retry->new(
        newobj	=> \&_mk_xfer,
        newargs => [ $req ],
        tryeach	=> $req->{location},
       );

    # reply now
    if( $x ){
        reply( 200, 'OK', $io, $proto, $req );
    }else{
        debug("sending error, xfer/retrier failed, $io->{info}");
        reply( 501, 'Error', $io, $proto, $req );
    }

    # send status when finished
    $x->set_callback('on_success', \&_yippee, $proto, $req);
    $x->set_callback('on_failure', \&_boohoo, $proto, $req);

    # start
    $x->start();
}

sub _mk_xfer {
    my $loc  = shift;
    my $req  = shift;

    my $x = AC::MrGamoo::Xfer->new(
        $req->{filename}, ($req->{dstname} || $req->{filename}), $loc, $req,
       );

    return $x;
}

################################################################

sub _yippee {
    my $x  = shift;
    my $e  = shift;
    my $proto = shift;
    my $req   = shift;

    tell_master( $req, 200, 'OK' );
}

sub _boohoo {
    my $x  = shift;
    my $e  = shift;
    my $proto = shift;
    my $req   = shift;

    debug("boohoo - xfer failed $req->{copyid}");
    tell_master( $req, 500, 'Failed' );
}

sub tell_master {
    my $req   = shift;
    my $code  = shift;
    my $msg   = shift;

    my($addr, $port) = get_peer_addr_from_id( $req->{master} );
    debug("sending xfer status update for $req->{copyid} => $code => $req->{master}");
    debug("cannot find addr") unless $addr;
    return unless $addr;

    my $x = AC::MrGamoo::API::Client->new( $addr, $port, "xfer $req->{copyid}", {
        type		=> 'mrgamoo_xferstatus',
        msgidno		=> $MSGID++,
        want_reply	=> 1,
    }, {
        jobid		=> $req->{jobid},
        copyid		=> $req->{copyid},
        status_code	=> $code,
        status_message	=> $msg,
    } );

    debug("cannot create client") unless $x;
    return unless $x;
    $x->start();

    # we don't need any reply or reply callbacks. just send + forget
}


################################################################

1;
