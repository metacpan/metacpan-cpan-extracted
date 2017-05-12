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
use Test::More tests => 8;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

require App::Chart::Glib::Ex::MoreUtils;

# my $want_version
# is ($App::Chart::Glib::Ex::MoreUtils::VERSION, $want_version, 'VERSION variable');
# is (App::Chart::Glib::Ex::MoreUtils->VERSION,  $want_version, 'VERSION class method');
# { ok (eval { App::Chart::Glib::Ex::MoreUtils->VERSION($want_version); 1 },
#       "VERSION class check $want_version");
#   my $check_version = $want_version + 1000;
#   ok (! eval { App::Chart::Glib::Ex::MoreUtils->VERSION($check_version); 1 },
#       "VERSION class check $check_version");
# }

require Glib;
MyTestHelpers::glib_gtk_versions();


#------------------------------------------------------------------------------
# lang_select

delete $ENV{'LANGUAGE'};
delete $ENV{'LC_ALL'};
delete $ENV{'LC_MESSAGES'};
delete $ENV{'LANG'};
is (App::Chart::Glib::Ex::MoreUtils::lang_select (en => 1, de => 2), 1);
is (App::Chart::Glib::Ex::MoreUtils::lang_select (de => 2, en => 1), 2);

$ENV{'LANGUAGE'} = 'en';
is (App::Chart::Glib::Ex::MoreUtils::lang_select (en => 1, de => 2), 1);
is (App::Chart::Glib::Ex::MoreUtils::lang_select (de => 1, en => 2), 2);

$ENV{'LANGUAGE'} = 'en_AU';
is (App::Chart::Glib::Ex::MoreUtils::lang_select (en => 1, de => 2), 1);
is (App::Chart::Glib::Ex::MoreUtils::lang_select (de => 1, en => 2), 2);

$ENV{'LANGUAGE'} = 'ar:en';
is (App::Chart::Glib::Ex::MoreUtils::lang_select (en => 1, de => 2), 1);
is (App::Chart::Glib::Ex::MoreUtils::lang_select (de => 1, en => 2), 2);

exit 0;
