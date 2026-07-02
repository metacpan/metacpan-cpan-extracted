use strict; use warnings; use Test::More;
use Data::SpatialHash::Shared;

my $s = Data::SpatialHash::Shared->new(undef, 5, 0, 1.0);

my $a = $s->insert(0.5, 0.5, 100);
ok defined $a, 'insert returns handle';
is $s->count, 1, 'count 1';
ok $s->has($a), 'has handle';
is $s->value($a), 100, 'value round-trip';
is_deeply [$s->position($a)], [0.5, 0.5, 0], 'position (z=0 for 2D)';

$s->set_value($a, 200);
is $s->value($a), 200, 'set_value';

# 3D insert
my $b = $s->insert(1.0, 2.0, 3.0, 999);
is_deeply [$s->position($b)], [1.0, 2.0, 3.0], '3D position';

# move
ok $s->move($a, 4.5, 4.5), 'move ok';
is_deeply [$s->position($a)], [4.5, 4.5, 0], 'moved position';

# remove
ok $s->remove($a), 'remove ok';
ok !$s->has($a), 'gone after remove';
is $s->count, 1, 'count back to 1';
ok !$s->remove($a), 'double remove returns false';

# value/position/set_value croak on a freed but in-range handle (the bitmap
# branch of sph_is_live), not only on out-of-range handles
eval { $s->value($a) };        ok $@, 'value on a freed handle croaks';
eval { $s->position($a) };     ok $@, 'position on a freed handle croaks';
eval { $s->set_value($a, 1) }; ok $@, 'set_value on a freed handle croaks';

# pool exhaustion: 5 slots, b uses 1, fill remaining 4
$s->insert($_, 0, $_) for 1..4;
is $s->insert(9, 9, 9), undef, 'insert returns undef when full';

# bad handle croaks
eval { $s->value(9999) };    ok $@, 'value on out-of-range handle croaks';
eval { $s->position(9999) }; ok $@, 'position on out-of-range handle croaks';

done_testing;
