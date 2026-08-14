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
use YAML::XS qw( Dump );

use App::karr::Git;
use App::karr::BoardStore;
use App::karr::Task;
use App::karr::Cmd::List;

# Ticket #66: `karr list --sort` deviated from kanban-md
# (internal/board/sort.go) in three ways, crashed on an unknown field, and --
# the reason this file exists at all -- used the field name straight from argv
# as a method name (`$a->$field`), so `--sort slug` and `--sort to_markdown`
# executed arbitrary App::karr::Task methods.
#
# Probed against the pre-fix code on a board with statuses
# [backlog todo in-progress review done archived] and priorities
# [low medium high critical]:
#
#   --sort status       backlog, backlog, review, todo   (alphabetical)
#   --sort priority     critical, high, medium, low      (reversed vs config)
#   --sort due          undated first, then 01-01/02-01/03-01
#   --sort bogus        Can't locate object method "bogus" ... List.pm line 204, exit 1
#   --sort slug         exit 0, sorted by App::karr::Task::slug
#   --sort <1 task>     exit 0 -- the comparator never ran, so nothing rejected
#
# Everything below pins the fixed behaviour and fails on all of the above.
#
# Note (ticket #91): the probe's priority row matches the current output again
# in direction, but for the opposite reason -- urgency-first is now deliberate
# (the top of the list is what pick would take) and still read from the config,
# so the hardcoded-table failure mode stays pinned by the reordered-board
# subtest, and t/110-list-priority-urgency-first.t pins the pick agreement.

sub _init_repo {
  my $repo = tempdir( CLEANUP => 1 );
  system( 'git', 'init', '-q', $repo ) == 0 or die "git init failed";
  system( 'git', '-C', $repo, 'config', 'user.email', 'test@example.com' );
  system( 'git', '-C', $repo, 'config', 'user.name',  'Test User' );
  return $repo;
}

# A board whose config can be overridden per test, so "config order" is proven
# to come from the config rather than from a second hardcoded table.
sub _board {
  my (%override) = @_;
  my $repo = _init_repo();
  my $git  = App::karr::Git->new( dir => $repo );
  $git->write_ref( 'refs/karr/config',
    Dump( { version => 1, board => { name => 'Sort Board' }, %override } ) );
  return App::karr::BoardStore->new( git => $git );
}

sub mk {
  my ( $store, %a ) = @_;
  my $t = App::karr::Task->new(
    id       => $a{id},
    title    => $a{title},
    status   => $a{status}   // 'backlog',
    priority => $a{priority} // 'medium',
    class    => 'standard',
  );
  $t->due( $a{due} ) if defined $a{due};
  $store->save_task($t);
  return $t;
}

# Returns the task ids in the order `karr list` rendered them. The capture
# carries the :encoding(UTF-8) layer F<bin/karr> installs
# (App::karr::Encoding::enable_std_utf8), because reopening STDOUT drops it and
# the command prints characters.
sub list_ids {
  my ( $store, %opt ) = @_;
  my $cmd = App::karr::Cmd::List->new( store => $store, %opt );
  my $buf = '';
  {
    local *STDOUT;
    open STDOUT, '>:encoding(UTF-8)', \$buf or die $!;
    $cmd->execute( [], [] );
  }
  return [ $buf =~ /^#(\d+)/mg ];
}

# Runs list and returns the error string instead of the ids.
sub list_error {
  my ( $store, %opt ) = @_;
  my $cmd = App::karr::Cmd::List->new( store => $store, %opt );
  my $buf = '';
  my $ok  = eval {
    local *STDOUT;
    open STDOUT, '>:encoding(UTF-8)', \$buf or die $!;
    $cmd->execute( [], [] );
    1;
  };
  return $ok ? undef : $@;
}

subtest '--sort status follows the config order, not the alphabet' => sub {
  my $store = _board();
  mk( $store, id => 1, title => 'in review',   status => 'review' );
  mk( $store, id => 2, title => 'in backlog',  status => 'backlog' );
  mk( $store, id => 3, title => 'in todo',     status => 'todo' );
  mk( $store, id => 4, title => 'in progress', status => 'in-progress' );

  is_deeply list_ids( $store, sort => 'status' ), [ 2, 3, 4, 1 ],
    'backlog, todo, in-progress, review -- the default config order'
    or diag 'alphabetical would be backlog, in-progress, review, todo';
};

subtest '--sort status honours a board that reorders its statuses' => sub {
  # The three columns under test are followed by done + archived so that none
  # of them is the board's *last* status. Since ticket #67 the last column is
  # the terminal one and `list` hides it by default, so a bare
  # [review todo backlog] would have made `backlog` mean "finished" and drop
  # task 2 from the output -- correctly, but for reasons that have nothing to
  # do with the sort order this subtest is about.
  my $store = _board( statuses => [qw( review todo backlog done archived )] );
  mk( $store, id => 1, title => 'in review',  status => 'review' );
  mk( $store, id => 2, title => 'in backlog', status => 'backlog' );
  mk( $store, id => 3, title => 'in todo',    status => 'todo' );

  is_deeply list_ids( $store, sort => 'status' ), [ 1, 3, 2 ],
    'the board config decides the order, so review sorts first here';
};

subtest '--sort priority is urgency-first, agreeing with pick (ticket #91)' => sub {
  my $store = _board();
  mk( $store, id => 1, title => 'crit', priority => 'critical' );
  mk( $store, id => 2, title => 'low',  priority => 'low' );
  mk( $store, id => 3, title => 'high', priority => 'high' );
  mk( $store, id => 4, title => 'med',  priority => 'medium' );

  is_deeply list_ids( $store, sort => 'priority' ), [ 1, 3, 4, 2 ],
    'critical, high, medium, low -- most urgent first, the config order read backwards'
    or diag 'the #66 ordering produced low, medium, high, critical';

  is_deeply list_ids( $store, sort => 'priority', reverse => 1 ), [ 2, 4, 3, 1 ],
    '--reverse gives least-urgent-first';
};

subtest '--sort priority reads urgency from a reordered board, not a hardcoded table' => sub {
  # Deliberately an order no hardcoded critical..low table can produce, in
  # either direction: the last name in the config list is the most urgent.
  my $store = _board( priorities => [qw( high low critical medium )] );
  mk( $store, id => 1, title => 'crit', priority => 'critical' );
  mk( $store, id => 2, title => 'low',  priority => 'low' );
  mk( $store, id => 3, title => 'high', priority => 'high' );
  mk( $store, id => 4, title => 'med',  priority => 'medium' );

  is_deeply list_ids( $store, sort => 'priority' ), [ 4, 1, 2, 3 ],
    'medium sorts first here -- it is the last name in this board\'s priorities';
};

subtest '--sort due puts tasks without a due date last' => sub {
  my $store = _board();
  mk( $store, id => 1, title => 'march',  due => '2026-03-01' );
  mk( $store, id => 2, title => 'undated' );
  mk( $store, id => 3, title => 'jan',    due => '2026-01-01' );
  mk( $store, id => 4, title => 'feb',    due => '2026-02-01' );

  is_deeply list_ids( $store, sort => 'due' ), [ 3, 4, 1, 2 ],
    'dated tasks ascending, the undated one last (kanban-md compareDue: nil sorts last)'
    or diag 'the old ("" cmp) fallback sorted the undated task first';
};

subtest '--sort created/updated stay chronological' => sub {
  my $store = _board();
  my $t1 = App::karr::Task->new( id => 1, title => 'newer', created => '2026-05-01T00:00:00Z' );
  my $t2 = App::karr::Task->new( id => 2, title => 'older', created => '2026-01-01T00:00:00Z' );
  $t1->updated('2026-05-02T00:00:00Z');
  $t2->updated('2026-01-02T00:00:00Z');
  $store->git->save_task_ref($_) for $t1, $t2;    # keep the stamps we set

  is_deeply list_ids( $store, sort => 'created' ), [ 2, 1 ], 'oldest created first';
  is_deeply list_ids( $store, sort => 'updated' ), [ 2, 1 ], 'oldest updated first';
};

subtest 'an unknown --sort field is a usage error, not a method call' => sub {
  my $store = _board();
  mk( $store, id => 1, title => 'one' );
  mk( $store, id => 2, title => 'two' );

  my $err = list_error( $store, sort => 'bogus' );
  ok defined $err, '--sort bogus dies';
  like $err, qr/^Usage: karr list --sort /,
    'the message is a Usage: line (bin/karr maps that to exit 2, ADR 0002)';
  like $err, qr/\Qid|status|priority|created|updated|due\E/,
    'it lists the accepted fields';
  like $err, qr/\Qbogus\E/, 'it echoes the rejected value';
  unlike $err, qr/Can't locate object method/,
    'no raw Perl method-resolution error reaches the user';
  unlike $err, qr/List\.pm line \d+/,
    'no karr source location leaks into the message';
};

subtest 'a --sort field naming a real Task method is refused before it is called' => sub {
  my $store = _board();
  mk( $store, id => 1, title => 'one' );
  mk( $store, id => 2, title => 'two' );

  # A sentinel method: if the comparator ever turns argv into a method name
  # again, this fires and the assertions below fail with its message instead
  # of the usage error.
  no warnings 'once';
  local *App::karr::Task::karr_sort_sentinel = sub { die "argv reached a method call\n" };

  for my $field (qw( karr_sort_sentinel slug to_markdown to_frontmatter )) {
    my $err = list_error( $store, sort => $field );
    like $err, qr/^Usage: karr list --sort /,
      "--sort $field is rejected as a usage error";
    unlike $err, qr/argv reached a method call/,
      "--sort $field never invoked the method";
  }
};

subtest 'an unknown --sort field is rejected even when the comparator would never run' => sub {
  for my $count ( 0, 1 ) {
    my $store = _board();
    mk( $store, id => 1, title => 'solo' ) if $count;
    my $err = list_error( $store, sort => 'bogus' );
    like $err, qr/^Usage: karr list --sort /,
      "rejected on a $count-task board too (the old code only crashed with >= 2 tasks)";
  }
};

subtest 'every accepted field is still accepted' => sub {
  my $store = _board();
  mk( $store, id => 1, title => 'one', due => '2026-01-01' );
  mk( $store, id => 2, title => 'two' );

  for my $field (qw( id status priority created updated due )) {
    is list_error( $store, sort => $field ), undef, "--sort $field works";
  }
  is_deeply list_ids($store), [ 1, 2 ], 'the default sort is still by id';
};

subtest 'the CLI exits 2 on a bad --sort value (ADR 0002)' => sub {
  my $ROOT = abs_path('.');
  my $repo = _init_repo();

  my $run = sub {
    my (@argv) = @_;
    my $old = getcwd();
    chdir $repo or die "chdir $repo: $!";
    my $errfh = gensym;
    my $pid = open3( undef, my $outfh, $errfh, $^X, "-I$ROOT/lib", "$ROOT/bin/karr", @argv );
    my $out = do { local $/; <$outfh> };
    my $err = do { local $/; <$errfh> };
    waitpid( $pid, 0 );
    my $exit = $? >> 8;
    chdir $old or die "chdir $old: $!";
    return { exit => $exit, stdout => $out // '', stderr => $err // '' };
  };

  is $run->( 'init', '--name', 'Sort Board' )->{exit}, 0, 'setup: karr init exits 0';
  is $run->( 'create', '--title', 'one' )->{exit}, 0, 'setup: first task created';
  is $run->( 'create', '--title', 'two' )->{exit}, 0, 'setup: second task created';

  my $bad = $run->( 'list', '--sort', 'bogus' );
  is $bad->{exit}, 2, 'karr list --sort bogus exits 2, not 1'
    or diag "stderr: $bad->{stderr}";
  like $bad->{stderr}, qr/^Usage: karr list --sort /m, 'stderr is the usage line';
  unlike $bad->{stderr}, qr/ at \S+ line \d+/, 'stderr carries no file:line suffix';

  my $good = $run->( 'list', '--sort', 'priority' );
  is $good->{exit}, 0, 'a valid --sort still exits 0';
};

done_testing;
