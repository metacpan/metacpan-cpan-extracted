#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 'blib/lib', 'blib/arch';
use ClickHouse::Encoder;
use Digest::SHA qw(sha1_hex);
use Config;
use JSON::PP ();

plan skip_all => 'fork not available on this perl'
    unless $Config{d_fork} && $Config{d_fork} eq 'define';

# JSON encoder uses path discovery, kind classification, and per-row
# Variant data emission - the most stateful encode path. Fork N
# children, each encodes the same input M times. If any per-encode
# global / static drifts (e.g. mutable cache, retained HV iterators),
# children's output hashes would diverge.

my $N_CHILDREN = 4;
my $N_ENCODES  = 30;

my @rows = (
    [{ name => "alice", age => 30, active => JSON::PP::true(),
       tags => ["a","b","c"] }],
    [{ name => "bob", age => 25, scores => [1.5, 2.5] }],
    [{}],
    [undef],
    [{ user => { name => "carol", deep => { id => 42 } } }],
    [{ mixed => 1 }],
    [{ mixed => "two" }],
    [{ mixed => 3.14 }],
    [{ array_int => [10, 20, 30] }],
    [{ array_str => ["foo", "bar"] }],
);

my $parent_enc = ClickHouse::Encoder->new(columns => [['j','JSON']]);
my $expected_hash = sha1_hex($parent_enc->encode(\@rows));

# Smoke check: re-encode in parent stays stable.
for (1..3) {
    is(sha1_hex($parent_enc->encode(\@rows)), $expected_hash,
       'parent re-encode is stable');
}

# Fork children, collect their hashes via pipes.
my @children;
for my $cid (1 .. $N_CHILDREN) {
    pipe(my $r, my $w) or die "pipe: $!";
    my $pid = fork // die "fork: $!";
    if ($pid == 0) {
        close $r;
        my $enc = ClickHouse::Encoder->new(columns => [['j','JSON']]);
        # Verify EVERY iteration matches, not just the last - a transient
        # drift on iteration 7 that converges by iteration 30 would
        # otherwise pass silently.
        my $stable = 1;
        for (1 .. $N_ENCODES) {
            $stable = 0
                if sha1_hex($enc->encode(\@rows)) ne $expected_hash;
        }
        print {$w} $stable ? "STABLE\n" : "DRIFT\n";
        close $w;
        exit 0;
    }
    close $w;
    push @children, { pid => $pid, rh => $r };
}

for my $c (@children) {
    my $line = readline $c->{rh};
    close $c->{rh};
    waitpid $c->{pid}, 0;
    chomp $line if defined $line;
    is($line, 'STABLE', "child PID $c->{pid} stable across all encodes");
}

done_testing();
