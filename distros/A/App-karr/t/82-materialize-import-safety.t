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
use YAML::XS qw( LoadFile );

use App::karr::Git;
use App::karr::BoardStore;
use App::karr::Task;

# The refs<->files bridge, four board tickets:
#
#   #48  `karr materialize` wrote its file view straight into the working tree:
#        it overwrote config.yml and removed every tasks/*.md, target unseen.
#        A repo with its own tracked tasks/ or config.yml lost them, from a
#        command that only reads the board.
#   #50  `karr import --yes` treated an existing but empty tasks/ as a view to
#        import, so it deleted every task ref and reported success.
#   #60  the materialized config.yml was unreadable to kanban-md -- the point
#        of the bridge -- because Perl's 1/0 are YAML integers where the Go
#        schema wants bools, and next_id (validated >= 1) was never written.
#   #70  import wrote refs as it parsed, so one malformed card aborted the run
#        mid-write and left the board half updated, with the offending file
#        never named.

my $ROOT = abs_path('.');
my $BIN  = "$ROOT/bin/karr";

sub _run_karr {
  my ( $cwd, @argv ) = @_;
  my $old = getcwd();
  chdir $cwd or die "chdir $cwd: $!";

  my $stderr = gensym;
  my $pid = open3( my $in, my $out, $stderr, $^X, "-I$ROOT/lib", $BIN, @argv );
  close $in;

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

sub _init_board {
  my ( $name, @titles ) = @_;
  my $repo = _init_repo();
  is( _run_karr( $repo, 'init', '--name', $name )->{exit}, 0, "board '$name' initialized" );
  is( _run_karr( $repo, 'create', $_ )->{exit}, 0, "created: $_" ) for @titles;
  return $repo;
}

sub _task_ids {
  my ($repo) = @_;
  return [ sort { $a <=> $b } App::karr::Git->new( dir => $repo )->list_task_refs ];
}

sub _titles {
  my ($repo) = @_;
  my $git = App::karr::Git->new( dir => $repo );
  return { map { $_ => $git->load_task_ref($_)->title } $git->list_task_refs };
}

# A file the pre-fix code deletes has to be reportable as a failed assertion,
# not as a die that takes the rest of the file down with it.
sub _slurp {
  my ($file) = @_;
  return $file->exists ? $file->slurp_utf8 : "<missing: $file>";
}

# ---------------------------------------------------------------- ticket #48

subtest 'materialize refuses to overwrite or delete git-tracked files' => sub {
  my $repo = _init_repo();
  my $root = path($repo);

  # A project that already owns both names materialize writes to, and that
  # additionally keeps a card-shaped file under tasks/ -- the one shape the
  # sweep would otherwise remove.
  $root->child('tasks')->mkpath;
  $root->child('tasks')->child('001-legacy-card.md')->spew_utf8("# Legacy\n");
  $root->child('config.yml')->spew_utf8("service: payments\n");
  system( 'git', '-C', $repo, 'add', 'tasks/001-legacy-card.md', 'config.yml' );
  system( 'git', '-C', $repo, 'commit', '-qm', 'project files' );

  is( _run_karr( $repo, 'init', '--name', 'Clobber Board' )->{exit}, 0, 'board initialized' );
  is( _run_karr( $repo, 'create', 'A task' )->{exit}, 0, 'task created' );

  my $rv = _run_karr( $repo, 'materialize' );
  isnt( $rv->{exit}, 0, 'materialize refuses instead of clobbering' );
  like( $rv->{stderr}, qr/tracked by git/, 'stderr says why it refused' );
  like( $rv->{stderr}, qr/\bconfig\.yml\b/,          'the tracked config.yml is named' );
  like( $rv->{stderr}, qr/tasks\/001-legacy-card\.md/, 'the tracked card is named' );

  is( _slurp( $root->child('config.yml') ), "service: payments\n",
    "the project's own config.yml is untouched" );
  is( _slurp( $root->child('tasks')->child('001-legacy-card.md') ), "# Legacy\n",
    "the project's own card is still there" );

  # Refusing means refusing before any write, not writing the board and then
  # complaining: no card of our own may have been laid down either.
  my @cards = grep { $_->basename ne '001-legacy-card.md' }
    $root->child('tasks')->children(qr/\.md$/);
  is_deeply( \@cards, [], 'nothing was materialized on the refusal path' );
};

subtest 'materialize --force overrides the refusal' => sub {
  my $repo = _init_repo();
  my $root = path($repo);
  $root->child('config.yml')->spew_utf8("service: payments\n");
  system( 'git', '-C', $repo, 'add', 'config.yml' );
  system( 'git', '-C', $repo, 'commit', '-qm', 'project config' );

  is( _run_karr( $repo, 'init', '--name', 'Forced Board' )->{exit}, 0, 'board initialized' );
  is( _run_karr( $repo, 'create', 'A task' )->{exit}, 0, 'task created' );

  my $rv = _run_karr( $repo, 'materialize', '--force' );
  is( $rv->{exit}, 0, 'materialize --force goes through' );
  like( $root->child('config.yml')->slurp_utf8, qr/Forced Board/,
    'the view replaced the tracked config.yml, as asked' );
};

subtest 'the tasks/ sweep only removes card-shaped files' => sub {
  my $repo = _init_board( 'Sweep Board', 'Keep me', 'Drop me' );
  my $root = path($repo);

  is( _run_karr( $repo, 'materialize' )->{exit}, 0, 'first materialize' );

  # Untracked, so no refusal -- but it is not a card and must survive anyway.
  $root->child('tasks')->child('deploy-runbook.md')->spew_utf8("# Runbook\n");

  is( _run_karr( $repo, 'delete', '2', '--yes' )->{exit}, 0, 'second task deleted from the board' );
  is( _run_karr( $repo, 'materialize' )->{exit}, 0, 'second materialize' );

  my @left = sort map { $_->basename } $root->child('tasks')->children(qr/\.md$/);
  is_deeply( \@left, [ '001-keep-me.md', 'deploy-runbook.md' ],
    'the stale card is swept and the project file is left alone' );
};

# ---------------------------------------------------------------- ticket #50

subtest 'import refuses an empty tasks/ instead of emptying the board' => sub {
  my $repo = _init_board( 'Empty View Board', 'Task one', 'Task two' );
  is( _run_karr( $repo, 'materialize' )->{exit}, 0, 'view materialized' );

  $_->remove for path($repo)->child('tasks')->children(qr/\.md$/);

  my $rv = _run_karr( $repo, 'import', '--yes' );
  isnt( $rv->{exit}, 0, 'import --yes fails on an empty view' );
  like( $rv->{stderr}, qr/file view is empty/, 'stderr says the view is empty' );

  is_deeply( _task_ids($repo), [ 1, 2 ], 'both task refs survived' );
};

# ---------------------------------------------------------------- ticket #60

subtest 'the materialized config is one kanban-md can load' => sub {
  my $repo = _init_board( 'Interop Board', 'Interop task' );
  is( _run_karr( $repo, 'materialize' )->{exit}, 0, 'view materialized' );

  my $config_file = path($repo)->child('config.yml');
  my $raw = $config_file->slurp_utf8;

  # go-yaml refuses to unmarshal `1` into a Go bool, and every one of these is
  # typed bool in kanban-md's schema, so an integer here makes the whole board
  # unreadable to it. Assert on the text: a Perl-side reload cannot tell a YAML
  # `true` from a YAML `1`.
  like( $raw, qr/^\s*(?:-\s*)?require_claim:\s*true\s*$/m,
    'require_claim is a YAML boolean' );
  like( $raw, qr/^\s*(?:-\s*)?bypass_column_wip:\s*true\s*$/m,
    'bypass_column_wip is a YAML boolean' );
  unlike( $raw, qr/^\s*(?:-\s*)?(?:require_claim|bypass_column_wip|enabled):\s*[01]\s*$/m,
    'no boolean key is written as an integer' );

  # kanban-md validates next_id >= 1 and rejects a config without it.
  my $config = LoadFile( $config_file->stringify );
  ok( defined $config->{next_id}, 'next_id is present in the view' );
  cmp_ok( $config->{next_id}, '>=', 1, 'next_id is >= 1' );

  my $store = App::karr::BoardStore->new( git => App::karr::Git->new( dir => $repo ) );
  is( $config->{next_id}, $store->peek_next_id,
    'and it carries the id refs/karr/meta/next-id would hand out next' );

  # The counter stays in the ref: importing the view back must not turn it into
  # a config override.
  is( _run_karr( $repo, 'import', '--yes' )->{exit}, 0, 'the view imports back cleanly' );
  my $overrides = App::karr::Git->new( dir => $repo )->read_config_ref;
  ok( !exists $overrides->{next_id}, 'import does not fold next_id into refs/karr/config' );
  is( $store->peek_next_id, $config->{next_id}, 'and the next-id ref is unchanged' );
};

# ---------------------------------------------------------------- ticket #70

subtest 'a malformed card aborts the whole import, changing nothing' => sub {
  my $repo = _init_board( 'Atomic Board', 'Task one', 'Task two', 'Task three' );
  is( _run_karr( $repo, 'materialize' )->{exit}, 0, 'view materialized' );

  my $before = _titles($repo);
  my $tasks  = path($repo)->child('tasks');

  # A view that changes something on every axis import touches: a rewritten
  # card, a removed card (which the prune would delete) -- and one broken file.
  my $one = $tasks->child('001-task-one.md');
  ( my $edited = $one->slurp_utf8 ) =~ s/^title: Task one$/title: Renamed one/m;
  $one->spew_utf8($edited);
  $tasks->child('003-task-three.md')->remove;
  $tasks->child('004-broken.md')->spew_utf8("no frontmatter at all\n");

  my $rv = _run_karr( $repo, 'import', '--yes' );
  isnt( $rv->{exit}, 0, 'import fails on the malformed card' );
  like( $rv->{stderr}, qr/004-broken\.md/, 'the offending file is named' );
  like( $rv->{stderr}, qr/No refs were changed/, 'stderr promises the board is untouched' );

  is_deeply( _titles($repo), $before, 'no task ref was rewritten' );
  is_deeply( _task_ids($repo), [ 1, 2, 3 ], 'and the prune never ran either' );
};

subtest 'every unparseable card is named, not just the first' => sub {
  my $repo = _init_board( 'Naming Board', 'Fine' );
  is( _run_karr( $repo, 'materialize' )->{exit}, 0, 'view materialized' );

  my $tasks = path($repo)->child('tasks');
  $tasks->child('002-no-frontmatter.md')->spew_utf8("just prose\n");
  $tasks->child('003-no-id.md')->spew_utf8("---\ntitle: nameless\n---\n");

  my $rv = _run_karr( $repo, 'import', '--yes' );
  isnt( $rv->{exit}, 0, 'import fails' );
  like( $rv->{stderr}, qr/002-no-frontmatter\.md/, 'the first bad file is named' );
  like( $rv->{stderr}, qr/003-no-id\.md/,          'the second bad file is named too' );
  like( $rv->{stderr}, qr/2 of 3 task file\(s\)/,  'and the count is reported' );
};

subtest 'a CRLF card is rejected by name, not as a bare parse error' => sub {
  # Task->_parse_content requires a literal "\A---\n" for kanban-md parity, so
  # a CRLF card is invalid on purpose. What was missing was which file it was.
  my $repo = _init_board( 'CRLF Board', 'Fine' );
  is( _run_karr( $repo, 'materialize' )->{exit}, 0, 'view materialized' );

  my $tasks = path($repo)->child('tasks');
  ( my $crlf = $tasks->child('001-fine.md')->slurp_utf8 ) =~ s/\n/\r\n/g;
  $tasks->child('002-crlf.md')->spew_utf8($crlf);

  my $rv = _run_karr( $repo, 'import', '--yes' );
  isnt( $rv->{exit}, 0, 'import fails' );
  like( $rv->{stderr}, qr/002-crlf\.md/, 'the CRLF file is named' );
};

subtest 'Task->from_file names the file it could not parse' => sub {
  my $dir  = path( tempdir( CLEANUP => 1 ) );
  my $file = $dir->child('001-broken.md');
  $file->spew_utf8("no frontmatter at all\n");

  my $err = '';
  eval { App::karr::Task->from_file($file); 1 } or $err = $@;
  like( $err, qr/Invalid task format/, 'still reports what went wrong' );
  like( $err, qr/\Q001-broken.md\E/,   'and which file it went wrong in' );

  my $missing = $dir->child('002-no-id.md');
  $missing->spew_utf8("---\ntitle: nameless\n---\n");
  $err = '';
  eval { App::karr::Task->from_file($missing); 1 } or $err = $@;
  like( $err, qr/\Q002-no-id.md\E/, 'a rejected frontmatter names its file too' );
};

done_testing;
