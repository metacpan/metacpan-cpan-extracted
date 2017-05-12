
use strict;
use warnings;
use Test::More;
use Beam::Wire;

my $wire = Beam::Wire->new;

ok $wire->is_meta( { '$class' => 'Foo' } ), 'is meta when $class is specified';
ok $wire->is_meta( { '$extends' => 'foo' } ), 'is meta when $extends is specified';
ok $wire->is_meta( { '$value' => 'foo' } ), 'is meta when $value is specified';
ok $wire->is_meta( { '$config' => 'Foo' } ), 'is meta when $config is specified';
ok $wire->is_meta( { '$ref' => 'foo' } ), 'is meta when $ref is specified';

ok $wire->is_meta( { '$class' => 'Foo', arg => 'value' } ),
    'is meta when $class is specified with unknown keys';

subtest 'unprefixed meta only in root nodes' => sub {
    ok $wire->is_meta( { 'class' => 'Foo' }, 1 ), 'is meta when class is specified in root';
    ok $wire->is_meta( { 'extends' => 'foo' }, 1 ), 'is meta when extends is specified in root';
    ok $wire->is_meta( { 'value' => 'foo' }, 1 ), 'is meta when value is specified in root';
    ok $wire->is_meta( { 'config' => 'Foo' }, 1 ), 'is meta when config is specified in root';
    ok $wire->is_meta( { 'ref' => 'foo' }, 1 ), 'is meta when ref is specified in root';

    ok !$wire->is_meta( { 'class' => 'Foo', unknown => 1 }, 1 ),
        'is not meta when unrecognized key is specified in root';

    ok !$wire->is_meta( { 'class' => 'Foo' } ), 'is not meta when class is specified outside root';
    ok !$wire->is_meta( { 'extends' => 'foo' } ), 'is not meta when extends is specified outside root';
    ok !$wire->is_meta( { 'value' => 'foo' } ), 'is not meta when value is specified outside root';
    ok !$wire->is_meta( { 'config' => 'Foo' } ), 'is not meta when config is specified outside root';
    ok !$wire->is_meta( { 'ref' => 'foo' } ), 'is not meta when ref is specified outside root';
};

done_testing;
