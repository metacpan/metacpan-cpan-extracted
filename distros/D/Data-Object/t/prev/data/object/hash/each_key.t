use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Hash';
can_ok 'Data::Object::Hash', 'each_key';

use Scalar::Util 'refaddr';

subtest 'test the each_key method' => sub {
    my $hash = Data::Object::Hash->new({1..8});

    my $keys = [];
    my @argument = (sub { push @$keys, shift; });
    my $each_key = $hash->each_key(@argument);

    is refaddr($hash), refaddr($each_key);
    is_deeply $each_key, $hash;
    is_deeply [sort @$keys], [sort keys %{$hash}];

    isa_ok $hash, 'Data::Object::Hash';
    isa_ok $each_key, 'Data::Object::Hash';
};

ok 1 and done_testing;
