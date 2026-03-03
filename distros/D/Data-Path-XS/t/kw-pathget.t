use strict;
use warnings;
use Test::More;

use Data::Path::XS ':keywords';

# Basic hash access
subtest 'pathget - basic hash access' => sub {
    my $data = { a => 1, b => 2 };

    my $v1 = pathget $data, "/a";
    is($v1, 1, 'single level hash access');

    my $v2 = pathget $data, "/b";
    is($v2, 2, 'single level hash access - different key');
};

# Nested hash access
subtest 'pathget - nested hash access' => sub {
    my $data = { a => { b => { c => 42 } } };

    my $v1 = pathget $data, "/a";
    is(ref($v1), 'HASH', 'returns hashref at intermediate level');

    my $v2 = pathget $data, "/a/b";
    is(ref($v2), 'HASH', 'returns hashref at second level');

    my $v3 = pathget $data, "/a/b/c";
    is($v3, 42, 'returns value at leaf');
};

# Array access
subtest 'pathget - array access' => sub {
    my $data = { items => [10, 20, 30] };

    my $v1 = pathget $data, "/items/0";
    is($v1, 10, 'array index 0');

    my $v2 = pathget $data, "/items/1";
    is($v2, 20, 'array index 1');

    my $v3 = pathget $data, "/items/2";
    is($v3, 30, 'array index 2');
};

# Mixed hash/array access
subtest 'pathget - mixed hash/array' => sub {
    my $data = { users => [ { name => 'Alice', age => 30 }, { name => 'Bob', age => 25 } ] };

    my $v1 = pathget $data, "/users/0/name";
    is($v1, 'Alice', 'hash->array->hash access');

    my $v2 = pathget $data, "/users/1/name";
    is($v2, 'Bob', 'second array element');

    my $v3 = pathget $data, "/users/0/age";
    is($v3, 30, 'different key in nested hash');
};

# Missing keys return undef
subtest 'pathget - missing keys' => sub {
    my $data = { a => { b => { c => 1 } } };

    my $v1 = pathget $data, "/nonexistent";
    is($v1, undef, 'missing top-level key');

    my $v2 = pathget $data, "/a/nonexistent";
    is($v2, undef, 'missing nested key');

    my $v3 = pathget $data, "/a/b/nonexistent";
    is($v3, undef, 'missing key at leaf level');
};

# Dynamic paths
subtest 'pathget - dynamic paths' => sub {
    my $data = { x => { y => { z => 99 } } };

    my $path1 = "/x";
    my $v1 = pathget $data, $path1;
    is(ref($v1), 'HASH', 'dynamic path - single level');

    my $path2 = "/x/y/z";
    my $v2 = pathget $data, $path2;
    is($v2, 99, 'dynamic path - multiple levels');

    my $path3 = "/nonexistent";
    my $v3 = pathget $data, $path3;
    is($v3, undef, 'dynamic path - missing key');
};

# Dynamic paths with arrays
subtest 'pathget - dynamic paths with arrays' => sub {
    my $data = { list => [ { val => 'first' }, { val => 'second' } ] };

    my $path = "/list/0/val";
    my $v1 = pathget $data, $path;
    is($v1, 'first', 'dynamic path with array index');

    for my $i (0, 1) {
        my $p = "/list/$i/val";
        my $v = pathget $data, $p;
        is($v, $i == 0 ? 'first' : 'second', "dynamic path in loop - index $i");
    }
};

# Edge cases
subtest 'pathget - edge cases' => sub {
    my $data = { a => { b => 0 } };
    my $v1 = pathget $data, "/a/b";
    is($v1, 0, 'returns zero (not undef)');

    $data = { a => { b => '' } };
    my $v2 = pathget $data, "/a/b";
    is($v2, '', 'returns empty string (not undef)');

    $data = { a => { b => undef } };
    my $v3 = pathget $data, "/a/b";
    is($v3, undef, 'returns explicit undef');
};

# Deep nesting
subtest 'pathget - deep nesting' => sub {
    my $data = { a => { b => { c => { d => { e => { f => 'deep' } } } } } };

    my $v = pathget $data, "/a/b/c/d/e/f";
    is($v, 'deep', '6 levels deep');
};

done_testing();
