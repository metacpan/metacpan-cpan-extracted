use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Array';
can_ok 'Data::Object::Array', 'set';

use Scalar::Util 'refaddr';

subtest 'test the set method' => sub {
    my $array = Data::Object::Array->new([1..5]);

    my @argument = (4,6);
    my $set = $array->set(@argument);

    isnt refaddr($array), refaddr($set);
    is_deeply $array, [1,2,3,4,6];
    is $set, 6;

    isa_ok $array, 'Data::Object::Array';
    isa_ok $set, 'Data::Object::Number';
};

ok 1 and done_testing;
