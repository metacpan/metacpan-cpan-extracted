# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok( 'Crypt::SimpleGPG' ); }

my $object = Crypt::SimpleGPG->new ();
isa_ok ($object, 'Crypt::SimpleGPG');


