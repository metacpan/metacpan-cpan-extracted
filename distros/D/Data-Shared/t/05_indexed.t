use strict;
use warnings;
use Test::More;
use Data::Shared qw(shared_get shared_set shared_incr shared_call);

subtest 'ndarray' => sub {
    my $r = Data::Shared->new;
    eval { $r->mount('lat', 'ndarray', undef, 'f64', 2, 3) };
    if ($@) { plan skip_all => "backend unavailable: $@"; return }
    shared_set($r, '/lat/0/1', 1.5);
    is shared_get($r, '/lat/0/1'), 1.5, 'ndarray get 0,1';
    shared_set($r, '/lat/1/2', 9);
    is shared_get($r, '/lat/1/2'), 9, 'ndarray get 1,2';
    is shared_call($r, '/lat', 'size'), 6, 'size via call';
    my @shape = shared_call($r, '/lat', 'shape');
    is_deeply \@shape, [2, 3], 'shape via call list context';
};

subtest 'fenwick' => sub {
    my $r = Data::Shared->new;
    eval { $r->mount('counts', 'fenwick', undef, 100) };
    if ($@) { plan skip_all => "backend unavailable: $@"; return }
    shared_incr($r, '/counts/5', 3);
    shared_incr($r, '/counts/9', 7);
    is shared_get($r, '/counts/5'), 3, 'point';
    is shared_call($r, '/counts', 'prefix', 9), 10, 'prefix via call';
    shared_set($r, '/counts/5', 100);
    is shared_get($r, '/counts/5'), 100, 'set';
};

subtest 'fenwick2d' => sub {
    my $r = Data::Shared->new;
    eval { $r->mount('grid', 'fenwick2d', undef, 24, 7) };
    if ($@) { plan skip_all => "backend unavailable: $@"; return }
    shared_set($r, '/grid/9/1', 100);
    is shared_get($r, '/grid/9/1'), 100, 'point 2d';
    shared_incr($r, '/grid/9/1', 12);
    is shared_get($r, '/grid/9/1'), 112, 'incr is update';
};

subtest 'segmenttree' => sub {
    my $r = Data::Shared->new;
    eval { $r->mount('arr', 'segmenttree', undef, 100) };
    if ($@) { plan skip_all => "backend unavailable: $@"; return }
    shared_set($r, '/arr/10', 42);
    is shared_get($r, '/arr/10'), 42, 'point via sum';
    shared_incr($r, '/arr/10', 5);
    is shared_get($r, '/arr/10'), 47, 'incr is add';
    is shared_call($r, '/arr', 'sum', 0, 99), 47, 'range sum via call';
};

subtest 'graph call driven' => sub {
    my $r = Data::Shared->new;
    eval { $r->mount('g', 'graph', undef, 100, 500) };
    if ($@) { plan skip_all => "backend unavailable: $@"; return }
    my $a = shared_call($r, '/g', 'add_node', 10);
    my $b = shared_call($r, '/g', 'add_node', 20);
    shared_call($r, '/g', 'add_edge', $a, $b, 5);
    is shared_get($r, "/g/$a"), 10, 'node_data via get';
    is shared_call($r, '/g', 'degree', $a), 1, 'degree via call';
    ok !eval { shared_set($r, '/g/0', 1); 1 }, 'graph set croaks honestly';
};

subtest 'kdtree call driven generic croaks' => sub {
    my $r = Data::Shared->new;
    eval { $r->mount('cities', 'kdtree', undef, 2, 1000) };
    if ($@) { plan skip_all => "backend unavailable: $@"; return }
    shared_call($r, '/cities', 'add', [10.5, 20.5], 42);
    my $near = shared_call($r, '/cities', 'nearest', [10.0, 20.0]);
    is $near->{id}, 42, 'nearest via call';
    ok !eval { shared_get($r, '/cities/0'); 1 }, 'kdtree get croaks';
};

done_testing;
