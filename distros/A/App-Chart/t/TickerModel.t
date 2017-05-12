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

use strict;
use warnings;

use Test::More 0.82 tests => 1;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }
use AppChartTestHelpers;

require App::Chart::Gtk2::TickerModel;
sub contents_object_property_values {
  my ($ref) = @_;
  require Scalar::Util;
  (Scalar::Util::blessed ($ref) && $ref->isa('Gtk2::Container'))
    or return;

  return map { ($_->{'flags'} & 'readable')
                 && $ref->get_property($_->{'name'}) }
    $ref->list_properties;
}

#------------------------------------------------------------------------------

# Test::Weaken 3 for "contents"
my $have_test_weaken = eval "use Test::Weaken 3; 1";
if (! $have_test_weaken) { diag "Test::Weaken 3 not available -- $@"; }

SKIP: {
  $have_test_weaken
    or skip 'due to Test::Weaken 3 not available', 1;

  my $leaks = Test::Weaken::leaks
    ({ constructor => sub {
         require App::Chart::Gtk2::Symlist;
         my $symlist = App::Chart::Gtk2::Symlist->new_from_key('favourites');
         my $tickermodel = App::Chart::Gtk2::TickerModel->new ($symlist);

         # don't fetch, it tickles a reference leak in Glib-Perl 1.200
         # my $iter = $tickermodel->get_iter_first;
         # if ($iter) { $tickermodel->get($iter,0); }

         return [ $tickermodel, $symlist ];
       },
       ignore => \&AppChartTestHelpers::ignore_symlists,
       contents => \&contents_object_property_values,
     });
  is ($leaks, undef, 'Test::Weaken deep garbage collection');
  if ($leaks) {
    diag "Test-Weaken ", explain $leaks;
  }
}

exit 0;
