#!/usr/bin/perl

# Test cloning of threads::shared data structures
# See: https://github.com/garu/Clone/issues/18
#      (migrated from rt.cpan.org #93821)
#
# threads::shared uses tie magic to synchronize shared data.
# Clone strips the sharing magic and produces a plain unshared
# deep copy by reading the values through the tie interface.
#
# NOTE: uses bare blocks instead of subtest to avoid Test2::API::Context
# global destruction warnings on older Perls (GH #78).

use strict;
use warnings;
use Test::More;

# threads must be loaded before anything else
BEGIN {
    my $has_threads = eval {
        require Config;
        $Config::Config{useithreads};
    };

    unless ($has_threads) {
        plan skip_all => 'Perl not compiled with thread support (useithreads)';
        exit 0;
    }

    eval { require threads };
    if ($@) {
        plan skip_all => "threads module not available: $@";
        exit 0;
    }

    eval { require threads::shared };
    if ($@) {
        plan skip_all => "threads::shared module not available: $@";
        exit 0;
    }
}

use threads;
use threads::shared;
use Clone qw(clone);

# --- Test 1: Clone a shared hash ---

{
    my $shared = shared_clone({ foo => 100, bar => 200 });

    is($shared->{foo}, 100, 'original shared hash accessible');
    is($shared->{bar}, 200, 'original shared hash bar accessible');

    my $cloned = clone($shared);

    is(ref($cloned), 'HASH', 'cloned result is a hash reference');
    is($cloned->{foo}, 100, 'cloned hash value foo correct');
    is($cloned->{bar}, 200, 'cloned hash value bar correct');

    # Clone is independent — mutations do not affect the original
    $cloned->{foo} = 999;
    is($shared->{foo}, 100, 'original unchanged after mutating clone');
    is($cloned->{foo}, 999, 'clone reflects mutation');
}

# --- Test 2: Clone a shared array ---

{
    my $shared = shared_clone([10, 20, 30]);

    is($shared->[0], 10, 'original shared array accessible');

    my $cloned = clone($shared);

    is(ref($cloned), 'ARRAY', 'cloned result is an array reference');
    is($cloned->[0], 10, 'cloned array elem 0 correct');
    is($cloned->[1], 20, 'cloned array elem 1 correct');
    is($cloned->[2], 30, 'cloned array elem 2 correct');

    # Clone is independent
    $cloned->[0] = 999;
    is($shared->[0], 10, 'original array unchanged after mutating clone');
    is($cloned->[0], 999, 'clone array reflects mutation');
}

# --- Test 3: Clone a shared scalar ---

{
    my $val :shared = 42;

    is($val, 42, 'original shared scalar accessible');

    my $cloned = clone(\$val);

    is(ref($cloned), 'SCALAR', 'cloned result is a scalar reference');
    is($$cloned, 42, 'cloned scalar value correct');

    # Clone is independent
    $$cloned = 999;
    is($val, 42, 'original scalar unchanged after mutating clone');
}

# --- Test 4: Clone a nested shared structure ---

{
    my $shared = shared_clone({
        name   => 'test',
        values => [1, 2, 3],
        nested => { a => 'deep' },
    });

    is($shared->{name}, 'test', 'original nested shared accessible');

    my $cloned = clone($shared);

    is($cloned->{name}, 'test', 'top-level value correct');
    is($cloned->{values}[1], 2, 'nested array value correct');
    is($cloned->{nested}{a}, 'deep', 'deeply nested value correct');

    # Clone is fully independent at every nesting level
    $cloned->{name} = 'modified';
    $cloned->{values}[0] = 999;
    $cloned->{nested}{a} = 'changed';

    is($shared->{name}, 'test', 'original name unchanged');
    is($shared->{values}[0], 1, 'original nested array unchanged');
    is($shared->{nested}{a}, 'deep', 'original deep hash unchanged');
}

# --- Test 5: Clone in a thread context ---

{
    my $shared = shared_clone({ key => 'value' });

    my $thr = threads->create(sub {
        my $cloned = eval { clone($shared) };
        return {
            ok    => !$@,
            error => $@ // '',
            val   => $cloned ? $cloned->{key} : undef,
        };
    });

    my $result = $thr->join();

    ok($result->{ok}, 'clone() inside thread does not die')
        or diag("thread clone died: $result->{error}");
    is($result->{val}, 'value', 'cloned value correct inside thread');
}

# --- Test 6: Clone is not shared ---

{
    my $shared = shared_clone({ x => 1 });
    my $cloned = clone($shared);

    ok(defined(threads::shared::is_shared($shared)), 'original is shared');
    ok(!defined(threads::shared::is_shared($cloned)), 'clone is not shared');
}

done_testing();
