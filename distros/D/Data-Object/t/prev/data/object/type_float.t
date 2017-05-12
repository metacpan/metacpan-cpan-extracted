use strict;
use warnings;
use Test::More;

plan skip_all => 'Missing implicit dependencies. Tests skipped.' unless eval q(
    require Data::Object::Float;
    1;
);

use Data::Object 'type_float';
use Scalar::Util 'refaddr';

can_ok 'Data::Object', 'type_float';

subtest 'test the type_float function' => sub {
    my $float1 = type_float 345.56;
    my $float2 = type_float 345.56;
    isa_ok $float1, 'Data::Object::Float';
    isa_ok $float2, 'Data::Object::Float';
    isnt refaddr($float1), refaddr($float2);
};

subtest 'test the type_float function - positive' => sub {
    my $float1 = type_float '+345.56';
    my $float2 = type_float '+345.56';
    isa_ok $float1, 'Data::Object::Float';
    isa_ok $float2, 'Data::Object::Float';
    isnt refaddr($float1), refaddr($float2);
};

ok 1 and done_testing;
