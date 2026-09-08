use strict;
use warnings;
use Test::More;
use Time::HiRes ();
use File::Temp ();
use File::Spec ();

use Data::HashMap::Shared::II;
use Data::HashMap::Shared::SS;

sub tmpfile { File::Temp::tempnam(File::Spec->tmpdir, 'shm_resize') . '.shm' }

# Insert enough to force several grow cycles, then verify all keys/values
{
    my $path = tmpfile();
    my $N = 10_000;
    my $map = Data::HashMap::Shared::II->new($path, $N);
    my $cap_before = $map->capacity;

    $map->put($_, $_ * 7) for 1..$N;
    is($map->size, $N, "II resize: inserted $N entries");
    my $cap_after = $map->capacity;
    ok($cap_after > $cap_before, "II resize: capacity grew ($cap_before → $cap_after)");

    # Verify every value
    my $ok = 1;
    for (1..$N) { $ok = 0, last if $map->get($_) != $_ * 7 }
    ok($ok, "II resize: all values intact after grow");

    # Drain everything; the table halves back to its initial capacity.  Asserting
    # only "did not grow" passed just as happily when shrink never ran at all.
    for (1..$N) { $map->remove($_) }
    is($map->size, 0, "II resize: emptied");
    my $cap_final = $map->capacity;
    is($cap_final, $cap_before, "II resize: capacity shrank back to $cap_before on drain (from $cap_after)");
    unlink $path;
}

# String variant: grow + shrink with string values
{
    my $path = tmpfile();
    my $N = 5_000;
    my $map = Data::HashMap::Shared::SS->new($path, $N);
    $map->put("k$_", "v" x ($_ % 50 + 1)) for 1..$N;
    is($map->size, $N, "SS resize: inserted $N entries");

    # Verify a sample
    my $ok = 1;
    for my $i (1, 100, 2500, 4999, $N) {
        my $expected = "v" x ($i % 50 + 1);
        $ok = 0, last if $map->get("k$i") ne $expected;
    }
    ok($ok, "SS resize: sample values intact");

    my $arena_used = $map->arena_used;
    $map->remove("k$_") for 1..$N;
    is($map->size, 0, "SS resize: emptied");
    ok($map->arena_used <= $arena_used, "SS resize: arena_used not growing on drain");
    unlink $path;
}

# reserve grows capacity ahead of time without inserting
{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 100_000);
    my $cap_initial = $map->capacity;
    ok($map->reserve(10_000), "reserve: succeeds for 10k entries");
    ok($map->capacity > $cap_initial, "reserve: capacity grew");
    is($map->size, 0, "reserve: no entries actually inserted");
    unlink $path;
}


# A batch removal reaches maybe_shrink ONCE for the whole batch, so a shrink
# that steps one halving per call leaves the table oversized.  Removing keys
# singly (above) converges either way and cannot tell the two apart.
for my $how (['drain',         sub { $_[0]->drain($_[1]) }],
             ['remove_multi',  sub { $_[0]->remove_multi(1 .. $_[1]) }],
             ['flush_expired', sub { $_[0]->flush_expired }]) {
    my ($name, $empty) = @$how;
    my $path = tmpfile();
    my $ttl  = $name eq 'flush_expired' ? 1 : 0;
    my $map  = Data::HashMap::Shared::II->new($path, 100_000, 0, $ttl);
    my $cap0 = $map->capacity;
    my $N    = 20_000;
    $map->put($_, $_) for 1 .. $N;
    my $grown = $map->capacity;
    cmp_ok($grown, '>', $cap0, "$name: table grew to $grown");

    Time::HiRes::sleep(1.2) if $ttl;                       # let every entry expire
    $empty->($map, $N);
    is($map->size, 0, "$name: emptied in one call");
    is($map->capacity, $cap0,
       "$name: capacity returned to $cap0, not part-way (was $grown)");
    unlink $path;
}

done_testing;
