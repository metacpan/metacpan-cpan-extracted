# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok( 'Catalyst::Plugin::Session::Store::MongoDB' ); }

my $object = Catalyst::Plugin::Session::Store::MongoDB->new ();
isa_ok ($object, 'Catalyst::Plugin::Session::Store::MongoDB');


