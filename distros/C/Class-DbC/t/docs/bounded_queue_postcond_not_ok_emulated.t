use strict;
use Test::Lib;
use Test::Most;
use Example::Contract::BoundedQueue;

my $governed = 'Example::BoundedQueueWithBadPop';
eval "require $governed";

my $emulation = Example::Contract::BoundedQueue::->govern($governed, { emulate => 1 });
my $q = $emulation->new(3);
$q->push($_) for 1 .. 3;

throws_ok { 
    $q->pop;

} qr/failed postcondition 'returns_old_head'/;

done_testing();
