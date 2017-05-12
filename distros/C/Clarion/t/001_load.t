# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok( 'Clarion' ); }

my $object = Clarion->new ();
isa_ok ($object, 'Clarion');

__END__
