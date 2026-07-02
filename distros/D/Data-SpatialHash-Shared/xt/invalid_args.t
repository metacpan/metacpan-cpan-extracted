use strict; use warnings; use Test::More;
use Data::SpatialHash::Shared;
plan skip_all => 'author test' unless $ENV{AUTHOR_TESTING};
my $s = Data::SpatialHash::Shared->new(undef, 100, 0, 1.0);
eval { $s->insert(1) };               ok $@, 'insert too few args';
eval { $s->move($s->insert(1,1,1), 1, 2, 3, 4) }; ok $@, 'move too many args';
eval { $s->query_radius(1,2) };       ok $@, 'query_radius too few args';
eval { $s->query_radius(0,0,-1) };    ok $@, 'negative radius';
eval { $s->query_knn(0,0,0) };        ok $@, 'k=0';
eval { $s->query_aabb(1,2,3) };       ok $@, 'aabb wrong arity';
eval { $s->query_cell(1) };           ok $@, 'query_cell wrong arity';
eval { $s->each_in_radius(0,0,5,'notcode') }; ok $@, 'each_in_radius non-coderef';
eval { $s->each_in_radius(0,0,-1,sub{}) };    ok $@, 'each_in_radius negative radius';
eval { $s->value(1<<30) };            ok $@, 'huge handle croaks';
eval { Data::SpatialHash::Shared->new(undef, 100, 0, -1) }; ok $@, 'negative cell_size';
# non-finite (Inf/NaN) rejected wherever a finite radius/extent is required -- an
# Inf radius used to silently scan only cell (0,0,0) and return a wrong subset
eval { $s->query_radius(0,0, "Inf"+0) };          ok $@, 'query_radius Inf radius croaks';
eval { $s->query_radius(0,0, "NaN"+0) };          ok $@, 'query_radius NaN radius croaks';
eval { $s->each_in_radius(0,0, "Inf"+0, sub{}) }; ok $@, 'each_in_radius Inf radius croaks';
eval { $s->each_pair_within("Inf"+0, sub{}) };    ok $@, 'each_pair_within Inf max_r croaks';
eval { $s->insert(1,2,3,4, "Inf"+0) };            ok $@, 'insert Inf radius croaks';
eval { Data::SpatialHash::Shared->new(undef, 100, 0, "Inf"+0) }; ok $@, 'Inf cell_size croaks';
{ my $h = $s->insert(7,7,9); eval { $s->set_radius($h, "Inf"+0) }; ok $@, 'set_radius Inf radius croaks'; }
{ my $g = Data::SpatialHash::Shared->new(undef, 100, 0, 50000, sphere => 6371000);
  eval { $g->query_geo_radius(0,0,0, "Inf"+0) }; ok $@, 'query_geo_radius Inf dist croaks'; }
ok defined($s->insert(1,2,3)), 'sane insert still works';
# query_knn enforces the cell cap via shell expansion (a distinct code path from
# the upfront span check used by query_radius/query_aabb)
{ my $c = Data::SpatialHash::Shared->new(undef, 10, 0, 1.0); $c->insert(0,0,1);
  eval { $c->query_knn(1e9, 1e9, 2) }; like $@, qr/cell/i, 'query_knn cap croaks with a cells message'; }
# the pair emitters reach the same cap via sph_pairs on a large FINITE reach
{ my $c = Data::SpatialHash::Shared->new(undef, 10, 0, 1.0); $c->insert(0,0,1);
  eval { $c->each_pair_within(1e9, sub{}) }; like $@, qr/cell/i, 'each_pair_within TOOBIG (large finite max_r) croaks'; }
{ my $c = Data::SpatialHash::Shared->new(undef, 10, 0, 1.0); my $h = $c->insert(0,0,1); $c->set_radius($h, 1e9);
  eval { $c->each_colliding_pair(sub{}) }; like $@, qr/cell/i, 'each_colliding_pair TOOBIG (huge entry radius) croaks'; }
# new-method error paths
eval { $s->each_pair_within(-1, sub {}) };   ok $@, 'each_pair_within negative max_r';
eval { $s->each_pair_within(1, 'notcode') }; ok $@, 'each_pair_within non-coderef';
eval { $s->each_colliding_pair('notcode') }; ok $@, 'each_colliding_pair non-coderef';
eval { $s->insert_many('notarray') };        ok $@, 'insert_many non-arrayref';
# insert_many validates each row's radius lock-safely (skips to undef, no croak-under-lock)
{ my @h = $s->insert_many([[1,2,3], [4,5,6,"Inf"+0], [7,8,9,-1]]);
  ok defined($h[0]),  'insert_many: good row inserts';
  ok !defined($h[1]), 'insert_many: Inf-radius row skipped to undef';
  ok !defined($h[2]), 'insert_many: negative-radius row skipped to undef'; }
eval { $s->move_many('notarray') };          ok $@, 'move_many non-arrayref';
eval { $s->query_radius_many('notarray') };  ok $@, 'query_radius_many non-arrayref';
eval { Data::SpatialHash::Shared->new(undef, 10, 0, 1.0, wrap => [1,2,3,4]) }; ok $@, 'wrap with 4 extents';
eval { Data::SpatialHash::Shared->new(undef, 10, 0, 1.0, "sphere") }; like $@, qr/odd number of option/, 'odd (unpaired) option list croaks';
done_testing;
