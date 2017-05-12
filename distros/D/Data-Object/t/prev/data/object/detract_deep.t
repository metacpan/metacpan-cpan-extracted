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

use Data::Object 'deduce_deep', 'detract_deep';
use Scalar::Util 'refaddr';

can_ok 'Data::Object', 'deduce_deep', 'detract_deep';
subtest 'test the deduce_deep/detract_deep function' => sub {
    my $main = bless {}, 'main';
    my $object = deduce_deep {1,2,3,{4,5,6,[-1, 99, $main],7,"abcd"}};

    $object = detract_deep($object);
    is_deeply $object, {1,2,3,{4,5,6,[-1, 99, $main],7,"abcd"}};

    is $object->{1}, 2;
    is $object->{3}{4}, 5;
    is $object->{3}{6}[0], -1;
    is $object->{3}{6}[1], 99;
    is $object->{3}{6}[2], $main;
    is $object->{3}{7}, "abcd";

    is ref($object),             'HASH';
    is ref($object->{1}),        '';
    is ref($object->{3}),        'HASH';
    is ref($object->{3}{4}),     '';
    is ref($object->{3}{6}),     'ARRAY';
    is ref($object->{3}{6}[0]),  '';
    is ref($object->{3}{6}[1]),  '';
    is ref($object->{3}{6}[2]),  'main';
    is ref($object->{3}{7}),     '';
};

ok 1 and done_testing;
