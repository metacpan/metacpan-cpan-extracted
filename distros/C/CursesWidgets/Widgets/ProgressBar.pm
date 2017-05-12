# Curses::Widgets::ProgressBar.pm -- Progress Bar Widgets
#
# (c) 2001, Arthur Corliss <corliss@digitalmages.com>
#
# $Id: ProgressBar.pm,v 1.103 2002/11/03 23:40:04 corliss Exp corliss $
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

Curses::Widgets::ProgressBar - Progress Bar Widgets

=head1 MODULE VERSION

$Id: ProgressBar.pm,v 1.103 2002/11/03 23:40:04 corliss Exp corliss $

=head1 SYNOPSIS

  use Curses::Widgets::ProgressBar;

  $progress = Curses::Widgets::ProgessBar->({
    CAPTION     => 'Progress',
    CAPTIONCOL  => 'yellow',
    LENGTH      => 10,
    VALUE       => 0,
    FOREGROUND  => undef,
    BACKGROUND  => 'black',
    BORDER      => 1,
    BORDERCOL   => undef,
    HORIZONTAL  => 1,
    X           => 1,
    Y           => 1,
    MIN         => 0,
    MAX         => 100,
    });

  $progress->draw($mwh);

  $progress->input(5);

  See the Curses::Widgets pod for other methods.

=head1 REQUIREMENTS

=over

=item Curses

=item Curses::Widgets

=back

=head1 DESCRIPTION

Curses::Widgets::ProgressBar provides simplified OO access to Curses-based
progress bar.  Each object maintains it's own state information.

Note that this widget is designed for rendering, not interactive input.  The
application should update the the value of the bar by either calling the
B<input> method, which will add the passed value to the widget's current
value, or by setting the value directly via the B<setField> method.

=cut

#####################################################################
#
# Environment definitions
#
#####################################################################

package Curses::Widgets::ProgressBar;

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

  $progress = Curses::Widgets::ProgressBar->({
    CAPTION     => 'Progress',
    CAPTIONCOL  => 'yellow',
    LENGTH      => 10,
    VALUE       => 0,
    FOREGROUND  => undef,
    BACKGROUND  => 'black',
    BORDER      => 1,
    BORDERCOL   => undef,
    HORIZONTAL  => 1,
    X           => 1,
    Y           => 1,
    MIN         => 0,
    MAX         => 100,
    });

The new method instantiates a new Progress Bar object.  The only mandatory
key/value pairs in the configuration hash are B<X> and B<Y>.  
All others have the following defaults:

  Key         Default   Description
  ============================================================
  CAPTION       undef   Caption superimposed on border
  CAPTIONCOL    undef   Foreground colour for caption text
  LENGTH           10   Number of columns for the bar
  VALUE             0   Current value
  FOREGROUND    undef   Default foreground colour
  BACKGROUND    undef   Default blackground colour
  BORDER            1   Display border around the set
  BORDERCOL     undef   Foreground colour for border
  HORIZONTAL        1   Horizontal orientation for bar
  MIN               0   Low value for bar (0%)
  MAX             100   High vlaue for bar (100%)

Setting the value will change the length of the bar, based on the bounds set
with B<MIN> and B<MAX>.  The B<CAPTION> is only rendered on the border of a
horizontal progress bar.

=cut

sub _conf {
  # Validates and initialises the new TextField object.
  #
  # Usage:  $self->_conf(%conf);

  my $self = shift;
  my %conf = (
    CAPTION     => undef,
    LENGTH      => 10,
    VALUE       => 0,
    BORDER      => 1,
    HORIZONTAL  => 1,
    MIN         => 0,
    MAX         => 100,
    @_ 
    );
  my @required = qw(X Y);
  my $err = 0;

  $conf{COLUMNS} = $conf{HORIZONTAL} ? $conf{LENGTH} : 0;

  # Check for required arguments
  foreach (@required) { $err = 1 unless exists $conf{$_} };

  $conf{VALUE} = $conf{MIN} if $conf{VALUE} < $conf{MIN};

  $err = 1 unless $self->SUPER::_conf(%conf);

  return $err == 0 ? 1 : 0;
}

=head2 draw

  $progress->draw($mwh);

The draw method renders the progress bar in its current state.  This
requires a valid handle to a curses window in which it will render
itself.

=cut

sub _geometry {
  my $self = shift;
  my $conf = $self->{CONF};
  my @rv;

  @rv = @$conf{qw(HORIZONTAL LENGTH Y X)};
  @rv[0,1] = @rv[1,0] unless ($rv[0]);
  if ($$conf{BORDER}) {
    $rv[0] += 2;
    $rv[1] += 2;
  }

  return @rv;
}

sub _cgeometry {
  my $self = shift;
  my $conf = $self->{CONF};
  my @rv;

  @rv = @$conf{qw(HORIZONTAL LENGTH Y X)};
  @rv[0,1] = @rv[1,0] unless ($rv[0]);
  @rv[2,3] = (1, 1) if $$conf{BORDER};

  return @rv;
}

sub _content {
  my $self = shift;
  my $dwh = shift;
  my $conf = $self->{CONF};
  my ($hz, $value, $length, $min, $max) = 
    @$conf{qw(HORIZONTAL VALUE LENGTH MIN MAX)};
  my ($i, $j, $k, $l);

  # Draw the bar
  $i = ($max - $min) / $length;
  $j = $min;
  $l = $hz ? 0 : $length - 1;
  $k = 0;
  while ($j < $value) {
    $dwh->addch($k, $l, ACS_CKBOARD);
    $hz ? ++$l : --$k;
    $j += $i;
  }
  $dwh->attroff(A_BOLD);
}

sub input_key {
  # Since this widget doesn't handle interactive input,
  # this routine does nothing.
}

sub execute {
  # Since this widget doesn't handle interactive input,
  # this routine does nothing.
}

=head2 input

  $progress->input(5);

The argument is added to the progress bar's current value.

=cut

sub input {
  my $self = shift;
  my $value = shift || 0;
  my $conf = $self->{CONF};

  $$conf{VALUE} += $value;
}

1;

=head1 HISTORY

=over

=item 2001/07/05 -- First implementation

=back

=head1 AUTHOR/COPYRIGHT

(c) 2001 Arthur Corliss (corliss@digitalmages.com)

=cut

