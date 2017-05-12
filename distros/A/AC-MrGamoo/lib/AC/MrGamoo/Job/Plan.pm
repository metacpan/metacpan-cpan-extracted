# -*- perl -*-

# Copyright (c) 2010 AdCopy
# Author: Jeff Weisberg
# Created: 2010-Jan-14 17:35 (EST)
# Function: 
#
# $Id: Plan.pm,v 1.1 2010/11/01 18:41:56 jaw Exp $

package AC::MrGamoo::Job::Plan;
use AC::MrGamoo::Debug 'plan';
use AC::Misc;

use strict;

my $REDUCEFACTOR = 1.9;		# QQQ - config?
my $MAPTARGETMIN = 8;		# try to have at least this many maps/server
my $MAPSIZELIMIT = 100_000_000;

sub new {
    my $class   = shift;
    my $job     = shift;
    my $servers = shift;
    my $files   = shift;

    return unless @$servers;

    # how many reduces?
    my $nr = _number_of_reduces( $job->{options}, scalar @$servers );

    # map servers to reduce bins
    my $redbin = _pick_reduce_bins( $nr, $servers );

    # plan out the map phase
    my @phase = 'map';
    my($planmap, $plancopy) = _plan_map( $job, $servers, $files, $nr, $redbin );
    my @task  = { phase => 'map', task => $planmap };

    # plan out the reduce phases
    my $nrp = @{$job->{mr}{content}{reduce}};
    for my $r (0 .. $nrp - 1){
        push @phase, "reduce/$r";
        # last reduce has 1 outfile, otherwise nr.
        my $nout = ($r == $nrp - 1) ? 1 : $nr;
        push @task,  { phase => "reduce/$r", task => _plan_reduce($job, $r, $nout, $redbin, $task[-1]{task}) };
    }

    # plan out a final phase
    if( $job->{mr}{content}{final} ){
        push @phase, 'final';
        push @task,  { phase => 'final', task => _plan_final($job, $redbin, $task[-1]{task}) };
    }

    # summary
    my %task;
    for my $ts (@task){
        for my $t ( @{$ts->{task}} ){
            $task{ $t->{id} } = $t;
        }
    }

    # debug("plan: " . dumper( \@task ));

    debug("infiles: " . @$files . ", precopy: " . @$plancopy . ", maps: " . @$planmap . ", reduces: $nr x $nrp");

    return bless {
        nserver		=> scalar(@$servers),
        nreduce		=> $nr,
        copying		=> $plancopy,
        phases		=> \@phase,
        taskplan	=> \@task,
        redbin		=> $redbin,
        taskidx		=> \%task,
    }, $class;
}

sub _number_of_reduces {
    my $config  = shift;
    my $nserver = shift;

    my $nr = $config->{reduces} + 0;
    $nr ||= int $nserver * $REDUCEFACTOR;
    $nr = 1 if $nr < 1;

    return $nr;
}

sub _pick_reduce_bins {
    my $nr      = shift;
    my $servers = shift;


    my @redbin;
    for my $bin (0 .. $nr-1){
        $redbin[$bin][0] = $servers->[ $bin % @$servers ]->{id};

        # pick alt location
        next unless @$servers > 1;
        $redbin[$bin][1] = $servers->[ ($bin + 1) % @$servers ]->{id};
    }
    shuffle(\@redbin);

    return \@redbin;
}

sub _plan_map {
    my $job     = shift;
    my $servers = shift;
    my $files   = shift;
    my $nr      = shift;
    my $redbin  = shift;

    # plan map
    #  divy files among servers
    #  split server + files into tasks

    my( $filemap, $copies ) = _plan_divy_files( $job, $files, $servers );

    my @maptask;
    for my $s (keys %$filemap){
        my $totalsize = 0;
        $totalsize += $_->{size} for @{$filemap->{$s}};;
        my $sizelimit = $totalsize / $MAPTARGETMIN;
        $sizelimit = $MAPSIZELIMIT if $sizelimit > $MAPSIZELIMIT;

        my @todo = sort { $b->{size} <=> $a->{size} } @{$filemap->{$s}};
        while( @todo ){
            my @file;
            my %alt;
            my $tot;

            while( @todo && ($tot < $sizelimit) ){
                my $f = shift @todo;
                $tot += $f->{size};
                push @file, $f->{filename};
                # backup plan?
                my $as = $f->{location}[1];
                $alt{$f->{filename}} = $as if $as;
            }

            my $id = unique();
            push @maptask, AC::MrGamoo::Job::TaskInfo->new( $job,
                id	=> $id,
                phase	=> 'map',
                server  => $s,
                infile  => \@file,
                altplan	=> \%alt,
                _total  => $tot,
                outfile => _plan_outfiles($job, $id, $nr, $redbin, 'map' ),
            );
        }
    }

    return (\@maptask, $copies);
}

sub _plan_reduce {
    my $job     = shift;
    my $rno     = shift;
    my $nout    = shift;
    my $redbin  = shift;
    my $ptasks  = shift;

    my $jid = $job->{request}{jobid};

    my @reds;
    my $sn = 0;
    for my $s (@$redbin){
        my $id = unique();
        push @reds, AC::MrGamoo::Job::TaskInfo->new( $job,
            id		=> $id,
            phase	=> "reduce/$rno",
            server	=> $s->[0],
            altserver	=> $s->[1],
            infile	=> [ map { $_->{outfile}[$sn]{filename} } @$ptasks ],
            outfile	=> _plan_outfiles($job, $id, $nout, $redbin, "red$rno"),
        );
        $sn++;
    }

    return \@reds;
}

sub _plan_final {
    my $job     = shift;
    my $redbin  = shift;
    my $ptasks  = shift;

    my $jid = $job->{request}{jobid};

    my $id = unique();
    return [
        AC::MrGamoo::Job::TaskInfo->new( $job,
            id		=> $id,
            server	=> $redbin->[0][0],
            altserver	=> $redbin->[0][1],
            phase	=> 'final',
            infile	=> [ map { $_->{outfile}[0]{filename} } @$ptasks ],
            outfile	=> [ ],
        ),
       ];
}

sub _plan_outfiles {
    my $job     = shift;
    my $taskid  = shift;
    my $nout    = shift;
    my $redbin  = shift;
    my $pfix    = shift;

    my @out;
    my $jid = $job->{request}{jobid};

    for my $n (0 .. $nout - 1){
        push @out, { filename => "mrtmp/j_$jid/${pfix}_${taskid}_$n", dst => [ @{$redbin->[$n]} ] };
    }

    return \@out;
}

sub _plan_map_these_servers {
    my $job     = shift;
    my $servers = shift;

    # limit number of servers?
    my $nm = ($job->{options}{maps} + 0) || @$servers;

    my %data;
    for my $s ( sort { $a->{metric} <=> $b->{metric} } @$servers ){
        $data{ $s->{id} } = { metric => $s->{metric}, use => ($nm ? 1 : 0) };
        $nm -- if $nm;
    }

    return \%data;
}

sub _plan_divy_files {
    my $job     = shift;
    my $files   = shift;
    my $servers = shift;

    my %filemap;
    my %bytes;
    my @copies;

    my $load = _plan_map_these_servers( $job, $servers );

    # divy files up among servers
    for my $f (sort { $b->{size} <=> $a->{size} } @$files){
        my($best_wgt, $best_loc);
        for my $loc ( @{$f->{location}} ){
            next unless exists $load->{$loc};	# down?
            next unless $load->{$loc}{use};
            my $w = (1 + $bytes{$loc}) * (1 + $load->{$loc}{metric});
            if( !$best_loc || $w < $best_wgt ){
                $best_wgt = $w;
                $best_loc = $loc;
            }
        }

        if( $best_loc ){
            # a server has the file. process it there.
            push @{$filemap{$best_loc}}, $f;
            $bytes{$best_loc} += $f->{size};
            next;
        }

        # pick best 2 servers
        my($sa, $sb) =
          map { $_->[1] }
          sort{ $a->[0] <=> $b->[0] }
          map { [(1 + $bytes{$_}) * (1 + $load->{$_}{metric}), $_] }
          grep { $load->{$_}{use} }
            (keys %$load);

        # copy the file
        my @loc = $sa;
        push @loc, $sb if $sb;
        my $newfile = "mrtmp/j_$job->{request}{jobid}/intmp_" . unique();
        debug("no active servers have file: $f->{filename}, copying to @loc => $newfile");

        my $ff = {
            filename	=> $newfile,
            location	=> \@loc,
            size	=> $f->{size},
        };
        push @{$filemap{$sa}}, $ff;
        $bytes{$sa} += $ff->{size};

        # need to copy this file from its current location to the server(s) that will run map on it
        for my $loc (@loc){
            push @copies, AC::MrGamoo::Job::XferInfo->new( $job,
                 id		=> unique(),
                 filename	=> $f->{filename},
                 dstname	=> $newfile,
                 size		=> $f->{size},
                 location	=> $f->{location},
                 dst		=> $loc,
                );
        }
    }

    return (\%filemap, \@copies);
}

1;
