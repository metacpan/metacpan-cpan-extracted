# Curses::Widgets::Calendar.pm -- Button Set Widgets
#
# (c) 2001, Arthur Corliss <corliss@digitalmages.com>
#
# $Id: Calendar.pm,v 1.103 2002/11/03 23:33:05 corliss Exp corliss $
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program; if not, write to the Free Software
#    Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#
#####################################################################

=head1 NAME

Curses::Widgets::Calendar - Calendar Widgets

=head1 MODULE VERSION

$Id: Calendar.pm,v 1.103 2002/11/03 23:33:05 corliss Exp corliss $

=head1 SYNOPSIS

  use Curses::Widgets::Calendar;

  $cal = Curses::Widgets::Calendar->({
    CAPTION     => 'Appointments',
    CAPTIONCOL  => 'yellow',
    INPUTFUNC   => \&scankey,
    FOREGROUND  => undef,
    BACKGROUND  => 'black',
    BORDER      => 1,
    BORDERCOL   => 'red',
    FOCUSSWITCH => "\t",
    X           => 1,
    Y           => 1,
    HIGHLIGHT   => [12, 17, 25],
    HIGHLIGHTCOL=> 'green',
    MONTH       => '11/2001',
    ONYEAR      => \&yearly,
    ONMONTH     => \&monthly,
    ONDAY       => \&daily,
    });

  $cal->draw($mwh, 1);

  See the Curses::Widgets pod for other methods.

=head1 REQUIREMENTS

=over

=item Curses

=item Curses::Widgets

=back

=head1 DESCRIPTION

Curses::Widgets::Calendar provides simplified OO access to Curses-based
calendars.  Each object maintains it's own state information.

=cut

#####################################################################
#
# Environment definitions
#
#####################################################################

package Curses::Widgets::Calendar;

use strict;
use vars qw($VERSION @ISA);
use Carp;
use Curses;
use Curses::Widgets;

($VERSION) = (q$Revision: 1.103 $ =~ /(\d+(?:\.(\d+))+)/);
@ISA = qw(Curses::Widgets);

#####################################################################
#
# Module code follows
#
#####################################################################

=head1 METHODS

=head2 new (inherited from Curses::Widgets)

  $cal = Curses::Widgets::Calendar->({
    CAPTION     => 'Appointments',
    CAPTIONCOL  => 'yellow',
    INPUTFUNC   => \&scankey,
    FOREGROUND  => undef,
    BACKGROUND  => 'black',
    BORDER      => 1,
    BORDERCOL   => 'red',
    FOCUSSWITCH => "\t",
    X           => 1,
    Y           => 1,
    HIGHLIGHT   => [12, 17, 25],
    HIGHLIGHTCOL=> 'green',
    MONTH       => '11/2001',
    ONYEAR      => \&yearly,
    ONMONTH     => \&monthly,
    ONDAY       => \&daily,
    });

The new method instantiates a new Calendar object.  The only mandatory
key/value pairs in the configuration hash are B<X> and B<Y>.  All
others have the following defaults:

  Key         Default   Description
  ============================================================
  CAPTION       undef   Caption superimposed on border
  CAPTIONCOL    undef   Foreground colour for caption text
  INPUTFUNC \&scankey   Function to use to scan for keystrokes
  FOREGROUND    undef   Default foreground colour
  BACKGROUND    undef   Default background colour
  BORDER            1   Display a border around the field
  BORDERCOL     undef   Foreground colour for border
  FOCUSSWITCH    "\t"   Characters which signify end of input
  HIGHLIGHT        []   Days to highlight
  HIGHLIGHTCOL  undef   Default highlighted data colour
  HEADERCOL     undef   Default calendar header colour
  MONTH     (current)   Month to display
  VALUE             1   Day of the month where the cursor is
  ONYEAR        undef   Callback function triggered by year
  ONMONTH       undef   Callback function triggered by month
  ONDAY         undef   Callback function triggered by day

Each of the ON* callback functions expect a subroutine reference that excepts
one argument: a handle to the calendar object itself.  If more than one
trigger is called, it will be called in the order of day, month, and then
year.

=cut

sub _conf {
  # Validates and initialises the new TextField object.
  #
  # Usage:  $self->_conf(%conf);

  my $self = shift;
  my %conf = ( 
    INPUTFUNC     => \&scankey,
    BORDER        => 1,
    FOCUSSWITCH   => "\t",
    HIGHLIGHT     => [],
    VALUE         => 1,
    MONTH         => join('/',
      (localtime)[4] + 1, (localtime)[5] + 1900),
    LINES         => 8,
    COLUMNS       => 20,
    @_ 
    );
  my @required = qw(X Y);
  my $err = 0;

  # Check for required arguments
  foreach (@required) { $err = 1 unless exists $conf{$_} };

  # Lowercase all colours
  foreach (qw(HIGHLIGHTCOL HEADERCOL)) {
    $conf{$_} = lc($conf{$_}) if exists $conf{$_} };

  $err = 1 unless $self->SUPER::_conf(%conf);

  return $err == 0 ? 1 : 0;
}

=head2 draw

  $cal->draw($mwh, 1);

The draw method renders the calendar in its current state.  This
requires a valid handle to a curses window in which it will render
itself.  The optional second argument, if true, will cause the calendar's
selected day to be rendered in standout mode (inverse video).

=cut

sub _content {
  my $self = shift;
  my $dwh = shift;
  my $conf = $self->{CONF};
  my $pos = $$conf{VALUE};
  my @date = split(/\//, $$conf{MONTH});
  my @highlight = @{ $$conf{HIGHLIGHT} };
  my ($i, @cal);

  # Get the calendar lines and print them
  @cal = _gen_cal(@date[1,0]);
  $i = 0;
  foreach (@cal) {

    # Set the header colour (if defined)
    unless ($i > 1 || ! exists $$conf{HEADERCOL}) {
      $dwh->attrset(COLOR_PAIR(
        select_colour(@$conf{qw(HEADERCOL BACKGROUND)})));
      $dwh->attron(A_BOLD) if $$conf{HEADERCOL} eq 'yellow';
    }

    # Save the cursor position if it's on this line
    $self->{COORD} = [$i, length($1)] if $cal[$i] =~ /^(.*\b)$pos\b/;

    # Print the calendar line
    $dwh->addstr($i, 0, $cal[$i]);

    # Highlight the necessary dates
    if (exists $$conf{HIGHLIGHTCOL}) {
      until ($#highlight == -1 || $cal[$i] !~ /^(.*\b)$highlight[0]\b/) {
        $dwh->chgat($i, length($1), length($highlight[0]), 0,
          select_colour(@$conf{qw(HIGHLIGHTCOL BACKGROUND)}), 0);
        shift @highlight;
      }
    }

    # Restore the default settings (if adjusted for headers or hightlights)
    $self->_restore($dwh);

    ++$i;
  }
}

sub _cursor {
  my $self = shift;
  my $dwh = shift;
  my $conf = $self->{CONF};
  my $pos = $$conf{VALUE};
  my @highlight = @{$$conf{HIGHLIGHT}};
  my ($y, $x) = @{$self->{COORD}};
  my $fg;

  # Determine the foreground colour
  if (exists $$conf{HIGHLIGHTCOL}) {
    $fg = (grep /^$pos$/, @highlight) ? $$conf{HIGHLIGHTCOL} :
      $$conf{FOREGROUND};
  } else {
    $fg = $$conf{FOREGROUND};
  }

  # Display the cursor
  $dwh->chgat($y, $x, length($pos), A_STANDOUT, 
    select_colour($fg, $$conf{BACKGROUND}), 0);

  # Restore the default settings
  $self->_restore($dwh);
}

sub _gen_cal {
  # Generates the calendar month output, and stuffs it into a
  # LOL, which is returned by the method.
  #
  # Modified from code provided courtesy of Michael E. Schechter,
  # <mschechter@earthlink.net>
  #
  # Usage:  @lines = $self->_gen_cal($year, $month);

  my @date = @_;
  my (@lines, @tmp, $i, @out);

  # All of these local subroutines are essentially code to replicate
  # the UNIX 'cal' command.  My code parses the output to create the 
  # LOL.

  local *print_month = sub {
    my ($year, $month) = @_;
    my @month = make_month_array($year, $month);
    my @months = ('', qw(January February March April May June 
      July August September October November December));
    my $days = 'Su Mo Tu We Th Fr Sa';
    my ($title, $diff, $left, $day, $end, $x, $out);

    $title = "$months[$month] $year";
    $diff = 20 - length($title);
    $left = $diff - int($diff / 2);
    $title = ' ' x $left."$title";
    $out = "$title\n$days";
    $end = 0;
    for ($x = 0; $x < scalar @month; $x++) {
      $out .= "\n" if $end == 0;
      $out .= "$month[$x]";
      $end++;
      if ($end > 6) {
        $end = 0;
      }
    }
    $out .= "\n";
    return $out;
  };

  local *make_month_array = sub {
    my ($year, $month) = @_;
    my $firstweekday = day_of_week_num($year, $month, 1);
    my (@month_array, $numdays, $remain, $x, $y);

    $numdays = days_in_month($year, $month);
    $y = 1;
    for ($x = 0; $x < $firstweekday; $x++ ) { $month_array[$x] = '   ' };
    if (! ($year == 1752 && $month == 9)) {
      for ($x = 1; $x <= $numdays; $x++, $y++) { 
        $month_array[$x + $firstweekday - 1] = sprintf( "%2d ", $y);
      }
    } else {
      for ($x = 1; $x <= $numdays; $x++, $y++) { 
        $month_array[$x + $firstweekday - 1] = sprintf( "%2d ", $y);
        if ($y == 2) {
          $y = 13;
        }
      }
    }
    return @month_array;
  };

  local *day_of_week_num = sub {
    my ($year, $month, $day) = @_;
    my ($a, $y, $m, $d);

    $a = int( (14 - $month)/12 );
    $y = $year - $a;
    $m = $month + (12 * $a) - 2;
    if (is_julian($year, $month)) {
      $d = (5 + $day + $y + int($y/4) + int(31*$m/12)) % 7;
    } else {
      $d = ($day + $y + int($y/4) - int($y/100) + int($y/400) + 
        int(31*$m/12)) % 7;
    }
    return $d;
  };

  local *days_in_month = sub {
    my ($year, $month) = @_;
    my @month_days = ( 0,31,28,31,30,31,30,31,31,30,31,30,31 );

    if ($month == 2 && is_leap_year($year)) {
      $month_days[2] = 29;
    } elsif ($year == 1752 && $month == 9) {
      $month_days[9] = 19;
    }
    return $month_days[$month];
  };

  local *is_julian = sub {
    my ($year, $month) = @_;
    my $bool = 0;

    $bool = 1 if ($year < 1752 || ($year == 1752 && $month <= 9));
    return $bool;
  };

  local *is_leap_year = sub {
    my $year = shift;
    my $bool = 0;

    if (is_julian($year, 1)) {
      $bool = 1 if ($year % 4 == 0);
    } else {
      $bool = 1 if (($year % 4 == 0 && $year % 100 != 0) || 
        $year % 400 == 0);
    }
    return $bool;
  };

  @out = split(/\n/, print_month(@date));

  return @out;

}

sub input_key {
  # Process input a keystroke at a time.
  #
  # Usage:  $self->input_key($key);

  my $self = shift;
  my $in = shift;
  my $conf = $self->{CONF};
  my $pos = $$conf{VALUE};
  my @date = split(/\//, $$conf{MONTH});
  my @days = (0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31);
  my ($y, $trigger);

  # Adjust for leap years, if necessary
  $days[2] += 1 if (($date[1] % 4 == 0 && $date[1] % 100 != 0) ||
    $date[1] % 400 == 0);

  $trigger = 'd';

  # Navigate according to key press
  if ($in eq KEY_LEFT) {
    $pos -= 1;
  } elsif ($in eq KEY_RIGHT) {
    $pos += 1;
  } elsif ($in eq KEY_UP) {
    $pos -= 7;
  } elsif ($in eq KEY_DOWN) {
    $pos += 7;
  } elsif ($in eq KEY_NPAGE) {
    $pos += 28;
    $pos += 7 if $pos <= $days[$date[0]];
  } elsif ($in eq KEY_PPAGE) {
    $pos -= 28;
    $pos -= 7 if $pos > 0;
  } elsif ($in eq KEY_HOME || $in eq KEY_FIND) {
    ($pos, @date) = (localtime)[3..5];
    $date[0] += 1;
    $date[1] += 1900;

  # Key press wasn't a navigation key, so reset trigger
  } else {
    $trigger = '';
  }

  # Adjust the dates as necessary according to the cursor movement
  if ($pos < 1) {
    --$date[0];
    if ($date[0] < 1) {
      --$date[1];
      $date[0] = 12;
    }
    $pos += $days[$date[0]];
  } elsif ($pos > $days[$date[0]]) {
    ++$date[0];
    if ($date[0] > 12) {
      ++$date[1];
      $date[0] = 1;
    }
    $pos -= $days[$date[0] > 1 ? $date[0] - 1 : 12];
  }

  # Compare old info to the new and set trigger flags
  $trigger .= 'm' if $date[0] != ($$conf{MONTH} =~ /^(\d+)/)[0];
  $trigger .= 'y' if $date[1] != ($$conf{MONTH} =~ /(\d+)$/)[0];

  # Save the adjusted dates
  @$conf{qw(VALUE MONTH)} = ($pos, join('/', @date));

  # Call the triggers
  &{$$conf{ONDAY}}($self) if (defined $$conf{ONDAY} && 
    $trigger =~ /d/);
  &{$$conf{ONMONTH}}($self) if (defined $$conf{ONMONTH} && 
    $trigger =~ /m/);
  &{$$conf{ONYEAR}}($self) if (defined $$conf{ONYEAR} && 
    $trigger =~ /y/);
}

1;

=head1 HISTORY

=over

=item 1999/12/29 -- Original calendar widget in functional model

=item 2001/07/05 -- First incarnation in OO architecture

=back

=head1 AUTHOR/COPYRIGHT

(c) 2001 Arthur Corliss (corliss@digitalmages.com) 

=cut

