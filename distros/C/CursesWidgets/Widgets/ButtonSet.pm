# Curses::Widgets::ButtonSet.pm -- Button Set Widgets
#
# (c) 2001, Arthur Corliss <corliss@digitalmages.com>
#
# $Id: ButtonSet.pm,v 1.103 2002/11/03 23:31:26 corliss Exp corliss $
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

Curses::Widgets::ButtonSet - Button Set Widgets

=head1 MODULE VERSION

$Id: ButtonSet.pm,v 1.103 2002/11/03 23:31:26 corliss Exp corliss $

=head1 SYNOPSIS

  use Curses::Widgets::ButtonSet;

  $btns = Curses::Widgets::ButtonSet->({
    LENGTH      => 10,
    VALUE       => 0,
    INPUTFUNC   => \&scankey,
    FOREGROUND  => 'white',
    BACKGROUND  => 'black',
    BORDER      => 1,
    BORDERCOL   => 'red',
    FOCUSSWITCH => "\t\n",
    HORIZONTAL  => 1,
    PADDING     => 1,
    X           => 1,
    Y           => 1,
    LABELS      => [qw(OK CANCEL)],
    });

  $btns->draw($mwh, 1);

  See the Curses::Widgets pod for other methods.

=head1 REQUIREMENTS

=over

=item Curses

=item Curses::Widgets

=back

=head1 DESCRIPTION

Curses::Widgets::ButtonSet provides simplified OO access to Curses-based
button sets.  Each object maintains it's own state information.

=cut

#####################################################################
#
# Environment definitions
#
#####################################################################

package Curses::Widgets::ButtonSet;

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

  $btns = Curses::Widgets::ButtonSet->({
    LENGTH      => 10,
    VALUE       => 0,
    INPUTFUNC   => \&scankey,
    FOREGROUND  => 'white',
    BACKGROUND  => 'black',
    BORDER      => 1,
    BORDERCOL   => 'red',
    FOCUSSWITCH => "\t\n",
    HORIZONTAL  => 1,
    PADDING     => 1,
    X           => 1,
    Y           => 1,
    LABELS      => [qw(OK CANCEL)],
    });

The new method instantiates a new ButtonSet object.  The only mandatory
key/value pairs in the configuration hash are B<X>, B<Y>, and B<LABELS>.  All
others have the following defaults:

  Key         Default    Description
  ============================================================
  LENGTH             10  Number of columns for each button label
  VALUE               0  Button selected (0-based indexing)
  INPUTFUNC   \&scankey  Function to use to scan for keystrokes
  FOREGROUND      undef  Default foreground colour
  BACKGROUND      undef  Default blackground colour
  BORDER              1  Display border around the set
  BORDERCOL       undef  Foreground colour for border
  FOCUSSWITCH    "\t\n"  Characters which signify end of input
  HORIZONTAL          1  Horizontal orientation for set
  PADDING             1  Number of spaces between buttons

The last option, B<PADDING>, is only applicable to horizontal sets without
borders.

=cut

sub _conf {
  # Validates and initialises the new TextField object.
  #
  # Usage:  $self->_conf(%conf);

  my $self = shift;
  my %conf = ( 
    LENGTH      => 10,
    VALUE       => 0,
    INPUTFUNC   => \&scankey,
    BORDER      => 1,
    FOCUSSWITCH => "\t\n",
    HORIZONTAL  => 1,
    PADDING     => 1,
    @_ 
    );
  my @required = qw(X Y LABELS);
  my $err = 0;
  my ($cols, $lines, $i);

  # Check for required arguments
  foreach (@required) { $err = 1 unless exists $conf{$_} };

  # Calculate the derived window dimensions
  $conf{LENGTH} += 2 unless $conf{BORDER};
  if ($conf{HORIZONTAL}) {
    $cols = $conf{LENGTH} * @{$conf{LABELS}};
    $i = 0;
    $i += $conf{PADDING} if ($conf{PADDING} && ! $conf{BORDER});
    $i++ if $conf{BORDER};
    $cols += (@{$conf{LABELS}} - 1) * $i;
    $lines = 1;
  } else {
    $cols = $conf{LENGTH};
    $lines = @{$conf{LABELS}};
    $lines += $conf{BORDER} ? @{$conf{LABELS}} - 1 : (@{$conf{LABELS}} - 1) *
      $conf{PADDING};
  }
  $conf{COLUMNS} = $cols;
  $conf{LINES} = $lines;

  # Make sure the parent class didn't generate any errors
  $err = 1 unless $self->SUPER::_conf(%conf);

  return $err == 0 ? 1 : 0;
}

=head2 draw

  $btns->draw($mwh, 1);

The draw method renders the button set in its current state.  This
requires a valid handle to a curses window in which it will render
itself.  The optional second argument, if true, will cause the set's
selected button to be rendered in standout mode (inverse video).

=cut

sub _border {
  my $self = shift;
  my $dwh = shift;
  my $conf = $self->{CONF};
  my ($y, $x, $hz, $value, $length, $cols, $lines) = 
    @$conf{qw(Y X HORIZONTAL VALUE LENGTH COLUMNS LINES)};
  my @labels = @{ $$conf{LABELS} };
  my $border = $$conf{BORDER};
  my ($i, $j, $l);

  # Draw the border
  if ($border) {
    if (defined $$conf{BORDERCOL}) {
      $dwh->attrset(COLOR_PAIR(
        select_colour(@$conf{qw(BORDERCOL BACKGROUND)})));
      $dwh->attron(A_BOLD) if $$conf{BORDERCOL} eq 'yellow';
    }
    $dwh->box(ACS_VLINE, ACS_HLINE);
    if ($hz) {
      $i = $length + 1;
      until ($i > $cols) {
        $dwh->addch(0, $i, ACS_TTEE);
        $dwh->addch(1, $i, ACS_VLINE);
        $dwh->addch(2, $i, ACS_BTEE);
        $i += ($length + 1);
      }
    } else {
      $i = 2;
      until ($i > $lines) {
        $dwh->addch($i, 0, ACS_LTEE);
        for ($j = 1; $j <= $length; $j++) {
          $dwh->addch($i, $j, ACS_HLINE) };
        $dwh->addch($i, $length + 1, ACS_RTEE);
        $i += 2;
      }
    }
    $dwh->attroff(A_BOLD);
  }

  $self->_restore($dwh);
}

sub _caption {
  # We won't be needing this method, and I don't want anyone using it by
  # accident.
}

sub _content {
  my $self = shift;
  my $dwh = shift;
  my $conf = $self->{CONF};
  my ($hz, $value, $length)  = @$conf{qw(HORIZONTAL VALUE LENGTH)};
  my @labels = @{$$conf{LABELS}};
  my ($i, $j, $l, $offset);
  my $z = 0;

  # Enforce a sane cursor position
  if ($$conf{VALUE} > $#labels) {
    $$conf{VALUE} = $#labels;
  } elsif ($$conf{VALUE} < 0) {
    $$conf{VALUE} = 0;
  }

  # Calculate the cell offset
  $offset = $$conf{BORDER} ?  1 : ($$conf{PADDING} ? $$conf{PADDING} : 0);

  # Draw the labels
  foreach (@labels) {
    $_ = substr($_, 0, $length);
    if (length($_) < $length - 1) {
      $i = int(($length - length($_)) / 2);
      unless ($$conf{BORDER}) {
        $i--;
        $_ = ' ' x $i . $_ . ' ' x ($length - (length($_) + $i + 2));
        $_ = "<$_>";
        $i = 0;
      }
    }
    if ($hz) {
      $dwh->addstr(0, $z + $i, $_);
      $z += $offset + $length;
    } else {
      $dwh->addstr($z, $i, $_);
      $z += $offset + 1;
    }
  }
}

sub _cursor {
  my $self = shift;
  my $dwh = shift;
  my $conf = $self->{CONF};
  my $label = $$conf{LABELS}->[$$conf{VALUE}];
  my ($length, $hz) = @$conf{qw(LENGTH HORIZONTAL)};
  my ($y, $x) = (0, 0);
  my ($offset);

  # Calculate the cell offset
  $offset = $$conf{BORDER} ?  1 : ($$conf{PADDING} ? $$conf{PADDING} : 0);

  # Set the coordinates
  if ($hz) {
    $offset = $$conf{VALUE} ? $$conf{VALUE} * $length + $$conf{VALUE} * 
      $offset : 0;
    $x = $offset;
  } else {
    $offset = $$conf{VALUE} ? $$conf{VALUE} + $$conf{VALUE} * $offset : 0;
    $y = $offset;
  }
  # Display the cursor
  $dwh->chgat($y, $x, $length, A_STANDOUT, 
    select_colour(@$conf{qw(FOREGROUND BACKGROUND)}), 0);

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
  my ($value, $hz) = @$conf{qw(VALUE HORIZONTAL)};
  my $num = scalar @{ $$conf{LABELS} };

  if ($hz) {
    if ($in eq KEY_RIGHT) {
      ++$value;
      $value = 0 if $value == $num;
    } elsif ($in eq KEY_LEFT) {
      --$value;
      $value = ($num - 1) if $value == -1;
    } else {
      beep;
    }
  } else {
    if ($in eq KEY_UP) {
      --$value;
      $value = ($num - 1) if $value == -1;
    } elsif ($in eq KEY_DOWN) {
      ++$value;
      $value = 0 if $value == $num;
    } else {
      beep;
    }
  }

  $$conf{VALUE} = $value;
}

1;

=head1 HISTORY

=over

=item 1999/12/29 -- Original button set widget in functional model

=item 2001/07/05 -- First incarnation in OO architecture

=back

=head1 AUTHOR/COPYRIGHT

(c) 2001 Arthur Corliss (corliss@digitalmages.com)

=cut

