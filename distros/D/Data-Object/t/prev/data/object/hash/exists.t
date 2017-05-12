use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Hash';
can_ok 'Data::Object::Hash', 'exists';

use Scalar::Util 'refaddr';

subtest 'test the exists method' => sub {
    my $hash = Data::Object::Hash->new({1..8,9,undef});

    my @argument = (1);
    my $exists = $hash->exists(@argument);

    isnt refaddr($hash), refaddr($exists);
    is $exists, 1;

    isa_ok $hash, 'Data::Object::Hash';
    isa_ok $exists, 'Data::Object::Number';
};

ok 1 and done_testing;
