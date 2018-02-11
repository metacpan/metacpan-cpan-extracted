use strict;
use Test::Lib;
use Test::Most;
use Example::BoundedQueue;
use Example::Contract::BoundedQueue;

Example::Contract::BoundedQueue::->govern('Example::BoundedQueue');

throws_ok { 
    my $q = Example::BoundedQueue::->new(-3);

} qr/Precondition 'positive_int_size'.*not satisfied/;

done_testing();
