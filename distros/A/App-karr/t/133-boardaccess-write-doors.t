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
use App::karr::Role::BoardAccess;
use App::karr::Cmd::Create;
use App::karr::Cmd::Delete;
use App::karr::Cmd::List;

# Regression for karr board ticket #120 -- the two write doors on
# Role::BoardAccess, both found while documenting the role for #118.
#
# 1. delete_task logged unconditionally. save_task returns early on a write
#    that did not land ("return $wrote unless $wrote") and never logs it;
#    delete_task called log_task_write whatever BoardStore::delete_task
#    answered, so deleting an id that was never there still appended to
#    refs/karr/log/*. Since #64 that log is what `karr log` and
#    `karr show --me` read, so the phantom delete was reported as an action
#    that happened. The entry has no room to say "attempted" -- agent, action,
#    task id -- so the guard belongs on delete_task too, and this file pins it.
#
# 2. save_config on the role was unreachable and would have corrupted the
#    board. Its no-argument fallback handed BoardStore::save_config the
#    `config` attribute from Role::BoardDiscovery, an App::karr::Config OBJECT,
#    where that method wants the plain effective-config hash (it reads
#    $effective->{version} and diffs the whole thing against the defaults).
#    It did not die on the mismatch: it wrote a refs/karr/config with the
#    blessed hash's `data` and `file` keys at the top level, burying the real
#    config -- board.name included -- under `data:`. Nothing called it, which
#    is the only reason no board was lost. The method is gone; config writes go
#    through $self->store->save_config($hash), as Cmd::Config and Cmd::Init do.

sub _board {
    my $repo = tempdir( CLEANUP => 1 );
    system( 'git', 'init', '-q', $repo ) == 0 or die "git init failed";
    system( 'git', '-C', $repo, 'config', 'user.email', 'dev@example.com' ) == 0
        or die "git config failed";
    system( 'git', '-C', $repo, 'config', 'user.name', 'Test User' ) == 0
        or die "git config failed";

    my $git = App::karr::Git->new( dir => $repo );
    $git->write_ref( 'refs/karr/config',
        Dump( { version => 1, board => { name => 'Doors' } } ) );
    $git->write_ref( 'refs/karr/meta/next-id', "1\n" );
    return ( $git, App::karr::BoardStore->new( git => $git ) );
}

sub _run_execute {
    my ( $cmd, @args ) = @_;
    my $out;
    my $err = do {
        local $@;
        eval {
            local ( *STDOUT, *STDERR );
            open STDOUT, '>', \$out  or die $!;
            open STDERR, '>', \my $e or die $!;
            $cmd->execute( \@args, [] );
        };
        $@;
    };
    return ( $err // '', $out );
}

sub _entries {
    my ($git) = @_;
    return App::karr::ActivityLog->new( git => $git )->entries;
}

sub _deletes_of {
    my ( $git, $id ) = @_;
    return grep { $_->{action} eq 'delete' && ( $_->{task_id} // -1 ) == $id }
        _entries($git);
}

subtest 'delete_task on an id that was never there writes no log entry' => sub {
    my ( $git, $store ) = _board();
    my $cmd = App::karr::Cmd::Delete->new( store => $store, yes => 1 );

    my $removed = $cmd->delete_task(999);
    ok( !$removed, 'the store reports that nothing was removed' );
    is( scalar( _entries($git) ), 0,
        'and the activity log stayed empty -- no delete of 999 to report' );
};

subtest 'delete_task logs the delete that did remove something' => sub {
    my ( $git, $store ) = _board();
    my ( $err ) = _run_execute( App::karr::Cmd::Create->new( store => $store ), 'Alpha' );
    is( $err, '', 'a task to delete is created' ) or diag $err;

    my $cmd = App::karr::Cmd::Delete->new( store => $store, yes => 1 );
    ok( $cmd->delete_task(1), 'deleting the task that exists succeeds' );
    is( scalar( _deletes_of( $git, 1 ) ), 1,
        'exactly one delete entry for task 1' );

    # The second call finds nothing left. Without the guard this is the shape
    # the log lied in: two deletes for one task.
    ok( !$cmd->delete_task(1), 'deleting it again removes nothing' );
    is( scalar( _deletes_of( $git, 1 ) ), 1,
        'and adds no second delete entry for the same task' );
};

subtest '`karr delete` on a missing id leaves no trace in the log' => sub {
    # The user-visible half: Cmd::Delete goes through delete_task_guarded, which
    # dies on the missing id before it logs. Pinned here so the two delete paths
    # keep answering alike.
    my ( $git, $store ) = _board();
    my ( $seed ) = _run_execute( App::karr::Cmd::Create->new( store => $store ), 'Alpha' );
    is( $seed, '', 'a task exists so the board is not empty' ) or diag $seed;

    my ( $err ) = _run_execute(
        App::karr::Cmd::Delete->new( store => $store, yes => 1 ), '99' );
    like( $err, qr/1 of 1 ids failed/, 'the batch reports the failure' );

    is( scalar( grep { $_->{action} eq 'delete' } _entries($git) ), 0,
        'no delete entry was written for the id that does not exist' );
};

subtest 'the role offers no config-write door of its own' => sub {
    my ( $git, $store ) = _board();
    my $cmd = App::karr::Cmd::List->new( store => $store );

    ok( !App::karr::Role::BoardAccess->can('save_config'),
        'Role::BoardAccess has no save_config' );
    ok( !$cmd->can('save_config'),
        'so a command composing it does not inherit one either' );
    ok( $store->can('save_config'),
        'the store keeps the single config-write choke point' );

    # Why re-adding the old fallback would be wrong: the two sides disagree on
    # the type. $self->config is the queryable object; save_config wants the
    # hash it was built from.
    isa_ok( $cmd->config, 'App::karr::Config',
        'the config attribute from Role::BoardDiscovery' );
    is( ref( $store->effective_config ), 'HASH',
        'while BoardStore::save_config takes the plain effective-config hash' );
};

done_testing;
