# Curses::Widgets::ComboBox.pm -- Text Field Widgets
#
# (c) 2001, Arthur Corliss <corliss@digitalmages.com>
#
# $Id: ComboBox.pm,v 1.103 2002/11/03 23:34:50 corliss Exp corliss $
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

Curses::Widgets::ComboBox - Combo-Box Widgets

=head1 MODULE VERSION

$Id: ComboBox.pm,v 1.103 2002/11/03 23:34:50 corliss Exp corliss $

=head1 SYNOPSIS

  use Curses::Widgets::ComboBox;

  $cb = Curses::Widgets::ComboBox->new({
    CAPTION     => 'Select',
    CAPTIONCOL  => 'yellow',
    COLUMNS     => 10,
    MAXLENGTH   => 255,
    MASK        => undef,
    VALUE       => '',
    INPUTFUNC   => \&scankey,
    FOREGROUND  => 'white',
    BACKGROUND  => 'black',
    BORDER      => 1,
    BORDERCOL   => 'red',
    FOCUSSWITCH => "\t\n",
    CURSORPOS   => 0,
    TEXTSTART   => 0,
    PASSWORD    => 0,
    X           => 1,
    Y           => 1,
    READONLY    => 0,
    LISTITEMS   => [qw(foo bar wop)],
    });

  $cb->draw($mwh, 1);

  See the Curses::Widgets pod for other methods.

=head1 REQUIREMENTS

=over

=item Curses

=item Curses::Widgets

=item Curses::Widgets::TextField

=item Curses::Widgets::ListBox

=back

=head1 DESCRIPTION

Curses::Widgets::ComboBox provides simplified OO access to Curses-based
combo-boxes.  This widget essentially acts as text field widget, but upon a
KEY_DOWN or "\n", a drop-down list is displayed, and the item selected is put
in the text field as the value.

=cut

#####################################################################
#
# Environment definitions
#
#####################################################################

package Curses::Widgets::ComboBox;

use strict;
use vars qw($VERSION @ISA);
use Carp;
use Curses;
use Curses::Widgets;
use Curses::Widgets::TextField;
use Curses::Widgets::ListBox;

($VERSION) = (q$Revision: 1.103 $ =~ /(\d+(?:\.(\d+))+)/);
@ISA = qw(Curses::Widgets::TextField Curses::Widgets);

#####################################################################
#
# Module code follows
#
#####################################################################

=head1 METHODS

=head2 new (inherited from Curses::Widgets)

  $cb = Curses::Widgets::ComboBox->new({
    CAPTION     => 'Select',
    CAPTIONCOL  => 'yellow',
    COLUMNS     => 10,
    MAXLENGTH   => 255,
    MASK        => undef,
    VALUE       => '',
    INPUTFUNC   => \&scankey,
    FOREGROUND  => 'white',
    BACKGROUND  => 'black',
    BORDER      => 1,
    BORDERCOL   => 'red',
    FOCUSSWITCH => "\t\n",
    CURSORPOS   => 0,
    TEXTSTART   => 0,
    PASSWORD    => 0,
    X           => 1,
    Y           => 1,
    READONLY    => 0,
    LISTITEMS   => [qw(foo bar wop)],
    });

The new method instantiates a new ComboBox object.  The only mandatory
key/value pairs in the configuration hash are B<X> and B<Y>.  All others
have the following defaults:

  Key         Default   Description
  ============================================================
  CAPTION       undef   Caption superimposed on border
  CAPTIONCOL    undef   Foreground colour for caption text
  COLUMNS          10   Number of columns displayed
  MAXLENGTH       255   Maximum string length allowed
  MASK          undef   Not yet implemented
  VALUE            ''   Current field text
  INPUTFUNC \&scankey   Function to use to scan for keystrokes
  FOREGROUND    undef   Default foreground colour
  BACKGROUND    undef   Default background colour
  BORDER            1   Display a border around the field
  BORDERCOL     undef   Foreground colour for border
  FOCUSSWITCH  "\t\n"   Characters which signify end of input
  CURSORPOS         0   Starting position of the cursor
  TEXTSTART         0   Position in string to start displaying
  PASSWORD          0   Subsitutes '*' instead of characters
  READONLY          0   Prevents alteration to content
  LISTLINES         5   Number of lines to display at a time 
                        in the drop-down list
  LISTCOLUMNS[COLUMNS]  Width of the drop-down list.  Defaults 
                        to the same length specified for the 
                        CombBox widget
  LISTITEMS        []   Items listed in drop-down list

The B<CAPTION> is only valid when the B<BORDER> is enabled.  If the border
is disabled, the field will be underlined, provided the terminal supports it.

If B<MAXLENGTH> is undefined, no limit will be placed on the string length.

=cut

sub _conf {
  # Validates and initialises the new ComboBox object.
  #
  # Internal use only.

  my $self = shift;
  my %conf = ( 
    LISTLINES     => 5,
    FOCUSSWITCH   => "\t",
    LISTITEMS     => [],
    @_
    );
  my $err = 0;

  # Set the default list length to the field length if it
  # hasn't been defined
  $conf{LISTCOLUMNS} = $conf{COLUMNS} unless exists $conf{LISTLENGTH};

  # Make sure no errors are returned by the parent method
  $err = 1 unless $self->SUPER::_conf(%conf);

  # Get updated conf hash
  %conf = ();
  %conf = %{$self->{CONF}};

  # Create a list box object for the popup if no errors were encountered
  $self->{LISTBOX} = Curses::Widgets::ListBox->new({
      X           => 0,
      Y           => 0,
      LISTITEMS   => $conf{LISTITEMS},
      INPUTFUNC   => $conf{INPUTFUNC},
      BORDERCOL   => $conf{BORDERCOL},
      FOREGROUND  => $conf{FOREGROUND},
      BACKGROUND  => $conf{BACKGROUND},
      LINES       => $conf{LISTLINES},
      COLUMNS     => $conf{LISTCOLUMNS},
      FOCUSSWITCH => "\n\e",
      BORDER      => $conf{BORDER},
    }) unless $err;

  return $err == 0 ? 1 : 0;
}

=head2 draw (inherited from Curses::Widgets::TextField)

  $cb->draw($mwh, 1);

The draw method renders the text field in its current state.  This
requires a valid handle to a curses window in which it will render
itself.  The optional second argument, if true, will cause the field's
text cursor to be rendered as well.

=cut

sub _geometry {
  my $self = shift;
  my $conf = $self->{CONF};
  my @rv = @$conf{qw(LINES COLUMNS Y X)};

  if ($$conf{BORDER}) {
    $rv[0] += 2;
    $rv[1] += 4;
  } else {
    $rv[1]++;
  }

  return @rv;
}

sub _border {
  my $self = shift;
  my $dwh = shift;
  my $conf = $self->{CONF};
  my ($y, $x);

  # Get maxyx
  $dwh->getmaxyx($y, $x);

  # Set the colours
  $dwh->attrset(COLOR_PAIR(
    select_colour(@$conf{qw(BORDERCOL BACKGROUND)})));
  $dwh->attron(A_BOLD) if $$conf{BORDERCOL} eq 'yellow';

  # Border rendering
  if ($$conf{BORDER}) {

    # Draw the main box
    $self->SUPER::_border($dwh);

    # Draw the tee intersections and arrow
    $dwh->addch($y - 2, $x - 2, ACS_DARROW);
    $dwh->addch(0, $x - 3 , ACS_TTEE);
    $dwh->addch($y - 2, $x - 3, ACS_VLINE);
    $dwh->addch($y - 1, $x - 3, ACS_BTEE);

  # No border still requires the down-arrow
  } else {
    $dwh->addch(0, $x - 1, ACS_DARROW);
  }

  # Restore the default settings
  $self->_restore($dwh);
}

sub draw {
  my $self = shift;
  my $mwh = shift;
  my $active = shift;
  my ($by, $bx);

  # Get and store the window's beginning y & x
  $mwh->getbegyx($by, $bx);
  $self->{BEGYX} = [$by, $bx];

  # Call the parent draw
  return $self->SUPER::draw($mwh, $active);
}

=head2 popup

  $combo->popup;

This method causes the drop down list to be displayed.  Since, theoretically,
this list should never be seen unless it's being actively used, we will always
assume that we need to draw a cursor on the list as well.

=cut

sub popup {
  my $self = shift;
  my $conf = $self->{CONF};
  my ($x, $y, $border) = @$conf{qw(X Y BORDER)};
  my ($by, $bx) = @{$self->{BEGYX}};
  my $lb = $self->{LISTBOX};
  my ($pwh, $items, $cp, $in, $key);

  # Calculate the border column/lines
  $border *= 2;
  if ($border) {
    $y--;
  } else {
    $y++;
  }

  # Create the popup window
  unless ($pwh = newwin($$conf{LISTLINES} + $border, $$conf{LISTCOLUMNS} +
    $border, $y + $border + $by, $x + $border + $bx)) {
    carp ref($self), ":  Popup creation failed, possible geometry problems";
    return;
  }
  $pwh->keypad(1);

  # Render the list box
  $key = $lb->execute($pwh);

  # Release the window
  $pwh->delwin;

  # Place the selected listbox value into the textfield if user
  # pressed enter
  if ($key eq "\n") {
    ($cp, $items) = $lb->getField(qw(CURSORPOS LISTITEMS));
    $$conf{VALUE} = $$items[$cp] if (defined $cp && scalar @$items);
  }
}

sub input_key {
  # Process input a keystroke at a time.
  #
  # Internal use only.

  my $self = shift;
  my $in = shift;
  my $conf = $self->{CONF};

  # Handle only special keys that will pull down the list
  if ($in eq "\n") {
  } elsif ($in eq KEY_DOWN) {

    $self->popup;

  # Hand everything else to the text widget
  } else {
    $self->SUPER::input_key($in);
  }
}

1;

=head1 HISTORY

=over

=item 2001/12/09 -- First version of the combo box

=back

=head1 AUTHOR/COPYRIGHT

(c) 2001 Arthur Corliss (corliss@digitalmages.com) 

=cut

