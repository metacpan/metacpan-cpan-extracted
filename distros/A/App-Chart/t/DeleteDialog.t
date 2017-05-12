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

use 5.008;
use strict;
use warnings;
use Test::More 0.82 tests => 3;  # version 0.82 for explain()

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

require App::Chart::Gtk2::DeleteDialog;
require Gtk2;
Gtk2->disable_setlocale;  # leave LC_NUMERIC alone for version nums
my $have_display = Gtk2->init_check;

#------------------------------------------------------------------------------

SKIP: {
  $have_display or skip 'due to no DISPLAY available', 2;

  {
    my $dialog = App::Chart::Gtk2::DeleteDialog->new;
    $dialog->destroy;
    require Scalar::Util;
    Scalar::Util::weaken ($dialog);
    MyTestHelpers::main_iterations();
    is ($dialog, undef, 'garbage collect after destroy');
  }

  {
    my $dialog = App::Chart::Gtk2::DeleteDialog->new;
    $dialog->realize;
    $dialog->destroy;
    require Scalar::Util;
    Scalar::Util::weaken ($dialog);
    MyTestHelpers::main_iterations();
    is ($dialog, undef, 'garbage collect after realize and destroy');
  }
}


#------------------------------------------------------------------------------

# Test::Weaken 3 for "contents"
my $have_test_weaken = eval "use Test::Weaken 3; 1";
if (! $have_test_weaken) { diag "Test::Weaken 3 not available -- $@"; }

SKIP: {
  ($have_display && $have_test_weaken)
    or skip 'due to no DISPLAY and/or no Test::Weaken available', 1;

  require Test::Weaken::Gtk2;

  my $leaks = Test::Weaken::leaks
    ({ constructor => sub {
         my $dialog = App::Chart::Gtk2::DeleteDialog->new;
         $dialog->realize;
         return $dialog;
       },
       destructor => \&Test::Weaken::Gtk2::destructor_destroy,
       contents => \&Test::Weaken::Gtk2::contents_container,
     });
  is ($leaks, undef, 'Test::Weaken deep garbage collection');
  if ($leaks) {
    diag "Test-Weaken ", explain $leaks;
  }
}

exit 0;
