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

use Data::Object 'deduce', 'detract';
use Scalar::Util 'refaddr';

can_ok 'Data::Object', 'deduce', 'detract';
subtest 'test the deduce/detract functions' => sub {
    my $array = deduce [1..5];
    isa_ok $array, 'Data::Object::Array';
    is_deeply detract($array), [1..5];

    my $code = deduce sub {1};
    isa_ok $code, 'Data::Object::Code';
    is detract($code)->(), 1;

    my $float = deduce 3.98765;
    isa_ok $float, 'Data::Object::Float';
    is detract($float), 3.98765;

    my $power = deduce '1.3e8';
    isa_ok $power, 'Data::Object::Float';
    is detract($power), '1.3e8';

    my $hash = deduce {1..4};
    isa_ok $hash, 'Data::Object::Hash';
    is_deeply detract($hash), {1..4};

    my $integer = deduce 99;
    isa_ok $integer, 'Data::Object::Number';
    is detract($integer), 99;

    my $number = deduce '+12345';
    isa_ok $number, 'Data::Object::Integer';
    is detract($number), 12345;

    my $regexp = deduce qr/\w+/;
    isa_ok $regexp, 'Data::Object::Regexp';
    is detract($regexp), qr/\w+/;

    my $string = deduce 'Hello World';
    isa_ok $string, 'Data::Object::String';
    is detract($string), 'Hello World';

    my $undef = deduce undef;
    isa_ok $undef, 'Data::Object::Undef';
    is detract($undef), undef;
};

ok 1 and done_testing;
