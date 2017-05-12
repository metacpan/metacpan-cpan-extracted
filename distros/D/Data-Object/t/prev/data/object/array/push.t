use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Array';
can_ok 'Data::Object::Array', 'push';

use Scalar::Util 'refaddr';

subtest 'test the push method' => sub {
    my $array = Data::Object::Array->new([1..5]);

    my @argument = (6,7,8);
    my $push = $array->push(@argument);

    is refaddr($array), refaddr($push);
    is_deeply $push, [1,2,3,4,5,6,7,8];

    isa_ok $array, 'Data::Object::Array';
    isa_ok $push, 'Data::Object::Array';
};

ok 1 and done_testing;
