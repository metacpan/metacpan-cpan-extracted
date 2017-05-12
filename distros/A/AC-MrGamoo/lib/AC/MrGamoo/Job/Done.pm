# -*- perl -*-

# Copyright (c) 2010 AdCopy
# Author: Jeff Weisberg
# Created: 2010-Jan-21 12:11 (EST)
# Function: 
#
# $Id: Done.pm,v 1.1 2010/11/01 18:41:56 jaw Exp $

package AC::MrGamoo::Job;
use File::Path 'rmtree';
use strict;

our %REGISTRY;
our $MSGID;

sub _finished {
    my $me = shift;

    debug("finished");
    $me->{statistics}{cleanup_time} = time() - $me->{statistics}{cleanup_start};

    verbose("job stats: task $me->{statistics}{task_run} $me->{statistics}{task_run_time}, " .
            "copy: $me->{statistics}{xfer_run} $me->{statistics}{xfer_run_time}, " .
            "job: $me->{statistics}{job_time}, " .
            "cleanup: $me->{statistics}{cleanup_files} $me->{statistics}{cleanup_time}");

    $me->{euconsole}->send_msg('debug', 'finished job');
    $me->{_finished} = 1;
    delete $REGISTRY{ $me->{request}{jobid} };

    # do something?
}

################################################################

sub abort {
    my $me = _find(shift, @_);
    my %p = @_;

    return unless $me;

    debug("abort job $me->{request}{jobid}");

    $me->{task_pending} = {};
    $me->{xfer_pending} = {};

    $me->_cleanup_tasks();
    $me->_cleanup_files();

    return if $me->{aborted};
    $me->{aborted}       = 1;

    # move to final state
    $me->{phase_no} = @{$me->{plan}{taskplan}};

    $me->{euconsole}->send_msg('stderr', 'aborted job' . ($p{reason} ? ": $p{reason}" : ''));
}

################################################################

sub _cleanup_files {
    my $me = shift;

    $me->{_cleanedup} = 1;
    $me->{statistics}{cleanup_start} = time();
    $me->{statistics}{job_time} = time() - $me->{statistics}{job_start};

    $me->{euconsole}->send_msg('debug',  'cleaning up');
    $me->{euconsole}->send_msg('finish', 'finish');

    # remove tmp files
    for my $fi (@{$me->{tmp_file}}){
        # debug("deleting $fi->{filename} from $fi->{server}");
        $me->{statistics}{cleanup_files} ++;

        AC::MrGamoo::Job::Request->new( $me,
            id		=> unique(),
            server	=> $fi->{server},
            info	=> "delete $fi->{filename} from $fi->{server}",
            proto	=> {
                type		=> 'mrgamoo_filedel',
                msgidno		=> $^T,
                want_reply	=> 1,
            },
            request 	=> {
                filename	=> $fi->{filename},
            },
        );
    }

    $me->{tmp_file} = [];
}


sub _cleanup_tasks {
    my $me = shift;

    # abort running tasks
    my @t = values %{$me->{task_running}};
    for my $t (@t){
        $t->abort($me);
    }

    $me->{task_running} = {};
}

sub _cleanup_old_tmp_dirs {

    my $base = conf_value('basedir') . '/mrtmp';
    opendir(D, $base);
    my @d = readdir(D);
    closedir D;

    for my $d (@d){
        next if $d eq '.' || $d eq '..';
        my $p = "$base/$d";

        if( -f $p ){
            # there should not be files here. remove.
            unlink $p;
            next;
        }

        my $mtime = (stat($p))[9];
        next unless $^T - $mtime > 24 * 3600;

        debug("removing old dir: $d");
        rmtree( $p, undef, undef );
    }
}

AC::DC::Sched->new(
    info	=> 'clean up old dirs',
    func	=> \&_cleanup_old_tmp_dirs,
    freq	=> 3600,
   );

1;

