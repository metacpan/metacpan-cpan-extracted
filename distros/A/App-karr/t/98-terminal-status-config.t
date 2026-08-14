# t/98-terminal-status-config.t
#
# Ticket #67: "which status means finished" was hardcoded to done + archived.
# That is right for the default board and wrong for every other one. karr's
# `statuses` are not settable from the CLI -- `karr config set statuses ...`
# answers "Key 'statuses' is read-only" -- so a custom status list only ever
# arrives through `karr import` of a kanban-md config.yml, which is precisely
# the interop path this matters on. On a board whose columns run
# backlog / doing / shipped / archived:
#
#   karr move 1 shipped ; karr pick --claim a
#     -> "Picked task 1: t1 (claimed by a)"    # hands a finished card back out
#   karr list --compact
#     -> "#1 shipped t1"                       # and does not hide it either
#
# The rule is now kanban-md's, from Config.IsTerminalStatus: the last configured
# status is terminal, or the one before it when the last is `archived`, and
# `archived` is terminal whether or not the board lists it.
#
# The class-method form keeps answering done + archived, because it has no board
# to ask -- App::karr::Task::update_timestamps calls it that way.
use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestGit qw( require_git_c );
require_git_c();
use File::Temp qw( tempdir );
use JSON::MaybeXS qw( decode_json );
use YAML::XS qw( Dump );

use App::karr::Config;
use App::karr::Git;
use App::karr::BoardStore;
use App::karr::Task;
use App::karr::Cmd::List;
use App::karr::Cmd::Pick;

sub cfg {
  my (@statuses) = @_;
  return App::karr::Config->from_merged( { statuses => \@statuses } );
}

subtest 'the class method still answers for the default board' => sub {
  is_deeply( [ App::karr::Config->terminal_statuses ], [ 'done', 'archived' ],
    'terminal_statuses called on the class is done + archived' );
  ok( App::karr::Config->is_terminal_status('done'),     'done is terminal' );
  ok( App::karr::Config->is_terminal_status('archived'), 'archived is terminal' );
  ok( !App::karr::Config->is_terminal_status('backlog'), 'backlog is not' );
  ok( !App::karr::Config->is_terminal_status('shipped'),
    'a status the default board has never heard of is not terminal' );
};

subtest 'an instance derives the terminal statuses from its own list' => sub {
  my $custom = cfg(qw( backlog doing shipped archived ));
  is_deeply( [ $custom->terminal_statuses ], [ 'shipped', 'archived' ],
    'last-but-archived is the final column' );
  ok( $custom->is_terminal_status('shipped'),  'shipped is terminal here' );
  ok( $custom->is_terminal_status('archived'), 'archived always is' );
  ok( !$custom->is_terminal_status('doing'),   'doing is not' );
  ok( !$custom->is_terminal_status('done'),
    'done is not terminal on a board without a done column' );
};

subtest 'a board that does not list archived' => sub {
  # kanban-md short-circuits on the archived name before consulting the list,
  # so it stays terminal even when the board has no such column.
  my $no_archive = cfg(qw( backlog doing finished ));
  is_deeply( [ $no_archive->terminal_statuses ], [ 'finished', 'archived' ],
    'the last status is terminal, and archived comes along' );
  ok( $no_archive->is_terminal_status('finished'), 'finished is terminal' );
  ok( $no_archive->is_terminal_status('archived'), 'archived still is' );
};

subtest 'degenerate status lists' => sub {
  is_deeply( [ cfg()->terminal_statuses ], [],
    'a board with no statuses has no terminal status (kanban-md returns false)' );
  ok( !cfg()->is_terminal_status('archived'),
    'not even archived, with an empty status list' );

  is_deeply( [ cfg('archived')->terminal_statuses ], ['archived'],
    'a single archived column is terminal and is not doubled up' );
};

subtest 'the mapping form of a status entry is understood' => sub {
  my $mapped = App::karr::Config->from_merged(
    { statuses => [ 'backlog', { name => 'doing', require_claim => 1 }, 'shipped' ] }
  );
  is_deeply( [ $mapped->terminal_statuses ], [ 'shipped', 'archived' ],
    'statuses given as mappings resolve to their names' );
};

sub board {
  my (@statuses) = @_;
  my $repo = tempdir( CLEANUP => 1 );
  system( 'git', 'init', '-q', $repo ) == 0 or BAIL_OUT('git init failed');
  system( 'git', '-C', $repo, 'config', 'user.email', 'test@example.com' ) == 0
    or BAIL_OUT('git config failed');
  system( 'git', '-C', $repo, 'config', 'user.name', 'Test User' ) == 0
    or BAIL_OUT('git config failed');
  my $git = App::karr::Git->new( dir => $repo );
  $git->write_ref(
    'refs/karr/config',
    Dump(
      { version  => 1,
        board    => { name => 'Custom' },
        statuses => [@statuses],
      }
    )
  );
  $git->write_ref( 'refs/karr/meta/next-id', "9\n" );
  return App::karr::BoardStore->new( git => $git );
}

sub add_task {
  my ( $store, $id, $title, $status ) = @_;
  $store->save_task(
    App::karr::Task->new(
      id       => $id,
      title    => $title,
      status   => $status,
      priority => 'high',
      class    => 'standard',
    )
  );
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

subtest 'the store asks the board, not the class' => sub {
  my $store = board(qw( backlog doing shipped archived ));
  ok( $store->is_terminal_status('shipped'),
    'BoardStore derives shipped from refs/karr/config' );
  ok( $store->is_terminal_status('archived'), 'archived is terminal' );
  ok( !$store->is_terminal_status('doing'),   'doing is not' );
  ok( !$store->is_terminal_status('done'),
    'done is not terminal on this board' );
};

subtest 'pick does not hand out a card in the board\'s final column' => sub {
  my $store = board(qw( backlog doing shipped archived ));
  add_task( $store, 1, 't1', 'shipped' );

  my $cmd = App::karr::Cmd::Pick->new( store => $store, claim => 'a' );
  my ( $err, $out ) = run_execute($cmd);

  is( $err, '', 'pick does not die' ) or diag("died with: $err");
  like( $out, qr/No available tasks to pick/,
    'a shipped card is finished work and is not picked' )
    or diag("got:\n$out");

  my ($task) = $store->load_tasks;
  ok( !$task->has_claimed_by, 'and nothing was claimed' );
};

subtest 'pick still takes work from the columns before it' => sub {
  my $store = board(qw( backlog doing shipped archived ));
  add_task( $store, 1, 'open', 'doing' );

  my $cmd = App::karr::Cmd::Pick->new( store => $store, claim => 'a' );
  my ( $err, $out ) = run_execute($cmd);

  is( $err, '', 'pick does not die' ) or diag("died with: $err");
  like( $out, qr/Picked task 1: open/, 'a doing card is still pickable' )
    or diag("got:\n$out");
};

subtest 'list hides the board\'s final column by default' => sub {
  my $store = board(qw( backlog doing shipped archived ));
  add_task( $store, 1, 'still-open', 'doing' );
  add_task( $store, 2, 'delivered',  'shipped' );
  add_task( $store, 3, 'retired',    'archived' );

  my ( $err, $out ) = run_execute(
    App::karr::Cmd::List->new( store => $store, compact => 1 ) );
  is( $err, '', 'list does not die' ) or diag("died with: $err");
  like( $out, qr/still-open/, 'open work is listed' );
  unlike( $out, qr/delivered/, 'the shipped card is hidden' ) or diag("got:\n$out");
  unlike( $out, qr/retired/,   'the archived card is hidden' );

  # ... and an explicit request still surfaces it, as with done on a default
  # board (t/42-list-archived.t).
  ( $err, $out ) = run_execute(
    App::karr::Cmd::List->new(
      store => $store, compact => 1, status => 'shipped' ) );
  is( $err, '', 'list --status shipped does not die' );
  like( $out, qr/delivered/, '--status shipped surfaces the finished card' )
    or diag("got:\n$out");
};

subtest 'list --archived shows the archive and only the archive' => sub {
  my $store = board(qw( backlog doing shipped archived ));
  add_task( $store, 1, 'still-open', 'doing' );
  add_task( $store, 2, 'delivered',  'shipped' );
  add_task( $store, 3, 'retired',    'archived' );

  my ( $err, $out ) = run_execute(
    App::karr::Cmd::List->new( store => $store, compact => 1, archived => 1 ) );
  is( $err, '', 'list --archived does not die' ) or diag("died with: $err");
  like( $out, qr/retired/, 'the archived card is shown' ) or diag("got:\n$out");
  unlike( $out, qr/still-open/, 'open work is not' );
  unlike( $out, qr/delivered/,  'and neither is the shipped card' );

  # kanban-md's --archived replaces the status filtering rather than narrowing
  # it (cmd/list.go), so it wins over --status.
  ( $err, $out ) = run_execute(
    App::karr::Cmd::List->new(
      store => $store, compact => 1, archived => 1, status => 'doing' ) );
  is( $err, '', 'list --archived --status doing does not die' );
  like( $out, qr/retired/, '--archived overrides --status' ) or diag("got:\n$out");
  unlike( $out, qr/still-open/, 'the --status value is not applied as well' );

  # --archived replaces the status filtering and nothing else, so the other
  # filters still narrow what comes back.
  add_task( $store, 4, 'retired-too', 'archived' );
  ( $err, $out ) = run_execute(
    App::karr::Cmd::List->new(
      store => $store, compact => 1, archived => 1, search => 'retired-too' ) );
  is( $err, '', 'list --archived -s does not die' );
  like( $out, qr/retired-too/, '--search still applies on top of --archived' )
    or diag("got:\n$out");
  unlike( $out, qr/#3/, 'the other archived card is filtered out by --search' )
    or diag("got:\n$out");

  ( $err, $out ) = run_execute(
    App::karr::Cmd::List->new( store => $store, archived => 1, json => 1 ) );
  is( $err, '', 'list --archived --json does not die' );
  my $data = eval { decode_json($out) };
  ok( $data, '--json output decodes' ) or diag("decode failed: $@\ngot:\n$out");
  is_deeply(
    [ sort map { $_->{title} } @$data ],
    [ 'retired', 'retired-too' ],
    '--json carries the archived tasks and only those'
  );
};

subtest 'the default board is untouched by any of this' => sub {
  my $store = board(
    'backlog', 'todo',
    { name => 'in-progress', require_claim => 1 },
    { name => 'review',      require_claim => 1 },
    'done', 'archived'
  );
  add_task( $store, 1, 'open',      'todo' );
  add_task( $store, 2, 'finished',  'done' );
  add_task( $store, 3, 'retired',   'archived' );

  ok( $store->is_terminal_status('done'),     'done is terminal' );
  ok( $store->is_terminal_status('archived'), 'archived is terminal' );
  ok( !$store->is_terminal_status('review'),  'review is not' );

  my ( $err, $out ) = run_execute(
    App::karr::Cmd::List->new( store => $store, compact => 1 ) );
  is( $err, '', 'list does not die' ) or diag("died with: $err");
  like( $out, qr/open/, 'open work listed' );
  unlike( $out, qr/finished/, 'done still hidden by default' );
  unlike( $out, qr/retired/,  'archived still hidden by default' );

  ( $err, $out ) = run_execute(
    App::karr::Cmd::Pick->new( store => $store, claim => 'a' ) );
  is( $err, '', 'pick does not die' ) or diag("died with: $err");
  like( $out, qr/Picked task 1: open/, 'pick takes the todo card' )
    or diag("got:\n$out");
};

done_testing;
