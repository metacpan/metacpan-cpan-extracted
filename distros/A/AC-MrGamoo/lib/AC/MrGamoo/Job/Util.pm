# -*- perl -*-

# Copyright (c) 2010 AdCopy
# Author: Jeff Weisberg
# Created: 2010-Jan-21 11:57 (EST)
# Function: misc
#
# $Id: Util.pm,v 1.2 2011/01/18 18:02:52 jaw Exp $

package AC::MrGamoo::Job;
use strict;

our %REGISTRY;
our $MAXFILE;
our $MAXLOAD;

sub _find {
    my $me = shift;
    return $me if ref $me;

    my %p = @_;
    my $jobid = $p{jobid};
    $me = $REGISTRY{$jobid};

    return $me;
}

################################################################

sub _send_request {
    my $me     = shift;
    my $server = shift;

    my($addr, $port) = get_peer_addr_from_id( $server );
    unless( $addr ){
        verbose("cannot locate server $server");
        return;
    }

    my $x = AC::MrGamoo::API::Client->new( $addr, $port, @_ );
    return $x;
}

################################################################

# do we have sufficient resources to take on more work?
sub _ok_to_do_more_p {
    my $me = shift;

    my $io = AC::DC::IO->underway();
    return if $io >= $MAXFILE / 2;

    if( loadave() >= $MAXLOAD ){
        return if rand() >= ( 1 - loadave() ) / 5;
    }

    # RSN - check ave/max load of all other servers
    my $MAX = $MAXLOAD * 1000;

    my $servers = get_peer_list();
    for my $s (@$servers){
        next unless $me->{server_info}{$s};
        return if $s->{metric} > $MAX;
    }


    return 1;
}


1;
