use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Data::Shared qw(shared_get shared_set shared_exists shared_call);

my $root = Data::Shared->new;
isa_ok $root, 'Data::Shared';

is shared_get($root, ''), $root, 'empty path returns root';
is shared_get($root, '/'), $root, 'slash returns root';
ok shared_exists($root, ''), 'root exists';
ok !eval { shared_set($root, '', 1); 1 }, 'cannot set root';
like $@, qr/cannot set the root/, 'set root error';

ok !eval { shared_get($root, '/nope/1'); 1 }, 'unknown mount croaks';
like $@, qr/no mount matches/, 'unknown mount error';

subtest 'nested mounts longest prefix' => sub {
    my $r = Data::Shared->new;
    plan skip_all => 'hashmap unavailable' unless eval { require Data::HashMap::Shared; 1 };
    $r->mount('cache', 'hashmap:ii', undef, 1000);
    my $h2 = $r->mount('cache/sessions', 'hashmap:ii', undef, 1000);
    shared_set($r, '/cache/1', 10);
    shared_set($r, '/cache/sessions/1', 99);
    is shared_get($r, '/cache/1'), 10, 'short mount';
    is shared_get($r, '/cache/sessions/1'), 99, 'longest prefix wins';
    is $r->handle('/cache/sessions'), $h2, 'handle exact mount';
    ok !eval { $r->handle('/cache/sessions/1'); 1 }, 'handle with extra components croaks';
    # Out of order on purpose: cache, cache/sessions alone is already sorted.
    $r->mount('alpha', 'hashmap:ii', undef, 16);
    is_deeply [$r->mounts], ['alpha', 'cache', 'cache/sessions'],
        'mounts listed sorted, not in insertion order';
    ok $r->unmount('alpha'), 'and the extra mount goes away again';
    my $info = $r->mount_info('cache');
    is $info->{key}, 'hashmap', 'mount_info key';
    is $info->{class}, 'Data::HashMap::Shared::II', 'mount_info class';
    ok $r->unmount('cache/sessions'), 'unmount';
    # Falls back to 'cache', which takes one key component.
    ok !eval { shared_get($r, '/cache/sessions/1'); 1 },
        'after unmount, the nested path no longer resolves';
    is_deeply [$r->mounts], ['cache'], 'only the short mount remains';
};

# The prefix walk starts at the deepest mount name; a bound too low stops a deep mount resolving.
subtest 'every depth of mount name resolves, and still does after unmount' => sub {
    my $r = Data::Shared->new;
    eval { $r->mount('a', 'hashmap:ii', undef, 64); 1 }
        or plan skip_all => "hashmap unavailable: $@";
    $r->mount('a/b/c', 'hashmap:ii', undef, 64);
    $r->mount('a/b', 'hashmap:ii', undef, 64);
    shared_set($r, '/a/1', 1);
    shared_set($r, '/a/b/1', 2);
    shared_set($r, '/a/b/c/1', 3);
    is shared_get($r, '/a/1'), 1, 'a one-component mount name';
    is shared_get($r, '/a/b/1'), 2, 'a two-component one';
    is shared_get($r, '/a/b/c/1'), 3, 'and the deepest one';
    ok $r->unmount('a/b/c'), 'the deepest mount goes away';
    is shared_get($r, '/a/b/1'), 2, 'the shallower nested mount still resolves';
    ok !eval { shared_get($r, '/a/b/c/1'); 1 },
        'and its own path falls back to a/b, which takes one key component';
    ok $r->unmount('a/b'), 'the last nested mount goes away';
    is shared_get($r, '/a/1'), 1, 'leaving the flat mount resolving on its own';
    # The answers above stay correct on the slower prefix walk, so assert the path taken.
    is $r->{_nest_depth}, 0, 'and back on the single-lookup path';
};

subtest 'duplicate mount croaks' => sub {
    my $r = Data::Shared->new;
    eval { $r->mount('x', 'hashmap:ii', undef, 10) };
    if ($@) { plan skip_all => "hashmap unavailable: $@"; return }
    ok !eval { $r->mount('x', 'hashmap:ii', undef, 10); 1 }, 'duplicate croaks';
    like $@, qr/already exists/, 'duplicate error';
};

subtest 'unmounting a name that is not there answers 0' => sub {
    my $r = Data::Shared->new;
    is $r->unmount('absent'), 0, 'documented: 0 when there was no mount';
    is $r->unmount('absent', unlink => 1), 0, 'and the same with unlink';
};

subtest 'unknown spec croaks' => sub {
    my $r = Data::Shared->new;
    ok !eval { $r->mount('x', 'nosuchthing', undef); 1 }, 'unknown spec croaks';
    like $@, qr/unknown mount spec/, 'unknown spec error';
    ok !eval { $r->mount('x', 'hashmap:nope', undef); 1 }, 'unknown variant croaks';
};

subtest 'mount by handle and factory are transient' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $r = Data::Shared->new($dir);
    my $h = eval { $r->mount('cache', 'hashmap:ii', undef, 100) };
    if ($@) { plan skip_all => "hashmap unavailable: $@"; return }
    is $r->mount_info('cache')->{transient}, 0, 'an ordinary mount reports transient 0';
    my $r2 = Data::Shared->new;
    $r2->mount('copy', $h);
    shared_set($r2, '/copy/1', 5);
    is shared_get($r2, '/copy/1'), 5, 'mounted handle works';
    ok $r2->mount_info('copy')->{transient}, 'handle mount is transient';

    my $r3 = Data::Shared->new;
    $r3->mount('made', sub { Data::HashMap::Shared::II->new(undef, 100) });
    shared_set($r3, '/made/2', 7);
    is shared_get($r3, '/made/2'), 7, 'factory mount works';
};

subtest ':keywords not provided' => sub {
    ok !eval { package KwTest; Data::Shared->import(':keywords'); 1 }, 'keywords croaks';
    like $@, qr/:keywords.*not available/, 'keywords error';
};

subtest 'unmount and mount_info canonicalize the name mount accepts' => sub {
    my $r = Data::Shared->new;
    plan skip_all => 'hashmap unavailable' unless eval { require Data::HashMap::Shared; 1 };
    $r->mount('/a/', 'hashmap:ii', undef, 16);
    is_deeply [$r->mounts], ['a'], 'mount installed the canonical name';
    ok $r->mount_info('/a/'), 'mount_info accepts the spelling mount took';
    is $r->mount_info('/a/')->{name}, 'a', 'and reports the canonical name';
    is $r->unmount('/a/'), 1, 'unmount accepts it too';
    is_deeply [$r->mounts], [], 'and the mount is gone';
};

done_testing;
