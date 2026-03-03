use strict;
use warnings;
use Test::More;

use Data::Path::XS ':keywords';

# Basic hash exists
subtest 'pathexists - basic hash' => sub {
    my $data = { a => 1, b => 2 };

    my $e1 = pathexists $data, "/a";
    ok($e1, 'existing key returns true');

    my $e2 = pathexists $data, "/nonexistent";
    ok(!$e2, 'non-existing key returns false');
};

# Nested hash exists
subtest 'pathexists - nested hash' => sub {
    my $data = { a => { b => { c => 42 } } };

    my $e1 = pathexists $data, "/a";
    ok($e1, 'top-level exists');

    my $e2 = pathexists $data, "/a/b";
    ok($e2, 'intermediate level exists');

    my $e3 = pathexists $data, "/a/b/c";
    ok($e3, 'leaf level exists');

    my $e4 = pathexists $data, "/a/b/x";
    ok(!$e4, 'non-existing leaf returns false');

    # Use dynamic path for non-existing intermediate
    my $path = "/a/x/y";
    my $e5 = pathexists $data, $path;
    ok(!$e5, 'non-existing intermediate returns false (dynamic)');
};

# Array exists
subtest 'pathexists - array' => sub {
    my $data = { items => [10, 20, 30] };

    my $e1 = pathexists $data, "/items/0";
    ok($e1, 'array index 0 exists');

    my $e2 = pathexists $data, "/items/2";
    ok($e2, 'array index 2 exists');

    my $e3 = pathexists $data, "/items/5";
    ok(!$e3, 'out of bounds index returns false');
};

# Mixed hash/array exists
subtest 'pathexists - mixed hash/array' => sub {
    my $data = { users => [ { name => 'Alice' }, { name => 'Bob' } ] };

    my $e1 = pathexists $data, "/users/0/name";
    ok($e1, 'nested hash->array->hash exists');

    my $e2 = pathexists $data, "/users/1/name";
    ok($e2, 'second array element exists');

    my $e3 = pathexists $data, "/users/0/email";
    ok(!$e3, 'non-existing nested key returns false');

    # Use dynamic path for out-of-bounds check
    my $path = "/users/5/name";
    my $e4 = pathexists $data, $path;
    ok(!$e4, 'out of bounds array element returns false (dynamic)');
};

# Undef values - key exists but value is undef
subtest 'pathexists - undef values' => sub {
    my $data = { defined => 1, undef => undef };

    my $e1 = pathexists $data, "/defined";
    ok($e1, 'defined value exists');

    my $e2 = pathexists $data, "/undef";
    ok($e2, 'undef value still exists (key exists)');

    my $e3 = pathexists $data, "/missing";
    ok(!$e3, 'missing key does not exist');
};

# Dynamic paths
subtest 'pathexists - dynamic paths' => sub {
    my $data = { x => { y => { z => 99 } } };

    my $path1 = "/x/y/z";
    my $e1 = pathexists $data, $path1;
    ok($e1, 'dynamic path exists');

    my $path2 = "/x/y/missing";
    my $e2 = pathexists $data, $path2;
    ok(!$e2, 'dynamic path does not exist');

};

# Zero and empty string values
subtest 'pathexists - zero and empty values' => sub {
    my $data = { zero => 0, empty => '' };

    my $e1 = pathexists $data, "/zero";
    ok($e1, 'zero value exists');

    my $e2 = pathexists $data, "/empty";
    ok($e2, 'empty string value exists');
};

# Deep nesting
subtest 'pathexists - deep nesting' => sub {
    my $data = { a => { b => { c => { d => { e => { f => 'deep' } } } } } };

    my $e1 = pathexists $data, "/a/b/c/d/e/f";
    ok($e1, '6 levels deep exists');

    my $e2 = pathexists $data, "/a/b/c/d/e/missing";
    ok(!$e2, '6 levels deep missing returns false');
};

# Sparse arrays
subtest 'pathexists - sparse arrays' => sub {
    my $data = { arr => [] };
    $data->{arr}[5] = 'fifth';

    my $e1 = pathexists $data, "/arr/5";
    ok($e1, 'sparse array element exists');

    my $e2 = pathexists $data, "/arr/0";
    ok(!$e2, 'unset sparse array element does not exist');

    my $e3 = pathexists $data, "/arr/10";
    ok(!$e3, 'beyond sparse array does not exist');
};

done_testing();
