use strict;
use warnings;
use Test::More;

plan skip_all => 'Missing implicit dependencies. Tests skipped.' unless eval q(
    require Data::Object::Scalar;
    1;
);

use Data::Object 'type_scalar';
use Scalar::Util 'refaddr';

can_ok 'Data::Object', 'type_scalar';

subtest 'test the type_scalar function' => sub {
    my $scalar1 = type_scalar \*main;
    my $scalar2 = type_scalar \*main;
    isa_ok $scalar1, 'Data::Object::Scalar';
    isa_ok $scalar2, 'Data::Object::Scalar';
    isnt refaddr($scalar1), refaddr($scalar2);
};

ok 1 and done_testing;
