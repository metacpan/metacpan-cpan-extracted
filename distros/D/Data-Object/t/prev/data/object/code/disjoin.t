use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Code';
can_ok 'Data::Object::Code', 'disjoin';

use Scalar::Util 'refaddr';

subtest 'test the disjoin method' => sub {
    my $code = Data::Object::Code->new(sub { $_[0] % 2 });
    my $disjoin = $code->disjoin(sub { -1 });

    my $result;
    isnt refaddr($code), refaddr($disjoin);

    $result = $disjoin->call(0);
    isa_ok $result, 'Data::Object::Integer';
    is $result, -1;

    $result = $disjoin->call(1);
    isa_ok $result, 'Data::Object::Number';
    is $result,  1;

    $result = $disjoin->call(2);
    isa_ok $result, 'Data::Object::Integer';
    is $result, -1;

    $result = $disjoin->call(3);
    isa_ok $result, 'Data::Object::Number';
    is $result,  1;

    $result = $disjoin->call(4);
    isa_ok $result, 'Data::Object::Integer';
    is $result, -1;

    isa_ok $code, 'Data::Object::Code';
    isa_ok $disjoin, 'Data::Object::Code';
};

ok 1 and done_testing;
