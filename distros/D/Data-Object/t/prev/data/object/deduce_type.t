use strict;
use warnings;
use Test::More;

plan skip_all => 'Missing implicit dependencies. Tests skipped.' unless eval q(
    require Data::Object::Array;
    require Data::Object::Code;
    require Data::Object::Float;
    require Data::Object::Hash;
    require Data::Object::Number;
    require Data::Object::Regexp;
    require Data::Object::Scalar;
    require Data::Object::String;
    require Data::Object::Undef;
    require Data::Object::Universal;
    1;
);

use Data::Object 'deduce_type';
use Scalar::Util 'refaddr';

can_ok 'Data::Object', 'deduce_type';
subtest 'test the deduce_type function' => sub {
    my $array = deduce_type [1..5];
    is $array, 'ARRAY';

    my $code = deduce_type sub {1};
    is $code, 'CODE';

    my $float = deduce_type 3.98765;
    is $float, 'FLOAT';

    my $power = deduce_type '1.3e8';
    is $power, 'FLOAT';

    my $hash = deduce_type {1..4};
    is $hash, 'HASH';

    my $integer = deduce_type 99;
    is $integer, 'NUMBER';

    my $pos_number = deduce_type '+12345';
    is $pos_number, 'INTEGER';

    my $neg_number = deduce_type '-12345';
    is $neg_number, 'INTEGER';

    my $regexp = deduce_type qr/\w+/;
    is $regexp, 'REGEXP';

    my $string = deduce_type 'Hello World';
    is $string, 'STRING';

    my $undef = deduce_type undef;
    is $undef, 'UNDEF';
};

ok 1 and done_testing;
