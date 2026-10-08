use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

use Data::HashMap::Shared::SS;

# pop/shift/drain start each call one shard further on (h->shard_rr); only
# delivery order shows it. The key-to-shard split is read off the PFX.n shard
# files, which are ordinary maps (xxhash is deterministic).

my $SHARDS = 4;
my $CAP    = 4000;
my $dir    = tempdir(CLEANUP => 1);
my $seq    = 0;

sub shard_of {
    my ($path) = @_;
    my %where;
    for my $i (0 .. $SHARDS - 1) {
        my $s = Data::HashMap::Shared::SS->new("$path.$i", $CAP);
        my @k = $s->keys;
        $where{$_} = $i for @k;
    }
    return \%where;
}

sub seeded {
    my ($name, $n) = @_;
    my $path = "$dir/$name" . $seq++;
    my $m = Data::HashMap::Shared::SS->new_sharded($path, $SHARDS, $CAP);
    $m->put("fair-key-$_", "value-$_") for 1 .. $n;
    my $where = shard_of($path);
    my %pop;
    $pop{ $where->{$_} }++ for keys %$where;
    my @thin = grep { ($pop{$_} // 0) < $SHARDS * 2 } 0 .. $SHARDS - 1;
    return ($m, $path, $where, \@thin);
}

for my $case (
    [ 'drain', sub { ($_[0]->drain(1))[0] } ],
    [ 'pop',   sub { ($_[0]->pop)[0] } ],
    [ 'shift', sub { ($_[0]->shift)[0] } ],
) {
    my ($name, $take) = @$case;
    my ($m, $path, $where, $thin) = seeded($name, 200);
    is scalar @$thin, 0, "$name: every shard holds enough keys to see a turn" or next;

    my @shards;
    for (1 .. $SHARDS) {
        my $k = $take->($m);
        last unless defined $k;
        push @shards, $where->{$k};
    }
    is scalar @shards, $SHARDS, "$name: $SHARDS calls each returned a key";
    my %seen; $seen{$_}++ for @shards;
    is scalar(keys %seen), $SHARDS,
       "$name: $SHARDS successive calls took from $SHARDS different shards (got @shards)";
}

{
    my ($m, $path, $where, $thin) = seeded('starve', 200);
    is scalar @$thin, 0, 'starvation case: every shard holds enough keys to see a turn';
    my @refill = grep { $where->{$_} == 0 } sort keys %$where;
    cmp_ok scalar @refill, '>=', 8, 'enough shard-0 keys to keep it stocked';
    splice @refill, 8;
    $m->remove($_) for @refill;                 # held back as the producer's backlog

    my %seen;
    for my $round (0 .. 7) {
        my ($k) = $m->drain(1);
        last unless defined $k;
        $seen{ $where->{$k} }++;
        $m->put($refill[$round], "refilled-$round");
    }
    is scalar(keys %seen), $SHARDS,
       "drain against a producer stocking shard 0 still reaches every shard (" .
       join(', ', map { "shard $_ x$seen{$_}" } sort keys %seen) . ")";
    cmp_ok $seen{0}, '<=', 2 + 8 / $SHARDS,
       'and shard 0 did not take more than its turn';
}

done_testing;
