use strict;
use warnings;
use Test::More;
use DOM::Tiny;

cmp_ok(scalar(@DOM::Tiny::ISA), '==', 1);

is($DOM::Tiny::ISA[0], 'Mojo::DOM58');

done_testing();
