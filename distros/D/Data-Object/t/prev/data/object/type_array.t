use strict;
use warnings;
use Test::More;

plan skip_all => 'Missing implicit dependencies. Tests skipped.' unless eval q(
    require Data::Object::Array;
    1;
);

use Data::Object 'type_array';
use Scalar::Util 'refaddr';

can_ok 'Data::Object', 'type_array';

subtest 'test the type_array function' => sub {
    my $array1 = type_array [1..5];
    my $array2 = type_array [1..5];
    isa_ok $array1, 'Data::Object::Array';
    isa_ok $array2, 'Data::Object::Array';
    isnt refaddr($array1), refaddr($array2);
};

ok 1 and done_testing;
