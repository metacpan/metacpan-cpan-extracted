# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 3;

BEGIN { use_ok( 'Business::PostNL' ); }

my $object = Business::PostNL->new ();
isa_ok ($object, 'Business::PostNL');

can_ok($object, qw/cost country large machine priority receipt register tracktrace weight zone/);
