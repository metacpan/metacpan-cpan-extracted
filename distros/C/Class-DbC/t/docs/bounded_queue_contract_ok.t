use strict;
use Test::Lib;
use Test::More;
use Example::BoundedQueue;
use Example::Contract::BoundedQueue;

Example::Contract::BoundedQueue::->govern('Example::BoundedQueue');

my $q = Example::BoundedQueue::->new(3);

$q->push($_) for 1 .. 3;
is $q->size => 3;

$q->push($_) for 4 .. 6;
is $q->size => 3;
is $q->pop => 4;
done_testing();
