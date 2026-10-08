use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

use Data::HashMap::Shared::SS;
use Data::HashMap::Shared::SI;

# Every insert path lands on the first tombstone it probes past and retires it;
# content tests cannot see that, but hdr->tombstones would only grow and refill
# workloads would rehash. Counts stay under shm_needs_compaction and
# shm_over_load, which would clear tombstones and hide it.

my $dir = tempdir(CLEANUP => 1);
my $seq = 0;

# Seed $n keys, remove the first $m, re-insert them through $insert; each probes
# the tombstone it just made.
sub cycle {
    my (%o) = @_;
    my ($class, $n, $m, $seed, $insert) = @o{qw(class n m seed insert)};
    my $map = $class->new("$dir/t" . $seq++, 4000);
    my @keys = map { "tomb-key-$_" } 1 .. $n;

    $seed->($map, $_) for @keys;
    my $cap0 = $map->capacity;
    my $t0   = $map->stats->{tombstones};

    $map->remove($_) for @keys[0 .. $m - 1];
    my $t1 = $map->stats->{tombstones};

    $insert->($map, $_) for @keys[0 .. $m - 1];
    return { map => $map, cap0 => $cap0, t0 => $t0, t1 => $t1,
             t2 => $map->stats->{tombstones} };
}

my @paths = (
    [ 'put',        'Data::HashMap::Shared::SS',
      sub { $_[0]->put($_[1], "value-of-$_[1]") },
      sub { $_[0]->put($_[1], "value-of-$_[1]") } ],
    [ 'add',        'Data::HashMap::Shared::SS',
      sub { $_[0]->put($_[1], "value-of-$_[1]") },
      sub { $_[0]->add($_[1], "value-of-$_[1]") } ],
    [ 'swap',       'Data::HashMap::Shared::SS',
      sub { $_[0]->put($_[1], "value-of-$_[1]") },
      sub { $_[0]->swap($_[1], "value-of-$_[1]") } ],
    [ 'get_or_set', 'Data::HashMap::Shared::SS',
      sub { $_[0]->put($_[1], "value-of-$_[1]") },
      sub { $_[0]->get_or_set($_[1], "value-of-$_[1]") } ],
    [ 'incr_by',    'Data::HashMap::Shared::SI',
      sub { $_[0]->put($_[1], 7) },
      sub { $_[0]->incr_by($_[1], 7) } ],
    [ 'max',        'Data::HashMap::Shared::SI',
      sub { $_[0]->put($_[1], 7) },
      sub { $_[0]->max($_[1], 7) } ],
);

for my $case (@paths) {
    my ($name, $class, $seed, $insert) = @$case;
    my $r = cycle(class => $class, n => 300, m => 50, seed => $seed, insert => $insert);

    is $r->{t0}, 0,  "$name: the seeded table has no tombstones";
    is $r->{t1}, 50, "$name: removing 50 keys leaves 50 tombstones";
    is $r->{t2}, 0,  "$name: re-inserting those 50 keys retired every tombstone";
    is $r->{map}->capacity, $r->{cap0},
       "$name: with no rehash to clear them (capacity still $r->{cap0})";
    is $r->{map}->size, 300, "$name: all 300 keys are present";
}

# Enough churn to cross shm_over_load if the tombstones are not retired.
{
    my $r = cycle(class => 'Data::HashMap::Shared::SS', n => 300, m => 100,
                  seed   => sub { $_[0]->put($_[1], "value-of-$_[1]") },
                  insert => sub { $_[0]->put($_[1], "value-of-$_[1]") });
    is $r->{map}->capacity, $r->{cap0},
       "300 keys, remove 100, put the same 100 back: the table stays at $r->{cap0} slots";
    is $r->{map}->size, 300, "and still holds exactly 300 keys";
}

# At max_entries the table cannot grow and churn turns empty slots into
# tombstones; once they outnumber the empty slots it must compact.
{
    require Data::HashMap::Shared::II;
    my $m = Data::HashMap::Shared::II->new(undef, 1000);
    my $k = 0;
    1 while $m->put(++$k, 1);                              # every slot, then refused
    my $cap = $m->capacity;
    $m->remove($_) for 1 .. $cap / 4;                     # max_entries left, the rest tombstones
    is $m->size + $m->tombstones, $cap, "full table: $cap slots, none empty";
    $m->put(-1, 1);
    is $m->tombstones, 0, 'the next insert compacts the tombstones away';
    is $m->capacity, $cap, '...in place, at the same capacity';
}

done_testing;
