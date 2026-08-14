use strict;
use warnings;
use Test::More;
use File::Temp qw( tempdir );
use Path::Tiny;

use App::karr::Task;
use App::karr::Config;

# Data-model regressions, all against App::karr::Task / App::karr::Config
# directly -- the CLI half of the same tickets is in t/91.
#
#   #58  blocked was free text; kanban-md has a bool plus block_reason
#   #68  completed survived a reopen, started was a bare date
#   #69  unknown frontmatter keys were dropped on the first write
#   #78  body "0" swallowed, slug cut mid-word, claim_timeout, config schema

# ---------------------------------------------------------------------------
# #58 -- blocked is a boolean, the reason lives in block_reason
# ---------------------------------------------------------------------------

subtest '#58 block/unblock keep the two fields consistent' => sub {
  my $task = App::karr::Task->new( id => 1, title => 'B' );
  ok( !$task->has_blocked, 'a fresh task is not blocked' );

  $task->block('waiting on API');
  ok( $task->has_blocked,             'has_blocked after block' );
  ok( $task->blocked,                 'blocked is true' );
  is( $task->block_reason, 'waiting on API', 'reason recorded separately' );

  my $fm = $task->to_frontmatter;
  is( $fm->{block_reason}, 'waiting on API', 'block_reason in frontmatter' );
  ok( $fm->{blocked}, 'blocked in frontmatter' );

  $task->unblock;
  ok( !$task->has_blocked,      'unblock clears the flag' );
  ok( !$task->has_block_reason, 'unblock clears the reason too' );
  ok( !exists $task->to_frontmatter->{blocked},
    'an unblocked task writes no blocked key at all (kanban-md omitempty)' );
};

subtest '#58 blocked serialises as a YAML boolean, not a string' => sub {
  my $task = App::karr::Task->new( id => 1, title => 'B' );
  $task->block('upstream outage');
  my $md = $task->to_markdown;

  like( $md, qr/^blocked: true$/m,
    'blocked: true -- a string here made kanban-md skip the file entirely' );
  like( $md, qr/^block_reason: upstream outage$/m, 'block_reason: <text>' );

  my $back = App::karr::Task->from_string($md);
  ok( $back->blocked, 'round trips as blocked' );
  is( $back->block_reason, 'upstream outage', 'reason round trips' );
};

subtest '#58 a legacy free-text blocked is migrated on read' => sub {
  my $doc = <<'END';
---
id: 4
title: Legacy
status: backlog
priority: medium
class: standard
created: 2026-01-01T00:00:00Z
updated: 2026-01-01T00:00:00Z
blocked: waiting on the vendor
---
END
  my $task = App::karr::Task->from_string($doc);
  ok( $task->has_blocked, 'still counts as blocked' );
  ok( $task->blocked,     'blocked is now a true boolean' );
  is( $task->block_reason, 'waiting on the vendor',
    'the old free text became the reason' );
  like( $task->to_markdown, qr/^blocked: true$/m, 'rewritten in the new shape' );
};

subtest '#58 boolean spellings are read as booleans, not as reasons' => sub {
  for my $spelling (qw( true yes on 1 )) {
    my $t = _doc_with( "blocked: $spelling" );
    ok( $t->has_blocked, "blocked: $spelling is blocked" );
    ok( !$t->has_block_reason, "blocked: $spelling invents no reason" );
  }
  for my $spelling (qw( false no off 0 )) {
    my $t = _doc_with( "blocked: $spelling" );
    ok( !$t->has_blocked, "blocked: $spelling is not blocked" );
  }
};

subtest '#58 a false blocked keeps a block_reason that is still on the card' => sub {
  # Deliberately not symmetrical with unblock: silently dropping a field found
  # in a document is exactly the #69 data loss.
  my $t = _doc_with("blocked: false\nblock_reason: it was the vendor");
  ok( !$t->has_blocked, 'not blocked' );
  is( $t->block_reason, 'it was the vendor', 'reason preserved' );
  like( $t->to_markdown, qr/^block_reason: it was the vendor$/m,
    'and written back out' );
};

subtest '#58 --json reports blocked as a JSON boolean' => sub {
  my $task = App::karr::Task->new( id => 1, title => 'B' );
  $task->block('waiting');
  my $json = $task->to_json_hash;
  ok( ref $json->{blocked}, 'blocked is a boolean object, not a bare scalar' );
  ok( $json->{blocked},     'and it is true' );
  is( $json->{block_reason}, 'waiting', 'reason is its own key' );
};

# ---------------------------------------------------------------------------
# #68 -- lifecycle timestamps
# ---------------------------------------------------------------------------

my $TS = qr/\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z\z/;

subtest '#68 started is a full timestamp, set on the first move out of backlog'
  => sub {
  my $task = App::karr::Task->new( id => 1, title => 'L', status => 'backlog' );
  $task->status('in-progress');
  $task->update_timestamps( 'backlog', 'in-progress', 'backlog' );

  ok( $task->has_started, 'started set' );
  like( $task->started, $TS,
    'a full Z timestamp -- a bare date cannot carry cycle time' );

  # Never restarted by a later move.
  my $first = $task->started;
  $task->update_timestamps( 'in-progress', 'review', 'backlog' );
  is( $task->started, $first, 'a later move does not restart the clock' );
};

subtest '#68 completed is cleared when a task is reopened' => sub {
  my $task = App::karr::Task->new( id => 1, title => 'L', status => 'todo' );
  $task->status('done');
  $task->update_timestamps( 'todo', 'done', 'backlog' );
  ok( $task->has_completed, 'completed set on the move to done' );
  like( $task->completed, $TS, 'as a full timestamp' );

  $task->status('todo');
  $task->update_timestamps( 'done', 'todo', 'backlog' );
  ok( !$task->has_completed,
    'reopening clears completed -- it used to stay behind forever' );
  ok( $task->has_started, 'started survives the reopen: work did begin' );
  ok( !exists $task->to_frontmatter->{completed},
    'and no completed key is written' );
};

subtest '#68 a direct move to a terminal status sets both stamps' => sub {
  my $task = App::karr::Task->new( id => 1, title => 'L', status => 'backlog' );
  $task->status('done');
  $task->update_timestamps( 'backlog', 'done', 'backlog' );
  ok( $task->has_started,   'started set even though in-progress was skipped' );
  ok( $task->has_completed, 'completed set' );
};

subtest '#68 archived counts as terminal' => sub {
  my $task = App::karr::Task->new( id => 1, title => 'L', status => 'todo' );
  $task->status('archived');
  $task->update_timestamps( 'todo', 'archived', 'backlog' );
  ok( $task->has_completed, 'completed set for archived, not only for done' );
};

subtest '#68 archiving a finished task keeps its real completion time' => sub {
  my $task = App::karr::Task->new( id => 1, title => 'L', status => 'done' );
  $task->completed('2026-01-01T00:00:00Z');
  $task->started('2025-12-31T00:00:00Z');
  $task->update_timestamps( 'done', 'archived', 'backlog' );
  is( $task->completed, '2026-01-01T00:00:00Z',
    'kanban-md re-stamps here; karr deliberately does not' );
};

# ---------------------------------------------------------------------------
# #69 -- unknown frontmatter survives a write
# ---------------------------------------------------------------------------

subtest '#69 unknown frontmatter keys are not deleted' => sub {
  my $doc = <<'END';
---
id: 7
title: External
status: backlog
priority: medium
class: standard
created: 2026-01-01T00:00:00Z
updated: 2026-01-01T00:00:00Z
custom_field: keep me
nested:
  a: 1
  b:
  - x
  - y
---

Body.
END
  my $task = App::karr::Task->from_string($doc);
  is( $task->extra->{custom_field}, 'keep me', 'kept on the object' );
  is_deeply( $task->extra->{nested}, { a => 1, b => [qw( x y )] },
    'including nested structures' );

  my $md = $task->to_markdown;
  like( $md, qr/^custom_field: keep me$/m, 'written back out' );

  # And again, so it survives more than one hop.
  my $twice = App::karr::Task->from_string($md);
  is( $twice->extra->{custom_field}, 'keep me', 'survives a second round trip' );
  is_deeply( $twice->extra->{nested}, { a => 1, b => [qw( x y )] },
    'nested structure intact after two round trips' );
};

subtest '#69 a modelled field always wins its own slot' => sub {
  my $task = App::karr::Task->new(
    id    => 8,
    title => 'Shadow',
    extra => { status => 'from-extra', whatever => 'kept' },
  );
  my $fm = $task->to_frontmatter;
  is( $fm->{status},   'backlog', 'the attribute wins over a stale extra' );
  is( $fm->{whatever}, 'kept',    'genuinely unknown keys still pass through' );
};

subtest '#69 a cleared field cannot be resurrected from extra' => sub {
  my $task = App::karr::Task->new(
    id    => 9,
    title => 'Cleared',
    due   => '2026-03-15',
    extra => { due => '2020-01-01' },
  );
  $task->clear_due;
  ok( !exists $task->to_frontmatter->{due}, 'no due key comes back' );
};

# ---------------------------------------------------------------------------
# #78 -- the small parity gaps
# ---------------------------------------------------------------------------

subtest '#78 a body of "0" is a body' => sub {
  my $task = App::karr::Task->new( id => 1, title => 'Zero', body => '0' );
  like( $task->to_markdown, qr/---\n\n0\n\z/, 'written into the document' );
  is( $task->to_json_hash->{body}, '0', 'present in the JSON payload' );

  my $back = App::karr::Task->from_string( $task->to_markdown );
  is( $back->body, '0', 'and survives the round trip' );
};

subtest '#78 the body reaches the same normal form on both storage paths'
  => sub {
  # App::karr::Git chomps a ref blob, files are not chomped. The two paths used
  # to disagree, so a body ending in blank lines lost one newline per ref save.
  my $dir = tempdir( CLEANUP => 1 );
  my $task = App::karr::Task->new( id => 1, title => 'Trail', body => "line\n\n" );

  my $doc = $task->to_markdown;
  ( my $chomped = $doc ) =~ s/\n\z//;   # what read_ref hands back
  is( App::karr::Task->from_string($chomped)->body,
    App::karr::Task->from_string($doc)->body,
    'a chomped document parses to the same body as an unchomped one' );

  $task->save($dir);
  my $from_file = App::karr::Task->from_file( $task->file_path );
  is( $from_file->body, 'line', 'file path settles on the same normal form' );

  # Stable: saving what we read back changes nothing.
  $from_file->save($dir);
  is( App::karr::Task->from_file( $from_file->file_path )->body,
    'line', 'and stays there' );
};

subtest '#78 slug truncation stops on a word boundary' => sub {
  my $long = App::karr::Task->new( id => 1,
    title => 'Implement the new authentication subsystem with token rotation' );
  is( $long->slug, 'implement-the-new-authentication-subsystem-with',
    'backs up to the last dash instead of cutting mid-word' );
  is( $long->filename, '001-implement-the-new-authentication-subsystem-with.md',
    'so a shared tasks/ directory gets one filename, not two' );

  my $dashes = App::karr::Task->new( id => 2,
    title => 'aaaa bbbb cccc dddd eeee ffff gggg hhhh iiii jjjj kkkk llll' );
  is( $dashes->slug, 'aaaa-bbbb-cccc-dddd-eeee-ffff-gggg-hhhh-iiii-jjjj',
    'no trailing dash left behind' );

  is( App::karr::Task->new( id => 3, title => 'Fix Login Bug' )->slug,
    'fix-login-bug', 'short titles are untouched' );
};

subtest '#78 claim_timeout understands the whole Go duration grammar' => sub {
  my %expect = (
    '1h'       => 3600,
    '30m'      => 1800,
    '1h30m'    => 5400,
    '90s'      => 90,
    '2h45m30s' => 9930,
    '0.5h'     => 1800,
    '1ms'      => 0.001,
    '0'        => 0,
  );
  is( App::karr::Config->parse_duration($_), $expect{$_}, "parse_duration $_" )
    for sort keys %expect;

  is( App::karr::Config->parse_duration($_), undef, "parse_duration rejects $_" )
    for ( '7d', '1 h', 'h', '1', 'nonsense', '' );
};

subtest '#78 config validation catches a broken schema' => sub {
  my $ok = App::karr::Config->default_config( name => 'T' );
  ok( eval { App::karr::Config->validate($ok) }, 'the default config is valid' )
    or diag $@;

  my %broken = (
    'defaults.status not a status'     => { defaults => { status => 'nope' } },
    'defaults.priority not a priority' => { defaults => { priority => 'nope' } },
    'defaults.class not a class'       => { defaults => { class => 'nope' } },
    'claim_timeout not a duration'     => { claim_timeout => '7d' },
    'statuses not a list'              => { statuses => 42 },
    'only one status'                  => { statuses => ['only'] },
    'duplicate statuses'               => { statuses => [ 'a', 'b', 'a' ] },
    'duplicate priorities'             => { priorities => [ 'low', 'low' ] },
    'empty board name'                 => { board => { name => '' } },
  );
  for my $label ( sort keys %broken ) {
    my $data = App::karr::Config->effective_config( $broken{$label},
      name => 'T' );
    my $lived = eval { App::karr::Config->validate($data); 1 };
    ok( !$lived, "rejected: $label" );
    like( $@, qr/\ABoard config is invalid: /, "  ...with a clear message" )
      unless $lived;
  }
};

subtest '#78 a broken config is still readable so it can be repaired' => sub {
  # The accessors must not die inside a dereference: `karr config show` is how
  # you find out the config is wrong.
  my $c = App::karr::Config->from_merged(
    { version => 1, board => { name => 'B' }, statuses => 42, classes => 'x' } );
  is_deeply( [ $c->statuses ], [], 'statuses degrades to empty' );
  is_deeply( [ $c->classes ],  [], 'classes degrades to empty' );
  is_deeply( [ $c->priorities ], [qw( low medium high critical )],
    'priorities falls back to the built-in list' );
  is( $c->status_requires_claim('todo'), 0, 'status_requires_claim survives' );
};

subtest '#54 the validators are the ones the write paths call' => sub {
  my $c = App::karr::Config->from_merged(
    App::karr::Config->default_config( name => 'T' ) );

  is( $c->validate_status('todo'),      'todo',     'valid status passes through' );
  is( $c->validate_priority('high'),    'high',     'valid priority' );
  is( $c->validate_class('expedite'),   'expedite', 'valid class' );
  is( App::karr::Config->validate_due('2026-03-15'), '2026-03-15', 'valid due' );

  for my $case (
    [ 'status',   sub { $c->validate_status('bogus') },   qr/\AUsage error: invalid status "bogus" \(valid: / ],
    [ 'priority', sub { $c->validate_priority('bogus') }, qr/\AUsage error: invalid priority "bogus" \(valid: / ],
    [ 'class',    sub { $c->validate_class('bogus') },    qr/\AUsage error: invalid class "bogus" \(valid: / ],
    [ 'due',      sub { App::karr::Config->validate_due('not-a-date') },
      qr/\AUsage error: invalid due date "not-a-date" \(expected YYYY-MM-DD\)/ ],
    [ 'impossible due', sub { App::karr::Config->validate_due('2026-02-30') },
      qr/\AUsage error: invalid due date "2026-02-30"/ ],
    ) {
    my ( $label, $code, $re ) = @$case;
    ok( !eval { $code->(); 1 }, "$label is rejected" );
    like( $@, $re, "  ...with the Usage error: marker bin/karr maps to 2" );
  }
};

sub _doc_with {
  my ($extra_lines) = @_;
  return App::karr::Task->from_string( <<"END" );
---
id: 5
title: Doc
status: backlog
priority: medium
class: standard
created: 2026-01-01T00:00:00Z
updated: 2026-01-01T00:00:00Z
$extra_lines
---
END
}

done_testing;
