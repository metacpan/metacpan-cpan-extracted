use strict;
use warnings;
use Test::More;

use Data::Path::XS ':keywords';

# Basic hash set
subtest 'pathset - basic hash set' => sub {
    my $data = {};

    pathset $data, "/a", 1;
    is($data->{a}, 1, 'set single level');

    pathset $data, "/b", 'hello';
    is($data->{b}, 'hello', 'set string value');
};

# Nested hash with autovivification
subtest 'pathset - autovivification (hash)' => sub {
    my $data = {};

    pathset $data, "/a/b/c", 42;
    is($data->{a}{b}{c}, 42, 'creates nested hashes');
    is(ref($data->{a}), 'HASH', 'intermediate is hash');
    is(ref($data->{a}{b}), 'HASH', 'second intermediate is hash');
};

# Array autovivification
subtest 'pathset - autovivification (array)' => sub {
    my $data = {};

    pathset $data, "/items/0", 'first';
    is($data->{items}[0], 'first', 'creates array for numeric index');
    is(ref($data->{items}), 'ARRAY', 'intermediate is array');

    pathset $data, "/items/1", 'second';
    is($data->{items}[1], 'second', 'appends to array');
};

# Mixed hash/array autovivification
subtest 'pathset - mixed autovivification' => sub {
    my $data = {};

    pathset $data, "/users/0/name", 'Alice';
    is($data->{users}[0]{name}, 'Alice', 'hash->array->hash autovivification');
    is(ref($data->{users}), 'ARRAY', 'users is array');
    is(ref($data->{users}[0]), 'HASH', 'users[0] is hash');

    pathset $data, "/users/0/email", 'alice@test.com';
    is($data->{users}[0]{email}, 'alice@test.com', 'add to existing nested hash');

    pathset $data, "/users/1/name", 'Bob';
    is($data->{users}[1]{name}, 'Bob', 'create second array element');
};

# Overwrite existing values
subtest 'pathset - overwrite' => sub {
    my $data = { a => { b => 'old' } };

    pathset $data, "/a/b", 'new';
    is($data->{a}{b}, 'new', 'overwrites existing value');

    pathset $data, "/a/b", undef;
    is($data->{a}{b}, undef, 'can set to undef');
};

# Dynamic paths
subtest 'pathset - dynamic paths' => sub {
    my $data = {};

    my $path1 = "/x/y/z";
    pathset $data, $path1, 'dynamic';
    is($data->{x}{y}{z}, 'dynamic', 'dynamic path creates structure');

    my $path2 = "/list/0/val";
    pathset $data, $path2, 100;
    is($data->{list}[0]{val}, 100, 'dynamic path with array');
};

# Set reference values
subtest 'pathset - reference values' => sub {
    my $data = {};
    my $ref = { nested => 'hash' };

    pathset $data, "/config", $ref;
    is_deeply($data->{config}, $ref, 'can set hashref');

    my $arr = [1, 2, 3];
    pathset $data, "/numbers", $arr;
    is_deeply($data->{numbers}, $arr, 'can set arrayref');
};

# Deep paths
subtest 'pathset - deep paths' => sub {
    my $data = {};

    pathset $data, "/a/b/c/d/e/f", 'deep';
    is($data->{a}{b}{c}{d}{e}{f}, 'deep', '6 levels deep');
};

# Sparse arrays
subtest 'pathset - sparse arrays' => sub {
    my $data = {};

    pathset $data, "/arr/5", 'fifth';
    is($data->{arr}[5], 'fifth', 'sparse array element');
    is(scalar(@{$data->{arr}}), 6, 'array has correct length');
    is($data->{arr}[0], undef, 'earlier elements are undef');
};

# Return value
subtest 'pathset - return value' => sub {
    my $data = {};

    my $ret = pathset $data, "/a/b", 42;
    is($ret, 42, 'returns set value (constant path)');

    my $path = "/c/d";
    my $ret2 = pathset $data, $path, 99;
    is($ret2, 99, 'returns set value (dynamic path)');

    my $ref = { x => 1 };
    $path = "/e";
    my $ret3 = pathset $data, $path, $ref;
    is($ret3, $ref, 'returns reference value (dynamic path)');
};

done_testing();
