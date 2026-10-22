use strict;
use warnings;
use Test::More;
BEGIN {
    plan skip_all => 'PDL not installed' unless grep { !ref($_) && -f "$_/PDL.pm" } @INC;
}
use Data::NDArray::Shared;

my $a = Data::NDArray::Shared->new(undef, 'f64', 2, 3)->fill(1.5);
my $p = $a->to_pdl;
isa_ok $p, 'PDL', 'to_pdl loads PDL without an application import';
is_deeply [ $p->dims ], [ 3, 2 ], 'the copied PDL has the reversed shape';
my $b = Data::NDArray::Shared->from_pdl($p);
is_deeply $b->to_list, [ (1.5) x 6 ], 'from_pdl loads the methods needed for copying';
$b->update_from_pdl($p + 2);
is_deeply $b->to_list, [ (3.5) x 6 ], 'PDL arithmetic and update work without an import';
is $a->sum, 9, 'PDL loading preserves the shared array reduction methods';
is $b->mean, 3.5, 'shared array methods still use the shared data';

done_testing;
