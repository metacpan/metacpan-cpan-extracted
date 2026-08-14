# t/82-pick-exclusivity-and-locks.t
#
# Two tickets, one code path.
#
# #86: `karr pick` decided which task to take from a snapshot of the board read
# before any lock existed, and never looked at the card again. Twelve parallel
# picks on a fresh twelve-task board reported "1 x task 1, 4 x task 2,
# 7 x task 3" -- and on the run that produced this file, nine agents were told
# they owned task 1 while the card named only the last of them. The lock was not
# the hole: its holder identity is the clone's user.email, which every agent on
# one machine shares, so twelve contenders all acquired it quite legitimately.
#
# #45: an agent that died between acquire and release left a lock ref that
# nothing could ever clear. It made its task unpickable forever, and once the
# card itself was deleted the ref still matched list_task_refs' pattern, so
# load_tasks handed every consumer an undef and list/board/materialize/pick all
# died on it. Recovery took `git update-ref -d` from outside karr.
use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestGit qw( require_git_c );
require_git_c();
use Config;
use File::Temp qw( tempdir );
use Path::Tiny qw( path );
use POSIX ();
use Time::HiRes ();
use Time::Piece;
use YAML::XS qw( Dump );

use App::karr::Git;
use App::karr::BoardStore;
use App::karr::Task;
use App::karr::Lock;
use App::karr::Cmd::Pick;
use App::karr::Cmd::Unlock;
use App::karr::Cmd::List;

my $CONTENDERS = 12;

# Built from the class rather than spelled out, so a move of the namespace --
# refs/karr/tasks/N/lock became refs/karr-local/tasks/N/lock in #93, to keep
# locks out of everything karr pushes -- cannot leave these assertions quietly
# checking an address nothing writes to any more.
sub lock_ref {
    my ($id) = @_;
    return App::karr::Lock->LOCK_ROOT . "$id/lock";
}

sub init_repo {
    my $repo = tempdir( CLEANUP => 1 );
    system( 'git', 'init', '-q', $repo ) == 0 or BAIL_OUT('git init failed');
    system( 'git', '-C', $repo, 'config', 'user.email', 'test@example.com' ) == 0
        or BAIL_OUT('git config failed');
    system( 'git', '-C', $repo, 'config', 'user.name', 'Test User' ) == 0
        or BAIL_OUT('git config failed');
    return $repo;
}

# A board of $n identical todo cards, so nothing but the race decides who gets
# which one.
sub init_board {
    my ( $repo, $n ) = @_;
    my $git = App::karr::Git->new( dir => $repo );
    $git->write_ref( 'refs/karr/config',
        Dump( { version => 1, board => { name => 'T' } } ) );
    $git->write_ref( 'refs/karr/meta/next-id', ( $n + 1 ) . "\n" );
    my $store = App::karr::BoardStore->new( git => $git );
    $store->save_task(
        App::karr::Task->new(
            id => $_, title => "Task $_", status => 'todo',
            priority => 'high', class => 'standard',
        )
    ) for 1 .. $n;
    return $store;
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

subtest 'twelve parallel picks claim twelve different tasks' => sub {
    plan skip_all => 'fork is not available on this platform'
        unless $Config{d_fork};

    my $repo = init_repo();
    init_board( $repo, $CONTENDERS );
    # Warm libgit2 in the parent so every child inherits it initialised and the
    # barrier below is the only thing gating them.
    App::karr::Git->new( dir => $repo )->list_task_refs;

    my $out   = path( tempdir( CLEANUP => 1 ) );
    my $start = Time::HiRes::time() + 0.4;

    my @pids;
    for my $n ( 1 .. $CONTENDERS ) {
        my $pid = fork;
        BAIL_OUT("fork failed: $!") unless defined $pid;
        if ( !$pid ) {
            my $line = eval {
                my $store = App::karr::BoardStore->new(
                    git => App::karr::Git->new( dir => $repo ) );
                $store->load_tasks;    # warm-up, before the barrier
                my $cmd = App::karr::Cmd::Pick->new(
                    store => $store,
                    claim => "agent-$n",
                    move  => 'in-progress',
                );
                my $left = $start - Time::HiRes::time();
                Time::HiRes::sleep($left) if $left > 0;
                my ( $err, $said ) = run_execute($cmd);
                $err ? "died: $err" : $said;
            };
            $line = "died: $@" unless defined $line;
            $line =~ s/\s+/ /g;
            $out->child($n)->spew_utf8("$line\n");
            # _exit, not exit: a child running Test::More's END block would
            # print a second TAP stream into the parent's.
            POSIX::_exit(0);
        }
        push @pids, $pid;
    }
    waitpid $_, 0 for @pids;

    my @lines = map {
        my $f = $out->child($_);
        my $l = $f->exists ? $f->slurp_utf8 : 'vanished without a result';
        chomp $l;
        $l;
    } 1 .. $CONTENDERS;

    # What each agent was told it got.
    my %told;
    for my $n ( 1 .. $CONTENDERS ) {
        $told{"agent-$n"} = $1 if $lines[ $n - 1 ] =~ /Picked task (\d+)/;
    }

    is scalar( keys %told ), $CONTENDERS,
        "all $CONTENDERS agents were told they picked a task"
        or diag join "\n", 'results:', @lines;

    my %by_task;
    push @{ $by_task{ $told{$_} } }, $_ for keys %told;
    my @shared = sort { $a <=> $b } grep { @{ $by_task{$_} } > 1 } keys %by_task;
    is_deeply \@shared, [],
        'no task was handed to more than one agent'
        or diag join "\n",
            ( map { "task $_ -> @{[ sort @{ $by_task{$_} } ]}" } @shared ),
            'results:', @lines;

    # ...and the board agrees with what they were told. This is the assertion
    # the pre-fix code cannot satisfy even when the counts happen to work out:
    # every agent wrote its claim with an unguarded last-writer-wins write, so
    # the card ended up naming whoever finished last.
    my $store = App::karr::BoardStore->new(
        git => App::karr::Git->new( dir => $repo ) );
    my %claimed = map { $_->id => ( $_->has_claimed_by ? $_->claimed_by : '' ) }
        $store->load_tasks;
    my @disagree =
        grep { ( $claimed{ $told{$_} } // '' ) ne $_ } sort keys %told;
    is_deeply \@disagree, [],
        'every agent that was told it picked a task is the one named on that card'
        or diag join "\n",
            ( map { "$_ was told task $told{$_}, which names '"
                    . ( $claimed{ $told{$_} } // '' ) . "'" } @disagree ),
            'results:', @lines;

    ok !( grep { m{/lock\z} } App::karr::Git->new( dir => $repo )
            ->list_refs( App::karr::Lock->LOCK_ROOT ) ),
        'no lock ref was left behind by any of the twelve';
};

subtest 'a candidate claimed after the ranking is not stolen' => sub {
    # The deterministic half of #86: the race above only fails the old code by
    # luck. Here the card is claimed by somebody else at the exact moment the
    # pre-fix code stopped looking -- after the lock is granted.
    my $repo  = init_repo();
    my $store = init_board( $repo, 2 );

    my $original = \&App::karr::Lock::acquire;
    my $fired    = 0;
    no warnings 'redefine';
    local *App::karr::Lock::acquire = sub {
        my ( $lock, $id, $email ) = @_;
        my @answer = $original->( $lock, $id, $email );
        if ( $answer[0] && !$fired++ ) {
            my $other = App::karr::BoardStore->new(
                git => App::karr::Git->new( dir => $repo ) )->find_task($id);
            $other->claimed_by('agent-other');
            $other->claimed_at( gmtime->datetime . 'Z' );
            App::karr::BoardStore->new(
                git => App::karr::Git->new( dir => $repo ) )->save_task($other);
        }
        return @answer;
    };
    use warnings 'redefine';

    my $cmd = App::karr::Cmd::Pick->new( store => $store, claim => 'agent-me' );
    my ( $err, $out ) = run_execute($cmd);
    is $err, '', 'pick does not die' or diag $err;

    my $fresh = App::karr::BoardStore->new(
        git => App::karr::Git->new( dir => $repo ) );
    is $fresh->find_task(1)->claimed_by, 'agent-other',
        'the claim written behind pick\'s back survives';
    like $out, qr/Picked task 2/,
        'pick re-read task 1 under the lock, saw it taken, and moved on';
    is $fresh->find_task(2)->claimed_by, 'agent-me',
        'the task it reports is the task the board says it has';
};

subtest 'a candidate claimed between the re-read and the write is not overwritten' => sub {
    # ...and the half below that: even the re-read is a snapshot, so the write
    # itself is a compare-and-swap. Slip a competing claim in between the two.
    my $repo  = init_repo();
    my $store = init_board( $repo, 2 );

    my $original = \&App::karr::BoardStore::find_task_with_oid;
    my $fired    = 0;
    no warnings 'redefine';
    local *App::karr::BoardStore::find_task_with_oid = sub {
        my ( $self, $id ) = @_;
        my @answer = $original->( $self, $id );
        if ( $answer[0] && !$fired++ ) {
            my $side = App::karr::BoardStore->new(
                git => App::karr::Git->new( dir => $repo ) );
            my $other = $side->find_task($id);
            $other->claimed_by('agent-other');
            $other->claimed_at( gmtime->datetime . 'Z' );
            $side->save_task($other);
        }
        return @answer;
    };
    use warnings 'redefine';

    my $cmd = App::karr::Cmd::Pick->new( store => $store, claim => 'agent-me' );
    my ( $err, $out ) = run_execute($cmd);
    is $err, '', 'pick does not die' or diag $err;

    my $fresh = App::karr::BoardStore->new(
        git => App::karr::Git->new( dir => $repo ) );
    is $fresh->find_task(1)->claimed_by, 'agent-other',
        'the competing claim is not overwritten by the write pick had already decided on';
    like $out, qr/Picked task 2/, 'pick lost the compare-and-swap and took the next candidate';
};

subtest 'an orphaned lock ref does not brick the board' => sub {
    my $repo  = init_repo();
    my $store = init_board( $repo, 2 );
    my $git   = App::karr::Git->new( dir => $repo );

    # Exactly the state #45 was reported from: an agent died holding the lock on
    # task 1, and the card was deleted later.
    App::karr::Lock->new( git => $git )->acquire( 1, 'ghost@example.com' );
    $store->delete_task(1);

    ok $git->ref_exists(lock_ref(1)), 'the orphaned lock is still there';
    is_deeply [ $git->list_task_refs ], [2],
        'a lock ref alone does not make a task id exist';
    is_deeply [ map { $_->id } $store->load_tasks ], [2],
        'load_tasks hands out cards, never undef';

    my ( $err, $out ) = run_execute(
        App::karr::Cmd::List->new( store => $store ) );
    is $err, '', 'karr list survives the orphaned lock' or diag $err;
    like $out, qr/Task 2/, '...and still shows the surviving card';

    ( $err, undef ) = run_execute(
        App::karr::Cmd::Pick->new( store => $store, claim => 'agent-me' ) );
    is $err, '', 'karr pick survives it too' or diag $err;
};

subtest 'locks expire, and a live one is not stolen' => sub {
    my $repo = init_repo();
    my $git  = App::karr::Git->new( dir => $repo );

    my $live = App::karr::Lock->new( git => $git, ttl => 3600 );
    my ( $ok, $msg ) = $live->acquire( 1, 'ghost@example.com' );
    ok $ok, 'the first agent takes the lock';

    ( $ok, $msg ) = $live->acquire( 1, 'other@example.com' );
    ok !$ok, 'a second agent is refused while the lock is live';
    is $msg, 'locked by ghost@example.com', 'and told who holds it';

    # Same ref, same holder, a TTL of zero. That means "no expiry", not "expire
    # everything", which is what `lock_timeout: 0s` has to mean for a board that
    # wants `karr unlock` to be the only way a lock is ever cleared.
    my $expiring = App::karr::Lock->new( git => $git, ttl => 0 );
    is $expiring->ttl, 0, 'a zero ttl is honoured, not swapped for the default';
    ( $ok, $msg ) = $expiring->acquire( 1, 'other@example.com' );
    ok !$ok, 'ttl 0 disables expiry rather than expiring everything instantly';

    my $instant = App::karr::Lock->new( git => $git, ttl => -1 );
    ( $ok, $msg ) = $instant->acquire( 1, 'other@example.com' );
    ok !$ok, 'a negative ttl disables expiry too';

    # A TTL the existing lock really is past. The lock's age is the committer
    # time of its commit, so sleeping past a one-second ttl is the honest way to
    # age it -- and only the "has expired" side is timed, so a slow machine
    # cannot turn this into a flake.
    my $short = App::karr::Lock->new( git => $git, ttl => 1 );
    sleep 2;
    ( $ok, $msg ) = $short->acquire( 1, 'other@example.com' );
    ok $ok, 'once past the ttl the lock is taken over';
    like $msg, qr/broke stale lock held by ghost\@example\.com/,
        'and the takeover says whose lock it broke';
    is $short->get(1), 'other@example.com', 'the ref now names the new holder';
};

subtest 'a stale-lock takeover is a compare-and-swap, not a force write' => sub {
    # The takeover must be guarded against the OID whose age was judged, or a
    # holder that refreshes its lock in the meantime is silently evicted.
    my $repo = init_repo();
    my $git  = App::karr::Git->new( dir => $repo );

    my $lock = App::karr::Lock->new( git => $git, ttl => 1 );
    $lock->acquire( 1, 'ghost@example.com' );
    sleep 2;

    my ( $stale_oid ) = $git->read_ref_with_oid(lock_ref(1));
    ok $lock->expired($stale_oid), 'the lock reads as expired';

    # The holder comes back and refreshes before the takeover lands.
    $lock->acquire( 1, 'ghost@example.com' );
    my ( $fresh_oid ) = $git->read_ref_with_oid(lock_ref(1));
    isnt $fresh_oid, $stale_oid, 'the refresh moved the ref';
    ok !$lock->expired($fresh_oid), 'and the refreshed lock is live again';

    is $git->write_ref_cas( lock_ref(1), "other\@example.com", $stale_oid ),
        0, 'a takeover guarded by the OID that was judged stale is refused';
    is $git->read_ref(lock_ref(1)), 'ghost@example.com',
        'the live holder keeps its lock';
};

subtest 'karr unlock reports locks and breaks them' => sub {
    my $repo  = init_repo();
    my $store = init_board( $repo, 3 );
    my $git   = App::karr::Git->new( dir => $repo );

    my $lock = App::karr::Lock->new( git => $git );
    $lock->acquire( $_, "ghost-$_\@example.com" ) for 1, 2;

    my ( $err, $out ) = run_execute(
        App::karr::Cmd::Unlock->new( store => $store ) );
    is $err, '', 'karr unlock with no arguments does not die' or diag $err;
    like $out, qr/Task 1\s+held by ghost-1\@example\.com/, 'it names the first holder';
    like $out, qr/Task 2\s+held by ghost-2\@example\.com/, 'and the second';
    ok $git->ref_exists(lock_ref(1)),
        'reporting on its own destroys nothing';

    ( $err, $out ) = run_execute(
        App::karr::Cmd::Unlock->new( store => $store ), '1' );
    is $err, '', 'breaking one lock does not die' or diag $err;
    like $out, qr/Broke lock on task 1 \(was held by ghost-1\@example\.com\)/,
        'it says what it broke';
    ok !$git->ref_exists(lock_ref(1)), 'the lock ref is gone';
    ok $git->ref_exists(lock_ref(2)), 'the other one is untouched';

    ( $err, $out ) = run_execute(
        App::karr::Cmd::Unlock->new( store => $store ), '1' );
    is $err, '', 'breaking an absent lock is not an error';
    like $out, qr/Task 1 is not locked/, 'it says so';

    ( $err, $out ) = run_execute(
        App::karr::Cmd::Unlock->new( store => $store, all => 1 ) );
    is $err, '', '--all does not die' or diag $err;
    ok !( grep { m{/lock\z} } $git->list_refs( App::karr::Lock->LOCK_ROOT ) ),
        '--all clears every remaining lock';

    ( $err, $out ) = run_execute(
        App::karr::Cmd::Unlock->new( store => $store ) );
    like $out, qr/No locks held/, 'and the board reports clean afterwards';

    # The escape hatch has to work on the state that caused #45: a lock whose
    # card is gone. `karr delete` cannot reach it -- "Task 1 not found".
    $lock->acquire( 3, 'ghost@example.com' );
    $store->delete_task(3);
    ( $err, $out ) = run_execute(
        App::karr::Cmd::Unlock->new( store => $store ), '3' );
    is $err, '', 'a lock with no card behind it can still be broken' or diag $err;
    ok !$git->ref_exists(lock_ref(3)), '...and it is';
};

subtest 'the lock is released, and the pick logged, before the push' => sub {
    my $remote = tempdir( CLEANUP => 1 );
    system( 'git', 'init', '--bare', '-q', $remote ) == 0
        or BAIL_OUT('git init --bare failed');
    my $repo = init_repo();
    system( 'git', '-C', $repo, 'remote', 'add', 'origin', $remote ) == 0
        or BAIL_OUT('git remote add failed');

    my $store = init_board( $repo, 1 );
    my ( $err, $out ) = run_execute(
        App::karr::Cmd::Pick->new( store => $store, claim => 'agent-me' ) );
    is $err, '', 'the pick succeeds against a real remote' or diag $err;
    like $out, qr/Picked task 1/, 'and reports the pick';

    my $remote_git = App::karr::Git->new( dir => $remote );
    my @refs = $remote_git->list_refs('refs/karr/');

    # Releasing after sync_after deleted the lock locally and left it on the
    # remote for good; the next pull brought it straight back (#45).
    ok !( grep { m{/lock\z} } @refs ),
        'no lock ref was published to the remote';

    # Logging after sync_after wrote the entry into a clone that had already
    # finished pushing, so it never left this machine.
    ok scalar( grep { m{\Arefs/karr/log/} } @refs ),
        'the pick log entry did reach the remote'
        or diag join "\n", 'remote refs:', @refs;

    ok( ( grep { $_ eq 'refs/karr/tasks/1/data' } @refs ),
        'and so did the claimed card' );
};

done_testing;
