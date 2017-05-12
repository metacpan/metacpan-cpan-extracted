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


# load all modules with Test::UseAllModules, if that's available

use strict;
use warnings;
use Test::More;

# Test::UseAllModules 0.11 need import() run, or all_uses_ok() would throw
# an error, hence eval "use" here.
#
if (! eval 'use Test::UseAllModules; 1') {
  plan skip_all => "due to Test::UseAllModules not available ($@)";
}

use lib 't';
use MyTestHelpers;
MyTestHelpers::nowarnings();

Test::UseAllModules::all_uses_ok
  (except => ('^Finance::Quote::',
              '^GT::',
              '::GT',
              '::TA',
              '^Perl::Critic::',
              'RawDialog', # Gtk2::Ex::Datasheet::DBI 2.1 does '-init'
              'App::Chart::Gtk2::IndicatorModelGenerated', # not really a module
             ));

exit 0;
