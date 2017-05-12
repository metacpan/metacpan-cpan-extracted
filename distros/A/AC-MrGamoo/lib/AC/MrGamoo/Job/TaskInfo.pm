# -*- perl -*-

# Copyright (c) 2010 AdCopy
# Author: Jeff Weisberg
# Created: 2010-Apr-22 10:50 (EDT)
# Function: info about tasks
#
# $Id: TaskInfo.pm,v 1.1 2010/11/01 18:41:57 jaw Exp $

package AC::MrGamoo::Job::TaskInfo;
use AC::MrGamoo::Debug 'job_taskinfo';
use AC::MrGamoo::PeerList;
use AC::Misc;
use strict;

our @ISA = 'AC::MrGamoo::Job::Info';

my $MAXRETRY = 2;

sub new {
    my $class = shift;
    my $job   = shift;

    return bless { @_ }, $class;
}

sub pend {
    my $me  = shift;
    my $job = shift;

    return if $me->{replaced};
    return if $me->{finished};

    # create instance, put on pending queue
    my $t = AC::MrGamoo::Job::Task->new($job, $me, $me->{server});
    return unless $t;
    $me->{instance}{ $t->{id} } = $t;

    return;
}

sub finished {
    my $me   = shift;
    my $t    = shift;
    my $job  = shift;

    delete $me->{instance}{ $t->{id} };

    $me->{finished} = 1;
    my $outfiles = $me->{outfile};
    my $server   = $t->{server};

    debug("task finished $me->{id} on $server");
    # copy files
    for my $fi (@$outfiles){
        # add to file_info - file is now on one server
        debug("  outfile $fi->{filename}");
        $job->{file_info}{ $fi->{filename} } = {
            filename	=> $fi->{filename},
            location	=> [ $server ],
        };
        $job->{server_info}{$server}{has_files}{$fi->{filename}} = 1;
        # QQQ - optionally leave final files?
        push @{$job->{tmp_file}}, { filename => $fi->{filename}, server => $server };

        # add to copy_pending
        foreach my $s ( @{$fi->{dst}} ){
            next if $job->{server_info}{$s}{has_files}{$fi->{filename}};
            my $c = AC::MrGamoo::Job::XferInfo->new( $job,
                id		=> unique(),
                filename	=> $fi->{filename},
                dst		=> $s,
               );
            next unless $c;
            $c->pend($job);
            debug("    => pending copy for $s");
        }
    }
}

sub failed {
    my $me   = shift;
    my $t    = shift;
    my $job  = shift;

    delete $me->{instance}{ $t->{id} };

    my $server = $me->{server};
    my $status = get_peer_status_from_id($server);
    if( $status != 200 ){
        # replan tasks
        $job->_replan_server($server, 'task', $me);
        return;
    }

    if( $me->{retries} ++ > $MAXRETRY ){
        # replan tasks
        $me->replan($job);
        return;
    }

    # retry
    debug("retry task");
    $me->pend($job);
}

################################################################

sub replan {
    my $me  = shift;
    my $job = shift;

    return if $me->{replaced};

    return $job->abort( reason => "too many failed tasks. out of replan options.")
      if $me->{replaces};

    return $me->_replan_altserver($job) if $me->{altserver};

    if( $me->{phase} eq 'reduce' ){
        verbose("cannot replan task. no altserver");
        $job->abort(reason => "cannot replan task. no alternate server available");
        return;
    }

    $me->_replan_map($job);
}

sub _replan_altserver {
    my $me  = shift;
    my $job = shift;

    $me->{server} = $me->{altserver};
    delete $me->{retries};
    delete $me->{altserver};

    debug("replanning task to new server");
    $me->pend($job);
}

sub _replan_map {
    my $me  = shift;
    my $job = shift;

    # remove task
    # divy files among servers
    # create new tasks
    # rediddle next phase

    my %newplan;	# server => @files

    $me->{replaced} = 1;

    unless( $me->{altplan} ){
        verbose("no alt task available - aborting");
        $job->abort(reason => "cannot replan task. no alternate available");
        return;
    }

    # divy files
    for my $f (@{$me->{infile}}){
        # alt loc for this file?
        my $loc = $me->{altplan}{$f};

        unless($loc){
            verbose("file unavailable - aborting ($f)");
            $job->abort(reason => "file unavailable: $f");
            return;
        }
        push @{$newplan{$loc}}, $f;
    }

    my @new;
    for my $as (keys %newplan){
        my $newid = unique();
        my $oldid = $me->{id};

        my $new = AC::MrGamoo::Job::TaskInfo->new($job,
            id		=> $newid,
            phase	=> $me->{phase},
            infile	=> $newplan{$as},
            replaces	=> $oldid,
            outfile	=> [ map {
                (my $f = $_->{filename}) =~ s/$oldid/$newid/;
                { dst => $_->{dst}, filename => $f, }
            } @{$me->{outfile}} ],
            server	=> $as,
        );
        debug("replan map $oldid => $newid on $as");

        # keep plan up to date
        $job->{plan}{taskidx}{$newid} = $new;
        push @{$job->{plan}{taskplan}[0]{task}}, $new;

        # move to pending queue
        $new->pend($job) if $job->{phase_no} == 0;

        push @new, $new;
    }

    $me->_replan_replace_files( $job, @new );

}

sub _replan_replace_files {
    my $me  = shift;
    my $job = shift;
    my @new = shift;

    my $oldid = $me->{id};
    my $curphase = 0;	# map
    my $nxtphase = 1;	# reduce/0

    # remove old task's files, add new tasks' files
    for my $ti ( @{$job->{plan}{taskplan}[$nxtphase]{task}} ){
        my @infile;
        for my $file (@{$ti->{infile}}){
            if( $file =~ /$oldid/ ){
                for my $new (@new){
                    my $newid = $new->{id};
                    (my $n = $file) =~ s/$oldid/$newid/;
                    push @infile, $n;
                }
            }else{
                push @infile, $file;
            }
        }
        $ti->{infile} = \@infile;
    }
}

1;
