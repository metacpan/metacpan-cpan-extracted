use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestGit qw( require_git_c );
require_git_c();
use File::Temp qw( tempdir );
use YAML::XS qw( Dump );

use App::karr::Git;
use App::karr::BoardStore;
use App::karr::ActivityLog;
use App::karr::Cmd::Create;
use App::karr::Cmd::Move;
use App::karr::Cmd::Edit;
use App::karr::Cmd::Handoff;
use App::karr::Cmd::Archive;
use App::karr::Cmd::Delete;
use App::karr::Cmd::Pick;
use App::karr::Cmd::Log;

# Regression for karr board ticket #64:
#   `grep -rn append_log lib/` found exactly one call site, Cmd/Pick.pm, so the
#   activity log was written by `pick` and by nothing else:
#
#     karr create a; karr move 1 todo; karr edit 1 -a note; karr archive 1
#     karr log   -> "No log entries."
#
#   `karr log`, `karr show --me/--agent` and anything else reading
#   refs/karr/log/* therefore ran on an almost empty log and looked correct
#   while doing it.
#
#   The mechanism is now in the shared write path -- Role::BoardAccess's
#   save_task/delete_task, which every mutating command already funnels
#   through -- so a command is logged because it wrote, not because it
#   remembered to call append_log. This test drives the real command classes
#   so a new mutating command that skips the funnel shows up here.

sub _init_repo {
    my $repo = tempdir( CLEANUP => 1 );
    system( 'git', 'init', '-q', $repo );
    system( 'git', '-C', $repo, 'config', 'user.email', 'dev@example.com' );
    system( 'git', '-C', $repo, 'config', 'user.name', 'Test User' );
    return $repo;
}

sub _run_execute {
    my ( $cmd, @args ) = @_;
    my $out;
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

my $repo = _init_repo();
my $git  = App::karr::Git->new( dir => $repo );
$git->write_ref( 'refs/karr/config', Dump( { version => 1, board => { name => 'T' } } ) );
$git->write_ref( 'refs/karr/meta/next-id', "1\n" );
my $store = App::karr::BoardStore->new( git => $git );

sub _entries {
    return App::karr::ActivityLog->new( git => $git )->entries;
}

sub _actions_for {
    my ($task_id) = @_;
    return map  { $_->{action} }
           grep { ( $_->{task_id} // 0 ) == $task_id } _entries();
}

subtest 'every mutating command writes an entry' => sub {
    my @runs = (
        [ 'create',  App::karr::Cmd::Create->new( store => $store ), 'Alpha' ],
        [ 'create',  App::karr::Cmd::Create->new( store => $store ), 'Beta' ],
        [ 'move',    App::karr::Cmd::Move->new( store => $store ), 1, 'todo' ],
        [ 'edit',    App::karr::Cmd::Edit->new( store => $store, append_body => 'a note' ), 1 ],
        [ 'handoff', App::karr::Cmd::Handoff->new( store => $store, claim => 'reviewer' ), 1 ],
        [ 'archive', App::karr::Cmd::Archive->new( store => $store ), 2 ],
        [ 'delete',  App::karr::Cmd::Delete->new( store => $store, yes => 1 ), 2 ],
    );

    for my $run (@runs) {
        my ( $action, $cmd, @args ) = @$run;
        my ( $err, undef ) = _run_execute( $cmd, @args );
        is( $err, '', "$action executes cleanly" ) or diag("died with: $err");
    }

    is_deeply( [ _actions_for(1) ], [ 'create', 'move', 'edit', 'handoff' ],
        'task 1: create, move, edit and handoff all logged, in order' );
    is_deeply( [ _actions_for(2) ], [ 'create', 'archive', 'delete' ],
        'task 2: create, archive and delete all logged, in order' );
};

subtest 'entries carry the acting agent and the resulting status' => sub {
    my %by_action = map { $_->{action} => $_ } _entries();

    is( $by_action{handoff}{agent}, 'reviewer',
        'a command with --claim is attributed to the claim' );
    is( $by_action{handoff}{detail}, 'review',
        'and records the status the task ended up in' );
    is( $by_action{create}{agent}, 'Test User',
        'a command without --claim falls back to the Git identity' );
    is( $by_action{archive}{detail}, 'archived', 'archive records the new status' );

    ok( ( grep { defined $_->{ts} && length $_->{ts} } _entries() ) == scalar( _entries() ),
        'every entry is timestamped' );
};

subtest 'pick logs its mutation exactly once' => sub {
    # Task 1 is claimed by the handoff above and task 2 is gone, so give pick
    # something unclaimed to find.
    _run_execute( App::karr::Cmd::Create->new( store => $store ), 'Gamma' );

    my $cmd = App::karr::Cmd::Pick->new(
        store => $store,
        claim => 'agent-fox',
        move  => 'in-progress',
    );
    my ( $err, $out ) = _run_execute($cmd);
    is( $err, '', 'pick executes cleanly' ) or diag("died with: $err");
    like( $out, qr/Picked task 3/, 'pick took the free task' );

    # Pick saves the task (logged by the shared write path) *and* calls
    # append_log itself; the second must not become a duplicate entry.
    my @picks = grep { ( $_->{action} // '' ) eq 'pick' } _entries();
    is( scalar @picks, 1, 'exactly one pick entry' );
    is( $picks[0]{agent},  'agent-fox',   'attributed to the picking agent' );
    is( $picks[0]{detail}, 'in-progress', 'with the status pick moved it to' );
};

subtest 'karr log renders what the commands wrote' => sub {
    my ( $err, $out ) = _run_execute( App::karr::Cmd::Log->new( store => $store ) );
    is( $err, '', 'log executes cleanly' ) or diag("died with: $err");
    unlike( $out, qr/No log entries/, 'the log is no longer empty' );
    for my $action (qw( create move edit handoff archive delete pick )) {
        like( $out, qr/\b\Q$action\E\b/, "`karr log` shows the $action entry" );
    }
};

subtest 'bulk restore paths stay out of the log' => sub {
    my $before = scalar _entries();
    # import/restore reinstate state verbatim through BoardStore, below the
    # role that logs, so they must not flood the log with one entry per task.
    $store->save_task( $store->find_task(1) );
    is( scalar _entries(), $before, 'a direct BoardStore write is not logged' );
};

done_testing;
