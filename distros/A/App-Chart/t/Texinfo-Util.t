#!/usr/bin/perl -w

# Copyright 2007, 2008, 2009, 2010 Kevin Ryde

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
use charnames ':full';

use Test::More tests => 7;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

require App::Chart::Texinfo::Util;
# example from the pod
is (App::Chart::Texinfo::Util::node_to_html_anchor ('My Node-Name'),
    'My-Node_002dName');

# example from "HTML Xref Node Name Expansion" in the texinfo manual
is (App::Chart::Texinfo::Util::node_to_html_anchor
    ('A  node --- with _\'%'),
    'A-node-_002d_002d_002d-with-_005f_0027_0025');

# example from "HTML Xref 8-bit Character Expansion" in the texinfo manual
is (App::Chart::Texinfo::Util::node_to_html_anchor
    ("A TeX B\N{COMBINING BREVE} \N{BLACK STAR}..."),
    'A-TeX-B_0306-_2605_002e_002e_002e');

is (App::Chart::Texinfo::Util::node_to_html_anchor('%'), 'g_t_0025');
is (App::Chart::Texinfo::Util::node_to_html_anchor('A%B'), 'A_0025B');
is (App::Chart::Texinfo::Util::node_to_html_anchor('-x'), 'g_t_002dx');
is (App::Chart::Texinfo::Util::node_to_html_anchor
    ("\x{10FFFD}"), 'g_t__10fffd');

exit 0;

