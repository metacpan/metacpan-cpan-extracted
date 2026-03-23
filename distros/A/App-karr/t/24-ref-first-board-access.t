use strict;
use warnings;
use Test::More;
use File::Temp qw( tempdir );
use Path::Tiny qw( path );
use YAML::XS qw( Dump );

use App::karr::Git;
use App::karr::Role::BoardAccess;

{
    package TestBoard;
    use Moo;
    with 'App::karr::Role::BoardAccess';
    has dir => ( is => 'ro', required => 1 );
    has has_dir => ( is => 'ro', default => sub { 1 } );
}

sub _git_ok {
    my (@cmd) = @_;
    my $rc = system(@cmd);
    is($rc, 0, "@cmd");
}

sub _init_repo {
    my $repo = tempdir( CLEANUP => 1 );
    _git_ok( 'git', 'init', '-q', $repo );
    _git_ok( 'git', '-C', $repo, 'config', 'user.email', 'test@example.com' );
    _git_ok( 'git', '-C', $repo, 'config', 'user.name', 'Test User' );
    return $repo;
}

subtest 'board access discovers a ref-backed board without a persistent karr directory' => sub {
    my $repo = _init_repo();
    my $git = App::karr::Git->new( dir => $repo );
    $git->write_ref( 'refs/karr/config', Dump({ version => 1, board => { name => 'Ref Board' } }) );
    $git->write_ref( 'refs/karr/meta/next-id', "3\n" );

    my $board = TestBoard->new( dir => $repo );
    ok( $board->board_dir->is_dir, 'temporary board dir exists' );
    ok( $board->board_dir->child('config.yml')->exists, 'config is materialized into temp dir' );
    ok( $board->tasks_dir->is_dir, 'temporary tasks dir exists' );
    ok( !$board->git_root->child('karr')->exists, 'no persistent karr directory is created in the repo root' );
};

subtest 'board access fails outside git repositories' => sub {
    my $dir = tempdir( CLEANUP => 1 );
    my $ok = eval { TestBoard->new( dir => $dir )->board_dir; 1 };
    ok( !$ok, 'board access dies outside git repos' );
    like( $@, qr/git repository/i, 'error mentions git repository requirement' );
};

done_testing;
