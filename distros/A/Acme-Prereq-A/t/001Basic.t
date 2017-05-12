######################################################################
# Test suite for Acme::Prereq::A
# by Mike Schilli <m@perlmeister.com>
######################################################################

use warnings;
use strict;

use Test::More qw(no_plan);
BEGIN { use_ok('Acme::Prereq::A') };
BEGIN { use_ok('Acme::Prereq::B') };

ok(1);
