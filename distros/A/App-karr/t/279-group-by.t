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
use JSON::MaybeXS qw( decode_json );

use App::karr::Git;
use App::karr::BoardStore;
use App::karr::Task;
use App::karr::Cmd::List;
use App::karr::Cmd::Board;

# Ticket #279: `karr list --group-by` and `karr board --group-by`, the
# kanban-md feature karr did not have. The group keys and their order follow
# kanban-md's GroupBy (internal/board/group.go): assignee falls back to
# "(unassigned)", a task without tags to "(untagged)" -- and one with several
# tags appears in each of them -- class to the board's default, and priority
# and status to their own values; status, priority and class groups follow the
# board config's own order, assignee and tag are alphabetical.
#
# The rendering is karr's own, not kanban-md's GroupedTable (which prints
# per-group status counts): a heading per group with the same rows below, so
# the grouped view and the flat view cannot drift. Grouping is a rendering
# concern -- --json and --compact win over it, exactly as --tags changes only
# the table.

sub _init_repo {
  my $repo = tempdir( CLEANUP => 1 );
  system( 'git', 'init', '-q', $repo ) == 0 or die "git init failed";
  system( 'git', '-C', $repo, 'config', 'user.email', 'test@example.com' );
  system( 'git', '-C', $repo, 'config', 'user.name',  'Test User' );
  return $repo;
}

# A board whose config can be overridden per test, so "the board's order" is
# proven to come from the board rather than from a hardcoded table.
sub _board {
  my (%override) = @_;
  my $repo = _init_repo();
  my $git  = App::karr::Git->new( dir => $repo );
  $git->write_ref( 'refs/karr/config',
    Dump( { version => 1, board => { name => 'Group Board' }, %override } ) );
  return App::karr::BoardStore->new( git => $git );
}

sub mk {
  my ( $store, %a ) = @_;
  my $t = App::karr::Task->new(
    id       => $a{id},
    title    => $a{title},
    status   => $a{status}   // 'todo',
    priority => $a{priority} // 'medium',
    class    => $a{class}    // 'standard',
  );
  $t->assignee( $a{assignee} ) if $a{assignee};
  $t->tags( $a{tags} )         if $a{tags};
  $store->save_task($t);
  return $t;
}

sub list_out {
  my ( $store, %opt ) = @_;
  my $cmd = App::karr::Cmd::List->new( store => $store, %opt );
  my $buf = '';
  {
    local *STDOUT;
    open STDOUT, '>:encoding(UTF-8)', \$buf or die $!;
    $cmd->execute( [], [] );
  }
  return $buf;
}

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

sub board_out {
  my ( $store, %opt ) = @_;
  local $ENV{NO_COLOR} = 1;
  my $cmd = App::karr::Cmd::Board->new( store => $store, %opt );
  my $buf = '';
  {
    local *STDOUT;
    open STDOUT, '>', \$buf or die $!;
    $cmd->execute( [], [] );
  }
  return $buf;
}

sub board_error {
  my ( $store, %opt ) = @_;
  local $ENV{NO_COLOR} = 1;
  my $cmd = App::karr::Cmd::Board->new( store => $store, %opt );
  my $buf = '';
  my $ok  = eval {
    local *STDOUT;
    open STDOUT, '>', \$buf or die $!;
    $cmd->execute( [], [] );
    1;
  };
  return $ok ? undef : $@;
}

# The group headings in display order and the task ids under each, read off the
# rendered output -- so the tests pin the rendering, not a data structure.
sub list_groups {
  my ($out) = @_;
  my (@order, %groups, $current);
  for my $line ( split /\n/, $out ) {
    if ( $line =~ /^## (.+)$/ ) {
      $current = $1;
      push @order, $current;
      $groups{$current} //= [];
    } elsif ( $line =~ /^#(\d+)/ ) {
      push @{ $groups{$current} }, $1;
    }
  }
  return ( \@order, \%groups );
}

sub board_groups {
  my ($out) = @_;
  my (@order, %groups, $current);
  for my $line ( split /\n/, $out ) {
    if ( $line =~ /^## (.+)$/ ) {
      $current = $1;
      push @order, $current;
      $groups{$current} //= [];
    } elsif ( $line =~ /^- (\d+) \|/ ) {
      push @{ $groups{$current} }, $1;
    }
  }
  return ( \@order, \%groups );
}

#### list --group-by

subtest 'list --group-by status groups in board config order' => sub {
  my $store = _board();
  mk( $store, id => 1, title => 'in review',  status => 'review' );
  mk( $store, id => 2, title => 'in backlog',  status => 'backlog' );
  mk( $store, id => 3, title => 'in todo',     status => 'todo' );
  mk( $store, id => 4, title => 'in progress', status => 'in-progress' );

  my ( $order, $groups ) = list_groups( list_out( $store, group_by => 'status' ) );
  is_deeply $order, [qw( backlog todo in-progress review )],
    'backlog, todo, in-progress, review -- the default config order, not the alphabet';
  is_deeply $groups->{backlog}, [2], 'each group holds its own cards';
  is_deeply $groups->{review},  [1], '...and the rows are the same ones the flat view prints';
};

subtest 'list --group-by status honours a board that reorders its statuses' => sub {
  my $store = _board( statuses => [qw( review todo backlog done archived )] );
  mk( $store, id => 1, title => 'in review',  status => 'review' );
  mk( $store, id => 2, title => 'in backlog',  status => 'backlog' );
  mk( $store, id => 3, title => 'in todo',     status => 'todo' );

  my ( $order ) = list_groups( list_out( $store, group_by => 'status' ) );
  is_deeply $order, [qw( review todo backlog )],
    'the board config decides the order, so review groups first here';
};

subtest 'list --group-by assignee: (unassigned) group, alphabetical order' => sub {
  my $store = _board();
  mk( $store, id => 1, title => 'bob\'s',   assignee => 'bob' );
  mk( $store, id => 2, title => 'alice\'s', assignee => 'alice' );
  mk( $store, id => 3, title => 'nobody\'s' );

  my ( $order, $groups ) = list_groups( list_out( $store, group_by => 'assignee' ) );
  is_deeply $order, [ '(unassigned)', 'alice', 'bob' ],
    'the unassigned group first, then the names alphabetically';
  is_deeply $groups->{'(unassigned)'}, [3], 'the card without an assignee lands in (unassigned)';
  is_deeply $groups->{alice}, [2], 'alice\'s card under alice';
  is_deeply $groups->{bob},   [1], 'bob\'s card under bob';
};

subtest 'list --group-by tag: one group per tag, multi-tag cards in each' => sub {
  my $store = _board();
  mk( $store, id => 1, title => 'bug only',  tags => [qw( bug )] );
  mk( $store, id => 2, title => 'both',      tags => [qw( bug claims )] );
  mk( $store, id => 3, title => 'no tags' );

  my ( $order, $groups ) = list_groups( list_out( $store, group_by => 'tag' ) );
  is_deeply $order, [ '(untagged)', 'bug', 'claims' ],
    'the untagged group first, then the tags alphabetically';
  is_deeply $groups->{'(untagged)'}, [3], 'the card without tags lands in (untagged)';
  is_deeply $groups->{bug},    [ 1, 2 ], 'the multi-tag card appears in the bug group';
  is_deeply $groups->{claims}, [2],      '...and in the claims group';
};

subtest 'list --group-by priority follows the config order, low first' => sub {
  my $store = _board();
  mk( $store, id => 1, title => 'high',     priority => 'high' );
  mk( $store, id => 2, title => 'low',      priority => 'low' );
  mk( $store, id => 3, title => 'critical', priority => 'critical' );

  my ( $order, $groups ) = list_groups( list_out( $store, group_by => 'priority' ) );
  is_deeply $order, [qw( low high critical )],
    'low, high, critical -- the config list forward, where --sort priority reads it backwards';
  is_deeply $groups->{low},      [2], 'each priority holds its own cards';
  is_deeply $groups->{critical}, [3], '...critical last';
};

subtest 'list --group-by class follows the config order' => sub {
  my $store = _board();
  mk( $store, id => 1, title => 'expedite',   class => 'expedite' );
  mk( $store, id => 2, title => 'standard',   class => 'standard' );
  mk( $store, id => 3, title => 'intangible', class => 'intangible' );

  my ( $order ) = list_groups( list_out( $store, group_by => 'class' ) );
  is_deeply $order, [qw( expedite standard intangible )],
    'expedite, standard, intangible -- the default classes in board order';
};

subtest 'rows within a group keep the --sort order' => sub {
  my $store = _board();
  mk( $store, id => 1, title => 'banana', priority => 'high' );
  mk( $store, id => 2, title => 'Apple',  priority => 'high' );
  mk( $store, id => 3, title => 'cherry', priority => 'low' );

  my ( $order, $groups ) = list_groups(
    list_out( $store, group_by => 'priority', sort => 'title' ) );
  is_deeply $order, [qw( low high )], 'the groups keep the config order';
  is_deeply $groups->{high}, [ 2, 1 ],
    'within the group the rows keep the sort: Apple before banana';
  is_deeply $groups->{low}, [3], '...and the low group holds its one card';
};

subtest 'the grouped view keeps the footer and its hidden-done hint' => sub {
  my $store = _board();
  mk( $store, id => 1, title => 'open' );
  mk( $store, id => 2, title => 'done', status => 'done' );

  my $out = list_out( $store, group_by => 'status' );
  like $out, qr/^1 task\(s\) \(1 done hidden; --status done to include\)$/m,
    'the footer is the flat view\'s footer, hidden-done hint included';
};

subtest 'an unknown --group-by field is a usage error' => sub {
  my $store = _board();
  mk( $store, id => 1, title => 'one' );

  my $err = list_error( $store, group_by => 'bogus' );
  ok defined $err, '--group-by bogus dies';
  like $err, qr/^Usage: karr list --group-by /,
    'the message is a Usage: line (bin/karr maps that to exit 2, ADR 0002)';
  like $err, qr/\Qassignee|tag|class|priority|status\E/,
    'it lists the accepted fields';
  like $err, qr/\Qbogus\E/, 'it echoes the rejected value';
  unlike $err, qr/List\.pm line \d+/, 'no karr source location leaks into the message';
};

subtest '--json and --compact win over --group-by' => sub {
  my $store = _board();
  mk( $store, id => 1, title => 'one', assignee => 'bob' );
  mk( $store, id => 2, title => 'two' );

  my $json = list_out( $store, group_by => 'assignee', json => 1 );
  unlike $json, qr/^## /m, 'no group headings in the json payload';
  my $data = decode_json($json);
  is scalar @$data, 2, 'the payload is the flat array, grouping is a rendering concern';

  my $compact = list_out( $store, group_by => 'assignee', compact => 1 );
  unlike $compact, qr/^## /m, 'no group headings in compact output';
  like $compact, qr/^#1\s+todo one$/m, 'the compact lines are the flat view\'s';
};

#### board --group-by

subtest 'board --group-by assignee: one section per assignee, same card rows' => sub {
  my $store = _board();
  mk( $store, id => 1, title => 'bob\'s',   assignee => 'bob',   status => 'in-progress' );
  mk( $store, id => 2, title => 'alice\'s', assignee => 'alice', status => 'todo' );
  mk( $store, id => 3, title => 'nobody\'s', status => 'backlog' );

  my ( $order, $groups ) = board_groups( board_out( $store, group_by => 'assignee' ) );
  is_deeply $order, [ '(unassigned)', 'alice', 'bob' ],
    'the same key rules and order as list --group-by assignee';
  is_deeply $groups->{'(unassigned)'}, [3], 'the unassigned card under (unassigned)';
  is_deeply $groups->{bob}, [1], 'bob\'s card under bob';

  my $out = board_out( $store, group_by => 'assignee' );
  like $out, qr/^- 1 \| bob's$/m, 'the card rows are the board\'s own rows';
  like $out, qr/^3 tasks/m,       'the footer is still there';
};

subtest 'board --group-by status groups in config order, done still hidden' => sub {
  my $store = _board();
  mk( $store, id => 1, title => 'in backlog', status => 'backlog' );
  mk( $store, id => 2, title => 'in todo',    status => 'todo' );
  mk( $store, id => 3, title => 'done',       status => 'done' );

  my ( $order, $groups ) = board_groups( board_out( $store, group_by => 'status' ) );
  is_deeply $order, [qw( backlog todo )], 'backlog, todo -- done hidden by default';
  is_deeply $groups->{backlog}, [1], 'each group holds its own cards';
  is_deeply $groups->{todo},    [2], '...and the rows are the board\'s own';

  my $out = board_out( $store, group_by => 'status' );
  like $out, qr/^3 tasks \(1 done hidden\)/m, 'the footer and its hint are unchanged';
};

subtest 'board --group-by status --done reveals the finished group' => sub {
  my $store = _board();
  mk( $store, id => 1, title => 'in backlog', status => 'backlog' );
  mk( $store, id => 2, title => 'done',       status => 'done' );

  my ( $order, $groups ) = board_groups( board_out( $store, group_by => 'status', done => 1 ) );
  is_deeply $order, [qw( backlog done )], '--done adds the finished group';
  is_deeply $groups->{done}, [2], '...with its cards';

  my $out = board_out( $store, group_by => 'status', done => 1 );
  unlike $out, qr/hidden/, 'and the hidden-count hint is gone, as in the flat view';
};

subtest 'board --group-by tag: multi-tag cards in each group, --tags still works' => sub {
  my $store = _board();
  mk( $store, id => 1, title => 'both', tags => [qw( bug claims )] );
  mk( $store, id => 2, title => 'no tags' );

  my ( $order, $groups ) = board_groups( board_out( $store, group_by => 'tag' ) );
  is_deeply $order, [ '(untagged)', 'bug', 'claims' ], 'the same key rules as list';
  is_deeply $groups->{bug}, [1], 'the multi-tag card appears in the bug group';
  is_deeply $groups->{claims}, [1], '...and in the claims group';

  my $out = board_out( $store, group_by => 'tag', tags => 1 );
  like $out, qr/^\s+#bug #claims$/m, '--tags still adds its line under the card';
};

subtest 'an unknown --group-by field is a usage error for board too' => sub {
  my $store = _board();
  mk( $store, id => 1, title => 'one' );

  my $err = board_error( $store, group_by => 'bogus' );
  ok defined $err, '--group-by bogus dies';
  like $err, qr/^Usage: karr board --group-by /,
    'the message is a Usage: line (bin/karr maps that to exit 2, ADR 0002)';
  like $err, qr/\Qassignee|tag|class|priority|status\E/, 'it lists the accepted fields';
  unlike $err, qr/Board\.pm line \d+/, 'no karr source location leaks into the message';
};

subtest 'board --json and --compact win over --group-by' => sub {
  my $store = _board();
  mk( $store, id => 1, title => 'one', assignee => 'bob' );
  mk( $store, id => 2, title => 'two' );

  my $json = board_out( $store, group_by => 'assignee', json => 1 );
  unlike $json, qr/^## /m, 'no group headings in the json payload';
  my $data = decode_json($json);
  ok $data->{columns}, 'the payload is the flat board shape, grouping is a rendering concern';

  my $compact = board_out( $store, group_by => 'assignee', compact => 1 );
  unlike $compact, qr/^## /m, 'no group headings in compact output';
  like $compact, qr/^backlog\(0\): -$/m, 'the compact lines are the flat view\'s';
};

#### the CLI, where the exit codes live

subtest 'the CLI exits 2 on a bad --group-by value (ADR 0002)' => sub {
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

  is $run->( 'init', '--name', 'Group Board' )->{exit}, 0, 'setup: karr init exits 0';
  is $run->( 'create', '--title', 'one' )->{exit}, 0, 'setup: first task created';

  for my $cmd ( 'list', 'board' ) {
    my $bad = $run->( $cmd, '--group-by', 'bogus' );
    is $bad->{exit}, 2, "karr $cmd --group-by bogus exits 2, not 1"
      or diag "stderr: $bad->{stderr}";
    like $bad->{stderr}, qr/^Usage: karr $cmd --group-by /m, 'stderr is the usage line';
    unlike $bad->{stderr}, qr/ at \S+ line \d+/, 'stderr carries no file:line suffix';
  }

  my $good = $run->( 'list', '--group-by', 'status' );
  is $good->{exit}, 0, 'a valid --group-by still exits 0';
  like $good->{stdout}, qr/^## backlog$/m, '...and groups the output';
};

done_testing;
