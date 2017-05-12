# -*- perl -*-

# Copyright (c) 2013
# Author: Jeff Weisberg <jaw @ solvemedia.com>
# Created: 2013-Mar-19 11:39 (EDT)
# Function: keep track of each network's status
#
# $Id$


package AC::Yenta::NetMon;
use AC::Yenta::MySelf;
use Socket;

use strict;

my $STALE	= 120;

my %lastok;	# natdom => T
my %natdom;	# ip => natdom


sub init {

    my $natinfo = my_network_info();
    for my $n ( @$natinfo ){
        my $dom = $n->{natdom} || 'public';
        $natdom{ $n->{ipa} } = $dom;
        $lastok{ $dom } = $^T;	# assume everything is working
    }
}

sub update {
    my $io = shift;

    my $ip  = inet_ntoa( (sockaddr_in(getsockname($io->{fd})))[1] );
    my $dom = $natdom{ $ip } || 'public';

    $lastok{$dom} = $^T;
}

sub status_dom {
    my $dom = shift;

    $dom ||= 'public';
    return unless exists $lastok{$dom};	# not local
    return ($lastok{$dom || 'public'} + $STALE < $^T) ? 0 : 200;
}


1;
