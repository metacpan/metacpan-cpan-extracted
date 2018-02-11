use strict;
use Test::Lib;
use Test::Most;

my $test_class = 'Example::BoundedQueueWithBadPush';
eval "use $test_class";
use Example::Contract::BoundedQueueByExtension;

'Example::Contract::BoundedQueueByExtension'->govern($test_class);

my $q = $test_class->new(3);
throws_ok { 
    $q->push($_) for 1 .. 4;

} qr/Invariant 'max_size_not_exceeded'/;

done_testing();
