# -*- perl -*-

# Copyright (c) 2010 AdCopy
# Author: Jeff Weisberg
# Created: 2010-Jan-13 13:02 (EST)
# Function: m/r task (parent side)
#
# $Id: Task.pm,v 1.10 2011/01/14 20:58:26 jaw Exp $

package AC::MrGamoo::Task;
use AC::MrGamoo::Debug 'task';
use AC::MrGamoo::Submit::Compile;
use AC::MrGamoo::Submit::Request;
use AC::MrGamoo::Task::Running;
use AC::MrGamoo::PeerList;
use AC::MrGamoo::Config;
use AC::DC::IO::Forked;
use JSON;
use strict;

my $TSTART  = $^T;
my $TIMEOUT = 3600;
my $MAXREQ  = 2;
my $MAXRUNNING = 7;	# tune me!
my %REGISTRY;
my $msgid = $$;


################################################################

# schedule periodic "cronjob"
AC::DC::Sched->new(
    info	=> "task periodic",
    freq	=> 5,
    func	=> \&periodic,
   );

################################################################

sub new {
    my $class = shift;
    # %ACPMRMTaskCreate

    my $me = bless {
        request		=> { @_ },
    }, $class;
    debug("new task $me->{request}{taskid}");

    my $task = $me->{request}{taskid};
    return problem("cannot create task: no task id")   unless $task;
    if( $REGISTRY{$task} ){
        verbose("ignoring duplicate request task $task");
        # will cause a 200 OK, so the requestor will not retry
        return $REGISTRY{$task};
    }

    $me->{options} = decode_json( $me->{request}{options} ) if $me->{request}{options};
    $me->{initres} = from_json( $me->{request}{initres}, {allow_nonref => 1} ) if $me->{request}{initres};

    # compile
    eval {
        my $mr = AC::MrGamoo::Submit::Compile->new( text => $me->{request}{jobsrc} );
        # merge job config + opts.
        $mr->set_config($me->{options});
        $mr->set_initres($me->{initres});
        $me->{R} = AC::MrGamoo::Submit::Request->new( $mr );
        $me->{R}{config}{jobid}  = $me->{request}{jobid};
        $me->{R}{config}{taskid} = $me->{request}{taskid};
        $me->{mr} = $mr;
    };
    if(my $e = $@){
        problem("cannot compile task: $e");
        return;
    }

    # measure
    for my $file (@{$me->{request}{infile}}){
        my $s = (stat(conf_value('basedir') . '/' . $file))[7];
        $me->{_inputsize} += $s
    }

    debug("input size: $me->{_inputsize}");

    # print STDERR "Task: ", dumper($me), "\n";
    $REGISTRY{$task} = $me;
    return $me;
}

sub start {
    my $me = shift;

    # if too many tasks are running, queue
    my $nrun = 0;
    for my $t (values %REGISTRY){
        $nrun ++ if $t->{io};
    }

    if( $nrun >= $MAXRUNNING ){
        $me->{_queueprio}    = $^T - $TSTART + $me->{_inputsize} / 1_000_000;
        $me->{status}{phase} = 'QUEUED';
        $me->{status}{amt}   = 0;
        debug("queue $me->{request}{phase} task $me->{request}{jobid}/$me->{request}{taskid} prio $me->{_queueprio}");
        return 1;
    }

    $me->_start();
}

sub _start {
    my $me = shift;

    debug("start $me->{request}{phase} task $me->{request}{jobid}/$me->{request}{taskid}");

    my $io = AC::DC::IO::Forked->new(
        \&AC::MrGamoo::Task::Running::_start_task, [ $me ],
        info	=> "task $me->{request}{jobid}/$me->{request}{taskid}",
       );

    $me->{io} = $io;
    $io->timeout_rel($TIMEOUT);
    $io->set_callback('timeout',  \&_timeout);
    $io->set_callback('read',     \&_read,     $me);
    $io->set_callback('shutdown', \&_shutdown, $me);

    $io->start();
}

sub abort {
    my $me = _find(shift, @_);

    return unless $me;
    debug("abort task $me->{request}{taskid}");
    $me->{io}->shut() if $me->{io};
    return 1;
}


sub _find {
    my $me = shift;
    return $me if ref $me;

    my %p = @_;
    my $task = $p{taskid};
    $me = $REGISTRY{$task};

    return $me;
}

sub _timeout {
    my $io = shift;
    $io->shut();
}

sub _shutdown {
    my $io  = shift;
    my $evt = shift;
    my $me  = shift;

    # send status to master
    $me->_send_status();

    my $task = $me->{request}{taskid};
    delete $REGISTRY{$task};

    delete $me->{io};

    periodic(1);	# try to start another task
}

sub _send_status_done {
    my $io  = shift;
    my $evt = shift;
    my $me  = shift;

    $me->{_status_underway} --;
}

sub _read {
    my $io  = shift;
    my $evt = shift;
    my $me  = shift;

    debug("read child $me->{request}{taskid}: $evt->{data}.");
    # read status msg from child
    $io->{rbuffer} .= $evt->{data};

    my @l = split /^/m, $io->{rbuffer};
    $io->{rbuffer} = '';
    for my $l (@l){
        unless( $l =~ /\n/ ){
            $io->{rbuffer} = $l;
            last;
        }

        debug("got status $l");
        chomp($l);
        my($phase, $amt) = split /\s+/, $l;

        $me->{status}{phase} = $phase;
        $me->{status}{amt}   = $amt;
        $me->{status}{fail}  = 1 if $phase eq 'FAILED';

        # send status to master
        $me->_send_status();
    }
}

sub _send_status {
    my $me = shift;

    # don't kill the master with too many requests
    # return if $me->{_status_underway} >= $MAXREQ;

    my($addr, $port) = get_peer_addr_from_id( $me->{request}{master} );
    return unless $addr;

    debug("sending task status update $me->{request}{taskid} => $me->{status}{phase}");
    my $x = AC::MrGamoo::API::Client->new( $addr, $port, "task $me->{request}{taskid}", {
        type		=> 'mrgamoo_taskstatus',
        msgidno		=> $msgid++,
        want_reply	=> 0,
    }, {
        jobid		=> $me->{request}{jobid},
        taskid		=> $me->{request}{taskid},
        phase		=> $me->{status}{phase},
        progress	=> $me->{status}{amt},
    } );

    return unless $x;

    $me->{_status_underway} ++;
    $x->set_callback('shutdown', \&_send_status_done, $me);

    $x->start();

}

sub attr {
    my $me = shift;
    my $bk = shift;
    my $p  = shift;

    return $bk->{attr}{$p} if $bk && $bk->{attr}{$p};
    return $me->{options}{$p};
}

sub report {

    my $txt;

    for my $t (values %REGISTRY){
        $txt .= "$t->{request}{jobid} $t->{request}{taskid} $t->{status}{phase}\n";
    }

    return $txt;
}

sub periodic {
    my $quick = shift;

    # how many tasks are running?
    my $nrun = 0;
    for my $t (values %REGISTRY){
        $nrun ++ if $t->{io};
    }

    return if $quick && $nrun >= $MAXRUNNING;

    # queued? send status, maybe start

    for my $t (sort { $a->{_queueprio} <=> $b->{_queueprio} } values %REGISTRY){
        next if $t->{io};

        $t->_send_status() unless $quick;

        if( $nrun < $MAXRUNNING ){
            $t->_start();
            $nrun ++;
        }
    }
}


1;

