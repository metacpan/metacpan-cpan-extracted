# -*- perl -*-

# Copyright (c) 2009 AdCopy
# Author: Jeff Weisberg
# Created: 2009-Mar-30 10:34 (EDT)
# Function: server side
#
# $Id$

package AC::Yenta::Server;
use AC::Yenta::Debug 'server';
use AC::Yenta::Protocol;
use AC::Yenta::Config;
use AC::Yenta::Kibitz::Status::Server;
use AC::Yenta::Kibitz::Store::Server;
use strict;

our @ISA = 'AC::DC::IO::TCP';

my $HDRSIZE = AC::Yenta::Protocol->header_size();
my $TIMEOUT = 2;

my %HANDLER = (
    yenta_status	=> 'AC::Yenta::Kibitz::Status::Server',
    yenta_get		=> \&AC::Yenta::Kibitz::Store::Server::api_get,
    yenta_distrib	=> \&AC::Yenta::Kibitz::Store::Server::api_distrib,
    yenta_check		=> \&AC::Yenta::Kibitz::Store::Server::api_check,
    http		=> 'AC::Yenta::Stats',
   );

sub new {
    my $class = shift;
    my $fd    = shift;
    my $ip    = shift;

    unless( $AC::Yenta::CONF->check_acl( $ip ) ){
        verbose("rejecting connection from $ip");
        return;
    }

    my $me = $class->SUPER::new( peerip => $ip, info => "tcp yenta server (from: $ip)" );

    $me->init($fd);
    $me->wantread(1);
    $me->timeout_rel($TIMEOUT);
    $me->set_callback('read',    \&read);
    $me->set_callback('timeout', \&timeout);
}

sub timeout {
    my $me = shift;

    debug("connection timed out");
    $me->shut();
}

sub read {
    my $me  = shift;
    my $evt = shift;

    my $yp = AC::Yenta::Protocol->new( secret => conf_value('secret') );
    my($proto, $data, $content) = $yp->read_protocol( $me, $evt );
    return unless $proto;

    # dispatch request
    my $h = $HANDLER{ $proto->{type} };

    unless( $h ){
        verbose("unknown message type: $proto->{type}");
        $me->shut();
        return;
    }

    debug("handling request - $proto->{type}");

    if( ref $h ){
        $h->( $me, $proto, $data, $content );
    }else{
        $h->handler( $me, $proto, $data, $content );
    }
}


1;
