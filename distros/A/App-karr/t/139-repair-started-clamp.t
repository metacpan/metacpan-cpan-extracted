# t/139-repair-started-clamp.t - ticket #138: `karr repair` raises a `started`
# stamp that precedes its own card's `created` up to that `created`.
#
# karr wrote `started` as a bare YYYY-MM-DD date until ticket #68. A bare date
# reads as midnight UTC, so a card filed at 16:11 and picked up the same day
# carries a start earlier than its own creation -- 75 of the 116 finished cards
# on karr's own board. `karr metrics` can measure nothing from such a stamp and
# leaves those cards out of its averages entirely.
#
# What this file pins, beyond "the number goes up":
#
#   * The criterion. Only the *known* bug is migrated: a bare-date `started`
#     under a `created` in karr's own YYYY-MM-DDTHH:MM:SSZ spelling, whose
#     midnight really does precede it. A start that precedes its card while
#     carrying a time of day is a different, unknown fault, and clamping it
#     would erase the only evidence that it happened -- so it is reported and
#     left exactly as it is. Two boards would look identical afterwards
#     otherwise.
#   * The two findings stay apart. `repair` had one job before this; a board
#     can need either migration without the other, and a run that merged the
#     two reports would leave a user unable to see which one concerns them.
#     In particular an encoding-current board no longer returns early.
#   * The price is in the output, not only in the POD. A clamped card asserts
#     zero queue time and no longer records that its stamp was ever
#     day-granular; neither is readable from the data afterwards. And where
#     `completed` is itself a bare date falling before the new `started` -- 42
#     of those 75 cards -- the clamp *creates* an ordering that was not there
#     before, so it is named by the run that does it rather than discovered on
#     the next invocation.
#   * `updated` is not bumped. A migration that re-dated every card it touched
#     would destroy more history than it repaired.
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
use YAML::XS ();
use Encode qw( encode_utf8 decode );

use App::karr::Git;
use App::karr::Task;

# Failure diagnostics compare character strings; without this the legacy
# subtest would warn "Wide character in print" and render the mojibake and the
# repaired text identically.
binmode( Test::More->builder->$_, ':encoding(UTF-8)' )
  for qw( output failure_output todo_output );

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

# A repository of its own every time, and never a remote: `repair --yes`
# rewrites refs and then pushes, and the board under test must not be able to
# reach anybody's real one.
sub _board {
  my $repo = tempdir( CLEANUP => 1 );
  system( 'git', 'init', '-q', $repo );
  system( 'git', '-C', $repo, 'config', 'user.email', 'test@example.com' );
  system( 'git', '-C', $repo, 'config', 'user.name',  'Test User' );
  my $rv = _run_karr( $repo, 'init', '--name', 'Clamp Board' );
  die "init failed: $rv->{stderr}" if $rv->{exit};
  is( scalar `git -C $repo remote 2>/dev/null`, '', 'the board under test has no remote' );
  return $repo;
}

sub _plant {
  my ( $repo, $id, %stamp ) = @_;
  my $task = App::karr::Task->new(
    id      => $id,
    title   => "card $id",
    status  => $stamp{status} // 'done',
    created => $stamp{created},
    updated => $stamp{updated} // $stamp{created},
  );
  $task->started( $stamp{started} )     if defined $stamp{started};
  $task->completed( $stamp{completed} ) if defined $stamp{completed};
  App::karr::Git->new( dir => $repo )->save_task_ref($task);
  return $task;
}

sub _card {
  my ( $repo, $id ) = @_;
  return App::karr::Git->new( dir => $repo )->load_task_ref($id);
}

sub _oids {
  my ($repo) = @_;
  my %oid;
  for my $line ( split /\n/, `git -C $repo for-each-ref --format='%(objectname) %(refname)' refs/karr/` ) {
    my ( $o, $r ) = split ' ', $line, 2;
    $oid{$r} = $o;
  }
  return \%oid;
}

# The population every criterion subtest below reasons about.
sub _mixed_board {
  my $repo = _board();
  # 1: the pre-#68 bug itself -- bare date, same day, midnight before creation.
  _plant( $repo, 1,
    created => '2026-07-02T02:03:51Z', started => '2026-07-02',
    completed => '2026-07-03T10:00:00Z' );
  # 2: bare date, but a *later* day. The start really did happen then; there is
  #    nothing wrong with it beyond its granularity, and clamping it back to
  #    creation would invent two days of work that never happened.
  _plant( $repo, 2,
    created => '2026-07-02T16:11:50Z', started => '2026-07-04',
    completed => '2026-07-05T10:00:00Z' );
  # 3: a full timestamp before creation -- not the #68 bug, cause unknown.
  _plant( $repo, 3,
    created => '2026-07-02T16:11:50Z', started => '2026-07-01T09:00:00Z',
    completed => '2026-07-05T10:00:00Z' );
  # 4: healthy.
  _plant( $repo, 4,
    created => '2026-07-02T10:00:00Z', started => '2026-07-02T11:00:00Z',
    completed => '2026-07-03T10:00:00Z' );
  # 5: never started.
  _plant( $repo, 5, created => '2026-07-02T10:00:00Z', status => 'backlog' );
  # 6: a bare date whose midnight *is* the creation instant. Nothing precedes
  #    anything here, so there is nothing to repair -- rewriting it would only
  #    change the stamp's spelling.
  _plant( $repo, 6,
    created => '2026-07-02T00:00:00Z', started => '2026-07-02',
    completed => '2026-07-03T10:00:00Z' );
  return $repo;
}

subtest 'the clamp criterion: only the pre-#68 bare-date stamp' => sub {
  my $repo = _mixed_board();

  my $rv = _run_karr( $repo, 'repair', '--yes' );
  is( $rv->{exit}, 0, 'repair --yes exits 0' ) or diag $rv->{stderr};

  is( _card( $repo, 1 )->started, '2026-07-02T02:03:51Z',
    'the bug case is raised to its own created, to the second' );

  is( _card( $repo, 2 )->started, '2026-07-04',
    'a bare date on a later day is left exactly as it was' );
  is( _card( $repo, 3 )->started, '2026-07-01T09:00:00Z',
    'a full timestamp before creation is left alone -- a different, unknown fault' );
  is( _card( $repo, 4 )->started, '2026-07-02T11:00:00Z', 'a healthy start is untouched' );
  ok( !_card( $repo, 5 )->has_started, 'a card that never started gains no start' );
  is( _card( $repo, 6 )->started, '2026-07-02',
    'a bare date equal to the creation instant precedes nothing and is not rewritten' );

  like( $rv->{stdout}, qr/Raised 'started' to 'created' on 1 card\(s\): 1\b/,
    'and the run says it touched exactly the one card' );
};

subtest 'the unclamped start before creation is reported, not swallowed' => sub {
  my $repo = _mixed_board();
  my $rv = _run_karr( $repo, 'repair' );
  is( $rv->{exit}, 0, 'the dry run exits 0' ) or diag $rv->{stderr};
  like( $rv->{stdout}, qr/Found and NOT repaired/, 'the survey section is printed' );
  like( $rv->{stdout},
    qr/1 card\(s\) with 'started' precedes 'created' in a shape this repair does not recognise[^\n]*: 3\n/,
    'and names the card it deliberately did not clamp' );
};

subtest 'a dry run reports and writes nothing' => sub {
  my $repo   = _mixed_board();
  my $before = _oids($repo);

  my $rv = _run_karr( $repo, 'repair' );
  is( $rv->{exit}, 0, 'exits 0' ) or diag $rv->{stderr};
  like( $rv->{stdout}, qr/Would raise 'started' to 'created' on 1 card\(s\): 1\b/,
    'it says what it would do' );
  like( $rv->{stdout}, qr/Run 'karr repair --yes' to apply/, 'and how to do it' );

  is_deeply( _oids($repo), $before, 'and not one ref moved' );
  is( _card( $repo, 1 )->started, '2026-07-02', 'the stamp is still the bare date' );
};

subtest 'the clamp does not bump updated, and is idempotent' => sub {
  my $repo = _board();
  _plant( $repo, 1,
    created => '2026-07-02T02:03:51Z', updated => '2026-07-09T18:00:00Z',
    started => '2026-07-02', completed => '2026-07-03T10:00:00Z' );

  is( _run_karr( $repo, 'repair', '--yes' )->{exit}, 0, 'first run exits 0' );
  my $card = _card( $repo, 1 );
  is( $card->started, '2026-07-02T02:03:51Z', 'the stamp is clamped' );
  is( $card->updated, '2026-07-09T18:00:00Z',
    'and updated is left alone -- a migration is not an edit' );

  my $after_first = _oids($repo);
  my $second = _run_karr( $repo, 'repair', '--yes' );
  is( $second->{exit}, 0, 'a second run exits 0' );
  like( $second->{stdout},
    qr/No card carries a bare-date 'started' that precedes its own 'created'/,
    'and finds nothing left to clamp' );
  is_deeply( _oids($repo), $after_first, 'so it changes nothing at all' );
};

subtest 'an encoding-current board is still surveyed and still clamped' => sub {
  # The regression this subtest exists for: while repair had only the encoding
  # job it returned the moment the marker said "version 2", which after #138
  # would mean the clamp never ran on any board written by a current karr --
  # i.e. on every board that has the bug and nothing else wrong with it.
  my $repo = _board();
  _plant( $repo, 1,
    created => '2026-07-02T02:03:51Z', started => '2026-07-02',
    completed => '2026-07-03T10:00:00Z' );

  my $rv = _run_karr( $repo, 'repair', '--yes' );
  is( $rv->{exit}, 0, 'exits 0' ) or diag $rv->{stderr};
  like( $rv->{stdout}, qr/Board encoding is already at version \d+; nothing to repair\./,
    'the encoding finding is still stated on its own terms' );
  like( $rv->{stdout}, qr/Raised 'started' to 'created' on 1 card\(s\)/,
    'and the stamp finding is stated separately, not folded into it' );
  is( _card( $repo, 1 )->started, '2026-07-02T02:03:51Z', 'the card is clamped' );
};

subtest 'both migrations run in one pass on a legacy board' => sub {
  # A 0.402 board has no refs/karr/meta/encoding, so its frontmatter is read
  # through repair_mojibake. The clamp writes the card back, and must write the
  # *repaired* document -- otherwise migrating the stamp would re-break the
  # encoding of every card it touches.
  my $repo = tempdir( CLEANUP => 1 );
  system( 'git', 'init', '-q', $repo );
  system( 'git', '-C', $repo, 'config', 'user.email', 'test@example.com' );
  system( 'git', '-C', $repo, 'config', 'user.name',  'Test User' );

  my $git = App::karr::Git->new( dir => $repo );
  $git->write_ref( 'refs/karr/config',       "version: 1\n" );
  $git->write_ref( 'refs/karr/meta/next-id', "2\n" );

  # Double-encoded UTF-8, exactly as 0.402 produced it: YAML::XS::Dump handed
  # octets and encoding them a second time. write_ref takes characters and
  # encodes once, so it is given the decoding of the bytes that must land in
  # the ref (the same trick t/71-legacy-encoding-repair.t plants with).
  my $title = "Gr\x{fc}n \x{2014} card";
  my $yaml  = YAML::XS::Dump( {
    id      => 1,
    title   => encode_utf8($title),
    status  => 'done',
    priority => 'medium',
    class   => 'standard',
    created => '2026-07-02T02:03:51Z',
    updated => '2026-07-02T02:03:51Z',
    started => '2026-07-02',
  } );
  $yaml =~ s/\A---\n//;
  $git->write_ref( 'refs/karr/tasks/1/data',
    decode( 'UTF-8', "---\n${yaml}---\n", Encode::FB_CROAK | Encode::LEAVE_SRC ) );

  ok( $git->board_is_legacy_encoded, 'setup: the board reads as legacy' );
  is( _card( $repo, 1 )->title, $title, 'setup: and its title reads correctly through the repair' );
  my $before = _card( $repo, 1 )->title;

  my $rv = _run_karr( $repo, 'repair', '--yes' );
  is( $rv->{exit}, 0, 'repair --yes exits 0' ) or diag $rv->{stderr};
  like( $rv->{stdout}, qr/Repaired 1 ref\(s\)/, 'the encoding finding is reported' );
  like( $rv->{stdout}, qr/Raised 'started' to 'created' on 1 card\(s\)/,
    'and the stamp finding separately' );

  my $fresh = App::karr::Git->new( dir => $repo );
  ok( !$fresh->board_is_legacy_encoded, 'the board is stamped as migrated' );
  my $card = $fresh->load_task_ref(1);
  is( $card->started, '2026-07-02T02:03:51Z', 'the stamp is clamped' );
  is( $card->title, $before,
    'and the title still reads as the same characters it did before the run' );
  unlike( $card->title, qr/\x{c3}/,
    'the clamp wrote the repaired document, not the double-encoded one' );
};

subtest 'the clamp names the ordering it creates, in the run that creates it' => sub {
  # `completed` was written day-granular by the same old karr and this command
  # does not touch it, so raising `started` to a `created` later that day steps
  # over it: the card's cycle time reads negative where before it was merely
  # absent. 42 of the 75 clamped cards on karr's own board are like this.
  my $repo = _board();
  _plant( $repo, 1,
    created => '2026-07-02T16:11:50Z', started => '2026-07-02',
    completed => '2026-07-02' );
  _plant( $repo, 2,
    created => '2026-07-02T02:03:51Z', started => '2026-07-02',
    completed => '2026-07-03T10:00:00Z' );

  my $dry = _run_karr( $repo, 'repair' );
  like( $dry->{stdout},
    qr/1 of them carries a bare-date 'completed' that would fall before the new 'started'/,
    'the dry run warns before anything is written' );
  like( $dry->{stdout}, qr/cycle time would read negative: 1\n/, 'and names the card' );
  like( $dry->{stdout}, qr/1 card\(s\) with 'completed' precedes 'started': 1\n/,
    'the survey counts the board as it would stand after --yes, not as it stands now' );

  my $rv = _run_karr( $repo, 'repair', '--yes' );
  like( $rv->{stdout},
    qr/1 of them carries a bare-date 'completed' that falls before the new 'started'/,
    'and the applying run states it in the indicative' );
  like( $rv->{stdout}, qr/cycle time reads negative: 1\n/, 'naming the same card' );

  is( _card( $repo, 1 )->started, '2026-07-02T16:11:50Z',
    'the card is clamped all the same -- the cost is reported, not avoided' );
};

subtest 'stamps this command does not repair are surveyed and named' => sub {
  my $repo = _board();
  # completed before created, and no start at all: nothing here is clampable.
  _plant( $repo, 1,
    created => '2026-07-02T16:11:50Z', completed => '2026-07-02' );
  # updated before created.
  _plant( $repo, 2,
    created => '2026-07-02T16:11:50Z', updated => '2026-07-01T09:00:00Z',
    status => 'backlog' );
  # A stamp shape karr cannot put in order against its own: kanban-md writes
  # RFC3339 with a local offset, and string order stops meaning time order the
  # moment two stamps sit in different zones.
  _plant( $repo, 3,
    created => '2026-07-02T18:11:03.449764553+02:00', started => '2026-07-02',
    completed => '2026-07-03T10:00:00Z' );
  # A ref that is not a card at all. A repair run must count it and carry on --
  # dying here would leave the board half-migrated.
  App::karr::Git->new( dir => $repo )->write_ref( 'refs/karr/tasks/4/data', "junk\n" );

  my $rv = _run_karr( $repo, 'repair' );
  is( $rv->{exit}, 0, 'the run completes despite the unparseable ref' ) or diag $rv->{stderr};
  like( $rv->{stdout}, qr/1 card\(s\) with 'completed' precedes 'created': 1\n/,   'completed before created' );
  like( $rv->{stdout}, qr/1 card\(s\) with 'updated' precedes 'created': 2\n/,     'updated before created' );
  like( $rv->{stdout}, qr/1 card\(s\) with a stamp in a shape karr cannot compare: 3\n/,
    'a stamp karr cannot compare' );
  like( $rv->{stdout}, qr/1 card\(s\) with a ref that does not parse as a card at all[^\n]*: 4\n/,
    'and a ref whose stamps were never examined -- not a silent "nothing found"' );

  is( _card( $repo, 3 )->started, '2026-07-02',
    'none of them is rewritten: this command clamps started only' );
};

subtest '--json keeps the two findings apart' => sub {
  my $repo = _mixed_board();

  my $dry = _run_karr( $repo, 'repair', '--json' );
  is( $dry->{exit}, 0, 'exits 0' ) or diag $dry->{stderr};
  my $data = decode_json( $dry->{stdout} );

  is_deeply( $data->{started_clamped}, [1], 'started_clamped carries the ids' );
  is( $data->{applied}, JSON::MaybeXS::false(), 'applied is false on a dry run' );
  is( $data->{up_to_date}, JSON::MaybeXS::true(),
    'up_to_date still answers for the encoding migration alone' );
  is_deeply( $data->{repaired}, [], 'which is why repaired is empty beside a non-empty clamp' );
  is_deeply( $data->{stamp_anomalies}{started_before_created_unclamped}, [3],
    'the unclamped fault is its own key' );
  is_deeply( $data->{started_clamped_over_completed}, [],
    'and nothing here steps over a completion' );

  my $applied = decode_json( _run_karr( $repo, 'repair', '--yes', '--json' )->{stdout} );
  is( $applied->{applied}, JSON::MaybeXS::true(), 'applied is true when the run wrote' );
  is_deeply( $applied->{started_clamped}, [1], 'and the same ids are reported as done' );

  my $again = decode_json( _run_karr( $repo, 'repair', '--json' )->{stdout} );
  is_deeply( $again->{started_clamped}, [], 'a later run has nothing left to clamp' );
  is_deeply( $again->{stamp_anomalies}{started_before_created_unclamped}, [3],
    'while the fault it refuses to touch is still reported every time' );
};

done_testing;
