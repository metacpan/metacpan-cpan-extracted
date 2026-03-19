use strict;
use warnings;
use Test::More;
use Test::LeakTrace;

use Data::Path::XS qw(path_compile pathc_get pathc_set pathc_delete pathc_exists);

subtest 'path_compile basic' => sub {
    my $cp = path_compile('/foo/bar/baz');
    ok(defined $cp, 'compile returns defined value');
    isa_ok($cp, 'Data::Path::XS::Compiled');

    my $empty = path_compile('');
    ok(defined $empty, 'compile empty path');
};

subtest 'pathc_get' => sub {
    my $data = { a => { b => { c => 'deep' } } };
    my $cp = path_compile('/a/b/c');
    my $cp_root = path_compile('');
    my $cp_missing = path_compile('/a/x/y');

    is(pathc_get($data, $cp), 'deep', 'get deep value');
    is(pathc_get($data, $cp_root), $data, 'get root');
    is(pathc_get($data, $cp_missing), undef, 'get missing returns undef');

    # Traverse through non-reference
    my $scalar_data = { a => 'scalar_value' };
    my $cp_through = path_compile('/a/b/c');
    is(pathc_get($scalar_data, $cp_through), undef, 'get through non-ref returns undef');

    # Array access
    my $arr = { list => [10, 20, 30] };
    my $cp_arr = path_compile('/list/1');
    is(pathc_get($arr, $cp_arr), 20, 'get array element');
};

subtest 'pathc_set' => sub {
    my $data = { a => { b => 1 } };
    my $cp = path_compile('/a/b');

    pathc_set($data, $cp, 42);
    is($data->{a}{b}, 42, 'set overwrites');

    # Create path
    $data = {};
    my $cp_new = path_compile('/x/y/z');
    pathc_set($data, $cp_new, 'created');
    is($data->{x}{y}{z}, 'created', 'set creates path');

    # Create array path
    $data = {};
    my $cp_arr = path_compile('/items/0/name');
    pathc_set($data, $cp_arr, 'first');
    is_deeply($data, { items => [{ name => 'first' }] }, 'set creates array for numeric key');

    # Autovivify over non-ref scalar intermediate
    $data = { a => 'string' };
    pathc_set($data, path_compile('/a/b'), 99);
    is(ref($data->{a}), 'HASH', 'pathc_set replaces scalar with hash');
    is($data->{a}{b}, 99, 'value stored through replaced intermediate');
};

subtest 'pathc_exists' => sub {
    my $data = { a => { b => undef, c => 0 } };
    my $cp_b = path_compile('/a/b');
    my $cp_c = path_compile('/a/c');
    my $cp_missing = path_compile('/a/x');
    my $cp_root = path_compile('');

    ok(pathc_exists($data, $cp_b), 'exists with undef value');
    ok(pathc_exists($data, $cp_c), 'exists with zero value');
    ok(!pathc_exists($data, $cp_missing), 'not exists for missing');
    ok(pathc_exists($data, $cp_root), 'root always exists');
};

subtest 'pathc_delete' => sub {
    my $data = { a => { b => 'val', c => 'keep' } };
    my $cp = path_compile('/a/b');
    my $cp_missing = path_compile('/a/x');

    my $deleted = pathc_delete($data, $cp);
    is($deleted, 'val', 'delete returns old value');
    ok(!exists $data->{a}{b}, 'key deleted');
    ok(exists $data->{a}{c}, 'sibling kept');

    is(pathc_delete($data, $cp_missing), undef, 'delete missing returns undef');
};

subtest 'compiled path reuse' => sub {
    my $cp = path_compile('/user/name');

    my $user1 = { user => { name => 'Alice' } };
    my $user2 = { user => { name => 'Bob' } };

    is(pathc_get($user1, $cp), 'Alice', 'reuse on first data');
    is(pathc_get($user2, $cp), 'Bob', 'reuse on second data');

    pathc_set($user1, $cp, 'Changed');
    is($user1->{user}{name}, 'Changed', 'set via reused path');
    is($user2->{user}{name}, 'Bob', 'other data unchanged');
};

subtest 'compiled path memory leaks' => sub {
    no_leaks_ok {
        my $cp = path_compile('/a/b/c');
    } 'compile and destroy';

    no_leaks_ok {
        my $cp = path_compile('/a/b/c');
        my $data = { a => { b => { c => 1 } } };
        pathc_get($data, $cp);
    } 'compile, get, destroy';

    no_leaks_ok {
        my $cp = path_compile('/a/b/c');
        my $data = {};
        pathc_set($data, $cp, 'val');
    } 'compile, set, destroy';

    no_leaks_ok {
        my $cp = path_compile('/a/b');
        my $data = { a => { b => 1 } };
        pathc_exists($data, $cp);
        pathc_delete($data, $cp);
    } 'compile, exists, delete, destroy';

    no_leaks_ok {
        my $cp = path_compile('/x/y');
        for (1..100) {
            my $data = { x => { y => $_ } };
            pathc_get($data, $cp);
            pathc_set($data, $cp, $_ * 2);
        }
    } 'reuse compiled path many times';
};

subtest 'error handling' => sub {
    # Paths without leading slash are now valid (consistent with keyword API)
    my $cp_no_slash = path_compile('a/b');
    my $data = { a => { b => 42 } };
    is(pathc_get($data, $cp_no_slash), 42, 'compile path without leading slash works');

    my $cp = path_compile('/a');
    eval { pathc_set({}, path_compile(''), 'x') };
    like($@, qr/Cannot set root/, 'cannot set root');

    eval { pathc_delete({}, path_compile('')) };
    like($@, qr/Cannot delete root/, 'cannot delete root');

    eval { pathc_get({}, 'not a compiled path') };
    like($@, qr/Not a compiled path/, 'reject non-compiled');

    # Type mismatch: string key on array (intermediate)
    eval { pathc_set({ arr => [1,2,3] }, path_compile('/arr/key/x'), 'val') };
    like($@, qr/Invalid array index/, 'pathc_set string key on array croaks');
};

# Test that compiled path owns its own buffer and continues working
# even if the original variable is modified or freed
subtest 'compiled path buffer ownership' => sub {
    my $path_str = '/users/0/name';
    my $cp = path_compile($path_str);

    my $data = { users => [{ name => 'Alice' }] };

    # Verify it works before modification
    is(pathc_get($data, $cp), 'Alice', 'works before source string modification');

    # Modify the original variable
    $path_str = '/completely/different/path';

    # Compiled path should still work with original path
    is(pathc_get($data, $cp), 'Alice', 'still works after source string variable reassigned');

    # Test with in-place modification (substr)
    my $path_str2 = '/foo/bar';
    my $cp2 = path_compile($path_str2);
    my $data2 = { foo => { bar => 'value' } };
    is(pathc_get($data2, $cp2), 'value', 'works before in-place modification');

    # In-place modification via substr
    substr($path_str2, 1, 3) = 'xxx';

    # Compiled path should still use original content (owns its own copy)
    is(pathc_get($data2, $cp2), 'value', 'still works after in-place modification');

    # Test with runtime-constructed string (no constant COW sharing)
    my $n = 0;
    my $runtime_path = sprintf("/users/%d/name", $n);
    my $cp3 = path_compile($runtime_path);
    is(pathc_get($data, $cp3), 'Alice', 'works with runtime-constructed path');

    # Destroy the runtime string
    $runtime_path = 'x' x 100;

    # Compiled path should still work (has its own buffer copy)
    is(pathc_get($data, $cp3), 'Alice', 'still works after runtime source string overwritten');

    # Verify memory is not leaking with source string modification
    no_leaks_ok {
        my $str = '/a/b/c';
        my $compiled = path_compile($str);
        my $d = { a => { b => { c => 'val' } } };
        pathc_get($d, $compiled);
        $str = 'modified';  # Reassign
    } 'no leaks when source string is reassigned';

    no_leaks_ok {
        my $str = sprintf("/a/%s/c", "b");
        my $compiled = path_compile($str);
        my $d = { a => { b => { c => 'val' } } };
        pathc_get($d, $compiled);
        $str = 'x' x 100;  # Overwrite with longer string
    } 'no leaks with runtime string overwritten';
};

subtest 'compiled path negative indices' => sub {
    my $data = { arr => ['a', 'b', 'c', 'd', 'e'] };

    my $cp_last = path_compile('/arr/-1');
    my $cp_second = path_compile('/arr/-2');
    my $cp_first = path_compile('/arr/-5');

    is(pathc_get($data, $cp_last), 'e', 'get last element');
    is(pathc_get($data, $cp_second), 'd', 'get second to last');
    is(pathc_get($data, $cp_first), 'a', 'get first via negative');

    ok(pathc_exists($data, $cp_last), 'last exists');
    ok(pathc_exists($data, $cp_second), 'second to last exists');
    ok(!pathc_exists($data, path_compile('/arr/-6')), 'out of bounds negative');

    pathc_set($data, $cp_last, 'z');
    is($data->{arr}[-1], 'z', 'set last element');

    my $del = pathc_delete($data, $cp_last);
    is($del, 'z', 'delete last element');

    no_leaks_ok {
        my $cp = path_compile('/arr/-1');
        my $d = { arr => [1, 2, 3] };
        pathc_get($d, $cp);
        pathc_exists($d, $cp);
    } 'negative index compiled path no leaks';
};

done_testing;
