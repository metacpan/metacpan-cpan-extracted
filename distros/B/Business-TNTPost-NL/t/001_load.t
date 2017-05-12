# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 3;

BEGIN { use_ok( 'Business::TNTPost::NL' ); }

my $object = Business::TNTPost::NL->new ();
isa_ok ($object, 'Business::TNTPost::NL');

can_ok($object, qw/cost country large machine priority receipt register tracktrace weight zone/);
