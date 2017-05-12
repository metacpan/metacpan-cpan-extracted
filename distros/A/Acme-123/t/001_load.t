# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok( 'Acme::123' ); }

my $object = Acme::123->new ();
isa_ok ($object, 'Acme::123');


