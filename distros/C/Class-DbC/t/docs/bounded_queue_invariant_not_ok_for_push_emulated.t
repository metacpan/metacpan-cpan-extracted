use strict;
use Test::Lib;
use Test::Most;

my $governed = 'Example::BoundedQueueWithBadPush';
eval "use $governed";
use Example::Contract::BoundedQueue;

my $emulation = Example::Contract::BoundedQueue::->govern($governed, { emulate => 1 });

my $q = $emulation->new(3);
throws_ok { 
    $q->push($_) for 1 .. 4;

} qr/Invariant 'max_size_not_exceeded'/;

done_testing();
