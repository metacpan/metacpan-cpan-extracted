use strict;
use warnings;
use Test::More;
use Test::LeakTrace;

use Data::Path::XS qw(path_get path_set path_delete path_exists
                      patha_get patha_set patha_delete patha_exists
                      :keywords);

# Basic leak tests for string API
subtest 'path_get leaks' => sub {
    my $data = { a => { b => { c => 'value' } } };

    no_leaks_ok {
        path_get($data, '/a/b/c');
    } 'path_get existing path';

    no_leaks_ok {
        path_get($data, '/a/b/missing');
    } 'path_get missing key';

    no_leaks_ok {
        path_get($data, '/a/missing/deep');
    } 'path_get missing intermediate';

    no_leaks_ok {
        path_get($data, '');
    } 'path_get root';
};

subtest 'path_exists leaks' => sub {
    my $data = { a => { b => { c => 'value' } } };

    no_leaks_ok {
        path_exists($data, '/a/b/c');
    } 'path_exists existing';

    no_leaks_ok {
        path_exists($data, '/a/missing');
    } 'path_exists missing';

    no_leaks_ok {
        path_exists($data, '');
    } 'path_exists root';
};

subtest 'path_set leaks' => sub {
    no_leaks_ok {
        my $data = { a => { b => 1 } };
        path_set($data, '/a/b', 2);
    } 'path_set overwrite';

    no_leaks_ok {
        my $data = { a => {} };
        path_set($data, '/a/new', 'val');
    } 'path_set new key';

    no_leaks_ok {
        my $data = {};
        path_set($data, '/a/b/c/d', 'deep');
    } 'path_set create intermediate hashes';

    no_leaks_ok {
        my $data = {};
        path_set($data, '/arr/0/1/2', 'val');
    } 'path_set create intermediate arrays';
};

subtest 'path_delete leaks' => sub {
    no_leaks_ok {
        my $data = { a => { b => 'val' } };
        path_delete($data, '/a/b');
    } 'path_delete existing';

    no_leaks_ok {
        my $data = { a => { b => 'val' } };
        path_delete($data, '/a/missing');
    } 'path_delete missing';

    no_leaks_ok {
        my $data = { a => 1 };
        path_delete($data, '/a/b/c');
    } 'path_delete non-ref intermediate';
};

# Array API leak tests
subtest 'patha_get leaks' => sub {
    my $data = { a => { b => { c => 'value' } } };
    my @path = qw(a b c);
    my @missing = qw(a b missing);

    no_leaks_ok {
        patha_get($data, \@path);
    } 'patha_get existing';

    no_leaks_ok {
        patha_get($data, \@missing);
    } 'patha_get missing';

    no_leaks_ok {
        patha_get($data, []);
    } 'patha_get empty path';
};

subtest 'patha_set leaks' => sub {
    no_leaks_ok {
        my $data = {};
        patha_set($data, ['a', 'b', 'c'], 'val');
    } 'patha_set create path';

    no_leaks_ok {
        my $data = { a => [1, 2, 3] };
        patha_set($data, ['a', 1], 'new');
    } 'patha_set array element';
};

subtest 'patha_exists leaks' => sub {
    my $data = { a => { b => 1 } };

    no_leaks_ok {
        patha_exists($data, ['a', 'b']);
    } 'patha_exists existing';

    no_leaks_ok {
        patha_exists($data, ['a', 'missing']);
    } 'patha_exists missing';
};

subtest 'patha_delete leaks' => sub {
    no_leaks_ok {
        my $data = { a => { b => 1 } };
        patha_delete($data, ['a', 'b']);
    } 'patha_delete existing';

    no_leaks_ok {
        my $data = { a => { b => 1 } };
        patha_delete($data, ['a', 'missing']);
    } 'patha_delete missing';
};

# Complex data structure tests
subtest 'complex structures leaks' => sub {
    no_leaks_ok {
        my $data = {
            users => [
                { name => 'Alice', tags => ['a', 'b'] },
                { name => 'Bob', tags => ['c', 'd'] },
            ],
        };
        path_get($data, '/users/0/name');
        path_get($data, '/users/1/tags/0');
        path_set($data, '/users/0/age', 30);
        path_exists($data, '/users/1/tags/1');
        path_delete($data, '/users/0/tags/0');
    } 'mixed operations on complex structure';
};

# Repeated operations
subtest 'repeated operations leaks' => sub {
    no_leaks_ok {
        my $data = { a => { b => { c => 1 } } };
        for (1..100) {
            path_get($data, '/a/b/c');
            path_set($data, '/a/b/c', $_);
            path_exists($data, '/a/b/c');
        }
    } 'repeated get/set/exists';

    no_leaks_ok {
        for (1..100) {
            my $data = {};
            path_set($data, '/a/b/c/d/e', 'val');
            path_delete($data, '/a/b/c/d/e');
        }
    } 'repeated create/delete';
};

# Reference handling
subtest 'reference handling leaks' => sub {
    no_leaks_ok {
        my $inner = { x => 1 };
        my $data = { a => $inner };
        my $got = path_get($data, '/a');
        # $got should be same ref as $inner
    } 'get returns same reference';

    no_leaks_ok {
        my $val = { complex => [1, 2, 3] };
        my $data = {};
        path_set($data, '/key', $val);
        my $got = path_get($data, '/key');
    } 'set/get complex value';
};

# Keyword API leak tests
subtest 'keyword pathget leaks' => sub {
    my $data = { a => { b => { c => 'value' } } };

    no_leaks_ok {
        my $v = pathget $data, "/a/b/c";
    } 'keyword pathget constant path';

    no_leaks_ok {
        my $path = "/a/b/c";
        my $v = pathget $data, $path;
    } 'keyword pathget dynamic path';

    no_leaks_ok {
        my $path = "/a/missing";
        my $v = pathget $data, $path;
    } 'keyword pathget dynamic missing';
};

subtest 'keyword pathset leaks' => sub {
    no_leaks_ok {
        my $data = { a => { b => 1 } };
        pathset $data, "/a/b", 2;
    } 'keyword pathset constant path';

    no_leaks_ok {
        my $data = {};
        my $path = "/a/b/c";
        pathset $data, $path, 'val';
    } 'keyword pathset dynamic path';
};

subtest 'keyword pathexists leaks' => sub {
    my $data = { a => { b => { c => 1 } } };

    no_leaks_ok {
        my $e = pathexists $data, "/a/b/c";
    } 'keyword pathexists constant path';

    no_leaks_ok {
        my $path = "/a/b/c";
        my $e = pathexists $data, $path;
    } 'keyword pathexists dynamic path';

    no_leaks_ok {
        my $path = "/a/missing";
        my $e = pathexists $data, $path;
    } 'keyword pathexists dynamic missing';
};

subtest 'keyword pathdelete leaks' => sub {
    no_leaks_ok {
        my $data = { a => { b => 1 } };
        pathdelete $data, "/a/b";
    } 'keyword pathdelete constant path';

    no_leaks_ok {
        my $data = { a => { b => 1 } };
        my $path = "/a/b";
        pathdelete $data, $path;
    } 'keyword pathdelete dynamic path';

    no_leaks_ok {
        my $data = { a => 1 };
        my $path = "/a/b/c";
        pathdelete $data, $path;
    } 'keyword pathdelete dynamic missing';
};

done_testing;
