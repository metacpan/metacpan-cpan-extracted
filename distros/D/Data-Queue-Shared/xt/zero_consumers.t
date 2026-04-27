use strict;
use warnings;
use Test::More;
use Data::Queue::Shared;

plan skip_all => 'AUTHOR_TESTING not set' unless $ENV{AUTHOR_TESTING};

# Queue with no consumers: pushes until full should succeed up to
# capacity, further pushes should return false (no leak, no crash).

my $q = Data::Queue::Shared::Int->new(undef, 8);
my $pushed = 0;
while ($q->push($pushed)) { $pushed++ }
is $pushed, 8, 'pushed exactly capacity (8) before refusal';
ok !$q->push(99), 'push fails when full, no consumers';

# Still usable: size matches, pop drains
is $q->size, 8, 'size reports full';
for (0..7) { is $q->pop, $_, "pop retrieves $_" }
is $q->size, 0, 'emptied';

done_testing;
