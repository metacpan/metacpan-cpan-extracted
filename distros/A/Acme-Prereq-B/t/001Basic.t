######################################################################
# Test suite for Acme::Prereq::B
# by Mike Schilli <m@perlmeister.com>
######################################################################

use warnings;
use strict;

use Test::More qw(no_plan);
BEGIN { use_ok('Acme::Prereq::B') };
BEGIN { use_ok('Acme::Prereq::A') };

ok(1);
