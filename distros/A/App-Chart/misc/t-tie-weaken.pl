#!/usr/bin/perl -w

# Copyright 2009, 2010 Kevin Ryde

# This file is part of Chart.
#
# Chart is free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation; either version 3, or (at your option) any later version.
#
# Chart is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
# details.
#
# You should have received a copy of the GNU General Public License along
# with Chart.  If not, see <http://www.gnu.org/licenses/>.

use Scalar::Util;

package MyTie;
use strict;
use warnings;
sub TIESCALAR { my $dummy = 1; return bless \$dummy,$_[0]; }
sub STORE {
  my ($self, $value) = @_;
  print "store ",$value//'undef',"\n";
}

package Gtk2::Ex::Dragger;
my $magical = 1;
tie $magical, 'MyTie';
$magical = [];
Scalar::Util::weaken ($magical);


my %x;
tie $x{'x'}, 'MyTie';
$x{'x'} = [];
Scalar::Util::weaken ($x{'x'});


package Tie::Scalar::StoreCallback;
use strict;
use warnings;

sub TIESCALAR {
  my ($class, $func, @args) = @_;
  my $scalar;
  return bless [ undef, $func, @args ], $class;
}
sub FETCH {
  my ($self) = @_;
  print "StoreCallback fetch\n";
  return $self->[0];
}
sub STORE {
  my ($self, $value) = @_;
  print "StoreCallback store ",$value//'undef',"\n";
  if (ref ($self->[0] = $value)) {
    Scalar::Util::weaken ($self->[0]);
  }
  $self->[1]->(@{$self}[2..$#$self]);
}

package main;
print "z\n";
my $z = 1;
tie $z, 'Tie::Scalar::StoreCallback',
  sub { print "stored now ",$z//'undef',"\n"; };
$z = [];
my $str = "$z";
print "fetch got $str\n";
Scalar::Util::weaken ($z);

