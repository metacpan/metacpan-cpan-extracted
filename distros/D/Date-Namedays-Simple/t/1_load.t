# -*- perl -*-

# t/1_load.t - check if we can load and instanteniate

use Test::More tests => 2;

BEGIN { use_ok( 'Date::Namedays::Simple' ); }

my $object = Date::Namedays::Simple->new ();
isa_ok ($object, 'Date::Namedays::Simple');

