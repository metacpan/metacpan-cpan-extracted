use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Hash';
can_ok 'Data::Object::Hash', 'set';

use Scalar::Util 'refaddr';

subtest 'test the set method' => sub {
    my $hash = Data::Object::Hash->new({1..8});

    my @argument = (1,10);
    my $set = $hash->set(@argument);

    isnt refaddr($hash), refaddr($set);
    is $set, 10;

    isa_ok $hash, 'Data::Object::Hash';
    isa_ok $set, 'Data::Object::Number';
};

ok 1 and done_testing;
