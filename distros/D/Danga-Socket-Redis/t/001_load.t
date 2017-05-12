# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok( 'Danga::Socket::Redis' ); }

my $object = Danga::Socket::Redis->new ();
isa_ok ($object, 'Danga::Socket::Redis');


