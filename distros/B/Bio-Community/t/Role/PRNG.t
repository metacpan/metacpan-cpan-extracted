use strict;
use warnings;
use Bio::Root::Test;

use_ok($_) for qw(
    t::Role::TestPRNG
);


my ($num, $obj, $obj2, @expected);


SKIP: {
test_skip(-tests => 1, -requires_module => 'Math::GSL::RNG');


# Basic object

ok $obj = t::Role::PRNG->new(), 'Basic object';
isa_ok $obj, 't::Role::PRNG';

can_ok $obj, 'get_seed';
can_ok $obj, 'set_seed';
can_ok $obj, 'rand';
can_ok $obj, 'get_random_number';


# Auto-generated seed

ok $obj = t::Role::PRNG->new( ), 'Auto-generated seed';
cmp_ok $obj->get_seed, '>', 0;
for (1..10) {
   ok $num = $obj->get_random_number(10);
   cmp_ok $num, '>=', 1;
   cmp_ok $num, '<=', 10;
}


# Provide a seed

ok $obj->set_seed( 1234 ), 'Specified seed';
is $obj->get_seed, 1234;

ok $obj2 = t::Role::PRNG->new( -seed => 1234 );
is $obj2->get_seed, 1234;

@expected = (2, 5, 7, 9, 5, 7, 8, 8, 8, 9);
for my $i (0..9) {
   is $obj->get_random_number , $expected[$i];
   is $obj2->get_random_number, $expected[$i];
}


}

done_testing();

exit;
