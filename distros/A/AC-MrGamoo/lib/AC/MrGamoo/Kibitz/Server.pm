# -*- perl -*-

# Copyright (c) 2010 AdCopy
# Author: Jeff Weisberg
# Created: 2010-Jan-22 14:20 (EST)
# Function: 
#
# $Id: Server.pm,v 1.1 2010/11/01 18:41:59 jaw Exp $

package AC::MrGamoo::Kibitz::Server;
use AC::MrGamoo::Debug 'kibitz_server';
use AC::MrGamoo::Protocol;
use strict;

require "AC/protobuf/mrgamoo_status.pl";

sub handler {
    my $class   = shift;
    my $io      = shift;
    my $proto   = shift;
    my $req     = shift;
    my $content = shift;

    debug("recvd request");
    if( $req ){
        AC::MrGamoo::Kibitz::Peers->update_sceptical( $req->{myself} );
    }

    unless( $proto->{want_reply} ){
        $io->shut();
        return;
    }

    # respond with all known peers
    my $all  = AC::MrGamoo::Kibitz::Peers->peer_list_all();
    my $resp = AC::MrGamoo::Protocol->encode_reply( $proto, {
        status => $all,
    } );

    debug("sending status reply");
    $io->write_and_shut( $resp );
}

1;
