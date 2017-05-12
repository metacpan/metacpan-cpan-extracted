
package App::FQStat::Input;
# App::FQStat is (c) 2007-2009 Steffen Mueller
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

use strict;
use warnings;
use Term::ANSIScreen qw/RESET locate :keyboard/;
use Term::ReadKey;

use App::FQStat::Drawing qw/printline update_display/;
require App::FQStat::Actions;
use App::FQStat::Debug;
use App::FQStat::Colors qw(get_color);

use base 'Exporter';
our %EXPORT_TAGS = (
  'all' => [qw(
    poll_user
    get_input_key
    select_multiple_jobs
    select_job
  )],
);
our @EXPORT_OK = @{$EXPORT_TAGS{'all'}};


# Poll user for info
sub poll_user {
  warnenter if ::DEBUG > 1;
  my $query = shift;
  locate(2,1);
  print get_color("user_input");
  printline("");
  locate(2,1);
  print $query;
  ReadMode 1;
  my $input = <STDIN>;
  ReadMode 3;
  print RESET;
  update_display();
  chomp $input;
  return $input;
}


# get new input key, blocking for KEY_POLL_INTERVAL seconds
sub get_input_key {
  warnenter if ::DEBUG > 3;
  my $timeout = shift;
  $timeout ||= ::KEY_POLL_INTERVAL();
  my $key = ReadKey $timeout;
  return $key;
}



# select many jobs
# returns reference to array of selected jobs
# and the key that triggered the end of selection
sub select_multiple_jobs {
  warnenter if ::DEBUG;
  my @args = ('multiple', @_);
  return _select_jobs(@args);
}


# select single job
# returns reference to array of selected jobs
# and the key that triggered the end of selection
sub select_job {
  warnenter if ::DEBUG;
  my @args = ('single', @_);
  return _select_jobs(@args);
}


# This implements the whole job selection thingy
sub _select_jobs {
  warnenter if ::DEBUG > 1;
  my $mode = shift; # can be "single" or "multiple". Defaults to "multiple".
  my $is_multiple = $mode eq 'single' ? 0 : 1;
  my $keys_toggle_return = shift || ['q'];
  my $select_color = shift || get_color("selected_job");
  my $cursor_color = shift || get_color('selected_cursor');
  my $selected_start = shift;

  # if one of these keys is found, we return
  my %return_keys = map {($_ => 1)} @$keys_toggle_return;

  my $cursor_pos;
  {
    lock($::DisplayOffset);
    $cursor_pos = $::DisplayOffset;
  }
  my %selected; # holds the indices of selected lines with a color (select_color)
  my %selected_mark; # holds indices of marked lines with mark ("* ")
  if ($selected_start) {
    %selected = map {($_ => $select_color)} @$selected_start;
    %selected_mark = map {($_ => "*")} @$selected_start;
  }
  my $selectspan_begin; # holds the start of the selection span

  # control key mappings
  my %ckeys = (
    'A'  => sub { # up
      $cursor_pos--;
      $cursor_pos = 0 if $cursor_pos < 0;
      lock($::DisplayOffset);
      App::FQStat::Actions::scroll_up(1) if $cursor_pos < $::DisplayOffset;
    },
    'B'  => sub { # down
      $cursor_pos++;
      $cursor_pos = @{$::Records}-1 if $cursor_pos >= @{$::Records};
      lock($::DisplayOffset);
      App::FQStat::Actions::scroll_down(1) if $cursor_pos >= $::DisplayOffset+$::Termsize[1]-5;
    },
    '5'  => sub { # pgup
      $cursor_pos -= $::Termsize[1]-5;
      $cursor_pos = 0 if $cursor_pos < 0;
      lock($::DisplayOffset);
      App::FQStat::Actions::scroll_up($::Termsize[1]-5) if $cursor_pos < $::DisplayOffset;
    },
    '6'  => sub { # pgdown
      $cursor_pos += $::Termsize[1]-5;
      $cursor_pos = @{$::Records}-1 if $cursor_pos >= @{$::Records};
      lock($::DisplayOffset);
      App::FQStat::Actions::scroll_down($::Termsize[1]-5) if $cursor_pos >= $::DisplayOffset+$::Termsize[1]-5;
    },
    'H'  => sub { # pos1
      $cursor_pos = 0;
      App::FQStat::Actions::scroll_up(1e9);
    },
    'F'  => sub { # end
      $cursor_pos = @{$::Records}-1;
      App::FQStat::Actions::scroll_down(1e9);
    },
  );


  my $redraw = 1;
  my @tsize = @::Termsize;
  while (1) {
    ::GetTermSize();
    if ($redraw or $tsize[0] != $::Termsize[0] or $tsize[1] != $::Termsize[1]) {
      my %highlight = %selected; # merge cursor highlight and selection highlight
      if (defined $selectspan_begin) {
        # mark the whole selection span as cursor
        my ($begin, $end) = ($selectspan_begin>$cursor_pos ? ($cursor_pos,$selectspan_begin) : ($selectspan_begin,$cursor_pos));
        $highlight{$_} = $cursor_color foreach ($begin..$end);
      }
      else { $highlight{$cursor_pos} = $cursor_color }

      App::FQStat::Drawing::draw_header_line();
      App::FQStat::Drawing::draw_job_display(\%highlight, \%selected_mark); # highlight and mark
      $redraw = 0;
    }

    my $input = get_input_key();
    if (defined $input) {
      if ($input =~ /\n/ or $input =~ /\r/ or $input eq ' ') { # select
        if ($is_multiple and defined $selectspan_begin) {
          _process_selectspan(\%selected, \%selected_mark, $selectspan_begin, $cursor_pos, $select_color);
          $selectspan_begin = undef; # end span selection
        }
        else {
          # normal selection/deselection
          _toggle_select_deselect(\%selected, \%selected_mark, $cursor_pos, $select_color);

          # only allow a single selection if not in multi-mode
          if (not $is_multiple) {
            my $selected = [keys %selected];
            return($selected, $input);
          }
        }
        $redraw = 1;
      }
      elsif (exists $return_keys{$input}) {
        # treat exit as selection in single-selection mode.
        if (not $is_multiple) {
          _toggle_select_deselect(\%selected, \%selected_mark, $cursor_pos, $select_color);
        }

        # wrap up and return
        my $selected = [keys %selected];
        return($selected, $input);
      }
      elsif ($is_multiple and $input eq 's') {
        if (defined $selectspan_begin) {
          _process_selectspan(\%selected, \%selected_mark, $selectspan_begin, $cursor_pos, $select_color);
          $selectspan_begin = undef; # end span selection
        }
        # start selection span
        else { $selectspan_begin = $cursor_pos }
        $redraw = 1;
      }
      elsif ($input eq '[') { # handle control keys
        my $key = get_input_key(0.01);
        if (defined $key and exists $ckeys{$key}) {
          $ckeys{$key}->($key);
          $redraw = 1;
        }
      }
    } # end if defined input
  } # end while
}


sub _toggle_select_deselect {
  warnenter if ::DEBUG > 2;
  my $select_hash = shift;
  my $select_mark_hash = shift;
  my $index = shift;
  my $color = shift;
  if (exists $select_hash->{$index}) {
    delete $select_hash->{$index}; 
    delete $select_mark_hash->{$index}; 
  }
  else {
    $select_hash->{$index} = $color;
    $select_mark_hash->{$index} = "*";
  }
}

sub _process_selectspan {
  warnenter if ::DEBUG > 2;
  my ($selected, $selected_mark, $selectspan_begin, $cursor_pos, $select_color) = @_;

  my ($begin, $end) = ( $selectspan_begin > $cursor_pos
                         ? ($cursor_pos, $selectspan_begin)
                         : ($selectspan_begin, $cursor_pos) );

  foreach my $index ($begin..$end) {
    _toggle_select_deselect($selected, $selected_mark, $index, $select_color);
  }
}




1;

