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

use Test::More 0.82 tests => 5;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }
use AppChartTestHelpers;

require App::Chart::Gtk2::TickerMain;

#------------------------------------------------------------------------------

require Glib;
Glib->VERSION (1.220); # for TreeModelFilter callback not leaking

require Gtk2;
Gtk2->disable_setlocale;  # leave LC_NUMERIC alone for version nums
my $have_display = Gtk2->init_check;

SKIP: {
  $have_display or skip 'due to no DISPLAY available', 3;

  {
    my $main = App::Chart::Gtk2::TickerMain->new;
    $main->show;
    my $ticker = $main->get('ticker') or die;
    my $tickermodel = $ticker->get('model') or die;
    $main->destroy;
    MyTestHelpers::main_iterations();

    require Scalar::Util;
    Scalar::Util::weaken ($main);
    is ($main, undef, 'garbage collect after destroy');
    Scalar::Util::weaken ($ticker);
    is ($ticker, undef, 'garbage collect Ticker after destroy');

    Scalar::Util::weaken ($tickermodel);
    is ($tickermodel, undef, 'garbage collect TickerModel after destroy');
  }
}

#------------------------------------------------------------------------------

# Test::Weaken 3 for "contents"
my $have_test_weaken = eval "use Test::Weaken 3; 1";
if (! $have_test_weaken) { diag "Test::Weaken 3 not available -- $@"; }
diag "Glib->VERSION is ",Glib->VERSION;

# Test::Weaken::ExtraBits
my $have_test_weaken_extrabits = eval "use Test::Weaken::ExtraBits; 1";
if (! $have_test_weaken_extrabits) {
  diag "Test::Weaken::ExtraBits not available -- $@";
}

sub my_ignores {
  my ($ref) = @_;

  # Class_Singleton for App::Chart::Gtk2::SymlistList
  return (Test::Weaken::ExtraBits::ignore_Class_Singleton($ref)
          || Test::Weaken::ExtraBits::ignore_DBI_globals($ref)
          || AppChartTestHelpers::ignore_symlists($ref)
          || AppChartTestHelpers::ignore_global_dbi($ref)
          || AppChartTestHelpers::ignore_all_dbi($ref)
         );
}

SKIP: {
  $have_display or skip 'due to no DISPLAY available', 2;
  $have_test_weaken or skip 'due to Test::Weaken 3 not available', 2;
  $have_test_weaken_extrabits
    or skip 'due to Test::Weaken::ExtraBits not available', 1;

  require Test::Weaken::Gtk2;

  {
    my $leaks = Test::Weaken::leaks
      ({ constructor => sub {
           my $main = App::Chart::Gtk2::TickerMain->new;
           my $ticker = $main->get('ticker') or die;
           $main->show;
           return [ $main, $ticker->get('model') ];
         },
         destructor => \&Test::Weaken::Gtk2::destructor_destroy,
         contents => \&Test::Weaken::Gtk2::contents_container,
         ignore => \&my_ignores,
       });
    is ($leaks, undef, 'Test::Weaken deep garbage collection');
    if ($leaks) {
      diag "Test-Weaken ", explain $leaks;

      diag "toplevels ",Gtk2::Window->list_toplevels;
      my $unfreed = $leaks->unfreed_proberefs;
      foreach (@$unfreed) {
        diag "  unfreed $_";
      }
      foreach (@$unfreed) {
        diag "  seek unfreed $_";
        MyTestHelpers::findrefs($_);
      }
    }
  }

  {
    my $leaks = Test::Weaken::leaks
      ({ constructor => sub {
           my $main = App::Chart::Gtk2::TickerMain->new;
           my $ticker = $main->get('ticker') or die;
           $main->show_all;
           $ticker->signal_emit ('menu-popup', 0, 'centre');
           return [ $main, $ticker, $ticker->get('model')];
         },
         destructor => \&Test::Weaken::Gtk2::destructor_destroy,
         contents => \&Test::Weaken::Gtk2::contents_container,
         ignore => \&my_ignores,
       });
    is ($leaks, undef, 'Test::Weaken deep garbage collection -- with menu');
    if ($leaks) {
      diag "Test-Weaken ", explain $leaks;

      my $unfreed = $leaks->unfreed_proberefs;
      foreach (@$unfreed) {
        diag "  unfreed $_";
      }
      foreach (@$unfreed) {
        diag "seek unfreed $_";
        MyTestHelpers::findrefs($_);
      }
    }
  }
}

exit 0;
