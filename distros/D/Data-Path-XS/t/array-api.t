use strict;
use warnings;
use Test::More;

use Data::Path::XS qw(patha_get patha_set patha_delete patha_exists);

# Basic hash access
subtest 'patha_get - hash access' => sub {
    my $data = { a => 1, b => { c => 2, d => { e => 3 } } };

    is(patha_get($data, []), $data, 'empty path returns root');
    is(patha_get($data, ['a']), 1, 'single level');
    is(patha_get($data, ['b', 'c']), 2, 'two levels');
    is(patha_get($data, ['b', 'd', 'e']), 3, 'three levels');
    is(patha_get($data, ['nonexistent']), undef, 'missing key');
    is(patha_get($data, ['b', 'nope']), undef, 'missing nested key');
    is(patha_get($data, ['b', 'c', 'deeper']), undef, 'traverse into non-ref');
};

# Basic array access
subtest 'patha_get - array access' => sub {
    my $data = { arr => [10, 20, [30, 40, [50]]] };

    is(patha_get($data, ['arr', 0]), 10, 'first element');
    is(patha_get($data, ['arr', 1]), 20, 'second element');
    is(patha_get($data, ['arr', 2, 0]), 30, 'nested array');
    is(patha_get($data, ['arr', 2, 2, 0]), 50, 'deeply nested');
    is(patha_get($data, ['arr', 99]), undef, 'out of bounds');
};

# Mixed hash/array
subtest 'patha_get - mixed structures' => sub {
    my $data = {
        users => [
            { name => 'Alice', tags => ['admin', 'user'] },
            { name => 'Bob', tags => ['user'] },
        ]
    };

    is(patha_get($data, ['users', 0, 'name']), 'Alice', 'hash in array');
    is(patha_get($data, ['users', 1, 'name']), 'Bob', 'second user');
    is(patha_get($data, ['users', 0, 'tags', 0]), 'admin', 'array in hash in array');
    is(patha_get($data, ['users', 0, 'tags', 1]), 'user', 'second tag');
};

# Numeric key handling
subtest 'patha_get - numeric keys' => sub {
    my $data = { arr => [0, 1, 2, 3, 4] };

    # Integer keys
    is(patha_get($data, ['arr', 0]), 0, 'integer 0');
    is(patha_get($data, ['arr', 2]), 2, 'integer 2');

    # String numeric keys
    is(patha_get($data, ['arr', '0']), 0, 'string "0"');
    is(patha_get($data, ['arr', '2']), 2, 'string "2"');

    # Negative indices - work with Perl array semantics
    is(patha_get($data, ['arr', -1]), 4, 'negative index -1 gets last element');
    is(patha_get($data, ['arr', -2]), 3, 'negative index -2 gets second to last');

    # Leading zeros - treated as hash key, not array index
    is(patha_get($data, ['arr', '00']), undef, 'leading zero rejected');
    is(patha_get($data, ['arr', '01']), undef, 'leading zero rejected');
    is(patha_get($data, ['arr', '007']), undef, 'leading zeros rejected');
};

# Edge values
subtest 'patha_get - edge values' => sub {
    my $data = {
        empty_str => '',
        zero => 0,
        undef_val => undef,
        false => !1,
    };

    is(patha_get($data, ['empty_str']), '', 'empty string');
    is(patha_get($data, ['zero']), 0, 'zero');
    is(patha_get($data, ['undef_val']), undef, 'undef value');
    is(patha_get($data, ['false']), !1, 'false value');
};

# patha_set basic
subtest 'patha_set - basic' => sub {
    my $data = {};

    patha_set($data, ['a'], 1);
    is($data->{a}, 1, 'set single level');

    patha_set($data, ['b', 'c'], 2);
    is($data->{b}{c}, 2, 'set with autovivification');
    is(ref($data->{b}), 'HASH', 'created hash');
};

# patha_set autovivification
subtest 'patha_set - autovivification' => sub {
    my $data = {};

    # String keys create hashes
    patha_set($data, ['a', 'b', 'c'], 'deep');
    is($data->{a}{b}{c}, 'deep', 'deep hash autoviv');
    is(ref($data->{a}), 'HASH', 'level 1 is hash');
    is(ref($data->{a}{b}), 'HASH', 'level 2 is hash');

    # Numeric keys create arrays
    patha_set($data, ['arr', 0, 'name'], 'first');
    is(ref($data->{arr}), 'ARRAY', 'numeric key creates array');
    is(ref($data->{arr}[0]), 'HASH', 'then hash for string key');
    is($data->{arr}[0]{name}, 'first', 'value set correctly');

    # Mixed
    patha_set($data, ['x', 0, 1, 'y'], 'mixed');
    is(ref($data->{x}), 'ARRAY', 'x is array');
    is(ref($data->{x}[0]), 'ARRAY', 'x[0] is array');
    is(ref($data->{x}[0][1]), 'HASH', 'x[0][1] is hash');
    is($data->{x}[0][1]{y}, 'mixed', 'value correct');
};

# patha_set overwrite
subtest 'patha_set - overwrite' => sub {
    my $data = { a => { b => 1 } };

    patha_set($data, ['a', 'b'], 2);
    is($data->{a}{b}, 2, 'overwrite existing');

    patha_set($data, ['a', 'b'], 'string');
    is($data->{a}{b}, 'string', 'change type');
};

# patha_set array elements
subtest 'patha_set - array elements' => sub {
    my $data = { arr => [1, 2, 3] };

    patha_set($data, ['arr', 1], 'two');
    is($data->{arr}[1], 'two', 'overwrite array element');

    patha_set($data, ['arr', 5], 'six');
    is($data->{arr}[5], 'six', 'sparse array');
    is($data->{arr}[4], undef, 'gap is undef');
};

# patha_set reference semantics
subtest 'patha_set - reference semantics' => sub {
    my $data = {};
    my $ref = { inner => 1 };

    patha_set($data, ['r'], $ref);
    is($data->{r}, $ref, 'reference stored');

    $ref->{inner} = 2;
    is($data->{r}{inner}, 2, 'changes reflected');
};

# patha_exists
subtest 'patha_exists - basic' => sub {
    my $data = {
        a => 1,
        b => { c => 2 },
        arr => [10, 20, 30],
        zero => 0,
        empty => '',
        undef_val => undef,
    };

    ok(patha_exists($data, []), 'empty path exists');
    ok(patha_exists($data, ['a']), 'existing key');
    ok(!patha_exists($data, ['nope']), 'missing key');
    ok(patha_exists($data, ['b', 'c']), 'nested exists');
    ok(!patha_exists($data, ['b', 'd']), 'nested missing');
    ok(patha_exists($data, ['arr', 0]), 'array element exists');
    ok(patha_exists($data, ['arr', 2]), 'last array element');
    ok(!patha_exists($data, ['arr', 99]), 'out of bounds');

    # Edge values - exist even if falsy
    ok(patha_exists($data, ['zero']), 'zero exists');
    ok(patha_exists($data, ['empty']), 'empty string exists');
    ok(patha_exists($data, ['undef_val']), 'undef value exists');
};

# patha_exists sparse array
subtest 'patha_exists - sparse array' => sub {
    my $data = { arr => [] };
    $data->{arr}[5] = 'five';

    ok(!patha_exists($data, ['arr', 0]), 'gap does not exist');
    ok(!patha_exists($data, ['arr', 4]), 'gap before set');
    ok(patha_exists($data, ['arr', 5]), 'set element exists');
    ok(!patha_exists($data, ['arr', 6]), 'after set does not exist');
};

# patha_delete
subtest 'patha_delete - basic' => sub {
    my $data = { a => 1, b => 2, c => { d => 3 } };

    my $del = patha_delete($data, ['a']);
    is($del, 1, 'returns deleted value');
    ok(!exists $data->{a}, 'key removed');
    is($data->{b}, 2, 'other keys intact');

    $del = patha_delete($data, ['c', 'd']);
    is($del, 3, 'nested delete');
    ok(!exists $data->{c}{d}, 'nested key removed');
    ok(exists $data->{c}, 'parent preserved');
};

# patha_delete array
subtest 'patha_delete - array' => sub {
    my $data = { arr => [10, 20, 30, 40] };

    my $del = patha_delete($data, ['arr', 1]);
    is($del, 20, 'deleted array element');
    ok(!exists $data->{arr}[1], 'element removed');
    is(scalar(@{$data->{arr}}), 4, 'array length unchanged (sparse)');
    is($data->{arr}[0], 10, 'other elements intact');
    is($data->{arr}[2], 30, 'later elements intact');
};

# patha_delete missing
subtest 'patha_delete - missing paths' => sub {
    my $data = { a => 1 };

    my $del = patha_delete($data, ['nonexistent']);
    is($del, undef, 'delete missing returns undef');

    $del = patha_delete($data, ['a', 'b', 'c']);
    is($del, undef, 'delete through non-ref returns undef');

    is($data->{a}, 1, 'original data unchanged');
};

# patha_delete return value
subtest 'patha_delete - return values' => sub {
    my $data = {
        zero => 0,
        empty => '',
        ref => { x => 1 },
    };

    my $del = patha_delete($data, ['zero']);
    is($del, 0, 'delete returns zero');

    $del = patha_delete($data, ['empty']);
    is($del, '', 'delete returns empty string');

    my $ref = $data->{ref};
    $del = patha_delete($data, ['ref']);
    is($del, $ref, 'delete returns reference');
};

# Error conditions
subtest 'error conditions' => sub {
    eval { patha_set({}, [], 'val') };
    like($@, qr/Cannot set root/, 'cannot set root');

    eval { patha_delete({}, []) };
    like($@, qr/Cannot delete root/, 'cannot delete root');
};

# Negative indices
subtest 'negative indices' => sub {
    my $data = { arr => ['a', 'b', 'c', 'd', 'e'] };

    # patha_get with negative indices
    is(patha_get($data, ['arr', -1]), 'e', 'patha_get -1');
    is(patha_get($data, ['arr', -2]), 'd', 'patha_get -2');
    is(patha_get($data, ['arr', -5]), 'a', 'patha_get -5 (first element)');
    is(patha_get($data, ['arr', -6]), undef, 'patha_get -6 (out of bounds)');

    # patha_set with negative indices
    patha_set($data, ['arr', -1], 'last');
    is($data->{arr}[-1], 'last', 'patha_set -1');

    patha_set($data, ['arr', -3], 'middle');
    is($data->{arr}[2], 'middle', 'patha_set -3');

    # patha_exists with negative indices
    ok(patha_exists($data, ['arr', -1]), 'patha_exists -1');
    ok(patha_exists($data, ['arr', -5]), 'patha_exists -5');
    ok(!patha_exists($data, ['arr', -10]), 'patha_exists -10 (out of bounds)');

    # patha_delete with negative indices
    my $data2 = { arr => [1, 2, 3, 4, 5] };
    my $del = patha_delete($data2, ['arr', -1]);
    is($del, 5, 'patha_delete -1 returns last element');
    ok(!exists $data2->{arr}[4], 'element deleted');
};

# Large indices
subtest 'large indices' => sub {
    my $data = { arr => [] };

    patha_set($data, ['arr', 1000], 'far');
    is($data->{arr}[1000], 'far', 'large index set');
    is(patha_get($data, ['arr', 1000]), 'far', 'large index get');
    ok(patha_exists($data, ['arr', 1000]), 'large index exists');
    ok(!patha_exists($data, ['arr', 500]), 'gap does not exist');

    my $del = patha_delete($data, ['arr', 1000]);
    is($del, 'far', 'large index delete');
    ok(!patha_exists($data, ['arr', 1000]), 'deleted');
};

# Integer vs string keys
subtest 'integer vs string key handling' => sub {
    # When accessing array, both integer and numeric string work
    my $arr = { list => ['a', 'b', 'c'] };
    is(patha_get($arr, ['list', 1]), 'b', 'integer index');
    is(patha_get($arr, ['list', '1']), 'b', 'string index');

    # When accessing hash, numeric string is just a key
    my $hash = { data => { '1' => 'one', '2' => 'two' } };
    is(patha_get($hash, ['data', '1']), 'one', 'string key in hash');
    is(patha_get($hash, ['data', 1]), 'one', 'integer key in hash (stringified)');
};

done_testing;
