use strict;
use Test::Lib;
use Test::Most;
use Example::Contract::BoundedQueue;

my $test_class = 'Example::BoundedQueueWithBadNewInv';
eval "require $test_class";
my $emulation = Example::Contract::BoundedQueue::->govern($test_class, { invariant => 1, emulate => 1 });

throws_ok { 
    my $q = $emulation->new(3);

} qr/Invariant 'max_size_not_exceeded'/;

done_testing();
