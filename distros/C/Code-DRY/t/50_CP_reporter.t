use strict;
use warnings;

use Code::DRY;
use Test::More tests => 2+2;

#########################

can_ok('Code::DRY', 'set_default_reporter');
can_ok('Code::DRY', 'set_reporter');

is(ref Code::DRY::set_default_reporter(), 'CODE', "set_default_reporter sets default");
is(ref [Code::DRY::set_reporter(Code::DRY::set_default_reporter())]->[0], 'CODE', "set_reporter sets given value (default)");

#TODO
