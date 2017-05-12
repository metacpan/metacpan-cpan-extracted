# -*- perl -*-

# Copyright (c) 2010 AdCopy
# Author: Jeff Weisberg
# Created: 2010-Jan-13 13:03 (EST)
# Function: m/r jobs we are controlling
#
# $Id: Job.pm,v 1.6 2011/01/18 18:00:23 jaw Exp $

package AC::MrGamoo::Job;
use AC::MrGamoo::Debug 'job';
use AC::MrGamoo::Config;
use AC::MrGamoo::Job::Plan;
use AC::MrGamoo::Job::RePlan;
use AC::MrGamoo::Job::Util;
use AC::MrGamoo::Job::Done;
use AC::MrGamoo::Job::Info;
use AC::MrGamoo::Job::Action;
use AC::MrGamoo::FileList;
use AC::MrGamoo::PeerList;
use AC::MrGamoo::MySelf;
use AC::MrGamoo::EUConsole;
use AC::MrGamoo::Stats;
use AC::DC::IO;
use AC::Misc;
use JSON;
use Time::HiRes 'time';
use strict;

# RSN - config? tune?
our $TASKTIMEOUT = 10;
our $XFERTIMEOUT = 10;
our $TASKSRVRMAX = 4;
our $XFERSRVRMAX = 4;
our $REQMAX      = 10;
our $MAXLOAD     = 0.5;

our %REGISTRY;
our $MSGID = $$;
my $_trying;

our $MAXFILE = `sh -c "ulimit -n"`;
$MAXFILE = 255 if $^O eq 'solaris' && $MAXFILE > 255;

################################################################

# schedule periodic "cronjob"
AC::DC::Sched->new(
    info	=> "job periodic",
    freq	=> 2,
    func	=> \&periodic,
   );

################################################################

sub new {
    my $class = shift;
    # %{ APCMRMJobCreate }

    my $me = bless {
        request		=> { @_ },
        phase_no	=> -1,
        file_info	=> {},
        tmp_file	=> [],
        server_info	=> {},
        task_running	=> {},
        task_pending	=> {},
        xfer_running	=> {},
        xfer_pending	=> {},
        request_running	=> {},
        request_pending	=> {},
        statistics	=> { job_start => time() },
    }, $class;

    if( $REGISTRY{ $me->{request}{jobid} } ){
        verbose("ignoring duplicate request job $me->{request}{jobid}");
        # will cause a 200 OK, so the requestor will not retry
        return $REGISTRY{ $me->{request}{jobid} };
    }

    verbose("new job: $me->{request}{jobid} ($me->{request}{traceinfo})");

    my $cf = $me->{options} = decode_json( $me->{request}{options} ) if $me->{request}{options};

    # open connection  to eu-console
    $me->{euconsole} = AC::MrGamoo::EUConsole->new( $me->{request}{jobid}, $me->{request}{console} );

    # partially compile
    eval {
        $me->{mr} = AC::MrGamoo::Submit::Compile->new( text => $me->{request}{jobsrc} );
    };
    if(my $e = $@){
        problem("cannot compile job: $e");
        return;
    }

    # RSN - get_file_list + Plan may take too long - do in sub-process

    # get file list
    my $files = get_file_list( $cf );
    #print STDERR "files: ", dumper($files), "\n";

    for my $f (@$files){
        $me->{file_info}{ $f->{filename} } = $f;
    }

    # get server list
    my $servers = get_peer_list( $cf );
    #print STDERR "servers: ", dumper($servers), "\n";

    # plan job
    my $plan = AC::MrGamoo::Job::Plan->new( $me, $servers, $files );
    #print STDERR "plan: ", dumper($plan), "\n";

    $me->{plan} = $plan;

    $me->{maxfail} = 5 * ( (keys %{$plan->{taskidx}}) + @{$plan->{copying}});

    $me->{server_info}{$_->{id}} = {} for @$servers;

    $me->_preload_file_copies();
    $REGISTRY{ $me->{request}{jobid} } = $me;
    return $me;
}

sub start {
    my $me = shift;

    debug("start job");
    $me->{euconsole}->send_msg('debug', 'starting job');
    $me->_try_to_do_something();
    1;
}

################################################################

# record status rcvd from task
sub task_status {
    my $me = _find(shift, @_);
    my %p  = @_;
    my $taskid = $p{taskid};

    return unless $me;
    my $t = $me->{task_running}{$taskid};
    return unless $t;

    $t->update_status( $me, $p{phase}, $p{progress} );

    1;
}

# record status rcvd from file xfer
sub xfer_status {
    my $me = _find(shift, @_);
    my %p  = @_;
    my $copyid = $p{copyid};

    return unless $me;
    my $c = $me->{xfer_running}{$copyid};
    return unless $c;

    $c->update_status( $me, $p{status_code} );

    1;
}

################################################################

sub periodic {
    # debug("periodic check");

    $_trying = 0;
    for my $job (values %REGISTRY){
        $job->_periodic();
    }
}

sub _periodic {
    my $me = shift;

    my @t = values %{$me->{task_running}};
    for my $t ( @t ){
        my $lt = $t->{status_time} || $t->{start_time};
        next if $^T - $lt < ($me->{options}{tasktimeout} || $TASKTIMEOUT);

        $t->failed( $me, 'timeout' );
    }

    my @c = values %{$me->{xfer_running}};
    for my $c ( @c ){
        my $lt = $c->{status_time} || $c->{start_time};
        next if $^T - $lt < ($me->{options}{xfertimeout} || $XFERTIMEOUT);

        $c->failed( $me, 'timeout' );
    }

    $me->_try_to_do_something();

    my $tr = keys %{ $me->{task_running} };
    my $tp = keys %{ $me->{task_pending} };
    my $xr = keys %{ $me->{xfer_running} };
    my $xp = keys %{ $me->{xfer_pending} };
    my $rr = keys %{ $me->{request_running} };
    my $rp = keys %{ $me->{request_pending} };

    my $ph = $me->{plan}{phases}[ $me->{phase_no} ] || 'none';

    debug("status: phase $ph, task $tr / $tp, xfer $xr / $xp, reqs $rr / $rp")
      if $tr || $tp || $xr || $xp || $rr || $rp;

}

################################################################

sub _start_next_phase {
    my $me = shift;

    debug("next phase");
    $me->{phase_no} ++;
    my $tp = $me->{plan}{taskplan}[ $me->{phase_no} ];

    # finished all phases ?
    unless( $tp ){
        if( $me->{_cleanedup} ){
            $me->_finished();
            return 1;
        }else{
            $me->_cleanup_files();
            return;
        }
    }

    debug("job $me->{request}{jobid} starting phase $tp->{phase}");
    $me->{euconsole}->send_msg('debug', "starting phase $tp->{phase}");

    # move tasks to pending
    for my $t (@{$tp->{task}}){
        $t->pend($me);
    }
}

sub _maybe_start_task {
    my $me = shift;
    my $task = shift;

    #debug("maybe start task");

    my $server   = $task->{server};
    my $underway = keys %{$me->{server_info}{$server}{task_running}};
    return if $underway >= $TASKSRVRMAX;		# don't overload server
    return if $task->{start_after} > $^T;		# rate limit retries

    # RSN - check that prerequisite xfers completed
    $task->start( $me );
    return 1;
}

sub _maybe_start_xfer {
    my $me = shift;
    my $copy = shift;

    #debug("maybe start xfer");

    my $server   = $copy->{server};
    my $underway = keys %{$me->{server_info}{$server}{xfer_running}};
    return if $underway >= $XFERSRVRMAX;		# don't overload server
    return if $copy->{start_after} > $^T;		# rate limit retries

    $copy->start( $me );
    return 1;
}

sub _maybe_start_request {
    my $me  = shift;
    my $req = shift;

    $req->start( $me );
    return 1;
}

################################################################

sub _preload_file_copies {
    my $me = shift;

    # start copying files

    for my $c ( @{$me->{plan}{copying}} ){
        $c->pend($me);
    }
}


################################################################

sub _try_to_do_something {
    my $me = shift;

    # debug("try something");

    return if $me->{_finished};
    return if $_trying;

    # is this phase done
    if( !(keys %{$me->{task_running}})
          && !(keys %{$me->{task_pending}})
          && !(keys %{$me->{xfer_running}})
          && !(keys %{$me->{xfer_pending}})
          && !(keys %{$me->{request_running}})
          && !(keys %{$me->{request_pending}})
         ){

        # this phase is finished
        return if $me->_start_next_phase();
    }

    if( $me->{aborted}
          && !(keys %{$me->{request_running}})
          && !(keys %{$me->{request_pending}})
         ){
        # this phase is finished
        return if $me->_start_next_phase();
    }

    # check load ave, etc
    return unless $me->_ok_to_do_more_p();

    $_trying ++;

    # are there requests that can start
    my @rp = values %{$me->{request_pending}};
    my $startreqs = $REQMAX - keys %{$me->{request_running}};
    for my $r (@rp){
        last if $startreqs <= 0;
        next unless $me->_maybe_start_request( $r );
        $startreqs --;
    }

    unless( $me->{aborted} ){

        # are there tasks that can start
        my $started = 0;
        my @tp = sort { $a->{created} <=> $b->{created} } values %{$me->{task_pending}};
        for my $t (@tp){
            $started += $me->_maybe_start_task( $t );
            last if $started >= $me->{plan}{nserver} / 4;	# keep them from getting in to lockstep
        }

        # are there copies that can start
        my @cp = sort { $a->{created} <=> $b->{created} } values %{$me->{xfer_pending}};
        for my $c (@cp){
            $me->_maybe_start_xfer( $c );
        }
    }

    # should we speculatively copy some files

    # should we speculatively retry a task


    $_trying --;
}

################################################################

sub something_failed {
    my $me = shift;

    return if ++$me->{total_fails} < $me->{maxfail};
    $me->abort();
    return 1;
}

################################################################

sub report {

    my $txt;

    for my $j (values %REGISTRY){
        my $ph;
        $ph = 'start'     if $j->{phase_no} < 0;
        $ph ||= 'cleanup' if $j->{phase_no} >= @{$j->{plan}{phases}};
        $ph ||= $j->{plan}{phases}[ $j->{phase_no} ];

        my $tr = keys %{$j->{task_running}};
        my $tp = keys %{$j->{task_pending}};
        my $cr = keys %{$j->{copy_running}};
        my $cp = keys %{$j->{copy_pending}};
        my $rr = keys %{$j->{request_running}};
        my $rp = keys %{$j->{request_pending}};

        $txt .= sprintf("%s %8s %4d %4d %4d %4d %4d %4d\n", $j->{request}{jobid}, $ph, $tr, $tp, $cr, $cp, $rr, $rp);
        # ...
    }

    return $txt;
}


1;
