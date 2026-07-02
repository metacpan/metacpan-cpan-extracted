use strict; use warnings; use Test::More;
use Data::SpatialHash::Shared;

# File-backed maps persist across reopen (durability), slot handles stay valid
# across reopen, and two handles to the same file are coherent (MAP_SHARED).

my $path = "/tmp/sph-persist-$$.bin";
unlink $path;

my $s = Data::SpatialHash::Shared->new($path, 1000, 0, 1.0);
my @h = map { $s->insert($_ + 0.5, $_ + 0.5, $_ * 10) } 0 .. 49;
is $s->count, 50, '50 entries before close';
$s->sync;
undef $s;                                              # munmap; file persists

my $s2 = Data::SpatialHash::Shared->new($path, 1000, 0, 1.0);
is $s2->count, 50, 'count persisted across reopen';
is_deeply [sort { $a <=> $b } $s2->query_aabb(-1, -1, 100, 100)],
          [map { $_ * 10 } 0 .. 49], 'all values persisted';
# slot indices are stable across reopen, so the old handles still resolve
is $s2->value($h[5]), 50, 'handle still valid + value persisted across reopen';
is_deeply [$s2->position($h[5])], [5.5, 5.5, 0], 'position persisted';
ok $s2->has($h[5]), 'handle live after reopen';

# two handles to the same file in one process see each other (coherent mmap)
my $a = Data::SpatialHash::Shared->new($path, 1000, 0, 1.0);
my $b = Data::SpatialHash::Shared->new($path, 1000, 0, 1.0);
my $hh = $a->insert(80.5, 80.5, 999);
ok  scalar(grep { $_ == 999 } $b->query_radius(80.5, 80.5, 1)), 'second handle sees first handle insert';
$a->remove($hh);
ok !scalar(grep { $_ == 999 } $b->query_radius(80.5, 80.5, 1)), 'second handle sees the remove';
undef $a; undef $b; undef $s2;

unlink $path;
done_testing;
