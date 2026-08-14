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
use JSON::MaybeXS qw( decode_json );

use App::karr::Task;

# Ticket #52: Task::_parse_content matched the closing frontmatter delimiter
# with a bare `---` instead of anchoring it to the start of a line, so the
# non-greedy scan stopped at the first `---` *anywhere* -- including one at the
# end of an ordinary frontmatter value, which YAML::XS dumps unquoted. The
# frontmatter was then cut mid-line and Task->new died with "Missing required
# arguments: id, title".
#
# The severity was in the blast radius, not the parse: every command loads the
# board before doing anything, `delete` included, so one `karr edit N --block
# "waiting ---"` left the board unrepairable through karr -- the only way out
# was a raw `git update-ref -d`. The CLI subtests below are therefore as much
# the point as the unit ones: they assert the board stays *usable*.
#
# kanban-md has never had this bug; splitFrontmatter
# (../kanban-md/internal/task/file.go) scans for the literal "\n---\n".

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

subtest 'a title ending in --- round-trips instead of truncating the document' => sub {
  my $task = App::karr::Task->new(
    id    => 1,
    title => 'Release v1 ---',
    body  => 'important notes',
  );
  my $md = $task->to_markdown;
  my $back = App::karr::Task->from_string($md);

  is( $back->id,    1,                'id survived the split' );
  is( $back->title, 'Release v1 ---', 'the title kept its trailing ---' );
  is( $back->body,  'important notes', 'the body is the body' );

  # The old failure did not lose the rest of the frontmatter, it demoted it into
  # the body: `updated: ...` and the real `---` ended up as body text.
  unlike( $back->body, qr/^updated:/m, 'no frontmatter leaked into the body' );
  is( $back->updated, $task->updated, 'updated is still a frontmatter field' );
};

subtest 'tags and a block reason ending in --- round-trip' => sub {
  my $task = App::karr::Task->new(
    id      => 7,
    title   => 'Blocked card',
    tags    => [ 'rel---', 'x' ],
    blocked => 'waiting ---',
    body    => 'hello',
  );
  my $back = App::karr::Task->from_string( $task->to_markdown );

  is_deeply( $back->tags, [ 'rel---', 'x' ], 'a tag ending in --- survived' );
  is( $back->block_reason, 'waiting ---', 'a block reason ending in --- survived' );
  is( $back->title,   'Blocked card', 'title untouched' );
  is( $back->body,    'hello',        'body untouched' );
};

subtest 'other string fields ending in --- round-trip' => sub {
  my $task = App::karr::Task->new(
    id       => 9,
    title    => 'Fields',
    assignee => 'someone ---',
    estimate => '3d ---',
    due      => '2026-01-01 ---',
    body     => 'b',
  );
  my $back = App::karr::Task->from_string( $task->to_markdown );

  is( $back->assignee, 'someone ---',    'assignee' );
  is( $back->estimate, '3d ---',         'estimate' );
  is( $back->due,      '2026-01-01 ---', 'due' );
  is( $back->body,     'b',              'body' );
};

subtest 'a horizontal rule inside the body is still body' => sub {
  # The closing delimiter is the *first* line-start `---` after the
  # frontmatter, so a later one in the body must be left alone. This is what
  # stops "anchor it to a line start" from being fixed by making the match
  # greedy instead.
  my $task = App::karr::Task->new( id => 3, title => 'Doc', body => "intro\n---\noutro" );
  my $back = App::karr::Task->from_string( $task->to_markdown );
  is( $back->body, "intro\n---\noutro", 'the rule in the body is preserved' );
  is( $back->title, 'Doc', 'and the frontmatter still parsed' );
};

subtest 'a genuinely malformed document still fails loudly' => sub {
  my $err = '';
  eval { App::karr::Task->from_string("no frontmatter at all\n"); 1 } or $err = $@;
  like( $err, qr/Invalid task format/, 'a document without frontmatter is rejected' );

  $err = '';
  eval { App::karr::Task->from_string("---\nid: 1\ntitle: unterminated\n"); 1 } or $err = $@;
  like( $err, qr/Invalid task format/, 'frontmatter without a closing delimiter is rejected' );
};

subtest 'a block reason ending in --- leaves the whole board usable' => sub {
  my $repo = _init_repo();
  is( _run_karr( $repo, 'init', '--name', 'Delimiter Board' )->{exit}, 0, 'board initialized' );
  is( _run_karr( $repo, 'create', 'Normal task', '--body', 'hello' )->{exit}, 0, 'task created' );

  my $edit = _run_karr( $repo, 'edit', '1', '--block', 'waiting ---' );
  is( $edit->{exit}, 0, 'the block reason is accepted' );

  # Under #52 all four of these exited 1 with "Missing required arguments: id,
  # title" -- including delete, which is why the board could not be repaired.
  my $list = _run_karr( $repo, 'list' );
  is( $list->{exit}, 0, 'list still works' ) or diag $list->{stderr};
  unlike( $list->{stderr}, qr/Missing required arguments/, 'and does not hit the Task constructor' );
  like( $list->{stdout}, qr/Normal task/, 'the card is listed' );

  is( _run_karr( $repo, 'board' )->{exit}, 0, 'board still works' );

  my $show = _run_karr( $repo, 'show', '1' );
  is( $show->{exit}, 0, 'show still works' );
  like( $show->{stdout}, qr/^Blocked:\s+waiting ---$/m, 'the block reason renders in full' );
  like( $show->{stdout}, qr/^hello$/m, 'the body is still just the body' );

  is( _run_karr( $repo, 'delete', '1', '--yes' )->{exit}, 0, 'delete can still remove the card' );
};

subtest 'a title and a tag ending in --- leave the board usable' => sub {
  my $repo = _init_repo();
  is( _run_karr( $repo, 'init', '--name', 'Title Board' )->{exit}, 0, 'board initialized' );
  is(
    _run_karr( $repo, 'create', 'Release v1 ---', '--tags', 'rel---,x', '--body', 'important notes' )->{exit},
    0, 'task created'
  );

  my $list = _run_karr( $repo, 'list' );
  is( $list->{exit}, 0, 'list still works' ) or diag $list->{stderr};
  like( $list->{stdout}, qr/\QRelease v1 ---\E/, 'the full title is listed, not a truncated one' );

  my $show = _run_karr( $repo, 'show', '1', '--json' );
  is( $show->{exit}, 0, 'show --json still works' );
  my $data = decode_json( $show->{stdout} );
  is( $data->{title}, 'Release v1 ---', 'title survived the ref round trip' );
  is_deeply( $data->{tags}, [ 'rel---', 'x' ], 'tags survived the ref round trip' );
  is( $data->{body}, 'important notes', 'body is not the leftover frontmatter' );
};

done_testing;
