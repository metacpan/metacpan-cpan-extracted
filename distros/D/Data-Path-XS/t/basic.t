use strict;
use warnings;
use Test::More;

use_ok('Data::Path::XS', qw(path_get path_set path_delete path_exists));

my $data = {
    foo => {
        bar => [1, 2, { baz => 'deep' }],
        empty => '',
        zero => 0,
    },
    arr => [10, 20, 30],
};

# path_get tests
is(path_get($data, ''), $data, 'get root');
is(path_get($data, '/foo/bar/0'), 1, 'get array element');
is(path_get($data, '/foo/bar/2/baz'), 'deep', 'get nested hash in array');
is(path_get($data, '/foo/empty'), '', 'get empty string');
is(path_get($data, '/foo/zero'), 0, 'get zero');
is(path_get($data, '/nonexistent'), undef, 'get nonexistent returns undef');
is(path_get($data, '/foo/bar/99'), undef, 'get out of bounds returns undef');

# path_exists tests
ok(path_exists($data, ''), 'root exists');
ok(path_exists($data, '/foo'), 'hash key exists');
ok(path_exists($data, '/foo/bar/1'), 'array index exists');
ok(path_exists($data, '/foo/empty'), 'empty string exists');
ok(path_exists($data, '/foo/zero'), 'zero value exists');
ok(!path_exists($data, '/nope'), 'nonexistent key');
ok(!path_exists($data, '/foo/bar/99'), 'out of bounds index');

# path_set tests
path_set($data, '/foo/bar/1', 42);
is($data->{foo}{bar}[1], 42, 'set overwrites');

path_set($data, '/new/nested/value', 'created');
is($data->{new}{nested}{value}, 'created', 'set creates intermediate hashes');

path_set($data, '/arr/5', 'sparse');
is($data->{arr}[5], 'sparse', 'set sparse array');

# path_delete tests
my $deleted = path_delete($data, '/foo/bar/0');
is($deleted, 1, 'delete returns old value');
ok(!exists $data->{foo}{bar}[0], 'delete removes from array');

$deleted = path_delete($data, '/foo/empty');
is($deleted, '', 'delete empty string');
ok(!exists $data->{foo}{empty}, 'delete removes from hash');

$deleted = path_delete($data, '/nonexistent');
is($deleted, undef, 'delete nonexistent returns undef');

done_testing;
