#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010, 2011, 2012 Kevin Ryde

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


use 5.008;
use strict;
use warnings;
use Test::More 0.82 tests => 3;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

require App::Chart::Gtk2::IntradayImage;
require Gtk2;
Gtk2->disable_setlocale;  # leave LC_NUMERIC alone for version nums
my $have_display = Gtk2->init_check;

{
  my $image = App::Chart::Gtk2::IntradayImage->new;
  require Scalar::Util;
  Scalar::Util::weaken ($image);
  is ($image, undef,
      'garbage collect after weaken');
}

#------------------------------------------------------------------------------

# Test::Weaken 2 for leaks() style
my $have_test_weaken = eval "use Test::Weaken 2; 1";
if (! $have_test_weaken) { diag "Test::Weaken 2 not available -- $@"; }

SKIP: {
  $have_test_weaken or skip 'due to no Test::Weaken available', 2;

  {
    my $leaks = Test::Weaken::leaks
      (sub { return App::Chart::Gtk2::IntradayImage->new });
    is ($leaks, undef, 'Test::Weaken deep garbage collection');
    if ($leaks) {
      diag "Test-Weaken ", explain $leaks;
    }
  }
  {
    my $leaks = Test::Weaken::leaks
      (sub { return App::Chart::Gtk2::IntradayImage->new
               (symbol => 'GM',
                mode => '1d')
             });
    is ($leaks, undef, 'Test::Weaken deep garbage collection, with symbol+mode');
    if ($leaks) {
      diag "Test-Weaken ", explain $leaks;
    }
  }
}

exit 0;
