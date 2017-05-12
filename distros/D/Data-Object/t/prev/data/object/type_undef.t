use strict;
use warnings;
use Test::More;

plan skip_all => 'Missing implicit dependencies. Tests skipped.' unless eval q(
    require Data::Object::Undef;
    1;
);

use Data::Object 'type_undef';
use Scalar::Util 'refaddr';

can_ok 'Data::Object', 'type_undef';

subtest 'test the type_undef function' => sub {
    my $undef1 = type_undef undef;
    my $undef2 = type_undef undef;
    isa_ok $undef1, 'Data::Object::Undef';
    isa_ok $undef2, 'Data::Object::Undef';
    isnt refaddr($undef1), refaddr($undef2);
};

ok 1 and done_testing;
