use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Hash';
can_ok 'Data::Object::Hash', 'get';

use Scalar::Util 'refaddr';

subtest 'test the get method' => sub {
    my $hash = Data::Object::Hash->new({1..8});

    my @argument = (5);
    my $get = $hash->get(@argument);

    isnt refaddr($hash), refaddr($get);
    is $get, 6;

    isa_ok $hash, 'Data::Object::Hash';
    isa_ok $get, 'Data::Object::Number';
};

ok 1 and done_testing;
