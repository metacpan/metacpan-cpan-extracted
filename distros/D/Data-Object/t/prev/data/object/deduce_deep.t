use strict;
use warnings;
use Test::More;

plan skip_all => 'Missing implicit dependencies. Tests skipped.' unless eval q(
    require Data::Object::Array;
    require Data::Object::Code;
    require Data::Object::Float;
    require Data::Object::Hash;
    require Data::Object::Number;
    require Data::Object::Number;
    require Data::Object::Scalar;
    require Data::Object::String;
    require Data::Object::Undef;
    require Data::Object::Universal;
    1;
);

use Data::Object 'deduce_deep';
use Scalar::Util 'refaddr';

can_ok 'Data::Object', 'deduce_deep';
subtest 'test the deduce_deep function' => sub {
    my $main = bless {}, 'main';
    my $object = deduce_deep {1,2,3,{4,5,6,[-1, 99, $main]}};

    is $object->{1}, 2;
    is $object->{3}{4}, 5;
    is $object->{3}{6}[0], -1;
    is $object->{3}{6}[1], 99;
    is $object->{3}{6}[2], $main;

    isa_ok $object,             'Data::Object::Hash';
    isa_ok $object->{1},        'Data::Object::Number';
    isa_ok $object->{3},        'Data::Object::Hash';
    isa_ok $object->{3}{4},     'Data::Object::Number';
    isa_ok $object->{3}{6},     'Data::Object::Array';
    isa_ok $object->{3}{6}[0],  'Data::Object::Integer';
    isa_ok $object->{3}{6}[1],  'Data::Object::Number';
    isa_ok $object->{3}{6}[2],  'main';
};

ok 1 and done_testing;
