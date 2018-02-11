use strict;
use Test::Lib;
use Test::Most;
use Example::BoundedQueueWithBadPop;
use Example::Contract::BoundedQueue;

Example::Contract::BoundedQueue::->govern('Example::BoundedQueueWithBadPop');

my $q = Example::BoundedQueueWithBadPop::->new(3);
$q->push($_) for 1 .. 3;

throws_ok { 
    $q->pop;

} qr/failed postcondition 'returns_old_head'/;

done_testing();
