use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Array';
can_ok 'Data::Object::Array', 'count';

use Scalar::Util 'refaddr';

subtest 'test the count method' => sub {
    my $array = Data::Object::Array->new([1..5]);
    my $count = $array->count();

    isnt refaddr($array), refaddr($count);
    is $count, 5;

    isa_ok $array, 'Data::Object::Array';
    isa_ok $count, 'Data::Object::Number';
};

ok 1 and done_testing;
