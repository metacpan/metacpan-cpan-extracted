use strict; use warnings; use Test::More;
use Data::SpatialHash::Shared;

# The 2D and 3D forms are selected by argument count; a 2D point is z=0,
# and a 2D query operates only on the z=0 cell layer (ignoring z entirely).

my $s = Data::SpatialHash::Shared->new(undef, 1000, 0, 1.0);

# a 2D insert stores z = 0
my $ha = $s->insert(3.5, 4.5, 1);
is_deeply [$s->position($ha)], [3.5, 4.5, 0], '2D insert stores z=0';

# the 2D point is found by both a 2D query and a 3D query at z=0
ok scalar(grep { $_ == 1 } $s->query_radius(3, 4, 2.0)),    '2D point: 2D query finds it';
ok scalar(grep { $_ == 1 } $s->query_radius(3, 4, 0, 2.0)), '2D point: 3D query at z=0 finds it';

# a 3D point sharing (x,y) but off the z=0 plane
my $hb = $s->insert(3.5, 4.5, 50, 2);
ok !scalar(grep { $_ == 2 } $s->query_radius(3, 4, 2.0)),     '2D query (z=0 layer) ignores the z=50 point';
ok scalar(grep { $_ == 2 } $s->query_radius(3, 4, 50, 2.0)),  '3D query at z=50 finds the z=50 point';

# the two points live in different cells along z (one point each in this fixture)
is_deeply [$s->query_cell(3, 4)],     [1], '2D point alone in cell (3,4,0)';
is_deeply [$s->query_cell(3, 4, 50)], [2], '3D point alone in cell (3,4,50)';

# move switches between the 2D and 3D forms
$s->move($ha, 8.5, 8.5);          # 2D move keeps z=0
is_deeply [$s->position($ha)], [8.5, 8.5, 0], '2D move keeps z=0';
$s->move($ha, 8.5, 8.5, 9.0);     # 3D move sets z
is_deeply [$s->position($ha)], [8.5, 8.5, 9.0], '3D move sets z';

# aabb honours the 2D/3D form too
$s->insert(2, 2, 3);                  # 2D (z=0)
ok scalar(grep { $_ == 3 } $s->query_aabb(1, 1, 3, 3)),          '2D aabb finds the 2D point';
ok scalar(grep { $_ == 3 } $s->query_aabb(1, 1, -1, 3, 3, 1)),   '3D aabb spanning z=0 finds it';
ok !scalar(grep { $_ == 3 } $s->query_aabb(1, 1, 10, 3, 3, 20)), '3D aabb above z=0 does not';

# each_in_radius honours the 3D form (items==6 dispatch)
my @seen3;
$s->each_in_radius(3.5, 4.5, 50, 2.0, sub { push @seen3, $_[0] });
my %seen3 = map { $_ => 1 } @seen3;
my %want3 = map { $_ => 1 } $s->query_radius(3.5, 4.5, 50, 2.0);
is_deeply \%seen3, \%want3, '3D each_in_radius matches 3D query_radius';

done_testing;
