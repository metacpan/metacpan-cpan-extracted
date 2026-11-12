use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Path ();
use POSIX qw(_exit);
use Fcntl ();
use Time::HiRes ();
use Data::Shared qw(shared_compile sharedc_get);

eval { require Data::HashMap::Shared::SS; 1 }
    or plan skip_all => "composite backends unavailable: $@";

sub map_store {
    my (%opt) = @_;
    my $root = Data::Shared->new(tempdir(CLEANUP => 1));
    $root->mount('users', { spec => 'hashmap:ss', args => [128],
        child => { spec => 'hashmap:ss', args => [128] }, max_children => 16,
        cache_size => 2, %opt });
    return $root;
}

sub hold_lock {
    my ($path, $mode, $lock, $signal, $seconds) = @_;
    pipe my $held_r, my $held_w or die $!;
    # PERL_UNICODE puts :utf8 on a new handle, and syswrite refuses one.
    binmode $_, ':raw' for $held_r, $held_w;
    my $pid = fork;
    plan skip_all => 'cannot fork' unless defined $pid;
    unless ($pid) {
        close $held_r;
        my $fh;
        my $ok = CORE::open($fh, $mode, $path) && flock $fh, $lock;
        syswrite $held_w, $ok ? $signal : "failed\n";
        select undef, undef, undef, $seconds;
        POSIX::_exit($ok ? 0 : 1);
    }
    close $held_w;
    return ($pid, $held_r);
}

subtest 'constructor failure releases the child budget and partial files' => sub {
    my $root = map_store(max_children => 1);
    my $construct = \&Data::Shared::_construct;
    {
        no warnings 'redefine';
        local *Data::Shared::_construct = sub {
            my ($context, $resolved, $name, @args) = @_;
            my @result = $construct->(@_);
            die "injected child failure\n" if $name eq 'child';
            return @result;
        };
        ok !eval { $root->set('/users/broken/key', 'bad'); 1 }, 'construction failed';
        like $@, qr/injected child failure/, 'original exception';
    }
    is_deeply [$root->children('/users')], [], 'no phantom registration';
    is $root->call('/users', 'child_count'), 0, 'budget released';
    is_deeply [glob($root->dir . '/.children/users/child-*')], [], 'partial child directory removed';
    $root->set('/users/good/key', 'ok');
    is $root->get('/users/good/key'), 'ok', 'next child can use the budget';
    ok -d $root->dir . '/.children/users/child-1', 'failed child ID was not reused';
};

subtest 'failed readiness publication is rolled back' => sub {
    my $root = map_store(max_children => 1);
    my $put = Data::HashMap::Shared::SS->can('put');
    {
        no warnings qw(redefine once);
        local *Data::HashMap::Shared::SS::put = sub {
            return 0 if $_[1] eq 'c:broken';
            return $put->(@_);
        };
        ok !eval { $root->set('/users/broken/key', 'bad'); 1 }, 'metadata failure propagated';
        like $@, qr/composite registry|cannot (?:put|record)/,
            'from the registry write, not from somewhere else';
    }
    is_deeply [$root->children('/users')], [], 'address not published';
    is $root->call('/users', 'child_count'), 0, 'count restored';
    $root->set('/users/good/key', 'ok');
    is $root->get('/users/good/key'), 'ok', 'retry on another address works';
};

subtest 'score-only registration survives failed lazy construction' => sub {
    eval { require Data::SortedSet::Shared::Strings; 1 }
        or plan skip_all => "string sorted set unavailable: $@";
    my $root = Data::Shared->new(tempdir(CLEANUP => 1));
    $root->mount('users', { spec => 'sortedset:strings', args => [{ max => 32 }],
        child => { spec => 'hashmap:ss', args => [16] }, max_children => 1 });
    $root->set('/users/alice', 100);
    my $construct = \&Data::Shared::_construct;
    {
        no warnings 'redefine';
        local *Data::Shared::_construct = sub {
            die "injected leaf failure\n" if $_[2] eq 'child';
            return $construct->(@_);
        };
        ok !eval { $root->set('/users/alice/name', 'x'); 1 }, 'leaf constructor failed';
    }
    is $root->get('/users/alice'), 100, 'score preserved';
    is_deeply [$root->children('/users')], ['alice'], 'registered address preserved';
    is $root->call('/users', 'child_count'), 1, 'existing reservation count preserved';
    $root->set('/users/alice/name', 'ok');
    is $root->get('/users/alice/name'), 'ok', 'reserved child can be retried';
};

subtest 'child count does not enumerate all addresses during writes' => sub {
    my $root = map_store(max_children => 64);
    {
        no warnings 'redefine';
        local *Data::Shared::Composite::_count_addresses = sub { die "unexpected registry scan\n" };
        $root->set("/users/$_/name", $_) for 1 .. 20;
        is $root->call('/users', 'child_count'), 20, 'counter tracks creation';
        $root->delete('/users/10');
        is $root->call('/users', 'child_count'), 19, 'counter tracks deletion';
    }
};

subtest 'a clean read-only child count does not enumerate either' => sub {
    my $dir = tempdir(CLEANUP => 1);
    {
        my $root = Data::Shared->new($dir);
        $root->mount('users', { spec => 'hashmap:ss', args => [128],
            child => { spec => 'hashmap:ss', args => [128] }, max_children => 64 });
        $root->set("/users/$_/name", $_) for 1 .. 5;
        # A live hashmap composite cannot be opened read-only unfrozen.
        $root->freeze_all;
    }
    my $ro = Data::Shared->open_readonly($dir);
    no warnings 'redefine';
    local *Data::Shared::Composite::_count_addresses = sub { die "unexpected registry scan\n" };
    is $ro->call('/users', 'child_count'), 5, 'the count comes from the counter';
    is $ro->stats->{users}{children}, 5, 'and so does the one stats reports';
};

# Deleting a child with children of its own opens it; cached, that open would
# evict 'b' at the cost of a reopen only, which no value check can see.
subtest 'removing a cold child does not evict a warm one' => sub {
    my $root = Data::Shared->new(tempdir(CLEANUP => 1));
    $root->mount('users', { spec => 'hashmap:ss', args => [128],
        child => { spec => 'hashmap:ss', args => [128],
                   child => { spec => 'hashmap:ss', args => [64] } },
        max_children => 32, cache_size => 1 });
    $root->set('/users/a/x/name', 'a');
    $root->set('/users/b/x/name', 'b');
    is $root->stats->{users}{open}, 1, 'one child is cached, as cache_size says';
    $root->delete('/users/a');
    is $root->stats->{users}{open}, 1, 'and removing the cold one leaves it there';
    is_deeply [keys %{ $root->stats->{users}{child_stats} }], ['b'], 'the warm child, specifically';
};

subtest 'file cache evicts the least recently used child' => sub {
    my $root = map_store(cache_size => 2);
    $root->set("/users/$_/name", $_) for qw(a b);
    $root->get('/users/a/name');
    $root->set('/users/c/name', 'c');
    is_deeply [sort keys %{ $root->stats->{users}{child_stats} }], [qw(a c)], 'recently touched child retained';
    is $root->get('/users/b/name'), 'b', 'evicted child reopens';
    is_deeply [sort keys %{ $root->stats->{users}{child_stats} }], [qw(b c)], 'oldest child evicted on reopen';
};

subtest 'missing child storage is not regenerated on a cache miss' => sub {
    my $root = map_store(cache_size => 1);
    $root->set('/users/a/key', 'a');
    $root->set('/users/b/key', 'b');
    my $path = $root->dir . '/.children/users/child-0/child.shm';
    unlink $path or die $!;
    ok !eval { $root->get('/users/a/key'); 1 }, 'missing child fails';
    like $@, qr/missing backing file/, 'missing file error';
    ok !-e $path, 'child file not recreated';
};

subtest 'concurrent first writers publish one shared child' => sub {
    local $SIG{ALRM} = sub { die "concurrent writers timed out\n" };
    alarm 20;
    my $root = map_store();
    pipe my $ready_r, my $ready_w or die $!;
    pipe my $go_r, my $go_w or die $!;
    # PERL_UNICODE puts :utf8 on a new handle, and sysread and syswrite refuse one.
    binmode $_, ':raw' for $ready_r, $ready_w, $go_r, $go_w;
    my @pids;
    for my $i (1 .. 6) {
        my $pid = fork(); die $! unless defined $pid;
        if (!$pid) {
            $SIG{ALRM} = sub { _exit(124) }; alarm 15;
            close $ready_r; close $go_w;
            my $ok = eval {
                my $child = Data::Shared->open($root->dir);
                syswrite($ready_w, 'r') == 1 or die $!;
                sysread($go_r, my $go, 1) == 1 or die 'missing start signal';
                $child->set("/users/shared/key$i", "value$i");
                1;
            };
            warn $@ unless $ok;
            _exit($ok ? 0 : 1);
        }
        push @pids, $pid;
    }
    close $ready_w; close $go_r;
    my $ready = '';
    while (length $ready < 6) {
        sysread($ready_r, my $next, 6 - length $ready) > 0 or die 'worker exited before barrier';
        $ready .= $next;
    }
    syswrite($go_w, 'g' x 6) == 6 or die $!;
    close $go_w;
    for my $pid (@pids) { waitpid $pid, 0; is $?, 0, 'writer exited successfully' }
    is_deeply [$root->children('/users')], ['shared'], 'one address';
    is $root->call('/users', 'child_count'), 1, 'one budget slot';
    is_deeply [map { $root->get("/users/shared/key$_") } 1 .. 6],
        [map { "value$_" } 1 .. 6], 'every process wrote the same child instance';
    is_deeply [glob($root->dir . '/.children/users/child-*')], [$root->dir . '/.children/users/child-0'], 'one backing instance';
    alarm 0;
};

subtest 'another process deletes and recreates a compiled target' => sub {
    my $root = map_store();
    $root->set('/users/a/key', 'old');
    my $path = shared_compile('/users/a/key');
    is sharedc_get($root, $path), 'old', 'old target cached';
    my $old = $root->handle('/users/a');
    my $pid = fork(); die $! unless defined $pid;
    if (!$pid) {
        $SIG{ALRM} = sub { _exit(124) }; alarm 15;
        my $ok = eval {
            my $child = Data::Shared->open($root->dir);
            $child->delete('/users/a');
            $child->set('/users/a/key', 'new');
            1;
        };
        warn $@ unless $ok;
        _exit($ok ? 0 : 1);
    }
    waitpid $pid, 0;
    is $?, 0, 'delete/recreate succeeded';
    is sharedc_get($root, $path), 'new', 'compiled path resolves new generation';
    is $old->get('key'), 'old', 'explicit native handle retains old instance';
};

subtest 'deletion waits for in-progress construction' => sub {
    local $SIG{ALRM} = sub { die "construction/delete coordination timed out\n" };
    alarm 20;
    my $root = map_store();
    pipe my $ready_r, my $ready_w or die $!;
    pipe my $release_r, my $release_w or die $!;
    pipe my $deleted_r, my $deleted_w or die $!;
    binmode $_, ':raw' for $ready_r, $ready_w, $release_r, $release_w, $deleted_r, $deleted_w;
    my $construct = \&Data::Shared::_construct;
    my $creator = fork(); die $! unless defined $creator;
    if (!$creator) {
        $SIG{ALRM} = sub { _exit(124) }; alarm 15;
        close $ready_r; close $release_w; close $deleted_r; close $deleted_w;
        my $ok = eval {
            my $child = Data::Shared->open($root->dir);
            no warnings 'redefine';
            local *Data::Shared::_construct = sub {
                if ($_[2] eq 'child') {
                    syswrite($ready_w, 'r') == 1 or die $!;
                    sysread($release_r, my $signal, 1) == 1 or die 'missing release';
                }
                return $construct->(@_);
            };
            $child->set('/users/a/key', 'value');
            1;
        };
        warn $@ unless $ok;
        _exit($ok ? 0 : 1);
    }
    close $ready_w; close $release_r;
    sysread($ready_r, my $ready, 1) == 1 or die 'creator did not reach constructor';
    my $deleter = fork(); die $! unless defined $deleter;
    if (!$deleter) {
        $SIG{ALRM} = sub { _exit(124) }; alarm 15;
        close $ready_r; close $release_w; close $deleted_r;
        my $ok = eval {
            $root->delete('/users/a');
            syswrite($deleted_w, 'd') == 1 or die $!;
            1;
        };
        warn $@ unless $ok;
        _exit($ok ? 0 : 1);
    }
    close $deleted_w;
    my $readable = '';
    vec($readable, fileno($deleted_r), 1) = 1;
    # Long, since this asserts an absence: a deleter that ignored the lock must
    # certainly have finished within it.
    is select($readable, undef, undef, 2), 0,
        'deletion has not completed while constructor holds the lock';
    syswrite($release_w, 'g') == 1 or die $!;
    close $release_w;
    for my $pid ($creator, $deleter) { waitpid $pid, 0; is $?, 0, 'coordinated process succeeded' }
    is_deeply [$root->children('/users')], [], 'completed child was detached';
    is $root->call('/users', 'child_count'), 0, 'budget returned';
    alarm 0;
};

subtest 'interrupted creation releases the lock and repairs the live counter' => sub {
    local $SIG{ALRM} = sub { die "interrupted creator timed out\n" };
    alarm 20;
    my $root = map_store(max_children => 1);
    pipe my $ready_r, my $ready_w or die $!;
    pipe my $wait_r, my $wait_w or die $!;
    binmode $_, ':raw' for $ready_r, $ready_w, $wait_r, $wait_w;
    my $construct = \&Data::Shared::_construct;
    my $pid = fork(); die $! unless defined $pid;
    if (!$pid) {
        $SIG{ALRM} = sub { _exit(124) }; alarm 15;
        close $ready_r; close $wait_w;
        my $ok = eval {
            my $child = Data::Shared->open($root->dir);
            no warnings 'redefine';
            local *Data::Shared::_construct = sub {
                my @result = $construct->(@_);
                if ($_[2] eq 'child') {
                    syswrite($ready_w, 'r') == 1 or die $!;
                    sysread($wait_r, my $unused, 1);
                    die 'unexpected release';
                }
                return @result;
            };
            $child->set('/users/interrupted/key', 'never published');
            1;
        };
        _exit($ok ? 0 : 1);
    }
    close $ready_w; close $wait_r;
    sysread($ready_r, my $ready, 1) == 1 or die 'constructor not reached';
    kill 9, $pid or die $!;
    waitpid $pid, 0;
    is $? & 127, 9, 'creator terminated before publication';
    is $root->call('/users', 'child_count'), 0, 'pending counter repaired under the released lock';
    is_deeply [$root->children('/users')], [], 'unfinished child was not published';
    $root->set('/users/good/key', 'value');
    is $root->get('/users/good/key'), 'value', 'budget usable by another writer';
    ok -d $root->dir . '/.children/users/child-1', 'interrupted ID not reused';
    ok -d $root->dir . '/.children/users/child-0', 'unpublished directory retained for explicit recovery';
    alarm 0;
};

subtest 'missing composite index cannot silently discard the hierarchy' => sub {
    my $root = map_store();
    $root->set('/users/a/key', 'saved');
    my $index = $root->dir . '/.children/users/index.shm';
    unlink $index or die $!;
    ok !eval { Data::Shared->open($root->dir); 1 }, 'missing index refused';
    like $@, qr/missing backing file.*index\.shm/, 'index path explained';
    ok !-e $index, 'index not rebuilt empty';
};

# A rollback of a failed recreation leaves a marker naming another incarnation.
subtest 'a marker from another incarnation does not count as constructed' => sub {
    my $root = map_store();
    my $dir = $root->dir;
    $root->set('/users/a/key', 'saved');
    my $index = $root->{mounts}{users}{composite}{index};
    my $id = $index->get('a:a');
    ok defined $id, 'the address is registered';
    is $index->get('c:a'), "id:$id", 'and the marker names that registration';
    $index->put('c:a', 'id:' . ($id + 1));
    undef $root;

    # A fresh root has no cache to answer from, so every read goes through the marker.
    my $next = Data::Shared->open($dir);
    is $next->get('/users/a/key'), undef, 'a read does not reach the storage';
    ok $next->exists('/users/a'), 'the registration itself still stands';
    is_deeply [$next->children('/users')], ['a'], 'and the address is still listed';
    ok !eval { $next->set('/users/a/key', 'again'); 1 }, 'a write does not recreate it';
    like $@, qr/unpublished child storage exists at .*child-\Q$id\E/,
        'naming the directory to inspect';
    ok $next->unlink_all, 'and teardown reclaims it';
    ok !-d "$dir/.children/users/child-$id", 'the leftover directory is gone';
};

subtest 'a removed child directory is named, and only that child is lost' => sub {
    my $root = map_store();
    my $dir = $root->dir;
    $root->set("/users/$_/key", $_) for qw(a b);
    my $id = $root->{mounts}{users}{composite}{index}->get('a:a');
    undef $root;
    my $gone = "$dir/.children/users/child-$id";
    ok -d $gone, 'the child has its own directory';
    File::Path::remove_tree($gone);

    my $re = Data::Shared->open($dir);
    ok !eval { $re->get('/users/a/key'); 1 }, 'reading the child whose directory went is refused';
    like $@, qr/\AData::Shared: missing composite child directory '\Q$gone\E'/,
        'naming the directory, not a file the caller never saw';
    is $re->get('/users/b/key'), 'b', 'the other child still reads';
    is_deeply [sort $re->children('/users')], ['a', 'b'], 'and the registry still lists both';
};

subtest 'legacy readiness markers and counters remain readable' => sub {
    my $root = map_store();
    $root->set('/users/a/key', 'saved');
    my $index = $root->{mounts}{users}{composite}{index};
    $index->put('c:a', 1);
    $index->remove('s:');
    my $again = Data::Shared->open($root->dir);
    is $again->get('/users/a/key'), 'saved', 'legacy child marker accepted';
    is $again->call('/users', 'child_count'), 1, 'counter initialized from legacy records';
};

subtest 'nested deletion retires the shared instance before cleanup' => sub {
    my $root = Data::Shared->new(tempdir(CLEANUP => 1));
    $root->mount('users', { spec => 'hashmap:ss', args => [32], cache_size => 1,
        child => { spec => 'hashmap:ss', args => [32], child => ['hashmap:ss', 16] } });
    $root->set('/users/a/b/key', 'saved');
    my $old = $root->{mounts}{users}{composite}{cache}{0}{comp};
    my $old_index = $old->{index};
    $root->set('/users/c/d/key', 'other');
    $root->delete('/users/a');
    is $old_index->get('x:'), 1, 'old mappings see retirement after cache eviction';
    ok !-d $root->dir . '/.children/users/child-0', 'old directory removed';
    $root->set('/users/a/b/key', 'new');
    is $root->get('/users/a/b/key'), 'new', 'fresh nested instance remains usable';
};

subtest 'freeze through call at a composite is refused, not half-applied' => sub {
    my $root = map_store();
    $root->set('/users/a/key', 'saved');
    ok !eval { $root->node('/users')->call('freeze'); 1 }, 'call(freeze) at a composite croaks';
    like $@, qr/cannot freeze composite mount 'users' through call\(\)/, 'and says why';
    like $@, qr/freeze_all/, 'and points at the tool that does it';
    ok eval { $root->set('/users/b/key', 'new'); 1 }, 'a new child still works';
    ok eval { $root->delete('/users/a'); 1 }, 'and delete still works';
    is $root->freeze_all >= 1, 1, 'freeze_all is the way to seal it';
};

subtest 'frozen composite storage can be unlinked by its producer' => sub {
    my $root = map_store();
    $root->set('/users/a/key', 'saved');
    $root->freeze_all;
    ok $root->unlink_all >= 1, 'producer unlinked frozen root';
    ok !-e $root->dir . '/manifest.json', 'manifest removed';
    ok !-d $root->dir . '/.children/users', 'frozen composite directory removed';
};

# A store recreated at the same directory allocates child ids from zero again,
# so the stale root's child-0 path now names the new store's child.
subtest 'a stale composite cannot attach to a recreated store' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $spec = { spec => 'hashmap:ss', args => [100],
                 child => { spec => 'hashmap:ss', args => [100] }, cache_size => 1 };
    {
        my $maker = Data::Shared->new($dir);
        $maker->mount('users', $spec);
        $maker->set('/users/alice/k', 'alice-original');
        $maker->set('/users/carol/k', 'carol-original');
    }
    my $stale = Data::Shared->open($dir);
    is $stale->get('/users/alice/k'), 'alice-original', 'the worker reads the original store';
    is $stale->get('/users/carol/k'), 'carol-original', 'and evicts the first child';

    {
        my $coord = Data::Shared->open($dir);
        $coord->freeze_all;
        $coord->unlink_all;
        my $fresh = Data::Shared->new($dir);
        $fresh->mount('users', $spec);
        $fresh->set('/users/dave/k', 'dave-new-store');
    }

    ok !eval { $stale->get('/users/alice/k'); 1 }, 'the stale worker is refused, not served';
    like $@, qr/belongs to a newer instance/, 'and told why';
    ok !eval { $stale->set('/users/alice/k', 'from-stale'); 1 }, 'and cannot write either';

    my $check = Data::Shared->open($dir);
    is $check->get('/users/dave/k'), 'dave-new-store', "the new store's data is untouched";
    is_deeply [$check->children('/users')], ['dave'], 'and it has only its own child';
};

subtest 'a stale read-only composite cannot attach to a recreated store' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $spec = { spec => 'hashmap:ss', args => [100],
                 child => { spec => 'hashmap:ss', args => [100] }, cache_size => 1 };
    my $maker = Data::Shared->new($dir);
    $maker->mount('users', $spec);
    $maker->set('/users/alice/k', 'alice-original');
    $maker->set('/users/carol/k', 'carol-original');
    $maker->freeze_all;

    my $ro = Data::Shared->open_readonly($dir, strict => 1);
    is $ro->get('/users/alice/k'), 'alice-original', 'the shipped store reads';
    is $ro->get('/users/carol/k'), 'carol-original', 'and the first child is evicted';

    $maker->unlink_all;
    my $fresh = Data::Shared->new($dir);
    $fresh->mount('users', $spec);
    $fresh->set('/users/dave/k', 'dave-new-store');
    $fresh->freeze_all;

    ok !eval { $ro->get('/users/alice/k'); 1 }, 'the stale reader is refused';
    like $@, qr/belongs to a newer instance/, 'and told why';
    # Not inline: `is Data::Shared->...` parses as a method call on the class.
    my $fresh_reader = Data::Shared->open_readonly($dir);
    is $fresh_reader->get('/users/dave/k'), 'dave-new-store',
        'a fresh reader still sees the new store';
};

# A recreated store restarts its revision, so the stale root passes its revision check.
subtest 'a stale root cannot tear down its successor' => sub {
    my $base = tempdir(CLEANUP => 1);
    my $dir = "$base/store";
    my $spec = ['hashmap:ss', 100, ['hashmap:ss', 100]];
    my $stale = Data::Shared->new($dir);
    $stale->mount('users', $spec);
    $stale->set('/users/alice/k', 'original');

    Data::Shared->open($dir)->unlink_all;
    my $fresh = Data::Shared->new($dir);
    $fresh->mount('users', $spec);
    $fresh->set('/users/bob/k', 'replacement');

    # The sweep removes ledgered storage by pathname, past the composite's own
    # identity check, so only the store identity can refuse this.
    ok !eval { $stale->unmount('users'); 1 }, "the stale root cannot retire the mount";
    like $@, qr/was replaced/, 'because the store is not the one it published';
    ok !eval { $stale->unlink_all; 1 }, "the stale root's teardown is refused";
    like $@, qr/was replaced|belongs to a newer instance/, 'because the storage is not its own';
    ok -d "$dir/.children/users", "the replacement's children survive";
    undef $fresh;
    my $check = eval { Data::Shared->open($dir) };
    ok $check, 'the replacement still opens' or diag $@;
    is eval { $check->get('/users/bob/k') }, 'replacement', 'and its data is intact'
        if $check;
};

subtest 'teardown respects a read-only composite lock' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $root = Data::Shared->new($dir);
    $root->mount('users', ['hashmap:ss', 100, ['hashmap:ss', 100]]);
    $root->set('/users/alice/k', 'v');
    my $lockfile = "$dir/.children/users/.lock";
    chmod 0400, $lockfile or die $!;
    plan skip_all => 'running as root: a read-only lock is still writable'
        if $> == 0 || do { open my $w, '+<', $lockfile or 0 };

    my ($pid, $held_r) = hold_lock($lockfile, '<', Fcntl::LOCK_EX(), "held\n", 1.5);
    is scalar <$held_r>, "held\n", 'a worker holds the read-only lock';
    my $start = Time::HiRes::time();
    $root->unmount('users');
    $root->unlink_all;
    my $waited = Time::HiRes::time() - $start;
    waitpid $pid, 0;
    cmp_ok $waited, '>', 1, 'the teardown waited for it';
    ok !-d "$dir/.children/users", 'and then removed the directory';
};

subtest 'teardown waits for a nested composite lock' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $root = Data::Shared->new($dir);
    $root->mount('atlas', ['hashmap:ss', 64, ['hashmap:ss', 64, ['hashmap:ss', 64]]]);
    $root->set('/atlas/eu/paris/k', 'v');
    my ($nested) = glob "$dir/.children/atlas/child-*/.lock";
    ok $nested, 'the nested composite has its own lock' or return;

    my ($pid, $held_r) = hold_lock($nested, '+<', Fcntl::LOCK_EX(), "held\n", 1.5);
    is scalar <$held_r>, "held\n", 'a worker holds the nested lock';
    my $start = Time::HiRes::time();
    $root->unmount('atlas');
    $root->unlink_all;
    my $waited = Time::HiRes::time() - $start;
    waitpid $pid, 0;
    cmp_ok $waited, '>', 1, 'the teardown waited for the nested lock too';
    ok !-d "$dir/.children/atlas", 'and then removed the tree';
};

subtest 'tearing down a sealed store waits for a nested lock it never cached' => sub {
    my $dir = tempdir(CLEANUP => 1);
    {
        my $maker = Data::Shared->new($dir);
        $maker->mount('atlas', ['hashmap:ss', 64, ['hashmap:ss', 64, ['hashmap:ss', 64]]]);
        $maker->set('/atlas/eu/paris/k', 'v');
        ok $maker->freeze_all, 'the store seals' or return;
    }
    my ($nested) = glob "$dir/.children/atlas/child-*/.lock";
    ok $nested, 'the sealed store has a nested lock' or return;

    my ($pid, $held_r) = hold_lock($nested, '<', Fcntl::LOCK_EX(), "held\n", 1.5);
    is scalar <$held_r>, "held\n", 'a reader holds the nested lock';

    my $sealed = Data::Shared->open_sealed($dir);
    is scalar(keys %{ $sealed->{mounts}{atlas}{composite}{cache} }), 0,
        'and the teardown has nothing cached to walk';
    my $start = Time::HiRes::time();
    $sealed->unlink_all;
    my $waited = Time::HiRes::time() - $start;
    waitpid $pid, 0;
    cmp_ok $waited, '>', 1, 'the teardown waited for it anyway';
    ok !-d "$dir/.children/atlas", 'and then removed the tree';
};

subtest 'a read-only reader rechecks identity after waiting for the lock' => sub {
    my $dir = tempdir(CLEANUP => 1);
    {
        my $root = Data::Shared->new($dir);
        $root->mount('users', ['hashmap:ss', 64, ['hashmap:ss', 64]]);
        $root->set('/users/alice/k', 'original');
        # A read-only open needs the files sealed.
        ok $root->freeze_all, 'the store seals';
    }
    my $index = "$dir/.children/users/index.shm";
    my $lock = "$dir/.children/users/.lock";
    ok -e $index && -e $lock, 'the composite has an index and a lock' or return;
    # Renamed over the index to give the path a new inode, as a teardown and recreate would.
    my $replacement = "$dir/.children/users/index.new";
    { open my $in, '<', $index or die $!; open my $out, '>', $replacement or die $!;
      local $/; print {$out} <$in>; close $out or die $! }

    my $ro = Data::Shared->open_readonly($dir);
    pipe my $held_r, my $held_w or die $!;
    binmode $_, ':raw' for $held_r, $held_w;
    my $pid = fork;
    plan skip_all => 'cannot fork' unless defined $pid;
    unless ($pid) {
        close $held_r;
        my $fh;
        my $ok = CORE::open($fh, '+<', $lock) && flock $fh, Fcntl::LOCK_EX();
        syswrite $held_w, $ok ? "held\n" : "failed\n";
        # Once the reader has passed its check and parked on the shared lock.
        select undef, undef, undef, 1;
        my $renamed = rename $replacement, $index;
        syswrite $held_w, $renamed ? "replaced\n" : "failed\n";
        select undef, undef, undef, 0.3;
        POSIX::_exit($ok && $renamed ? 0 : 1);
    }
    close $held_w;
    is scalar <$held_r>, "held\n", 'a writer holds the composite lock';

    my $got = eval { $ro->get('/users/alice/k') };
    my $err = $@;
    is scalar <$held_r>, "replaced\n", 'the store was replaced during the wait';
    waitpid $pid, 0;
    ok !defined $got, 'the parked reader is not served from the replacement'
        or diag "got '$got'";
    like $err, qr/belongs to a newer instance/, 'it is told the storage is not its own';
};

subtest 'teardown waits for a shared holder, not only an exclusive one' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $root = Data::Shared->new($dir);
    $root->mount('users', ['hashmap:ss', 64, ['hashmap:ss', 64]]);
    $root->set('/users/alice/k', 'v');
    my $lockfile = "$dir/.children/users/.lock";

    my ($pid, $held_r) = hold_lock($lockfile, '<', Fcntl::LOCK_SH(), "shared\n", 1.5);
    is scalar <$held_r>, "shared\n", 'a reader holds it shared';
    my $start = Time::HiRes::time();
    $root->unmount('users');
    $root->unlink_all;
    my $waited = Time::HiRes::time() - $start;
    waitpid $pid, 0;
    is $?, 0, 'the reader held it for its whole hold';
    cmp_ok $waited, '>', 1, 'and the teardown waited for it';
};

subtest 'teardown waits for a composite lock it does not hold' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $root = Data::Shared->new($dir);
    $root->mount('users', ['hashmap:ss', 100, ['hashmap:ss', 100]]);
    $root->set('/users/alice/k', 'v');
    my $lockfile = "$dir/.children/users/.lock";
    ok -e $lockfile, 'the composite has its own lock';

    my ($pid, $held_r) = hold_lock($lockfile, '+<', Fcntl::LOCK_EX(), "held\n", 1.5);
    my $ack = <$held_r>;
    is $ack, "held\n", 'a worker holds it';

    my $start = Time::HiRes::time();
    $root->unmount('users');
    $root->unlink_all;
    my $waited = Time::HiRes::time() - $start;
    waitpid $pid, 0;
    is $?, 0, 'the worker kept the lock for its whole hold';
    cmp_ok $waited, '>', 1, 'the teardown waited for it rather than removing underneath';
    ok !-d "$dir/.children/users", 'and then removed the directory';
};

# A kill between delete_subtree's two index removals leaves the second behind:
# a registration is a state a retry can finish, an orphaned marker is not.
subtest 'the delete order leaves the crash state a retry can finish' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $root = Data::Shared->new($dir);
    $root->mount('u', ['hashmap:ss', 64, ['hashmap:ii', 16]]);
    $root->set('/u/alice/5', 1);
    my $comp = $root->{mounts}{u}{composite};
    my $id = $comp->{index}->get('a:alice');

    my @order;
    my $orig = \&Data::Shared::Composite::_index_remove;
    {
        no warnings 'redefine';
        local *Data::Shared::Composite::_index_remove = sub {
            push @order, $_[1] if $_[1] =~ /\A[ac]:/;
            return $orig->(@_);
        };
        $root->delete('/u/alice');
    }
    is_deeply \@order, ['c:alice', 'a:alice'],
        'the constructed marker goes before the registration';

    # Drop only the marker, as a kill between the two removals would.
    $root->set('/u/bob/5', 2);
    my $bid = $comp->{index}->get('a:bob');
    my $bdir = "$dir/.children/u/child-$bid";
    ok -d $bdir, 'the second child has its directory';
    $comp->{index}->remove('c:bob');
    undef $root;

    my $retry = Data::Shared->open($dir);
    ok $retry->delete('/u/bob'), 'a retry over the surviving registration completes';
    ok !-d $bdir, 'and the directory is gone';
};

done_testing;
