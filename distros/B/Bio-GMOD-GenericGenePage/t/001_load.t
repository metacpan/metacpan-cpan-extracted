# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok( 'Bio::GMOD::GenericGenePage' ); }

my $object = Bio::GMOD::GenericGenePage->new ();
isa_ok ($object, 'Bio::GMOD::GenericGenePage');


