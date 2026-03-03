use strict;
use warnings;
use Test::More;

use Data::Path::XS ':keywords';

# Basic hash delete
subtest 'pathdelete - basic hash delete' => sub {
    my $data = { a => 1, b => 2 };

    my $del = pathdelete $data, "/a";
    is($del, 1, 'returns deleted value');
    ok(!exists $data->{a}, 'key is deleted');
    is($data->{b}, 2, 'other keys preserved');
};

# Nested hash delete
subtest 'pathdelete - nested hash delete' => sub {
    my $data = { a => { b => { c => 42, d => 99 } } };

    my $del = pathdelete $data, "/a/b/c";
    is($del, 42, 'returns deleted nested value');
    ok(!exists $data->{a}{b}{c}, 'nested key is deleted');
    is($data->{a}{b}{d}, 99, 'sibling key preserved');
    ok(exists $data->{a}{b}, 'parent preserved');
};

# Array element delete
subtest 'pathdelete - array element delete' => sub {
    my $data = { items => ['a', 'b', 'c'] };

    my $del = pathdelete $data, "/items/1";
    is($del, 'b', 'returns deleted array element');
    ok(!defined $data->{items}[1], 'array element deleted (undef)');
    is($data->{items}[0], 'a', 'earlier elements preserved');
    is($data->{items}[2], 'c', 'later elements preserved');
};

# Mixed hash/array delete
subtest 'pathdelete - mixed hash/array delete' => sub {
    my $data = { users => [ { name => 'Alice', age => 30 }, { name => 'Bob' } ] };

    my $del = pathdelete $data, "/users/0/age";
    is($del, 30, 'returns deleted value from nested structure');
    ok(!exists $data->{users}[0]{age}, 'nested key deleted');
    is($data->{users}[0]{name}, 'Alice', 'sibling key preserved');

    my $del2 = pathdelete $data, "/users/1";
    is(ref($del2), 'HASH', 'can delete array element containing hash');
    is($del2->{name}, 'Bob', 'deleted hash has correct content');
};

# Delete non-existent key
subtest 'pathdelete - non-existent key' => sub {
    my $data = { a => { b => 1 } };

    my $del = pathdelete $data, "/nonexistent";
    is($del, undef, 'returns undef for non-existent key');
    ok(exists $data->{a}, 'data unchanged');

    my $del2 = pathdelete $data, "/a/nonexistent";
    is($del2, undef, 'returns undef for non-existent nested key');
};

# Dynamic paths
subtest 'pathdelete - dynamic paths' => sub {
    my $data = { x => { y => { z => 'value' } } };

    my $path = "/x/y/z";
    my $del = pathdelete $data, $path;
    is($del, 'value', 'dynamic path delete works');
    ok(!exists $data->{x}{y}{z}, 'key deleted via dynamic path');
};

# Delete entire subtree
subtest 'pathdelete - delete subtree' => sub {
    my $data = { a => { b => { c => 1, d => 2 }, e => 3 } };

    my $del = pathdelete $data, "/a/b";
    is(ref($del), 'HASH', 'returns deleted subtree');
    is_deeply($del, { c => 1, d => 2 }, 'subtree has correct content');
    ok(!exists $data->{a}{b}, 'subtree deleted');
    is($data->{a}{e}, 3, 'sibling preserved');
};

# Delete preserves structure
subtest 'pathdelete - preserves structure' => sub {
    my $data = { a => { b => { c => 1 } } };

    pathdelete $data, "/a/b/c";
    ok(exists $data->{a}, 'top level preserved');
    ok(exists $data->{a}{b}, 'intermediate level preserved');
    is_deeply($data->{a}{b}, {}, 'leaf becomes empty hash');
};

# Deep delete
subtest 'pathdelete - deep delete' => sub {
    my $data = { a => { b => { c => { d => { e => { f => 'deep' } } } } } };

    my $del = pathdelete $data, "/a/b/c/d/e/f";
    is($del, 'deep', 'deep delete returns value');
    ok(exists $data->{a}{b}{c}{d}{e}, 'parent structure preserved');
};

# Delete with zero/empty values
subtest 'pathdelete - zero and empty values' => sub {
    my $data = { zero => 0, empty => '', undef => undef };

    my $del1 = pathdelete $data, "/zero";
    is($del1, 0, 'returns deleted zero');

    my $del2 = pathdelete $data, "/empty";
    is($del2, '', 'returns deleted empty string');

    my $del3 = pathdelete $data, "/undef";
    is($del3, undef, 'returns deleted undef');
};

done_testing();
