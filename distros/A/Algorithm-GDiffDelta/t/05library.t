# Check that the library can be loaded without things breaking.

use strict;
use warnings;
use Test::More tests => 2;

BEGIN { use_ok('Algorithm::GDiffDelta') }
require_ok('Algorithm::GDiffDelta');

# vim:ft=perl ts=4 sw=4 expandtab:
