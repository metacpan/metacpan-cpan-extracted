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
use Test::More;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

require App::Chart::Gtk2::HScale;
require Gtk2;
Gtk2->disable_setlocale;  # leave LC_NUMERIC alone for version nums
Gtk2->init_check
  or plan skip_all => 'due to no DISPLAY available';

plan tests => 5;

{
  my $hscale = App::Chart::Gtk2::HScale->new;
  require Scalar::Util;
  Scalar::Util::weaken ($hscale);
  is ($hscale, undef,
      'garbage collect when weakened');
}

{
  my $label = Gtk2::Label->new;
  my $hscale = App::Chart::Gtk2::HScale->new (widget => $label);
  Scalar::Util::weaken ($hscale);
  is ($hscale, undef,
      'garbage collect when weakened -- with widget');
}

{
  my $label1 = Gtk2::Label->new;
  my $label2 = Gtk2::Label->new;

  my $hscale = App::Chart::Gtk2::HScale->new (widget => $label1);
  $hscale->set (widget => $label2);
  Scalar::Util::weaken ($label1);
  is ($label1, undef, 'previous widget unreferenced');
}

{
  my $label = Gtk2::Label->new;
  my $hscale = App::Chart::Gtk2::HScale->new (widget => $label);
  Scalar::Util::weaken ($label);
  is ($label, undef, 'widget weakened away');
  if ($label) {
    if (eval { require Devel::FindRef }) {
      diag Devel::FindRef::track ($label);
    }
  }
}

#------------------------------------------------------------------------------

# Test::Weaken 3 for "contents"
my $have_test_weaken = eval "use Test::Weaken 3; 1";
if (! $have_test_weaken) { diag "Test::Weaken 3 not available -- $@"; }

SKIP: {
  $have_test_weaken
    or skip 'due to no Test::Weaken available', 1;

  require Test::Weaken::Gtk2;

  my $leaks = Test::Weaken::leaks
    ({ constructor => sub {
         my $label = Gtk2::Label->new;
         my $hscale = App::Chart::Gtk2::HScale->new (widget => $label);
         return [ $hscale, $label ];
       },
     });
  is ($leaks, undef, 'Test::Weaken deep garbage collection');
  if ($leaks) {
    diag "Test-Weaken ", explain $leaks;
  }
}

exit 0;

