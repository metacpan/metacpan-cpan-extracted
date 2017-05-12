#!/usr/bin/perl -w

# Copyright 2009, 2010, 2016 Kevin Ryde

# This file is part of Chart.
#
# Chart is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Chart is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
# details.
#
# You should have received a copy of the GNU General Public License
# along with Chart.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;
use Scalar::Util;
use Gtk2 '-init';

package ZZ;
use strict;
use warnings;

sub new {
  my ($class, %self) = @_;
  return bless \%self, $class;
}

sub DESTROY {
  my ($self) = @_;
  print "ZZ DESTROY\n";
  my $widget = $self->{'widget'};
  if (! defined $widget) {
    print "  widget undef (ok)\n";
    return;
  }
  print $widget->window || 'undef',"\n";
}

package main;

my $z = ZZ->new;
my $global = Gtk2::ListStore->new ('Glib::String');

$z->{'widget'} = $global;
Scalar::Util::weaken ($z->{'widget'});

exit 0;

