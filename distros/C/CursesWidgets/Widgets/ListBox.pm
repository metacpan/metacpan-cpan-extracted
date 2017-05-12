# Curses::Widgets::ListBox.pm -- List Box Widgets
#
# (c) 2001, Arthur Corliss <corliss@digitalmages.com>
#
# $Id: ListBox.pm,v 1.104 2002/11/14 01:20:28 corliss Exp corliss $
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

Curses::Widgets::ListBox - List Box Widgets

=head1 MODULE VERSION

$Id: ListBox.pm,v 1.104 2002/11/14 01:20:28 corliss Exp corliss $

=head1 SYNOPSIS

  use Curses::Widgets::ListBox;

  $lb = Curses::Widgets::ListBox->new({
    CAPTION     => 'List',
    CAPTIONCOL  => 'yellow',
    COLUMNS     => 10,
    LINES       => 3,
    VALUE       => 0,
    INPUTFUNC   => \&scankey,
    FOREGROUND  => 'white',
    BACKGROUND  => 'black',
    SELECTEDCOL => 'green',
    BORDER      => 1,
    BORDERCOL   => 'red',
    FOCUSSWITCH => "\t",
    X           => 1,
    Y           => 1,
    TOPELEMENT  => 0,
    LISTITEMS   => [@list],
    });

  $lb->draw($mwh, 1);

  See the Curses::Widgets pod for other methods.

=head1 REQUIREMENTS

=over

=item Curses

=item Curses::Widgets

=back

=head1 DESCRIPTION

Curses::Widgets::ListBox provides simplified OO access to Curses-based
single/multi-select list boxes.  Each object maintains its own state 
information.

=cut

#####################################################################
#
# Environment definitions
#
#####################################################################

package Curses::Widgets::ListBox;

use strict;
use vars qw($VERSION @ISA);
use Carp;
use Curses;
use Curses::Widgets;

($VERSION) = (q$Revision: 1.104 $ =~ /(\d+(?:\.(\d+))+)/);
@ISA = qw(Curses::Widgets);

#####################################################################
#
# Module code follows
#
#####################################################################

=head1 METHODS

=head2 new (inherited from Curses::Widgets)

  $tm = Curses::Widgets::ListBox->new({
    CAPTION     => 'List',
    CAPTIONCOL  => 'yellow',
    COLUMNS     => 10,
    LINES       => 3,
    VALUE       => 0,
    INPUTFUNC   => \&scankey,
    FOREGROUND  => 'white',
    BACKGROUND  => 'black',
    SELECTEDCOL => 'green',
    BORDER      => 1,
    BORDERCOL   => 'red',
    FOCUSSWITCH => "\t",
    X           => 1,
    Y           => 1,
    TOPELEMENT  => 0,
    LISTITEMS   => [@list],
    });

The new method instantiates a new ListBox object.  The only mandatory
key/value pairs in the configuration hash are B<X> and B<Y>.  All others
have the following defaults:

  Key           Default   Description
  ============================================================
  CAPTION         undef   Caption superimposed on border
  CAPTIONCOL      undef   Foreground colour for caption text
  COLUMNS            10   Number of columns displayed
  LINES               3   Number of lines in the window
  INPUTFUNC   \&scankey   Function to use to scan for keystrokes
  FOREGROUND      undef   Default foreground colour
  BACKGROUND      undef   Default background colour
  SELECTEDCOL     undef   Default colour of selected items
  BORDER              1   Display a border around the field
  BORDERCOL       undef   Foreground colour for border
  FOCUSSWITCH      "\t"   Characters which signify end of input
  TOPELEMENT          0   Index of element displayed on line 1
  LISTITEMS          []   List of list items
  MULTISEL            0   Whether or not multiple items can be 
                          selected
  TOGGLE         "\n\s"   What input toggles selection of the 
                          current item
  VALUE         0 or []   Index(es) of selected items
  CURSORPOS           0   Index of the item the cursor is 
                          currently on

The B<CAPTION> is only valid when the B<BORDER> is enabled.  If the border
is disabled, the field will be underlined, provided the terminal supports it.

The value of B<VALUE> should be an array reference when in multiple
selection mode.  Otherwise it should either undef or an integer.

=cut

sub _conf {
  # Validates and initialises the new ListBox object.
  #
  # Usage:  $self->_conf(%conf);

  my $self = shift;
  my %conf = ( 
    COLUMNS     => 10,
    LINES       => 3,
    VALUE       => undef,
    INPUTFUNC   => \&scankey,
    BORDER      => 1,
    FOCUSSWITCH => "\t",
    TOPELEMENT  => 0,
    LISTITEMS   => [],
    MULTISEL    => 0,
    VALUE       => undef,
    CURSORPOS   => 0,
    TOGGLE      => "\n ",
    @_ 
    );
  my @required = qw(X Y);
  my $err = 0;

  # Check for required arguments
  foreach (@required) { $err = 1 unless exists $conf{$_} };

  $conf{SELECTEDCOL} = lc($conf{SELECTEDCOL}) if exists $conf{SELECTEDCOL};

  # Make sure no errors are returned by the parent method
  $err = 1 unless $self->SUPER::_conf(%conf);

  # Update VALUE depending on selection mode
  $conf{VALUE} = [] if $conf{MULTISEL} and not exists $conf{VALUE};

  return $err == 0 ? 1 : 0;
}

=head2 draw

  $lb->draw($mwh, 1);

The draw method renders the list box in its current state.  This
requires a valid handle to a curses window in which it will render
itself.  The optional second argument, if true, will cause the field's
text cursor to be rendered as well.

=cut

sub _border {
  my $self = shift;
  my $dwh = shift;
  my $conf = $self->{CONF};
  my ($top, $pos, $lines, $cols, $items) = 
    @$conf{qw(TOPELEMENT CURSORPOS LINES COLUMNS LISTITEMS)};
  my ($y, $x);

  # Render the box
  $self->SUPER::_border($dwh);

  # Adjust the cursor position if it's out of whack
  $pos = $#{$items} if $pos > $#{$items};
  while ($pos - $top > $lines - 1) { $top++ };
  while ($top > $pos) { --$top };

  # Render up/down arrows as needed
  $dwh->getmaxyx($y, $x);
  $dwh->addch(0, $x - 2, ACS_UARROW) if $top > 0;
  $dwh->addch($y - 1, $x - 2, ACS_DARROW) if 
    $top + $lines < @$items ;

  # Restore the default settings
  $self->_restore($dwh);

  # Save any massaged values
  @$conf{qw(TOPELEMENT CURSORPOS)} = ($top, $pos);
}

sub _content {
  my $self = shift;
  my $dwh = shift;
  my $conf = $self->{CONF};
  my ($pos, $top, $border, $cols, $lines, $sel) = 
    @$conf{qw(CURSORPOS TOPELEMENT BORDER COLUMNS LINES VALUE)};
  my @items = @{$$conf{LISTITEMS}};
  my (@colours, $i);

  # Turn on underlining (terminal-dependent) if no border is used
  $dwh->attron(A_UNDERLINE) unless $border;

  # Display the items on the list
  if (scalar @items) {

    # Display the items
    for $i ($top..$#items) {
      @colours = @$conf{qw(FOREGROUND BACKGROUND)};
      if (defined $sel &&
        grep /^$i$/, (ref($sel) eq 'ARRAY' ? @$sel : $sel)) {

        # Set the colour for selected items
        if (exists $$conf{SELECTEDCOL}) {
          $colours[0] = $$conf{SELECTEDCOL};
          $dwh->attrset(COLOR_PAIR(select_colour(
            @$conf{qw(SELECTEDCOL BACKGROUND)})));
          $dwh->attron(A_BOLD) if $$conf{SELECTEDCOL} eq 'yellow';

        # Bold it if no selection colour was defined
        } else {
          $dwh->attron(A_BOLD);
        }
      }

      # Print the item
      $dwh->addstr($i - $top, 0, substr($items[$i], 0, $cols));

      # Underline the line if there's no border
      $dwh->chgat($i - $top, 0, $cols, A_UNDERLINE, select_colour(@colours), 
        0) unless $border;

      # Restore the default settings
      $self->_restore($dwh);
    }
  }
}

sub _cursor {
  my $self = shift;
  my $dwh = shift;
  my $conf = $self->{CONF};
  my ($pos, $top, $cols, $sel) = 
    @$conf{qw(CURSORPOS TOPELEMENT COLUMNS VALUE)};
  my $fg;

  # Determine the foreground colour
  if (defined $sel && exists $$conf{SELECTEDCOL} &&
    grep /^$pos$/, (ref($sel) eq 'ARRAY' ? @$sel : $sel)) {
    $fg = $$conf{SELECTEDCOL};
  } else {
    $fg = $$conf{FOREGROUND};
  }

  # Display the cursor
  $dwh->chgat($pos - $top, 0, $cols, A_STANDOUT, select_colour(
    $fg, $$conf{BACKGROUND}), 0);

  # Restore the default settings
  $self->_restore($dwh);
}

sub input_key {
  # Process input a keystroke at a time.
  #
  # Usage:  $self->input_key($key);

  my $self = shift;
  my $in = shift;
  my $conf = $self->{CONF};
  my $sel = $$conf{VALUE};
  my @items = @{$$conf{LISTITEMS}};
  my $pos = $$conf{CURSORPOS};
  my $re = $$conf{TOGGLE};
  my $np;

  # Process special keys
  if ($in eq KEY_UP) {
    if ($pos > 0) {
      --$pos;
    } else {
      beep;
    }
  } elsif ($in eq KEY_DOWN) {
    if ($pos < $#items) {
      ++$pos;
    } else {
      beep;
    }
  } elsif ($in eq KEY_HOME || $in eq KEY_END || $in eq KEY_PPAGE ||
    $in eq KEY_NPAGE) {

    if (scalar @items) {
      if ($in eq KEY_HOME) {
        beep if $pos == 0;
        $pos = 0;
      } elsif ($in eq KEY_END) {
        beep if $pos == $#items;
        $pos = $#items;
      } elsif ($in eq KEY_PPAGE) {
        beep if $pos == 0;
        $pos -= $$conf{LINES};
        $pos = 0 if $pos < 0;
      } elsif ($in eq KEY_NPAGE) {
        beep if $pos == $#items;
        $pos += $$conf{LINES};
        $pos = $#items if $pos > $#items;
      }
    } else {
      beep;
    }

  # Process normal key strokes
  } else {
    
    # Exit out if there's no list to apply strokes to
    return unless scalar @items;

    if ($in =~ /^[$re]$/) {
      if ($$conf{MULTISEL}) {
        if (grep /^$pos$/, @$sel) {
          @$sel = grep  !/^$pos$/, @$sel;
        } else {
          push(@$sel, $pos);
        }
      } else {
        $sel = $pos;
      }
    } elsif ($in =~ /^[[:print:]]$/ && $pos < $#items) {
      $pos = $self->match_key($in);
    } else {
      beep;
    }
  }

  # Save the changes
  @$conf{qw(VALUE CURSORPOS)} = ($sel, $pos);
}

sub match_key {
  my $self = shift;
  my $in = shift;
  my $conf = $self->{CONF};
  my @items = @{$$conf{LISTITEMS}};
  my $pos = $$conf{CURSORPOS};
  my $np;

  $np = $pos + 1;
  while ($np <= $#items && $items[$np] !~ /^\Q$in\E/i) { $np++ };
  $pos = $np if $np <= $#items and $items[$np] =~ /^\Q$in\E/i;

  return $pos;
}

1;

=head1 HISTORY

=over

=item 1999/12/29 -- Original list box widget in functional model

=item 2001/07/05 -- First incarnation in OO architecture

=back

=head1 AUTHOR/COPYRIGHT

(c) 2001 Arthur Corliss (corliss@digitalmages.com)

=cut

