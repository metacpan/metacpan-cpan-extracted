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
use App::karr::ActivityLog;

plan skip_all => 'fork is not available on this platform'
    unless $Config{d_fork};

# Ticket #156: ActivityLog::log_entry did a read-modify-write on the log ref
# with no CAS guard. Two processes that took the same identity ref would
# both read the same existing content, both append their own line, and both
# write the result -- the loser overwrites the winner's entry, and the log
# loses a record of something the task itself already happened. The bug is
# only visible under concurrent writers, so this test has to fork.
my $CONTENDERS = 12;

sub init_repo {
    my $repo = tempdir( CLEANUP => 1 );
    system( 'git', 'init', '-q', $repo ) == 0
        or BAIL_OUT('git init failed');
    system( 'git', '-C', $repo, 'config', 'user.email', 'test@example.com' ) == 0
        or BAIL_OUT('git config failed');
    system( 'git', '-C', $repo, 'config', 'user.name', 'Test User' ) == 0
        or BAIL_OUT('git config failed');
    # The board has to be initialised before any log entry has a ref to land
    # in -- log_entry writes to refs/karr/log/<role>/<encoded_email>, and an
    # empty repo has no committed yet.
    my $git = App::karr::Git->new( dir => $repo );
    $git->write_ref( 'refs/karr/meta/next-id', "1\n" );
    return $repo;
}

# Fork $CONTENDERS children and have them enter the critical section at the
# same wall-clock instant. $body is called as ($n, $barrier); everything before
# $barrier->() is warm-up, and only what follows it races. Without that split
# the children queue up behind each other's first libgit2 call and the
# contention window never opens.
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

subtest 'parallel log_entry keeps every entry' => sub {
    my $repo = init_repo();
    # Warm libgit2 up in the parent so every child inherits it initialised
    # and the barrier is the only thing gating them.
    App::karr::Git->new( dir => $repo )->ref_exists('refs/karr/meta/next-id');

    my @lines = race( sub {
        my ( $n, $barrier ) = @_;
        my $log = App::karr::ActivityLog->new(
            git => App::karr::Git->new( dir => $repo ) );
        $barrier->();
        my $ok = $log->log_entry(
            agent   => "agent-$n",
            action  => 'create',
            task_id => $n,
            detail  => 'backlog',
        );
        return $ok ? "logged $n" : "lost $n";
    } );

    my @logged = grep { /\Alogged \d+\z/ } @lines;
    my @lost   = grep { /\Alost \d+\z/ } @lines;
    my @broken = grep { !/\A(?:logged|lost) \d+\z/ } @lines;

    is_deeply \@broken, [],
        'no contender died on a raw libgit2 error instead of getting an answer'
        or diag join "\n", 'results:', @lines;

    is scalar @lost, 0,
        'no log_entry reported a lost write'
        or diag join "\n", 'results:', @lines;

    is scalar @logged, $CONTENDERS,
        "all $CONTENDERS log_entry calls returned success"
        or diag join "\n", 'results:', @lines;

    # The actual ticket #156 failure: only one entry in the ref after N
    # writers, because every loser overwrote the winner's append.
    my $git = App::karr::Git->new( dir => $repo );
    my $log = App::karr::ActivityLog->new( git => $git );
    my @entries = $log->entries;
    is scalar @entries, $CONTENDERS,
        'the log ref holds every entry its writers thought they appended'
        or diag join "\n", 'stored entries:', map { $_->{action} . ' ' . $_->{task_id} } @entries;

    my %seen;
    $seen{$_->{task_id}}++ for @entries;
    my @dupes = sort { $a <=> $b } grep { $seen{$_} > 1 } keys %seen;
    is_deeply \@dupes, [],
        'no entry was written twice by a retry loop'
        or diag join "\n", "duplicated: @dupes";

    is_deeply [ sort { $a <=> $b } map { $_->{task_id} } @entries ],
        [ 1 .. $CONTENDERS ],
        'every task_id 1..N appears exactly once';
};

subtest 'log_entry keeps its single-process contract' => sub {
    # The CAS guard should be invisible to the single-writer case -- nobody
    # ever sees a "lost write" because no one was racing to win.
    my $repo = init_repo();
    my $log = App::karr::ActivityLog->new(
        git => App::karr::Git->new( dir => $repo ) );

    ok $log->log_entry( agent => 'alpha', action => 'edit',   task_id => 1, detail => 'backlog'  ),
        'the first entry writes';
    ok $log->log_entry( agent => 'alpha', action => 'move',   task_id => 1, detail => 'in-progress' ),
        'the second entry writes';
    ok $log->log_entry( agent => 'alpha', action => 'edit',   task_id => 1, detail => 'in-progress' ),
        'the third entry writes';

    my @entries = $log->entries;
    is scalar @entries, 3, 'all three entries land in the ref';
    is_deeply [ map { $_->{action} } @entries ], [ 'edit', 'move', 'edit' ],
        'the entries come back in the order they were appended';
};

done_testing;
