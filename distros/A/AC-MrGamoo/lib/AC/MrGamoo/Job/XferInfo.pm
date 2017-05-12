# -*- perl -*-

# Copyright (c) 2010 AdCopy
# Author: Jeff Weisberg
# Created: 2010-Apr-22 12:02 (EDT)
# Function: info about xfers
#
# $Id: XferInfo.pm,v 1.1 2010/11/01 18:41:58 jaw Exp $

package AC::MrGamoo::Job::XferInfo;
use AC::MrGamoo::Debug 'job_xferinfo';
use AC::MrGamoo::PeerList;
use strict;

our @ISA = 'AC::MrGamoo::Job::Info';

my $MAXRETRY = 1;

# id, filename, dstname, size, location, dst
sub new {
    my $class = shift;
    my $job   = shift;

    my $me = bless { @_ }, $class;
    $me->{server} = $me->{dst};

    return $me;
}

sub pend {
    my $me  = shift;
    my $job = shift;

    # create instances, put on pending queue
    my $x = AC::MrGamoo::Job::Xfer->new($job, $me, $me->{dst});
    return unless $x;
    $me->{instance}{ $x->{id} } = $x;

    return;
}

sub failed {
    my $me   = shift;
    my $x    = shift;
    my $job  = shift;

    delete $me->{instance}{ $x->{id} };

    # retry? replan? abort?

    my $server = $me->{dst};
    my $status = get_peer_status_from_id($server);
    my $loc    = $job->{file_info}{$me->{filename}}{location} || $me->{location};

    verbose("xfer failed $me->{id} $server ($status) $me->{filename} @$loc");

    my $skip = $job->{options}{skipmissinginputfiles};	# QQQ
    if( $job->{phase_no} == -1 && $skip ){
        # ignore
        return;
    }

    if( $status != 200 ){
        # replan tasks
        $job->_replan_server($server, 'xfer', $me);
        return;
    }

    if( $me->{retries} ++ > $MAXRETRY ){
        # replan tasks
        $job->_replan($server, 'xfer', $me);
        return;
    }

    # retry
    debug("retry xfer");
    $me->pend($job);
}

sub finished {
    my $me   = shift;
    my $x    = shift;
    my $job  = shift;

    delete $me->{instance}{ $x->{id} };
    $me->{finished} = 1;
}

1;
