use strict;
use warnings;
use Test::More;

plan skip_all => 'Missing implicit dependencies. Tests skipped.' unless eval q(
    require Data::Object::Universal;
    1;
);

use Data::Object 'type_universal';
use Scalar::Util 'refaddr';

can_ok 'Data::Object', 'type_universal';

subtest 'test the type_universal function' => sub {
    my $universal1 = type_universal 'Test::More';
    my $universal2 = type_universal 'Test::More';
    isa_ok $universal1, 'Data::Object::Universal';
    isa_ok $universal2, 'Data::Object::Universal';
    isnt refaddr($universal1), refaddr($universal2);
};

ok 1 and done_testing;
