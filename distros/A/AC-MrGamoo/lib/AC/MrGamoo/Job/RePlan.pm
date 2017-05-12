# -*- perl -*-

# Copyright (c) 2010 AdCopy
# Author: Jeff Weisberg
# Created: 2010-Jan-21 16:20 (EST)
# Function: 
#
# $Id: RePlan.pm,v 1.1 2010/11/01 18:41:56 jaw Exp $

package AC::MrGamoo::Job;
use strict;

sub _replan {
    my $me     = shift;
    my $server = shift;
    my $x      = shift;
    my $obj    = shift;

    debug("replan $server, $x $obj->{id}");
    if( $x eq 'xfer' ){
        $obj = $me->_replan_xfer_fails_task( $obj );
    }

    return unless $obj;

    $obj->replan($me);
}

sub _replan_server {
    my $me     = shift;
    my $server = shift;
    my $x      = shift;
    my $obj    = shift;

    debug("replan down server $server, $x $obj->{id}");
    my $cpn = $me->{phase_no};
    $cpn ++ if $x eq 'xfer';

    my @replan;
    # replan all tasks on server
    for my $pn ($cpn .. @{$me->{plan}{phases}} - 1){
        for my $t ( @{$me->{plan}{taskplan}[$pn]{task}} ){
            next unless $t->{server} eq $server;
            push @replan, $t;
        }
    }
    for my $t (@replan){
        $t->replan($me);
    }
}

################################################################

sub _replan_xfer_fails_task {
    my $me  = shift;
    my $obj = shift;

    # what task fails bacause of failed xfer?

    my $file = $obj->{dstname} || $obj->{filename};

    for my $task (keys %{$me->{plan}{taskidx}}){
        my $ti = $me->{plan}{taskidx}{$task};
        next unless $obj->{server} eq $ti->{server};

        for my $in ( @{$ti->{infile}} ){
            next unless $in eq $file;

            debug("failed xfer $obj->{id} => fails task $task on $ti->{server}");
            return $ti;
        }
    }
}

1;
