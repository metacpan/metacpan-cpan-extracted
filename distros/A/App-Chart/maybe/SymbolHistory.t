#!/usr/bin/perl

# Copyright 2009, 2010 Kevin Ryde

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

use lib 't';
use MyTestHelpers;

use Test::More 0.82 tests => 7;

SKIP: { eval 'use Test::NoWarnings; 1'
          or skip 'Test::NoWarnings not available', 1; }

require App::Chart::SymbolHistory;
require Gtk2;
Gtk2->disable_setlocale;  # leave LC_NUMERIC alone for version nums
my $have_display = Gtk2->init_check;

#-----------------------------------------------------------------------------
# back_menu(), forward_menu()

SKIP: {
  $have_display or skip 'due to no DISPLAY available', 4;

  my $history = App::Chart::SymbolHistory->new;

  $history->goto ('AAA');
  $history->goto ('BBB');
  $history->goto ('CCC');

  {
    my $menu = $history->back_menu;
    isa_ok ($menu, 'Gtk2::Menu');
    $menu->popup (undef, undef, undef, undef, 0, 0);
    my @children = $menu->get_children;
    is (scalar @children, 2);
  }
  {
    my $menu = $history->forward_menu;
    isa_ok ($menu, 'Gtk2::Menu');
    $menu->popup (undef, undef, undef, undef, 0, 0);
    my @children = $menu->get_children;
    is (scalar @children, 0);
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

  my $leak ;
  my $leaks = Test::Weaken::leaks
    ({ constructor => sub {
         return App::Chart::SymbolHistory->new;
       },
       contents => \&Test::Weaken::Gtk2::contents_container,
     });
  is ($leaks, undef, 'Test::Weaken deep garbage collection');
  if ($leaks) {
    diag "Test-Weaken ", explain $leaks;
  }
}

SKIP: {
  ($have_display && $have_test_weaken)
    or skip 'due to no DISPLAY and/or no Test::Weaken available', 1;

  require Test::Weaken::Gtk2;

  my $leak ;
  my $leaks = Test::Weaken::leaks
    ({ constructor => sub {
         my $history = App::Chart::SymbolHistory->new;
         $history->goto ('AAA');
         $history->goto ('BBB');
         $history->goto ('CCC');

         my $back_menu = $history->back_menu;
         $back_menu->popup (undef, undef, undef, undef, 0, 0);
         $back_menu->popdown;

         my $forward_menu = $history->forward_menu;
         $forward_menu->popup (undef, undef, undef, undef, 0, 0);
         $forward_menu->popdown;

         return ($history, $back_menu, $forward_menu);
       },
       contents => \&Test::Weaken::Gtk2::contents_container,
     });
  is ($leaks, undef, 'Test::Weaken deep garbage collection');
  if ($leaks) {
    diag "Test-Weaken ", explain $leaks;
  }
}

exit 0;
