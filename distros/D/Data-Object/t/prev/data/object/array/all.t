use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Array';
can_ok 'Data::Object::Array', 'all';

use Scalar::Util 'refaddr';

subtest 'test the all method - natural' => sub {
    my $array = Data::Object::Array->new([2..5]);
    my $all = $array->all(sub { shift > 1 });

    isnt refaddr($array), refaddr($all);
    is $all, 1;

    isa_ok $array, 'Data::Object::Array';
    isa_ok $all, 'Data::Object::Number';
};

subtest 'test the all method - codified' => sub {
    my $array = Data::Object::Array->new([2..5]);
    my $all = $array->all('$a > 1 ');

    isnt refaddr($array), refaddr($all);
    is $all, 1;

    isa_ok $array, 'Data::Object::Array';
    isa_ok $all, 'Data::Object::Number';
};

subtest 'test the all method - codified with refs' => sub {
    my $array = Data::Object::Array->new([2..5]);
    my $all = $array->all('$value > 1 ');

    isnt refaddr($array), refaddr($all);
    is $all, 1;

    isa_ok $array, 'Data::Object::Array';
    isa_ok $all, 'Data::Object::Number';
};

ok 1 and done_testing;
