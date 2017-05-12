#!/usr/bin/perl -w

# Copyright 2007, 2008, 2009, 2010, 2011, 2014 Kevin Ryde

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
use Test::More tests => 6;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

require App::Chart::Gtk2::Diagnostics;


# just check the string comes out
ok (App::Chart::Gtk2::Diagnostics->str ());
ok (App::Chart::Gtk2::Diagnostics->str ());

require Gtk2;
Gtk2->disable_setlocale;  # leave LC_NUMERIC alone for version nums
my $have_display = Gtk2->init_check;

SKIP: {
  $have_display or skip 'due to no DISPLAY available', 4;

  {
    my $dialog = App::Chart::Gtk2::Diagnostics->new;
    require Scalar::Util;
    Scalar::Util::weaken ($dialog);
    $dialog->destroy;
    MyTestHelpers::main_iterations();
    is ($dialog, undef,
        'garbage collect by weaken after destroy');
  }
  {
    my $dialog = App::Chart::Gtk2::Diagnostics->new;
    $dialog->show;
    Scalar::Util::weaken ($dialog);
    $dialog->destroy;
    MyTestHelpers::main_iterations();
    is ($dialog, undef,
        'garbage collect by weaken after show and destroy');
  }

  {
    my $dialog = App::Chart::Gtk2::Diagnostics->popup;
    {
      my $d2 = App::Chart::Gtk2::Diagnostics->popup;
      ok ($dialog == $d2);
    }

    Scalar::Util::weaken ($dialog);
    $dialog->destroy;
    MyTestHelpers::main_iterations();
    is ($dialog, undef,
        'garbage collect popup by destroy and weaken');
  }
}

exit 0;
