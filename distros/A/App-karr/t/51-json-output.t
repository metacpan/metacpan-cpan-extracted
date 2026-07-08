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
use App::karr::Cmd::Move;
use App::karr::Cmd::Edit;
use App::karr::Cmd::Show;
use App::karr::Cmd::Pick;
use App::karr::Cmd::Handoff;

# Ticket #24: two JSON-output duplicates were pulled into shared helpers --
#   Role::Output->print_json_results (the "single result is a bare object,
#   many results are an array" tail used by move/edit/delete/archive) and
#   Task->to_json_hash (frontmatter + body payload used by show/pick/handoff).
# delete --json (t/44) and archive --json (t/45) already cover the first helper,
# but move/edit/show/pick/handoff had no --json coverage at all. This pins the
# behaviour those helpers now carry so the refactor -- and any future edit to it
# -- can't silently change the JSON contract.

sub _fresh_store {
  my $repo = tempdir( CLEANUP => 1 );
  system( 'git', 'init', '-q', $repo );
  system( 'git', '-C', $repo, 'config', 'user.email', 'test@example.com' );
  system( 'git', '-C', $repo, 'config', 'user.name', 'Test User' );
  my $git = App::karr::Git->new( dir => $repo );
  $git->write_ref( 'refs/karr/config', Dump( { version => 1, board => { name => 'T' } } ) );
  $git->write_ref( 'refs/karr/meta/next-id', "9\n" );
  return App::karr::BoardStore->new( git => $git );
}

sub _save {
  my ( $store, %args ) = @_;
  $store->save_task(
    App::karr::Task->new(
      id       => $args{id},
      title    => $args{title},
      status   => $args{status}   // 'todo',
      priority => $args{priority} // 'medium',
      class    => 'standard',
      body     => $args{body}     // '',
    )
  );
}

# Capture STDOUT of a command's execute() (sync chatter goes to STDERR, so the
# capture stays clean JSON in --json mode).
sub _run_execute {
  my ( $cmd, @args ) = @_;
  my $out;
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

subtest 'Task->to_json_hash: frontmatter plus body only when body is set' => sub {
  my $with = App::karr::Task->new( id => 1, title => 'Alpha', body => 'hello' );
  my $h    = $with->to_json_hash;
  is( $h->{id},    1,       'id carried through from frontmatter' );
  is( $h->{title}, 'Alpha', 'title carried through from frontmatter' );
  is( $h->{body},  'hello', 'body key present when body is non-empty' );

  my $without = App::karr::Task->new( id => 2, title => 'Beta' );
  my $h2      = $without->to_json_hash;
  is( $h2->{id}, 2, 'frontmatter still built when body is empty' );
  ok( !exists $h2->{body}, 'body key absent when body is empty' );
};

subtest 'move --json: single id is a bare object, batch is an array' => sub {
  my $store = _fresh_store();
  _save( $store, id => 1, title => 'Alpha', status => 'todo' );

  my $cmd = App::karr::Cmd::Move->new( store => $store, json => 1 );
  my ( $err, $out ) = _run_execute( $cmd, '1', 'done' );
  is( $err, '', 'move 1 done --json does not die' ) or diag $err;

  my $data = eval { decode_json($out) };
  is( ref $data, 'HASH', 'single move --json emits a bare JSON object' ) or diag $out;
  is( $data->{id},         1,      'object carries the moved id' );
  is( $data->{old_status}, 'todo', 'old_status reported' );
  is( $data->{new_status}, 'done', 'new_status reported' );

  my $store2 = _fresh_store();
  _save( $store2, id => 1, title => 'Alpha', status => 'todo' );
  _save( $store2, id => 2, title => 'Beta',  status => 'todo' );

  my $cmd2 = App::karr::Cmd::Move->new( store => $store2, json => 1 );
  my ( $err2, $out2 ) = _run_execute( $cmd2, '1,2', 'done' );
  is( $err2, '', 'move 1,2 done --json does not die' ) or diag $err2;

  my $arr = eval { decode_json($out2) };
  is( ref $arr,       'ARRAY', 'batch move --json emits a JSON array' ) or diag $out2;
  is( scalar @$arr,   2,       'one array entry per moved task' );
  is( $arr->[0]{id},  1,       'first entry is task 1' );
  is( $arr->[1]{id},  2,       'second entry is task 2' );
};

subtest 'move without --json: print_json_results is a no-op (guard)' => sub {
  my $store = _fresh_store();
  _save( $store, id => 1, title => 'Alpha', status => 'todo' );

  my $cmd = App::karr::Cmd::Move->new( store => $store );
  my ( $err, $out ) = _run_execute( $cmd, '1', 'done' );
  is( $err, '', 'move without --json does not die' );
  like( $out, qr/Moved task 1/, 'human-readable line printed' );

  # A removed guard would leak the results object/array into plain output; the
  # human line itself carries no braces, so any brace means JSON leaked through.
  unlike( $out, qr/[{}]/, 'no JSON emitted when --json is absent' );

  my $decoded = eval { decode_json($out) };
  ok( !defined $decoded, 'plain output is not JSON-decodable' );
};

subtest 'edit --json: single id is a bare object with id and title' => sub {
  my $store = _fresh_store();
  _save( $store, id => 1, title => 'Old title', status => 'todo' );

  my $cmd = App::karr::Cmd::Edit->new(
    store => $store,
    json  => 1,
    title => 'New title',
  );
  my ( $err, $out ) = _run_execute( $cmd, '1' );
  is( $err, '', 'edit 1 --json does not die' ) or diag $err;

  my $data = eval { decode_json($out) };
  is( ref $data,     'HASH',      'single edit --json emits a bare JSON object' ) or diag $out;
  is( $data->{id},    1,          'object carries the edited id' );
  is( $data->{title}, 'New title', 'edited title reflected in the payload' );
};

subtest 'show --json: explicit id renders frontmatter + body via to_json_hash' => sub {
  my $store = _fresh_store();
  _save( $store, id => 1, title => 'Alpha', status => 'todo', body => 'Alpha body' );

  my $cmd = App::karr::Cmd::Show->new( store => $store, json => 1 );
  my ( $err, $out ) = _run_execute( $cmd, '1' );
  is( $err, '', 'show 1 --json does not die' ) or diag $err;

  my $data = eval { decode_json($out) };
  is( ref $data,      'HASH',       'explicit id --json stays a bare object' ) or diag $out;
  is( $data->{id},     1,           'id present' );
  is( $data->{title},  'Alpha',     'title present' );
  is( $data->{status}, 'todo',      'status present' );
  is( $data->{body},   'Alpha body', 'body included when present' );
};

subtest 'pick --json: picked task payload built via to_json_hash' => sub {
  my $store = _fresh_store();
  _save( $store, id => 1, title => 'Alpha', status => 'todo', priority => 'high', body => 'Alpha body' );

  my $cmd = App::karr::Cmd::Pick->new(
    store => $store,
    claim => 'agent-test',
    json  => 1,
  );
  my ( $err, $out ) = _run_execute($cmd);
  is( $err, '', 'pick --json does not die' ) or diag $err;

  my $data = eval { decode_json($out) };
  is( ref $data,          'HASH',       'pick --json emits a bare JSON object' ) or diag $out;
  is( $data->{id},         1,           'picked id present' );
  is( $data->{claimed_by}, 'agent-test', 'claim reflected in payload' );
  is( $data->{body},       'Alpha body', 'body included' );
};

subtest 'handoff --json: review payload built via to_json_hash' => sub {
  my $store = _fresh_store();
  _save( $store, id => 1, title => 'Alpha', status => 'in-progress', body => 'Alpha body' );

  my $cmd = App::karr::Cmd::Handoff->new(
    store => $store,
    claim => 'agent-test',
    json  => 1,
  );
  my ( $err, $out ) = _run_execute( $cmd, '1' );
  is( $err, '', 'handoff --json does not die' ) or diag $err;

  my $data = eval { decode_json($out) };
  is( ref $data,          'HASH',       'handoff --json emits a bare JSON object' ) or diag $out;
  is( $data->{id},         1,           'handoff id present' );
  is( $data->{status},     'review',    'status moved to review' );
  is( $data->{claimed_by}, 'agent-test', 'claim reflected in payload' );
  is( $data->{body},       'Alpha body', 'body included' );
};

done_testing;
