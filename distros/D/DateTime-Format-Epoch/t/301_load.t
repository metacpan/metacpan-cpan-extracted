# t/301_load.t - check module loading

use Test::More tests => 1;

BEGIN { use_ok( 'DateTime::Format::Epoch::TAI64' ); }
