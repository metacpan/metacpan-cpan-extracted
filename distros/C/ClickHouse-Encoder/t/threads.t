#!/usr/bin/env perl
# ithreads safety. Encoder and Streamer are blessed IVs holding a raw C
# pointer; ithreads clone SVs verbatim, so without CLONE_SKIP both
# interpreters own the same pointer and each frees it - aborting the
# process on any thread spawn. Threaded perls are the distribution
# default, so this is a common configuration, not an exotic one.
use strict;
use warnings;
use lib 'blib/lib', 'blib/arch';
use Test::More;
use Config;

use ClickHouse::Encoder;

# The CLONE_SKIP contract itself is asserted on every perl: dropping it
# would only show up as a crash on a threaded build, which is exactly the
# configuration a non-threaded CI run cannot catch.
ok(ClickHouse::Encoder->CLONE_SKIP,
   'ClickHouse::Encoder sets CLONE_SKIP');
ok(ClickHouse::Encoder::Streamer->CLONE_SKIP,
   'ClickHouse::Encoder::Streamer sets CLONE_SKIP');

if (!$Config{useithreads}) {
    done_testing();
    exit 0;
}
require threads;
threads->import;

# Each case runs in its own process: a double free aborts rather than
# returning, so an in-process check could not report the failure.
my @inc = map { "-I$_" } grep { -d } qw(blib/lib blib/arch);

sub run_ok {
    my ($label, $code) = @_;
    my $rc = system($^X, @inc, '-e', "use threads; use ClickHouse::Encoder; $code");
    my $sig = $rc & 127;
    ok($rc == 0, $label)
        or diag($sig ? "child died on signal $sig (double free / use-after-free)"
                     : "child exited with " . ($rc >> 8));
    return;
}

run_ok('thread spawned while an encoder is alive',
       'my $e = ClickHouse::Encoder->new(columns=>[["a","String"]]);
        threads->create(sub { 1 })->join;');

run_ok('child touches the cloned encoder',
       'my $e = ClickHouse::Encoder->new(columns=>[["a","String"]]);
        threads->create(sub { eval { $e->encode([["x"]]) }; 1 })->join;');

run_ok('thread spawned while a streamer is alive',
       'my $e = ClickHouse::Encoder->new(columns=>[["a","String"]]);
        my $s = $e->streamer(sub { 1 });
        threads->create(sub { 1 })->join;');

run_ok('encoder built inside the thread',
       'threads->create(sub {
            my $e = ClickHouse::Encoder->new(columns=>[["a","String"]]);
            $e->encode([["x"]]); 1 })->join;');

run_ok('several threads, encoder alive in the parent',
       'my $e = ClickHouse::Encoder->new(columns=>[["a","String"]]);
        for (1..4) {
            threads->create(sub {
                my $x = ClickHouse::Encoder->new(columns=>[["b","Int32"]]);
                $x->encode([[1]]); 1 })->join;
        }');

# The parent's encoder must survive the round trip untouched.
{
    my $enc = ClickHouse::Encoder->new(columns => [['a', 'String']]);
    my $before = $enc->encode([['x']]);
    threads->create(sub { 1 })->join;
    is($enc->encode([['x']]), $before,
       'parent encoder still works after a thread round-trip');
}

# CLONE_SKIP leaves the child's copy unblessed, so a cross-thread use is a
# clean Perl error rather than undefined behaviour.
{
    my $enc = ClickHouse::Encoder->new(columns => [['a', 'String']]);
    my $err = threads->create(sub {
        return eval { $enc->encode([['y']]); '' } ? '' : "$@";
    })->join;
    like($err, qr/unblessed|undefined value/,
         'cross-thread use fails as a Perl error, not a crash');
}

done_testing();
