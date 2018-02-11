use strict;
use Test::Lib;
use Test::Most;
use Example::Contract::BoundedQueue;

my $governed = 'Example::BoundedQueueWithBadNew';
eval "require $governed";

my $emulation = Example::Contract::BoundedQueue::->govern($governed, { emulate => 1 });

throws_ok { 
    my $q = $emulation->new(3);

} qr/failed postcondition 'zero_sized'/;

done_testing();
