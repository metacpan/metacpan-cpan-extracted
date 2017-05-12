# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok( 'Audio::Radio::V4L' ); }

my $object = Audio::Radio::V4L->new ();
isa_ok ($object, 'Audio::Radio::V4L');


