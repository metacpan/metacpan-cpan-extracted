use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Hash';
can_ok 'Data::Object::Hash', 'each';

use Scalar::Util 'refaddr';

subtest 'test the each method' => sub {
    my $hash = Data::Object::Hash->new({1..8});

    my $data = {};
    my @argument = (sub { $data->{$_[0]} = $_[1]; });
    my $each = $hash->each(@argument);

    is refaddr($hash), refaddr($each);
    is_deeply $each, $each;
    is_deeply $hash, $data;

    isa_ok $hash, 'Data::Object::Hash';
    isa_ok $each, 'Data::Object::Hash';
};

ok 1 and done_testing;
