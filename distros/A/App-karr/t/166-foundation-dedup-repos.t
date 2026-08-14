use strict;
use warnings;
use Test::More;
use Path::Tiny qw( path tempdir );

use App::karr::Foundation;
use App::karr::Git;

# ---------------------------------------------------------------------------
# Helpers (kept small; the existing t/30-* tests carry the heavy lifting)
# ---------------------------------------------------------------------------

sub new_foundation {
  return App::karr::Foundation->new(@_);
}

sub make_git_repo {
  my $dir = tempdir( CLEANUP => 1 );
  system( 'git', '-C', "$dir", 'init', '-q' ) == 0
    or die "git init failed";
  system( 'git', '-C', "$dir", 'config', 'user.email', 'test@example.invalid' ) == 0
    or die "git config email failed";
  system( 'git', '-C', "$dir", 'config', 'user.name', 'Test' ) == 0
    or die "git config name failed";
  return $dir;
}

sub write_karr_file {
  my ( $dir ) = @_;
  $dir->child('.karr')->spew_utf8("command: echo hello\n");
}

sub write_config {
  my ( $dirs, $scan ) = @_;
  my $cfg_dir  = tempdir( CLEANUP => 1 );
  my $cfg_file = $cfg_dir->child('config.yml');
  my $body = '';
  $body .= "dirs:\n" . join( '', map { "  - $_\n" } @$dirs ) if $dirs && @$dirs;
  $body .= "scan:\n" . join( '', map { "  - $_\n" } @$scan ) if $scan && @$scan;
  $cfg_file->spew_utf8($body);
  return ( $cfg_dir, $cfg_file );
}

# ---------------------------------------------------------------------------
# Regression: ticket #166 — a repo reachable through both dirs: and scan:
# must be processed exactly once per tick. Before the fix _discover_repos
# returned the same Path::Tiny twice, so _process_repo ran twice (real money
# for a claude agent, real board churn) and --status printed the board twice.
# ---------------------------------------------------------------------------

subtest '_discover_repos: dirs + scan dedup (#166)' => sub {
  my $parent = tempdir( CLEANUP => 1 );
  my $repo   = $parent->child('b1');
  $repo->mkpath;
  system( 'git', '-C', "$repo", 'init', '-q' );
  system( 'git', '-C', "$repo", 'config', 'user.email', 'test@example.invalid' );
  system( 'git', '-C', "$repo", 'config', 'user.name',  'Test' );
  write_karr_file( $repo );

  my ( $cfg_dir, $cfg ) = write_config( ["$repo"], ["$parent"] );
  my $f = new_foundation( config => "$cfg" );
  my @repos = $f->_discover_repos;
  is scalar @repos, 1, 'repo reachable via dirs: AND scan: counted once';
  is "$repos[0]", "$repo", '...and the surviving entry is the real path';
};

# Same repo via two different path spellings — trailing slash, relative
# spelling, parent through scan:. All should collapse to one entry. The
# ticket explicitly asks for path-based (not URL-based) dedup; the key is
# the canonical filesystem path.
subtest '_discover_repos: dedup across path spellings (#166)' => sub {
  my $parent = tempdir( CLEANUP => 1 );
  my $repo   = $parent->child('b1');
  $repo->mkpath;
  system( 'git', '-C', "$repo", 'init', '-q' );
  write_karr_file( $repo );

  # Trailing slash on the dirs: spelling — same dir, different string.
  my ( $cfg_dir, $cfg ) = write_config( [ "$repo/" ], ["$parent"] );
  my $f = new_foundation( config => "$cfg" );
  my @repos = $f->_discover_repos;
  is scalar @repos, 1, 'trailing-slash spelling still counts as one';
};

# A symlink that points at the real repo must not double-count either:
# the explicit dirs: entry names the symlink, scan: names the real parent,
# and the two Path::Tiny objects are different strings but resolve to the
# same canonical filesystem location.
subtest '_discover_repos: symlinked dirs: path is the same board (#166)' => sub {
  my $parent  = tempdir( CLEANUP => 1 );
  my $real    = $parent->child('real');
  my $symlink = $parent->child('link');
  $real->mkpath;
  system( 'git', '-C', "$real", 'init', '-q' );
  write_karr_file( $real );
  symlink "$real", "$symlink" or die "symlink: $!";

  my ( $cfg_dir, $cfg ) = write_config( ["$symlink"], ["$parent"] );
  my $f = new_foundation( config => "$cfg" );
  my @repos = $f->_discover_repos;
  is scalar @repos, 1, 'symlink + real parent collapse to one entry';
};

# Order preservation: an explicit dirs: entry should keep its place ahead
# of a scan: finding that names the same repo. The fix uses a hash by
# canonical path, but it must walk the inputs in order and record first
# occurrence — otherwise a scan: hit could shove the explicit entry out of
# position and flip the iteration order in run().
subtest '_discover_repos: dedup preserves first-seen order (#166)' => sub {
  my $parent = tempdir( CLEANUP => 1 );
  my $repo1  = $parent->child('a1');
  my $repo2  = $parent->child('a2');
  $repo1->mkpath;
  $repo2->mkpath;
  system( 'git', '-C', "$repo1", 'init', '-q' );
  system( 'git', '-C', "$repo2", 'init', '-q' );
  write_karr_file( $repo1 );
  write_karr_file( $repo2 );

  # dirs: lists a1, a2 in that order; scan: finds both via the parent.
  my ( $cfg_dir, $cfg ) = write_config( [ "$repo1", "$repo2" ], ["$parent"] );
  my $f = new_foundation( config => "$cfg" );
  my @repos = $f->_discover_repos;
  is scalar @repos, 2, 'two distinct repos still count as two';
  is "$repos[0]", "$repo1", 'dirs: order preserved (a1 before a2)';
  is "$repos[1]", "$repo2", '...and the scan: duplicates did not reorder';

  # Reverse it: scan: first, dirs: second. The first-seen wins.
  my ( $cfg_dir2, $cfg2 ) = write_config( [ "$repo2", "$repo1" ], ["$parent"] );
  my $f2 = new_foundation( config => "$cfg2" );
  my @r2  = $f2->_discover_repos;
  is "$r2[0]", "$repo2", 'explicit dirs: order is the source of truth';
  is "$r2[1]", "$repo1", '...not the order the scan happened to find them';
};

# End-to-end: --status would have rendered the same board twice before the
# fix; after the fix the overview shows it once. We capture stdout to check.
subtest '_print_overview: duplicate dirs/scan boards render once (#166)' => sub {
  my $parent = tempdir( CLEANUP => 1 );
  my $repo   = $parent->child('b1');
  $repo->mkpath;
  system( 'git', '-C', "$repo", 'init', '-q' );
  write_karr_file( $repo );

  my ( $cfg_dir, $cfg ) = write_config( ["$repo"], ["$parent"] );
  my $f = new_foundation( config => "$cfg" );

  my @repos = $f->_discover_repos;
  is scalar @repos, 1, 'discovery deduplicated';

  my $out = '';
  {
    local *STDOUT;
    open STDOUT, '>', \$out or die $!;
    $f->_print_overview( \@repos );
  }
  my $hits = () = $out =~ /b1/g;
  is $hits, 1, 'overview shows the board exactly once';
};

done_testing;
