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

use Data::Object 'deduce';
use Scalar::Util 'refaddr';

can_ok 'Data::Object', 'deduce';
subtest 'test the deduce function' => sub {
    my $array = deduce [1..5];
    isa_ok $array, 'Data::Object::Array';

    my $code = deduce sub {1};
    isa_ok $code, 'Data::Object::Code';

    my $float = deduce 3.98765;
    isa_ok $float, 'Data::Object::Float';

    my $power = deduce '1.3e8';
    isa_ok $power, 'Data::Object::Float';

    my $hash = deduce {1..4};
    isa_ok $hash, 'Data::Object::Hash';

    my $integer = deduce 99;
    isa_ok $integer, 'Data::Object::Number';

    my $number = deduce '+12345';
    isa_ok $number, 'Data::Object::Integer';

    my $regexp = deduce qr/\w+/;
    isa_ok $regexp, 'Data::Object::Regexp';

    my $string = deduce 'Hello World';
    isa_ok $string, 'Data::Object::String';

    my $undef = deduce undef;
    isa_ok $undef, 'Data::Object::Undef';
};

ok 1 and done_testing;
