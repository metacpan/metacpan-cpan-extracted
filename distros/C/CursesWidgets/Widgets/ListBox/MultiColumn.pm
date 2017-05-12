# Curses::Widgets::ListBox::MultiColumn.pm -- Multi-Column List Box Widgets
#
# (c) 2001, Arthur Corliss <corliss@digitalmages.com>
#
# $Id: MultiColumn.pm,v 0.1 2002/11/14 01:28:49 corliss Exp corliss $
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

Curses::Widgets::ListBox::MultiColumn - Multi-Column List Box Widgets

=head1 MODULE VERSION

$Id: MultiColumn.pm,v 0.1 2002/11/14 01:28:49 corliss Exp corliss $

=head1 SYNOPSIS

  use Curses::Widgets::ListBox::MultiColumn;

  $lb = Curses::Widgets::ListBox::MultiColumn->new({
    COLUMNS     => [0, 5, 10, 3, 3],
    LISTITEMS   => [@list],
    });

  $lb->draw($mwh, 1);

  See the Curses::Widgets pod for other methods.

=head1 REQUIREMENTS

=over

=item Curses

=item Curses::Widgets

=item Curses::Widgets::ListBox

=back

=head1 DESCRIPTION

Curses::Widgets::ListBox::MultiColumn is an extension of the standard
Curses::Widgets::ListBox that allows a list of columns, with each column a
specified width.

=cut

#####################################################################
#
# Environment definitions
#
#####################################################################

package Curses::Widgets::ListBox::MultiColumn;

use strict;
use vars qw($VERSION @ISA);
use Carp;
use Curses;
use Curses::Widgets;
use Curses::Widgets::ListBox;

($VERSION) = (q$Revision: 0.1 $ =~ /(\d+(?:\.(\d+))+)/);
@ISA = qw(Curses::Widgets::ListBox);

#####################################################################
#
# Module code follows
#
#####################################################################

=head1 METHODS

=head2 new (inherited from Curses::Widgets)

  $tm = Curses::Widgets::ListBox->new({
    COLUMNS     => [0, 5, 10, 3, 3],
    LISTITEMS   => [@list],
    HEADERS     => [@headers],
    HEADERCOLFG => 'white',
    HEADERCOLBG => 'green',
    BIGHEADER   => 1,
    });

All of the same key values apply here as they do for the parent class
Curses::Widgets::ListBox.  In addition, the following new keys are defined:

  Key           Default   Description
  ============================================================
  COLUMNS            []   Column widths
  LISTITEMS          []   List of list values
  HEADERS            []   Column header labels
  HEADERFGCOL     undef   Header foreground colour
  HEADERBGCOL     undef   Header background colour
  BIGHEADER           0   Use more graphics for the header
  KEYINDX             0   Index of key column

If headers are defined but one or both of the header colours are not, then
they will default to the widget fore and background.

B<NOTE>:  Headers take up more lines in addition to the border (one line for
the normal, small header, two lines for the larger).  You need to take that
into account when setting the geometry.  If no labels are passed in the
HEADERS array, no space will be used for the headers.

The B<KEYINDX> value is currently only used to match keystrokes against for
quick navigation.

=cut

sub _conf {
  # Validates and initialises the new ListBox object.
  #
  # Usage:  $self->_conf(%conf);

  my $self = shift;
  my %conf = (
    COLWIDTHS   => [10],
    KEYINDEX    => 0,
    HEADERS     => [],
    BIGHEADER   => 0,
    KEYINDX     => 0,
    @_
    );
  my $err = 0;
  my @required = qw(COLWIDTHS);

  # Check for required fields
  foreach (@required) { $err = 1 unless exists $conf{$_} };
  $err = 1 unless @{$conf{COLWIDTHS}};

  # Lowercase extra colours
  foreach (qw(HEADERFGCOL HEADERBGCOL)) { 
    $conf{$_} = lc($conf{$_}) if exists $conf{$_} };

  # Make sure no errors are returned by the parent method
  $err = 1 unless $self->SUPER::_conf(%conf);

  return $err == 0 ? 1 : 0;
}

=head2 draw

  $lb->draw($mwh, 1);

The draw method renders the list box in its current state.  This
requires a valid handle to a curses window in which it will render
itself.  The optional second argument, if true, will cause the field's
text cursor to be rendered as well.

=cut

sub _geometry {
  my $self = shift;
  my $conf = $self->{CONF};
  my @rv;

  @rv = $self->SUPER::_geometry;
  if (@{$$conf{HEADERS}}) {
    $rv[0]++;
    $rv[0]++ if $$conf{BIGHEADER};
  }

  return @rv;
}

sub _cgeometry {
  my $self = shift;
  my $conf = $self->{CONF};
  my @rv;

  @rv = $self->SUPER::_cgeometry;
  if (@{$$conf{HEADERS}}) {
    $rv[2]++;
    $rv[2]++ if $$conf{BIGHEADER};
  }

  return @rv;
}

sub _border {
  my $self = shift;
  my $dwh = shift;
  my $conf = $self->{CONF};
  my (@colours, $header, @headers, $i, $h);
  my ($y, $x);

  # Render the border
  $self->SUPER::_border($dwh);

  # Draw the headers if any were defined
  if (@{$$conf{HEADERS}}) {

    # Construct the header
    $i = -1;
    foreach (@{$$conf{COLWIDTHS}}) {
      ++$i;
      next unless $_;
      $h = $$conf{HEADERS}[$i] || '';
      $header .= substr($h, 0, $_);
      $header .= ' ' x ($_ - length($h)) if length($h) < $_;
      $header .= ' ';
    }
    chop $header;

    # Print the header
    $i = $$conf{BORDER} ? 1 : 0;
    $dwh->addstr($i, $i, substr($header, 0, $$conf{COLUMNS}));

    # Set the colours
    push(@colours, exists $$conf{HEADERFGCOL} ? $$conf{HEADERFGCOL} :
      $$conf{FOREGROUND});
    push(@colours, exists $$conf{HEADERBGCOL} ? $$conf{HEADERBGCOL} :
      $$conf{BACKGROUND});
    $dwh->chgat($i, $i, $$conf{COLUMNS}, $colours[0] eq 'yellow' ? A_BOLD :
      0, select_colour(@colours), 0);

    # Draw the big header graphics
    if ($$conf{BIGHEADER}) {

      # Use the border colours
      $dwh->attrset(COLOR_PAIR(
        select_colour(@$conf{qw(BORDERCOL BACKGROUND)})));
      $dwh->attron(A_BOLD) if $$conf{BORDERCOL} eq 'yellow';

      # Draw the lower line
      $dwh->getmaxyx($y, $x);
      for (0..($x - 1)) { $dwh->addch($i + 1, $_, ACS_HLINE) };

      # Draw the vertical lines and tees
      $h = 0;
      foreach (@{$$conf{COLWIDTHS}}) {
        $h += $_ + $i;
        last if $h > $$conf{COLUMNS};
        $dwh->addch(0, $h, ACS_TTEE) if $i == 1;
        $dwh->addch($i, $h, ACS_VLINE);
        $dwh->addch($i + 1, $h, ACS_BTEE);
      }
      if ($$conf{BORDER}) {
        $dwh->addch($i + 1, 0, ACS_LTEE);
        $dwh->addch($i + 1, $x - 1, ACS_RTEE);
      }
    }

    $self->_restore($dwh);
  }
}

sub _content {
  my $self = shift;
  my $dwh = shift;
  my $conf = $self->{CONF};
  my ($pos, $top, $border, $cols, $lines, $sel) = 
    @$conf{qw(CURSORPOS TOPELEMENT BORDER COLUMNS LINES VALUE)};
  my @items = @{$$conf{LISTITEMS}};
  my (@colours, $h, $i, $j, $item);

  # Turn on underlining (terminal-dependent) if no border is used
  $dwh->attron(A_UNDERLINE) unless $border;

  # Display the items on the list
  if (scalar @items) {

    # Display the items
    for $i ($top..$#items) {

      # Construct the header
      $j = -1;
      $item = '';
      foreach (@{$$conf{COLWIDTHS}}) {
        ++$j;
        next unless $_;
        $h = $items[$i][$j] || '';
        $item .= substr($h, 0, $_);
        $item .= ' ' x ($_ - length($h)) if length($h) < $_;
        $item .= ' ';
      }
      chop $item;

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
      $dwh->addstr($i - $top, 0, substr($item, 0, $cols));

      # Underline the line if there's no border
      $dwh->chgat($i - $top, 0, $cols, A_UNDERLINE, select_colour(@colours), 
        0) unless $border;

      # Restore the default settings
      $self->_restore($dwh);
    }
  }
}

sub match_key {
  my $self = shift;
  my $in = shift;
  my $conf = $self->{CONF};
  my @items = @{$$conf{LISTITEMS}};
  my ($pos, $indx) = @$conf{qw(CURSORPOS KEYINDX)};
  my $np;

  $np = $pos + 1;
  while ($np <= $#items && $items[$np][$indx] !~ /^\Q$in\E/i) { $np++ };
  $pos = $np if $np <= $#items and $items[$np][$indx] =~ /^\Q$in\E/i;

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

