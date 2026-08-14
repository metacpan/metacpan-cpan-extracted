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

# Ticket #82: a remote that is empty for the wrong reason reconciled the whole
# board away.
#
# Since the tracking mirror landed (#40/#49), "the remote had these refs at the
# last sync and does not have them now" is a well-founded observation, and
# acting on it is what makes a delete propagate across clones. It is also
# exactly what these look like:
#
#   * origin re-created or re-initialised
#   * the remote URL edited to point somewhere else
#   * a hosting-side restore that rolled the namespace back
#
# In each of those, a routine writing command reconciled the local board down
# to nothing, in one step, silently. Nothing in the refs can tell them apart
# from a deliberate `karr destroy`, so the wholesale case -- and only that one
# -- now stops and asks. Everything else still reconciles unattended.
#
# Both transports are exercised: reconciliation is one code path in local Perl
# code, but that is a property worth pinning rather than assuming (#41).

sub two_clones {
    my $work = tempdir( CLEANUP => 1 );
    system( 'git', 'init', '-q', '--bare', "$work/origin.git" );
    my @git;
    for my $name (qw( a b )) {
        system("git clone -q '$work/origin.git' '$work/$name' 2>/dev/null");
        system( 'git', '-C', "$work/$name", 'config', 'user.email',
            "$name\@karr.test" );
        system( 'git', '-C', "$work/$name", 'config', 'user.name', "agent-$name" );
        push @git, App::karr::Git->new( dir => "$work/$name" );
    }
    return ( $work, @git );
}

sub task {
    my ( $id, $title, $body ) = @_;
    return App::karr::Task->new(
        id => $id, title => $title, status => 'todo',
        priority => 'high', class => 'standard', body => $body // '',
    );
}

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

# A published board on A, synced once by B, so B's mirror holds the remote as
# it was. Returns the pair plus the ref names B is carrying. The board carries
# the identity stamp a current karr init writes (#95); B adopts it on the
# first pull, which is why the ref count below is 6, not 5.
sub published_board {
    my ($transport) = @_;
    my ( $work, $a, $b ) = two_clones();
    $a->write_ref( 'refs/karr/config',        "board:\n  name: demo\n" );
    $a->write_ref( 'refs/karr/meta/next-id',  "4\n" );
    $a->write_ref( 'refs/karr/meta/board-id', 'a' x 32 . "\n" );
    $a->save_task_ref( task( $_, "Task $_" ) ) for 1 .. 3;
    $a->push or die 'A could not publish the board';
    with_transport( $transport, sub { $b->pull } ) or die 'B could not sync';
    return ( $work, $a, $b, [ sort $b->list_refs('refs/karr/') ] );
}

# The accident: origin is readable, answers cleanly, and has no karr refs --
# because it is not the origin it was.
sub recreate_origin {
    my ($work) = @_;
    system("rm -rf '$work/origin.git'");
    system( 'git', 'init', '-q', '--bare', "$work/origin.git" );
    return;
}

for my $transport (qw( native cli )) {
    subtest "$transport transport: a re-created origin does not wipe the board" => sub {
        my ( $work, $a, $b, $before ) = published_board($transport);
        is scalar(@$before), 6, 'B carries the whole board before the accident';

        recreate_origin($work);

        my $rv  = eval { with_transport( $transport, sub { $b->pull } ) };
        my $err = $@;
        ok !$rv, 'the pull does not quietly report success';
        like $err, qr/refusing to sync/,
            'it refuses, instead of applying the deletion';
        like $err, qr/would delete the whole board/,
            'and says what it was about to do';
        like $err, qr/karr sync --prune/,
            'and how to go through with it if that is really what is wanted';
        is_deeply [ sort $b->list_refs('refs/karr/') ], $before,
            'every board ref is still there';

        # The refusal has to be repeatable. If the emptied mirror were left in
        # place, the next pull would read the whole board as unpushed local
        # work, keep it -- and then push it back at whatever origin now is.
        my $again = eval { with_transport( $transport, sub { $b->pull } ) };
        ok !$again, 'the second pull refuses too, rather than passing silently';
        is_deeply [ sort $b->list_refs('refs/karr/') ], $before,
            'and the board is still intact after it';
    };

    subtest "$transport transport: --prune goes through with it" => sub {
        my ( $work, $a, $b, $before ) = published_board($transport);
        recreate_origin($work);

        my $rv = eval {
            with_transport( $transport, sub { $b->pull( 'origin', accept_wipe => 1 ) } );
        };
        ok $rv, 'the caller that opted in gets the reconciliation';
        is_deeply [ sort $b->list_refs('refs/karr/') ], [],
            'and the board is reconciled away as asked';
    };

    subtest "$transport transport: a partial deletion is not the guarded case" => sub {
        my ( $work, $a, $b ) = published_board($transport);

        $a->delete_ref('refs/karr/tasks/2/data');
        $a->delete_ref('refs/karr/tasks/3/data');
        ok $a->push, 'A deletes two of the three tasks and pushes';

        my $rv = eval { with_transport( $transport, sub { $b->pull } ) };
        ok $rv, 'B pulls without being stopped';
        ok !$b->ref_exists('refs/karr/tasks/2/data'),
            'the deletions still propagate (#49)';
        ok $b->ref_exists('refs/karr/tasks/1/data'),
            'and the surviving task is untouched';
    };

    # The boundary the guard must not cross. A deletion that reaches a ref
    # this clone had edited is case 4: the local version is parked under
    # refs/karr-conflict/ and the user is warned, so it is neither silent nor
    # unrecoverable — the two things the guard exists for. Counting it would
    # block the ordinary "the remote dropped the task I was editing" case on
    # any board small enough for that to be the last ref (t/73 case 4b).
    subtest "$transport transport: a parked, warned deletion is not a wipe" => sub {
        my ( $work, $a, $b ) = two_clones();
        $a->save_task_ref( task( 1, 'Only task', 'base' ) );
        ok $a->push, 'A publishes a board whose only ref is one task';
        ok with_transport( $transport, sub { $b->pull } ), 'B syncs';

        $a->delete_ref('refs/karr/tasks/1/data');
        ok $a->push, 'A deletes it, leaving the remote with no karr refs';
        $b->save_task_ref( task( 1, 'Only task', 'edited by B' ) );

        my @warned;
        my $rv = eval {
            local $SIG{__WARN__} = sub { push @warned, $_[0] };
            with_transport( $transport, sub { $b->pull } );
        };
        ok $rv, 'the pull is not refused';
        ok !$b->ref_exists('refs/karr/tasks/1/data'), 'the deletion is applied';
        like join( '', @warned ), qr/both changed/,
            'because it was announced instead of happening silently';
        like $b->read_ref('refs/karr-conflict/origin/tasks/1/data'),
            qr/edited by B/, 'and the local version is still recoverable';
    };

    subtest "$transport transport: unpushed local work is not a wipe either" => sub {
        my ( $work, $a, $b ) = published_board($transport);

        # B has work the remote has never seen; the remote then goes wrong.
        # The board does not go to zero here (case 3 keeps the unpushed ref),
        # so the guard must not fire -- the loud stop belongs to the total
        # loss, not to every unlucky pull.
        $b->save_task_ref( task( 9, 'UNPUSHED WORK' ) );
        recreate_origin($work);

        my $rv = eval { with_transport( $transport, sub { $b->pull } ) };
        ok $rv, 'the pull completes';
        ok $b->ref_exists('refs/karr/tasks/9/data'),
            'and the unpushed task survives it';
    };
}

# ---------------------------------------------------------------------
# The legitimate path, end to end through the CLI: a `karr destroy` on one
# clone still reaches another one. It is no longer silent -- that is the
# whole point -- but it must still be reachable.
# ---------------------------------------------------------------------
subtest 'end to end: karr destroy on one clone still propagates to another' => sub {
    my $root = abs_path('.');
    my $bin  = "$root/bin/karr";

    my $work = tempdir( CLEANUP => 1 );
    system( 'git', 'init', '-q', '--bare', "$work/origin.git" );
    for my $name (qw( a b )) {
        system("git clone -q '$work/origin.git' '$work/$name' 2>/dev/null");
        system( 'git', '-C', "$work/$name", 'config', 'user.email',
            "$name\@karr.test" );
        system( 'git', '-C', "$work/$name", 'config', 'user.name', "agent-$name" );
    }

    my $karr = sub {
        my ( $clone, @argv ) = @_;
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

    is $karr->( 'a', 'init', '--name', 'demo' )->{exit}, 0, 'A creates the board';
    is $karr->( 'a', 'create', 'Shared task' )->{exit}, 0, 'A creates a task';
    is $karr->( 'b', 'sync', '--pull' )->{exit}, 0, 'B syncs the board in';
    like $karr->( 'b', 'list', '--compact' )->{stdout}, qr/Shared task/,
        'B has the board';

    is $karr->( 'a', 'destroy', '--yes' )->{exit}, 0, 'A destroys the board';

    # B's next writing command stops instead of losing the board behind the
    # user's back -- the same refusal, reached through the CLI.
    my $blocked = $karr->( 'b', 'create', 'Another task' );
    isnt $blocked->{exit}, 0, 'a writing command on B fails instead of wiping';
    like $blocked->{stderr}, qr/refusing to sync/, 'and says why';
    like $karr->( 'b', 'list', '--compact' )->{stdout}, qr/Shared task/,
        'B still has its board while the question is open';

    my $pruned = $karr->( 'b', 'sync', '--prune' );
    is $pruned->{exit}, 0, 'karr sync --prune succeeds';
    my $gone = App::karr::Git->new( dir => "$work/b" );
    is_deeply [ sort $gone->list_refs('refs/karr/') ], [],
        'and the destroy has propagated to B';
};

# The other way out: the remote was wrong, so republish this board over it.
subtest 'end to end: karr sync --push republishes instead of accepting the loss' => sub {
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
    is $karr->( 'create', 'Precious task' )->{exit}, 0, 'and published';

    recreate_origin($work);

    my $blocked = $karr->( 'create', 'Second task' );
    isnt $blocked->{exit}, 0, 'the accident stops the next writing command';

    is $karr->( 'sync', '--push' )->{exit}, 0, 'sync --push republishes the board';
    my @remote =
      `git -C '$work/origin.git' for-each-ref --format='%(refname)' 'refs/karr/'`;
    chomp @remote;
    ok scalar( grep { m{tasks/1/data} } @remote ),
        'the board is back on the remote';

    # And the standoff is over: ordinary commands work again.
    is $karr->( 'create', 'Third task' )->{exit}, 0,
        'writing commands resume once the remote agrees again';
};

done_testing;
