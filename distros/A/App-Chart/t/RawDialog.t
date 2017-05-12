#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010, 2011, 2012, 2016 Kevin Ryde

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
use Test::More 0.82;

# Gtk2::Ex::Datasheet::DBI 2.1 has a forcible -init, so must have a display
use Gtk2;
BEGIN {
  Gtk2->disable_setlocale;  # leave LC_NUMERIC alone for version nums
  Gtk2->init_check
    or plan skip_all => 'due to no DISPLAY available';
}

# before nowarnings() as Gtk2::Ex::Datasheet::DBI::CellEditableText in 2.1
# doesn't have 'editing-canceled' property or something
use App::Chart::Gtk2::RawDialog;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

plan tests => 3;

MyTestHelpers::glib_gtk_versions();

#------------------------------------------------------------------------------

{
  my $dialog = App::Chart::Gtk2::RawDialog->new;
  $dialog->destroy;
  require Scalar::Util;
  Scalar::Util::weaken ($dialog);
  MyTestHelpers::main_iterations();
  is ($dialog, undef, 'garbage collect after destroy');
}

{
  my $dialog = App::Chart::Gtk2::RawDialog->new;
  $dialog->realize;
  $dialog->destroy;
  require Scalar::Util;
  Scalar::Util::weaken ($dialog);
  MyTestHelpers::main_iterations();
  is ($dialog, undef, 'garbage collect after realize and destroy');
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
  return Test::Weaken::ExtraBits::ignore_global_functions($ref);
}

SKIP: {
  $have_test_weaken
    or skip 'due to no Test::Weaken 3 available', 1;
  $have_test_weaken_extrabits
    or skip 'due to Test::Weaken::ExtraBits not available', 1;

  require Test::Weaken::Gtk2;

  my $leaks = Test::Weaken::leaks
    ({ constructor => sub {
         my $dialog = App::Chart::Gtk2::RawDialog->new;
         $dialog->realize;
         return $dialog;
       },
       destructor => \&Test::Weaken::Gtk2::destructor_destroy_and_iterate,
       contents => \&Test::Weaken::Gtk2::contents_container,
       ignore => \&my_ignore
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
