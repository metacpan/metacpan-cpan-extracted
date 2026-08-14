use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestGit qw( require_git_c );
require_git_c();
use File::Temp qw( tempdir );
use App::karr::Git;
use App::karr::Task;
use Git::Native::Remote;

# Ticket #95: the wholesale-wipe guard (#82) only catches a remote that lost
# every board ref -- not one that was swapped for a DIFFERENT, non-empty
# board. A stale clone, a re-initialised origin, a typo in the remote URL:
# reconciliation treated the foreign board as the truth and converged the
# local board onto it, silently and totally. The zero-ref check cannot fire
# for that, because the ref count is not zero.
#
# The fix is a board identity: refs/karr/meta/board-id, stamped at init and
# compared on every pull, before any reconciliation.
#
#   both sides stamped, ids differ    refuse (unless the caller opted in)
#   remote stamped, local not         adopt the remote's id (clone shape)
#   local stamped, remote not         a pre-change remote: keep the local id,
#                                     the push path re-arms the remote
#   neither stamped                   a pre-change board: proceed, and stamp
#                                     it so the guard is armed from then on
#
# Both transports are exercised for the guard proper, the same property t/73
# and t/85 pin for the rest of pull (#41).

my $ID_A = 'a' x 32;
my $ID_B = 'b' x 32;

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

# The ref content, normalized the way the comparison normalizes it. Read
# directly rather than through the new accessor, so this file fails as a
# regression test on unfixed code instead of dying on a missing method.
sub board_id_of {
    my ($git) = @_;
    my $raw = $git->read_ref('refs/karr/meta/board-id') // '';
    $raw =~ s/\s+//g;
    return length $raw ? $raw : undef;
}

sub origin_board_id {
    my ($work) = @_;
    my $raw = `git -C '$work/origin.git' cat-file blob refs/karr/meta/board-id:data 2>/dev/null`;
    chomp $raw;
    return length $raw ? $raw : undef;
}

# A board stamped the way a current karr init stamps it, published by A and
# synced once by B -- so B's mirror holds the remote as it was and B has
# adopted the board's identity.
sub stamped_board {
    my ($transport) = @_;
    my ( $work, $a, $b ) = two_clones();
    $a->write_ref( 'refs/karr/config',        "board:\n  name: demo\n" );
    $a->write_ref( 'refs/karr/meta/next-id',  "3\n" );
    $a->write_ref( 'refs/karr/meta/board-id', "$ID_A\n" );
    $a->save_task_ref( task( $_, "Task $_" ) ) for 1 .. 2;
    $a->push or die 'A could not publish the board';
    with_transport( $transport, sub { $b->pull } ) or die 'B could not sync';
    return ( $work, $a, $b, [ sort $b->list_refs('refs/karr/') ] );
}

# The accident from #95: origin is readable, answers cleanly, and holds a
# whole board -- just not this one.
sub swap_in_foreign_board {
    my ($work) = @_;
    system("rm -rf '$work/origin.git'");
    system( 'git', 'init', '-q', '--bare', "$work/origin.git" );
    system("git clone -q '$work/origin.git' '$work/foreign' 2>/dev/null");
    system( 'git', '-C', "$work/foreign", 'config', 'user.email',
        'f@karr.test' );
    system( 'git', '-C', "$work/foreign", 'config', 'user.name', 'agent-f' );
    my $f = App::karr::Git->new( dir => "$work/foreign" );
    $f->write_ref( 'refs/karr/config',        "board:\n  name: foreign\n" );
    $f->write_ref( 'refs/karr/meta/board-id', "$ID_B\n" );
    $f->save_task_ref( task( 77, 'Foreign task' ) );
    $f->push or die 'the foreign board could not be published';
    return;
}

for my $transport (qw( native cli )) {
    subtest "$transport transport: a swapped remote is refused before reconciliation" => sub {
        my ( $work, $a, $b, $before ) = stamped_board($transport);
        is board_id_of($b), $ID_A, 'setup: B carries the board identity';

        swap_in_foreign_board($work);

        my $rv  = eval { with_transport( $transport, sub { $b->pull } ) };
        my $err = $@;
        ok !$rv, 'the pull does not quietly report success';
        like $err, qr/refusing to sync/,
            'it refuses, instead of converging onto the foreign board';
        like $err, qr/different board/, 'and says what the remote turned into';
        like $err, qr/karr sync --push/,
            'and names the republish way through';
        like $err, qr/accept-foreign-board/,
            'and the deliberate adoption way through';
        is_deeply [ sort $b->list_refs('refs/karr/') ], $before,
            'every board ref is still there';
        is board_id_of($b), $ID_A, 'and the identity was not rewritten';

        # The refusal has to be repeatable: the mirror is rolled back, so the
        # next pull sees the same foreign board and refuses again.
        my $again = eval { with_transport( $transport, sub { $b->pull } ) };
        ok !$again, 'the second pull refuses too, rather than passing silently';
        is_deeply [ sort $b->list_refs('refs/karr/') ], $before,
            'and the board is still intact after it';
    };

    subtest "$transport transport: the opted-in pull adopts the foreign board" => sub {
        my ( $work, $a, $b ) = stamped_board($transport);
        swap_in_foreign_board($work);

        my $rv = eval {
            with_transport( $transport,
                sub { $b->pull( 'origin', accept_foreign => 1 ) } );
        };
        ok $rv, 'the caller that opted in gets the reconciliation'
            or diag $@;
        is board_id_of($b), $ID_B, "the remote's identity is adopted with its board";
        ok $b->ref_exists('refs/karr/tasks/77/data'),
            'the foreign content is here';
        ok !$b->ref_exists('refs/karr/tasks/1/data'),
            'and the old board content is gone';

        my $next = eval { with_transport( $transport, sub { $b->pull } ) };
        ok $next, 'the standoff is over: the next plain pull is fine again';
    };

    subtest "$transport transport: a fresh remote is not a foreign board" => sub {
        my ( $work, $a ) = two_clones();
        $a->write_ref( 'refs/karr/config',        "board:\n  name: fresh\n" );
        $a->write_ref( 'refs/karr/meta/board-id', "$ID_A\n" );
        $a->save_task_ref( task( 1, 'Local only' ) );

        my $rv = eval { with_transport( $transport, sub { $a->pull } ) };
        ok $rv, 'a pull against an empty remote proceeds' or diag $@;
        is_deeply [ sort $a->list_refs('refs/karr/') ],
            [ sort qw(
                refs/karr/config
                refs/karr/meta/board-id
                refs/karr/tasks/1/data
            ) ],
            'the never-pushed board is untouched';

        ok $a->push, 'and the push publishes it';
        is origin_board_id($work), $ID_A,
            'including the identity, arming the remote';
    };

    subtest "$transport transport: a pre-change board proceeds and gets stamped" => sub {
        my ( $work, $a, $b ) = two_clones();
        # The shape every board had before identities existed: no board-id
        # ref on either side.
        $a->write_ref( 'refs/karr/config',       "board:\n  name: old\n" );
        $a->write_ref( 'refs/karr/meta/next-id', "3\n" );
        $a->save_task_ref( task( $_, "Task $_" ) ) for 1 .. 2;
        $a->push or die 'A could not publish the pre-change board';

        my $rv = eval { with_transport( $transport, sub { $b->pull } ) };
        ok $rv, 'the pull proceeds -- no identities anywhere to conflict'
            or diag $@;
        my $stamped = board_id_of($b);
        ok defined $stamped, 'B stamped the board on the way through';
        like $stamped, qr/\A[0-9a-f]{32}\z/, 'and the stamp looks like an id';
        ok $b->ref_exists('refs/karr/tasks/2/data'),
            'and the board content is untouched';

        ok $b->push, 'B pushes';
        is origin_board_id($work), $stamped,
            'the normal push path carried the stamp to the remote';

        my $back = eval { with_transport( $transport, sub { $a->pull } ) };
        ok $back, 'A pulls the now-stamped board without a refusal';
        is board_id_of($a), $stamped,
            'and adopts the identity rather than stamping its own';
    };

    subtest "$transport transport: a remote that lost its stamp is re-armed, not refused" => sub {
        my ( $work, $a, $b ) = stamped_board($transport);

        # A pre-change karr's forced, pruning push drops the stamp off the
        # remote while the rest of the board stays. That remote is still this
        # board -- so the pull must neither refuse nor let reconciliation read
        # the missing ref as "the remote deleted the identity".
        system( 'git', '-C', "$work/origin.git", 'update-ref', '-d',
            'refs/karr/meta/board-id' );

        my $rv = eval { with_transport( $transport, sub { $b->pull } ) };
        ok $rv, 'the pull proceeds' or diag $@;
        is board_id_of($b), $ID_A, "B's identity survived the pull";

        ok $b->push, 'B pushes';
        is origin_board_id($work), $ID_A,
            'and the remote carries the same stamp again';
    };

    subtest "$transport transport: nothing anywhere stamps nothing" => sub {
        my ( $work, $a, $b ) = two_clones();
        my $rv = eval { with_transport( $transport, sub { $b->pull } ) };
        ok $rv, 'an empty pull from an empty remote succeeds' or diag $@;
        is_deeply [ $b->list_refs('refs/karr/') ], [],
            'and no stray identity ref is left on a board that does not exist';
    };
}

done_testing;
