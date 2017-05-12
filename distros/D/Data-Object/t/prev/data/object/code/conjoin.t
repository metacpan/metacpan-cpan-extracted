use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Code';
can_ok 'Data::Object::Code', 'conjoin';

use Scalar::Util 'refaddr';

subtest 'test the conjoin method' => sub {
    my $code = Data::Object::Code->new(sub { $_[0] % 2 });
    my $conjoin = $code->conjoin(sub { 1 });

    my $result;
    isnt refaddr($code), refaddr($conjoin);

    $result = $conjoin->(0);
    ok ! ref $result;
    is "$result", 0;

    $result = $conjoin->(1);
    ok ! ref $result;
    is "$result", 1;

    $result = $conjoin->(2);
    ok ! ref $result;
    is "$result", 0;

    $result = $conjoin->(3);
    ok ! ref $result;
    is "$result", 1;

    $result = $conjoin->(4);
    ok ! ref $result;
    is "$result", 0;

    $result = $conjoin->call(0);
    isa_ok $result, 'Data::Object::Number';
    is "$result", 0;

    $result = $conjoin->call(1);
    isa_ok $result, 'Data::Object::Number';
    is "$result", 1;

    $result = $conjoin->call(2);
    isa_ok $result, 'Data::Object::Number';
    is "$result", 0;

    $result = $conjoin->call(3);
    isa_ok $result, 'Data::Object::Number';
    is "$result", 1;

    $result = $conjoin->call(4);
    isa_ok $result, 'Data::Object::Number';
    is "$result", 0;

    isa_ok $code, 'Data::Object::Code';
    isa_ok $conjoin, 'Data::Object::Code';
};

ok 1 and done_testing;
