use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

use Data::HashMap::Shared::SS;
use Data::HashMap::Shared::SI;

# Every insert path lands a new entry on the first tombstone it probes past,
# retiring it.  Without that the insert walks on to the first empty slot: the
# content is identical, so no content test sees it, but hdr->tombstones only
# grows, and shm_over_load counts it, so a remove-and-refill workload rehashes
# and doubles a table that had room -- taking a table_gen bump and every live
# cursor's reset with it.
#
# Six insert paths carry their own copy, so each is cycled below.  The counts
# stay under shm_needs_compaction (tomb <= size, tomb <= cap/4) and under
# shm_over_load, either of which would clear the tombstones by rehashing and
# hide the difference; the last block crosses over_load deliberately, to show
# what that costs.

my $dir = tempdir(CLEANUP => 1);
my $seq = 0;

# Seed $n keys, remove the first $m, then re-insert exactly those $m through
# $insert.  The same keys hash the same way, so every re-insert probes the
# tombstone it just made.
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

done_testing;
