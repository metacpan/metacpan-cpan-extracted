use strict;
use warnings;
use Test::More;
use File::Temp ();
use File::Spec ();

use Data::HashMap::Shared::II;

# Model-based / oracle test: drive a long random stream of operations against
# the map AND a plain Perl-hash reference, then reconcile. A small key space
# forces frequent collisions, updates, removes, and tombstone reuse / resizes.
# Deterministic (srand) so failures reproduce.

sub tmp { File::Temp::tempnam(File::Spec->tmpdir, 'shm_oracle') . '.shm' }

my $path = tmp();
my $m = Data::HashMap::Shared::II->new($path, 100_000);
my %oracle;
srand(20260624);

my $KEYSPACE = 400;
my $ROUNDS   = 4;
my $OPS      = 6000;

sub reconcile {
    my $label = shift;
    is($m->size, scalar keys %oracle, "$label: size matches oracle (@{[scalar keys %oracle]} keys)");
    my $bad = 0;
    for my $k (keys %oracle) {
        my $got = $m->get($k);
        $bad++ unless defined $got && $got == $oracle{$k};
    }
    is($bad, 0, "$label: every present key matches the oracle");
    my $ghost = 0;
    for my $k (0 .. $KEYSPACE - 1) {
        next if exists $oracle{$k};
        $ghost++ if defined $m->get($k);
    }
    is($ghost, 0, "$label: absent keys return undef");
}

# values stay well within int64 (and 64-bit Perl IV), so oracle arithmetic
# matches the map's exactly (no wrap in this range)
for my $round (1 .. $ROUNDS) {
    for (1 .. $OPS) {
        my $k  = int rand $KEYSPACE;
        my $op = int rand 5;
        if ($op == 0) {                              # put / overwrite
            my $v = int(rand 1e9);
            $m->put($k, $v);
            $oracle{$k} = $v;
        } elsif ($op == 1) {                         # remove
            $m->remove($k);
            delete $oracle{$k};
        } elsif ($op == 2) {                         # incr_by (creates at delta)
            my $d = int(rand 2001) - 1000;
            $m->incr_by($k, $d);
            $oracle{$k} = ($oracle{$k} // 0) + $d;
        } elsif ($op == 3) {                         # max (insert-if-absent)
            my $v = int(rand 1e9);
            $m->max($k, $v);
            $oracle{$k} = (exists $oracle{$k} && $oracle{$k} > $v) ? $oracle{$k} : $v;
        } else {                                     # get (exercise lookups)
            $m->get($k);
        }
    }
    reconcile("round $round");
}

unlink $path;
done_testing;
