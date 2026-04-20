use strict;
use warnings;
use Test::More;

use Data::HashMap::II;
use Data::HashMap::SS;

my $SEED = $ENV{FUZZ_SEED} // int(rand(2 ** 32));
srand($SEED);
diag "fuzz seed: $SEED (set FUZZ_SEED to reproduce)";

my $OPS = 5000;

# ---- II vs %h (int-int) ----

{
    my $m = Data::HashMap::II->new();
    my %h;
    my $key_space = 200;

    for my $i (1 .. $OPS) {
        my $op = int(rand(5));
        my $k = int(rand($key_space));
        if ($op == 0) {
            my $v = int(rand(1_000_000));
            $m->put($k, $v);
            $h{$k} = $v;
        }
        elsif ($op == 1) {
            my $got = $m->get($k);
            my $ref = exists $h{$k} ? $h{$k} : undef;
            if (defined($got) != defined($ref) || (defined $got && $got != $ref)) {
                fail("op=get k=$k iter=$i: got="
                    . (defined $got ? $got : 'undef')
                    . " ref=" . (defined $ref ? $ref : 'undef'));
                last;
            }
        }
        elsif ($op == 2) {
            $m->remove($k);
            delete $h{$k};
        }
        elsif ($op == 3) {
            my $got = $m->incr($k);
            $h{$k} = (exists $h{$k} ? $h{$k} : 0) + 1;
            is $got, $h{$k}, "op=incr k=$k iter=$i" or last;
        }
        else {
            my $got = $m->exists($k) ? 1 : 0;
            my $ref = exists $h{$k} ? 1 : 0;
            is $got, $ref, "op=exists k=$k iter=$i" or last;
        }
        if ($i % 500 == 0) {
            is $m->size, scalar(keys %h), "size check at iter=$i" or last;
        }
    }

    is $m->size, scalar(keys %h), 'II final size matches reference';
    for my $k (keys %h) {
        is $m->get($k), $h{$k}, "final get($k) matches" or last;
    }
}

# ---- SS vs %h (string-string) ----

{
    my $m = Data::HashMap::SS->new();
    my %h;
    my @pool = map { "k$_" } 0..99;

    for my $i (1 .. $OPS) {
        my $op = int(rand(3));
        my $k = $pool[int(rand(@pool))];
        if ($op == 0) {
            my $v = "v" . int(rand(1_000_000));
            $m->put($k, $v);
            $h{$k} = $v;
        }
        elsif ($op == 1) {
            my $got = $m->get($k);
            my $ref = $h{$k};
            if (defined($got) != defined($ref) || (defined $got && $got ne $ref)) {
                fail("SS op=get k=$k iter=$i"); last;
            }
        }
        else {
            $m->remove($k);
            delete $h{$k};
        }
    }
    is $m->size, scalar(keys %h), 'SS final size matches reference';
}

done_testing;
