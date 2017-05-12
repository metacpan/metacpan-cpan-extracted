use strict;
use warnings;
use Test::More;

plan skip_all => 'Missing implicit dependencies. Tests skipped.' unless eval q(
    require Data::Object::Number;
    1;
);

use Data::Object 'type_number';
use Scalar::Util 'refaddr';

can_ok 'Data::Object', 'type_number';

subtest 'test the type_number function - pure number' => sub {
    my $number1 = type_number 123;
    my $number2 = type_number 123;
    isa_ok $number1, 'Data::Object::Number';
    isa_ok $number2, 'Data::Object::Number';
    isnt refaddr($number1), refaddr($number2);
};

subtest 'test the type_number function - positve number' => sub {
    my $number1 = type_number '+123';
    my $number2 = type_number '+123';
    isa_ok $number1, 'Data::Object::Number';
    isa_ok $number2, 'Data::Object::Number';
    isnt refaddr($number1), refaddr($number2);
};

ok 1 and done_testing;
