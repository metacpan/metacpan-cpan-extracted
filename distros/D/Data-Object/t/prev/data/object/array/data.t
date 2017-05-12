use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Array';
can_ok 'Data::Object::Array', 'data';

subtest 'test the data method' => sub {
    my $array = Data::Object::Array->new([1,2,3,4,5]);
    is_deeply $array->data, [1,2,3,4,5];
};

ok 1 and done_testing;
