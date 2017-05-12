# -*- mode: perl; coding: utf-8; tab-width: 4 -*-

use strict;
use warnings;
# use Test::More qw(no_plan);
use Test::More tests => 2;
BEGIN { use_ok('Cv', -nomore) }

SKIP: {
	skip "no DISPLAY", 1 unless Cv->hasGUI;
	Cv->initSystem([ "-display", ":0" ]);
	ok(1);
}
