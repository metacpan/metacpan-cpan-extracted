use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestGit qw( require_git_c );
require_git_c();
use File::Temp qw( tempdir );
use File::Path qw( make_path );
use Cwd qw( abs_path );
use IPC::Open3 qw( open3 );
use Symbol qw( gensym );
use App::karr::Git;
use App::karr::Task;
use Git::Native::Repository;
use Git::Native::Error;

# Ticket #154: a pulled ref that could not be written locally was dropped in
# silence, and the tracking mirror was advanced as if it had been applied.
#
# The apply step used a bare, unretried reference_create whose 0 nobody looked
# at, so a ref whose .lock file was held -- by another karr mid-write, or left
# behind by one that was killed -- simply did not land. That alone would be a
# missed update. What made it data loss is the mirror: left claiming the remote
# OID was in place, the NEXT reconciliation read the stale local ref as
# L != T, R == T -- "unpushed local work: keep it" -- and the forced, pruning
# push wrote it over the remote's newer card, in every clone, at exit 0.
#
# So this file pins three things, and the loss two syncs later is the point of
# the third:
#
#   * the write is retried, on the same terms as every other ref write in the
#     class: losing the race for refs/<name>.lock is a write that has not been
#     attempted yet, not one that failed (#46)
#   * a ref that could not be applied fails the pull loudly and by name, which
#     is what stops the push -- pushing after a partial pull is the destructive
#     step
#   * the mirror never records an OID that was not applied, so once the lock
#     clears the next sync decides that ref again instead of force-pushing the
#     stale local version over the remote

sub two_clones {
    my $work = tempdir( CLEANUP => 1 );
    system( 'git', 'init', '-q', '--bare', "$work/origin.git" );
    my @git;
    for my $name (qw( a b )) {
        system("git clone -q '$work/origin.git' '$work/$name' 2>/dev/null");
        system( 'git', '-C', "$work/$name", 'config', 'user.email',
            "$name\@karr.test" );
        system( 'git', '-C', "$work/$name", 'config', 'user.name',
            "agent-$name" );
        push @git, App::karr::Git->new( dir => "$work/$name" );
    }
    return ( $work, @git );
}

sub task {
    my ( $id, $title, $body ) = @_;
    return App::karr::Task->new(
        id       => $id,
        title    => $title,
        status   => 'todo',
        priority => 'high',
        class    => 'standard',
        body     => $body // '',
    );
}

# The failure this is all about, reproduced without any timing: the lock file
# a killed karr leaves behind. libgit2 refuses to take refs/<name>.lock while
# it is there and reports GIT_ELOCKED, exactly as it does for a live writer.
sub stale_lock {
    my ( $dir, $ref ) = @_;
    my $path = "$dir/.git/$ref.lock";
    my ($parent) = $path =~ m{^(.*)/[^/]+$};
    make_path($parent);
    open my $fh, '>', $path or die "cannot create $path: $!";
    close $fh;
    return $path;
}

sub mirror_oid {
    my ( $git, $ref ) = @_;
    my $oids = $git->ref_oids('refs/karr-remote/origin/') || {};
    return $oids->{"refs/karr-remote/origin/$ref"};
}

sub warnings_from {
    my ($code) = @_;
    my @warned;
    local $SIG{__WARN__} = sub { push @warned, $_[0] };
    $code->();
    return \@warned;
}

# ---------------------------------------------------------------------
subtest 'a ref that cannot be written fails the pull and leaves the mirror alone'
    => sub {
    my ( $work, $a, $b ) = two_clones();

    $a->write_ref( 'refs/karr/config',       "board:\n  name: demo\n" );
    $a->write_ref( 'refs/karr/meta/next-id', "2\n" );
    $a->save_task_ref( task( 1, 'Original title', 'v1' ) );
    ok $a->push, 'A publishes the board';
    ok $b->pull, 'B syncs it in';
    is $b->load_task_ref(1)->title, 'Original title', 'B has the card';

    my $before = mirror_oid( $b, 'tasks/1/data' );
    ok $before, 'and a mirror entry for it';

    my $edited = $a->load_task_ref(1);
    $edited->title('IMPORTANT EDIT FROM A');
    $a->save_task_ref($edited);
    ok $a->push, 'A publishes an edit';

    my $lock = stale_lock( "$work/b", 'refs/karr/tasks/1/data' );

    my $rv  = eval { $b->pull };
    my $err = $@;
    ok !$rv, 'the pull does not report success';
    like $err, qr/could not apply the remote's version/,
        'it fails loudly instead of skipping the ref';
    like $err, qr{refs/karr/tasks/1/data}, 'and names the ref it could not apply';

    is $b->load_task_ref(1)->title, 'Original title',
        "B's local card is untouched -- the write really did not land";
    is mirror_oid( $b, 'tasks/1/data' ), $before,
        'the mirror still holds the pre-fetch OID, not the one that was not applied';

    # The loss used to happen here, two syncs later and with the lock long
    # gone: the mirror said B had already seen A's edit, so B's stale card read
    # as unpushed work worth keeping and the forced push put it back on origin.
    unlink $lock;
    ok $b->pull, 'the next pull, with the lock cleared, goes through';
    is $b->load_task_ref(1)->title, 'IMPORTANT EDIT FROM A',
        "and applies A's edit";
    ok $b->push, 'B pushes afterwards';

    ok $a->pull, 'A pulls back';
    is $a->load_task_ref(1)->title, 'IMPORTANT EDIT FROM A',
        "A's edit survived B's sync round trip";
};

# ---------------------------------------------------------------------
subtest 'a remote deletion that cannot be applied is not swallowed either' => sub {
    my ( $work, $a, $b ) = two_clones();

    $a->write_ref( 'refs/karr/config',       "board:\n  name: demo\n" );
    $a->write_ref( 'refs/karr/meta/next-id', "3\n" );
    $a->save_task_ref( task( $_, "Task $_" ) ) for 1 .. 2;
    ok $a->push, 'A publishes two tasks';
    ok $b->pull, 'B syncs them in';

    my $before = mirror_oid( $b, 'tasks/2/data' );
    ok $a->delete_ref('refs/karr/tasks/2/data'), 'A deletes task 2';
    ok $a->push, 'and pushes the deletion';

    my $lock = stale_lock( "$work/b", 'refs/karr/tasks/2/data' );

    my $rv  = eval { $b->pull };
    my $err = $@;
    ok !$rv, 'the pull does not report success';
    like $err, qr{refs/karr/tasks/2/data}, 'and names the ref';
    ok $b->ref_exists('refs/karr/tasks/2/data'), 'the local ref is still there';
    is mirror_oid( $b, 'tasks/2/data' ), $before,
        'and the mirror has not been pruned for a deletion that did not land';

    # Without the rollback the next pull reads the surviving local ref as
    # unpushed work and the push resurrects the task on origin (#49 again).
    unlink $lock;
    ok $b->pull, 'the next pull goes through';
    ok !$b->ref_exists('refs/karr/tasks/2/data'), 'and the deletion is applied';
    ok $b->push, 'B pushes afterwards';

    my @origin = `git -C '$work/origin.git' for-each-ref --format='%(refname)' 'refs/karr/tasks/'`;
    chomp @origin;
    is_deeply [ sort @origin ], ['refs/karr/tasks/1/data'],
        'the deleted task is not resurrected on origin';
};

# ---------------------------------------------------------------------
subtest 'a conflict whose local side cannot be parked keeps the local ref' => sub {
    my ( $work, $a, $b ) = two_clones();

    $a->write_ref( 'refs/karr/config',       "board:\n  name: demo\n" );
    $a->write_ref( 'refs/karr/meta/next-id', "2\n" );
    $a->save_task_ref( task( 1, 'Shared', 'v1' ) );
    ok $a->push, 'A publishes the board';
    ok $b->pull, 'B syncs it in';

    my $mine = $b->load_task_ref(1);
    $mine->body('v2 from B');
    $b->save_task_ref($mine);          # local only: never pushed

    my $theirs = $a->load_task_ref(1);
    $theirs->body('v2 from A');
    $a->save_task_ref($theirs);
    ok $a->push, 'A publishes its own version';

    my $before = mirror_oid( $b, 'tasks/1/data' );
    my $lock = stale_lock( "$work/b", 'refs/karr-conflict/origin/tasks/1/data' );

    my $rv  = eval { $b->pull };
    my $err = $@;
    ok !$rv, 'the pull does not report success';
    like $err, qr{refs/karr/tasks/1/data}, 'and names the board ref';
    is $b->load_task_ref(1)->body, 'v2 from B',
        "B's version is kept rather than replaced with nothing to point at";
    ok !$b->ref_exists('refs/karr-conflict/origin/tasks/1/data'),
        'nothing was parked';
    is mirror_oid( $b, 'tasks/1/data' ), $before,
        'and the mirror was rolled back for the conflicted ref';

    unlink $lock;
    my $warned = warnings_from( sub { $rv = $b->pull } );
    ok $rv, 'the next pull goes through';
    like join( '', @$warned ), qr/both changed/, 'and reports the conflict';
    is $b->load_task_ref(1)->body, 'v2 from A', "the remote's version is in place";
    ok $b->ref_exists('refs/karr-conflict/origin/tasks/1/data'),
        "and B's version is parked where the warning says it is";
};

# ---------------------------------------------------------------------
# The same defect one ref over, in the identity guard's migration branch (#95):
# a remote that still is this board but has lost its stamp gets the mirror slot
# pointed back at the local one, so reconciliation does not read the missing
# ref as "the remote deleted the id". Unchecked, that write failing stripped
# the stamp from this clone too.
subtest 'a mirror stamp that cannot be written stops the pull' => sub {
    my ( $work, $a, $b ) = two_clones();

    # A board from before identities existed: no meta/board-id anywhere.
    $a->write_ref( 'refs/karr/config',       "board:\n  name: demo\n" );
    $a->write_ref( 'refs/karr/meta/next-id', "2\n" );
    $a->save_task_ref( task( 1, 'Shared' ) );
    ok $a->push, 'A publishes an unstamped board';
    ok $b->pull, 'B syncs it in';

    my $stamp = $b->read_board_id_ref;
    ok $stamp, 'B stamped the board on the way in';

    # The remote still has no stamp, so B's next pull takes the migration
    # branch -- with the mirror slot for it locked.
    my $lock = stale_lock( "$work/b", 'refs/karr-remote/origin/meta/board-id' );
    my $rv  = eval { $b->pull };
    my $err = $@;
    ok !$rv, 'the pull does not report success';
    like $err, qr/could not update the tracking mirror/, 'and says what failed';
    is $b->read_board_id_ref, $stamp,
        "the board's identity stamp is still here";

    unlink $lock;
    ok $b->pull, 'the next pull goes through';
    is $b->read_board_id_ref, $stamp, 'and the stamp is still the same one';
};

# ---------------------------------------------------------------------
# The retry half (#46). A lock held for a moment by a live karr is not a failed
# write, it is a write that has not been attempted yet -- and before this
# ticket the reconciliation apply step was the one ref write in the class that
# did not retry at all, so a single microsecond-wide collision was enough to
# drop the update.
subtest 'a lock that clears is retried, not reported' => sub {
    my ( $work, $a, $b ) = two_clones();

    $a->write_ref( 'refs/karr/config',       "board:\n  name: demo\n" );
    $a->write_ref( 'refs/karr/meta/next-id', "2\n" );
    $a->save_task_ref( task( 1, 'Original title' ) );
    ok $a->push, 'A publishes the board';
    ok $b->pull, 'B syncs it in';

    my $edited = $a->load_task_ref(1);
    $edited->title('IMPORTANT EDIT FROM A');
    $a->save_task_ref($edited);
    ok $a->push, 'A publishes an edit';

    # Exactly what a live writer holding the lock looks like from here, and it
    # lets go after three attempts.
    my $target   = 'refs/karr/tasks/1/data';
    my $attempts = 0;
    my $rv;
    {
        my $real = \&Git::Native::Repository::reference_create;
        no warnings 'redefine';
        local *Git::Native::Repository::reference_create = sub {
            my ( $repo, $ref, @rest ) = @_;
            if ( $ref eq $target ) {
                $attempts++;
                die Git::Native::Error->new(
                    code    => -14,          # GIT_ELOCKED
                    message => "failed to lock file '$ref.lock' for writing",
                ) if $attempts <= 3;
            }
            return $real->( $repo, $ref, @rest );
        };
        $rv = eval { $b->pull };
    }

    ok $rv, 'the pull succeeds';
    is $@, '', 'without an exception';
    cmp_ok $attempts, '>', 3, 'the contended write was retried, not given up on';
    is $b->load_task_ref(1)->title, 'IMPORTANT EDIT FROM A',
        "and A's edit landed once the lock cleared";
};

# ---------------------------------------------------------------------
# End to end through the CLI, which is where the cost was: `karr sync` reported
# "Done." at exit 0 while origin lost the card. The control -- the identical
# script without the lock file -- is the second half of the subtest, because
# the fix is only a fix if the ordinary path still converges.
subtest 'end to end: karr sync stops instead of pushing over the remote' => sub {
    my $root = abs_path('.');
    my $bin  = "$root/bin/karr";

    my $run = sub {
        my ( $work, $clone, @argv ) = @_;
        my $err = gensym;
        my $pid = open3( my $in, my $out, $err,
            $^X, "-I$root/lib", $bin, '--dir', "$work/$clone", @argv );
        close $in;
        my $stdout = do { local $/; <$out> };
        my $stderr = do { local $/; <$err> };
        waitpid $pid, 0;
        return {
            exit   => $? >> 8,
            stdout => defined $stdout ? $stdout : '',
            stderr => defined $stderr ? $stderr : '',
        };
    };

    my $origin_title = sub {
        my ($work) = @_;
        my $blob = `git -C '$work/origin.git' show refs/karr/tasks/1/data:data 2>/dev/null`;
        my ($title) = $blob =~ /^title:\s*(.*)$/m;
        return $title // '';
    };

    for my $mode (qw( locked control )) {
        my ( $work ) = two_clones();

        is $run->( $work, 'a', 'init', '--name', 'demo' )->{exit}, 0,
            "$mode: A creates the board";
        is $run->( $work, 'a', 'create', 'Original title' )->{exit}, 0,
            "$mode: A creates a task";
        is $run->( $work, 'a', 'sync' )->{exit}, 0, "$mode: A syncs";
        is $run->( $work, 'b', 'sync' )->{exit}, 0, "$mode: B syncs";

        is $run->( $work, 'a', 'edit', '1', '--title', 'IMPORTANT EDIT FROM A' )
            ->{exit}, 0, "$mode: A edits the card";
        is $run->( $work, 'a', 'sync' )->{exit}, 0, "$mode: A syncs the edit out";
        is $origin_title->($work), 'IMPORTANT EDIT FROM A',
            "$mode: origin carries the edit";

        my $lock = $mode eq 'locked'
            ? stale_lock( "$work/b", 'refs/karr/tasks/1/data' )
            : undef;

        my $sync = $run->( $work, 'b', 'sync' );
        if ($lock) {
            isnt $sync->{exit}, 0, "$mode: B's sync fails instead of saying Done.";
            like $sync->{stderr}, qr/could not apply the remote's version/,
                "$mode: and says which ref it could not apply";
            like $sync->{stderr}, qr{refs/karr/tasks/1/data}, "$mode: by name";
            unlink $lock;
        }
        else {
            is $sync->{exit}, 0, "$mode: B's sync succeeds";
        }

        is $origin_title->($work), 'IMPORTANT EDIT FROM A',
            "$mode: origin still carries the edit";

        # And the sync after it -- the one that used to force-push the stale
        # card -- converges instead.
        is $run->( $work, 'b', 'sync' )->{exit}, 0, "$mode: B's next sync succeeds";
        like $run->( $work, 'b', 'list', '--compact' )->{stdout},
            qr/IMPORTANT EDIT FROM A/, "$mode: B has the edit";
        is $origin_title->($work), 'IMPORTANT EDIT FROM A',
            "$mode: and origin still has it";
    }
};

done_testing;
