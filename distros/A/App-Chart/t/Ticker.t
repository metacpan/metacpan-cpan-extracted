#!/usr/bin/perl -w

# Copyright 2007, 2008, 2009, 2010, 2011, 2012 Kevin Ryde

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

use Test::More 0.82 tests => 4;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }
use AppChartTestHelpers;

# uncomment this to run the ### lines
#use Smart::Comments;

require App::Chart::Gtk2::Ticker;


#------------------------------------------------------------------------------

require Glib;
Glib->VERSION (1.220); # for TreeModelFilter callback not leaking

require Gtk2;
Gtk2->disable_setlocale;  # leave LC_NUMERIC alone for version nums
my $have_display = Gtk2->init_check;

SKIP: {
  $have_display or skip 'due to no DISPLAY available', 2;

  {
    my $ticker = App::Chart::Gtk2::Ticker->new;
    require Scalar::Util;
    Scalar::Util::weaken ($ticker);
    is ($ticker, undef, 'garbage collect after weaken');
  }
  {
    my $ticker = App::Chart::Gtk2::Ticker->new;
    $ticker->menu;
    Scalar::Util::weaken ($ticker);
    is ($ticker, undef, 'garbage collect after weaken -- with menu');
  }
}

#------------------------------------------------------------------------------

# Test::Weaken 2.002 for "ignore"
my $have_test_weaken = eval "use Test::Weaken 2.002; 1";
if (! $have_test_weaken) { diag "Test::Weaken 2.002 not available -- $@"; }

# Test::Weaken::ExtraBits
my $have_test_weaken_extrabits = eval "use Test::Weaken::ExtraBits; 1";
if (! $have_test_weaken_extrabits) {
  diag "Test::Weaken::ExtraBits not available -- $@";
}

sub my_ignores {
  my ($ref) = @_;

  # Class_Singleton for App::Chart::Gtk2::SymlistList
  return (Test::Weaken::ExtraBits::ignore_Class_Singleton($ref)
          || AppChartTestHelpers::ignore_symlists($ref)
          || AppChartTestHelpers::ignore_global_dbi($ref)
          || AppChartTestHelpers::ignore_all_dbi($ref)
         );
}

SKIP: {
  $have_test_weaken
    or skip 'due to Test::Weaken 2.002 not available', 1;
  $have_test_weaken_extrabits
    or skip 'due to Test::Weaken::ExtraBits not available', 1;
  # display for some width calculations ...
  $have_display
    or skip 'due to no DISPLAY available', 1;

  my $leaks = Test::Weaken::leaks
    ({ constructor => sub {
         my $symlist = App::Chart::Gtk2::Symlist->new_from_key('favourites');
         my $ticker = App::Chart::Gtk2::Ticker->new (symlist => $symlist);
         $ticker->show;
         return $ticker;
       },
       ignore => \&my_ignores,
     });
  is ($leaks, undef, 'Test::Weaken deep garbage collection');
  if ($leaks) {
    diag "Test-Weaken ", explain $leaks;
  }
}

SKIP: {
  $have_test_weaken or skip 'due to Test::Weaken not available', 1;
  $have_display or skip 'due to no DISPLAY available', 1;

  require Test::Weaken::Gtk2;

  my $leaks = Test::Weaken::leaks
    ({ constructor => sub {
         my $ticker = App::Chart::Gtk2::Ticker->new;

         my $tickermodel = $ticker->get('model');
         my $childmodel = $tickermodel->get_model;
         # ### $tickermodel
         # ### $childmodel
         ### childmodel dbh: "$childmodel->{'dbh'}"
         ### childmodel sth: "$childmodel->{'sth'}->{'read'}"
         ### childmodel sth: $childmodel->{'sth'}->{'read'}

         my $toplevel = Gtk2::Window->new('toplevel');
         $toplevel->add($ticker);
         $toplevel->show_all;

         my $menu = $ticker->menu;

         return [ $toplevel,
                  $ticker,
                  $tickermodel,
                  $childmodel,
                  $menu,
                ];
       },
       destructor => \&Test::Weaken::Gtk2::destructor_destroy,
       contents => sub {
         my ($ref) = @_;
           ### ref: "$ref"
         if (Scalar::Util::blessed($ref)
             && ($ref->isa('DBI::db')
                 || $ref->isa('DBI::st'))) {
         }
         goto &Test::Weaken::Gtk2::contents_container
       },
       ignore => \&my_ignores,
     });
  is ($leaks, undef, 'Test::Weaken deep garbage collection -- with menu');
  if ($leaks) {
    diag "Test-Weaken ", explain $leaks;

    my $unfreed = $leaks->unfreed_proberefs;
    foreach my $proberef (@$unfreed) {
      diag "  unfreed $proberef";
    }
    foreach my $proberef (@$unfreed) {
      diag "  search $proberef";
      MyTestHelpers::findrefs($proberef);
    }
  }
}

exit 0;
