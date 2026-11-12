use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Time::HiRes ();
use POSIX ();
use Cwd ();
use Data::Shared qw(shared_get shared_set shared_call shared_compile sharedc_call);

my $probe = Data::Shared->new(tempdir(CLEANUP => 1));
eval { $probe->mount('p', 'hashmap:ii', undef, 16); 1 }
    or plan skip_all => "hashmap backend unavailable: $@";

sub bytes_under {
    my ($dir) = @_;
    my $total = 0;
    my @queue = ($dir);
    while (my $d = shift @queue) {
        opendir my $h, $d or next;
        for my $e (readdir $h) {
            next if $e eq '.' || $e eq '..';
            my $p = "$d/$e";
            -d $p ? push @queue, $p : ($total += -s $p || 0);
        }
    }
    return $total;
}

subtest 'unlink_all removes storage an unmount retained' => sub {
    my $dir = tempdir(CLEANUP => 1);
    {
        my $root = Data::Shared->new($dir);
        $root->mount('cache', 'hashmap:ii', undef, 100);
        $root->mount('users', ['hashmap:ss', 100, ['hashmap:ii', 100]]);
        shared_set($root, '/cache/1', 111);
        shared_set($root, '/users/alice/1', 222);
        $root->unmount($_) for $root->mounts;
        cmp_ok bytes_under($dir), '>', 0, 'the storage is still there after unmounting';
        $root->unlink_all;
        is bytes_under($dir), 0, 'and unlink_all removes it';
    }
    my $fresh = Data::Shared->new($dir);
    $fresh->mount('cache', 'hashmap:ii', undef, 100);
    $fresh->mount('users', ['hashmap:ss', 100, ['hashmap:ii', 100]]);
    is shared_get($fresh, '/cache/1'), undef, 'a fresh store does not serve the old value';
    is_deeply [$fresh->children('/users')], [], 'nor the old children';
};

subtest 'unmount can remove the storage with it' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $root = Data::Shared->new($dir);
    $root->mount('cache', 'hashmap:ii', undef, 100);
    shared_set($root, '/cache/1', 7);
    ok -e "$dir/cache.shm", 'the backing file exists';
    is $root->unmount('cache', unlink => 1), 1, 'unmount with unlink reports success';
    ok !-e "$dir/cache.shm", 'and the storage is gone';
    ok !eval { $root->unmount('cache', bogus => 1); 1 }, 'an unknown option is refused';
    like $@, qr/unknown unmount option/, 'and named';
};

subtest 'a transient mount does not publish a revision' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $root = Data::Shared->new($dir);
    $root->mount('shared', 'hashmap:ii', undef, 100);
    my $revision = $root->{_revision};
    # Keeps the equality checks below from passing as undef against undef.
    ok defined $revision, 'the revision counter exists';
    my $before = do { open my $f, '<', "$dir/manifest.json" or die $!; local $/; <$f> };

    my $handle = Data::HashMap::Shared::II->new(undef, 16);
    $root->mount('scratch', $handle);
    is $root->{_revision}, $revision, 'the revision is unchanged';
    my $after = do { open my $f, '<', "$dir/manifest.json" or die $!; local $/; <$f> };
    is $after, $before, 'and the manifest is byte-identical';

    $root->unmount('scratch');
    is $root->{_revision}, $revision, 'unmounting it does not publish either';
    $root->mount('real', 'hashmap:ii', undef, 16);
    cmp_ok $root->{_revision}, '>', $revision, 'but a real mount still does';
};

subtest 'a composite remembers what its storage was created for' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $root = Data::Shared->new($dir);
    plan skip_all => 'bloomfilter backend unavailable'
        unless eval { $root->mount('users', ['hashmap:ss', 100, ['bloomfilter', 1000, 0.01]]); 1 };
    shared_set($root, '/users/alice/e1', 1);
    $root->unmount('users');
    ok !eval { $root->mount('users', ['hashmap:ss', 100, ['hashmap:ii', 100]]); 1 },
        'a different child type is refused';
    like $@, qr/storage was created for/, 'and says what it was created for';
    ok eval { $root->mount('users', ['hashmap:ss', 100, ['bloomfilter', 1000, 0.01]]); 1 },
        'the same chain still mounts' or diag $@;
    is shared_get($root, '/users/alice/e1'), 1, 'with its children intact';
};

subtest 'a native unlink answers the retirement, not the backend' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $root = Data::Shared->new($dir);
    plan skip_all => 'queue:int unavailable'
        unless eval { $root->mount('q', 'queue:int', undef, 16); 1 };
    # The queue's own unlink answers undef, so 1 can only come from the retirement.
    is shared_call($root, '/q', 'unlink'), 1, 'the facade reports one mount retired';
    ok !(grep { $_ eq 'q' } $root->mounts), 'and the mount is gone';
};

subtest 'a native unlink retires the mount with the storage' => sub {
    for my $tier (['string', sub { shared_call($_[0], '/cache', 'unlink') }],
                  ['compiled', sub { sharedc_call($_[0], shared_compile('/cache'), 'unlink') }]) {
        my ($label, $call) = @$tier;
        my $dir = tempdir(CLEANUP => 1);
        {
            my $root = Data::Shared->new($dir);
            $root->mount('cache', 'hashmap:ii', undef, 100);
            $root->mount('keep', 'hashmap:ii', undef, 16);
            shared_set($root, '/cache/1', 7);
            shared_set($root, '/keep/1', 9);
            $call->($root);
            ok !(grep { $_ eq 'cache' } $root->mounts), "$label: the mount is gone";
            ok((grep { $_ eq 'keep' } $root->mounts), "$label: the others stay");
        }
        my $reopened = eval { Data::Shared->open($dir) };
        ok $reopened, "$label: the store still opens" or diag $@;
        is eval { shared_get($reopened, '/keep/1') }, 9, "$label: and reads what is left"
            if $reopened;
    }
};

subtest 'another process reclaims what an unmount retained' => sub {
    my $dir = tempdir(CLEANUP => 1);
    {
        my $a = Data::Shared->new($dir);
        $a->mount('keep', 'hashmap:ii', undef, 16);
        $a->mount('cache', 'hashmap:ii', undef, 100);
        $a->mount('users', ['hashmap:ss', 100, ['hashmap:ii', 100]]);
        shared_set($a, '/cache/1', 111);
        shared_set($a, '/users/alice/1', 222);
        $a->unmount($_) for qw(cache users);
    }
    my $b = Data::Shared->open($dir);
    is_deeply [$b->mounts], ['keep'], 'the survivor is the only mount';
    ok $b->unlink_all, 'unlink_all succeeds';
    is bytes_under($dir), 0, 'and reclaims the storage the other process retained';
    ok !-d "$dir/.children", 'including the composite child directory';

    my $c = Data::Shared->new($dir);
    $c->mount('users', ['hashmap:ss', 100, ['hashmap:ii', 100]]);
    is shared_get($c, '/users/alice/1'), undef, 'a later mount does not resurrect it';
};

subtest 'a teardown through a stale root does not resurrect the store' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $first = Data::Shared->new($dir);
    $first->mount('cache', 'hashmap:ii', undef, 16);
    my $stale = Data::Shared->open($dir);
    $first->unlink_all;
    ok !-e "$dir/manifest.json", 'the first teardown took the manifest';
    is $stale->unlink_all, 0, 'the stale root finds nothing left to remove';
    ok !-e "$dir/manifest.json", 'and did not write one of its own';
    is_deeply [sort grep { $_ ne '.' && $_ ne '..' }
               do { opendir my $d, $dir or die $!; readdir $d }],
        ['.manifest.lock'], 'leaving only the lock, as a finished teardown does';
};

# A rebuild by the same steps reproduces topology and revision and may reuse
# the manifest's inode: only the store identity tells the two stores apart.
subtest 'a stale root cannot mistake a rebuilt store for its own' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $read = sub { open my $fh, '<', "$dir/manifest.json" or die $!; local $/; <$fh> };
    my $stale = Data::Shared->new($dir);
    $stale->mount('cache', 'hashmap:ss', undef, 16);
    $stale->unmount('cache');
    my ($first) = $read->() =~ /"store":"([0-9a-f]+)"/;
    ok defined $first, 'the manifest names its store';

    my $rebuilt = Data::Shared->open($dir);
    $rebuilt->unlink_all;
    $rebuilt = Data::Shared->new($dir);
    $rebuilt->mount('cache', 'hashmap:ss', undef, 16);
    shared_set($rebuilt, '/cache/k', 'replacement');
    $rebuilt->unmount('cache');
    my ($second) = $read->() =~ /"store":"([0-9a-f]+)"/;
    ok defined $second && $second ne $first, 'a rebuilt store is a different store';

    ok !eval { $stale->unlink_all; 1 }, 'so the stale root cannot tear it down';
    like $@, qr/this store was replaced/, 'and says why';
    ok -e "$dir/manifest.json", 'the rebuilt store is still there';
    my $again = Data::Shared->open($dir);
    $again->mount('cache', 'hashmap:ss', undef, 16);
    is shared_get($again, '/cache/k'), 'replacement', 'with its data';
};

# A copy of a whole store carries the nonce, revision and bytes, so only the
# manifest's inode tells a restored copy from the store a root wrote.
subtest 'a stale root cannot tear down a restored copy of its store' => sub {
    my $base = tempdir(CLEANUP => 1);
    my $dir = "$base/store";
    my $stale = Data::Shared->new($dir);
    $stale->mount('cache', 'hashmap:ss', undef, 16);
    shared_set($stale, '/cache/k', 'v');
    mkdir "$base/copy" or die $!;
    opendir my $dh, $dir or die $!;
    for my $f (grep { !/\A\.\.?\z/ } readdir $dh) {
        open my $in, '<:raw', "$dir/$f" or die $!;
        open my $out, '>:raw', "$base/copy/$f" or die $!;
        local $/; print {$out} <$in>; close $out or die $!;
    }
    rename $dir, "$base/old" or die $!;
    rename "$base/copy", $dir or die $!;
    ok !eval { $stale->unlink_all; 1 }, 'the stale root cannot tear down the restored copy';
    like $@, qr/this store was replaced/, 'and says why';
    ok -e "$dir/cache.shm", "the copy's storage survives";
};

subtest 'unlink_all counts what it removed, not what was retained' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $root = Data::Shared->new($dir);
    for my $i (1 .. 20) {
        $root->mount('s', 'hashmap:ii', undef, 16);
        shared_set($root, '/s/1', $i);
        $root->unmount('s');
    }
    is $root->unlink_all, 2, 'one backing file and the manifest';
    is bytes_under($dir), 0, 'and nothing is left on disk';

    # A string SortedSet keeps two files, where counting files and counting calls differ.
    SKIP: {
        my $two = tempdir(CLEANUP => 1);
        my $r = Data::Shared->new($two);
        skip 'sortedset:strings unavailable', 2
            unless eval { $r->mount('board', 'sortedset:strings', { max => 16 }); 1 };
        shared_set($r, '/board/alice', 1);
        is $r->unlink_all, 3, 'two backing files and the manifest';
        is bytes_under($two), 0, 'with nothing left on disk';
    }
};

subtest 'tearing down one root leaves the storage another root owns' => sub {
    my $dir_a = tempdir(CLEANUP => 1);
    my $owner = Data::Shared->new($dir_a);
    my $handle = $owner->mount('cache', 'hashmap:ss', undef, 16);
    shared_set($owner, '/cache/k', 'v');
    my $file = $owner->mount_info('cache')->{file};

    my $other = Data::Shared->new(tempdir(CLEANUP => 1));
    $other->mount('alias', $handle);
    is $other->mount_info('alias')->{transient}, 1, 'the alias is transient';
    is $other->unlink_all, 1, 'its teardown removes its own manifest and nothing else';
    ok -e $file, "and leaves the owner's storage";
    is shared_get($owner, '/cache/k'), 'v', 'the owner still reads it';
    ok eval { Data::Shared->open($dir_a); 1 }, 'and another process can still open it'
        or diag $@;

    # The facade recorded no storage for the alias, so unlink => 1 has nothing to reclaim.
    for my $how (['unmount', sub { $_[0]->unmount('alias', unlink => 1) }],
                 ['shared_call', sub { shared_call($_[0], '/alias', 'unlink') }]) {
        my ($label, $retire) = @$how;
        my $aliasing = Data::Shared->new(tempdir(CLEANUP => 1));
        $aliasing->mount('alias', $handle);
        ok eval { $retire->($aliasing); 1 }, "$label: retires the alias" or diag $@;
        is_deeply [$aliasing->mounts], [], "$label: and the mount is gone";
        ok -e $file, "$label: without taking the owner's storage";
    }
    is shared_get($owner, '/cache/k'), 'v', 'which the owner still reads';
};

subtest 'storage shared with another mount is not unlinked' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $root = Data::Shared->new($dir);
    my $handle = $root->mount('cache', 'hashmap:ss', undef, 100);
    shared_set($root, '/cache/k', 'v');
    $root->mount('alias', $handle);
    for my $how (['unmount', sub { $_[0]->unmount('alias', unlink => 1) }],
                 ['shared_call', sub { shared_call($_[0], '/alias', 'unlink') }]) {
        my ($label, $call) = @$how;
        ok !eval { $call->($root); 1 }, "$label: refused";
        like $@, qr/shares its storage with 'cache'/, "$label: and says with which mount";
    }
    ok -e "$dir/cache.shm", 'the owner still has its storage';
    ok $root->unmount('alias'), 'unmounting the alias without unlink is fine';
    undef $root; undef $handle;
    ok eval { Data::Shared->open($dir) }, 'and the store still opens' or diag $@;
};

subtest 'storage is removed while the topology lock is held' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $stamp = "$dir/removed-at";
    # The sibling is released as the removal begins, so its mount can only
    # follow the removal if the lock is held across it.
    pipe my $entered_r, my $entered_w or die "pipe: $!";
    # PERL_UNICODE puts :utf8 on a new handle, and syswrite refuses one.
    binmode $_, ':raw' for $entered_r, $entered_w;
    my $root = Data::Shared->new($dir);
    $root->mount('keep', 'hashmap:ii', undef, 16);
    $root->mount('scratch', 'hashmap:ii', undef, 16);
    my $native_unlink = \&Data::HashMap::Shared::II::unlink;
    no warnings 'redefine';
    local *Data::HashMap::Shared::II::unlink = sub {
        syswrite $entered_w, "removing\n";
        select undef, undef, undef, 0.6;        # a window, not a synchroniser
        open my $fh, '>', $stamp or die $!;
        print $fh Time::HiRes::time();
        close $fh or die $!;
        return $native_unlink->(@_);
    };

    my $pid = fork;
    plan skip_all => 'cannot fork' unless defined $pid;
    unless ($pid) {
        close $entered_w;
        my $go = <$entered_r>;
        POSIX::_exit(1) unless defined $go && $go =~ /removing/;
        my $other = eval { Data::Shared->open($dir) } or POSIX::_exit(2);
        eval { $other->mount('sibling', 'hashmap:ii', undef, 16); 1 } or POSIX::_exit(3);
        CORE::open(my $fh, '>', "$dir/locked-at") or POSIX::_exit(4);
        print $fh Time::HiRes::time();
        close $fh or POSIX::_exit(5);
        POSIX::_exit(0);
    }
    close $entered_r;
    $root->unmount('scratch', unlink => 1);
    waitpid $pid, 0;
    is $?, 0, 'the sibling opened the store and mounted, released by the removal';

    my $removed = -e $stamp ? do { open my $f, '<', $stamp; local $/; <$f> } : '';
    my $locked = -e "$dir/locked-at" ? do { open my $f, '<', "$dir/locked-at"; local $/; <$f> } : '';
    ok length $removed, 'the removal ran';
    ok length $locked, 'the sibling changed topology';
    cmp_ok $locked, '>', $removed, 'only after the storage was gone';
    my $after = Data::Shared->open($dir);
    ok((grep { $_ eq 'sibling' } $after->mounts), 'and its mount is in the published manifest');
};

subtest 'retained paths are recorded against the root, not the caller' => sub {
    my $base = tempdir(CLEANUP => 1);
    my $elsewhere = tempdir(CLEANUP => 1);
    my $start = Cwd::getcwd();
    chdir $base or die $!;
    {
        my $r = Data::Shared->new('state');
        $r->mount('users', ['hashmap:ss', 100, ['hashmap:ii', 100]]);
        shared_set($r, '/users/alice/1', 42);
        $r->unmount('users');
    }
    my $manifest = do { open my $fh, '<', "$base/state/manifest.json" or die $!; local $/; <$fh> };
    chdir $elsewhere or die $!;
    my ($entry) = $manifest =~ /"retained"\s*:\s*\[\s*"([^"]+)"/;
    ok defined $entry, 'the ledger records the retained storage';
    is $entry, '.children/users', 'the entry is relative to the root';
    ok -e "$base/state/$entry", 'and resolves there';
    my $n = eval { Data::Shared->open("$base/state")->unlink_all };
    my $err = $@;
    chdir $start or die $!;
    is $n, 2, 'unlink_all reclaims it from another directory' or diag $err;
    ok !-d "$base/state/.children/users", 'the composite directory is gone';
};

subtest 'a handle reopened onto the same storage is still shared' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $root = Data::Shared->new($dir);
    my $handle = $root->mount('cache', 'hashmap:ss', undef, 100);
    shared_set($root, '/cache/k', 'v');
    $root->mount('alias', $handle);
    $root->unmount('cache');
    $root->mount('cache', 'hashmap:ss', undef, 100);   # adopts, new handle object
    ok !eval { $root->unmount('alias', unlink => 1); 1 }, 'the stale alias cannot unlink it';
    like $@, qr/shares its storage with 'cache'/, 'and names the owner';
    ok -e "$dir/cache.shm", 'the owner keeps its storage';

    my $solo = Data::Shared->new(tempdir(CLEANUP => 1));
    $solo->mount('only', 'hashmap:ss', undef, 100);
    is $solo->unmount('only', unlink => 1), 1, 'a mount sharing nothing still unlinks';
};

subtest 'a failed retained cleanup can be retried from another root' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $hold = tempdir(CLEANUP => 1);
    my $root = Data::Shared->new($dir);
    $root->mount('ext', 'hashmap:ii', "$hold/ext.shm", 16);
    shared_set($root, '/ext/1', 5);
    $root->unmount('ext');
    chmod 0500, $hold or die $!;
    plan skip_all => 'running as a user that ignores directory permissions'
        if unlink "$hold/ext.shm";
    ok !eval { $root->unlink_all; 1 }, 'the blocked cleanup reports failure';
    like $@, qr/cannot clean|Permission denied/, 'naming what it could not remove';
    ok -e "$hold/ext.shm", 'and the storage survives';
    ok -e "$dir/manifest.json", 'as does the manifest that names it';
    chmod 0700, $hold or die $!;
    is(Data::Shared->open($dir)->unlink_all, 2, 'a fresh root removes it and the manifest');
    ok !-e "$hold/ext.shm", 'and the storage is gone';
};

# HashMap reports a failed removal by returning false, not by croaking, and a
# path that cannot even be stat'ed is not a path that is gone.
subtest 'a removal that did not happen keeps its storage on the ledger' => sub {
    for my $case (['unmount with unlink', 0500, sub { $_[0]->unmount('ext', unlink => 1) }],
                  ['teardown of an unreadable directory', 0000, sub { $_[0]->unmount('ext'); $_[0]->unlink_all }]) {
        my ($label, $mode, $retire) = @$case;
        my $dir = tempdir(CLEANUP => 1);
        my $hold = tempdir(CLEANUP => 1);
        my $root = Data::Shared->new($dir);
        $root->mount('ext', 'hashmap:ii', "$hold/ext.shm", 16);
        chmod $mode, $hold or die $!;
        if (opendir my $probe, $hold) {
            if ($mode == 0000 || unlink "$hold/ext.shm") {
                chmod 0700, $hold;
                plan skip_all => 'running as a user that ignores directory permissions';
            }
        }
        ok !eval { $retire->($root); 1 }, "$label: the blocked removal is reported";
        chmod 0700, $hold or die $!;
        ok -e "$hold/ext.shm", "$label: the storage survives";
        Data::Shared->open($dir)->unlink_all;
        ok !-e "$hold/ext.shm", "$label: and a fresh root reclaims it";
    }
};

subtest 'an archived root reclaims its own storage, not its successor' => sub {
    my $base = tempdir(CLEANUP => 1);
    my $live = "$base/state";
    {
        my $old = Data::Shared->new($live);
        $old->mount('cache', 'hashmap:ii', undef, 64);
        shared_set($old, '/cache/1', 1);
        $old->unmount('cache');
    }
    rename $live, "$base/state.old" or die "rename: $!";
    my $new = Data::Shared->new($live);
    $new->mount('cache', 'hashmap:ii', undef, 64);
    shared_set($new, '/cache/1', 42);

    Data::Shared->open("$base/state.old")->unlink_all;
    ok -e "$live/cache.shm", "the live root's storage is untouched";
    ok !-e "$base/state.old/cache.shm", "the archived root's own storage is gone";
    is shared_get($new, '/cache/1'), 42, 'the live root still reads';
    undef $new;
    ok eval { Data::Shared->open($live) }, 'and still opens' or diag $@;
};

subtest 'a mounted composite child handle cannot unlink its storage' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $root = Data::Shared->new($dir);
    $root->mount('users', ['hashmap:ss', 100, ['hashmap:ii', 100]]);
    shared_set($root, '/users/alice/1', 42);
    my $child = $root->handle('/users/alice');
    ok $child, 'the documented child handle';
    $root->mount('alias', $child);
    ok !eval { $root->unmount('alias', unlink => 1); 1 }, 'retiring it with unlink is refused';
    like $@, qr/shares its storage with 'users'/, 'naming the composite that owns it';
    ok $root->exists('/users/alice'), 'the child is still registered';
    undef $root; undef $child;
    my $re = Data::Shared->open($dir);
    is $re->get('/users/alice/1'), 42, 'and another process can still read it';
};

subtest 'a retained entry resolves against a wide-character root' => sub {
    my $base = tempdir(CLEANUP => 1);
    my $dir = "$base/\x{3b1}root";
    my $root = Data::Shared->new($dir);
    $root->mount('m', 'hashmap:ii', "$dir/\x{3b2}store.shm", 64);
    shared_set($root, '/m/1', 7);
    $root->unmount('m');
    is scalar(() = glob "$dir/*.shm"), 1, 'the retained file is on disk';
    # Named by no ledger, so only the directory sweep can reach it.
    my $stray = "$dir/\x{3b3}stray.shm";
    { my $h = Data::HashMap::Shared::II->new($stray, 16) }
    ok -f $stray, 'and an unpublished stray beside it';
    ok $root->unlink_all, 'unlink_all succeeds';
    is scalar(() = glob "$dir/*.shm"), 0, 'and the retained file is really gone';
    ok !-f $stray, 'and so is the stray';
    opendir my $dh, $dir or die $!;
    my @left = sort grep { $_ ne '.' && $_ ne '..' } readdir $dh;
    closedir $dh;
    is_deeply \@left, ['.manifest.lock'], 'leaving only the lock, as under an ASCII root';
};

subtest 'rotating mounts does not grow the root' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $root = Data::Shared->new($dir);
    for my $i (1 .. 50) {
        $root->mount("rot$i", 'hashmap:ii', undef, 16);
        $root->unmount("rot$i", unlink => 1);
    }
    is_deeply [$root->mounts], [], 'every rotation was retired';
    ok !exists $root->{_abs_cache} || !keys %{ $root->{_abs_cache} },
        'no resolved path is held after the operation that resolved it';
    ok -e "$dir/manifest.json", 'the manifest is still there';
    is bytes_under($dir), -s "$dir/manifest.json", 'only the manifest is left on disk';
};

subtest 'a teardown blocked part-way can be retried' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $root = Data::Shared->new($dir);
    $root->mount('users', ['hashmap:ss', 100, ['hashmap:ss', 100]]);
    shared_set($root, '/users/alice/k', 'v');
    $root->freeze_all;
    chmod 0500, "$dir/.children" or die $!;
    plan skip_all => 'running as a user that ignores directory permissions'
        if rmdir "$dir/.children/users";
    ok !eval { $root->unlink_all; 1 }, 'the blocked teardown reports failure';
    ok -d "$dir/.children/users", 'and leaves the directory it could not remove';
    chmod 0700, "$dir/.children" or die $!;
    ok $root->unlink_all, 'the retry completes';
    ok !-d "$dir/.children/users", 'the directory is gone';
    ok !-e "$dir/manifest.json", 'and so is the manifest';
};

# destroy marks the index 'x:' before it removes anything, so a teardown can
# meet a composite already tombstoned and must still finish it.
subtest 'teardown completes over an already tombstoned composite' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $root = Data::Shared->new($dir);
    $root->mount('u', ['hashmap:ss', 64, ['hashmap:ii', 16]]);
    shared_set($root, '/u/alice/1', 1);
    $root->{mounts}{u}{composite}{index}->put('x:', 1);
    ok $root->unlink_all, 'the teardown reports work done';
    ok !-d "$dir/.children/u", 'the composite directory is gone';
    ok !-e "$dir/manifest.json", 'and so is the manifest';
};

subtest 'teardown completes over a tombstoned nested composite it must reopen' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $root = Data::Shared->new($dir);
    $root->mount('t', ['hashmap:ss', 64, ['hashmap:ss', 64, ['hashmap:ii', 16]], { cache_size => 1 }]);
    shared_set($root, '/t/a/x/1', 1);
    shared_set($root, '/t/b/x/1', 1);
    my $comp = $root->{mounts}{t}{composite};
    my $id = $comp->_reg_id('a');
    ok !$comp->{cache}{$id}, 'the first nested composite was evicted';
    Data::HashMap::Shared::SS->new("$dir/.children/t/child-$id/index.shm", 64)->put('x:', 1);
    ok eval { $root->unlink_all; 1 }, 'the teardown completes' or diag $@;
    ok !-d "$dir/.children/t", 'and the whole subtree is gone';
};

subtest 'a teardown killed part-way is finished by another process' => sub {
    my $dir = tempdir(CLEANUP => 1);
    {
        my $root = Data::Shared->new($dir);
        $root->mount('a', 'hashmap:ii', undef, 64);
        $root->mount('b', 'hashmap:ii', undef, 64);
        shared_set($root, '/a/1', 1);
        shared_set($root, '/b/1', 1);
    }
    my $pid = fork;
    plan skip_all => 'cannot fork' unless defined $pid;
    unless ($pid) {
        my $root = Data::Shared->open($dir);
        my $seen = 0;
        no warnings 'redefine';
        my $orig = \&Data::HashMap::Shared::II::unlink;
        local *Data::HashMap::Shared::II::unlink = sub {
            kill 9, $$ if $seen++;
            return $orig->(@_);
        };
        eval { $root->unlink_all };
        POSIX::_exit(0);
    }
    waitpid $pid, 0;
    is $? & 127, 9, 'the worker died mid-teardown';
    ok !-e "$dir/a.shm", 'the first storage is gone';
    ok -e "$dir/b.shm", 'the second is still there';
    my $next = eval { Data::Shared->open($dir) };
    ok $next, 'and another process can still open the store' or diag $@;
    is_deeply [$next ? $next->mounts : ('did not open')], [],
        'which replays an empty topology';
    ok $next && $next->unlink_all, 'whose own teardown finishes the job';
    ok !-e "$dir/b.shm", 'the stranded storage is reclaimed';
    ok !-e "$dir/manifest.json", 'and the manifest is gone';
};

subtest 'a kill between the publish and the removal leaves the file reclaimable' => sub {
    my $dir = tempdir(CLEANUP => 1);
    # Outside the root, where the stray-file sweep would reclaim it without the ledger.
    my $hold = tempdir(CLEANUP => 1);
    {
        my $root = Data::Shared->new($dir);
        $root->mount('m1', 'hashmap:ss', "$hold/m1.shm", 128);
        shared_set($root, '/m1/secret', 'olddata');
    }
    my $pid = fork;
    plan skip_all => 'cannot fork' unless defined $pid;
    unless ($pid) {
        my $root = Data::Shared->open($dir);
        no warnings 'redefine';
        local *Data::Shared::_retire_storage = sub { kill 9, $$ };
        $root->unmount('m1', unlink => 1);
        POSIX::_exit(0);
    }
    waitpid $pid, 0;
    is $? & 127, 9, 'the worker died in the window';
    ok -e "$hold/m1.shm", 'its storage is still on disk';
    my $manifest = do { open my $fh, '<', "$dir/manifest.json" or die $!; local $/; <$fh> };
    unlike $manifest, qr/"m1"/, 'the manifest no longer names the mount';
    like $manifest, qr/"retained"\s*:\s*\[[^\]]*m1/, 'but the ledger names the storage';
    my $next = Data::Shared->open($dir);
    ok $next->unlink_all, 'so another process can reclaim it';
    ok !-e "$hold/m1.shm", 'and the storage is gone';
    my $again = Data::Shared->new($dir);       # unlink_all took the manifest too
    $again->mount('m1', 'hashmap:ss', "$hold/m1.shm", 128);
    is shared_get($again, '/m1/secret'), undef, 'and a remount starts empty';
};

subtest 'a completed removal leaves the published ledger' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $hold = tempdir(CLEANUP => 1);
    my $root = Data::Shared->new($dir);
    $root->mount('ext', 'hashmap:ii', "$hold/ext.shm", 16);
    shared_set($root, '/ext/1', 5);
    $root->unmount('ext', unlink => 1);
    ok !-e "$hold/ext.shm", 'the storage is gone';
    my $manifest = do { open my $fh, '<', "$dir/manifest.json" or die $!; local $/; <$fh> };
    unlike $manifest, qr/ext\.shm/, 'and the ledger no longer names the path';

    # Storage outside the root is recorded absolute, so a stale entry would name this file.
    open my $fh, '>', "$hold/ext.shm" or die $!;
    print $fh 'someone else' or die $!;
    close $fh or die $!;
    Data::Shared->open($dir)->unlink_all;
    ok -e "$hold/ext.shm", 'and another process leaves a foreign file there alone';
};

subtest 'teardown reclaims a backing file no manifest ever named' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $root = Data::Shared->new($dir);
    $root->mount('cache', 'hashmap:ii', undef, 64);
    shared_set($root, '/cache/7', 42);

    my $orphan = "$dir/scratch.shm";
    { my $h = Data::HashMap::Shared::II->new($orphan, 16) }
    ok -f $orphan, 'an unpublished backing file is on disk';
    is $root->mount_info('scratch'), undef, 'and no mount record names it';

    # What a publication killed between its temporary file and the rename leaves behind.
    my $temp = "$dir/.manifest-Aa0Bb1Cc";
    { open my $fh, '>', $temp or die $!; print $fh "{}\n" }
    ok -f $temp, 'and an abandoned publication temp is on disk';

    my $n = $root->unlink_all;
    ok !-f $orphan, 'teardown removes it too';
    ok !-f $temp, 'and the abandoned temp with it';
    cmp_ok $n, '>=', 3, 'and counts it among what it removed';
    opendir my $dh, $dir or die $!;
    my @left = sort grep { $_ ne '.' && $_ ne '..' } readdir $dh;
    closedir $dh;
    is_deeply \@left, ['.manifest.lock'], 'leaving only the lock, as documented';
};

done_testing;

