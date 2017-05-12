# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok( 'BSON::Stream' ); }

my $object = BSON::Stream->new ();
isa_ok ($object, 'BSON::Stream');


