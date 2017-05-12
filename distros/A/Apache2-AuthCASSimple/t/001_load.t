# -*- perl -*-

# t/001_load.t - check module loading 

use Test::More tests => 1;

BEGIN { use_ok( 'Apache2::AuthCASSimple' ); }

#my $object = Apache2::AuthCASSimple->handler ();
#isa_ok ($object, 'Apache2::AuthCASSimple');


