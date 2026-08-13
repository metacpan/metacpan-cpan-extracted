use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Data::SpatialHash::Shared;

my $dir  = tempdir(CLEANUP => 1);
my $path = "$dir/frozen.sph";

sub S { [ sort { $a <=> $b } @{ $_[0] } ] }
sub pair_key { my ($a, $b) = @_; ($a, $b) = ($b, $a) if $a > $b; return "$a,$b"; }
sub sorted_pairs {
    my @out;
    my $cb = sub { push @out, pair_key(@_) };
    return ($cb, \@out);
}

# ---- producer: build MANY points across MANY cells, freeze ----
my ($h2d, $h3d, $ca, $cb, $cc);
my ($exp_cell, $exp_aabb, $exp_radius, $exp_knn);
my (@exp_batch, @exp_each, @exp_pairwithin, @exp_colliding);
my ($exp_pos2d, $exp_val2d, $exp_rad2d, $exp_pos3d, $exp_count, $exp_stats);
{
    my $s = Data::SpatialHash::Shared->new($path, 2000, 0, 1.0);
    ok !$s->frozen,   'freshly created spatial hash is not frozen';
    ok !$s->readonly, 'read-write handle is not read-only';

    # 25x25 grid: 625 points, one per cell (many points across many cells)
    for my $gx (0 .. 24) {
        for my $gy (0 .. 24) {
            my $v = $s->insert($gx + 0.5, $gy + 0.5, $gx * 25 + $gy);
            $h2d = $v if $gx == 10 && $gy == 10;   # remember one handle for has/value/position
        }
    }
    # a handful of 3D points (nonzero z)
    for my $i (0 .. 4) {
        my $v = $s->insert(100 + $i, 100, 5, 9000 + $i);
        $h3d = $v if $i == 2;
    }
    # a small collision cluster (radius-bearing 2D entries, well away from the grid)
    $ca = $s->insert(1000, 1000, 0, 9001, 2.0);
    $cb = $s->insert(1001, 1000, 0, 9002, 2.0);   # distance 1 < 2+2 -> collides with ca
    $cc = $s->insert(1000, 1050, 0, 9003, 1.0);   # far away -> collides with neither

    $exp_count = $s->count;
    is $exp_count, 625 + 5 + 3, 'producer count == inserted points';

    $exp_pos2d = [ $s->position($h2d) ];
    $exp_val2d = $s->value($h2d);
    $exp_rad2d = $s->get_radius($ca);
    $exp_pos3d = [ $s->position($h3d) ];

    $exp_cell   = S([ $s->query_cell(10.5, 10.5) ]);
    $exp_aabb   = S([ $s->query_aabb(5, 5, 15, 15) ]);
    $exp_radius = S([ $s->query_radius(12, 12, 8) ]);
    $exp_knn    = [ $s->query_knn(12, 12, 5) ];              # nearest-first: order matters
    @exp_batch  = map { S($_) } @{ $s->query_radius_many([ [ 5, 5, 3 ], [ 20, 20, 4 ], [ 1000, 1000, 5 ] ]) };

    $s->each_in_radius(12, 12, 8, sub { push @exp_each, $_[0] });
    @exp_each = sort { $a <=> $b } @exp_each;

    {
        my ($cb1, $out1) = sorted_pairs();
        $s->each_pair_within(1.5, $cb1);
        @exp_pairwithin = sort @$out1;
    }
    {
        my ($cb2, $out2) = sorted_pairs();
        $s->each_colliding_pair($cb2);
        @exp_colliding = sort @$out2;
    }
    is_deeply \@exp_colliding, [ pair_key(9001, 9002) ], 'producer: exactly the one colliding pair';

    $exp_stats = $s->stats;

    $s->freeze;
    ok $s->frozen,   'frozen after ->freeze';
    ok $s->readonly, 'freezing handle becomes read-only';
    is $s->count, $exp_count, 'count unchanged by freeze';

    # ---- every mutator croaks frozen (producer handle) ----
    like exception(sub { $s->insert(0, 0, 1) }),              qr/frozen|read-only/, 'insert on frozen handle croaks';
    like exception(sub { $s->insert_many([[0,0,1]]) }),       qr/frozen|read-only/, 'insert_many on frozen handle croaks';
    like exception(sub { $s->insert_geo(0, 0, 0, 1) }),       qr/frozen|read-only/, 'insert_geo on frozen handle croaks';
    like exception(sub { $s->move($h2d, 0, 0) }),             qr/frozen|read-only/, 'move on frozen handle croaks';
    like exception(sub { $s->move_many([[$h2d, 0, 0]]) }),    qr/frozen|read-only/, 'move_many on frozen handle croaks';
    like exception(sub { $s->move_geo($h2d, 0, 0, 0) }),      qr/frozen|read-only/, 'move_geo on frozen handle croaks';
    like exception(sub { $s->remove($h2d) }),                 qr/frozen|read-only/, 'remove on frozen handle croaks';
    like exception(sub { $s->set_value($h2d, 1) }),           qr/frozen|read-only/, 'set_value on frozen handle croaks';
    like exception(sub { $s->set_radius($h2d, 1) }),          qr/frozen|read-only/, 'set_radius on frozen handle croaks';
    like exception(sub { $s->clear }),                        qr/frozen|read-only/, 'clear on frozen handle croaks';
    like exception(sub { $s->freeze }),                       qr/read-only/,        'freeze on a read-only handle croaks';

    # handle and count must be intact: no mutator partially applied before croaking
    is $s->count, $exp_count, 'count still unchanged after the mutator-croak sweep';
}

# ---- consumer: read-only attach (the shipped artifact) ----
{
    my $ro = Data::SpatialHash::Shared->new_readonly($path);
    isa_ok $ro, 'Data::SpatialHash::Shared';
    ok $ro->frozen,   'read-only view reports frozen';
    ok $ro->readonly, 'read-only view reports readonly';

    # every read/query/accessor method on the read-only (PROT_READ) handle --
    # a method that still takes the rwlock here would SIGSEGV.
    ok $ro->has($h2d), 'has true via read-only view';
    ok !$ro->has(999_999), 'has false for an invalid handle via read-only view';
    is $ro->value($h2d), $exp_val2d, 'value matches producer via read-only view';
    is $ro->get_radius($ca), $exp_rad2d, 'get_radius matches producer via read-only view';
    is_deeply [ $ro->position($h2d) ], $exp_pos2d, 'position (2D) matches producer via read-only view';
    is_deeply [ $ro->position($h3d) ], $exp_pos3d, 'position (3D) matches producer via read-only view';
    is $ro->count, $exp_count, 'count matches producer via read-only view';

    is_deeply S([ $ro->query_cell(10.5, 10.5) ]), $exp_cell, 'query_cell matches producer via read-only view';
    is_deeply S([ $ro->query_aabb(5, 5, 15, 15) ]), $exp_aabb, 'query_aabb matches producer via read-only view';
    is_deeply S([ $ro->query_radius(12, 12, 8) ]), $exp_radius, 'query_radius matches producer via read-only view';
    is_deeply [ $ro->query_knn(12, 12, 5) ], $exp_knn, 'query_knn (nearest-first) matches producer via read-only view';

    my $batch = $ro->query_radius_many([ [ 5, 5, 3 ], [ 20, 20, 4 ], [ 1000, 1000, 5 ] ]);
    is_deeply [ map { S($_) } @$batch ], \@exp_batch, 'query_radius_many matches producer via read-only view';

    my @got_each;
    $ro->each_in_radius(12, 12, 8, sub { push @got_each, $_[0] });
    is_deeply [ sort { $a <=> $b } @got_each ], \@exp_each, 'each_in_radius matches producer via read-only view';

    {
        my ($rocb, $roout) = sorted_pairs();
        $ro->each_pair_within(1.5, $rocb);
        is_deeply [ sort @$roout ], \@exp_pairwithin, 'each_pair_within matches producer via read-only view';
    }
    {
        my ($rocb, $roout) = sorted_pairs();
        $ro->each_colliding_pair($rocb);
        is_deeply [ sort @$roout ], \@exp_colliding, 'each_colliding_pair matches producer via read-only view';
    }

    my $st = $ro->stats;
    is $st->{frozen},      1, 'stats.frozen set';
    is $st->{readonly},    1, 'stats.readonly set';
    is $st->{count},       $exp_count, 'stats.count matches producer via read-only view';
    is $st->{max_entries}, $exp_stats->{max_entries}, 'stats.max_entries matches producer';
    is $st->{num_buckets}, $exp_stats->{num_buckets}, 'stats.num_buckets matches producer';
    is $st->{max_chain},   $exp_stats->{max_chain},   'stats.max_chain matches producer via read-only view';
    is $st->{max_cell},    $exp_stats->{max_cell},    'stats.max_cell matches producer via read-only view';

    # plain introspection accessors (already lock-free, but must still work read-only)
    is $ro->max_entries, $exp_stats->{max_entries}, 'max_entries readable read-only';
    is $ro->num_buckets, $exp_stats->{num_buckets}, 'num_buckets readable read-only';
    is $ro->cell_size, 1.0, 'cell_size readable read-only';
    is $ro->path, $path, 'path readable read-only';
    is $ro->memfd, -1, 'memfd readable read-only (file-backed => -1)';

    eval { $ro->sync };
    ok !$@, 'sync on read-only view is a silent no-op';

    # ---- every mutator croaks on the read-only view too ----
    like exception(sub { $ro->insert(0, 0, 1) }),           qr/read-only/, 'insert on read-only view croaks';
    like exception(sub { $ro->insert_many([[0,0,1]]) }),    qr/read-only/, 'insert_many on read-only view croaks';
    like exception(sub { $ro->insert_geo(0, 0, 0, 1) }),    qr/read-only/, 'insert_geo on read-only view croaks';
    like exception(sub { $ro->move($h2d, 0, 0) }),          qr/read-only/, 'move on read-only view croaks';
    like exception(sub { $ro->move_many([[$h2d, 0, 0]]) }), qr/read-only/, 'move_many on read-only view croaks';
    like exception(sub { $ro->move_geo($h2d, 0, 0, 0) }),   qr/read-only/, 'move_geo on read-only view croaks';
    like exception(sub { $ro->remove($h2d) }),              qr/read-only/, 'remove on read-only view croaks';
    like exception(sub { $ro->set_value($h2d, 1) }),        qr/read-only/, 'set_value on read-only view croaks';
    like exception(sub { $ro->set_radius($h2d, 1) }),       qr/read-only/, 'set_radius on read-only view croaks';
    like exception(sub { $ro->clear }),                     qr/read-only/, 'clear on read-only view croaks';
    like exception(sub { $ro->freeze }),                    qr/read-only/, 'freeze on read-only view croaks';

    is $ro->count, $exp_count, 'count still unchanged after the read-only mutator-croak sweep';
}

# ---- two independent read-only views of the same file, concurrently ----
{
    my $a = Data::SpatialHash::Shared->new_readonly($path);
    my $b = Data::SpatialHash::Shared->new_readonly($path);
    ok $a->has($h2d) && $b->has($h2d), 'two read-only views query the same file';
    is_deeply [ $a->position($h2d) ], [ $b->position($h2d) ], 'two read-only views agree';
}

# ---- refuse a read-write reopen of a sealed file ----
like exception(sub { Data::SpatialHash::Shared->new($path, 2000, 0, 1.0) }),
     qr/frozen|read-only/, 'read-write reopen of a sealed file is refused';

# ---- new_from_fd also refuses a sealed file opened read-write ----
{
    open(my $fh, '+<', $path) or die "open $path: $!";
    like exception(sub { Data::SpatialHash::Shared->new_from_fd(fileno($fh)) }),
         qr/frozen|read-only/, 'new_from_fd on a sealed file is refused';
}

# ---- new_readonly rejects a non-frozen file ----
{
    my $u = "$dir/unsealed.sph";
    { my $s = Data::SpatialHash::Shared->new($u, 100, 0, 1.0); $s->insert(1, 1, 1); }
    like exception(sub { Data::SpatialHash::Shared->new_readonly($u) }),
         qr/not frozen/, 'new_readonly on an unsealed file croaks';
}

# ---- new_readonly error paths ----
like exception(sub { Data::SpatialHash::Shared->new_readonly("$dir/does-not-exist.sph") }),
     qr/open|No such/, 'new_readonly on a missing path croaks';
like exception(sub { Data::SpatialHash::Shared->new_readonly(undef) }),
     qr/required/, 'new_readonly requires a path';

# ---- spherical (geo) world: producer/consumer parity for the geo read paths ----
{
    my $gpath = "$dir/geo.sph";
    my $geh;
    my ($exp_geo_pos, $exp_geo_radius);
    {
        # cell_size 5km; points spread ~5-55km apart (lat/lon steps of a fraction
        # of a radian); query dist 30km -> per-axis cell span well under the cap.
        my $g = Data::SpatialHash::Shared->new($gpath, 200, 0, 5_000, sphere => 6_371_000);
        for my $i (0 .. 19) {
            my $v = $g->insert_geo(0.0005 * ($i - 10), 0.0007 * ($i - 10), 500, 5000 + $i);
            $geh = $v if $i == 10;
        }
        $exp_geo_pos = [ $g->position_geo($geh) ];
        $exp_geo_radius = S([ $g->query_geo_radius(0, 0, 500, 30_000) ]);
        ok scalar(@$exp_geo_radius) > 1, 'sanity: geo radius query matches more than one point';
        $g->freeze;
        like exception(sub { $g->insert_geo(0, 0, 0, 1) }), qr/frozen|read-only/, 'insert_geo on frozen geo handle croaks';
        like exception(sub { $g->move_geo($geh, 0, 0, 0) }), qr/frozen|read-only/, 'move_geo on frozen geo handle croaks';
    }
    my $gro = Data::SpatialHash::Shared->new_readonly($gpath);
    ok $gro->frozen && $gro->readonly, 'geo read-only view reports frozen/readonly';
    my @got_geo_pos = $gro->position_geo($geh);
    for my $i (0 .. 2) {
        cmp_ok abs($got_geo_pos[$i] - $exp_geo_pos->[$i]), '<', 1e-9, "position_geo[$i] matches producer via read-only view";
    }
    is_deeply S([ $gro->query_geo_radius(0, 0, 500, 30_000) ]), $exp_geo_radius,
        'query_geo_radius matches producer via read-only view';
    like exception(sub { $gro->insert_geo(0, 0, 0, 1) }), qr/read-only/, 'insert_geo on read-only geo view croaks';
    like exception(sub { $gro->move_geo($geh, 0, 0, 0) }), qr/read-only/, 'move_geo on read-only geo view croaks';
}

done_testing;

# minimal exception helper (avoid a Test::Fatal dependency)
sub exception {
    my $code = shift;
    my $err;
    { local $@; eval { $code->(); 1 } or $err = $@; }
    return $err;
}
