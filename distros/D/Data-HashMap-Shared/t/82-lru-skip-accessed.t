use strict;
use warnings;
use Test::More;
use Data::HashMap::Shared::II;

# With $lru_skip most updates skip the promotion, and a skipped one must still
# set the accessed bit: otherwise a key updated just before an eviction is
# taken as though nobody had touched it.  lru_skip 90 skips 15 updates in 16.

my %op = (
    put        => sub { shm_ii_put $_[0], 2, 20 },
    touch      => sub { shm_ii_touch $_[0], 2 },
    incr       => sub { shm_ii_incr $_[0], 2 },
    get_or_set => sub { shm_ii_get_or_set $_[0], 2, 20 },
);
for my $name (sort keys %op) {
    my $lost = 0;
    for (1 .. 16) {
        my $m = Data::HashMap::Shared::II->new(undef, 1000, 100, 0, 90);
        shm_ii_put $m, $_, $_ for 1 .. 100;
        $op{$name}->($m);                     # key 2 is next to the tail
        shm_ii_put $m, $_, $_ for 101, 102;   # evicts two
        $lost++ unless shm_ii_exists $m, 2;
    }
    is $lost, 0, "$name: the updated key survives the next two evictions";
}

done_testing;
