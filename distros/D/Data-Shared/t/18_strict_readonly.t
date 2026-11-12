use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Data::Shared qw(shared_compile sharedc_call);

eval { require Data::HashMap::Shared::SS; require Data::Queue::Shared::Int; 1 }
    or plan skip_all => "backends unavailable: $@";

subtest 'native readonly backend rejects writes through every entry point' => sub {
    my $root = Data::Shared->new(tempdir(CLEANUP => 1));
    $root->mount('map', 'hashmap:ss', undef, 32);
    $root->set('/map/key', 'saved');
    $root->freeze_all;
    my $ro = Data::Shared->open_readonly($root->dir, strict => 1);
    is $ro->get('/map/key'), 'saved', 'strict read works';
    ok !eval { $ro->call('/map', 'put', 'bad', 'value'); 1 }, 'native mutator rejected';
    like $@, qr/read-only|frozen/, 'by the read-only guard';
    ok !eval { sharedc_call($ro, shared_compile('/map'), 'put', 'bad', 'value'); 1 },
        'compiled native mutator rejected';
    like $@, qr/read-only|frozen/, 'by the same guard on the compiled tier';
    ok !eval { $ro->handle('/map')->put('bad', 'value'); 1 }, 'raw native handle rejects data writes';
    like $@, qr/read-only|frozen/, 'at the backend, which is sealed';
    ok !eval { $ro->call('/map', 'unlink'); 1 }, 'native lifecycle escape blocked';
    like $@, qr/read-only|frozen/, 'by the lifecycle guard';
    ok -f $root->dir . '/map.shm', 'file retained';
};

subtest 'unsupported backend refused and legacy fallback remains explicit' => sub {
    my $root = Data::Shared->new(tempdir(CLEANUP => 1));
    $root->mount('queue', 'queue:int', undef, 16);
    ok !eval { Data::Shared->open_readonly($root->dir, strict => 1); 1 }, 'strict open rejects queue';
    like $@, qr/strict read-only.*not supported/, 'capability error';
    my $compat = Data::Shared->open_readonly($root->dir);
    ok $compat->readonly, 'compatibility mode still available';
    $compat->call('/queue', 'push', 42);
    is $root->pop('/queue'), 42, 'compatibility mode retains backend permissions';
};

subtest 'immutable perfecthash is loaded without rebuilding' => sub {
    eval { require Data::PerfectHash::Shared; 1 } or plan skip_all => "perfecthash unavailable: $@";
    my $root = Data::Shared->new(tempdir(CLEANUP => 1));
    $root->mount('words', 'perfecthash', { build_str => [qw(apple banana)] });
    {
        no warnings qw(redefine once);
        local *Data::PerfectHash::Shared::build_str = sub { die "unexpected rebuild\n" };
        my $again = Data::Shared->open($root->dir);
        ok $again->exists('/words/apple'), 'writable root reopens immutable file';
        my $ro = Data::Shared->open_readonly($root->dir, strict => 1);
        ok $ro->exists('/words/banana'), 'immutable backend accepted in strict mode';
    }
};

subtest 'strict checks composite leaves before opening parent handles' => sub {
    my $root = Data::Shared->new(tempdir(CLEANUP => 1));
    $root->mount('users', ['hashmap:ss', 32, ['queue:int', 16]]);
    ok !eval { Data::Shared->open_readonly($root->dir, strict => 1); 1 }, 'unsupported child rejected eagerly';
    like $@, qr/strict read-only.*Queue/, 'child capability error precedes parent frozen check';
    like $@, qr/at mount 'users'/, 'and the mount it came from';
};

subtest 'backend minimum is checked before creating storage' => sub {
    my $root = Data::Shared->new(tempdir(CLEANUP => 1));
    local $Data::Shared::Registry::REGISTRY{hashmap}{min_version} = '999.0';
    ok !eval { $root->mount('old', 'hashmap:ss', undef, 32); 1 }, 'insufficient backend version rejected';
    like $@, qr/requires version 999/, 'version requirement explained';
    ok !-e $root->dir . '/old.shm', 'storage not created';
};

subtest 'strict composite reads reopen frozen children without writes' => sub {
    my $root = Data::Shared->new(tempdir(CLEANUP => 1));
    $root->mount('users', { spec => 'hashmap:ss', args => [32],
        child => { spec => 'hashmap:ss', args => [16] }, cache_size => 1 });
    $root->set("/users/$_/name", $_) for qw(a b);
    $root->freeze_all;
    my $ro = Data::Shared->open_readonly($root->dir, strict => 1);
    is $ro->get('/users/a/name'), 'a', 'first frozen child read';
    is $ro->get('/users/b/name'), 'b', 'second frozen child read';
    is $ro->get('/users/a/name'), 'a', 'evicted frozen child reopened';
    ok !eval { $ro->call('/users/a', 'put', 'bad', 'value'); 1 }, 'child native mutator rejected';
    ok !eval { $ro->call('/users/missing', 'size'); 1 }, 'native query cannot allocate a missing child';
    is_deeply [$ro->children('/users')], [qw(a b)], 'read-only namespace unchanged';
};

subtest 'missing sorted-set sidecar is not recreated' => sub {
    eval { require Data::SortedSet::Shared::Strings; 1 }
        or plan skip_all => "strings unavailable: $@";
    my $root = Data::Shared->new(tempdir(CLEANUP => 1));
    $root->mount('names', 'sortedset:strings', { max => 32 });
    $root->set('/names/alice', 42);
    my $keys = $root->dir . '/names__keys.shm';
    unlink $keys or die $!;
    ok !eval { Data::Shared->open($root->dir); 1 }, 'missing key table refused';
    like $@, qr/missing backing file.*names__keys/, 'sidecar path explained';
    ok !-e $keys, 'key table not recreated';
};

done_testing;
