use strict;
use warnings;
use Test::More;

plan skip_all => 'Missing implicit dependencies. Tests skipped.' unless eval q(
    require Data::Object::Code;
    1;
);

use Data::Object 'type_code';
use Scalar::Util 'refaddr';

can_ok 'Data::Object', 'type_code';

subtest 'test the type_code function' => sub {
    my $code1 = type_code sub {1};
    my $code2 = type_code sub {1};
    isa_ok $code1, 'Data::Object::Code';
    isa_ok $code2, 'Data::Object::Code';
    isnt refaddr($code1), refaddr($code2);
};

ok 1 and done_testing;
