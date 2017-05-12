use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Array';
can_ok 'Data::Object::Array', 'get';

use Scalar::Util 'refaddr';

subtest 'test the get method' => sub {
    my $array = Data::Object::Array->new([1..5]);

    my @argument = (0);
    my $get = $array->get(@argument);

    isnt refaddr($array), refaddr($get);
    is $get, 1;

    isa_ok $array, 'Data::Object::Array';
    isa_ok $get, 'Data::Object::Number';
};

ok 1 and done_testing;
