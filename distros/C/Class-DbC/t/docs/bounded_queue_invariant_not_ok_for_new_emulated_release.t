use strict;
use warnings;
use Test::Lib;
use Test::Most;
use Example::Contract::BoundedQueue;

my $test_class = 'Example::BoundedQueueWithBadNewInv';
eval "require $test_class";

my $emulation = Example::Contract::BoundedQueue::->govern($test_class, { emulate => 1 });

throws_ok { 
    my $q1 = $emulation->new(3);

} qr/failed postcondition 'zero_sized'/;

Example::Contract::BoundedQueue::->govern($test_class, { emulate => 1, pre=>1, invariant=>1 });

throws_ok { 
    my $q2 = $emulation->new(3);

} qr/Invariant 'max_size_not_exceeded'/;

Example::Contract::BoundedQueue::->govern($test_class, { emulate => 1, pre=>1 });
my $q3 = $emulation->new(3);
is $q3->size => 4;

Example::Contract::BoundedQueue::->govern($test_class, { emulate => 1, pre=>0 });
my $q4 = $emulation->new(3);
is $q4->size => 4;

done_testing();
