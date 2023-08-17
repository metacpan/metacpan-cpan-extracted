#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010, 2011, 2012, 2014, 2015, 2016, 2017, 2018, 2019, 2020, 2023 Kevin Ryde

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

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

if (! eval { require Finance::Quote; }) {
  plan skip_all => "Finance::Quote not available -- $@";
}
plan tests => 4;

require Finance::Quote::Chart;

diag "Finance::Quote version ",Finance::Quote->VERSION;

#------------------------------------------------------------------------------
# VERSION

my $want_version = 271;
is ($Finance::Quote::Chart::VERSION, $want_version, 'VERSION variable');
is (Finance::Quote::Chart->VERSION,  $want_version, 'VERSION class method');
{ ok (eval { Finance::Quote::Chart->VERSION($want_version); 1 },
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Finance::Quote::Chart->VERSION($check_version); 1 },
      "VERSION class check $check_version");
}

#------------------------------------------------------------------------------

require Finance::Quote;
my $q = Finance::Quote->new ('Chart');
my %quotes = $q->fetch('chartprog','BHP.AX','RS.WCE');

exit 0;
