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
use App::karr::Cmd::Board;

sub _init_repo {
  my $repo = tempdir( CLEANUP => 1 );
  system( 'git', 'init', '-q', $repo );
  system( 'git', '-C', $repo, 'config', 'user.email', 'test@example.com' );
  system( 'git', '-C', $repo, 'config', 'user.name', 'Test User' );
  return $repo;
}

my $repo  = _init_repo();
my $git   = App::karr::Git->new( dir => $repo );
$git->write_ref( 'refs/karr/config', Dump( { version => 1, board => { name => 'My Board' } } ) );
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
  $t->due( $a{due} )               if $a{due};
  $t->claimed_by( $a{claimed_by} ) if $a{claimed_by};
  $t->blocked( $a{blocked} )       if $a{blocked};
  $t->tags( $a{tags} )             if $a{tags};
  $store->save_task($t);
}

mk( id => 1, title => 'Write documentation', status => 'todo',        priority => 'high', due => '2026-07-01' );
mk( id => 2, title => 'Review pull requests', status => 'in-progress', claimed_by => 'getty' );
mk( id => 3, title => 'Fix sync race',        status => 'in-progress', priority => 'critical',
    claimed_by => 'alice', blocked => 'waiting on libgit2' );
mk( id => 4, title => 'Ship v0.301',          status => 'done' );
mk( id => 5, title => 'Tagged task',          status => 'todo', tags => [qw( docs urgent )] );

sub render {
  my (%opt) = @_;
  local $ENV{NO_COLOR} = 1;
  my $target_store = delete $opt{store} // $store;
  my $cmd = App::karr::Cmd::Board->new( store => $target_store, %opt );
  my $buf = '';
  {
    local *STDOUT;
    open STDOUT, '>', \$buf or die $!;
    $cmd->execute( [], [] );
  }
  return $buf;
}

subtest 'default kanban-style rendering' => sub {
  my $out = render();

  like $out, qr/^# My Board$/m,                        'board name as h1';
  like $out, qr/^## Todo$/m,                            'status header title-cased';
  like $out, qr/^## In Progress$/m,                     'kebab status -> "In Progress"';
  # CHANGED for ticket #10 (2026-07-02): done tasks are no longer shown by
  # default; this used to assert the opposite ('## Done' always rendered).
  # See the dedicated 'done tasks are hidden by default' subtest below.
  unlike $out, qr/^## Done$/m,                          'Done section omitted by default';

  like $out, qr/^- 1 \| Write documentation \| priority:high \| due:2026-07-01$/m,
    'task line: id | title | priority | due';
  like $out, qr/^- 2 \| Review pull requests \| \@getty$/m,
    'claimed task shows @owner and omits default priority';
  unlike $out, qr/priority:medium/,                     'medium (default) priority is suppressed';
  like $out, qr/^- 3 \| Fix sync race \| priority:critical \| \@alice \| blocked:waiting on libgit2$/m,
    'blocked task shows reason';

  unlike $out, qr/#docs|#urgent/,                       'tags hidden without --tags';

  like $out, qr/^5 tasks/m,                             'footer counts tasks';
  like $out, qr/\bclaimed\b/,                           'footer mentions claimed';
  like $out, qr/\bblocked\b/,                           'footer mentions blocked';
};

subtest '--tags adds an extra tag line' => sub {
  my $out = render( tags => 1 );
  like $out, qr/^- 5 \| Tagged task$/m,                 'tagged task line unchanged';
  like $out, qr/^\s+#docs #urgent$/m,                   'tags on their own indented line';
  unlike $out, qr/Ship v0\.301/,                        'done task stays hidden under --tags too';
};

subtest 'archived empty section is skipped' => sub {
  my $out = render();
  unlike $out, qr/^## Archived$/m, 'empty archived not shown';
};

# --- Ticket #10: hide done tasks by default, add --done to show them -----

subtest 'done tasks hidden by default, footer shows a hidden-count hint' => sub {
  my $out = render();

  unlike $out, qr/^## Done$/m,        'Done section is omitted entirely';
  unlike $out, qr/Ship v0\.301/,      'done task title is not rendered anywhere';
  like $out, qr/^5 tasks \(1 done hidden\)/m,
    'footer pins "N tasks (M done hidden)" with the correct hidden count';
};

subtest '--done renders the Done section as before, no hidden-count hint' => sub {
  my $out = render( done => 1 );

  like $out, qr/^## Done$/m,                       'Done section is rendered with --done';
  like $out, qr/^- 4 \| Ship v0\.301$/m,           'done task line renders like any other status';
  unlike $out, qr/done hidden/,                    'no hidden-count hint when nothing is hidden';
  unlike $out, qr/^5 tasks \(/m,                   'footer count has no parenthetical with --done';
};

subtest 'empty done section: no hint, output unchanged from today' => sub {
  my $repo2  = _init_repo();
  my $git2   = App::karr::Git->new( dir => $repo2 );
  $git2->write_ref( 'refs/karr/config', Dump( { version => 1, board => { name => 'No Done Board' } } ) );
  my $store2 = App::karr::BoardStore->new( git => $git2 );
  $store2->save_task( App::karr::Task->new(
    id => 1, title => 'Only task', status => 'todo', priority => 'medium', class => 'standard',
  ) );

  my $out = render( store => $store2 );
  unlike $out, qr/^## Done$/m,     'empty done section stays hidden, same as today';
  unlike $out, qr/done hidden/,    'no hidden-count hint when there is nothing to hide';
  like $out, qr/^1 tasks$/m,       'footer unaffected when done is empty';
};

subtest 'json board output: same filtering, --done includes done tasks' => sub {
  my $out = render( json => 1 );
  unlike $out, qr/Ship v0\.301/, 'default JSON payload does not leak the done task';

  my $data = decode_json($out);
  ok( $data->{columns}, 'json payload has a columns array' );

  my $out_done = render( json => 1, done => 1 );
  like $out_done, qr/Ship v0\.301/, '--done JSON payload includes the done task';

  my $data_done  = decode_json($out_done);
  my ($done_col) = grep { $_->{status} eq 'done' } @{ $data_done->{columns} };
  ok( $done_col, 'done column is present in the json structure with --done' );
  ok( ( grep { $_->{title} eq 'Ship v0.301' } @{ $done_col->{tasks} // [] } ),
    'done task appears inside the done column with --done' );
};

done_testing;
