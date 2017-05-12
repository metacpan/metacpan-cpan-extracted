
package App::FQStat::Scanner;
# App::FQStat is (c) 2007-2009 Steffen Mueller
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

use strict;
use warnings;
use Time::HiRes qw/sleep/;
use String::Trigram ();
use DateTime ();
use Time::Zone ();
use App::FQStat::Debug;

# run qstat
sub run_qstat {
  warnenter if ::DEBUG;
  my $forced = shift;
  lock($::ScannerStartRun);

  if (not defined $::ScannerThread) {
    warnline "Creating new (initial?) scanner thread" if ::DEBUG;
    $::ScannerThread = threads->new(\&App::FQStat::Scanner::scanner_thread);
  }
  elsif ($::ScannerThread->is_joinable()) {
    warnline "Joining scanner thread" if ::DEBUG;
    my $return = $::ScannerThread->join();
    ($::Records, $::NoActiveNodes) = @$return;
    $::Summary = [];
    $::Initialized = 1;
    { lock($::RecordsChanged); $::RecordsChanged = 1; }
    warnline "Joined scanner thread. Creating new scanner thread" if ::DEBUG;
    $::ScannerThread = threads->new(\&App::FQStat::Scanner::scanner_thread);
  }
  elsif (!$::ScannerThread->is_running()) {
    warnline "scanner thread not running. Creating new scanner thread" if ::DEBUG;
    undef $::ScannerThread;
    $::ScannerThread = threads->new(\&App::FQStat::Scanner::scanner_thread);
  }
  elsif ($forced) {
    warnline "scanner thread running. Force in effect, setting StartRun" if ::DEBUG;
    $::ScannerStartRun = 1;
  }
}

sub scanner_thread {
  warnenter if ::DEBUG;
  {
    lock($::ScannerStartRun);
    $::ScannerStartRun = 0;
  }

  my @lines;
  my @args;
  {
    lock($::SummaryMode);
    if ($::SummaryMode) {
      push @args, '-u', '*';
    }
    else {
      lock($::User);
      push @args, '-u', ( (defined($::User) && $::User ne '') ? $::User : '*');
    }
  }

  my $timebefore = time();
  my $qstat = App::FQStat::Config::get("qstatcmd");
  my $output = App::FQStat::System::run_capture($qstat, @args);
  if (not defined $output) {
    die "Running 'qstat' failed!";
  }
  my $duration = time()-$timebefore;

  # Update the update interval according to the time it takes
  {
    lock($::Interval);
    if ($duration >= $::Interval) {
      $::Interval = ($duration > $::Interval*1.8 ? $duration+1.0 : $::Interval*1.8);
    }
    elsif ($duration < $::Interval and $duration > $::UserInterval) {
      $::Interval = ($::Interval/1.1 > $::UserInterval ? $::Interval/1.1 : $::UserInterval);
    }
  }

  @lines = split /\n/, $output;
  shift @lines;
  shift @lines;

  my $noActiveNodes = 0;
  foreach my $line (@lines) {
    $line =~ s/^\s+//;
    my $rec = [split /\s+/, $line];
    $rec->[7] = '' if not $rec->[7] =~ /\D/;
    my @date = split /\//, $rec->[5];
    @date = @date[1, 0, 2];
    my @jobdesc;
    @jobdesc = (
      $rec->[0],        # F_id
      $rec->[1],        # F_prio
      $rec->[2],        # F_name
      $rec->[3],        # F_user
      $rec->[4],        # F_status
      join('.', @date), # F_date
      $rec->[6],        # F_time
      $rec->[7],        # F_queue
    );
    $noActiveNodes++ if $rec->[4] =~ /^\s*r\s*$/;
    $line = \@jobdesc;
  }

  reverse_records(\@lines) if $::RecordsReversed; # retain state of reversal

  sort_current(\@lines);

  lock($::DisplayOffset);
  lock(@::Termsize);
  my $limit = @lines - $::Termsize[1]+4;
  if ($::DisplayOffset and $::DisplayOffset > $limit) {
    $::DisplayOffset = $limit;
  }

  sleep 0.1; # Note to self: fractional sleep without HiRes => CPU=100%
  warnline "End of scanner_thread" if ::DEBUG;
  return [\@lines, $noActiveNodes];
}






# sorts the qstat output by $::SortField
sub sort_current {
  warnenter if ::DEBUG;
  my $lines = shift;
  my $sortfield;
  {
    lock($::SortField);
    if (not defined $::SortField or $::SortField eq '' or not exists $::Columns{$::SortField}) {
      warnline "Nothing to sort" if ::DEBUG;
      return;
    }
    $sortfield = $::SortField;
  }
  my $key = $sortfield;
  my $key_index = ::RECORD_KEY_CONSTANT()->{$key};
  
  my $order;
  $order = $::Columns{$sortfield}{order} unless $sortfield eq 'status';
  $order = 'status' if $sortfield eq 'status';

  warnline "Sorting: key=$key order=$order" if ::DEBUG;

  return if not defined $order;

  my $time = time(); # for debugging / profiling

  if ($order eq 'status') {
    
    @$lines = 
          map { $_->[0] }
          sort { $a->[1] <=> $b->[1] }
          map {
            my $s = $_->[::F_status];
            if    ($s =~ /[Ed]/) { $s = 0 }
            elsif ($s =~ /r/) { $s = 1 }
            elsif ($s =~ /t/) { $s = 2 }
            elsif ($s =~ /w/) { $s = 3 }
            else  { $s = 4 }
            [$_, $s]
          }
          @$lines;
  }
  elsif ($order eq 'time') {
    ::debug "Sorting by time";
    @$lines =
          map { $_->[0] }
          sort { $a->[1] <=> $b->[1] or $a->[2] <=> $b->[2] or $a->[3] <=> $b->[3] }
          map { [$_, split(/:/, $_->[$key_index])] }
          @$lines;
  }
  elsif ($order eq 'date') {
    ::debug "Sorting by date";
    @$lines =
          map { $_->[0] }
          sort { $b->[1] <=> $a->[1] or $b->[2] <=> $a->[2] or $b->[3] <=> $a->[3] }
          map { [$_, split(/\./, $_->[$key_index])] }
          @$lines;
  }
  elsif ($order eq 'num') {
    ::debug "Sorting numerically";
    @$lines =
          sort { $a->[$key_index] <=> $b->[$key_index] }
          @$lines;
  }
  elsif ($order eq 'num_highlow') {
    ::debug "Sorting numerically high to low";
    @$lines =
          sort { $b->[$key_index] <=> $a->[$key_index] }
          @$lines;
  }
  else { # default to alpha
    ::debug "Sorting alphabetically";
    @$lines =
          sort { $a->[$key_index] cmp $b->[$key_index] }
          @$lines;
  }

  {
    lock($::RecordsReversed);
    lock($::RecordsChanged);
    reverse_records($::Records) if $::RecordsReversed;
    $::RecordsChanged = 1 if $::RecordsReversed;
  }

  if (::DEBUG()) {
    my $diff = time()-$time;
    ::debug "Sorting took $diff seconds.";
  }
}


# reverse the current set of records
sub reverse_records {
  warnenter if ::DEBUG;
  my $lines = shift;
  @$lines = reverse @$lines;
}


# calculate the job summary
sub calculate_summary {
  warnenter if ::DEBUG;
  $::Summary = [];

  my $offset = Time::Zone::tz_local_offset();
  my $curtime = time() + $offset;

  # cluster by user name
  my %user_clusters;
  foreach my $job (@$::Records) {
    my $user = $job->[::F_user];
    $user_clusters{$user} ||= [];
    push @{$user_clusters{$user}}, $job;
  }

  if (App::FQStat::Config::get("summary_clustering")) {
    my $trigram = String::Trigram->new(
      minSim  => App::FQStat::Config::get("summary_clustering_similarity"),
      warp    => 1.2,
      cmpBase => [],
    );

    my %user_name_clusters;

    # cluster by similarity
    foreach my $user (keys %user_clusters) {
      $trigram->reInit([]);

      my %jname_clusters;
      my $jobs = $user_clusters{$user};
      foreach my $job (@$jobs) {
        my $jname = $job->[::F_name];
        # ignore numbers
        $jname =~ s/\d+//g;
        
        if (keys %jname_clusters) {
          my @bestmatch;
          my $sim = $trigram->getBestMatch($jname, \@bestmatch);
          if (@bestmatch and $sim) {
            push @{ $jname_clusters{$bestmatch[0]} }, $job;
          }
          else {
            $jname_clusters{$jname} ||= [];
            push @{ $jname_clusters{$jname} }, $job;
            $trigram->extendBase([$jname]);
          }
        }
        else {
          $jname_clusters{$jname} = [$job];
          $trigram->extendBase([$jname]);
        }

      }

      foreach my $jname (keys %jname_clusters) {
        my $clustername = "$user;$jname";
        $user_name_clusters{$clustername} ||= [];
        push @{$user_name_clusters{$clustername}}, @{$jname_clusters{$jname}};
        delete $jname_clusters{$jname};
      }
      
    } # end foreach user cluster

    %user_clusters = %user_name_clusters;
  }

  # actually calculate the summaries for each cluster
  foreach my $user (keys %user_clusters) {
    my $jobs          = $user_clusters{$user};
    my %n_status      = (r => 0, E => 0, h => 0, 'qw' => 0);
    my $prio_sum      = 0;
    my $nprio         = 0;
    my $runtime_sum   = 0;
    my $njobs_started = 0;
    my $max_runtime   = 0;

    foreach my $job (@$jobs) {
      my $prio = $job->[::F_prio];
      $nprio++, $prio_sum += $prio if $prio > 1.e-2;

      # find job status
      for ($job->[::F_status]) {
        if    (/^[rt]$/)      { $n_status{r}++;  }
        elsif (/(?:^d|E)/)    { $n_status{E}++;  }
        elsif (/h(?:qw|r|t)/) { $n_status{h}++;  }
        else                  { $n_status{qw}++; }
      }

      if ($job->[::F_status] =~ /^h?[rt]$/) {
        my ($day, $month, $year)     = split /\./, $job->[::F_date];
        my ($hour, $minute, $second) = split /:/, $job->[::F_time];
        my $dt = DateTime->new(year => $year, month  => $month,  day    => $day,
                               hour => $hour, minute => $minute, second => $second);
        my $runtime = $curtime - $dt->epoch();
        $runtime_sum += $runtime;
        $max_runtime = $runtime if $runtime > $max_runtime;
        $njobs_started++;
      }

    }

    ($user, my $jobname) = split /;/, $user;

    my $runtime = '';
    if ($njobs_started) {
      my $seconds = $runtime_sum/$njobs_started;
      my $hours = int($seconds / 3600);
      my $minutes = int($seconds / 60 - $hours*60);
      $seconds = int($seconds) % 60;
      $runtime = sprintf('%02u:%02u:%02u', $hours, $minutes, $seconds);

      $seconds = $max_runtime;
      $hours = int($seconds / 3600);
      $minutes = int($seconds / 60 - $hours*60);
      $seconds = int($seconds) % 60;
      $max_runtime = sprintf('%02u:%02u:%02u', $hours, $minutes, $seconds);
    }
    else {
      $max_runtime = '';
    }

    my $line = [ $user, $jobname, @n_status{'r', 'E', 'h', 'qw'}, ($nprio?$prio_sum/$nprio:0), $runtime, $njobs_started, $max_runtime ];
    push @$::Summary, $line;
  } # end for each user

  @$::Summary =
    sort {
         $b->[3] <=> $a->[3] #errors
      or $b->[8] <=> $a->[8] #nodes-used
      or $b->[2] <=> $a->[2] #running
    }
    @$::Summary;

  return(1);
}


1;

