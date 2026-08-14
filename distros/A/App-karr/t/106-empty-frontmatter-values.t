# t/106-empty-frontmatter-values.t
#
# Ticket #98: an optional frontmatter key that is present but empty must load
# as "unset", not as "set to nothing".
#
# Every optional field karr models is `omitempty` in kanban-md's Go struct, so
# "absent" and "present but empty" are one state over there. On this side Moo's
# predicate calls the second one set, and karr reads "attribute is set" as "has
# a value". A card carrying `claimed_by: ""` -- hand-written, or written by a
# third tool -- therefore looked claimed to everything that asked:
#
#   karr show 1     ->  "Claimed:  "        (a label with nothing after it)
#   karr board      ->  "- 1 | Card | @"    and "1 claimed" in the footer
#   karr move 1 in-progress
#                   ->  accepted with no claimant at all, because the card
#                       already "had" one and require_claim was satisfied
#   karr-foundation ->  counted the card as one the agent had engaged, which
#                       is what feeds the auto-block
#
# Ticket #59 patched three readers of this one at a time (pick, list, context's
# overdue). The fix here is in App::karr::Task::BUILD instead, once, so a reader
# nobody has written yet cannot get it wrong either.
#
# Emptiness is length and never truth: `0` and `"0"` are one character long and
# must survive. That is the trap ticket #78 hit with a body of "0".

use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestGit qw( require_git_c );
require_git_c();
use File::Temp qw( tempdir );
use YAML::XS qw( Dump );

use App::karr::ActivityLog;
use App::karr::Config;
use App::karr::Git;
use App::karr::BoardStore;
use App::karr::Task;
use App::karr::Cmd::Show;
use App::karr::Cmd::Board;
use App::karr::Cmd::Edit;
use App::karr::Cmd::Move;
use App::karr::Foundation;

# Every optional field, minus `blocked`: that one is a boolean, and both the
# empty string and a "0" spelling of it correctly mean "not blocked" -- see the
# dedicated subtest below.
my @OPTIONAL = qw(
  assignee due estimate parent claimed_by claimed_at block_reason
  started completed
);

sub card {
  my (%extra) = @_;
  my $fm = join '', map { "$_: $extra{$_}\n" } sort keys %extra;
  return "---\nid: 1\ntitle: Interop card\nstatus: backlog\n"
    . "priority: medium\nclass: standard\n"
    . "created: 2026-01-01T00:00:00Z\nupdated: 2026-01-01T00:00:00Z\n"
    . $fm . "---\n";
}

sub init_repo {
  my $repo = tempdir( CLEANUP => 1 );
  system( 'git', 'init', '-q', $repo ) == 0 or BAIL_OUT('git init failed');
  system( 'git', '-C', $repo, 'config', 'user.email', 'test@example.com' ) == 0
    or BAIL_OUT('git config failed');
  system( 'git', '-C', $repo, 'config', 'user.name', 'Test User' ) == 0
    or BAIL_OUT('git config failed');
  return $repo;
}

# A board holding one card, written as raw frontmatter. Task->new cannot build
# this card any more -- clearing the empty values is the fix -- so the bytes go
# straight into the ref the way an import or a hand edit would leave them.
sub board_with {
  my ($content) = @_;
  my $repo = init_repo();
  my $git  = App::karr::Git->new( dir => $repo );
  $git->write_ref( 'refs/karr/config', Dump( App::karr::Config->default_config ) );
  $git->write_ref( 'refs/karr/meta/next-id', "9\n" );
  $git->write_ref( 'refs/karr/tasks/1/data', $content );
  return ( App::karr::BoardStore->new( git => $git ), $repo );
}

sub capture {
  my ($code) = @_;
  my $buf = '';
  {
    local *STDOUT;
    open STDOUT, '>', \$buf or die $!;
    $code->();
  }
  return $buf;
}

subtest 'an empty optional value loads as unset' => sub {
  my $task = App::karr::Task->from_string(
    card( map { $_ => q{""} } @OPTIONAL, 'blocked' ) );

  for my $attr ( @OPTIONAL, 'blocked' ) {
    my $has = "has_$attr";
    ok( !$task->$has, "$attr: \"\" loads as unset" );
  }
};

subtest 'an explicit null still loads as unset' => sub {
  # The pre-#98 behaviour, which must not regress: this is what karr's own
  # older writes and an external null-valued edit look like.
  my $task = App::karr::Task->from_string(
    card( map { $_ => '~' } @OPTIONAL, 'blocked' ) );

  for my $attr ( @OPTIONAL, 'blocked' ) {
    my $has = "has_$attr";
    ok( !$task->$has, "$attr: null loads as unset" );
  }
};

subtest '0 and "0" are values, not emptiness' => sub {
  my $zero = App::karr::Task->from_string( card( map { $_ => 0 } @OPTIONAL ) );
  for my $attr (@OPTIONAL) {
    my $has = "has_$attr";
    ok( $zero->$has, "$attr: 0 survives as a value" );
    is( $zero->$attr, '0', "$attr: and its value is still 0" );
  }

  my $quoted = App::karr::Task->from_string( card( map { $_ => q{"0"} } @OPTIONAL ) );
  for my $attr (@OPTIONAL) {
    my $has = "has_$attr";
    ok( $quoted->$has, qq{$attr: "0" survives as a value} );
  }
};

subtest 'blocked keeps its own boolean rules' => sub {
  # `blocked` is a bool with omitempty on the Go side, so an empty value and a
  # "0" spelling both mean not blocked. _normalize_blocked already said so; the
  # empty-string clearing must not change that answer either way.
  for my $spelling ( q{""}, '0', 'false', 'no' ) {
    my $t = App::karr::Task->from_string( card( blocked => $spelling ) );
    ok( !$t->has_blocked, "blocked: $spelling is not blocked" );
  }
  for my $spelling ( '1', 'true', 'yes' ) {
    my $t = App::karr::Task->from_string( card( blocked => $spelling ) );
    ok( $t->has_blocked, "blocked: $spelling is blocked" );
  }
};

subtest 'the empty keys do not survive a write' => sub {
  my $task = App::karr::Task->from_string(
    card( map { $_ => q{""} } @OPTIONAL, 'blocked' ) );
  my $fm = $task->to_frontmatter;

  for my $attr ( @OPTIONAL, 'blocked' ) {
    ok( !exists $fm->{$attr}, "to_frontmatter drops $attr" );
  }
  # kanban-md's own writer omits them too, so this is what makes karr's
  # rewrite of an imported card byte-shaped like one kanban-md wrote itself.
  my $md = $task->to_markdown;
  unlike( $md, qr/^(?:@{[ join '|', @OPTIONAL, 'blocked' ]}):/m,
    'and none of them reach the document' )
    or diag("wrote:\n$md");

  my $json = $task->to_json_hash;
  ok( !exists $json->{$_}, "--json payload has no $_ key" )
    for ( @OPTIONAL, 'blocked' );
};

subtest 'show does not print a label with nothing after it' => sub {
  my ($store) = board_with( card( map { $_ => q{""} } @OPTIONAL ) );
  my $out = capture(
    sub { App::karr::Cmd::Show->new( store => $store )->execute( [1], [] ) } );

  like( $out, qr/^Task #1: Interop card$/m, 'the card is shown' )
    or diag("got:\n$out");
  for my $label (qw( Assignee Due Estimate Claimed Blocked )) {
    unlike( $out, qr/^\Q$label\E:\s*$/m, "no bare $label: line" )
      or diag("got:\n$out");
  }
};

subtest 'board does not show or count a claim that is not there' => sub {
  local $ENV{NO_COLOR} = 1;
  my ($store) = board_with( card( claimed_by => q{""}, due => q{""} ) );
  my $out = capture(
    sub { App::karr::Cmd::Board->new( store => $store )->execute( [], [] ) } );

  like( $out, qr/^- 1 \| Interop card$/m,
    'the card renders with no claim and no due token' )
    or diag("got:\n$out");
  unlike( $out, qr/claimed/, 'and the footer counts no claim' )
    or diag("got:\n$out");
};

subtest 'require_claim is not satisfied by claimed_by: ""' => sub {
  my ($store) = board_with( card( claimed_by => q{""} ) );

  # The batch loop reports a per-id failure on STDERR and dies with a summary
  # (ticket #61), so the reason is in the warning and the refusal is in $@.
  my $warned = '';
  my $err    = do {
    local $@;
    local $SIG{__WARN__} = sub { $warned .= $_[0] };
    eval {
      capture( sub {
        App::karr::Cmd::Move->new( store => $store )
          ->execute( [ 1, 'in-progress' ], [] );
      } );
      1;
    } ? undef : ( $@ || 'unknown error' );
  };

  ok( defined $err, 'the move fails' )
    or diag('move succeeded, which it must not');
  like( $warned, qr/requires --claim/,
    'moving into a require_claim status still needs a real claimant' )
    or diag("warned: $warned");

  my ($task) = $store->load_tasks;
  is( $task->status, 'backlog', 'and the card did not move' );
};

subtest 'the activity log falls through to the git identity' => sub {
  # A sixth reader of the same assumption, not listed on the ticket:
  # App::karr::Role::BoardAccess::log_agent attributes a write to whoever holds
  # the task before it falls back to the Git identity, so `claimed_by: ""`
  # wrote `"agent": ""` into the log -- an entry that names nobody at all.
  my ($store) = board_with( card( claimed_by => q{""} ) );
  my $err = do {
    local $@;
    my $out = '';
    eval {
      local *STDOUT;
      open STDOUT, '>', \$out or die $!;
      App::karr::Cmd::Edit->new( store => $store, append_body => 'note' )
        ->execute( [1], [] );
      1;
    } ? undef : ( $@ || 'unknown error' );
  };
  is( $err, undef, 'the edit goes through' ) or diag("died with: $err");

  my $log = App::karr::ActivityLog->new( git => $store->git, role => 'user' );
  my ($entry) = grep { $_->{action} eq 'edit' } $log->entries;
  ok( $entry, 'the edit was logged' );
  ok( defined $entry->{agent} && length $entry->{agent},
    'and it names somebody' )
    or diag( 'logged agent: ' . ( defined $entry->{agent} ? "'$entry->{agent}'" : 'undef' ) );
};

subtest 'foundation does not treat an empty claim as an engaged card' => sub {
  my ( undef, $repo ) = board_with( card( claimed_by => q{""} ) );
  my $foundation = App::karr::Foundation->new;
  my %states     = $foundation->_task_states($repo);

  ok( exists $states{1}, 'the card is in the snapshot' );
  is( $states{1}{claimed_by}, undef, 'with no claimant recorded' );
  ok( $foundation->_is_actionable( $states{1} ), 'and it is still actionable' );

  # Identical before and after a run means the agent made no progress. A card
  # nobody ever claimed must not count toward the auto-block for that -- even
  # when the agent did write to it during the run, which is what the engagement
  # record here says (#158).
  my $engaged = { seen => 0, ids => { 1 => 1 }, claims => {} };
  is_deeply( [ $foundation->_stuck_tasks( \%states, \%states, $engaged ) ], [],
    'an unclaimed card is not a stuck task' );
};

done_testing;
