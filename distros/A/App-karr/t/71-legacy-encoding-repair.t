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
use YAML::XS ();
use JSON::MaybeXS qw( encode_json decode_json );
use Encode qw( encode_utf8 decode );

use App::karr::Git;
use App::karr::Encoding qw( BOARD_ENCODING_VERSION );

# Ticket #53, the half that is about boards that already exist.
#
# karr up to 0.402 fed YAML::XS::Dump the *octets* of every frontmatter value
# (because @ARGV was never decoded) and Dump encoded them a second time, so
# every board written by those versions carries double-encoded UTF-8 in its task
# frontmatter, its config, and its activity log. Task bodies do not: they were
# concatenated onto the document verbatim and are singly encoded. Fixing the
# encoding without accounting for that would have turned every existing board's
# titles into visible mojibake.
#
# The decision, and what this file pins:
#
#   * refs/karr/meta/encoding is the discriminator. Absent => a board written
#     by 0.402 or earlier,
#     read through App::karr::Encoding::repair_mojibake. Present and >= 2 =>
#     hands off, no guessing, forever.
#   * `karr init` and `karr import --yes` stamp it; `karr repair --yes` migrates
#     an old board and stamps it.
#   * The repair is idempotent and never touches a ref whose payload is ASCII.
#
# The legacy fixtures below are not an approximation. _legacy_task_doc was
# checked byte-for-byte against what karr 0.402 actually wrote for the same
# input before this test was committed.

# Failure diagnostics compare character strings; without this they would warn
# "Wide character in print" and render the mojibake and the repaired text
# identically, which is exactly the confusion this file exists to resolve.
binmode( Test::More->builder->$_, ':encoding(UTF-8)' )
  for qw( output failure_output todo_output );

my $ROOT = abs_path('.');
my $BIN  = "$ROOT/bin/karr";

my $TITLE = "Legacy \x{dc}nicode \x{2014} task";
my $BODY  = "Body caf\x{e9} \x{2014} na\x{ef}ve";
my $TAG   = "gr\x{fc}n";
my $NAME  = "Legacy B\x{f6}";

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

sub _blob {
  my ( $repo, $ref ) = @_;
  open my $fh, '-|', 'git', '-C', $repo, 'cat-file', '-p', "$ref:data" or die "git cat-file: $!";
  binmode $fh;
  my $raw = do { local $/; <$fh> };
  close $fh;
  return defined $raw ? $raw : '';
}

sub _oid {
  my ( $repo, $ref ) = @_;
  my $out = `git -C $repo rev-parse $ref 2>/dev/null`;
  chomp $out;
  return $out;
}

# Store an exact byte payload in a ref -- the only way to plant something the
# current code would never produce. write_ref encodes its argument as UTF-8, so
# it is handed the UTF-8 decoding of the bytes we want and writes them back
# verbatim. A double-encoded document is still structurally valid UTF-8, which
# is exactly why this works (and why the corruption was invisible for so long).
sub _plant {
  my ( $git, $ref, $bytes ) = @_;
  my $chars = decode( 'UTF-8', $bytes, Encode::FB_CROAK | Encode::LEAVE_SRC );
  $git->write_ref( $ref, $chars );
  die "planted payload for $ref did not round-trip" unless _blob_matches( $git, $ref, $bytes );
  return 1;
}

# read_ref chomps one trailing newline, so compare through git itself.
sub _blob_matches {
  my ( $git, $ref, $bytes ) = @_;
  return _blob( $git->dir->stringify, $ref ) eq $bytes;
}

# Exactly what karr 0.402 wrote: Dump over octets (double encode) for the
# frontmatter, the body appended as raw octets (single encode).
sub _legacy_task_doc {
  my (%args) = @_;
  my %fm = (
    id       => $args{id},
    title    => encode_utf8( $args{title} ),
    status   => $args{status} // 'backlog',
    priority => 'medium',
    class    => 'standard',
    created  => '2026-01-01T00:00:00Z',
    updated  => '2026-01-02T03:04:05Z',
  );
  $fm{tags} = [ map { encode_utf8($_) } @{ $args{tags} } ] if $args{tags};
  my $yaml = YAML::XS::Dump( \%fm );
  $yaml =~ s/\A---\n//;
  my $doc = "---\n${yaml}---\n";
  $doc .= "\n" . encode_utf8( $args{body} ) . "\n" if defined $args{body};
  return $doc;
}

sub _legacy_config_doc {
  my ($name) = @_;
  return YAML::XS::Dump( { version => 1, board => { name => encode_utf8($name) } } );
}

sub _legacy_log_doc {
  my ($detail) = @_;
  return encode_json(
    { ts => '2026-01-01T00:00:00Z', agent => 'legacy', action => 'edit', detail => encode_utf8($detail) } );
}

# A board exactly as 0.402 left it: no refs/karr/meta/encoding, one non-ASCII
# task, one pure-ASCII task, a non-ASCII config and a non-ASCII log entry.
sub _legacy_board {
  my $repo = _init_repo();
  my $git  = App::karr::Git->new( dir => $repo );
  _plant( $git, 'refs/karr/config', _legacy_config_doc($NAME) );
  $git->write_ref( 'refs/karr/meta/next-id', "3\n" );
  _plant( $git, 'refs/karr/tasks/1/data',
    _legacy_task_doc( id => 1, title => $TITLE, body => $BODY, tags => [$TAG] ) );
  _plant( $git, 'refs/karr/tasks/2/data',
    _legacy_task_doc( id => 2, title => 'Pure ascii task', body => 'plain body' ) );
  _plant( $git, 'refs/karr/log/agent/legacy', _legacy_log_doc("blocked on \x{fc}bergang") );
  return ( $repo, $git );
}

# A card in a file view, written the way any correct tool writes one: singly
# encoded UTF-8 octets on disk. This is what import reads back into refs.
sub _write_view_card {
  my ( $repo, $id, $title, $body ) = @_;
  mkdir "$repo/tasks" unless -d "$repo/tasks";
  my $doc = <<"MD";
---
id: $id
title: $title
status: backlog
priority: medium
class: standard
created: 2026-01-01T00:00:00Z
updated: 2026-01-01T00:00:00Z
---

$body
MD
  open my $fh, '>', "$repo/tasks/$id-card.md" or die "open: $!";
  binmode $fh;
  print {$fh} encode_utf8($doc);
  close $fh;
  return 1;
}

subtest 'the legacy fixture really is double-encoded' => sub {
  my ( $repo, $git ) = _legacy_board();

  my $blob = _blob( $repo, 'refs/karr/tasks/1/data' );
  is( index( $blob, encode_utf8($TITLE) ), -1,
    'the title is not in the ref as singly-encoded UTF-8' );
  ok( index( $blob, encode_utf8($BODY) ) >= 0,
    'but the body is -- bodies never went through Dump' );

  ok( !$git->ref_exists('refs/karr/meta/encoding'), 'and there is no encoding marker' );
  is( $git->board_encoding_version, 1, 'so the board reads as encoding version 1' );
  ok( $git->board_is_legacy_encoded, 'and is treated as legacy' );
};

subtest 'a legacy board still reads correctly before any migration' => sub {
  my ( $repo, $git ) = _legacy_board();

  my $task = $git->load_task_ref(1);
  is( $task->title, $TITLE, 'title is repaired on read' );
  is( $task->body,  $BODY,  'body is passed through untouched (it was never broken)' );
  is_deeply( $task->tags, [$TAG], 'tags are repaired on read' );

  is( $git->read_config_ref->{board}{name}, $NAME, 'config is repaired on read' );

  my $show = _run_karr( $repo, 'show', '1', '--json' );
  is( $show->{exit}, 0, 'show --json exits 0' ) or diag $show->{stderr};
  my $data = decode_json( $show->{stdout} );
  is( $data->{title}, $TITLE, 'and --json hands out the right characters' );
  is( $data->{body},  $BODY,  'body too' );

  my $log = _run_karr( $repo, 'log', '--json' );
  is( $log->{exit}, 0, 'log --json exits 0' );
  is( decode_json( $log->{stdout} )->[0]{detail}, "blocked on \x{fc}bergang",
    'log entries are repaired on read as well' );
};

subtest 'karr repair reports before it writes' => sub {
  my ( $repo, $git ) = _legacy_board();
  my %before = map { $_ => _oid( $repo, $_ ) } $git->list_refs('refs/karr/');

  my $rv = _run_karr( $repo, 'repair' );
  is( $rv->{exit}, 0, 'the dry run exits 0' ) or diag $rv->{stderr};
  like( $rv->{stdout}, qr/Would repair 3 ref\(s\)/, 'it names how many refs it would touch' );
  like( $rv->{stdout}, qr{refs/karr/config},            'the config ref is listed' );
  like( $rv->{stdout}, qr{refs/karr/tasks/1/data},      'the non-ASCII task is listed' );
  like( $rv->{stdout}, qr{refs/karr/log/agent/legacy},  'the log ref is listed' );
  unlike( $rv->{stdout}, qr{refs/karr/tasks/2/data},    'the ASCII task is not' );
  like( $rv->{stdout}, qr/--yes/, 'and it says how to apply' );

  my %after = map { $_ => _oid( $repo, $_ ) } $git->list_refs('refs/karr/');
  is_deeply( \%after, \%before, 'a dry run changes nothing at all' );
};

subtest 'karr repair --yes migrates the board and leaves ASCII alone' => sub {
  my ( $repo, $git ) = _legacy_board();
  my $ascii_before = _oid( $repo, 'refs/karr/tasks/2/data' );
  my $updated_before = $git->load_task_ref(1)->updated;

  my $rv = _run_karr( $repo, 'repair', '--yes' );
  is( $rv->{exit}, 0, 'repair --yes exits 0' ) or diag $rv->{stderr};
  like( $rv->{stdout}, qr/Repaired 3 ref\(s\)/, 'it reports what it did' );

  is( _oid( $repo, 'refs/karr/tasks/2/data' ), $ascii_before,
    'the ASCII task ref is byte-identical -- not even re-serialized' );

  my $blob = _blob( $repo, 'refs/karr/tasks/1/data' );
  ok( index( $blob, encode_utf8($TITLE) ) >= 0, 'the repaired ref holds singly-encoded UTF-8' );
  is( index( $blob, encode_utf8( encode_utf8($TITLE) ) ), -1, 'and no trace of the double encode' );

  my $fresh = App::karr::Git->new( dir => $repo );
  is( $fresh->board_encoding_version, BOARD_ENCODING_VERSION, 'the board is stamped' );
  ok( !$fresh->board_is_legacy_encoded, 'so nothing repairs on read any more' );

  my $task = $fresh->load_task_ref(1);
  is( $task->title, $TITLE, 'the title still reads as the same characters' );
  is( $task->body,  $BODY,  'and so does the body' );
  is_deeply( $task->tags, [$TAG], 'and the tags' );
  is( $task->updated, $updated_before, 'the migration did not bump the updated timestamp' );

  is( $fresh->read_config_ref->{board}{name}, $NAME, 'the config still reads correctly' );

  my $log = _run_karr( $repo, 'log', '--json' );
  is( decode_json( $log->{stdout} )->[0]{detail}, "blocked on \x{fc}bergang",
    'and so does the log' );
};

subtest 'karr repair is idempotent' => sub {
  my ( $repo, $git ) = _legacy_board();
  is( _run_karr( $repo, 'repair', '--yes' )->{exit}, 0, 'first run migrates' );
  my %after_first = map { $_ => _oid( $repo, $_ ) } $git->list_refs('refs/karr/');

  my $second = _run_karr( $repo, 'repair', '--yes' );
  is( $second->{exit}, 0, 'second run exits 0' );
  like( $second->{stdout}, qr/already at version 2/, 'and says there is nothing to do' );

  my %after_second = map { $_ => _oid( $repo, $_ ) } $git->list_refs('refs/karr/');
  is_deeply( \%after_second, \%after_first, 'the second run changes nothing' );

  my $dry = _run_karr( $repo, 'repair' );
  is( $dry->{exit}, 0, 'a later dry run exits 0 too' );
  like( $dry->{stdout}, qr/already at version 2/, 'and reports the board as current' );
};

subtest 'a card whose only non-ASCII is in the body is not rewritten' => sub {
  # Bodies were never double-encoded -- they were appended to the document
  # verbatim, outside YAML::XS::Dump -- so such a card needs no repair at all.
  # It is also the case that is easy to get wrong: read_ref chomps a trailing
  # newline and the re-serialized document has one, so a naive comparison marks
  # every one of them as changed. On karr's own board that was 63 refs to
  # rewrite instead of 18.
  my $repo = _init_repo();
  my $git  = App::karr::Git->new( dir => $repo );
  _plant( $git, 'refs/karr/config', _legacy_config_doc('Ascii Titles') );
  $git->write_ref( 'refs/karr/meta/next-id', "2\n" );
  _plant( $git, 'refs/karr/tasks/1/data',
    _legacy_task_doc( id => 1, title => 'Ascii title', body => $BODY ) );
  my $before = _oid( $repo, 'refs/karr/tasks/1/data' );

  my $dry = _run_karr( $repo, 'repair' );
  unlike( $dry->{stdout}, qr{refs/karr/tasks/1/data},
    'the dry run does not list a body-only card' );

  is( _run_karr( $repo, 'repair', '--yes' )->{exit}, 0, 'repair --yes exits 0' );
  is( _oid( $repo, 'refs/karr/tasks/1/data' ), $before, 'and the card ref is untouched' );

  is( App::karr::Git->new( dir => $repo )->load_task_ref(1)->body, $BODY,
    'the body still reads correctly afterwards' );
};

subtest 'an all-ASCII legacy board comes out bit-identical' => sub {
  my $repo = _init_repo();
  my $git  = App::karr::Git->new( dir => $repo );
  _plant( $git, 'refs/karr/config', _legacy_config_doc('Plain Board') );
  $git->write_ref( 'refs/karr/meta/next-id', "2\n" );
  _plant( $git, 'refs/karr/tasks/1/data',
    _legacy_task_doc( id => 1, title => 'Plain task', body => 'plain body' ) );

  my %before = map { $_ => _oid( $repo, $_ ) } $git->list_refs('refs/karr/');

  my $rv = _run_karr( $repo, 'repair', '--yes' );
  is( $rv->{exit}, 0, 'repair --yes exits 0' );
  like( $rv->{stdout}, qr/No double-encoded payloads found/, 'nothing needed repairing' );

  my %after = map { $_ => _oid( $repo, $_ ) } $git->list_refs('refs/karr/');
  delete $after{'refs/karr/meta/encoding'};
  is_deeply( \%after, \%before, 'every payload ref is untouched; only the marker was added' );
  is( App::karr::Git->new( dir => $repo )->board_encoding_version, BOARD_ENCODING_VERSION,
    'and the board is stamped so it is never guessed at again' );
};

subtest 'init and import stamp only a board they create themselves' => sub {
  my $repo = _init_repo();
  is( _run_karr( $repo, 'init', '--name', 'Fresh Board' )->{exit}, 0, 'board initialized' );

  my $git = App::karr::Git->new( dir => $repo );
  is( $git->board_encoding_version, BOARD_ENCODING_VERSION, 'karr init stamps the marker' );

  my $rv = _run_karr( $repo, 'repair' );
  like( $rv->{stdout}, qr/already at version 2/, 'a fresh board needs no migration' );

  # Import's other half: on a repository with nothing under refs/karr/ it is a
  # board-birth path, and there the claim is true -- every ref the board has
  # came out of this import's character-level file reads.
  my $bootstrap = _init_repo();
  _write_view_card( $bootstrap, 1, $TITLE, $BODY );
  is( _run_karr( $bootstrap, 'import', '--yes' )->{exit}, 0, 'import bootstraps a board' );

  my $born = App::karr::Git->new( dir => $bootstrap );
  is( $born->board_encoding_version, BOARD_ENCODING_VERSION,
    'and stamps the board it just created' );
  is( $born->load_task_ref(1)->title, $TITLE, 'with the card intact' );

  # But not on a board that was already there. Import replaces the task refs and
  # leaves everything else alone -- the activity log above all -- so on a 0.402
  # board the marker would declare double-encoded payloads clean and turn off
  # the read repair that is the only reason they still read right (#132).
  my ( $legacy_repo, $legacy_git ) = _legacy_board();
  is( _run_karr( $legacy_repo, 'materialize' )->{exit}, 0, 'legacy board materializes' );
  is( _run_karr( $legacy_repo, 'import', '--yes' )->{exit}, 0, 'and imports back' );

  my $after = App::karr::Git->new( dir => $legacy_repo );
  ok( $after->board_is_legacy_encoded,
    'import does not stamp a board it merely wrote into' );
  is( $after->load_task_ref(1)->title, $TITLE, 'the card survived the trip' );
  ok( index( _blob( $legacy_repo, 'refs/karr/tasks/1/data' ), encode_utf8($TITLE) ) >= 0,
    'and its ref is singly encoded afterwards' );
  is( decode_json( _run_karr( $legacy_repo, 'log', '--json' )->{stdout} )->[0]{detail},
    "blocked on \x{fc}bergang",
    'while the log ref import never touched still reads correctly' );

  # And the command that may stamp -- because it rewrites every ref -- still can.
  is( _run_karr( $legacy_repo, 'repair', '--yes' )->{exit}, 0, 'karr repair --yes runs' );
  my $migrated = App::karr::Git->new( dir => $legacy_repo );
  ok( !$migrated->board_is_legacy_encoded, 'and finishes the migration import left open' );
  is( $migrated->load_task_ref(1)->title, $TITLE, 'card still correct' );
  is( decode_json( _run_karr( $legacy_repo, 'log', '--json' )->{stdout} )->[0]{detail},
    "blocked on \x{fc}bergang", 'log still correct' );
};

subtest 'init on a legacy half-board does not claim its payloads are current' => sub {
  # Ticket #132. init completes a half-board -- task refs present,
  # refs/karr/config missing (#62) -- and used to stamp the encoding marker on
  # the way out regardless. On a board written by 0.402 that assertion is false:
  # the cards it adopts are double-encoded, the marker switches the read repair
  # off, and `karr repair` then calls the board up to date and declines. Nothing
  # in the refs changes, which is why this asserts on what the board *reads* as.
  my $repo = _init_repo();
  my $git  = App::karr::Git->new( dir => $repo );
  $git->write_ref( 'refs/karr/meta/next-id', "2\n" );
  _plant( $git, 'refs/karr/tasks/1/data',
    _legacy_task_doc( id => 1, title => $TITLE, body => $BODY, tags => [$TAG] ) );
  _plant( $git, 'refs/karr/log/agent/legacy', _legacy_log_doc("blocked on \x{fc}bergang") );

  ok( !$git->ref_exists('refs/karr/config'), 'setup: a half-board, no config ref' );
  is( decode_json( _run_karr( $repo, 'show', '1', '--json' )->{stdout} )->{title},
    $TITLE, 'setup: and it reads correctly before init' );

  my $init = _run_karr( $repo, 'init', '--name', 'Completed' );
  is( $init->{exit}, 0, 'init completes the half-board rather than refusing it (#62)' )
    or diag $init->{stderr};
  like( $init->{stdout}, qr/Completed a half-board/, 'and says that is what it did' );
  is( _run_karr( $repo, 'config', 'get', 'board.name' )->{stdout}, "Completed\n",
    'the config it was there to write is written' );

  my $after = App::karr::Git->new( dir => $repo );
  ok( !$after->ref_exists('refs/karr/meta/encoding'), 'no encoding marker was stamped' );
  ok( $after->board_is_legacy_encoded, 'so the board is still treated as legacy' );

  my $show = _run_karr( $repo, 'show', '1', '--json' );
  is( $show->{exit}, 0, 'show --json still exits 0' ) or diag $show->{stderr};
  my $data = decode_json( $show->{stdout} );
  is( $data->{title}, $TITLE, 'and the card reads exactly as it did before init' );
  is( $data->{body},  $BODY,  'body too' );
  is_deeply( $data->{tags}, [$TAG], 'and the tags' );
  is( decode_json( _run_karr( $repo, 'log', '--json' )->{stdout} )->[0]{detail},
    "blocked on \x{fc}bergang", 'the activity log still reads correctly as well' );

  # The recovery path stays open: repair used to answer "already at version 2".
  my $dry = _run_karr( $repo, 'repair' );
  is( $dry->{exit}, 0, 'karr repair exits 0' );
  unlike( $dry->{stdout}, qr/already at version/,
    'and does not report the board as up to date' );
  like( $dry->{stdout}, qr{refs/karr/tasks/1/data}, 'it still sees the legacy card' );
  like( $dry->{stdout}, qr{refs/karr/log/agent/legacy}, 'and the legacy log entry' );

  is( _run_karr( $repo, 'repair', '--yes' )->{exit}, 0, 'karr repair --yes runs' );
  my $migrated = App::karr::Git->new( dir => $repo );
  ok( !$migrated->board_is_legacy_encoded, 'the board is migrated and stamped' );
  is( $migrated->load_task_ref(1)->title, $TITLE, 'with the card still correct' );
};

subtest 'a stamped board is never second-guessed, even when its text looks like mojibake' => sub {
  # This is the whole reason the repair is gated on a marker instead of running
  # on every read: "\x{c3}\x{a9}" is a legitimate two-character string that also
  # happens to be the UTF-8 bytes of "\x{e9}". On a stamped board karr must
  # store and return it verbatim.
  my $repo = _init_repo();
  is( _run_karr( $repo, 'init', '--name', 'Literal Board' )->{exit}, 0, 'board initialized' );

  my $looks_broken = "caf\x{c3}\x{a9} \x{c3}\x{bc}ber";
  is( _run_karr( $repo, 'create', encode_utf8($looks_broken) )->{exit}, 0, 'task created' );

  my $git = App::karr::Git->new( dir => $repo );
  is( $git->load_task_ref(1)->title, $looks_broken,
    'the mojibake-looking title is returned exactly as it was given' );

  my $show = _run_karr( $repo, 'show', '1', '--json' );
  is( decode_json( $show->{stdout} )->{title}, $looks_broken, 'and --json agrees' );

  # And the marker is what makes that true, not luck. Drop it and the same,
  # correctly written ref is read as if it were double-encoded -- which is the
  # exact cost of the heuristic, and the reason it is gated instead of
  # permanent. (A real 0.402 board cannot hit this: everything non-ASCII it
  # wrote genuinely was double-encoded, so undoing that is always right there.)
  system( 'git', '-C', $repo, 'update-ref', '-d', 'refs/karr/meta/encoding' );
  my $unstamped = App::karr::Git->new( dir => $repo );
  ok( $unstamped->board_is_legacy_encoded, 'without the marker the board reads as legacy' );
  isnt( $unstamped->load_task_ref(1)->title, $looks_broken,
    'and the literal string is then "repaired" into something else' );

  $unstamped->write_encoding_version;
  is( App::karr::Git->new( dir => $repo )->load_task_ref(1)->title, $looks_broken,
    'putting the marker back makes it verbatim again' );
};

subtest 'repair says so when it cannot parse a ref instead of skipping quietly' => sub {
  my ( $repo, $git ) = _legacy_board();
  my $junk = "this is not a task document, \x{fc}\n";
  _plant( $git, 'refs/karr/tasks/5/data', encode_utf8($junk) );
  my $junk_oid = _oid( $repo, 'refs/karr/tasks/5/data' );

  my $rv = _run_karr( $repo, 'repair', '--yes' );
  is( $rv->{exit}, 0, 'repair still completes' );
  like( $rv->{stderr}, qr/Left 1 ref\(s\) unchanged/, 'the unparseable ref is reported' );
  like( $rv->{stderr}, qr{refs/karr/tasks/5/data},     'and named' );

  is( _oid( $repo, 'refs/karr/tasks/5/data' ), $junk_oid, 'and left exactly as it was' );
  is( App::karr::Git->new( dir => $repo )->load_task_ref(1)->title, $TITLE,
    'the refs it could parse were still repaired' );
};

subtest 'repair refuses on a repo without a board' => sub {
  my $repo = _init_repo();
  my $rv = _run_karr( $repo, 'repair' );
  isnt( $rv->{exit}, 0, 'repair on an uninitialized repo fails' );
  like( $rv->{stderr}, qr/No karr board found/, 'and says why' );
};

done_testing;
