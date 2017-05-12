# For Emacs: -*- mode:cperl; mode:folding; -*-
#
# (c) 2005-2011 Jiri Vaclavik <my name dot my last name at gmail dot com>
#

use strict;
use warnings;

use Date::Say::Czech qw(:ALL);
use Test::More tests => 7;

is(time_to_say(1316114598), 'patnáctého září dva tisíce jedenáct', 'time_to_say');
is(time_to_say(1000000000), 'devátého září dva tisíce jedna', 'time_to_say');
is(date_to_say(5, 6, 800), 'pátého června osm set', 'date_to_say');
is(date_to_say(1, 12, 2000), 'prvního prosince dva tisíce', 'date_to_say');
is(month_to_say(8), 'srpna', 'month_to_say');
is(year_to_say(1999), 'tisíc devět set devadesát devět', 'year_to_say');
is(day_to_say(5), 'pátého', 'day_to_say');
