use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Array';
can_ok 'Data::Object::Array', 'detract';

subtest 'test the detract method' => sub {
    my $array = Data::Object::Array->new([1,2,3,4,5]);
    is_deeply $array->detract, [1,2,3,4,5];
};

ok 1 and done_testing;
