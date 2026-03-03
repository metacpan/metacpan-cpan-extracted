use strict;
use warnings;
use Test::More;
use Test::LeakTrace;

use Data::Path::XS qw(path_get path_set path_delete path_exists
                      patha_get patha_set patha_delete patha_exists);

my $ITERATIONS = 1000;

subtest 'stress: repeated path_get' => sub {
    my $data = { a => { b => { c => { d => { e => 'deep' } } } } };

    no_leaks_ok {
        for (1..$ITERATIONS) {
            path_get($data, '/a/b/c/d/e');
        }
    } "path_get $ITERATIONS iterations";
};

subtest 'stress: repeated path_set overwrite' => sub {
    my $data = { key => 'initial' };

    no_leaks_ok {
        for my $i (1..$ITERATIONS) {
            path_set($data, '/key', "value$i");
        }
    } "path_set overwrite $ITERATIONS iterations";
};

subtest 'stress: create and destroy paths' => sub {
    no_leaks_ok {
        for (1..$ITERATIONS) {
            my $data = {};
            path_set($data, '/a/b/c/d/e', 'val');
            path_delete($data, '/a/b/c/d/e');
            path_delete($data, '/a/b/c/d');
            path_delete($data, '/a/b/c');
            path_delete($data, '/a/b');
            path_delete($data, '/a');
        }
    } "create/destroy $ITERATIONS iterations";
};

subtest 'stress: missing paths' => sub {
    my $data = { a => { b => 1 } };

    no_leaks_ok {
        for (1..$ITERATIONS) {
            path_get($data, '/a/b/c/d/e');
            path_get($data, '/x/y/z');
            path_exists($data, '/missing/path');
            path_delete($data, '/not/here');
        }
    } "missing paths $ITERATIONS iterations";
};

subtest 'stress: array operations' => sub {
    no_leaks_ok {
        for (1..$ITERATIONS) {
            my $data = { arr => [] };
            for my $i (0..9) {
                path_set($data, "/arr/$i", $i * 2);
            }
            for my $i (0..9) {
                path_get($data, "/arr/$i");
            }
        }
    } "array operations $ITERATIONS iterations";
};

subtest 'stress: patha_get' => sub {
    my $data = { a => { b => { c => { d => { e => 'deep' } } } } };
    my @path = qw(a b c d e);

    no_leaks_ok {
        for (1..$ITERATIONS) {
            patha_get($data, \@path);
        }
    } "patha_get $ITERATIONS iterations";
};

subtest 'stress: patha_set/delete cycle' => sub {
    my @path = qw(x y z);

    no_leaks_ok {
        for (1..$ITERATIONS) {
            my $data = {};
            patha_set($data, \@path, 'val');
            patha_delete($data, \@path);
        }
    } "patha_set/delete $ITERATIONS iterations";
};

subtest 'stress: mixed string and array API' => sub {
    no_leaks_ok {
        for (1..$ITERATIONS) {
            my $data = {};
            path_set($data, '/a/b/c', 1);
            patha_get($data, ['a', 'b', 'c']);
            patha_set($data, ['a', 'b', 'd'], 2);
            path_get($data, '/a/b/d');
            path_delete($data, '/a/b/c');
            patha_delete($data, ['a', 'b', 'd']);
        }
    } "mixed API $ITERATIONS iterations";
};

subtest 'stress: complex values' => sub {
    no_leaks_ok {
        for (1..$ITERATIONS) {
            my $data = {};
            my $complex = {
                arr => [1, 2, { nested => 'hash' }],
                deep => { a => { b => { c => 'd' } } },
            };
            path_set($data, '/item', $complex);
            path_get($data, '/item/arr/2/nested');
            path_get($data, '/item/deep/a/b/c');
        }
    } "complex values $ITERATIONS iterations";
};

subtest 'stress: error paths (eval)' => sub {
    no_leaks_ok {
        for (1..$ITERATIONS) {
            path_get({}, 'invalid');
            eval { path_set({}, '', 'x') };
            eval { path_delete({}, '') };
        }
    } "error paths $ITERATIONS iterations";
};

# Memory growth test (not using no_leaks_ok)
subtest 'memory stability check' => sub {
    plan skip_all => 'ps -o rss= not portable'
        unless $^O =~ /^(?:linux|darwin)$/;

    my $data = {};

    # Warm up
    for (1..100) {
        path_set($data, "/key$_", "val$_");
    }

    # Measure baseline
    my $before = `ps -o rss= -p $$` + 0;

    for (1..10000) {
        path_set($data, "/dyn/key$_", "value$_");
        path_get($data, "/dyn/key$_");
        path_delete($data, "/dyn/key$_");
    }

    my $after = `ps -o rss= -p $$` + 0;
    my $growth = $after - $before;

    # Allow some growth but not excessive (< 1MB)
    ok($growth < 1024, "memory growth reasonable: ${growth}KB");
    diag("Memory: before=${before}KB after=${after}KB growth=${growth}KB");
};

done_testing;
