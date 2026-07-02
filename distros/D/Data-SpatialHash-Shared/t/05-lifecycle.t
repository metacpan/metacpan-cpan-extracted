use strict; use warnings; use Test::More;
use Data::SpatialHash::Shared;

my $s = Data::SpatialHash::Shared->new(undef, 1000, 0, 1.0);
$s->insert($_+0.5, 0.5, $_) for 0..9;

# each_in_radius: snapshot-then-callback, safe to mutate inside cb
my @seen;
$s->each_in_radius(5, 0.5, 3.0, sub { push @seen, $_[0] });
my %seen = map { $_=>1 } @seen;
my %want = map { $_=>1 } $s->query_radius(5, 0.5, 3.0);
is_deeply \%seen, \%want, 'each_in_radius matches query_radius';

# callback may re-enter the map (no deadlock) because snapshot is taken first
my $count = 0;
$s->each_in_radius(5, 0.5, 100.0, sub { $count++ if $s->has($_[0]); });
is $count, 10, 'callback can call back into the map';

# stats
my $st = $s->stats;
is $st->{count}, 10, 'stats count';
is $st->{max_entries}, 1000, 'stats max_entries';
ok exists $st->{occupied_buckets}, 'stats occupied_buckets';
ok exists $st->{max_chain}, 'stats max_chain';
ok exists $st->{load_factor}, 'stats load_factor';
is $st->{free_slots}, 990, 'stats free_slots';
ok exists $st->{ops}, 'stats ops';
is $st->{num_buckets}, $s->num_buckets, 'stats num_buckets';
is $st->{cell_size}, 1.0, 'stats cell_size';
cmp_ok $st->{mmap_size}, '>', 0, 'stats mmap_size';

# clear
$s->clear;
is $s->count, 0, 'cleared';
is_deeply [$s->query_radius(5,0.5,100)], [], 'empty after clear';
# reuse after clear
my $h = $s->insert(1,1,42);
is $s->value($h), 42, 'usable after clear';

# --- error paths ---
# set_value on an invalid handle croaks (and releases the write lock)
eval { $s->set_value(999_999, 7) }; ok $@, 'set_value on bad handle croaks';

# a callback that dies propagates out of each_in_radius, does not strand the
# lock, and (verified under the valgrind CI job, which runs t/*.t) does not
# leak the snapshot buffer.
$s->insert($_, 0, $_) for 20..25;
my $iters = 0;
eval { $s->each_in_radius(22, 0, 100, sub { $iters++; die "stop\n" }) };
like $@, qr/stop/, 'dying callback propagates';
ok $iters >= 1, 'callback ran before dying';
ok defined($s->insert(0, 0, 1)), 'map still usable after a dying callback (lock not stranded)';

# the callback may MUTATE the map during iteration: the snapshot is taken under
# the lock before any callback runs, so iteration sees the pre-mutation set.
{
    my $m = Data::SpatialHash::Shared->new(undef, 1000, 0, 1.0);
    my %hv; $hv{$_} = $m->insert($_ + 0.5, 0.5, $_) for 1 .. 10;
    my @delivered;
    $m->each_in_radius(5, 0.5, 100, sub {
        my ($v) = @_;
        push @delivered, $v;
        $m->remove($hv{$v});               # remove the entry just seen
        $m->insert(500, 500, 1000 + $v);   # and insert a new far-away one
    });
    is_deeply [sort { $a <=> $b } @delivered], [1 .. 10], 'callback got the full pre-mutation snapshot';
    is $m->count, 10, 'count consistent after mutating during iteration (10 removed, 10 inserted)';
    is_deeply [$m->query_radius(5, 0.5, 100)], [], 'originals removed by the callback';
    is_deeply [sort { $a <=> $b } $m->query_radius(500, 500, 1)], [map { 1000 + $_ } 1 .. 10],
        'callback inserts are present and consistent';
}

done_testing;
