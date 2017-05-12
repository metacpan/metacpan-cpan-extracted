use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Array';
can_ok 'Data::Object::Array', 'slice';

use Scalar::Util 'refaddr';

subtest 'test the slice method' => sub {
    my $array = Data::Object::Array->new([1..5]);

    my @argument = (2,4);
    my $slice = $array->slice(@argument);

    isnt refaddr($array), refaddr($slice);
    is_deeply $array, [1,2,3,4,5];
    is_deeply $slice, [3,5];

    isa_ok $array, 'Data::Object::Array';
    isa_ok $slice, 'Data::Object::Array';
};

ok 1 and done_testing;
