# Curses::Widgets::Menu.pm -- Menu Widgets
#
# (c) 2001, Arthur Corliss <corliss@digitalmages.com>
#
# $Id: Menu.pm,v 1.103 2002/11/14 01:26:34 corliss Exp corliss $
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

Curses::Widgets::Menu - Menu Widgets

=head1 MODULE VERSION

$Id: Menu.pm,v 1.103 2002/11/14 01:26:34 corliss Exp corliss $

=head1 SYNOPSIS

  use Curses::Widgets::Menu;

  $menu = Curses::Widgets::Menu->new({
    COLUMNS     => 10,
    INPUTFUNC   => \&scankey,
    FOREGROUND  => undef,
    BACKGROUND  => 'black',
    FOCUSSWITCH => "\t",
    X           => 1,
    Y           => 1,
    MENUS       => {
      MENUORDER => [qw(File)],
      File => {
        ITEMORDER => [qw(Save Quit)],
        Save      => \&Save,
        Quit      => \&Quit,
      },
    CURSORPOS   => 'File',
    BORDER      => 1,
    });

  $menu->draw($mwh, 1);
  $menu->execute;

  See the Curses::Widgets pod for other methods.

=head1 REQUIREMENTS

=over

=item Curses

=item Curses::Widgets

=item Curses::Widgets::ListBox

=back

=head1 DESCRIPTION

Curses::Widgets::Menu provides simplified OO access to menus.  Each item in a
menu can be tied to a subroutine reference which is called when selected.

=cut

#####################################################################
#
# Environment definitions
#
#####################################################################

package Curses::Widgets::Menu;

use strict;
use vars qw($VERSION @ISA);
use Carp;
use Curses;
use Curses::Widgets;
use Curses::Widgets::ListBox;

($VERSION) = (q$Revision: 1.103 $ =~ /(\d+(?:\.(\d+))+)/);
@ISA = qw(Curses::Widgets);

#####################################################################
#
# Module code follows
#
#####################################################################

=head1 METHODS

=head2 new (inherited from Curses::Widgets)

  $menu = Curses::Widgets::Menu->new({
    INPUTFUNC   => \&scankey,
    FOREGROUND  => undef,
    BACKGROUND  => 'black',
    FOCUSSWITCH => "\t",
    MENUS       => {
      MENUORDER => [qw(File)],
      File      => {
        ITEMORDER => [qw(Save Quit)],
        Save      => \&Save,
        Quit      => \&Quit,
      },
    CURSORPOS   => 'File',
    BORDER      => 1,
    });

The new method instantiates a new Menu object.  The only mandatory
key/value pairs in the configuration hash are B<X> and B<Y>.  All others
have the following defaults:

  Key           Default  Description
  ============================================================
  INPUTFUNC   \&scankey  Function to use to scan for keystrokes
  FOREGROUND      undef  Default foreground colour
  BACKGROUND    'black'  Default background colour
  FOCUSSWITCH      "\t"  Characters which signify end of input
  MENUS              {}  Menu structure
  CURSORPOS          ''  Current position of the cursor
  BORDER              0  Avoid window borders

The B<MENUS> option is a hash of hashes, with each hash a separate menu, and
the constituent hashes being a Entry/Function pairs.  Each hash requires a
special key/value pair that determines the order of the items when displayed.
Each item is separated by two spaces.

=cut

sub _conf {
  # Validates and initialises the new Menu object.
  #
  # Internal use only.

  my $self = shift;
  my %conf = ( 
    INPUTFUNC     => \&scankey,
    FOREGROUND    => undef,
    BACKGROUND    => 'black',
    FOCUSSWITCH   => "\t",
    MENUS         => {MENUORDER => []},
    BORDER        => 0,
    EXIT          => 0,
    CURSORPOS     => '',
    @_ 
    );
  my $err = 0;

  # Set the default CURSORPOS if undefined
  $conf{CURSORPOS} = $conf{MENUS}{MENUORDER}[0] unless 
    defined $conf{CURSORPOS};

  # Make sure no errors are returned by the parent method
  $err = 1 unless $self->SUPER::_conf(%conf);

  # Get the updated conf hash
  %conf = ();
  %conf = %{$self->{CONF}};

  # Create a listbox as our popup menu
  $self->{LISTBOX} = Curses::Widgets::ListBox->new({
      X           => 0,
      Y           => 0,
      LISTITEMS   => [],
      FOREGROUND  => $conf{FOREGROUND},
      BACKGROUND  => $conf{BACKGROUND},
      LINES       => 3,
      COLUMNS     => 10,
      FOCUSSWITCH => "\n\e",
      INPUTFUNC   => $conf{INPUTFUNC},
    }) unless $err;

  return $err == 0 ? 1 : 0;
}

=head2 draw

  $menu->draw($mwh, 1);

The draw method renders the menu in its current state.  This
requires a valid handle to a curses window in which it will render
itself.  The optional second argument, if true, will cause the selection
cursor to be rendered as well.

=cut

sub draw {
  my $self = shift;
  my $mwh = shift;
  my $active = shift;
  my $conf = $self->{CONF};
  my ($y, $x);

  # Get the parent window's (max|beg)yx and save the info
  $mwh->getmaxyx($y, $x);
  $$conf{COLUMNS} = $x;
  $mwh->getbegyx($y, $x);
  $self->{BEGYX} = [$y, $x];

  # Call the parent's draw method
  return $self->SUPER::draw($mwh, $active);
}

sub _geometry {
  my $self = shift;
  my $conf = $self->{CONF};
  my @rv = (1, $$conf{COLUMNS}, 0, 0);

  if ($$conf{BORDER}) {
    $rv[1] -= 2;
    @rv[2,3] = (1, 1);
  }

  return @rv;
}

sub _cgeometry {
  my $self = shift;
  my $conf = $self->{CONF};
  my @rv = (1, $$conf{COLUMNS}, 0, 0);

  $rv[1] -= 2 if $$conf{BORDER};

  return @rv;
}

sub _border {
  # Make sure no one tries to call this on a menu
}

sub _caption {
  # Make sure no one tries to call this on a menu
}

sub _content {
  my $self = shift;
  my $dwh = shift;
  my $conf = $self->{CONF};
  my $menu = $$conf{MENUS};
  my $label;

  # Print the labels
  $label = join(' ', @{$$menu{MENUORDER}});
  carp ref($self), ":  Window not wide enough to display all menus!"
    if length($label) > $$conf{COLUMNS} - 2 * $$conf{BORDER};
  $dwh->addstr(0, 0, $label);
}

sub _cursor {
  my $self = shift;
  my $dwh = shift;
  my $conf = $self->{CONF};
  my $menu = $$conf{MENUS};
  my $pos = $$conf{CURSORPOS};
  my ($x, $label);

  # Get the x coordinate of the cursor and display the cursor
  $label = join(' ', @{$$menu{MENUORDER}});
  if ($label =~ /^(.*\b)\Q$pos\E\b/) {
    $x = length($1);
    $dwh->chgat(0, $x, length($pos), A_STANDOUT, select_colour(
      @$conf{qw(FOREGROUND BACKGROUND)}), 0);
  }

  $self->_restore($dwh);
}

=head2 popup

  $menu->popup;

This method causes the menu to be displayed.  Since, theoretically, the menu 
should never be seen unless it's being actively used, we will always assume 
that we need to draw a cursor on the list as well.

=cut

sub popup {
  my $self = shift;
  my $conf = $self->{CONF};
  my ($x, $y, $border) = (@$conf{qw(X Y)}, 1);
  my $lb = $self->{LISTBOX};
  my ($pwh, $items, $cp, $in, $rv, $l);

  # Calculate the border column/lines
  $border *= 2;

  # Create the popup window
  unless ($pwh = newwin($lb->getField('LINES') + $border, 
    $lb->getField('COLUMNS') + $border, $y, $x)) {
    carp ref($self), ":  Popup creation failed, possible geometry problems";
    return;
  }
  $pwh->keypad(1);

  # Render the list box
  $rv = $lb->execute($pwh);

  # Release the window
  $pwh->delwin;

  # Exit now if $rv is an escape
  return undef if $rv =~ /\e/;

  # Return the menu selection
  ($cp, $items) = $lb->getField(qw(CURSORPOS LISTITEMS));
  return $$items[$cp] if (defined $cp && scalar @$items);
}

sub input_key {
  # Process input a keystroke at a time.
  #
  # Internal use only.

  my $self = shift;
  my $in = shift;
  my $conf = $self->{CONF};
  my $lb = $self->{LISTBOX};
  my ($menus, $pos) = @$conf{qw(MENUS CURSORPOS)};
  my ($width, $height, $x, $y, $i, $j, $item, $rv, $sub, $l);

  return unless @{$$menus{MENUORDER}};

  # Get the current menu index
  $i = 0;
  while ($i < @{$$menus{MENUORDER}} && 
    $$menus{MENUORDER}[$i] ne $pos) { $i++ };
  $item = $$menus{MENUORDER}[$i];

  # Process special keys
  if ($in eq KEY_LEFT) {
    --$i;
    $i = $#{$$menus{MENUORDER}} if $i < 0;
  } elsif ($in eq KEY_RIGHT) {
    ++$i;
    $i = 0 if $i > $#{$$menus{MENUORDER}};

  # Display the Menu
  } elsif ($in eq KEY_DOWN || $in eq "\n") {

    # Calculate and set popup geometry
    $x = 0;
    for (0..$i) {
      $x += (length($$menus{MENUORDER}[$i]) + 2) if $_ != $i;
    }
    $x += 1 if $$conf{BORDER};
    $x += $self->{BEGYX}->[1];
    $y = $$conf{BORDER} ? 2 : 1;
    $y += $self->{BEGYX}->[0];
    @$conf{qw(Y X)} = ($y, $x);
    $l = 0;
    foreach (@{$$menus{$item}{ITEMORDER}}) {
      $l = length($_) if $l < length($_) };
    $lb->setField(
      LISTITEMS => [ @{$$menus{$item}{ITEMORDER}} ],
      LINES     => scalar @{$$menus{$item}{ITEMORDER}},
      COLUMNS   => $l,
      CURSORPOS => 0,
      );

    # Display the popup
    $rv = $self->popup;
    if (defined $rv) {
      $$conf{EXIT} = 1;

      # Execute the reference
      {
        no strict 'refs';

        $sub = $$menus{$item}{$rv};
        if (defined $sub) {
          &$sub();
        } else {
          carp ref($self), ":  undefined subroutine ($rv) call attempted";
        }
      }
    }

  # Process normal key strokes
  } else {
    beep();
  }

  # Save the changes
  $pos = $$menus{MENUORDER}[$i];
  $$conf{CURSORPOS} = $pos;
}

=head2 execute

  $menu->execute;

This method acts like the standard Curses::Widgets method of the same name,
with the exception being that selection of any menu item will also cause it to
exit (having already called the associated item subroutine).

=cut

sub execute {
  my $self = shift;
  my $mwh = shift;
  my $conf = $self->{CONF};
  my $menus = $$conf{MENUS};
  my $func = $$conf{'INPUTFUNC'} || \&scankey;
  my $regex = $$conf{'FOCUSSWITCH'};
  my $key;

  # Don't execute unless we have menus to interact with
  return unless @{$$menus{MENUORDER}};

  # Set the initial focused menu to the first in the list
  $$conf{CURSORPOS} = $$menus{MENUORDER}[0];
  $$conf{EXIT} = 0;

  $self->draw($mwh, 1);

  # Enter the scan loop
  while (1) {
    $key = &$func($mwh);
    if (defined $key) {
      if (defined $regex) {
        return $key if ($key =~ /^[$regex]/ || ($regex =~ /\t/ &&
          $key eq KEY_STAB));
      }
      $self->input_key($key);
    }
    return $key if $$conf{EXIT};
    $self->draw($mwh, 1);
  }
}

1;

=head1 HISTORY

=over

=item 2002/10/17 -- First implementation

=back

=head1 AUTHOR/COPYRIGHT

(c) 2001 Arthur Corliss (corliss@digitalmages.com)

=cut

