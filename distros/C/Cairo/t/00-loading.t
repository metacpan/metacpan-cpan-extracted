#!/usr/bin/perl
#
# Copyright (c) 2004-2012 by the cairo perl team (see the file README)
#
# Licensed under the LGPL, see LICENSE file for more information.
#

use strict;
use warnings;

use Test::More tests => 18;

BEGIN {
  ok (! eval "use Cairo 2.000; 1");
  ok (eval "use Cairo 1.000; 1");
}

ok(defined Cairo::LIB_VERSION);
ok(defined Cairo::LIB_VERSION_ENCODE (1, 0, 0));
ok(defined Cairo->LIB_VERSION);
ok(defined Cairo->LIB_VERSION_ENCODE (1, 0, 0));
ok(defined Cairo::lib_version);
ok(defined Cairo::lib_version_string);
ok(defined Cairo->lib_version);
ok(defined Cairo->lib_version_string);

# Deprecated names:
ok(defined Cairo::VERSION);
ok(defined Cairo::VERSION_ENCODE (1, 0, 0));
ok(defined Cairo->VERSION);
ok(defined Cairo->VERSION_ENCODE (1, 0, 0));
ok(defined Cairo::version);
ok(defined Cairo::version_string);
ok(defined Cairo->version);
ok(defined Cairo->version_string);
