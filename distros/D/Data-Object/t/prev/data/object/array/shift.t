use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Array';
can_ok 'Data::Object::Array', 'shift';

use Scalar::Util 'refaddr';

subtest 'test the shift method' => sub {
    my $array = Data::Object::Array->new([1..5]);
    my $shift = $array->shift;

    isnt refaddr($array), refaddr($shift);
    is_deeply $array, [2,3,4,5];
    is $shift, 1;

    isa_ok $array, 'Data::Object::Array';
    isa_ok $shift, 'Data::Object::Number';
};

ok 1 and done_testing;
