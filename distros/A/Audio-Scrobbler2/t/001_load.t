# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok( 'Audio::Scrobbler2' ); }

my $object = Audio::Scrobbler2->new ();
isa_ok ($object, 'Audio::Scrobbler2');


