# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok( 'DBIx::Composer' ); }

my $object = DBIx::Composer->new ();
isa_ok ($object, 'DBIx::Composer');


