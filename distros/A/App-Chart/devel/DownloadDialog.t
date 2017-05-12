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
use Test::More 0.82 tests => 2;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

require App::Chart::Gtk2::DownloadDialog;

#------------------------------------------------------------------------------

require Gtk2;
Gtk2->disable_setlocale;  # leave LC_NUMERIC alone for version nums
my $have_display = Gtk2->init_check;

SKIP: {
  $have_display or skip 'due to no DISPLAY available', 1;

  {
    my $dialog = App::Chart::Gtk2::DownloadDialog->new;
    require Scalar::Util;
    Scalar::Util::weaken ($dialog);
    $dialog->destroy;
    MyTestHelpers::main_iterations();
    is ($dialog, undef, 'garbage collect after destroy');
  }
}

#------------------------------------------------------------------------------

# Test::Weaken 3 for "contents"
my $have_test_weaken = eval "use Test::Weaken 3; 1";
if (! $have_test_weaken) { diag "Test::Weaken 3 not available -- $@"; }

# Test::Weaken::ExtraBits
my $have_test_weaken_extrabits = eval "use Test::Weaken::ExtraBits; 1";
if (! $have_test_weaken_extrabits) {
  diag "Test::Weaken::ExtraBits not available -- $@";
}

sub my_ignore {
  my ($ref) = @_;
  return (Test::Weaken::ExtraBits::ignore_Class_Singleton($ref)  # JobQueue
          || Test::Weaken::ExtraBits::ignore_global_functions($ref));
}

SKIP: {
  $have_display
    or skip 'due to no DISPLAY available', 1;
  $have_test_weaken
    or skip 'due to Test::Weaken 3 not available', 1;
  $have_test_weaken_extrabits
    or skip 'due to Test::Weaken::ExtraBits not available', 1;

  require Test::Weaken::Gtk2;

  my $leaks = Test::Weaken::leaks
    ({ constructor => sub {
         my $dialog = App::Chart::Gtk2::DownloadDialog->new;
         return $dialog;
       },
       destructor => \&Test::Weaken::Gtk2::destructor_destroy,
       contents => \&Test::Weaken::Gtk2::contents_container,
       ignore => \&my_ignore,
     });
  is ($leaks, undef, 'Test::Weaken deep garbage collection');
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
