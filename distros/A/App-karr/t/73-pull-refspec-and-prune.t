use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestGit qw( require_git_c );
require_git_c();
use File::Temp qw( tempdir );
use Cwd qw( abs_path );
use IPC::Open3 qw( open3 );
use Symbol qw( gensym );
use App::karr::Git;
use App::karr::Task;
use Git::Native::Remote;

# Regression tests for the pull half of the transport (#40, #49, #41).
#
#   #40  pull used the non-forced refspec `refs/karr/*:refs/karr/*` while push
#        used the forced one. Since write_ref commits are parentless, every
#        board update is non-fast-forward, so the fetch silently declined it,
#        pull still returned success, and the next push force-wrote the stale
#        local ref over the other agent's work.
#   #49  pull never pruned, so a task deleted in one clone came back from any
#        other clone that still had it.
#   #41  the two transports disagreed on a diverged board: libgit2 no-opped in
#        silence, the git-CLI fallback failed with "non-fast-forward" on every
#        ref and locked the clone out permanently. The fix has to land on both,
#        so every scenario below runs twice and the outcomes are compared.
#
# Plus the regression the first attempt at those introduced: pruning on "the
# remote does not have this ref" alone deleted local work that had been written
# but not pushed yet -- precisely what karr promises to keep after a failed
# push ("Local refs are intact. Run 'karr sync' to retry."). pull therefore
# fetches into a tracking mirror (refs/karr-remote/<remote>/*) and reconciles
# against it, which makes the four cases decidable. All four are pinned below.
#
# "native" runs with KARR_NO_CLI_FALLBACK=1 so libgit2 has to do the work on
# its own. "cli" makes the whole native remote surface throw, which is the
# production fallback path (ssh-config / ProxyCommand remotes).

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

sub origin_board_refs {
    my ($work) = @_;
    my @refs = `git -C '$work/origin.git' for-each-ref --format='%(refname)' 'refs/karr/'`;
    chomp @refs;
    return [ sort @refs ];
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

sub warnings_from {
    my ($code) = @_;
    my @warned;
    local $SIG{__WARN__} = sub { push @warned, $_[0] };
    $code->();
    return \@warned;
}

# Point the clone's push URL at nothing, so its push really fails while its
# fetch keeps working -- the state karr describes as "Local refs are intact".
sub break_push {
    my ($dir) = @_;
    system( 'git', '-C', $dir, 'remote', 'set-url', '--push', 'origin',
        '/nonexistent-karr-remote.git' );
    return;
}

sub fix_push {
    my ( $dir, $work ) = @_;
    system( 'git', '-C', $dir, 'remote', 'set-url', '--push', 'origin',
        "$work/origin.git" );
    return;
}

# Run $code with the transport the caller asked for, and nothing else.
sub with_transport {
    my ( $transport, $code ) = @_;
    if ( $transport eq 'native' ) {
        local $ENV{KARR_NO_CLI_FALLBACK} = 1;
        return $code->();
    }
    no warnings 'redefine';
    local *Git::Native::Remote::fetch =
        sub { die "forced libgit2 fetch failure\n" };
    local *Git::Native::Remote::list_refs =
        sub { die "forced libgit2 ls failure\n" };
    return $code->();
}

my %outcome;

for my $transport (qw( native cli )) {
    subtest "$transport transport: pull applies updates and deletions" => sub {
        my ( $work, $a, $b ) = two_clones();

        # A publishes a board with two tasks.
        $a->save_task_ref( task( 1, 'Shared task', 'hello' ) );
        $a->save_task_ref( task( 3, 'Doomed task' ) );
        ok $a->push, 'A pushes the initial board';

        ok with_transport( $transport, sub { $b->pull } ),
            'B pulls the initial board';
        my $first = $b->load_task_ref(1);
        ok $first, 'B has task 1 after the first pull';
        is $first && $first->body, 'hello', 'B sees the initial body';

        # A moves task 1 on and drops task 3 -- both are non-fast-forward
        # changes for B, which is the whole point.
        my $updated = $a->load_task_ref(1);
        $updated->body("hello\nnote from A");
        $a->save_task_ref($updated);
        $a->delete_ref('refs/karr/tasks/3/data');
        ok $a->push, 'A pushes the update and the deletion';

        my $diverged_rv = with_transport( $transport, sub { $b->pull } ) ? 1 : 0;
        ok $diverged_rv,
            '#41: pull succeeds on a diverged board (no silent no-op, no lockout)';

        my $seen = $b->load_task_ref(1);
        ok $seen, 'B still has task 1';
        like $seen && $seen->body, qr/note from A/,
            "#40: B's pull actually applied A's update";
        ok !$b->ref_exists('refs/karr/tasks/3/data'),
            '#49: the ref A deleted is pruned from B';

        # The headline of #40: B writes on top of what it just read, and A's
        # work survives instead of being force-written away.
        my $mine = $b->load_task_ref(1);
        $mine->body( $mine->body . "\nnote from B" );
        $b->save_task_ref($mine);
        ok $b->push, 'B pushes its own edit';

        ok $a->pull, 'A pulls B back';
        my $merged = $a->load_task_ref(1);
        like $merged && $merged->body, qr/note from A/,
            "#40: A's note survived B's write";
        like $merged && $merged->body, qr/note from B/,
            "B's note is on the shared board";

        # #49 again, from the other side: B's push must not resurrect task 3.
        # (The board-id in these lists is the identity stamp #95 adds: B's
        # first pull of this hand-built, unstamped board is the pre-change
        # migration case, so B stamped it, and B's push armed the remote.)
        is_deeply origin_board_refs($work),
            [ 'refs/karr/meta/board-id', 'refs/karr/tasks/1/data' ],
            '#49: the deleted task stays deleted after a round trip through B';

        # The diverged-pull return value is in here on purpose: before the fix
        # the two transports differed exactly there (libgit2 returned success
        # after doing nothing, the CLI returned failure and stayed failing),
        # so this is what makes the comparison below a real #41 assertion and
        # not just two equally broken boards agreeing.
        $outcome{$transport} = {
            diverged_pull_rv => $diverged_rv,
            body             => $merged ? $merged->body : undef,
            origin_refs      => origin_board_refs($work),
            local_refs       => [ sort $b->list_refs('refs/karr/') ],
        };
    };
}

# #41: same repo, same refs, same operation -- the two transports have to end
# up in the same place.
is_deeply $outcome{cli}, $outcome{native},
    '#41: the libgit2 and git-CLI transports leave the board in the same state';

# The prune added for #49 must not turn a not-yet-pushed board into an empty
# one. `karr init` writes the board into local refs and never pushes, so the
# remote's karr namespace is legitimately empty on the first command that
# syncs -- an unguarded prune-on-fetch wipes the whole board there (verified:
# both transports do delete every local refs/karr/* in that situation).
for my $transport (qw( native cli )) {
    subtest "$transport transport: pull does not wipe a board the remote has never seen" => sub {
        my ( $work, $a ) = two_clones();
        $a->write_ref( 'refs/karr/config',        "board:\n  name: fresh\n" );
        $a->write_ref( 'refs/karr/meta/next-id',  "1\n" );
        $a->save_task_ref( task( 1, 'Local only' ) );

        ok with_transport( $transport, sub { $a->pull } ),
            'pull against a remote without a board succeeds';
        is_deeply [ sort $a->list_refs('refs/karr/') ],
            [ sort qw(
                refs/karr/config
                refs/karr/meta/board-id
                refs/karr/meta/next-id
                refs/karr/tasks/1/data
            ) ],
            'the freshly initialized board is still there';
    };
}

# ---------------------------------------------------------------------
# The four cases the tracking mirror exists to tell apart. Each is built
# from scratch so a failure names exactly which distinction broke.
# ---------------------------------------------------------------------
for my $transport (qw( native cli )) {
    subtest "$transport transport: the four sync cases" => sub {

        subtest 'case 1: remote moved, nothing unpushed here -> take the remote' => sub {
            my ( $work, $a, $b ) = two_clones();
            $a->save_task_ref( task( 1, 'Shared task', 'v1' ) );
            ok $a->push, 'A publishes the board';
            ok with_transport( $transport, sub { $b->pull } ), 'B syncs';

            $a->save_task_ref( task( 1, 'Shared task', 'v2' ) );
            ok $a->push, 'A publishes an update';

            my $warned = warnings_from(
                sub { with_transport( $transport, sub { $b->pull } ) } );
            my $seen = $b->load_task_ref(1);
            is $seen && $seen->body, 'v2', 'B took the remote version';
            is_deeply $warned, [], 'an ordinary remote update is not a conflict';
        };

        subtest 'case 2: remote deleted it, nothing unpushed here -> prune' => sub {
            my ( $work, $a, $b ) = two_clones();
            $a->save_task_ref( task( 1, 'Kept' ) );
            $a->save_task_ref( task( 3, 'Doomed' ) );
            ok $a->push, 'A publishes two tasks';
            ok with_transport( $transport, sub { $b->pull } ), 'B syncs';

            $a->delete_ref('refs/karr/tasks/3/data');
            ok $a->push, 'A deletes one and pushes';

            ok with_transport( $transport, sub { $b->pull } ), 'B pulls';
            ok !$b->ref_exists('refs/karr/tasks/3/data'),
                'the deletion propagated (#49)';
            ok $b->ref_exists('refs/karr/tasks/1/data'),
                'the surviving task is untouched';
        };

        subtest 'case 3: remote never had it, unpushed here -> keep it' => sub {
            my ( $work, $a, $b ) = two_clones();
            $a->save_task_ref( task( 1, 'Shared task' ) );
            ok $a->push, 'A publishes the board';
            ok with_transport( $transport, sub { $b->pull } ), 'B syncs';

            # From here B is in the state karr reports as "Local refs are
            # intact. Run 'karr sync' to retry."
            break_push("$work/b");
            $b->save_task_ref( task( 2, 'UNPUSHED WORK' ) );
            ok !$b->push, "B's push really fails";
            ok $b->ref_exists('refs/karr/tasks/2/data'),
                'the local ref is there, as karr just promised';

            ok with_transport( $transport, sub { $b->pull } ),
                'B pulls before it manages to retry the push';
            ok $b->ref_exists('refs/karr/tasks/2/data'),
                'the unpushed task survives the pull';
            my $kept = $b->load_task_ref(2);
            is $kept && $kept->title, 'UNPUSHED WORK',
                'and still has its content';

            # The promise is only kept if the retry actually works afterwards.
            fix_push( "$work/b", $work );
            ok $b->push, "B's retried push succeeds";
            is_deeply origin_board_refs($work),
                [ 'refs/karr/meta/board-id',
                  'refs/karr/tasks/1/data', 'refs/karr/tasks/2/data' ],
                'the rescued task reaches the remote';
        };

        subtest 'case 3b: an unpushed local deletion stays deleted' => sub {
            my ( $work, $a, $b ) = two_clones();
            $a->save_task_ref( task( 1, 'Kept' ) );
            $a->save_task_ref( task( 2, 'To delete' ) );
            ok $a->push, 'A publishes two tasks';
            ok with_transport( $transport, sub { $b->pull } ), 'B syncs';

            break_push("$work/b");
            $b->delete_ref('refs/karr/tasks/2/data');
            ok !$b->push, "B's push of the deletion fails";

            my $warned = warnings_from(
                sub { with_transport( $transport, sub { $b->pull } ) } );
            ok !$b->ref_exists('refs/karr/tasks/2/data'),
                'the deletion is not undone by the remote copy';
            is_deeply $warned, [],
                'and it is not mistaken for a conflict';

            fix_push( "$work/b", $work );
            ok $b->push, "B's retried push succeeds";
            is_deeply origin_board_refs($work),
                [ 'refs/karr/meta/board-id', 'refs/karr/tasks/1/data' ],
                'the deletion finally reaches the remote';
        };

        subtest 'case 4: both sides moved -> remote wins, local parked, warned' => sub {
            my ( $work, $a, $b ) = two_clones();
            $a->save_task_ref( task( 1, 'Shared task', 'base' ) );
            ok $a->push, 'A publishes the board';
            ok with_transport( $transport, sub { $b->pull } ), 'B syncs';

            $a->save_task_ref( task( 1, 'Shared task', 'from A' ) );
            ok $a->push, 'A edits and pushes';
            $b->save_task_ref( task( 1, 'Shared task', 'from B' ) );

            my $warned = warnings_from(
                sub { with_transport( $transport, sub { $b->pull } ) } );

            my $won = $b->load_task_ref(1);
            is $won && $won->body, 'from A',
                'the remote version takes the slot';
            like join( '', @$warned ), qr/both changed .*tasks/,
                'the user is told, instead of it happening silently';
            like join( '', @$warned ), qr{refs/karr-conflict/},
                'and is told where the local version went';

            my $parked = $b->read_ref('refs/karr-conflict/origin/tasks/1/data');
            like $parked, qr/from B/,
                "B's displaced version is recoverable, not just reported";

            ok $b->push, 'B pushes on';
            is_deeply origin_board_refs($work),
                [ 'refs/karr/meta/board-id', 'refs/karr/tasks/1/data' ],
                'the parked conflict is never pushed to the remote';
        };

        subtest 'case 4b: remote deleted it while this clone edited it' => sub {
            my ( $work, $a, $b ) = two_clones();
            $a->save_task_ref( task( 1, 'Shared task', 'base' ) );
            ok $a->push, 'A publishes the board';
            ok with_transport( $transport, sub { $b->pull } ), 'B syncs';

            $a->delete_ref('refs/karr/tasks/1/data');
            ok $a->push, 'A deletes it and pushes';
            $b->save_task_ref( task( 1, 'Shared task', 'edited by B' ) );

            my $warned = warnings_from(
                sub { with_transport( $transport, sub { $b->pull } ) } );

            ok !$b->ref_exists('refs/karr/tasks/1/data'),
                'the deletion wins, as the last write did';
            like join( '', @$warned ), qr/both changed/,
                'but the clone that had edited it is told';
            like $b->read_ref('refs/karr-conflict/origin/tasks/1/data'),
                qr/edited by B/, "and B's edit is still recoverable";
        };
    };
}

# Guards the other half of the mirror contract: push has to update it too.
# Without that, every ref this clone ever pushed reads as "changed locally" and
# the next ordinary update from the other side is reported as a conflict.
for my $transport (qw( native cli )) {
    subtest "$transport transport: ordinary two-agent ping-pong is conflict-free" => sub {
        my ( $work, $a, $b ) = two_clones();
        $a->save_task_ref( task( 1, 'Shared task', 'a1' ) );
        ok $a->push, 'A writes and pushes';

        my $warned = warnings_from( sub {
            with_transport( $transport, sub { $b->pull } );
            $b->save_task_ref( task( 1, 'Shared task', 'b1' ) );
            $b->push;
            with_transport( $transport, sub { $a->pull } );
            $a->save_task_ref( task( 1, 'Shared task', 'a2' ) );
            $a->push;
            with_transport( $transport, sub { $b->pull } );
        } );

        my $final = $b->load_task_ref(1);
        is $final && $final->body, 'a2', 'both sides converge';
        is_deeply $warned, [], 'no spurious conflict reports';
    };
}

# ---------------------------------------------------------------------
# The reported regression, through the CLI exactly as filed: push broken,
# `create`, then `sync --pull`, and the work has to survive.
# ---------------------------------------------------------------------
subtest 'end to end: a failed push leaves work that the next sync keeps' => sub {
    my $root = abs_path('.');
    my $bin  = "$root/bin/karr";

    my $work = tempdir( CLEANUP => 1 );
    system( 'git', 'init', '-q', '--bare', "$work/origin.git" );
    system("git clone -q '$work/origin.git' '$work/a' 2>/dev/null");
    system( 'git', '-C', "$work/a", 'config', 'user.email', 'a@karr.test' );
    system( 'git', '-C', "$work/a", 'config', 'user.name',  'agent-a' );

    my $karr = sub {
        my (@argv) = @_;
        my $err = gensym;
        my $pid = open3( my $in, my $out, $err,
            $^X, "-I$root/lib", $bin, '--dir', "$work/a", @argv );
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

    is $karr->( 'init', '--name', 'demo' )->{exit}, 0, 'board created';
    is $karr->( 'create', 'task that is safely pushed' )->{exit}, 0,
        'first task created and pushed';

    break_push("$work/a");

    my $created = $karr->( 'create', 'UNPUSHED WORK' );
    like $created->{stderr}, qr/Local refs are intact/,
        'karr says the local refs are intact';

    my $before = $karr->( 'list', '--compact' );
    like $before->{stdout}, qr/UNPUSHED WORK/, 'the work is on the board';

    is $karr->('sync', '--pull')->{exit}, 0, 'sync --pull succeeds';
    my $after = $karr->( 'list', '--compact' );
    like $after->{stdout}, qr/UNPUSHED WORK/,
        'sync --pull did not delete it';

    # Every writing command pulls through sync_before, so it has to survive
    # those too -- that path is wider than the filed reproduction.
    $karr->( 'edit', '1', '-a', 'note' );
    like $karr->( 'list', '--compact' )->{stdout}, qr/UNPUSHED WORK/,
        'a writing command did not delete it either';

    fix_push( "$work/a", $work );
    is $karr->('sync')->{exit}, 0, 'the retried sync succeeds';
    is_deeply [ grep { m{/tasks/} } @{ origin_board_refs($work) } ],
        [ 'refs/karr/tasks/1/data', 'refs/karr/tasks/2/data' ],
        'and the rescued task reaches the remote';
};

done_testing;
