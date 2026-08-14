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

use App::karr::Git;
use App::karr::BoardStore;
use App::karr::Lock;

plan skip_all => 'fork is not available on this platform'
    unless $Config{d_fork};

# Both bugs under test are races, so a single-process call proves nothing:
# the old read-then-write code is perfectly correct when nothing else is
# running. These have to be real concurrent processes.
my $CONTENDERS = 12;

sub init_repo {
    my $repo = tempdir( CLEANUP => 1 );
    system( 'git', 'init', '-q', $repo ) == 0
        or BAIL_OUT('git init failed');
    system( 'git', '-C', $repo, 'config', 'user.email', 'test@example.com' ) == 0
        or BAIL_OUT('git config failed');
    system( 'git', '-C', $repo, 'config', 'user.name', 'Test User' ) == 0
        or BAIL_OUT('git config failed');
    return $repo;
}

# Fork $CONTENDERS children and have them enter the critical section at the
# same wall-clock instant. $body is called as ($n, $barrier): everything before
# $barrier->() is warm-up, and only what follows it races. Without that split
# the children queue up behind each other's first libgit2 call and the window
# never opens.
#
# Each child reports one line through a file; children never touch TAP.
sub race {
    my ( $body ) = @_;
    my $out   = path( tempdir( CLEANUP => 1 ) );
    my $start = Time::HiRes::time() + 0.4;

    my @pids;
    for my $n ( 1 .. $CONTENDERS ) {
        my $pid = fork;
        BAIL_OUT("fork failed: $!") unless defined $pid;
        if ( !$pid ) {
            my $line = eval {
                $body->( $n, sub {
                    my $left = $start - Time::HiRes::time();
                    Time::HiRes::sleep($left) if $left > 0;
                } );
            };
            $line = "died: $@" unless defined $line;
            $line =~ s/\s+/ /g;
            $out->child($n)->spew_utf8("$line\n");
            # _exit, not exit: a child that ran Test::More's END block would
            # print a second TAP stream into the parent's.
            POSIX::_exit(0);
        }
        push @pids, $pid;
    }
    waitpid $_, 0 for @pids;

    return map {
        my $file = $out->child($_);
        if ( $file->exists ) { my $l = $file->slurp_utf8; chomp $l; $l }
        else                 { "vanished without a result" }
    } 1 .. $CONTENDERS;
}

subtest 'parallel allocate_next_id never hands out the same id twice' => sub {
    my $repo = init_repo();
    # Warm libgit2 up in the parent so every child inherits it initialised and
    # the barrier is the only thing gating them.
    App::karr::Git->new( dir => $repo )->ref_exists('refs/karr/meta/next-id');

    my @lines = race( sub {
        my ( $n, $barrier ) = @_;
        my $store = App::karr::BoardStore->new(
            git => App::karr::Git->new( dir => $repo ) );
        $store->peek_next_id;
        $barrier->();
        return $store->allocate_next_id;
    } );

    my @ids = grep { /\A\d+\z/ } @lines;
    is scalar @ids, $CONTENDERS,
        "all $CONTENDERS allocations came back with an id"
        or diag join "\n", 'results:', @lines;

    my %seen;
    $seen{$_}++ for @ids;
    my @dupes = sort { $a <=> $b } grep { $seen{$_} > 1 } keys %seen;
    is_deeply \@dupes, [], 'no id was handed to two agents at once'
        or diag join "\n", "duplicated: @dupes", 'results:', @lines;

    is_deeply [ sort { $a <=> $b } @ids ], [ 1 .. $CONTENDERS ],
        'the ids handed out are exactly 1..N, with no gaps and no repeats';

    my $store = App::karr::BoardStore->new(
        git => App::karr::Git->new( dir => $repo ) );
    is $store->peek_next_id, $CONTENDERS + 1,
        'the counter ends up one past the last id it handed out';
};

subtest 'parallel Lock::acquire has exactly one winner' => sub {
    my $repo = init_repo();
    my $git  = App::karr::Git->new( dir => $repo );
    $git->ref_exists( App::karr::Lock->LOCK_ROOT . '1/lock' );

    my @lines = race( sub {
        my ( $n, $barrier ) = @_;
        my $lock = App::karr::Lock->new(
            git => App::karr::Git->new( dir => $repo ) );
        $lock->get(1);
        $barrier->();
        my ( $ok, $msg ) = $lock->acquire( 1, "agent-$n\@test.com" );
        return join ' ', ( $ok ? 'acquired' : 'denied' ), $n, $msg;
    } );

    my @acquired = grep { /\Aacquired / } @lines;
    my @denied   = grep { /\Adenied / } @lines;
    my @broken   = grep { !/\A(?:acquired|denied) / } @lines;

    is_deeply \@broken, [],
        'no contender died on a raw libgit2 error instead of getting an answer'
        or diag join "\n", 'results:', @lines;

    is scalar @acquired, 1, 'exactly one contender was told it acquired the lock'
        or diag join "\n", 'results:', @lines;

    is scalar @denied, $CONTENDERS - 1,
        'every other contender was cleanly denied'
        or diag join "\n", 'results:', @lines;

    is scalar( grep { /\Adenied \d+ locked by agent-\d+\@test\.com\z/ } @denied ),
        scalar @denied, 'each denial names the agent actually holding the lock';

    # The point of #46: three processes were told "acquired" while the ref could
    # only hold one of them. Comparing the ref against the set of self-declared
    # winners catches that even if the counts above were somehow satisfied.
    my $holder = $git->read_ref( App::karr::Lock->LOCK_ROOT . '1/lock' );
    is_deeply [$holder],
        [ map { my $n = ( split ' ', $_ )[1]; "agent-$n\@test.com" } @acquired ],
        'the lock ref holds exactly the one contender that was told it won';
};

subtest 'acquire keeps its single-process contract' => sub {
    my $repo = init_repo();
    my $lock = App::karr::Lock->new(
        git => App::karr::Git->new( dir => $repo ) );

    my ( $ok, $msg ) = $lock->acquire( 4, 'a@test.com' );
    ok $ok, 'an unheld lock is acquired';

    ( $ok, $msg ) = $lock->acquire( 4, 'a@test.com' );
    ok $ok, 'the holder may re-acquire its own lock';

    ( $ok, $msg ) = $lock->acquire( 4, 'b@test.com' );
    ok !$ok, 'another agent is refused';
    is $msg, 'locked by a@test.com', 'the refusal names the holder';

    $lock->release( 4, 'a@test.com' );
    ( $ok, $msg ) = $lock->acquire( 4, 'b@test.com' );
    ok $ok, 'the lock is available again after release';
};

subtest 'write_ref_cas only writes when the ref is where it was left' => sub {
    my $repo = init_repo();
    my $git  = App::karr::Git->new( dir => $repo );
    my $ref  = 'refs/karr/meta/cas-probe';

    is $git->write_ref_cas( $ref, "one\n", undef ), 1,
        'create-if-absent writes an absent ref';
    is $git->write_ref_cas( $ref, "two\n", undef ), 0,
        'create-if-absent is refused once the ref exists';
    is $git->read_ref($ref), 'one', 'the refused create did not land';

    my ( $oid, $value ) = $git->read_ref_with_oid($ref);
    like $oid, qr/\A[0-9a-f]{40}\z/, 'read_ref_with_oid returns the target OID';
    is $value, 'one', '...together with the content of that same commit';

    is $git->write_ref_cas( $ref, "three\n", $oid ), 1,
        'an update guarded by the current OID lands';
    is $git->write_ref_cas( $ref, "four\n", $oid ), 0,
        'the same guard a second time is refused';
    is $git->read_ref($ref), 'three', 'the stale update did not land';

    my $before = $git->pending_writes;
    is $git->write_ref_cas( $ref, "five\n", 'dead' x 10 ), 0,
        'a guard that never matched is refused';
    is $git->pending_writes, $before,
        'a refused write is not counted as a pending write';

    is_deeply [ $git->read_ref_with_oid('refs/karr/meta/absent') ], [ undef, '' ],
        'an absent ref reads back as (undef, empty)';
};

done_testing;
