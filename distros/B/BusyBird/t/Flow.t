use strict;
use warnings;
use Test::More;
use Test::Memory::Cycle;

BEGIN {
    use_ok('BusyBird::Flow');
}

my $flow = BusyBird::Flow->new();
memory_cycle_ok($flow);

done_testing();


