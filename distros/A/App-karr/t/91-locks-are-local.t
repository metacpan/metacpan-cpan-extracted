use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestGit qw( require_git_c );
require_git_c();
use File::Temp qw( tempdir );
use App::karr::Git;
use App::karr::Lock;
use App::karr::Task;
use App::karr::BoardStore;
use App::karr::Cmd::Unlock;

# Ticket #93: task locks lived at refs/karr/tasks/N/lock -- inside the namespace
# karr pushes.
#
# A lock means "this process, in this clone, is mid-pick right now". It says
# nothing a second clone can act on: it cannot tell whether the holder is still
# alive, and has no way to find out. But any sync that fired while one was held
# published it, the next clone to pull inherited it, and it then blocked that
# clone's picks until somebody ran `karr unlock`. Board backups snapshotted it
# too.
#
# The fix is not better release timing -- it is that no refspec can reach the
# refs at all: they live under refs/karr-local/ now.
#
# What must NOT change with them: refs/karr/log/* (the activity log) and every
# other board ref are board state and must keep syncing. Only the locks are
# process-local.

sub task {
    my ( $id, $title ) = @_;
    return App::karr::Task->new(
        id => $id, title => $title, status => 'todo',
        priority => 'high', class => 'standard', body => '',
    );
}

# A bare origin plus two clones of it, each with a board identity.
sub two_clones {
    my $work = tempdir( CLEANUP => 1 );
    system( 'git', 'init', '-q', '--bare', "$work/origin.git" );
    for my $name (qw( a b )) {
        system("git clone -q '$work/origin.git' '$work/$name' 2>/dev/null");
        system( 'git', '-C', "$work/$name", 'config', 'user.email', "$name\@karr.test" );
        system( 'git', '-C', "$work/$name", 'config', 'user.name',  "agent-$name" );
    }

    my $a = App::karr::Git->new( dir => "$work/a" );
    $a->write_ref( 'refs/karr/config', "board:\n  name: demo\n" );
    $a->write_ref( 'refs/karr/log/user/a%40karr.test', "{}\n" );
    $a->save_task_ref( task( 1, 'One' ) );
    return ( $work, $a, App::karr::Git->new( dir => "$work/b" ) );
}

sub run_execute {
    my ( $cmd, @args ) = @_;
    my $out = '';
    my $err = do {
        local $@;
        eval {
            local *STDOUT;
            open STDOUT, '>', \$out or die $!;
            $cmd->execute( \@args, [] );
        };
        $@;
    };
    return ( $err, $out );
}

sub origin_refs {
    my ($work) = @_;
    my @refs =
      `git -C '$work/origin.git' for-each-ref --format='%(refname)' 'refs/'`;
    chomp @refs;
    return [ sort @refs ];
}

subtest 'a lock ref is not in the board namespace at all' => sub {
    my $lock = App::karr::Lock->new( dir => '.' );
    is $lock->ref_name(12), 'refs/karr-local/tasks/12/lock',
        'locks live under refs/karr-local/';
    unlike $lock->ref_name(12), qr{\Arefs/karr/},
        'and nothing that starts with refs/karr/ can match them';
};

subtest 'a sync while a lock is held does not publish it' => sub {
    my ( $work, $a ) = two_clones();

    my ( $ok, $msg ) = App::karr::Lock->new( git => $a )->acquire( 1, 'a@karr.test' );
    ok $ok, "the lock is taken ($msg)";

    # The push happens with the lock still held -- the exact situation the old
    # layout could not survive.
    ok $a->push, 'the board pushes';

    my $refs = origin_refs($work);
    ok !( grep { m{/lock\z} } @$refs ), 'no lock reached the remote'
        or diag "remote has: @$refs";

    # ...and everything that IS board state still did.
    is_deeply $refs,
        [ 'refs/karr/config', 'refs/karr/log/user/a%40karr.test',
          'refs/karr/tasks/1/data' ],
        'the config, the activity log and the task all still sync';
};

subtest 'a second clone never inherits a lock, and can pick the same task' => sub {
    my ( $work, $a, $b ) = two_clones();

    App::karr::Lock->new( git => $a )->acquire( 1, 'a@karr.test' );
    ok $a->push, 'clone a pushes while holding the lock';
    ok $b->pull, 'clone b pulls';

    ok !( grep { m{/lock\z} } $b->list_refs('refs/karr/') ),
        'clone b did not inherit a lock through the board namespace';
    ok !( grep { m{/lock\z} } $b->list_refs('refs/karr-local/') ),
        'nor through any other namespace';

    my ( $ok, $msg ) = App::karr::Lock->new( git => $b )->acquire( 1, 'b@karr.test' );
    ok $ok, "clone b is free to take its own lock ($msg)";
};

subtest 'a held lock survives a pull that prunes the board' => sub {
    my ( $work, $a, $b ) = two_clones();
    ok $a->push, 'the board is on the remote';
    ok $b->pull, 'clone b has it';

    my $lock = App::karr::Lock->new( git => $b );
    ok +( $lock->acquire( 1, 'b@karr.test' ) )[0], 'clone b locks task 1';

    # Clone a deletes the task and publishes that; b's pull prunes it. The lock
    # b is holding right now must not be pruned along with the board refs -- and
    # cannot be, because the prune never sees that namespace.
    $a->delete_ref('refs/karr/tasks/1/data');
    ok $a->push, 'the deletion is published';
    ok $b->pull, 'clone b reconciles';

    ok !$b->ref_exists('refs/karr/tasks/1/data'), 'the task really was pruned';
    is $lock->get(1), 'b@karr.test',
        'the lock this process is holding is still held';
};

subtest 'a board backup carries no locks' => sub {
    my ( $work, $a ) = two_clones();
    App::karr::Lock->new( git => $a )->acquire( 1, 'a@karr.test' );

    # What Cmd::Backup snapshots: BoardStore::all_refs, i.e. refs/karr/*.
    my @snapshot = $a->list_refs('refs/karr/');
    ok !( grep { m{/lock\z} } @snapshot ),
        'somebody\'s momentary lock is not part of the board snapshot'
        or diag "snapshot: @snapshot";
    ok scalar( grep { m{\Arefs/karr/tasks/1/data\z} } @snapshot ),
        'while the task itself is';
};

subtest 'set-refs cannot be used to publish a lock either' => sub {
    my ( $work, $a ) = two_clones();
    my $err = do { local $@; eval {
        $a->validate_helper_ref('refs/karr-local/tasks/1/lock'); 1 } ? '' : $@ };
    like $err, qr/protected namespace/,
        'refs/karr-local/ is off limits to the helper-ref commands';

    # The namespace it was carved out of is still protected, and ordinary
    # helper refs are still allowed.
    like do { local $@; eval { $a->validate_helper_ref('refs/karr/x'); 1 } ? '' : $@ },
        qr/protected namespace/, 'refs/karr/ still is too';
    is $a->validate_helper_ref('refs/handoff/x'), 'refs/handoff/x',
        'and an ordinary helper ref is unaffected';
};

# --- locks the old layout left behind ---------------------------------------
#
# A board that was pushed with locks in it, or a clone still running an older
# karr, leaves refs at the old address. Nothing writes there any more, but they
# must not become invisible: `karr unlock` is the only way they ever get
# cleared.

subtest 'a lock left at the old address is reported, not hidden' => sub {
    my ( $work, $a ) = two_clones();
    $a->write_ref( 'refs/karr/tasks/1/lock', 'ghost@example.com' );

    my @held = App::karr::Lock->new( git => $a )->locks;
    is scalar @held, 1, 'the stray lock is listed';
    is $held[0]{task_id}, 1, 'against the right task';
    is $held[0]{owner}, 'ghost@example.com', 'with the identity that wrote it';
    is $held[0]{legacy}, 1, 'and marked as one from the old layout';
};

subtest 'both layouts are reported side by side' => sub {
    my ( $work, $a ) = two_clones();
    $a->write_ref( 'refs/karr/tasks/1/lock', 'ghost@example.com' );
    App::karr::Lock->new( git => $a )->acquire( 1, 'a@karr.test' );

    my @held = App::karr::Lock->new( git => $a )->locks;
    is scalar @held, 2, 'both refs are visible';
    is_deeply [ map { $_->{legacy} } @held ], [ 0, 1 ],
        'the current one first, the stray one after it';
    is $held[0]{owner}, 'a@karr.test', 'the live lock is this clone\'s';
};

subtest 'breaking a lock clears the old address too' => sub {
    my ( $work, $a ) = two_clones();
    $a->write_ref( 'refs/karr/tasks/1/lock', 'ghost@example.com' );
    $a->write_ref( 'refs/karr/tasks/2/lock', 'ghost@example.com' );

    my ( $ok, $owner ) = App::karr::Lock->new( git => $a )->break_lock(1);
    ok $ok, 'the stray lock is breakable';
    is $owner, 'ghost@example.com', 'and its holder is reported';
    ok !$a->ref_exists('refs/karr/tasks/1/lock'), 'the ref is gone';
    ok $a->ref_exists('refs/karr/tasks/2/lock'), 'the other one is untouched';

    my ( $again, $msg ) = App::karr::Lock->new( git => $a )->break_lock(1);
    ok !$again, 'breaking it twice reports nothing to break';
    is $msg, 'not locked', 'with the usual wording';
};

subtest 'break_lock clears a current lock and a stray one in one go' => sub {
    my ( $work, $a ) = two_clones();
    $a->write_ref( 'refs/karr/tasks/1/lock', 'ghost@example.com' );
    App::karr::Lock->new( git => $a )->acquire( 1, 'a@karr.test' );

    my ($ok) = App::karr::Lock->new( git => $a )->break_lock(1);
    ok $ok, 'the break succeeds';
    ok !$a->ref_exists('refs/karr-local/tasks/1/lock'), 'the live lock is gone';
    ok !$a->ref_exists('refs/karr/tasks/1/lock'), 'and so is the stray one';
    is_deeply [ App::karr::Lock->new( git => $a )->locks ], [],
        'nothing is left holding task 1';
};

subtest 'karr unlock shows a stray lock and clears it' => sub {
    my ( $work, $a ) = two_clones();
    $a->write_ref( 'refs/karr/tasks/1/lock', 'ghost@example.com' );
    App::karr::Lock->new( git => $a )->acquire( 2, 'a@karr.test' );

    my $store = App::karr::BoardStore->new( git => $a );
    my ( $err, $out ) =
        run_execute( App::karr::Cmd::Unlock->new( store => $store ) );
    is $err, '', 'karr unlock does not die on a stray lock' or diag $err;
    like $out, qr/Task 1\s+held by ghost\@example\.com.*\[stray/,
        'the stray is listed and named as one';
    like $out, qr/Task 2\s+held by a\@karr\.test(?!.*\[stray)/,
        'while the live lock is not';

    # --all must break each task once, even though task 1 has only the stray
    # and a task with both addresses would appear twice.
    App::karr::Lock->new( git => $a )->acquire( 1, 'a@karr.test' );
    ( $err, $out ) = run_execute(
        App::karr::Cmd::Unlock->new( store => $store, all => 1 ) );
    is $err, '', '--all does not die' or diag $err;
    is scalar( () = $out =~ /task 1\b/gi ), 1,
        'a task holding both a live and a stray lock is broken once, not twice';
    unlike $out, qr/is not locked/,
        'and nothing is reported as already clear';

    is_deeply [ App::karr::Lock->new( git => $a )->locks ], [],
        'both addresses are clear afterwards';
};

subtest 'a stray lock does not block this clone from picking' => sub {
    my ( $work, $a ) = two_clones();
    $a->write_ref( 'refs/karr/tasks/1/lock', 'ghost@example.com' );

    # It cannot say anything about this process, and pick exclusivity rests on
    # the compare-and-swap on the card, not on the lock. Blocking on it would be
    # the #93 symptom surviving the #93 fix.
    my ( $ok, $msg ) =
        App::karr::Lock->new( git => $a )->acquire( 1, 'a@karr.test' );
    ok $ok, "the pick goes ahead ($msg)";
    is $a->read_ref('refs/karr/tasks/1/lock'), 'ghost@example.com',
        'and the stray ref is left exactly as it was, for karr unlock to clear';
};

done_testing;
