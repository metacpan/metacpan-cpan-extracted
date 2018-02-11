use strict;
use Test::Lib;
use Test::Most;
use Example::BoundedQueueWithBadNew;
use Example::Contract::BoundedQueue;

Example::Contract::BoundedQueue::->govern('Example::BoundedQueueWithBadNew');


throws_ok { 
    my $q = Example::BoundedQueueWithBadNew->new(3);

} qr/failed postcondition 'zero_sized'/;

done_testing();
