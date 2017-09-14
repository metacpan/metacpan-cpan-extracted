#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010, 2011, 2012, 2014, 2015, 2016, 2017 Kevin Ryde

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

use strict;
use warnings;
use Test::More 0.82;

if (! eval { require GT::DB; }) {
  plan skip_all => "GT::DB not available -- $@";
}
plan tests => 4;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

require GT::DB::Chart;

# no version
diag "GT::DB version ",GT::DB->VERSION;

#------------------------------------------------------------------------------
# VERSION

my $want_version = 263;
is ($GT::DB::Chart::VERSION, $want_version, 'VERSION variable');
is (GT::DB::Chart->VERSION,  $want_version, 'VERSION class method');
{ ok (eval { GT::DB::Chart->VERSION($want_version); 1 },
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { GT::DB::Chart->VERSION($check_version); 1 },
      "VERSION class check $check_version");
}

exit 0;
