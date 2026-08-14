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

# Ticket #129: `karr list --json` built its payload from Task->to_frontmatter,
# which is the YAML frontmatter view -- and the body lives *below* the
# frontmatter in the file format, never inside it, so every card came out of
# list --json without its text. show, pick, and handoff already went through
# Task->to_json_hash, which is the same hash plus a body key, so the same card
# had a body in one command's JSON and none in another's.
#
# kanban-md marshals the full *task.Task structs in cmd/list.go (outputTaskList),
# and Body there carries `json:"body,omitempty"` (internal/task/task.go:33), so
# list --json ships bodies upstream too: this was a parity gap, and it forced an
# agent that wanted ticket text to fall back to one `show` per id.
#
# Pinned here, at the CLI, because the bug lived in the one line where the
# command chose its serializer -- an in-process Task->to_json_hash assertion
# (t/51) could not see it and stayed green throughout.
#
#   - a card with a body carries it, verbatim
#   - a card without one carries no body key at all (omitempty, not "body":"")
#   - a body of "0" is a body (ticket #78: emptiness is length, not truth)

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

my $BODY = "First line of the body\n\nAnd a second paragraph.";

my $repo = _init_repo();
is( _run_karr( $repo, 'init', '--name', 'Body Board' )->{exit}, 0, 'board initialized' );

is( _run_karr( $repo, 'create', 'With body', '--body', $BODY )->{exit},
  0, 'card 1 created with a body' );
is( _run_karr( $repo, 'create', 'Without body' )->{exit},
  0, 'card 2 created without one' );
is( _run_karr( $repo, 'create', 'Falsy body', '--body', '0' )->{exit},
  0, 'card 3 created with a body of "0"' );

my $rv = _run_karr( $repo, 'list', '--json' );
is( $rv->{exit}, 0, 'list --json succeeds' ) or diag( $rv->{stderr} );

my $data = eval { decode_json( $rv->{stdout} ) };
is( ref $data, 'ARRAY', 'list --json emits a JSON array' ) or diag( $rv->{stdout} );

my %by_id = map { $_->{id} => $_ } @{ $data || [] };
is( scalar keys %by_id, 3, 'all three cards are in the payload' );

is( $by_id{1}{body}, $BODY, 'the card with a body carries it verbatim' )
  or diag( $rv->{stdout} );

# omitempty, exactly as kanban-md's Body tag spells it: an absent body is an
# absent key, not an empty string, so a consumer can tell "no text" from "".
ok( !exists $by_id{2}{body}, 'the bodyless card carries no body key at all' );

# Ticket #78 in the list payload: a body of "0" is false in Perl but is text.
is( $by_id{3}{body}, '0', 'a body of "0" is present, not dropped as empty' );

# The rest of the frontmatter must survive the switch of serializer -- the fix
# swaps the whole payload builder, so a regression there would be silent.
is( $by_id{1}{title},  'With body', 'title still present' );
is( $by_id{1}{status}, 'backlog',   'status still present' );
ok( exists $by_id{1}{created}, 'created still present' );

subtest 'a filtered list keeps the bodies too' => sub {
  # -s searches the body already, so the search path is the one most likely to
  # be used for "give me the text of everything matching X".
  my $found = _run_karr( $repo, 'list', '-s', 'second paragraph', '--json' );
  is( $found->{exit}, 0, 'list -s --json succeeds' ) or diag( $found->{stderr} );

  my $hits = eval { decode_json( $found->{stdout} ) };
  is( ref $hits,     'ARRAY', 'search --json emits a JSON array' ) or diag( $found->{stdout} );
  is( scalar @$hits, 1,       'one card matched' );
  is( $hits->[0]{id},   1,     'the matching card is the one with the body' );
  is( $hits->[0]{body}, $BODY, 'and it carries the body it was matched on' );
};

done_testing;
