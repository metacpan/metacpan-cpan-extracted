use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestGit qw( require_git_c );
require_git_c();
use TestKarr qw( run_karr );
use File::Temp qw( tempdir );

# `view` is a registered alias for the `show` command (same mechanism as
# set-refs/get-refs/agent-name in %COMMAND_ALIASES). `karr view ID` must
# dispatch to App::karr::Cmd::Show and produce byte-identical output to
# `karr show ID`, across the show forms (plain, --json, --compact). The help
# listing must not gain a second entry: only `show` appears in `karr --help`.

sub _run_karr { return run_karr(@_) }

sub _git_ok {
  my (@cmd) = @_;
  my $rc = system(@cmd);
  is( $rc, 0, "@cmd" );
}

sub _setup_repo {
  my $repo = tempdir( CLEANUP => 1 );
  _git_ok( 'git', 'init', '-q', $repo );
  _git_ok( 'git', '-C', $repo, 'config', 'user.email', 'test@example.com' );
  _git_ok( 'git', '-C', $repo, 'config', 'user.name', 'Test User' );

  my $init = _run_karr( $repo, 'init', '--name', 'View Alias Board' );
  is( $init->{exit}, 0, 'karr init succeeds' ) or diag $init->{stderr};

  my $create = _run_karr( $repo, 'create', 'Distinctive View Task', '--priority', 'high' );
  is( $create->{exit}, 0, 'seed task created' ) or diag $create->{stderr};

  return $repo;
}

subtest 'karr view ID matches karr show ID (plain)' => sub {
  my $repo = _setup_repo();

  my $show = _run_karr( $repo, 'show', '1' );
  my $view = _run_karr( $repo, 'view', '1' );

  is( $view->{exit}, 0, 'karr view exits 0' ) or diag $view->{stderr};
  is( $view->{exit}, $show->{exit}, 'view and show share the same exit code' );
  is( $view->{stdout}, $show->{stdout}, 'view stdout is identical to show stdout' );
  like( $view->{stdout}, qr/Distinctive View Task/,
    'view dispatches to Show (task detail, not the board summary)' );
};

subtest 'karr view ID --json matches karr show ID --json' => sub {
  my $repo = _setup_repo();

  my $show = _run_karr( $repo, 'show', '1', '--json' );
  my $view = _run_karr( $repo, 'view', '1', '--json' );

  is( $view->{exit}, 0, 'karr view --json exits 0' ) or diag $view->{stderr};
  is( $view->{stdout}, $show->{stdout}, 'view --json stdout is identical to show --json' );
};

subtest 'karr view ID --compact matches karr show ID --compact' => sub {
  my $repo = _setup_repo();

  my $show = _run_karr( $repo, 'show', '1', '--compact' );
  my $view = _run_karr( $repo, 'view', '1', '--compact' );

  is( $view->{exit}, 0, 'karr view --compact exits 0' ) or diag $view->{stderr};
  is( $view->{stdout}, $show->{stdout}, 'view --compact stdout is identical to show --compact' );
};

subtest 'karr --help lists show once and does not list view as a separate command' => sub {
  my $repo = _setup_repo();
  my $rv   = _run_karr( $repo, '--help' );

  is( $rv->{exit}, 0, 'karr --help exits 0' ) or diag $rv->{stderr};

  ( my $plain = $rv->{stdout} ) =~ s/\x1b\[[0-9;]*m//g;

  like( $plain, qr/^\s*show\b/m, 'help lists the show command' );
  unlike( $plain, qr/^\s*view\b/m,
    'help does not double-list the view alias as its own command' );
};

done_testing;
