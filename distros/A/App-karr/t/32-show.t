use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestGit qw( require_git_c );
require_git_c();
use TestKarr qw( run_karr );
use File::Temp qw( tempdir );
use YAML::XS qw( Dump );
use JSON::MaybeXS qw( decode_json );

use App::karr::Git;
use App::karr::BoardStore;
use App::karr::Task;
use App::karr::Cmd::Show;

sub _init_repo {
  my $repo = tempdir( CLEANUP => 1 );
  system( 'git', 'init', '-q', $repo );
  system( 'git', '-C', $repo, 'config', 'user.email', 'test@example.com' );
  system( 'git', '-C', $repo, 'config', 'user.name', 'Test User' );
  return $repo;
}

my $repo  = _init_repo();
my $git   = App::karr::Git->new( dir => $repo );
$git->write_ref( 'refs/karr/config', Dump( { version => 1, board => { name => 'T' } } ) );
$git->write_ref( 'refs/karr/meta/next-id', "9\n" );
my $store = App::karr::BoardStore->new( git => $git );

# Three tasks, deterministic 'updated' so recency ordering is stable.
my %updated = (
  1 => '2026-01-01T00:00:00Z',
  2 => '2026-03-01T00:00:00Z',
  3 => '2026-02-01T00:00:00Z',
);
for my $id ( 1, 2, 3 ) {
  my $t = App::karr::Task->new(
    id       => $id,
    title    => "Task $id",
    status   => 'backlog',
    priority => 'medium',
    class    => 'standard',
  );
  $t->updated( $updated{$id} );
  $t->claimed_by('fox-owl') if $id == 3;
  $store->save_task($t);
}

my $ids = sub { map { $_->id } @_ };

subtest 'explicit id wins over selectors' => sub {
  my $cmd = App::karr::Cmd::Show->new( store => $store, me => 1, last => 5 );
  my @t = $cmd->_select_tasks(1);
  is_deeply [ $ids->(@t) ], [1], 'returns exactly the requested task';
};

subtest 'no id, default last=1 -> most recently updated' => sub {
  my $cmd = App::karr::Cmd::Show->new( store => $store );
  my @t = $cmd->_select_tasks(undef);
  is_deeply [ $ids->(@t) ], [2], 'task 2 is newest by updated';
};

subtest '--last 2 -> two newest, descending' => sub {
  my $cmd = App::karr::Cmd::Show->new( store => $store, last => 2 );
  my @t = $cmd->_select_tasks(undef);
  is_deeply [ $ids->(@t) ], [ 2, 3 ], 'two newest in updated-desc order';
};

subtest '--agent filters by claimed_by' => sub {
  my $cmd = App::karr::Cmd::Show->new( store => $store, agent => 'fox-owl', last => 5 );
  my @t = $cmd->_select_tasks(undef);
  is_deeply [ $ids->(@t) ], [3], 'only the task claimed by fox-owl';
};

subtest '--me resolves via the activity log identity' => sub {
  # Two entries for this identity; task 1 is the most recent action.
  my $ref = 'refs/karr/log/user/test_example.com';
  my $l1  = '{"ts":"2026-01-01T00:00:00Z","agent":"fox-owl","action":"pick","task_id":3}';
  my $l2  = '{"ts":"2026-04-01T00:00:00Z","agent":"fox-owl","action":"move","task_id":1}';
  $git->write_ref( $ref, "$l1\n$l2" );

  my $cmd = App::karr::Cmd::Show->new( store => $store, me => 1 );
  my @t = $cmd->_select_tasks(undef);
  is_deeply [ $ids->(@t) ], [1], '--me default last=1 -> last task acted on';

  my $cmd2 = App::karr::Cmd::Show->new( store => $store, me => 1, last => 5 );
  my @t2 = $cmd2->_select_tasks(undef);
  is_deeply [ $ids->(@t2) ], [ 1, 3 ], '--me dedupes and orders newest first';
};

# ---------------------------------------------------------------------------
# the ID[,ID,...] batch form (ticket #274)
# ---------------------------------------------------------------------------

# A throwaway board with three tasks, driven through the CLI so exit codes and
# STDERR are the ones a caller of `karr` actually sees. Never the developer's
# real board.
sub _cli_board {
  my $repo = tempdir( CLEANUP => 1 );
  system( 'git', 'init', '-q', $repo ) == 0                                  or die 'git init';
  system( 'git', '-C', $repo, 'config', 'user.email', 'test@example.com' ) == 0 or die 'git config';
  system( 'git', '-C', $repo, 'config', 'user.name',  'Test User' ) == 0     or die 'git config';
  is( run_karr( $repo, 'init', '--name', 'Show Batch' )->{exit}, 0,
      'setup: karr init exits 0' );
  for my $i ( 1 .. 3 ) {
    is( run_karr( $repo, 'create', "Task $i" )->{exit}, 0,
        "setup: task $i created" );
  }
  return $repo;
}

subtest 'show ID,ID prints the cards one after another, in the given order' => sub {
  my $repo = _cli_board();

  my $rv = run_karr( $repo, 'show', '2,1' );
  is( $rv->{exit}, 0, 'exit 0' ) or diag $rv->{stderr};
  my $i2 = index( $rv->{stdout}, 'Task #2:' );
  my $i1 = index( $rv->{stdout}, 'Task #1:' );
  ok( $i2 >= 0 && $i1 >= 0, 'both cards are rendered' );
  ok( $i2 < $i1, 'cards come in the order the ids were given, not sorted' );
};

subtest 'show ID,ID --json is an array, as list --json is' => sub {
  my $repo = _cli_board();

  my $rv = run_karr( $repo, 'show', '1,2', '--json' );
  is( $rv->{exit}, 0, 'exit 0' ) or diag $rv->{stderr};
  my $data = eval { decode_json( $rv->{stdout} ) };
  is( ref $data, 'ARRAY', 'STDOUT is a JSON array' ) or diag $rv->{stdout};
  return unless ref $data eq 'ARRAY';
  is( scalar @$data, 2, 'one entry per card' );
  is( $data->[0]{id}, 1, 'first card is the first id' );
  is( $data->[1]{id}, 2, 'second card is the second id' );
};

subtest 'show ID,ID --compact is one line per card' => sub {
  my $repo = _cli_board();

  my $rv = run_karr( $repo, 'show', '1,2', '--compact' );
  is( $rv->{exit}, 0, 'exit 0' ) or diag $rv->{stderr};
  my @lines = grep { length } split /\n/, $rv->{stdout};
  is( scalar @lines, 2, 'one compact line per card' );
  like( $lines[0], qr/^#1\b/, 'first line is card 1' );
  like( $lines[1], qr/^#2\b/, 'second line is card 2' );
};

subtest 'a missing id in the batch is reported, the others are still shown, exit 1' => sub {
  my $repo = _cli_board();

  my $rv = run_karr( $repo, 'show', '1,999,2' );

  is( $rv->{exit}, 1, 'partial batch failure exits 1 (ADR 0002)' );
  like( $rv->{stderr}, qr/Task 999 not found/, 'STDERR names the missing id' );
  like( $rv->{stderr}, qr/1 of 3 ids failed/, 'and the batch summary' );
  like( $rv->{stdout}, qr/^Task #1:/m, 'the id before the bad one is shown' );
  like( $rv->{stdout}, qr/^Task #2:/m, 'the id AFTER the bad one is shown too' );
};

subtest 'a missing id in the batch is reported under --json too' => sub {
  my $repo = _cli_board();

  my $rv = run_karr( $repo, 'show', '1,999,2', '--json' );
  is( $rv->{exit}, 1, 'exit 1' );
  like( $rv->{stderr}, qr/Task 999 not found/,
      'STDERR reports the missing id even under --json' );

  my $data = eval { decode_json( $rv->{stdout} ) };
  is( ref $data, 'ARRAY', 'STDOUT is still a clean JSON array of the found cards' )
      or diag $rv->{stdout};
  return unless ref $data eq 'ARRAY';
  is( scalar @$data, 2, 'one entry per found card, none for the missing id' );
  is( $data->[0]{id}, 1, 'first found card' );
  is( $data->[1]{id}, 2, 'second found card' );
};

subtest 'a batch where every id is missing exits 1 without the empty-selection line' => sub {
  my $repo = _cli_board();

  my $rv = run_karr( $repo, 'show', '999,998' );
  is( $rv->{exit}, 1, 'exit 1' );
  like( $rv->{stderr}, qr/2 of 2 ids failed/, 'the batch summary' );
  unlike( $rv->{stdout}, qr/No tasks found/,
      'no misleading "No tasks found." -- the per-id reports already said it' );
};

subtest 'the batch form is an array even when only one card survives' => sub {
  my $repo = _cli_board();

  my $rv = run_karr( $repo, 'show', '1,999', '--json' );
  is( $rv->{exit}, 1, 'exit 1' );
  my $data = eval { decode_json( $rv->{stdout} ) };
  is( ref $data, 'ARRAY', 'a batch is an array, not a bare object' )
      or diag $rv->{stdout};
  return unless ref $data eq 'ARRAY';
  is( scalar @$data, 1, 'the one surviving card' );
  is( $data->[0]{id}, 1, 'and it is the found one' );
};

subtest 'a single id keeps the bare-object --json and the id-wins selectors' => sub {
  my $repo = _cli_board();

  my $json = run_karr( $repo, 'show', '1', '--json' );
  is( $json->{exit}, 0, 'show 1 --json exits 0' );
  my $data = eval { decode_json( $json->{stdout} ) };
  is( ref $data, 'HASH', 'a single explicit lookup stays a bare object' )
      or diag $json->{stdout};

  my $me = run_karr( $repo, 'show', '1', '--me' );
  is( $me->{exit}, 0, 'show 1 --me exits 0' );
  like( $me->{stdout}, qr/^Task #1:/m, 'the explicit id wins over --me' );
};

done_testing;
