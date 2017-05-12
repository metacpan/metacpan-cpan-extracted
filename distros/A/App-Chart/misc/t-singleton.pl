#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010, 2011 Kevin Ryde

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

{
  package Foo;
  use strict;
  use warnings;
  use base 'Class::Singleton::Const';

  sub _new_instance {
    print "new instance\n";
    return {};
  }
}

my $x = Foo->instance;
print "$x\n";
print "$x\n";
require Scalar::Util;
Scalar::Util::weaken ($x);
print "$x\n";


exit 0;
