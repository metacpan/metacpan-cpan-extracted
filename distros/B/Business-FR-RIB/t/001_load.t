# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use strict;
use warnings;
use Test::More tests => 3;

BEGIN { use_ok( 'Business::FR::RIB' ); }

my $object = Business::FR::RIB->new();
isa_ok ($object, 'Business::FR::RIB');

$object = Business::FR::RIB->new('1234567890DWFACEOFBOE08');
isa_ok ($object, 'Business::FR::RIB');
