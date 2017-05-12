use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Hash';
can_ok 'Data::Object::Hash', 'empty';

use Scalar::Util 'refaddr';

subtest 'test the empty method' => sub {
    my $hash = Data::Object::Hash->new({1..8});

    my @argument = ();
    my $empty = $hash->empty(@argument);

    is refaddr($hash), refaddr($empty);
    is_deeply $empty, {};

    isa_ok $hash, 'Data::Object::Hash';
    isa_ok $empty, 'Data::Object::Hash';
};

ok 1 and done_testing;
