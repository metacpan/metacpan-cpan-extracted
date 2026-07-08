use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestGit qw( require_git_c );
require_git_c();
use File::Temp qw( tempdir );
use Cwd qw( abs_path getcwd );
use IPC::Open3 qw( open3 );
use Symbol qw( gensym );
use Path::Tiny qw( path );

use App::karr::Git;
use App::karr::BoardStore;

# Ticket #29: the materialized file view (config.yml + tasks/) is a disposable
# view of the canonical refs/karr/* state and must never be committed. karr
# ensures the board-root .gitignore covers it on `init` and `materialize`,
# appending idempotently (like kanban-md's ensureGitignoreEntry) so it never
# duplicates an entry and always preserves existing content.

my $ROOT = abs_path('.');
my $BIN  = "$ROOT/bin/karr";

sub _run_karr {
  my ( $cwd, @argv ) = @_;
  my $old = getcwd();
  chdir $cwd or die "chdir $cwd: $!";

  my $stderr = gensym;
  my $pid = open3( undef, my $out, $stderr, $^X, "-I$ROOT/lib", $BIN, @argv );

  my $stdout      = do { local $/; <$out> };
  my $stderr_text = do { local $/; <$stderr> };
  waitpid( $pid, 0 );
  my $exit = $? >> 8;

  chdir $old or die "chdir $old: $!";
  return {
    exit   => $exit,
    stdout => ( defined $stdout      ? $stdout      : '' ),
    stderr => ( defined $stderr_text ? $stderr_text : '' ),
  };
}

sub _init_repo {
  my $repo = tempdir( CLEANUP => 1 );
  system( 'git', 'init', '-q', $repo );
  system( 'git', '-C', $repo, 'config', 'user.email', 'test@example.com' );
  system( 'git', '-C', $repo, 'config', 'user.name', 'Test User' );
  return $repo;
}

sub _store_for {
  my ($repo) = @_;
  return App::karr::BoardStore->new( git => App::karr::Git->new( dir => $repo ) );
}

sub _count {
  my ( $text, $re ) = @_;
  my $n = () = $text =~ /$re/g;
  return $n;
}

subtest 'ensure_gitignore creates .gitignore with the file-view entries' => sub {
  my $repo = _init_repo();
  my $gi   = path($repo)->child('.gitignore');
  ok( !$gi->exists, 'no .gitignore to start' );

  my @added = _store_for($repo)->ensure_gitignore($repo);
  is_deeply( [ sort @added ], [ 'config.yml', 'tasks/' ], 'both file-view entries reported as added' );

  ok( $gi->exists, '.gitignore created' );
  my $body = $gi->slurp_utf8;
  like( $body, qr{^tasks/$}m,      'tasks/ ignored' );
  like( $body, qr{^config\.yml$}m, 'config.yml ignored' );
};

subtest 'ensure_gitignore is idempotent (no duplicate entries)' => sub {
  my $repo  = _init_repo();
  my $store = _store_for($repo);

  $store->ensure_gitignore($repo);
  my @again = $store->ensure_gitignore($repo);
  is_deeply( \@again, [], 'a second call adds nothing' );

  my $body = path($repo)->child('.gitignore')->slurp_utf8;
  is( _count( $body, qr{^tasks/$}m ),      1, 'tasks/ appears exactly once' );
  is( _count( $body, qr{^config\.yml$}m ), 1, 'config.yml appears exactly once' );
};

subtest 'ensure_gitignore preserves existing unrelated content' => sub {
  my $repo = _init_repo();
  my $gi   = path($repo)->child('.gitignore');
  $gi->spew_utf8("*.swp\n/build/\n");

  _store_for($repo)->ensure_gitignore($repo);

  my $body = $gi->slurp_utf8;
  like( $body, qr{^\*\.swp$}m,     'existing *.swp preserved' );
  like( $body, qr{^/build/$}m,     'existing /build/ preserved' );
  like( $body, qr{^tasks/$}m,      'tasks/ appended' );
  like( $body, qr{^config\.yml$}m, 'config.yml appended' );
};

subtest 'ensure_gitignore fixes a missing trailing newline before appending' => sub {
  my $repo = _init_repo();
  my $gi   = path($repo)->child('.gitignore');
  $gi->spew_utf8("*.swp");    # deliberately no trailing newline

  _store_for($repo)->ensure_gitignore($repo);

  my $body = $gi->slurp_utf8;
  unlike( $body, qr{\*\.swptasks}, 'the previous last line is not run together with our entry' );
  like( $body, qr{^\*\.swp$}m, 'existing entry still on its own line' );
  like( $body, qr{^tasks/$}m,  'tasks/ appended cleanly' );
};

subtest 'ensure_gitignore tops up a partially present block without duplicating' => sub {
  my $repo = _init_repo();
  my $gi   = path($repo)->child('.gitignore');
  $gi->spew_utf8("tasks/\n");    # tasks/ already ignored, config.yml is not

  my @added = _store_for($repo)->ensure_gitignore($repo);
  is_deeply( \@added, ['config.yml'], 'only the missing entry is added' );

  my $body = $gi->slurp_utf8;
  is( _count( $body, qr{^tasks/$}m ),      1, 'tasks/ not duplicated' );
  is( _count( $body, qr{^config\.yml$}m ), 1, 'config.yml added once' );
};

subtest 'karr init ensures the file view is gitignored' => sub {
  my $repo = _init_repo();
  my $rv   = _run_karr( $repo, 'init', '--name', 'Ignore Board' );
  is( $rv->{exit}, 0, 'init exits 0' );
  like( $rv->{stdout}, qr/\.gitignore/, 'init notes the .gitignore update' );

  my $body = path($repo)->child('.gitignore')->slurp_utf8;
  like( $body, qr{^tasks/$}m,      'init ignored tasks/' );
  like( $body, qr{^config\.yml$}m, 'init ignored config.yml' );
};

subtest 'karr init preserves a pre-existing .gitignore' => sub {
  my $repo = _init_repo();
  path($repo)->child('.gitignore')->spew_utf8("node_modules/\n");

  is( _run_karr( $repo, 'init', '--name', 'Preserve Board' )->{exit}, 0, 'init exits 0' );

  my $body = path($repo)->child('.gitignore')->slurp_utf8;
  like( $body, qr{^node_modules/$}m, 'unrelated entry preserved' );
  like( $body, qr{^tasks/$}m,        'tasks/ appended' );
  like( $body, qr{^config\.yml$}m,   'config.yml appended' );
};

subtest 'karr materialize ensures the file view is gitignored, idempotently' => sub {
  my $repo = _init_repo();
  is( _run_karr( $repo, 'init', '--name', 'Mat Board' )->{exit}, 0, 'init exits 0' );

  # init already added the entries; materialize must not duplicate them.
  is( _run_karr( $repo, 'materialize' )->{exit}, 0, 'materialize exits 0' );
  is( _run_karr( $repo, 'materialize' )->{exit}, 0, 'materialize again exits 0' );

  my $body = path($repo)->child('.gitignore')->slurp_utf8;
  is( _count( $body, qr{^tasks/$}m ),      1, 'tasks/ still appears exactly once' );
  is( _count( $body, qr{^config\.yml$}m ), 1, 'config.yml still appears exactly once' );
};

done_testing;
