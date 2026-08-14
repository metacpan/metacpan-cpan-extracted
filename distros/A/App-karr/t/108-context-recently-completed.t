# t/108-context-recently-completed.t
#
# Ticket #99: `karr context` built its recently-completed section by grepping
# the terminal statuses out of @active_tasks -- and @active_tasks is defined
# three lines above as the tasks whose status is NOT terminal. The intersection
# is empty by construction, so the section had never produced a single entry on
# any board, with or without the terminal-status work of ticket #67.
#
# kanban-md's buildRecentlyCompletedSection (internal/board/context.go) scans
# the whole task list and bounds it by the completion stamp, which is what karr
# does now. The bound stays day-granular: `completed` is a string here, and an
# interop card can carry it as a bare YYYY-MM-DD, as an RFC3339 stamp in UTC,
# or as one with a local offset.

use strict;
use warnings;
use Test::More;
use lib 't/lib';
use Time::Piece;
use JSON::MaybeXS qw( decode_json );

use App::karr::Config;
use App::karr::Task;
use App::karr::Cmd::Context;
use MockStore;

sub mk {
  my (%a) = @_;
  my $t = App::karr::Task->new(
    id       => $a{id},
    title    => $a{title},
    status   => $a{status},
    priority => $a{priority} // 'medium',
    class    => 'standard',
  );
  $t->completed( $a{completed} ) if defined $a{completed};
  return $t;
}

sub render {
  my (%opt) = @_;
  my $tasks = delete $opt{tasks};
  my $ec    = delete $opt{ec};
  my $store = MockStore->new(
    tasks => $tasks,
    ( $ec ? ( ec => $ec ) : () ),
  );
  my $cmd = App::karr::Cmd::Context->new( store => $store, %opt );
  my $buf = '';
  {
    local *STDOUT;
    # Same layer bin/karr installs via enable_std_utf8: reopening STDOUT drops
    # it, and App::karr::Encoding's POD makes putting it back the in-process
    # capturer's job. Without it the em dash in a noted item (ticket #108)
    # prints wide and warns.
    open STDOUT, '>:encoding(UTF-8)', \$buf or die $!;
    $cmd->execute( [], [] );
  }
  return $buf;
}

my $today     = gmtime->datetime . 'Z';
my $yesterday = ( gmtime() - 86400 )->datetime . 'Z';
my $long_ago  = ( gmtime() - 60 * 86400 )->datetime . 'Z';

subtest 'a card finished this week is reported' => sub {
  my $out = render(
    tasks => [
      mk( id => 1, title => 'Finished work', status => 'done', completed => $today ),
      mk( id => 2, title => 'Still going',   status => 'in-progress' ),
    ],
  );

  like( $out, qr/^### Recently Completed$/m, 'the section is rendered at all' )
    or diag("got:\n$out");
  like( $out, qr/\*\*#1\*\* Finished work/, 'with the finished card in it' )
    or diag("got:\n$out");
};

subtest 'the completion stamp is what bounds it' => sub {
  my $out = render(
    tasks => [
      mk( id => 1, title => 'Just now',   status => 'done', completed => $yesterday ),
      mk( id => 2, title => 'Last month', status => 'done', completed => $long_ago ),
      mk( id => 3, title => 'Never stamped', status => 'done' ),
    ],
  );

  like( $out, qr/\*\*#1\*\* Just now/, 'inside the window' ) or diag("got:\n$out");
  unlike( $out, qr/Last month/, 'outside the window' )       or diag("got:\n$out");
  unlike( $out, qr/Never stamped/,
    'and a card with no completion stamp is not "recently" anything' )
    or diag("got:\n$out");
};

subtest '--days widens the window' => sub {
  my $out = render(
    days  => 90,
    tasks => [ mk( id => 2, title => 'Last month', status => 'done', completed => $long_ago ) ],
  );
  like( $out, qr/\*\*#2\*\* Last month/, '--days 90 reaches back far enough' )
    or diag("got:\n$out");
};

subtest 'a bare YYYY-MM-DD stamp counts too' => sub {
  # What kanban-md's compat path accepts, and what karr wrote for `started`
  # before ticket #68.
  my $out = render(
    tasks => [
      mk( id => 1, title => 'Date only', status => 'done',
        completed => gmtime->strftime('%Y-%m-%d') ),
    ],
  );
  like( $out, qr/\*\*#1\*\* Date only/, 'a date-only stamp is inside the window' )
    or diag("got:\n$out");
};

subtest 'archived work is filed away, not recently completed' => sub {
  my $out = render(
    tasks => [
      mk( id => 1, title => 'Put away', status => 'archived', completed => $today ),
    ],
  );
  unlike( $out, qr/Recently Completed/, 'no section for an archived card alone' )
    or diag("got:\n$out");
};

subtest 'the board\'s own final column is what counts as completed' => sub {
  my $out = render(
    ec => {
      %{ App::karr::Config->default_config },
      board    => { name => 'Custom' },
      statuses => [qw( backlog doing shipped archived )],
    },
    tasks => [
      mk( id => 1, title => 'Delivered', status => 'shipped', completed => $today ),
    ],
  );
  like( $out, qr/\*\*#1\*\* Delivered/,
    'a shipped card is completed work on a board that ends in shipped' )
    or diag("got:\n$out");
};

subtest 'the JSON payload carries the section as well' => sub {
  my $out = render(
    json  => 1,
    tasks => [
      mk( id => 1, title => 'Finished work', status => 'done', completed => $today ),
    ],
  );
  my $data = decode_json($out);
  my ($section) = grep { $_->{name} eq 'recently-completed' } @{ $data->{sections} };
  ok( $section, 'recently-completed is in --json output' ) or diag("got:\n$out");
  is( $section->{items}[0]{id}, 1, 'with the finished card' );
  like( $section->{items}[0]{note}, qr/\Acompleted /, 'annotated with its stamp' );
};

subtest '--sections recently-completed selects it' => sub {
  my $out = render(
    sections => 'recently-completed',
    tasks    => [
      mk( id => 1, title => 'Finished work', status => 'done', completed => $today ),
      mk( id => 2, title => 'Still going',   status => 'in-progress' ),
    ],
  );
  like( $out, qr/Recently Completed/, 'the requested section is there' )
    or diag("got:\n$out");
  unlike( $out, qr/In Progress/, 'and nothing else is' ) or diag("got:\n$out");
};

done_testing;
