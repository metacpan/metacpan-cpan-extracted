# Curses::Widgets::Label.pm -- Label Widgets
#
# (c) 2001, Arthur Corliss <corliss@digitalmages.com>
#
# $Id: Label.pm,v 1.102 2002/11/03 23:36:21 corliss Exp corliss $
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

Curses::Widgets::Label - Label Widgets

=head1 MODULE VERSION

$Id: Label.pm,v 1.102 2002/11/03 23:36:21 corliss Exp corliss $

=head1 SYNOPSIS

  use Curses::Widgets::Label;

  $lbl = Curses::Widgets::Label->new({
    COLUMNS      => 10,
    LINES       => 1,
    VALUE       => 'Name:',
    FOREGROUND  => undef,
    BACKGROUND  => 'black',
    X           => 1,
    Y           => 1,
    ALIGNMENT   => 'R',
    });

  $tf->draw($mwh);

  See the Curses::Widgets pod for other methods.

=head1 REQUIREMENTS

=over

=item Curses

=item Curses::Widgets

=back

=head1 DESCRIPTION

Curses::Widgets::Label provides simplified OO access to Curses-based
single or multi-line labels.

=cut

#####################################################################
#
# Environment definitions
#
#####################################################################

package Curses::Widgets::Label;

use strict;
use vars qw($VERSION @ISA);
use Carp;
use Curses;
use Curses::Widgets;

($VERSION) = (q$Revision: 1.102 $ =~ /(\d+(?:\.(\d+))+)/);
@ISA = qw(Curses::Widgets);

#####################################################################
#
# Module code follows
#
#####################################################################

=head1 METHODS

=head2 new (inherited from Curses::Widgets)

  $lbl = Curses::Widgets::Label->new({
    COLUMNS      => 10,
    LINES       => 1,
    VALUE       => 'Name:',
    FOREGROUND  => undef,
    BACKGROUND  => 'black',
    X           => 1,
    Y           => 1,
    ALIGNMENT   => 'R',
    });

The new method instantiates a new Label object.  The only mandatory
key/value pairs in the configuration hash are B<X> and B<Y>.  All others
have the following defaults:

  Key         Default   Description
  ============================================================
  COLUMNS           10   Number of columns displayed
  LINES             1   Number of lines displayed
  VALUE            ''   Label text
  FOREGROUND    undef   Default foreground colour
  BACKGROUND    undef   Default background colour
  ALIGNMENT         L   'R'ight, 'L'eft, or 'C'entered

If the label is a multi-line label it will filter the current VALUE through
the Curses::Widgets::textwrap function to break it along whitespace and
newlines.

=cut

sub _conf {
  # Validates and initialises the new Label object.
  #
  # Usage:  $self->_conf(%conf);

  my $self = shift;
  my %conf = ( 
    COLUMNS     => 10,
    LINES       => 1,
    VALUE       => '',
    ALIGNMENT   => 'L',
    BORDER      => 0,
    @_ 
    );
  my @required = qw(X Y);
  my $err = 0;

  # Check for required arguments
  foreach (@required) { $err = 1 unless exists $conf{$_} };

  $conf{ALIGNMENT} = uc($conf{ALIGNMENT});

  # Make sure no errors are returned by the parent method
  $err = 1 unless $self->SUPER::_conf(%conf);

  return $err == 0 ? 1 : 0;
}

=head2 draw

  $tf->draw($mwh);

The draw method renders the text field in its current state.  This
requires a valid handle to a curses window in which it will render
itself.

=cut

sub _content {
  my $self = shift;
  my $dwh = shift;
  my $conf = $self->{CONF};
  my ($lines, $cols, $value) = 
    @$conf{qw(LINES COLUMNS VALUE)};
  my (@lines, $offset);

  # Get the lines
  @lines = textwrap($value, $cols);

  # Write the widget value
  foreach (0..$lines) {
    next unless defined $lines[$_];
    $offset = $$conf{ALIGNMENT} eq 'C' ?
      int(($$conf{COLUMNS} - length($lines[$_])) / 2) : 
      ($$conf{ALIGNMENT} eq 'R' ? 
      $$conf{COLUMNS} - length($lines[$_]) : 0);
    $offset = 0 if $offset < 0;
    $dwh->addstr(0 + $_, 0 + $offset, $lines[$_]) if $_ <= $#lines;
  }
}

# The following are overridden to make sure no one tries anything fancy with
# this widget.  ;-)

sub input_key {
  return;
}

sub execute {
 return;
}

1;

=head1 HISTORY

=over

=item 2002/10/18 -- First implementation

=back

=head1 AUTHOR/COPYRIGHT

(c) 2001 Arthur Corliss (corliss@digitalmages.com) 

=cut

