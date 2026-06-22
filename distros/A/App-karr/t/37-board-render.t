use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestGit qw( require_git_c );
require_git_c();
use File::Temp qw( tempdir );
use YAML::XS qw( Dump );

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
  my $cmd = App::karr::Cmd::Board->new( store => $store, %opt );
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
  like $out, qr/^## Done$/m,                            'empty-ish section still shown';

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
};

subtest 'archived empty section is skipped' => sub {
  my $out = render();
  unlike $out, qr/^## Archived$/m, 'empty archived not shown';
};

done_testing;
