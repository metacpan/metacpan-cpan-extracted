# -*- perl -*-

# Copyright (c) 2010 AdCopy
# Author: Jeff Weisberg
# Created: 2010-Jan-14 17:13 (EST)
# Function: translate + filter peers
#
# $Id: PeerList.pm,v 1.1 2010/11/01 18:41:43 jaw Exp $

package AC::MrGamoo::PeerList;
use AC::MrGamoo::Kibitz::Peers;
use AC::Import;

use strict;

our @EXPORT = qw(get_peer_list get_peer_addr_from_id get_peer_status_from_id);

# return an array of:
#   {
#     id     => mrgamoo@a2be021ad31c
#     metric => 2
#   }

sub get_peer_list {

    my $s = peer_list_all();

    return [ map {
        {
            id		=> $_->{server_id},
            metric	=> $_->{sort_metric},
        }
    } grep { $_->{status} == 200 } @$s ];
}

sub get_peer_addr_from_id {
    my $id = shift;

    my $s  = get_peer_by_id($id);
    return unless $id;
    return pick_best_addr_for_peer( $s->{ip} );
}

sub get_peer_status_from_id {
    my $id = shift;

    my $s  = get_peer_by_id($id);
    return unless $id;
    return $s->{status};
}



1;
