# t/96-empty-optional-fields.t
#
# Ticket #59: an optional frontmatter field set to the empty string counted as
# "set", because Moo's predicate only knows whether the attribute was passed.
#
# That is exactly the shape kanban-md hands over. Go writes these fields with
# `omitempty`, so a card it produced omits them -- but a card it *read* and
# rewrote, or any hand-written one, carries `claimed_by: ""` and
# `block_reason: ""` verbatim, and `karr import` stores them as it found them.
# `karr pick` then read that empty string as a claim by somebody and skipped the
# card, so on a freshly imported kanban-md board it answered "No available tasks
# to pick." while `karr list` showed the very same work sitting in backlog. The
# whole point of the bridge is that an agent can pick up work that came in
# through it.
#
# The same assumption showed up wherever a predicate stood in for "has a value":
# `karr list` printed a bare "@" for `assignee: ""`, and `karr context` counted
# `due: ""` as overdue for ever, because the empty string sorts before every
# real date.
use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestGit qw( require_git_c );
require_git_c();
use Cwd qw( abs_path getcwd );
use File::Temp qw( tempdir );
use IPC::Open3 qw( open3 );
use JSON::MaybeXS qw( decode_json );
use Symbol qw( gensym );
use Time::Piece;
use YAML::XS qw( Dump );

use App::karr::Git;
use App::karr::BoardStore;
use App::karr::Task;
use App::karr::Cmd::Pick;
use App::karr::Cmd::List;
use App::karr::Cmd::Context;

my $ROOT = abs_path('.');
my $BIN  = "$ROOT/bin/karr";

# The exact card in the ticket: `blocked: false` (which Task normalises away
# already, per #58) plus the two empty strings that survive it.
my $KANBAN_CARD = <<'CARD';
---
id: 1
title: kanban-written
status: backlog
priority: high
blocked: false
block_reason: ""
claimed_by: ""
---
CARD

sub init_repo {
  my $repo = tempdir( CLEANUP => 1 );
  system( 'git', 'init', '-q', $repo ) == 0 or BAIL_OUT('git init failed');
  system( 'git', '-C', $repo, 'config', 'user.email', 'test@example.com' ) == 0
    or BAIL_OUT('git config failed');
  system( 'git', '-C', $repo, 'config', 'user.name', 'Test User' ) == 0
    or BAIL_OUT('git config failed');
  return $repo;
}

sub run_karr {
  my ( $cwd, @argv ) = @_;
  my $old = getcwd();
  chdir $cwd or die "chdir $cwd: $!";
  my $stderr = gensym;
  my $pid = open3( my $in, my $out, $stderr, $^X, "-I$ROOT/lib", $BIN, @argv );
  close $in;
  my $stdout = do { local $/; <$out> };
  my $errtxt = do { local $/; <$stderr> };
  waitpid( $pid, 0 );
  my $exit = $? >> 8;
  chdir $old or die "chdir $old: $!";
  return {
    exit   => $exit,
    stdout => ( defined $stdout ? $stdout : '' ),
    stderr => ( defined $errtxt ? $errtxt : '' ),
  };
}

# A ref-backed board carrying one task built from a raw kanban-md document, so
# the empty strings reach the store exactly as import would leave them.
sub board_with_card {
  my ($content) = @_;
  my $repo = init_repo();
  my $git  = App::karr::Git->new( dir => $repo );
  $git->write_ref( 'refs/karr/config',
    Dump( { version => 1, board => { name => 'Interop' } } ) );
  $git->write_ref( 'refs/karr/meta/next-id', "2\n" );
  my $store = App::karr::BoardStore->new( git => $git );
  $store->save_task( App::karr::Task->from_string($content) );
  return $store;
}

sub run_execute {
  my ( $cmd, @args ) = @_;
  my $out = '';
  my $err = do {
    local $@;
    eval {
      local *STDOUT;
      open STDOUT, '>', \$out or die $!;
      $cmd->execute( \@args, [] );
    };
    $@;
  };
  return ( $err, $out );
}

subtest 'the empty strings do not survive the import' => sub {
  my $store = board_with_card($KANBAN_CARD);
  my ($task) = $store->load_tasks;

  ok( $task, 'the card is on the board' );
  ok( !$task->has_blocked, 'blocked: false is normalised away (ticket #58)' );

  # This assertion is inverted from the one #59 left here, which recorded that
  # the empty strings reached the task untouched and named itself "the one to
  # revisit if a later change makes Task normalise them on load". Ticket #98 is
  # that change: an optional field whose value has no length now loads as
  # unset, which is the same fix for every reader at once. The behaviour
  # assertions below are unchanged and stay green either way -- which is the
  # point of having had them.
  ok( !$task->has_claimed_by,   'claimed_by: "" loads as no claim at all' );
  ok( !$task->has_block_reason, 'block_reason: "" loads as no reason at all' );
};

subtest 'pick claims a card whose claimed_by is the empty string' => sub {
  my $store = board_with_card($KANBAN_CARD);

  my $cmd = App::karr::Cmd::Pick->new( store => $store, claim => 'bob' );
  my ( $err, $out ) = run_execute($cmd);

  is( $err, '', 'pick does not die' ) or diag("died with: $err");
  like( $out, qr/Picked task 1: kanban-written/,
    'the imported card is pickable (was "No available tasks to pick.")' )
    or diag("got:\n$out");

  my ($task) = $store->load_tasks;
  is( $task->claimed_by, 'bob', 'the claim landed on the card' );
};

subtest 'a real claim is still a claim' => sub {
  my $store = board_with_card( <<'CARD' );
---
id: 1
title: taken
status: backlog
priority: high
claimed_by: alice
claimed_at: 2999-01-01T00:00:00Z
---
CARD

  my $cmd = App::karr::Cmd::Pick->new( store => $store, claim => 'bob' );
  my ( $err, $out ) = run_execute($cmd);

  is( $err, '', 'pick does not die' ) or diag("died with: $err");
  like( $out, qr/No available tasks to pick/,
    'a non-empty claim inside its timeout still hides the card' )
    or diag("got:\n$out");

  my ($task) = $store->load_tasks;
  is( $task->claimed_by, 'alice', 'alice keeps her claim' );
};

subtest 'an expired claim is still reaped' => sub {
  my $stale = gmtime( time - 86_400 )->datetime . 'Z';
  my $store = board_with_card( <<"CARD" );
---
id: 1
title: abandoned
status: backlog
priority: high
claimed_by: alice
claimed_at: $stale
---
CARD

  my $cmd = App::karr::Cmd::Pick->new( store => $store, claim => 'bob' );
  my ( $err, $out ) = run_execute($cmd);

  is( $err, '', 'pick does not die' ) or diag("died with: $err");
  like( $out, qr/Picked task 1: abandoned/,
    'a claim older than claim_timeout is still taken over' )
    or diag("got:\n$out");
};

subtest 'a blocked card is still skipped' => sub {
  my $store = board_with_card( <<'CARD' );
---
id: 1
title: stuck
status: backlog
priority: high
blocked: true
block_reason: waiting on upstream
claimed_by: ""
---
CARD

  my $cmd = App::karr::Cmd::Pick->new( store => $store, claim => 'bob' );
  my ( $err, $out ) = run_execute($cmd);

  is( $err, '', 'pick does not die' ) or diag("died with: $err");
  like( $out, qr/No available tasks to pick/,
    'blocked: true still wins over an empty claimed_by' )
    or diag("got:\n$out");
};

subtest 'list does not render an empty assignee as a bare @' => sub {
  my $store = board_with_card( <<'CARD' );
---
id: 1
title: nobody-assigned
status: backlog
priority: high
assignee: ""
---
CARD

  my $cmd = App::karr::Cmd::List->new( store => $store );
  my ( $err, $out ) = run_execute($cmd);

  is( $err, '', 'list does not die' ) or diag("died with: $err");
  like( $out, qr/\[high\]/, 'the meta list carries the priority alone' )
    or diag("got:\n$out");
  unlike( $out, qr/\@/, 'no "@" is printed for an empty assignee' )
    or diag("got:\n$out");
};

subtest 'context does not count an empty due date as overdue' => sub {
  my $store = board_with_card( <<'CARD' );
---
id: 1
title: no-due-date
status: backlog
priority: high
due: ""
---
CARD

  my $cmd = App::karr::Cmd::Context->new( store => $store );
  my ( $err, $out ) = run_execute($cmd);

  is( $err, '', 'context does not die' ) or diag("died with: $err");
  like( $out, qr/\| 0 overdue/, 'the summary counts no overdue task' )
    or diag("got:\n$out");
  unlike( $out, qr/### Overdue/, 'and renders no Overdue section' )
    or diag("got:\n$out");
};

subtest 'context --json omits an empty assignee rather than emitting ""' => sub {
  my $store = board_with_card( <<'CARD' );
---
id: 1
title: unassigned
status: in-progress
priority: high
assignee: ""
---
CARD

  my $cmd = App::karr::Cmd::Context->new( store => $store, json => 1 );
  my ( $err, $out ) = run_execute($cmd);

  is( $err, '', 'context --json does not die' ) or diag("died with: $err");
  my $data = eval { decode_json($out) };
  ok( $data, 'the payload decodes' ) or diag("decode failed: $@\ngot:\n$out");

  my ($item) = map { @{ $_->{items} } } @{ $data->{sections} || [] };
  ok( $item, 'the in-progress task is in a section' ) or return;
  ok( !exists $item->{assignee},
    'no assignee key is emitted for an empty assignee' )
    or diag( 'got assignee: ' . ( $item->{assignee} // '(undef)' ) );
};

# The reported reproduction, end to end through the CLI: a kanban-md file view
# imported with `karr import --yes`, then picked.
subtest 'karr import then karr pick, through the CLI' => sub {
  my $repo = init_repo();

  is( run_karr( $repo, 'init', '--name', 'Interop' )->{exit}, 0, 'karr init' );

  mkdir "$repo/tasks" or die "mkdir $repo/tasks: $!";
  open my $fh, '>', "$repo/tasks/001-kanban-written.md" or die $!;
  print {$fh} $KANBAN_CARD;
  close $fh;

  my $import = run_karr( $repo, 'import', '--yes' );
  is( $import->{exit}, 0, 'karr import --yes succeeds' )
    or diag( $import->{stderr} );

  my $list = run_karr( $repo, 'list', '--compact' );
  like( $list->{stdout}, qr/kanban-written/, 'the card is on the board' );

  my $pick = run_karr( $repo, 'pick', '--claim', 'bob' );
  is( $pick->{exit}, 0, 'karr pick exits 0' );
  like( $pick->{stdout}, qr/Picked task 1: kanban-written/,
    'an imported kanban-md board is not invisible to pick' )
    or diag( "stdout: $pick->{stdout}\nstderr: $pick->{stderr}" );
};

done_testing;
