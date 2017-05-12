# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 5;

BEGIN { use_ok( 'Acme::IRC::Art'); }

my $object = Acme::IRC::Art->new (5,5);
isa_ok ($object, 'Acme::IRC::Art');


can_ok($object,qw(pixel rectangle text result));
can_ok($object,qw(save load));

isa_ok([$object->result],'ARRAY');
