use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestGit qw( require_git_c );
require_git_c();
use File::Temp qw( tempdir );
use YAML::XS qw( Dump );
use JSON::MaybeXS qw( decode_json );

use App::karr::Git;
use App::karr::BoardStore;
use App::karr::Task;
use App::karr::Cmd::List;

# Ticket #7: `karr list --status archived` returns nothing (--json => []) even
# though archived tasks exist and `karr show ID` displays them fine. Root
# cause under investigation is App::karr::Cmd::List::_filter (lib/App/karr/Cmd/List.pm):
# it unconditionally strips terminal statuses (done + archived, per
# App::karr::Config->is_terminal_status) *before* applying an explicit
# --status filter, so any explicit --status request for a terminal status
# filters against an already-emptied list. This file pins:
#   (a) default `list` (no --status) hides both done and archived - GREEN today
#   (b) `--status archived` surfaces archived tasks - RED today (bug)
#   (c) `--status done,archived` surfaces both terminal groups - RED today
#   (d) --json is consistent with plain output for both of the above
#   (e) --status archived combined with --tag/--sort still works
#
# Uses an isolated temp git repo/refs, never the real board (see
# t/37-board-render.t for the same in-process Cmd-driving pattern).

sub _init_repo {
  my $repo = tempdir( CLEANUP => 1 );
  system( 'git', 'init', '-q', $repo );
  system( 'git', '-C', $repo, 'config', 'user.email', 'test@example.com' );
  system( 'git', '-C', $repo, 'config', 'user.name', 'Test User' );
  return $repo;
}

my $repo  = _init_repo();
my $git   = App::karr::Git->new( dir => $repo );
$git->write_ref( 'refs/karr/config', Dump( { version => 1, board => { name => 'Archive Board' } } ) );
my $store = App::karr::BoardStore->new( git => $git );

sub mk {
  my (%a) = @_;
  my $t = App::karr::Task->new(
    id       => $a{id},
    title    => $a{title},
    status   => $a{status},
    priority => $a{priority} // 'medium',
    class    => 'standard',
  );
  $t->tags( $a{tags} ) if $a{tags};
  $store->save_task($t);
}

mk( id => 1, title => 'Open todo',        status => 'todo' );
mk( id => 2, title => 'In flight',        status => 'in-progress' );
mk( id => 3, title => 'Shipped feature',  status => 'done' );
mk( id => 4, title => 'Retired ticket',   status => 'archived', tags => ['legacy'] );
mk( id => 5, title => 'Old cleanup task', status => 'archived', tags => ['legacy', 'chore'] );

sub run_list {
  my (%opt) = @_;
  my $cmd = App::karr::Cmd::List->new( store => $store, %opt );
  my $buf = '';
  {
    local *STDOUT;
    open STDOUT, '>', \$buf or die $!;
    $cmd->execute( [], [] );
  }
  return $buf;
}

sub titles_of {
  my ($data) = @_;
  return { map { $_->{title} => 1 } @$data };
}

subtest 'default list hides archived and done (current, intended behaviour)' => sub {
  my $out = run_list();
  like $out, qr/Open todo/,          'todo task listed';
  like $out, qr/In flight/,          'in-progress task listed';
  unlike $out, qr/Shipped feature/,  'done task hidden by default (pinned intended behaviour)';
  unlike $out, qr/Retired ticket/,   'archived task hidden by default';
  unlike $out, qr/Old cleanup task/, 'second archived task hidden by default';
  like $out, qr/^2 task\(s\)$/m,     'footer counts only the 2 non-terminal tasks';
};

subtest '--status archived surfaces archived tasks (BUG: currently empty)' => sub {
  my $out = run_list( status => 'archived' );
  like $out, qr/Retired ticket/,     'explicit --status archived includes first archived task'
    or diag "got:\n$out";
  like $out, qr/Old cleanup task/,   'explicit --status archived includes second archived task'
    or diag "got:\n$out";
  unlike $out, qr/Open todo/,        '--status archived excludes non-archived tasks';
  unlike $out, qr/Shipped feature/,  '--status archived excludes done tasks';
  like $out, qr/^2 task\(s\)$/m,     'footer counts the 2 archived tasks'
    or diag "got:\n$out";
};

subtest '--status done,archived surfaces both terminal groups (BUG: currently empty)' => sub {
  my $out = run_list( status => 'done,archived' );
  like $out, qr/Shipped feature/,    'done task included'
    or diag "got:\n$out";
  like $out, qr/Retired ticket/,     'first archived task included'
    or diag "got:\n$out";
  like $out, qr/Old cleanup task/,   'second archived task included'
    or diag "got:\n$out";
  unlike $out, qr/Open todo/,        'non-terminal tasks excluded';
  like $out, qr/^3 task\(s\)$/m,     'footer counts all 3 terminal tasks'
    or diag "got:\n$out";
};

subtest '--json is consistent: default excludes archived, explicit --status includes it' => sub {
  my $out_default = run_list( json => 1 );
  my $data_default = decode_json($out_default);
  my $titles_default = titles_of($data_default);
  ok( !$titles_default->{'Retired ticket'}, 'default --json omits archived task' )
    or diag "got:\n$out_default";
  ok( $titles_default->{'Open todo'}, 'default --json still includes open task' );

  my $out_archived = run_list( json => 1, status => 'archived' );
  my $data_archived = decode_json($out_archived);
  is( scalar @$data_archived, 2, '--status archived --json returns both archived tasks' )
    or diag "got:\n$out_archived";
  my $titles_archived = titles_of($data_archived);
  ok( $titles_archived->{'Retired ticket'},   '--json payload contains first archived task' )
    or diag "got:\n$out_archived";
  ok( $titles_archived->{'Old cleanup task'}, '--json payload contains second archived task' )
    or diag "got:\n$out_archived";
  is_deeply(
    [ sort grep { $_ } map { $_->{status} } @$data_archived ],
    [ 'archived', 'archived' ],
    'every task in the --status archived --json payload actually has status archived'
  ) or diag "got:\n$out_archived";
};

subtest '--status archived combined with --tag still filters correctly' => sub {
  my $out = run_list( status => 'archived', tag => 'chore' );
  unlike $out, qr/Retired ticket/,   '--tag chore excludes the archived task without that tag'
    or diag "got:\n$out";
  like $out, qr/Old cleanup task/,   '--tag chore keeps the archived task that has it'
    or diag "got:\n$out";
  like $out, qr/^1 task\(s\)$/m,     'footer counts just the one matching archived task'
    or diag "got:\n$out";
};

subtest '--status archived combined with --sort/--reverse still orders correctly' => sub {
  my $out = run_list( status => 'archived', sort => 'id', reverse => 1 );
  my ($first_id) = $out =~ /^#(\d+)/m;
  is( $first_id, 5, '--reverse on --status archived puts the higher id first' )
    or diag "got:\n$out";
};

done_testing;
