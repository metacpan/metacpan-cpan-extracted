use strict;
use warnings;
use Test::More;

plan skip_all => 'Missing implicit dependencies. Tests skipped.' unless eval q(
    require Data::Object::String;
    1;
);

use Data::Object 'type_string';
use Scalar::Util 'refaddr';

can_ok 'Data::Object', 'type_string';

subtest 'test the type_string function' => sub {
    my $string1 = type_string "Hello";
    my $string2 = type_string "Hello";
    isa_ok $string1, 'Data::Object::String';
    isa_ok $string2, 'Data::Object::String';
    isnt refaddr($string1), refaddr($string2);
};

ok 1 and done_testing;
