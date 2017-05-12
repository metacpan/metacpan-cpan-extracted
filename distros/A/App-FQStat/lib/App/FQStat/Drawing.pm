
package App::FQStat::Drawing;
# App::FQStat is (c) 2007-2009 Steffen Mueller
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

use strict;
use warnings;
use Time::HiRes qw/sleep time/;
use Term::ANSIScreen qw/RESET locate clline cls/;
use App::FQStat::Debug;
use App::FQStat::Colors qw(get_color);

use base 'Exporter';
our %EXPORT_TAGS = (
  'all' => [qw(
    printline
    update_display
  )],
);
our @EXPORT_OK = @{$EXPORT_TAGS{'all'}};

# print line and buffer with space to line length
sub printline {
  warnenter if ::DEBUG > 2;
  my $line = shift;
  my $offset = shift || 0;
  $line .= ' ' x ($::Termsize[0]-length($line)-$offset);
  print $line, "\n";
}


# draws the first, title line
sub draw_title_line {
  warnenter if ::DEBUG > 1;
  locate(1,1);
  my $line;

  my $summary_mode = $::SummaryMode;

  if ($::MenuMode) {
    print get_color("menu_normal");
    $line = App::FQStat::Menu::get_menu_title_line();
  }
  elsif ($summary_mode) {
    lock($::Interval);
    my $progress = ::PROGRESS_INDICATORS()->[$::ProgressIndicator];
    $progress = ' ' if not defined $progress;
    $line = sprintf(
      'fqstat v%.1f %s Jobs:%i Upd:%.1fs [S]witch [F10] Menu ' . get_color('header_highlight') . 'Summary Mode' . RESET . ', Nodes:%i',
      $App::FQStat::VERSION||0,
      $progress,
      scalar(@{$::Records})||0,
      $::Interval||0,
      $::NoActiveNodes||0,
    );
  }
  else {
    lock($::RecordsReversed);
    lock($::Interval);
    lock($::User);

    # reversed list indicator
    my $status = get_color('reverse_indicator').'[';
    if ($::RecordsReversed) { $status .= 'R' }
    if ($status =~ /\[$/) { $status = '' }
    else { $status .= ']'.RESET.' ' }

    my $progress = ::PROGRESS_INDICATORS()->[$::ProgressIndicator];
    $progress = ' ' if not defined $progress;
    $line = sprintf(
      'fqstat v%.1f %s %s%sJobs:%i Upd:%.1fs [h]elp [F10] Menu (c) S. Mueller, Nodes:%i',
      $App::FQStat::VERSION||0,
      $progress,
      $status||'',
      (defined($::User) ? "User:$::User " : ""),
      scalar(@{$::Records})||0,
      $::Interval||0,
      $::NoActiveNodes||0,
    );
  }
  ::GetTermSize();
  $line = substr($line, 0, $::Termsize[0]) if $::Termsize[0] < length($line);
  printline($line);
  print RESET if $::MenuMode;
}

# draws the column header line
sub draw_header_line {
  warnenter if ::DEBUG > 1;
  my @highlight = @_;
  my %highlight = map {($_ => 1)} @highlight;

  # Header Line
  locate(2,1);
  my ($line, $width);

  my $high = get_color("header_highlight");
  my $norm = get_color("header_normal");

  my $summary_mode = $::SummaryMode;
  my $summary_clustering = App::FQStat::Config::get("summary_clustering");

  print $norm;
  if (not $summary_mode) {
    if (exists $highlight{1}) { $line = $high.'Stat'.$norm }
    else { $line = 'Stat' }
  }

  $width = 4;
  my $colno = 1;
  my $columns_list = $summary_mode ? \@::SummaryColumns : \@::Columns;
  my $columns_hash = $summary_mode ? \%::SummaryColumns : \%::Columns;
  foreach my $col (@$columns_list) {
    my $c = $columns_hash->{$col};
    $colno++;
    next if $summary_mode and $c->{key} eq 'name' and not $summary_clustering;
    $line .= (' 'x($::Termsize[0]-$width-1)).'>', last if $width+2+$c->{width} > $::Termsize[0];
    $width += 1+$c->{width};
    $line .= ' ' unless $colno == 2 and $summary_mode;
    if (exists $highlight{$colno}) { $line .= $high.sprintf("\%-".$c->{width}."s", $c->{name}).$norm }
    else                           { $line .= sprintf("\%-".$c->{width}."s", $c->{name}) }
  }
  printline($line);
  print RESET;
}


my $last_update;
sub update_display {
  warnenter if ::DEBUG;
  my $force = shift;
  $last_update ||= time();
  my $time = time();

  if ($force or $time-$last_update > $::Interval) {
    $last_update = $time;
    $::ProgressIndicator++;
    $::ProgressIndicator = 0
      if $::ProgressIndicator >= scalar(@{::PROGRESS_INDICATORS()});
    App::FQStat::Scanner::run_qstat($force);
  }

  cls();
  ::GetTermSize();

  draw_title_line(); # first line
  draw_header_line(); # second line
  my $summary_mode = $::SummaryMode;

  if ($summary_mode) {
    draw_summary();
  } else {
    draw_job_display(); # list of jobs
  }

  if ($::MenuMode) {
    App::FQStat::Menu::draw_menu();
  }

  locate(1,1);
}

# Draws the job summary
sub draw_summary {
  warnenter if ::DEBUG;

  # before there's any jobs, warn the user that the
  # queue isn't actually empty.
  if (not $::Initialized) {
    draw_initializing_sign();
    locate(1,1);
    return;
  }

  App::FQStat::Scanner::calculate_summary()
    if not defined $::Summary or @$::Summary == 0;

  my $summary = $::Summary;
  my $summary_clustering = App::FQStat::Config::get("summary_clustering");

  my $maxno_lines = space_for_jobs();

  my %status_color = (
    nrun  => get_color("status_running"),
    nerr  => get_color("status_error"),
    nhold => get_color("status_hold"),
    nwait => get_color("status_queued"),
  );

  locate(3,1);
  my $summary_color = get_color("summary");

  my $no = 0;

  foreach my $summaryLine (@$summary) {
    $no++;
    last if $no >= $maxno_lines;

    clline();
    print $summary_color;

    my $width = 0;
    my $first = 1;
    my $too_short = 0;
    foreach my $col (@::SummaryColumns) {
      my $c = $::SummaryColumns{$col};

      # skip name column if not defined
      next if $c->{key} eq 'name' and not $summary_clustering;

      $too_short = 1, last if $width+3+$c->{width} > $::Termsize[0];
      $width += 1+$c->{width};
      print ' ' unless $first;
      $first = 0;
      print $status_color{ $c->{key} } if exists $status_color{ $c->{key} };
      printf( $c->{format}, $summaryLine->[ $c->{index} ] );
      print $summary_color if exists $status_color{ $c->{key} };
    }

    # padding for "position bar" of scroll bar
    print ' 'x($::Termsize[0]-$width-1);

    if ($too_short) {
      # not enough space
      print '>';
    }
    
    print RESET;

    print "\n";
  }

  locate(1,1);
}

# Draws the list of jobs
# Optional argument: hash reference of items to highlight
sub draw_job_display {
  warnenter if ::DEBUG;
  my $highlight = shift || {};
  my $mark      = shift || {};

  # before there's any jobs, warn the user that the
  # queue isn't actually empty.
  if (not $::Initialized) {
    draw_initializing_sign();
    locate(1,1);
    return;
  }

  my $jobs = $::Records;
  check_display_offset();
  lock($::DisplayOffset);

  my $drawUpperScrollbar = need_upper_scrollbar();
  draw_upper_scrollbar() if $drawUpperScrollbar;

  my $drawLowerScrollbar = need_lower_scrollbar();

  
  my $max_job_index = space_for_jobs() - $drawUpperScrollbar - $drawLowerScrollbar;

  locate(3+$drawUpperScrollbar,1);
  my $last = (@$jobs-$::DisplayOffset <= $max_job_index ? @$jobs-1 : $::DisplayOffset + $max_job_index);

  # Calculate "scroll bar" marker
  # XXX this is only necessary if there is enough space.
  my $marker_start = 0;
  my $marker_end   = 1e99;
  if (@$jobs) {
    my $jobs_per_display_line = int(@$jobs / $max_job_index)||1;
    my $display_lines_before_marker = int($::DisplayOffset / $jobs_per_display_line);
    my $display_lines_of_marker     = int(($last-$::DisplayOffset) / $jobs_per_display_line);
    my $display_lines_after_marker  = (@$jobs-$last) / $jobs_per_display_line;
    $marker_start = int $display_lines_before_marker;
    $marker_end   = int($display_lines_before_marker+$display_lines_of_marker);
    $marker_end += 1 if $marker_start == $marker_end;
  }

  my $no = 0;
  my %status_color = (
    running  => get_color("status_running"),
    hold     => get_color("status_hold"),
    error    => get_color("status_error"),
    queued   => get_color("status_queued"),
    fallback => get_color("status_fallback"),
  );

  foreach my $jobIndex  ($::DisplayOffset .. $last) {
    clline();
    my $job = $jobs->[$jobIndex];
    last if $no >= $max_job_index;

    # band-aid fix for uninit... bug
    if (not defined $job) {
      next;
    }

    $no++;

    my $highlightcolor = $highlight->{$jobIndex};

    # highlight selected user name
    $highlightcolor = get_color("user_highlight")
      if not defined $highlightcolor
         and defined $::HighlightUser
         and $job->[::F_user] =~ $::HighlightUser;

    # Print STATUS
    my $status = $job->[::F_status];
    if    ($status =~ /^[rt]$/)     { print $status_color{running} }
    elsif ($status =~ /(?:^d|E)/)   { print $status_color{error} }
    elsif ($status =~ /h(?:qw|r)/)  { print $status_color{hold} }
    elsif ($status =~ /w/)          { print $status_color{queued} }
    else                            { print $status_color{fallback} }

    printf('%-4s', $status);
    print RESET;

    print $highlightcolor if defined $highlightcolor;

    # print marking if applicable
    if (exists($mark->{$jobIndex})) {
      my $markstring = $mark->{$jobIndex};
      $markstring = "*" if not defined $markstring;
      printf("%1s", $markstring);
    }
    else { print " " }
    
    my $width = 4;
    my $first = 1;
    my $too_short = 0;
    foreach my $col (@::Columns) {
      my $c = $::Columns{$col};
      $too_short = 1, last if $width+3+$c->{width} > $::Termsize[0];
      $width += 1+$c->{width};
      print ' ' unless $first;
      $first = 0;
      printf( $c->{format}, $job->[ $c->{index} ] );
    }

    # padding for "position bar" of scroll bar
    print ' 'x($::Termsize[0]-$width-1);

    if ($too_short) {
      # not enough space
      print '>';
    }
    else {
      # draw "position bar" if there is enough space
      my $marker;
      my $bgcolor = get_color("scrollbar_bg");
      my $fgcolor = get_color("scrollbar_fg");
      if ($no >= $marker_start and $no <= $marker_end) {
        $marker = $fgcolor . " " . RESET();
      }
      else {
        $marker = $bgcolor . " " . RESET();
      }
      print $marker;
    }
    
    print RESET;


    print "\n";
  }

  draw_lower_scrollbar() if $drawLowerScrollbar;
  locate(1,1);
}

sub draw_upper_scrollbar {
  warnenter if ::DEBUG > 1;
  locate(3,1);
  printline("^" x ($::Termsize[0]-2));
}

sub draw_lower_scrollbar {
  warnenter if ::DEBUG > 1;
  locate($::Termsize[1]-1, 1);
  printline("v" x ($::Termsize[0]-2));
}

sub need_upper_scrollbar {
  warnenter if ::DEBUG > 2;
  return 1 if $::DisplayOffset;
  return 0;
}

sub need_lower_scrollbar {
  warnenter if ::DEBUG > 2;
  my $jobs = $::Records;
  my $drawLowerScrollbar = (@$jobs-$::DisplayOffset > space_for_jobs()-need_upper_scrollbar() ? 1 : 0);
  return $drawLowerScrollbar;
}

sub space_for_jobs {
  warnenter if ::DEBUG > 1;
  my $space = $::Termsize[1]-3;
  return $space;  
}

sub show_warning {
  warnenter if ::DEBUG > 1;
  my $text = shift;
  # Header Line
  locate(2,1);
  my $color = get_color('header_warning');
  printline($color.$text);
  print RESET;
  sleep 2;
  return;
}

sub check_display_offset {
  lock($::DisplayOffset);
  return if not $::DisplayOffset;
  if (@$::Records <= $::DisplayOffset) {
    $::DisplayOffset = $#{$::Records};
  }
  $::DisplayOffset = 0 if $::DisplayOffset < 0;
}

sub draw_initializing_sign {
  warnenter if ::DEBUG > 1;
  locate(3,1);
  my $color = get_color('initializing');
  print $color, <<'HERE';
                         
                         
   Initial Job Scan...   
                         
                         
HERE
  print RESET;

}

1;


