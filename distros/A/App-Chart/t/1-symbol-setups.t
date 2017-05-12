#!/usr/bin/perl -w

# Copyright 2007, 2008, 2009, 2010, 2014 Kevin Ryde

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


# Load all suffix modules.

use strict;
use warnings;
use Test::More tests => 1;
use ExtUtils::Manifest;
use File::Basename;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

require App::Chart;

my $m = ExtUtils::Manifest::maniread();
my @filenames = grep {m{^lib/App/Chart/Suffix/.*pm$}} keys %$m;
diag "loading ", scalar(@filenames), " suffix modules";

foreach my $filename (@filenames) {
  my $suffix = File::Basename::basename ($filename, '.pm');
  my $symbol = 'FOO.' . $suffix;

  App::Chart::symbol_setups ($symbol);

  require App::Chart::TZ;
  if (! App::Chart::TZ->for_symbol ($symbol)) {
    die "no timezone for $symbol\n";
  }
}
ok(1);

exit 0;
