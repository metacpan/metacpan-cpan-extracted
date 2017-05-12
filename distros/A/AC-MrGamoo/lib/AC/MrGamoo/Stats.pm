# -*- perl -*-

# Copyright (c) 2009 AdCopy
# Author: Jeff Weisberg
# Created: 2009-Apr-06 13:27 (EDT)
# Function: internal stats monitoring
#
# $Id: Stats.pm,v 1.1 2010/11/01 18:41:45 jaw Exp $

package AC::MrGamoo::Stats;
use AC::MrGamoo::Debug 'stats';
use AC::Import;
use strict;

our @EXPORT = qw(add_idle loadave inc_stat);

my $loadave = 0;
my %STATS;

sub add_idle {
    my $idle  = shift;
    my $total = shift;

    # decaying average
    return unless $total;
    my $load = 1 - $idle / $total;
    $total = 60 if $total > 60;
    my $exp = exp( - $total / 60 );
    $loadave = $loadave * $exp + $load * (1 - $exp);
}

sub loadave {
    return $loadave;
}

sub inc_stat {
    my $stat = shift;

    $STATS{$stat} ++;
}


################################################################

sub http_load {

    return sprintf("loadave:    %0.4f\n\n", loadave());
}

sub http_stats {

    my $res;
    for my $k (sort keys %STATS){
        $res .= sprintf("%-24s%s\n", "$k:", $STATS{$k});
    }

    $res .= "\n";
    return $res;
}

sub http_status {
    return "status: OK\n\n";
}


1;
