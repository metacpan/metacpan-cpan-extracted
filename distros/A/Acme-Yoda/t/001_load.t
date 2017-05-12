# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok( 'Acme::Yoda' ); }

my $object = Acme::Yoda->new ();
isa_ok ($object, 'Acme::Yoda');


