use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Hash';
can_ok 'Data::Object::Hash', 'iterator';

use Scalar::Util 'refaddr';

subtest 'test the iterator method' => sub {
    my $hash = Data::Object::Hash->new({1..8});

    my $values = [];
    my @argument = ();
    my $iterator = $hash->iterator(@argument);
    while (my $value = $iterator->()) {
        push @$values, $value;
    }

    isnt refaddr($hash), refaddr($iterator);
    ok $iterator, ;
    is_deeply [sort @{$values}], [sort values %{$hash}];

    isa_ok $hash, 'Data::Object::Hash';
    isa_ok $iterator, 'Data::Object::Code';
};

ok 1 and done_testing;
