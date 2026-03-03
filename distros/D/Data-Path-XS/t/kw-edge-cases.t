use strict;
use warnings;
use Test::More;

use Data::Path::XS ':keywords';

# Empty path components (double slashes)
subtest 'double slashes in path' => sub {
    my $data = { a => { b => 1 } };

    my $v1 = pathget $data, "//a//b";
    is($v1, 1, 'pathget handles double slashes');

    # Multiple trailing slashes
    my $v2 = pathget $data, "/a/b//";
    is($v2, 1, 'pathget handles multiple trailing slashes');

    my $e1 = pathexists $data, "/a/b//";
    ok($e1, 'pathexists handles multiple trailing slashes');

    my $data2 = {};
    pathset $data2, "//x//y", 42;
    is($data2->{x}{y}, 42, 'pathset handles double slashes');

    $data2 = {};
    pathset $data2, "/x/y//", 99;
    is($data2->{x}{y}, 99, 'pathset handles multiple trailing slashes');

    $data2 = { a => { b => 'val' } };
    my $del = pathdelete $data2, "/a/b//";
    is($del, 'val', 'pathdelete handles multiple trailing slashes');
    ok(!exists $data2->{a}{b}, 'pathdelete actually deleted');
};

# Path without leading slash
subtest 'path without leading slash' => sub {
    my $data = { a => { b => 1 } };

    my $v = pathget $data, "a/b";
    is($v, 1, 'pathget works without leading slash');

    my $data2 = {};
    pathset $data2, "x/y", 99;
    is($data2->{x}{y}, 99, 'pathset works without leading slash');
};

# Single component path
subtest 'single component path' => sub {
    my $data = { key => 'value' };

    my $v = pathget $data, "/key";
    is($v, 'value', 'single component get');

    my $data2 = {};
    pathset $data2, "/single", 'test';
    is($data2->{single}, 'test', 'single component set');

    my $del = pathdelete $data, "/key";
    is($del, 'value', 'single component delete');
};

# Arrayref as root with numeric path
subtest 'arrayref as root' => sub {
    my $arr = [1, 2, 3];
    my $v = pathget $arr, "/0";
    is($v, 1, 'arrayref with numeric path works');

    my $v2 = pathget $arr, "/2";
    is($v2, 3, 'arrayref index 2');

    # Nested array in arrayref
    my $nested = [['a', 'b'], ['c', 'd']];
    my $v3 = pathget $nested, "/1/0";
    is($v3, 'c', 'nested arrayref access');
};

# Very long keys
subtest 'long keys' => sub {
    my $long_key = 'a' x 1000;
    my $data = {};

    pathset $data, "/$long_key", 'long';
    is($data->{$long_key}, 'long', 'can set with long key');

    my $v = pathget $data, "/$long_key";
    is($v, 'long', 'can get with long key');
};

# Special characters in keys (dynamic paths only)
subtest 'special characters (dynamic)' => sub {
    my $data = {};

    my $path1 = "/key with spaces";
    pathset $data, $path1, 'spaced';
    is($data->{'key with spaces'}, 'spaced', 'key with spaces');

    my $path2 = "/key-with-dashes";
    pathset $data, $path2, 'dashed';
    is($data->{'key-with-dashes'}, 'dashed', 'key with dashes');

    my $path3 = "/key.with.dots";
    pathset $data, $path3, 'dotted';
    is($data->{'key.with.dots'}, 'dotted', 'key with dots');
};

# Unicode keys (dynamic paths)
subtest 'unicode keys (dynamic)' => sub {
    my $data = {};

    my $path = "/ключ/キー";  # Russian and Japanese
    pathset $data, $path, 'unicode';
    is($data->{'ключ'}{'キー'}, 'unicode', 'unicode keys work');

    my $v = pathget $data, $path;
    is($v, 'unicode', 'unicode get works');
};

# Large array indices
subtest 'large array indices' => sub {
    my $data = {};

    pathset $data, "/arr/100", 'hundredth';
    is($data->{arr}[100], 'hundredth', 'large index set');
    is(scalar(@{$data->{arr}}), 101, 'array extended');

    my $v = pathget $data, "/arr/100";
    is($v, 'hundredth', 'large index get');
};

# Nested arrays
subtest 'nested arrays' => sub {
    my $data = { matrix => [[1,2],[3,4]] };

    my $v = pathget $data, "/matrix/0/1";
    is($v, 2, 'nested array access');

    my $v2 = pathget $data, "/matrix/1/0";
    is($v2, 3, 'second nested array');
};

# Setting over existing structure
subtest 'overwrite structure' => sub {
    my $data = { a => { b => { c => 1, d => 2 } } };

    pathset $data, "/a/b", 'flat';
    is($data->{a}{b}, 'flat', 'can overwrite hash with scalar');

    # Test traversing into scalar with dynamic path (handles gracefully)
    $data = { x => 'scalar' };
    my $path = "/x/y";  # Use dynamic path - it returns undef for type mismatch
    my $v = pathget $data, $path;
    is($v, undef, 'dynamic path returns undef for scalar traversal');
};

# Dynamic pathset autovivification over non-ref scalar intermediate
subtest 'pathset dynamic autovivify over non-ref scalar' => sub {
    my $d1 = { a => 'string' };
    my $path = '/a/b';
    pathset $d1, $path, 99;
    is(ref($d1->{a}), 'HASH', 'dynamic pathset replaces scalar intermediate with hash');
    is($d1->{a}{b}, 99, 'value stored correctly');

    my $d2 = { a => 'string' };
    $path = '/a/0';
    pathset $d2, $path, 'val';
    is(ref($d2->{a}), 'ARRAY', 'dynamic pathset replaces scalar intermediate with array');
    is($d2->{a}[0], 'val', 'value stored in new array');
};

# Reference values
subtest 'reference values' => sub {
    my $data = {};
    my $inner = { nested => 'hash' };

    pathset $data, "/ref", $inner;
    is($data->{ref}{nested}, 'hash', 'hashref stored');

    # Modify through reference
    $inner->{nested} = 'modified';
    is($data->{ref}{nested}, 'modified', 'reference semantics preserved');
};

# Undef data structure (dynamic path only - constant path would fail at compile)
subtest 'undef handling' => sub {
    my $data = undef;
    my $path = "/a/b";

    # pathget on undef with dynamic path should return undef
    my $v = pathget $data, $path;
    is($v, undef, 'dynamic pathget on undef returns undef');
};

# Empty string path
subtest 'empty path' => sub {
    my $data = { a => 1 };

    my $v = pathget $data, "";
    is($v, $data, 'empty path returns root data');
};

# Leading zeros in indices - should be treated as hash keys, not array indices
subtest 'leading zeros' => sub {
    # With leading zeros, the component should be treated as a hash key
    my $data = { arr => { '007' => 'james' } };

    # Constant path with leading zero
    my $v = pathget $data, "/arr/007";
    is($v, 'james', 'leading zero treated as hash key (constant path)');

    # Dynamic path should behave the same
    my $path = "/arr/007";
    my $v2 = pathget $data, $path;
    is($v2, 'james', 'leading zero treated as hash key (dynamic path)');

    # Setting with leading zeros
    my $data2 = {};
    pathset $data2, "/x/007", 'bond';
    ok(exists $data2->{x}{'007'}, 'set with leading zero creates hash key');
    is($data2->{x}{'007'}, 'bond', 'value correctly set');
};

# Very long numeric strings (overflow protection)
subtest 'long numeric strings' => sub {
    # 19+ digit numbers should be treated as hash keys (overflow protection)
    my $long_num = '1' x 20;  # 20 digits - too long for array index
    my $data = { arr => { $long_num => 'overflow' } };

    my $path = "/arr/$long_num";
    my $v = pathget $data, $path;
    is($v, 'overflow', 'long numeric string treated as hash key');

    # Constant path with long number
    my $data2 = { arr => { '12345678901234567890' => 'big' } };
    my $v2 = pathget $data2, "/arr/12345678901234567890";
    is($v2, 'big', 'constant long number treated as hash key');
};

# Empty path handling for dynamic paths
subtest 'empty path - dynamic' => sub {
    my $data = { a => 1 };

    # pathget with empty path returns root
    my $path = "";
    my $v = pathget $data, $path;
    is($v, $data, 'pathget empty dynamic path returns root');

    $path = "/";
    $v = pathget $data, $path;
    is($v, $data, 'pathget "/" dynamic path returns root');

    # pathexists with empty path returns true (root always exists)
    $path = "";
    ok((pathexists $data, $path), 'pathexists empty dynamic path returns true');

    # pathset with empty path should croak
    $path = "";
    eval { pathset $data, $path, 'x' };
    like($@, qr/Cannot set root/, 'pathset empty dynamic path croaks');

    $path = "/";
    eval { pathset $data, $path, 'x' };
    like($@, qr/Cannot set root/, 'pathset "/" dynamic path croaks');

    $path = "//";
    eval { pathset $data, $path, 'x' };
    like($@, qr/Cannot set root/, 'pathset "//" dynamic path croaks');

    $path = "///";
    eval { pathset $data, $path, 'x' };
    like($@, qr/Cannot set root/, 'pathset "///" dynamic path croaks');

    # pathdelete with empty path should croak
    $path = "";
    eval { pathdelete $data, $path };
    like($@, qr/Cannot delete root/, 'pathdelete empty dynamic path croaks');

    $path = "//";
    eval { pathdelete $data, $path };
    like($@, qr/Cannot delete root/, 'pathdelete "//" dynamic path croaks');

    $path = "///";
    eval { pathdelete $data, $path };
    like($@, qr/Cannot delete root/, 'pathdelete "///" dynamic path croaks');

    # pathset with type mismatch should croak (string key on array)
    $path = "/x/y";
    eval { my $d = { x => [1,2,3] }; pathset $d, $path, 'val' };
    like($@, qr/Cannot navigate/, 'pathset type mismatch dynamic path croaks');
};

# Empty path handling for constant paths
subtest 'empty path - constant' => sub {
    my $data = { a => 1 };

    # pathexists with constant empty path returns true
    # (This previously would generate invalid `exists $data` op)
    ok((pathexists $data, ""), 'pathexists constant empty path returns true');
    ok((pathexists $data, "/"), 'pathexists constant "/" path returns true');
    ok((pathexists $data, "//"), 'pathexists constant "//" path returns true');

    # pathset with constant "/" and "//" should croak (compile-time, needs string eval)
    eval q{ pathset $data, "/", 'x' };
    like($@, qr/Cannot set root/, 'pathset constant "/" croaks');

    eval q{ pathset $data, "//", 'x' };
    like($@, qr/Cannot set root/, 'pathset constant "//" croaks');
};

# Double slashes should not affect autovivification type detection (dynamic paths)
subtest 'double slashes autovivification - dynamic' => sub {
    # Without double slashes - creates array for numeric next component
    my $d1 = {};
    my $path1 = '/a/0';
    pathset $d1, $path1, 'value';
    ok(ref($d1->{a}) eq 'ARRAY', 'single slash: creates array for numeric component');
    is($d1->{a}[0], 'value', 'single slash: value stored correctly');

    # With double slashes - should also create array (bug fix verification)
    my $d2 = {};
    my $path2 = '/a//0';
    pathset $d2, $path2, 'value';
    ok(ref($d2->{a}) eq 'ARRAY', 'double slash: creates array for numeric component');
    is($d2->{a}[0], 'value', 'double slash: value stored correctly');

    # Multiple levels with double slashes
    my $d3 = {};
    my $path3 = '/x//y//0//z';
    pathset $d3, $path3, 'deep';
    ok(ref($d3->{x}) eq 'HASH', 'x is hash (next is y)');
    ok(ref($d3->{x}{y}) eq 'ARRAY', 'y is array (next is 0)');
    ok(ref($d3->{x}{y}[0]) eq 'HASH', '0 is hash (next is z)');
    is($d3->{x}{y}[0]{z}, 'deep', 'deep value stored correctly');

    # Verify pathget also works with double slashes after autovivification
    my $v = pathget $d3, '/x//y//0//z';
    is($v, 'deep', 'pathget retrieves value through double slashes');
};

# Negative array indices via keywords
subtest 'keyword negative indices' => sub {
    my $data = { arr => ['a', 'b', 'c', 'd', 'e'] };

    # pathget with negative indices (constant paths)
    my $v1 = pathget $data, "/arr/-1";
    is($v1, 'e', 'pathget constant -1');

    my $v2 = pathget $data, "/arr/-2";
    is($v2, 'd', 'pathget constant -2');

    # pathget with negative indices (dynamic paths)
    my $path = "/arr/-1";
    my $v3 = pathget $data, $path;
    is($v3, 'e', 'pathget dynamic -1');

    # pathexists with negative indices
    ok((pathexists $data, "/arr/-1"), 'pathexists constant -1');
    ok(!(pathexists $data, "/arr/-6"), 'pathexists constant -6 out of bounds');

    # pathset with negative index (dynamic - constant would autovivify)
    my $data2 = { arr => [1, 2, 3] };
    my $spath = "/arr/-1";
    pathset $data2, $spath, 'last';
    is($data2->{arr}[-1], 'last', 'pathset dynamic -1');

    # pathdelete with negative index
    my $data3 = { arr => [10, 20, 30] };
    my $del = pathdelete $data3, "/arr/-1";
    is($del, 30, 'pathdelete constant -1');

    # OOB negative index croaks
    my $data4 = { arr => [] };
    my $oob_path = "/arr/-1";
    eval { pathset $data4, $oob_path, 'val' };
    like($@, qr/Failed to store/, 'pathset dynamic OOB negative index croaks');
};

done_testing();
