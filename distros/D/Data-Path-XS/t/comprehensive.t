use strict;
use warnings;
use Test::More;

use Data::Path::XS qw(path_get path_set path_delete path_exists
                      patha_get patha_set patha_delete patha_exists
                      path_compile pathc_set);

# Double slashes handling (consistency with keyword API)
subtest 'double slashes' => sub {
    my $data = { a => { b => 1 } };

    is(path_get($data, '//a//b'), 1, 'path_get handles double slashes');
    is(path_get($data, '/a//b/'), 1, 'path_get handles trailing slash');
    is(path_get($data, '/a/b//'), 1, 'path_get handles multiple trailing slashes');
    ok(path_exists($data, '//a//b'), 'path_exists handles double slashes');
    ok(path_exists($data, '/a/b//'), 'path_exists handles multiple trailing slashes');

    my $d = {};
    path_set($d, '//x//y', 42);
    is($d->{x}{y}, 42, 'path_set handles double slashes');

    $d = {};
    path_set($d, '/x/y//', 99);
    is($d->{x}{y}, 99, 'path_set handles multiple trailing slashes');

    $d = { a => { b => 'val' } };
    my $deleted = path_delete($d, '/a/b//');
    is($deleted, 'val', 'path_delete handles multiple trailing slashes');
    ok(!exists $d->{a}{b}, 'path_delete actually deleted with trailing slashes');
};

# Edge cases for path_get
subtest 'path_get edge cases' => sub {
    # Empty/special values
    my $data = {
        empty_str => '',
        zero => 0,
        undef_val => undef,
        empty_hash => {},
        empty_arr => [],
    };

    is(path_get($data, '/empty_str'), '', 'get empty string');
    is(path_get($data, '/zero'), 0, 'get zero');
    is(path_get($data, '/undef_val'), undef, 'get undef');
    is_deeply(path_get($data, '/empty_hash'), {}, 'get empty hash');
    is_deeply(path_get($data, '/empty_arr'), [], 'get empty array');

    # Non-existent paths
    is(path_get($data, '/nonexistent'), undef, 'missing key');
    is(path_get($data, '/empty_str/deeper'), undef, 'traverse into non-ref');
    is(path_get($data, '/empty_hash/missing'), undef, 'missing in empty hash');

    # Root
    is_deeply(path_get($data, ''), $data, 'empty path returns root');

    # Nested arrays
    my $arr = { a => [[1, 2], [3, 4]] };
    is(path_get($arr, '/a/0/0'), 1, 'nested array [0][0]');
    is(path_get($arr, '/a/1/1'), 4, 'nested array [1][1]');
    is(path_get($arr, '/a/2/0'), undef, 'out of bounds outer');
    is(path_get($arr, '/a/0/5'), undef, 'out of bounds inner');

    # Large indices
    my $sparse = { arr => [] };
    $sparse->{arr}[1000] = 'far';
    is(path_get($sparse, '/arr/1000'), 'far', 'large array index');
    is(path_get($sparse, '/arr/500'), undef, 'sparse array gap');
};

# Return values from set operations
subtest 'set return values' => sub {
    my $data = {};
    my $ret1 = path_set($data, '/a', 42);
    is($ret1, 42, 'path_set returns value set');

    my $ret2 = patha_set($data, ['b'], 99);
    is($ret2, 99, 'patha_set returns value set');

    my $ret3 = pathc_set($data, path_compile('/c'), 77);
    is($ret3, 77, 'pathc_set returns value set');
};

# Edge cases for path_set
subtest 'path_set edge cases' => sub {
    # Overwrite different types
    my $data = { key => 'string' };
    path_set($data, '/key', [1, 2, 3]);
    is_deeply($data->{key}, [1, 2, 3], 'overwrite string with array');

    path_set($data, '/key', { a => 1 });
    is_deeply($data->{key}, { a => 1 }, 'overwrite array with hash');

    # Numeric string keys create arrays when they look like indices
    my $d = {};
    path_set($d, '/arr/0/val', 'x');
    is_deeply($d, { arr => [{ val => 'x' }] }, 'numeric key after hash creates array');

    # Set special values
    $data = {};
    path_set($data, '/a', undef);
    ok(exists $data->{a}, 'set undef creates key');
    is($data->{a}, undef, 'set undef value');

    path_set($data, '/b', 0);
    is($data->{b}, 0, 'set zero');

    path_set($data, '/c', '');
    is($data->{c}, '', 'set empty string');

    # Deep creation
    $data = {};
    path_set($data, '/a/b/c/d/e/f/g', 'deep');
    is($data->{a}{b}{c}{d}{e}{f}{g}, 'deep', 'deep path creation');

    # Mixed hash/array creation
    $data = {};
    path_set($data, '/users/0/name', 'Alice');
    is_deeply($data, { users => [ { name => 'Alice' } ] }, 'auto-create array for numeric key');
};

# Edge cases for path_exists
subtest 'path_exists edge cases' => sub {
    my $data = {
        undef_val => undef,
        zero => 0,
        empty => '',
        arr => [undef, 0, ''],
    };

    ok(path_exists($data, '/undef_val'), 'exists with undef value');
    ok(path_exists($data, '/zero'), 'exists with zero value');
    ok(path_exists($data, '/empty'), 'exists with empty string');
    ok(path_exists($data, '/arr/0'), 'exists with undef in array');
    ok(path_exists($data, '/arr/1'), 'exists with zero in array');
    ok(path_exists($data, '/arr/2'), 'exists with empty in array');

    ok(!path_exists($data, '/missing'), 'not exists missing key');
    ok(!path_exists($data, '/arr/99'), 'not exists out of bounds');
    ok(!path_exists($data, '/zero/deeper'), 'not exists through non-ref');

    ok(path_exists($data, ''), 'root always exists');
};

# Edge cases for path_delete
subtest 'path_delete edge cases' => sub {
    # Delete returns old value
    my $data = { a => 'val', b => 0, c => undef, d => '' };

    is(path_delete($data, '/a'), 'val', 'delete returns string');
    ok(!exists $data->{a}, 'key removed');

    is(path_delete($data, '/b'), 0, 'delete returns zero');
    is(path_delete($data, '/c'), undef, 'delete returns undef');
    is(path_delete($data, '/d'), '', 'delete returns empty string');

    # Delete from array
    $data = { arr => [10, 20, 30] };
    is(path_delete($data, '/arr/1'), 20, 'delete array element');
    ok(!exists $data->{arr}[1], 'array element deleted (sparse)');
    is($data->{arr}[0], 10, 'other elements intact');
    is($data->{arr}[2], 30, 'other elements intact');

    # Delete nonexistent
    is(path_delete($data, '/missing'), undef, 'delete missing returns undef');
    is(path_delete($data, '/arr/99'), undef, 'delete out of bounds returns undef');
};

# Array API tests
subtest 'patha_* basic operations' => sub {
    my $data = { a => { b => [1, 2, { c => 3 }] } };

    # patha_get
    is(patha_get($data, []), $data, 'empty path returns root');
    is(patha_get($data, ['a', 'b', 0]), 1, 'array path get');
    is(patha_get($data, ['a', 'b', 2, 'c']), 3, 'mixed path');
    is(patha_get($data, ['missing']), undef, 'missing returns undef');

    # patha_exists
    ok(patha_exists($data, []), 'empty path exists');
    ok(patha_exists($data, ['a', 'b', 2, 'c']), 'deep path exists');
    ok(!patha_exists($data, ['a', 'b', 99]), 'out of bounds not exists');

    # patha_set
    my $d = {};
    patha_set($d, ['x', 'y'], 'val');
    is($d->{x}{y}, 'val', 'patha_set creates path');

    patha_set($d, ['arr', 0, 'name'], 'test');
    is_deeply($d->{arr}, [{ name => 'test' }], 'patha_set with integer key creates array');

    # patha_delete
    $d = { a => { b => 1, c => 2 } };
    is(patha_delete($d, ['a', 'b']), 1, 'patha_delete returns value');
    ok(!exists $d->{a}{b}, 'key deleted');
    ok(exists $d->{a}{c}, 'sibling intact');
};

# Integer keys in array API
subtest 'patha_* integer keys' => sub {
    my $data = { arr => [10, 20, 30] };

    # Integer vs string keys
    is(patha_get($data, ['arr', 1]), 20, 'integer index');
    is(patha_get($data, ['arr', '1']), 20, 'string index');

    # Set with integer
    my $d = {};
    patha_set($d, ['list', 0], 'first');
    patha_set($d, ['list', 1], 'second');
    is_deeply($d->{list}, ['first', 'second'], 'integer keys create array');
};

# Error handling
subtest 'error handling' => sub {
    # Paths without leading slash now work (consistent with keyword API)
    my $data = { a => { b => 1 } };
    is(path_get($data, 'a/b'), 1, 'path without leading slash works');

    # Cannot set/delete root (empty string)
    eval { path_set({}, '', 'val') };
    like($@, qr/Cannot set root/, 'cannot set root (empty)');

    eval { path_delete({}, '') };
    like($@, qr/Cannot delete root/, 'cannot delete root (empty)');

    # Cannot set/delete root (slash-only)
    eval { path_set({}, '/', 'val') };
    like($@, qr/Cannot set root/, 'cannot set root (/)');

    eval { path_delete({}, '/') };
    like($@, qr/Cannot delete root/, 'cannot delete root (/)');

    # Exists with slash-only returns true
    ok(path_exists({}, '/'), 'path_exists "/" returns true');

    eval { patha_set({}, [], 'val') };
    like($@, qr/Cannot set root/, 'cannot patha_set root');

    eval { patha_delete({}, []) };
    like($@, qr/Cannot delete root/, 'cannot patha_delete root');

    # Type mismatch: string key on array
    eval { path_set({ x => [1,2,3] }, '/x/y', 'val') };
    like($@, qr/Invalid array index/, 'path_set string key on array croaks');

    # Out-of-bounds negative index croaks
    eval { path_set({ arr => [] }, '/arr/-1', 'val') };
    like($@, qr/Failed to store/, 'path_set OOB negative index croaks');

    eval { patha_set({ arr => [] }, ['arr', -1], 'val') };
    like($@, qr/Failed to store/, 'patha_set OOB negative index croaks');

    eval { pathc_set({ arr => [] }, path_compile('/arr/-1'), 'val') };
    like($@, qr/Failed to store/, 'pathc_set OOB negative index croaks');
};

# Reference integrity
subtest 'reference integrity' => sub {
    my $inner = { x => 1 };
    my $data = { ref => $inner };

    my $got = path_get($data, '/ref');
    is($got, $inner, 'get returns same reference');

    $got->{x} = 2;
    is($data->{ref}{x}, 2, 'modifying returned ref affects original');
    is($inner->{x}, 2, 'original inner also changed');

    # Set copies reference (standard Perl SV copy behavior)
    my $val = { y => 1 };
    path_set($data, '/new', $val);
    $val->{y} = 2;
    is($data->{new}{y}, 2, 'set copies ref, both point to same hash');
};

# Unicode/binary keys
subtest 'special characters in keys' => sub {
    my $data = {
        "key with spaces" => 1,
        "key\twith\ttabs" => 2,
        "émoji→here" => 3,
        "" => 4,  # empty key
    };

    is(path_get($data, '/key with spaces'), 1, 'spaces in key');
    is(path_get($data, "/key\twith\ttabs"), 2, 'tabs in key');
    is(path_get($data, '/émoji→here'), 3, 'unicode in key');
    # Note: "/" now means root, not empty key. Use array API for empty keys.
    is(path_get($data, '/'), $data, 'slash alone returns root');

    # Array API - use this for empty string keys
    is(patha_get($data, ['key with spaces']), 1, 'patha spaces');
    is(patha_get($data, ['émoji→here']), 3, 'patha unicode');
    is(patha_get($data, ['']), 4, 'patha empty key');
};

# Numeric edge cases
subtest 'numeric index edge cases' => sub {
    my $arr = { list => [0, 1, 2, 3, 4] };

    # Negative indices work like Perl arrays
    is(patha_get($arr, ['list', -1]), 4, 'negative index -1 gets last element');
    is(patha_get($arr, ['list', -2]), 3, 'negative index -2 gets second to last');

    # String that looks like negative number
    is(path_get($arr, '/list/-1'), 4, 'string -1 gets last element');

    # Leading zeros should not work
    is(path_get($arr, '/list/01'), undef, 'leading zero rejected');
    is(path_get($arr, '/list/00'), undef, 'double zero rejected');

    # But single zero works
    is(path_get($arr, '/list/0'), 0, 'single zero works');

    # Very large indices (overflow protection)
    is(path_get($arr, '/list/9999999999999999999'), undef, 'huge index returns undef');
    is(path_get($arr, '/list/12345678901234567890'), undef, 'overflow-size index returns undef');

    # Valid large index (within reasonable range)
    my $sparse = { arr => [] };
    $sparse->{arr}[999999] = 'far';
    is(path_get($sparse, '/arr/999999'), 'far', 'large but valid index works');
};

# Double slashes should not affect autovivification type detection
subtest 'double slashes autovivification' => sub {
    # Without double slashes - creates array for numeric next component
    my $d1 = {};
    path_set($d1, '/a/0', 'value');
    ok(ref($d1->{a}) eq 'ARRAY', 'single slash: creates array for numeric component');
    is($d1->{a}[0], 'value', 'single slash: value stored correctly');

    # With double slashes - should also create array (bug fix verification)
    my $d2 = {};
    path_set($d2, '/a//0', 'value');
    ok(ref($d2->{a}) eq 'ARRAY', 'double slash: creates array for numeric component');
    is($d2->{a}[0], 'value', 'double slash: value stored correctly');

    # Multiple levels with double slashes
    my $d3 = {};
    path_set($d3, '/x//y//0//z', 'deep');
    ok(ref($d3->{x}) eq 'HASH', 'x is hash (next is y)');
    ok(ref($d3->{x}{y}) eq 'ARRAY', 'y is array (next is 0)');
    ok(ref($d3->{x}{y}[0]) eq 'HASH', '0 is hash (next is z)');
    is($d3->{x}{y}[0]{z}, 'deep', 'deep value stored correctly');

    # Triple slashes
    my $d4 = {};
    path_set($d4, '/a///0', 'triple');
    ok(ref($d4->{a}) eq 'ARRAY', 'triple slash: creates array');
    is($d4->{a}[0], 'triple', 'triple slash: value stored');

    # patha_* API doesn't have this issue (no slash parsing), but verify consistency
    my $d5 = {};
    patha_set($d5, ['a', 0], 'patha');
    ok(ref($d5->{a}) eq 'ARRAY', 'patha: creates array for numeric');
    is($d5->{a}[0], 'patha', 'patha: value stored');
};

# Autovivification over existing non-ref scalar intermediates
subtest 'autovivify over non-ref intermediate' => sub {
    # path_set replaces non-ref scalar with hash
    my $d1 = { a => 'existing_string' };
    path_set($d1, '/a/b', 42);
    is(ref($d1->{a}), 'HASH', 'path_set replaces scalar with hash');
    is($d1->{a}{b}, 42, 'path_set stores value through replaced intermediate');

    # path_set replaces non-ref scalar with array
    my $d2 = { a => 'existing_string' };
    path_set($d2, '/a/0', 'val');
    is(ref($d2->{a}), 'ARRAY', 'path_set replaces scalar with array');
    is($d2->{a}[0], 'val', 'path_set stores value in new array');

    # patha_set same behavior
    my $d3 = { a => 'existing_string' };
    patha_set($d3, ['a', 'b'], 99);
    is(ref($d3->{a}), 'HASH', 'patha_set replaces scalar with hash');
    is($d3->{a}{b}, 99, 'patha_set stores value through replaced intermediate');
};

done_testing;
