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

# Variable::Magic sees weakening set

use strict;
use warnings;
use Scalar::Util;
use Variable::Magic;
use Data::Dumper;

my $wizard = Variable::Magic::wizard
  (set => sub { my ($ref, $data) = @_;
                print "set\n";
                print Dumper($ref);
              });

my $a = [ 123 ];
my $x;
Variable::Magic::cast ($x, $wizard);
$x = $a;
print "weaken\n";
Scalar::Util::weaken ($x);
print "undef strong\n";
undef $a;
print "done\n";
exit 0;

