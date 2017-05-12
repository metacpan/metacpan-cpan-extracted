use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Hash';
can_ok 'Data::Object::Hash', 'pairs';

use Scalar::Util 'refaddr';

subtest 'test the pairs method' => sub {
    my $hash = Data::Object::Hash->new({1..8});
    my $pairs = $hash->pairs;

    isnt refaddr($hash), refaddr($pairs);
    is_deeply $_, [$_->[0], $_->[0] + 1] for @{$pairs};

    isa_ok $hash, 'Data::Object::Hash';
    isa_ok $pairs, 'Data::Object::Array';
};

ok 1 and done_testing;
