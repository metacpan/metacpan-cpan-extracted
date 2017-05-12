use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Hash';
can_ok 'Data::Object::Hash', 'values';

use Scalar::Util 'refaddr';

subtest 'test the values method' => sub {
    my $hash = Data::Object::Hash->new({1..8});

    my @argument = ();
    my $values = $hash->values(@argument);

    isnt refaddr($hash), refaddr($values);
    is_deeply [sort @{$values}], [sort values %{$hash}];

    isa_ok $hash, 'Data::Object::Hash';
    isa_ok $values, 'Data::Object::Array';
};

ok 1 and done_testing;
