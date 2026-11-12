use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Data::Shared qw(shared_get shared_set shared_delete shared_exists shared_incr shared_call shareda_get shareda_set);

subtest 'hashmap II' => sub {
    my $r = Data::Shared->new;
    eval { $r->mount('cache', 'hashmap:ii', undef, 1000) };
    if ($@) { plan skip_all => "backend unavailable: $@"; return }
    shared_set($r, '/cache/42', 100);
    is shared_get($r, '/cache/42'), 100, 'get';
    ok shared_exists($r, '/cache/42'), 'exists true';
    is shared_exists($r, '/cache/99'), 0, 'exists false is 0';
    is shared_get($r, '/cache/99'), undef, 'missing is undef';
    shared_set($r, 'cache/42', 101);
    is shared_get($r, 'cache/42'), 101, 'leading slash optional';
    is shared_incr($r, '/cache/42'), 102, 'incr';
    is shared_incr($r, '/cache/42', 10), 112, 'incr_by via delta';
    shared_delete($r, '/cache/42');
    is shared_exists($r, '/cache/42'), 0, 'deleted';
    is shared_call($r, '/cache', 'size'), 0, 'call size';
};

subtest 'hashmap SS string keys with slash via array tier' => sub {
    my $r = Data::Shared->new;
    eval { $r->mount('m', 'hashmap:ss', undef, 1000) };
    if ($@) { plan skip_all => "backend unavailable: $@"; return }
    shareda_set($r, ['m', 'a/b'], 'v1');
    is shareda_get($r, ['m', 'a/b']), 'v1', 'slash key via array';
    is shared_get($r, '/m/a'), undef, 'string tier splits slash (documented)';
};

subtest 'buffer I64 via file-backed root' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $r = Data::Shared->new($dir);
    eval { $r->mount('counters', 'buffer:i64', undef, 100) };
    if ($@) { plan skip_all => "backend unavailable: $@"; return }
    shared_set($r, '/counters/0', 42);
    is shared_get($r, '/counters/0'), 42, 'buffer get';
    ok shared_exists($r, '/counters/0'), 'buffer exists in range';
    is shared_exists($r, '/counters/99999'), 0, 'buffer exists out of range';
    is shared_incr($r, '/counters/0'), 43, 'buffer incr';
};

subtest 'radixtree joined keys' => sub {
    my $r = Data::Shared->new;
    eval { $r->mount('routes', 'radixtree', undef, 4096, 65536) };
    if ($@) { plan skip_all => "backend unavailable: $@"; return }
    shared_set($r, '/routes/10.0.0.0/8', 100);
    is shared_get($r, '/routes/10.0.0.0/8'), 100, 'joined key get';
    ok shared_exists($r, '/routes/10.0.0.0/8'), 'exists';
    shared_set($r, '/routes/10.0', 200);
    is shared_call($r, '/routes', 'longest_prefix', '10.0.0.5'), 200, 'longest_prefix via call';
    shared_delete($r, '/routes/10.0.0.0/8');
    is shared_exists($r, '/routes/10.0.0.0/8'), 0, 'deleted';
};

subtest 'intern' => sub {
    my $r = Data::Shared->new;
    eval { $r->mount('ids', 'intern', undef, 1000, 65536) };
    if ($@) { plan skip_all => "backend unavailable: $@"; return }
    my $id = shared_set($r, '/ids/alice');
    is $id, 0, 'intern returns id 0';
    is shared_set($r, '/ids/alice'), 0, 'same string same id';
    is shared_get($r, '/ids/alice'), 0, 'get is id_of';
    ok shared_exists($r, '/ids/alice'), 'exists';
    is shared_exists($r, '/ids/carol'), 0, 'not exists';
    is shared_call($r, '/ids', 'string', 0), 'alice', 'string via call';
};

subtest 'pool I64' => sub {
    my $r = Data::Shared->new;
    eval { $r->mount('slots', 'pool:i64', undef, 100) };
    if ($@) { plan skip_all => "backend unavailable: $@"; return }
    my $idx = shared_call($r, '/slots', 'alloc');
    ok defined $idx, 'alloc';
    shared_set($r, "/slots/$idx", 42);
    is shared_get($r, "/slots/$idx"), 42, 'pool get';
    ok shared_exists($r, "/slots/$idx"), 'pool allocated exists';
    shared_delete($r, "/slots/$idx");
    is shared_exists($r, "/slots/$idx"), 0, 'pool freed';
};

done_testing;
