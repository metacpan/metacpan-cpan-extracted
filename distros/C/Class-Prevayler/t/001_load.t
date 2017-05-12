# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok( 'Class::Prevayler' ); }

my $object = Class::Prevayler->new ();
isa_ok ($object, 'Class::Prevayler');


