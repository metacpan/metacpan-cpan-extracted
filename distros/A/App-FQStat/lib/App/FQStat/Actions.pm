
package App::FQStat::Actions;
# App::FQStat is (c) 2007-2009 Steffen Mueller
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

use strict;
use warnings;
use Time::HiRes qw/sleep time/;
use Term::ANSIScreen qw/RESET locate clline cls/;

use App::FQStat::Drawing qw/printline update_display/;
use App::FQStat::Input qw/poll_user get_input_key select_multiple_jobs select_job/;
use App::FQStat::Debug;
use App::FQStat::Config qw/get_config set_config/;
use App::FQStat::Colors qw/get_color/;


####################
# ACTIONS

# Scrolling: set display offset with boundary checking:
sub scroll_up {
  warnenter if ::DEBUG;
  my $lines = shift || 1;
  lock($::DisplayOffset);
  $::DisplayOffset -= $lines;
  $::DisplayOffset = 0 if $::DisplayOffset < 0;
}

sub scroll_down {
  warnenter if ::DEBUG;
  my $lines = shift || 1;
  lock($::DisplayOffset);
  $::DisplayOffset += $lines;
  my $limit = @{$::Records} - $::Termsize[1]+4;
  $::DisplayOffset = $limit if $::DisplayOffset > $limit;
  $::DisplayOffset = 0 if $::DisplayOffset < 0;
}


sub update_user_name {
  warnenter if ::DEBUG;
  my $input = poll_user("User name: ");
  lock($::User);
  if (not defined $input or $input =~ /^\s*$/) {
    $::User = undef;
  }
  else {
    $::User = $input;
  }
  update_display(1);
}

sub set_user_interval {
  warnenter if ::DEBUG;
  my $input = poll_user("Desired update interval: ");
  if (defined $input and  $input =~ /^\s*[+-]?(?=\d|\.\d)\d*(?:\.\d*)?(?:[Ee][+-]?\d+)?\s*$/) {
    $::UserInterval = $input+0;
    lock($::Interval);
    $::Interval = $::UserInterval;
  }
  update_display(1);
}

sub select_sort_field {
  warnenter if ::DEBUG;
  my @cols = ('status', @::Columns);

  # determine start sort field
  my $sort = 0;
  my $colno = 0;
  if (defined $::SortField) {
    foreach my $col (@cols) {
      if ($col eq $::SortField) {
        $sort = $colno;
        last;
      }
      $colno++;
    }
  }

  # key mappings
  my %ckeys = (
    'D' => sub { $sort--; $sort = @cols-1 if $sort < 0; }, # left
    'C' => sub { $sort++; $sort = 0 if $sort >= @cols;  }, # right
  );

  # print instructions
  locate(1,1);
  clline();
  print get_color("selected_cursor");
  print "Select Sort Field:";
  print RESET;
  print " (left/right to select, s/Enter to confirm, n for none, q to cancel)\n";

  while (1) {
    App::FQStat::Drawing::draw_header_line($sort+1);
    my $input = get_input_key();
    if (defined $input) {
      if ($input eq 's' or $input =~ /\n/ or $input =~ /\r/) { # select
        $::SortField = $cols[$sort];
        App::FQStat::Scanner::sort_current($::Records);
        return 1; # redraw
      }
      elsif ($input eq 'n') {
        $::SortField = undef;
        return 1; # redraw
      }
      elsif ($input eq 'q') {
        return 1;
      }
      elsif ($input eq '[') {
        my $key = get_input_key(0.01);
        if (defined $key and exists $ckeys{$key}) {
          $ckeys{$key}->($key);
        }
      }
    } # end if defined input
  } # end while
}

sub toggle_reverse_sort {
  warnenter if ::DEBUG;
  ::debug "Reversing sort order";
  lock($::RecordsReversed);
  if ($::RecordsReversed == 1) { $::RecordsReversed = 0 }
  else { $::RecordsReversed = 1 }
  App::FQStat::Scanner::reverse_records($::Records);
  return 1; # redraw
}


sub kill_jobs {
  warnenter if ::DEBUG;
  # print instructions
  locate(1,1);
  clline();
  print get_color("user_instructions");
  print "Kill jobs: Select with Space, span with 's', hit 'k' to kill or 'q' to cancel.";
  print RESET;
  print "\n";

  my ($selected, $key) = select_multiple_jobs( ['q', 'k'] );

  if ($key eq 'q' or @$selected == 0) {
    # cancel
    return 1; # redraw
  }
  elsif ($key eq 'k') {
    my $confirm = poll_user("Really kill? Type 'yes' to kill: ");
    if ($confirm =~ /^\s*yes\s*$/i) {
      my $jobs = $::Records;
      my @ids = sort { $a <=> $b } map { $jobs->[$_][::F_id] } @$selected;
      cls();
      locate(3,1);
      print get_color("warning") . "Killing the following jobs:" . RESET();
      print "\n", join("\n", @ids);
      print "\n";
      foreach my $dead (@ids) {
        if ( App::FQStat::System::run(get_config("qdelcmd"), $dead) ) {
            # This branch doesn't seem to be entered because qdel is braindead and doesn't
            # signal failure with exit($POSITIVE_INTEGER)
            print get_color("warning"), "WARNING: Something went wrong. Return value: $!", RESET;
            print "\n(Hit Enter to continue)";
            my $tmp = <STDIN>;
            last;
          }
      }
      sleep 2;
      update_display(1);
      return;
    }
    else {
      return 1; # redraw
    }
  } # end if $key is 'k'
  else {
    die "Invalid key which stopped selection mode. (Sanity check)";
  }
  return 1;
}


sub change_priority {
  warnenter if ::DEBUG;
  # print instructions
  locate(1,1);
  clline();
  print get_color("user_instructions");
  print "Change priority: Select with Space, span with 's', hit 'p' to set priority or 'q' to cancel.";
  print RESET;
  print "\n";

  my ($selected, $key) = select_multiple_jobs( ['q', 'p'] );

  if ($key eq 'q' or @$selected == 0) {
    # cancel
    return 1; # redraw
  }
  elsif ($key eq 'p') {
    my $prio = poll_user("Which priority should these jobs be set to? ");
    if ($prio =~ /^\s*[+-]?\d+\s*$/i) {
      my $integerprio = $prio+=0; # make an integer
      my $jobs = $::Records;
      my @ids = sort { $a <=> $b } map { $jobs->[$_][::F_id] } @$selected;
      cls();
      locate(3,1);
      print get_color("warning"), "Setting priority for the following jobs:", RESET();
      print "\n", join("\n", @ids);
      print "\n";

      foreach my $job (@ids) {
        if ( App::FQStat::System::run(get_config("qaltercmd"), '-p', $integerprio, $job) ) {
          print "\n", get_color("warning"), "WARNING: Something went wrong. Return value: $!", RESET;
          print "\n(Hit 'q' to quit or any other key to continue)";
          my $tmp = get_input_key(1e9);
          last if (defined $tmp and $tmp eq 'q');
        }
        print "\n";
      }
      sleep 2;
      update_display(1);
      return;
    }
    else {
      return 1; # redraw
    }
  } # end if $key is 'p'
  else {
    die "Invalid key which stopped selection mode. (Sanity check)";
  }
  return 1;
}



sub hold_jobs {
  warnenter if ::DEBUG;
  # print instructions
  locate(1,1);
  clline();
  print get_color("user_instructions");
  print "Hold jobs: Select with Space, span with 's', hit 'o' to hold or 'q' to cancel.";
  print RESET;
  print "\n";

  my ($selected, $key) = select_multiple_jobs( ['q', 'o'] );

  if ($key eq 'q' or @$selected == 0) {
    # cancel
    return 1; # redraw
  }
  elsif ($key eq 'o') {
    my $jobs = $::Records;
    my @ids = sort { $a <=> $b } map { $jobs->[$_][::F_id] } @$selected;
    cls();
    locate(3,1);
    print get_color("warning"), "Setting the following jobs on hold:", RESET();
    print "\n", join("\n", @ids);
    print "\n";

    foreach my $job (@ids) {
      if ( App::FQStat::System::run(get_config("qaltercmd"), '-h', 'u', $job) ) {
        print "\n", get_color("warning"), "WARNING: Something went wrong. Return value: $!", RESET;
        print "\n(Hit 'q' to quit or any other key to continue)";
        my $tmp = get_input_key(1e9);
        last if (defined $tmp and $tmp eq 'q');
      }
      print "\n";
    }
    sleep 2;
    update_display(1);
    return;
  } # end if $key is 'o'
  else {
    die "Invalid key which stopped selection mode. (Sanity check)";
  }
  return 1;
}


sub resume_jobs {
  warnenter if ::DEBUG;
  # print instructions
  locate(1,1);
  clline();
  print get_color("user_instructions");
  print "Resume jobs: Select with Space, span with 's', hit 'o' or 'O' to resume or 'q' to cancel.";
  print RESET;
  print "\n";

  my ($selected, $key) = select_multiple_jobs( ['q', 'o', 'O'] );

  if ($key eq 'q' or @$selected == 0) {
    # cancel
    return 1; # redraw
  }
  elsif ($key eq 'o' or $key eq 'O') {
    my $jobs = $::Records;
    my @ids = sort { $a <=> $b } map { $jobs->[$_][::F_id] } @$selected;
    cls();
    locate(3,1);
    print get_color("warning"), "Resuming the following jobs:", RESET();
    print "\n", join("\n", @ids);
    print "\n";

    foreach my $job (@ids) {
      if ( App::FQStat::System::run(get_config("qaltercmd"), '-h', 'U', $job) ) {
        print "\n", get_color("warning"), "WARNING: Something went wrong. Return value: $!", RESET;
        print "\n(Hit 'q' to quit or any other key to continue)";
        my $tmp = get_input_key(1e9);
        last if (defined $tmp and $tmp eq 'q');
      }
      print "\n";
    }
    sleep 2;
    update_display(1);
    return;
  } # end if $key is 'o' or 'O'
  else {
    die "Invalid key which stopped selection mode. (Sanity check)";
  }
  return 1;
}


sub clear_job_error_state {
  warnenter if ::DEBUG;
  # print instructions
  locate(1,1);
  clline();
  print get_color("user_instructions");
  print "Clear error state: Select with Space, span with 's', hit 'c' to apply or 'q' to cancel.";
  print RESET;
  print "\n";

  my ($selected, $key) = select_multiple_jobs( ['q', 'c'] );

  if ($key eq 'q' or @$selected == 0) {
    # cancel
    return 1; # redraw
  }
  elsif ($key eq 'c') {
    my $jobs = $::Records;
    my @ids = sort { $a <=> $b } map { $jobs->[$_][::F_id] } @$selected;
    cls();
    locate(3,1);
    print get_color("warning"), "Clearing the error state of the following jobs:", RESET();
    print "\n", join("\n", @ids);
    print "\n";

    foreach my $job (@ids) {
      if ( App::FQStat::System::run(get_config("qmodcmd"), '-cj', $job) ) {
        print "\n", get_color("warning"), "WARNING: Something went wrong. Return value: $!", RESET;
        print "\n(Hit 'q' to quit or any other key to continue)";
        my $tmp = get_input_key(1e9);
        last if (defined $tmp and $tmp eq 'q');
      }
      print "\n";
    }
    sleep 2;
    update_display(1);
    return;
  } # end if $key is 'c'
  else {
    die "Invalid key which stopped selection mode. (Sanity check)";
  }
  return 1;
}


sub update_highlighted_user_name {
  warnenter if ::DEBUG;
  my $input = poll_user("User name to highlight: ");
  if (not defined $input or $input =~ /^\s*$/) {
    $::HighlightUser = undef;
    update_display(1);
    return;
  }
  
  my $regex;
  eval { $regex = qr/$input/; };
  if ($@ or not defined $regex) {
    show_warning("Invalid regular expression!");
    update_display(1);
    return;
  }
  $::HighlightUser = $regex;
  update_display(1);
  return;
}


sub change_dependencies {
  warnenter if ::DEBUG;
  # print instructions
  locate(1,1);
  clline();
  print get_color("user_instructions");
  print "Change deps of jobs: Select with Space, span with 's', hit 'd' to confirm or 'q' to cancel.";
  print RESET;
  print "\n";

  my ($selected, $key) = select_multiple_jobs( ['q', 'd'] );

  if ($key eq 'q' or @$selected == 0) {
    # cancel
    return 1; # redraw
  }
  elsif ($key eq 'd') {
    locate(1,1);
    clline();
    print get_color("user_instructions");
    print "Jobs to depend on: Select with Space, span with 's', hit 'd' to confirm or 'q' to cancel.";
    print RESET;
    print "\n";

    my ($dependencies, $key) = select_multiple_jobs( ['q', 'd'] );
    if ($key eq 'q' or @$dependencies == 0) {
      # cancel
      return 1; # redraw
    }

    my $jobs = $::Records;
    my $deplist = join (',', map { $jobs->[$_][::F_id]  } @$dependencies);
    
    my @ids = sort { $a <=> $b } map { $jobs->[$_][::F_id] } @$selected;
    cls();
    locate(3,1);
    print get_color("warning"), "Changing the dependencies of the following jobs:", RESET();
    print "\n", join("\n", @ids);
    print "\n";

    foreach my $job (@ids) {
      if ( App::FQStat::System::run(get_config("qaltercmd"), $job, '-hold_jid', $deplist) ) {
        print "\n", get_color("warning"), "WARNING: Something went wrong. Return value: $!", RESET;
        print "\n(Hit 'q' to quit or any other key to continue)";
        my $tmp = get_input_key(1e9);
        last if (defined $tmp and $tmp eq 'q');
      }
      print "\n";
    }
    sleep 2;
    update_display(1);
    return;
  } # end if $key is 'o'
  else {
    die "Invalid key which stopped selection mode. (Sanity check)";
  }
  return 1;
}



sub show_job_details {
  warnenter if ::DEBUG;
  # print instructions
  locate(1,1);
  clline();
  print get_color("user_instructions");
  print "Show job details: Select with Space/Enter, 'q' to cancel.";
  print RESET;
  print "\n";

  my ($selected, $key) = select_job();

  if ($key eq 'q' or @$selected == 0) {
    # cancel
    return 1; # redraw
  }
  else {
    my $jobs = $::Records;
    my $id = $jobs->[ $selected->[0] ][::F_id]; # get job id
    my $qstat = get_config("qstatcmd");
    my $output = App::FQStat::System::run_capture($qstat, '-j', $id); # perhaps IPC::Cmd or IPC::Run or even just Open3 would be better here?
    if ($output =~ /^\s*$/ms) {
      print get_color("warning"), "WARNING: Something went wrong. Return value: $!", RESET;
      print "\n(Hit Enter to continue)";
      my $tmp = <STDIN>;
      return 1;
    }
    cls();
    my $color = get_color("warning");
    my $reset = RESET;
    $output =~ s/^([^:]+:)/$color$1$reset/mg;
    print $output;
    print "\n(Hit any key to continue)";
    my $tmp = get_input_key(1e9);

    # FIXME! We could do better than just puke to STDOUT.
  } # end if selection okay
  return 1; # doesn't happen
}




sub show_job_log {
  warnenter if ::DEBUG;
  # print instructions
  locate(1,1);
  clline();
  print get_color("user_instructions");
  print "Show job log: Select with Space/Enter or 'l', 'q' to cancel.";
  print RESET;
  print "\n";

  my ($selected, $key) = select_job(['q','l']);

  if ($key eq 'q' or @$selected == 0) {
    # cancel
    return 1; # redraw
  }
  else {
    my $jobs = $::Records;
    my $id = $jobs->[ $selected->[0] ][::F_id]; # get job id
    my $qstat = get_config("qstatcmd");
    my $output = App::FQStat::System::run_capture($qstat, '-j', $id); # perhaps IPC::Cmd or IPC::Run or even just Open3 would be better here?
    if ($output =~ /^\s*$/ms) {
      print get_color("warning"), "WARNING: Something went wrong. Return value: $!", RESET;
      print "\n(Hit Enter to continue)";
      my $tmp = <STDIN>;
      return 1;
    }
    cls();

    my @o = split /\n/, $output;
    my $err;
    my $out;
    my $cwd;
    foreach my $line (@o) {
      if ( $line =~ /^std(err|out)_path_list:/ ) {
        my $match = $1;
        $line =~ s/^std(?:err|out)_path_list:\s*//;
        chomp $line;
        if ($match eq 'err') { $err = $line }
        else { $out = $line }
        last if defined $out and defined $err;
      }
      elsif ( $line =~ /^cwd:/ ) {
        $cwd = $line;
        $cwd =~ s/^cwd:\s*//;
        chomp $cwd;
      }
    }
    $err =~ s/^stderr_path_list:\s*// if defined $err;
    $out =~ s/^stdout_path_list:\s*// if defined $out;

    if ( not defined $cwd ) {
      print "Could not determine current working directory for locating the logs.\n";
      my $tmp = get_input_key(300);
      return 1;
    }
    elsif ( not defined $out and not defined $err ) {
      # couldn't find log
      print "No log could be found for this job. Owner didn't set stdout nor stderr redirection?\n";
      my $tmp = get_input_key(300);
      return 1;
    }
    elsif ( defined $out and defined $err and $out eq $err ) {
      undef $err; # only show once
    }

    my $cmd;
    if (defined $out) {
      if ($out !~ /^\//) {
        $out = File::Spec->catdir($cwd, $out);
      }
      $cmd .= " $out";
    }
    if (defined $err) {
      if ($err !~ /^\//) {
        $err = File::Spec->catdir($cwd, $err);
      }
      $cmd .= " $err";
    }
    App::FQStat::System::run("sh", '-c', qq(cat $cmd | less));

  } # end if selection okay
  return 1; # doesn't happen
}


sub delete_color_scheme {
  warnenter if ::DEBUG;
  my $name = poll_user("Delete which color scheme? ");
  if ($name =~ /^\s*(\w+)\s*$/i) {
    my $schemeName = lc($1);
    return 1 if $schemeName eq 'default';
    my $schemes = get_config("color_schemes");
    if (exists($schemes->{$schemeName})) {
      delete $schemes->{$schemeName};
    }
  }
  return 1;
}

sub save_color_scheme {
  warnenter if ::DEBUG;
  my $name = poll_user("Save as which color scheme? ");
  if ($name =~ /^\s*(\w+)\s*$/i) {
    my $schemeName = lc($1);
    return 1 if $schemeName eq 'default';
    my $schemes = get_config("color_schemes");
    $schemes->{$schemeName} = {%{ get_config('colors') }};
  }
  return 1;
}

sub toggle_summary_mode {
  warnenter if ::DEBUG;
  {
    lock($::SummaryMode);
    $::SummaryMode = ($::SummaryMode+1) % 2;
    set_config("summary_mode", $::SummaryMode);
  }
  return 1;
}


sub toggle_summary_name_clustering {
  warnenter if ::DEBUG;
  $::Summary = [];
  my $cluster = get_config("summary_clustering")||0;
  $cluster = ($cluster+1)%2;
  set_config("summary_clustering", $cluster);
  return 1;
}


sub show_manual {
  warnenter if ::DEBUG;
  cls();
  my $heading = get_color("menu_normal");
  my $h = get_color("warning");
  my $r = RESET;
  print <<"HERE";
${heading}  fqstat v$App::FQStat::VERSION - Interactive front-end for qstat               $r
Commands:
  ${h}'h'             ${r}     Show this (H)elp screen
  ${h}'q'             ${r}     (Q)uit
  ${h}F10             ${r}     Show Menu
  ${h}F5              ${r}     Refresh data from qstat and redraw
  ${h}'S'             ${r}     Toggle Summary Mode
  ${h}Up- / Down-Arrow${r}     Scroll up/down if possible
  ${h}Page-Up / -Down ${r}     Scroll one page up/down if possible
  ${h}Pos1 / End      ${r}     Jump to beginning / end
  ${h}Space / Enter   ${r}     Show detailed job info

  ${h}'u'             ${r}     Enter (U)ser name whose jobs to display
  ${h}'H'             ${r}     (H)ightlight a user's jobs
  ${h}'i'             ${r}     Set the desired update (I)nterval
  ${h}'s'             ${r}     Select the field to (S)ort by
  ${h}'r'             ${r}     Toggle display (R)eversal
  ${h}'l'             ${r}     Show job (l)og
  ${h}'k'             ${r}     (Kill), Select jobs for Deletion
  ${h}'p'             ${r}     Change (P)riority of selected jobs
  ${h}'o/O'           ${r}     H(o)ld jobs / Resume j(O)bs
  ${h}'c'             ${r}     (C)lear error state of jobs
                               (In Summary Mode: Toggle Clustering)
  ${h}'d'             ${r}     Change job (d)ependencies
fqstat is (c) 2007-2009 Steffen Mueller. This program is free software; you
can redistribute it and/or modify it under the same terms as Perl itself.
HERE
  my $input = Term::ReadKey::ReadKey(1e9);
  return 1; # redraw
}



1;


