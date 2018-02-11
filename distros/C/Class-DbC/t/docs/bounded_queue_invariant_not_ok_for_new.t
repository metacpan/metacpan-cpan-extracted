use strict;
use Test::Lib;
use Test::Most;
use Example::BoundedQueueWithBadNewInv;
use Example::Contract::BoundedQueue;

my $test_class = 'Example::BoundedQueueWithBadNewInv';
Example::Contract::BoundedQueue::->govern($test_class, { invariant => 1 });


throws_ok { 
    my $q = $test_class->new(3);

} qr/Invariant 'max_size_not_exceeded'/;

done_testing();
