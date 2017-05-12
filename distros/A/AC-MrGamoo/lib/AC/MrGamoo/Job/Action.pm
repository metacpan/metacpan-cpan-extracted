# -*- perl -*-

# Copyright (c) 2010 AdCopy
# Author: Jeff Weisberg
# Created: 2010-Apr-22 12:05 (EDT)
# Function: bookkeeping for xfers + tasks
#
# $Id: Action.pm,v 1.1 2010/11/01 18:41:55 jaw Exp $

package AC::MrGamoo::Job::Action;
use AC::MrGamoo::Debug 'job_action';
use AC::MrGamoo::Job::Task;
use AC::MrGamoo::Job::Xfer;
use AC::MrGamoo::Job::Request;
use Time::HiRes 'time';
use strict;


sub started {
    my $me  = shift;
    my $job = shift;
    my $x   = shift;

    my $server = $me->{server};
    my $id = $me->{id};
    $me->{start_time} = time();

    # remove from _pending
    # add to _running
    # add to server_info._running

    debug("$x started $id on $server");
    delete $job->{"${x}_pending"}{$id};
    $job->{"${x}_running"}{$id} = $me;
    $job->{server_info}{$server}{"${x}_running"}{$id} = $me;
}

sub finished {
    my $me  = shift;
    my $job = shift;
    my $x   = shift;

    my $server = $me->{server};
    my $id = $me->{id};

    $me->{finished} = 1;

    # remove from _running
    # remove from server_info._running
    # add to server_info._finished
    # record timing info

    my $started = $me->{start_time};
    $job->{statistics}{"${x}_run_time"} += time() - $started;
    $job->{statistics}{"${x}_run"} ++;

    debug("$x finished $id on $server");
    delete $job->{"${x}_running"}{$id};
    delete $job->{server_info}{$server}{"${x}_running"}{$id};
    $me->{server_info}{$server}{"${x}_finished"}{$id} = 1;
}

sub failed {
    my $me  = shift;
    my $job = shift;
    my $x   = shift;

    my $server = $me->{server};
    my $id = $me->{id};

    delete $job->{"${x}_running"}{$id};
    delete $job->{server_info}{$server}{"${x}_running"}{$id};

}


1;
