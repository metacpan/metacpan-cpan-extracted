# -*- perl -*-

# Copyright (c) 2010 AdCopy
# Author: Jeff Weisberg
# Created: 2010-Apr-22 11:12 (EDT)
# Function: remote tasks
#
# $Id: Task.pm,v 1.2 2011/01/14 22:38:06 jaw Exp $

package AC::MrGamoo::Job::Task;
use AC::MrGamoo::Debug 'job_task';
use AC::MrGamoo::Config;
use AC::MrGamoo::MySelf;
use AC::Misc;
use Time::HiRes 'time';
use strict;

our @ISA = 'AC::MrGamoo::Job::Action';


sub new {
    my $class  = shift;
    my $job    = shift;
    my $info   = shift;
    my $server = shift;

    my $id = unique();

    my $me = bless {
        id	=> $id,
        info	=> $info,
        server	=> $server,
        created => time(),
    };

    $job->{task_pending}{$id} = $me;

    debug("  => pending task $info->{id} => $id on $server");

    return $me;
}

sub start {
    my $me  = shift;
    my $job = shift;

    my $server = $me->{server};
    debug("starting task $job->{request}{jobid}/$me->{info}{id}/$me->{id} on $server");

    # send request to server
    my $ti = $me->{info};

    my $x = $job->_send_request( $server, "task $me->{id}", {
        type		=> 'mrgamoo_taskcreate',
        msgidno		=> $^T,
        want_reply	=> 1,
    }, {
        jobid		=> $job->{request}{jobid},
        taskid		=> $me->{id},
        jobsrc		=> $job->{request}{jobsrc},
        options		=> $job->{request}{options},
        initres		=> $job->{request}{initres},
        console		=> ($job->{request}{console} || ''),
        phase		=> $ti->{phase},
        infile		=> $ti->{infile},
        outfile		=> [ map { $_->{filename} } @{$ti->{outfile}} ],
        master		=> my_server_id(),
    } );

    unless( $x ){
        verbose("cannot start task");
        $me->failed($job);
        return;
    }

    # no success cb here. we will either timeout, or get a TaskStatus msg.
    $x->set_callback('on_failure', \&_cb_start_task_fail, $me, $job );

    $me->started($job, 'task');
    $x->start();
}

sub _cb_start_task_fail {
    my $io  = shift;
    my $evt = shift;
    my $me  = shift;
    my $job = shift;

    $me->failed($job, 'network');
}

sub update_status {
    my $me  = shift;
    my $job = shift;
    my $phase = shift;
    my $progress = shift;

    $me->{status_time}  = $^T;
    $me->{status_phase} = $phase;
    $me->{status_amt}   = $progress;
    $me->{status_fail}  = 1 if $phase eq 'FAILED';

    debug("task is $phase $progress");

    if( $phase eq 'FINISHED' ){
        if( $me->{status_fail} ){
            $me->failed( $job, "status fail" );
        }else{
            $me->finished( $job );
        }
    }

    return 1;
}

sub failed {
    my $me   = shift;
    my $job  = shift;
    my $why  = shift;

    debug("task failed: $why $me->{status_time}");

    return if $job->something_failed();
    $me->SUPER::failed($job, 'task');
    $me->{info}->failed( $me, $job );
    if( $why eq 'timeout' ){
        $me->abort($job)
    }else{
        # $job->_try_to_do_something();
    }
}

sub finished {
    my $me   = shift;
    my $job  = shift;
    my $why  = shift;

    debug('task finish');

    $me->SUPER::finished($job, 'task');
    $me->{info}->finished( $me, $job );

    $job->_try_to_do_something();
}

sub abort {
    my $me  = shift;
    my $job = shift;

    debug("aborting task $me->{id}");

    AC::MrGamoo::Job::Request->new( $job,
        id	=> unique(),
        server	=> $me->{server},
        info	=> "abort task $me->{id}",
        proto	=> {
            type		=> 'mrgamoo_taskabort',
            msgidno		=> $^T,
            want_reply		=> 1,
        },
        request	=> {
            jobid		=> $job->{request}{jobid},
            taskid		=> $me->{id},
        },
    );

    delete $job->{"task_running"}{$me->{id}};
    delete $job->{server_info}{$me->{server}}{"task_running"}{$me->{id}};
}



1;
