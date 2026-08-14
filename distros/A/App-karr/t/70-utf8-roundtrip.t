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
use JSON::MaybeXS qw( decode_json );
use Encode qw( encode_utf8 decode FB_CROAK LEAVE_SRC );

use App::karr::Git;
use App::karr::Task;
use App::karr::Encoding qw( repair_mojibake );

# Ticket #53: karr mixed character strings and UTF-8 octets. YAML::XS::Dump
# emits octets and Load wants them, Path::Tiny's slurp_utf8/spew_utf8 work in
# characters, and @ARGV was never decoded -- so the frontmatter in every ref was
# encoded twice, `--json` handed agents mojibake, materialize wrote three
# encodes deep, and a correctly encoded kanban-md file could not be imported at
# all ("invalid trailing UTF-8 octet"). `karr show` looked right only because
# two errors cancelled.
#
# The contract now is one line: characters inside, octets only at the edges
# (App::karr::Encoding). This file walks a non-ASCII card the whole way round --
# argv, ref, show, --json, materialize, import, ref -- and asserts on the
# *bytes* at every edge, because any assertion that decodes what karr encoded is
# an identity round trip and would stay green under a consistent mis-encoding
# (ticket #63).

# The expectations here are character strings, so a failure diagnostic printing
# one would otherwise warn "Wide character in print" and show the wrong bytes --
# in an encoding test that is the worst possible time for illegible output.
binmode( Test::More->builder->$_, ':encoding(UTF-8)' )
  for qw( output failure_output todo_output );

my $ROOT = abs_path('.');
my $BIN  = "$ROOT/bin/karr";

my $TITLE = "Fix \x{dc}nicode \x{2014} \x{e4}rger";
my $BODY  = "Caf\x{e9} \x{2014} na\x{ef}ve";
my $TAG   = "gr\x{fc}n";

sub _run_karr {
  my ( $cwd, @argv ) = @_;
  my $old = getcwd();
  chdir $cwd or die "chdir $cwd: $!";

  my $stderr = gensym;
  my $pid = open3( my $in, my $out, $stderr, $^X, "-I$ROOT/lib", $BIN, @argv );
  close $in;
  binmode $out;
  binmode $stderr;
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

# The stored bytes, straight out of git and untouched by any karr code path.
sub _blob {
  my ( $repo, $ref ) = @_;
  open my $fh, '-|', 'git', '-C', $repo, 'cat-file', '-p', "$ref:data"
    or die "git cat-file: $!";
  binmode $fh;
  my $raw = do { local $/; <$fh> };
  close $fh;
  return defined $raw ? $raw : '';
}

# "Encoded exactly once" as an assertion: the text is present as UTF-8 octets,
# the double encode of it is not, and the payload as a whole is valid UTF-8
# (which rules out three encodes and any partial decode).
sub is_single_utf8 {
  my ( $bytes, $text, $name ) = @_;
  my $ok = 1;
  $ok &&= ok( index( $bytes, encode_utf8($text) ) >= 0, "$name: present as UTF-8 octets" );
  $ok &&= is( index( $bytes, encode_utf8( encode_utf8($text) ) ), -1, "$name: not double-encoded" );
  $ok &&= ok( defined eval { decode( 'UTF-8', $bytes, FB_CROAK | LEAVE_SRC ) },
    "$name: payload is valid UTF-8" );
  diag( "offending bytes: " . unpack( 'H*', $bytes ) ) unless $ok;
  return $ok;
}

subtest 'argv to ref: a non-ASCII card is stored as singly-encoded UTF-8' => sub {
  my $repo = _init_repo();
  is( _run_karr( $repo, 'init', '--name', encode_utf8("Board \x{fc}") )->{exit}, 0, 'board initialized' );
  is(
    _run_karr( $repo, 'create', encode_utf8($TITLE),
      '--body', encode_utf8($BODY), '--tags', encode_utf8($TAG) )->{exit},
    0, 'task created from UTF-8 argv'
  );

  my $blob = _blob( $repo, 'refs/karr/tasks/1/data' );
  is_single_utf8( $blob, $TITLE, 'ref blob title' );
  is_single_utf8( $blob, $BODY,  'ref blob body' );
  is_single_utf8( $blob, $TAG,   'ref blob tag' );

  is_single_utf8( _blob( $repo, 'refs/karr/config' ), "Board \x{fc}", 'config ref board name' );

  # And the same bytes parse back to the characters that were typed.
  my $git = App::karr::Git->new( dir => $repo );
  my $task = $git->load_task_ref(1);
  is( $task->title, $TITLE, 'title reads back as characters' );
  is( $task->body,  $BODY,  'body reads back as characters' );
  is_deeply( $task->tags, [$TAG], 'tag reads back as characters' );
};

subtest 'ref to stdout: show and show --json are both singly encoded' => sub {
  my $repo = _init_repo();
  is( _run_karr( $repo, 'init', '--name', 'Show Board' )->{exit}, 0, 'board initialized' );
  is(
    _run_karr( $repo, 'create', encode_utf8($TITLE),
      '--body', encode_utf8($BODY), '--tags', encode_utf8($TAG) )->{exit},
    0, 'task created'
  );

  my $show = _run_karr( $repo, 'show', '1' );
  is( $show->{exit}, 0, 'show exits 0' );
  is_single_utf8( $show->{stdout}, $TITLE, 'show stdout title' );
  is_single_utf8( $show->{stdout}, $BODY,  'show stdout body' );

  # --json is the interface agents parse and the one #53 got wrong even while
  # plain show looked correct.
  my $json = _run_karr( $repo, 'show', '1', '--json' );
  is( $json->{exit}, 0, 'show --json exits 0' );
  is_single_utf8( $json->{stdout}, $TITLE, 'show --json title' );
  is_single_utf8( $json->{stdout}, $BODY,  'show --json body' );

  my $data = decode_json( $json->{stdout} );
  is( $data->{title}, $TITLE, 'decoded json title' );
  is( $data->{body},  $BODY,  'decoded json body' );
  is_deeply( $data->{tags}, [$TAG], 'decoded json tag' );

  my $list = _run_karr( $repo, 'list' );
  is( $list->{exit}, 0, 'list exits 0' );
  is_single_utf8( $list->{stdout}, $TITLE, 'list stdout title' );
};

subtest 'ref to file view and back: materialize, import, ref' => sub {
  my $repo = _init_repo();
  is( _run_karr( $repo, 'init', '--name', 'Round Board' )->{exit}, 0, 'board initialized' );
  is(
    _run_karr( $repo, 'create', encode_utf8($TITLE),
      '--body', encode_utf8($BODY), '--tags', encode_utf8($TAG) )->{exit},
    0, 'task created'
  );
  my $before = _blob( $repo, 'refs/karr/tasks/1/data' );

  is( _run_karr( $repo, 'materialize' )->{exit}, 0, 'materialize exits 0' );

  my ($card) = path($repo)->child('tasks')->children(qr/\.md$/);
  ok( $card, 'a card was written' );
  my $raw = do { open my $fh, '<:raw', "$card" or die $!; local $/; <$fh> };
  is_single_utf8( $raw, $TITLE, 'materialized file title' );
  is_single_utf8( $raw, $BODY,  'materialized file body' );

  my $cfg = do {
    open my $fh, '<:raw', path($repo)->child('config.yml')->stringify or die $!;
    local $/;
    <$fh>;
  };
  ok( defined eval { decode( 'UTF-8', $cfg, FB_CROAK | LEAVE_SRC ) }, 'config.yml is valid UTF-8' );

  is( App::karr::Task->from_file($card)->title, $TITLE, 'the file parses back to the characters' );

  is( _run_karr( $repo, 'import', '--yes' )->{exit}, 0, 'import --yes exits 0' );
  is( _blob( $repo, 'refs/karr/tasks/1/data' ), $before,
    'materialize then import leaves the ref byte-identical' );
};

subtest 'karr reads a task file written by kanban-md' => sub {
  # Not a file karr produced: a plain UTF-8 kanban-md card. Under #53 the whole
  # import died with "YAML::XS::Load Error: invalid trailing UTF-8 octet", so
  # the interop goal was broken for every non-ASCII board.
  my $repo = _init_repo();
  my $tasks = path($repo)->child('tasks');
  $tasks->mkpath;

  my $doc = join '',
    "---\n",
    "id: 1\n",
    "title: " . $TITLE . "\n",
    "status: backlog\n",
    "priority: medium\n",
    "class: standard\n",
    "created: 2026-01-01T00:00:00Z\n",
    "updated: 2026-01-01T00:00:00Z\n",
    "tags:\n",
    "- " . $TAG . "\n",
    "---\n",
    "\n",
    $BODY . "\n";
  { open my $fh, '>:raw', $tasks->child('001-cafe.md')->stringify or die $!;
    print {$fh} encode_utf8($doc);
    close $fh }

  my $direct = App::karr::Task->from_file( $tasks->child('001-cafe.md') );
  is( $direct->title, $TITLE, 'from_file decodes a kanban-md title' );
  is( $direct->body,  $BODY,  'from_file decodes a kanban-md body' );
  is_deeply( $direct->tags, [$TAG], 'from_file decodes a kanban-md tag' );

  my $rv = _run_karr( $repo, 'import', '--yes' );
  is( $rv->{exit}, 0, 'import --yes succeeds on a kanban-md view' ) or diag $rv->{stderr};
  unlike( $rv->{stderr}, qr/invalid trailing UTF-8 octet/, 'no YAML::XS decode error' );

  is_single_utf8( _blob( $repo, 'refs/karr/tasks/1/data' ), $TITLE, 'imported ref title' );
  is( App::karr::Git->new( dir => $repo )->load_task_ref(1)->title, $TITLE,
    'and it reads back as the same characters' );
};

subtest 'backup and restore preserve a non-ASCII board' => sub {
  my $repo = _init_repo();
  is( _run_karr( $repo, 'init', '--name', 'Snap Board' )->{exit}, 0, 'board initialized' );
  is(
    _run_karr( $repo, 'create', encode_utf8($TITLE),
      '--body', encode_utf8($BODY), '--tags', encode_utf8($TAG) )->{exit},
    0, 'task created'
  );
  my $before = _blob( $repo, 'refs/karr/tasks/1/data' );

  my $file = path($repo)->child('snapshot.yml');
  is( _run_karr( $repo, 'backup', '--output', "$file" )->{exit}, 0, 'backup --output exits 0' );

  my $raw = do { open my $fh, '<:raw', "$file" or die $!; local $/; <$fh> };
  is_single_utf8( $raw, $TITLE, 'snapshot file title' );

  is( _run_karr( $repo, 'restore', '--yes', '--input', "$file" )->{exit}, 0, 'restore exits 0' );

  # Not a byte-for-byte comparison: Git::read_ref chomps the payload's trailing
  # newline to match the old `git cat-file` behaviour, so a backup/restore cycle
  # has always dropped exactly that one byte -- on ASCII boards too, and on
  # 0.402 as well. That is a separate defect; what this subtest is about is that
  # no character is mangled on the way through.
  my $after = _blob( $repo, 'refs/karr/tasks/1/data' );
  is( $after, ( $before =~ s/\n\z//r ), 'the restored ref is the original payload (less the chomped newline)' );
  is_single_utf8( $after, $TITLE, 'restored ref title' );
  is_single_utf8( $after, $BODY,  'restored ref body' );

  my $task = App::karr::Git->new( dir => $repo )->load_task_ref(1);
  is( $task->title, $TITLE, 'restored title reads back as characters' );
  is( $task->body,  $BODY,  'restored body reads back as characters' );
  is_deeply( $task->tags, [$TAG], 'restored tag reads back as characters' );
};

subtest 'the two entry points install the boundary' => sub {
  # The boundary only exists if the scripts set it up; a command body doing it
  # for itself is exactly the per-call-site encoding #53 removed. Pinning the
  # two call sites keeps a future refactor from quietly dropping one.
  for my $script (qw( karr karr-foundation )) {
    my $src = path($ROOT)->child( 'bin', $script )->slurp_utf8;
    like( $src, qr/^enable_std_utf8\(\);/m, "bin/$script puts the UTF-8 layer on stdout/stderr" );
    like( $src, qr/^decode_argv\(\);/m,     "bin/$script decodes \@ARGV" );
  }
};

subtest 'repair_mojibake only touches what is unambiguously double-encoded' => sub {
  # The one heuristic in the encoding boundary, used for boards written by
  # 0.402 or earlier.
  # Its safety rests on these four cases.
  is( repair_mojibake('plain ascii'), 'plain ascii', 'ASCII is returned unchanged' );
  is( repair_mojibake($TITLE), $TITLE, 'text with a real wide character is left alone' );

  # Latin-1 that is not valid UTF-8 when read back as bytes: "\x{fc}ber" is
  # fc 62, an unfinished sequence. Nothing to undo, so nothing is undone.
  is( repair_mojibake("\x{fc}ber"), "\x{fc}ber", 'lone Latin-1 text is left alone' );

  # The actual corruption: the UTF-8 octets of $TITLE read as Latin-1.
  my $broken = decode( 'ISO-8859-1', encode_utf8($TITLE) );
  isnt( $broken, $TITLE, 'the fixture really is mojibake to begin with' );
  is( repair_mojibake($broken), $TITLE, 'double-encoded text is repaired' );

  is_deeply(
    repair_mojibake( { title => $broken, tags => [ decode( 'ISO-8859-1', encode_utf8($TAG) ) ], id => 4 } ),
    { title => $TITLE, tags => [$TAG], id => 4 },
    'hashes and arrays are walked, non-strings pass through'
  );
  is( repair_mojibake( repair_mojibake($broken) ), $TITLE, 'repairing an already-repaired string is a no-op' );
};

done_testing;
