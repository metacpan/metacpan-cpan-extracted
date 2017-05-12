use strict;
use warnings;
use Test::More;

plan skip_all => 'Missing implicit dependencies. Tests skipped.' unless eval q(
    require Data::Object::Number;
    1;
);

use Data::Object 'type_integer';
use Scalar::Util 'refaddr';

can_ok 'Data::Object', 'type_integer';

subtest 'test the type_integer function - raw' => sub {
    my $integer1 = type_integer 9;
    my $integer2 = type_integer 9;
    isa_ok $integer1, 'Data::Object::Integer';
    isa_ok $integer2, 'Data::Object::Integer';
    isnt refaddr($integer1), refaddr($integer2);
};

subtest 'test the type_integer function - positive' => sub {
    my $integer1 = type_integer '+9';
    my $integer2 = type_integer '+9';
    isa_ok $integer1, 'Data::Object::Integer';
    isa_ok $integer2, 'Data::Object::Integer';
    isnt refaddr($integer1), refaddr($integer2);
};

subtest 'test the type_integer function - negative' => sub {
    my $integer1 = type_integer -9;
    my $integer2 = type_integer -9;
    isa_ok $integer1, 'Data::Object::Integer';
    isa_ok $integer2, 'Data::Object::Integer';
    isnt refaddr($integer1), refaddr($integer2);
};

ok 1 and done_testing;
