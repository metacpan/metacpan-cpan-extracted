use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Hash';
can_ok 'Data::Object::Hash', 'each_n_values';

use Scalar::Util 'refaddr';

subtest 'test the each_n_values method' => sub {
    my $hash = Data::Object::Hash->new({1..8});

    my $values = [];
    my @argument = (3, sub { push @$values, 0 + @_; });
    my $each_n_values = $hash->each_n_values(@argument);

    is refaddr($hash), refaddr($each_n_values);
    is_deeply $each_n_values, $hash;
    is_deeply $values, [3,1];

    isa_ok $hash, 'Data::Object::Hash';
    isa_ok $each_n_values, 'Data::Object::Hash';
};

ok 1 and done_testing;
