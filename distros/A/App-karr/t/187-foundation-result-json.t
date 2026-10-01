use strict;
use warnings;
use Test::More;
use Path::Tiny qw( path tempdir );

use App::karr::Foundation;
use App::karr::Git;
use App::karr::BoardStore;
use App::karr::Task;
use App::karr::Encoding qw( json_decode json_encode );

# Ticket #187: a run is classified from its result JSON, not by matching
# patterns against its transcript.
#
# The text scan exists because there was nothing better to read, and #160 is
# the standing record of what that costs: an agent working a karr board prints
# the board, so a backlog title and a diffstat both classified a healthy run as
# a rate limit. #160 bought that back by asking what the run DID before what it
# PRINTED -- but only where the run did something. A run that moved nothing is
# still judged by a word search over megabytes of the agent's own prose.
#
# A claude-code agent invoked with --output-format json ends its output with
# one line: a JSON object saying whether the run failed, how it ended, how many
# turns it took, how long it ran and what it cost. This file pins three things
# about reading it:
#
#   1. how foundation finds out there is one at all (the tail of the output,
#      not a config key and not a flag sniffed out of the command string),
#   2. that a mixture of prose and JSON cannot be misread as a report,
#   3. that where there is a report it replaces the scan, and where there is
#      none the scan is untouched.

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

sub make_git_repo {
  my $dir = tempdir( CLEANUP => 1 );
  system( 'git', '-C', "$dir", 'init', '-q' ) == 0                          or die "git init";
  system( 'git', '-C', "$dir", 'config', 'user.email', 'a@b.invalid' ) == 0 or die;
  system( 'git', '-C', "$dir", 'config', 'user.name', 'T' ) == 0            or die;
  return $dir;
}

sub seed_board {
  my ( $repo, @specs ) = @_;
  my $store = App::karr::BoardStore->new(
    git => App::karr::Git->new( dir => "$repo" ) );
  for my $spec ( @specs ) {
    my $id = $store->allocate_next_id;
    # todo, not backlog: the board has to hold open work, and backlog is held
    # back and not actionable (ticket k306).
    $store->save_task( App::karr::Task->new(
      id => $id, status => 'todo', title => "task $id",
      ref $spec ? %$spec : ( title => $spec ) ) );
  }
}

sub tasks_of {
  my ( $repo ) = @_;
  return App::karr::BoardStore->new(
    git => App::karr::Git->new( dir => "$repo" ) )->load_tasks;
}

sub task_by_id {
  my ( $repo, $id ) = @_;
  return App::karr::BoardStore->new(
    git => App::karr::Git->new( dir => "$repo" ) )->find_task( $id );
}

sub state_data {
  my ( $repo ) = @_;
  my $file = path( $repo )->child('.karr.state');
  return {} unless $file->exists;
  return json_decode( $file->slurp_utf8 );
}

sub log_of {
  my ( $repo ) = @_;
  my $file = path( $repo )->child('.karr.log');
  return $file->exists ? $file->slurp_utf8 : '';
}

# A result object in the shape `claude -p --output-format json` really emits
# (2.1.233): the fields this classification reads, with the rest of the real
# payload's bulk left out. Written as one line, which is how it arrives.
sub result_json {
  my ( %over ) = @_;
  return json_encode( {
    type             => 'result',
    subtype          => 'success',
    is_error         => \0,
    num_turns        => 7,
    duration_ms      => 1490,
    total_cost_usd   => 0.04704,
    session_id       => '10efe29e-1fad-4dce-8026-b4086b5c37f5',
    stop_reason      => 'end_turn',
    terminal_reason  => 'completed',
    api_error_status => undef,
    result           => 'done',
    %over,
  } );
}

# What #160's corpus proves an ordinary agent prints: its own board, including
# a backlog title with a symptom word in it, and a genuine-looking API error
# line. Neither may reach the classifier once the run has reported for itself.
my $NOISE = <<'NOISE';
#3 backlog retry the network fetch on 503
#4 backlog invalid credentials in the auth path
API Error: 429 {"type":"error","error":{"type":"rate_limit_error"}}
NOISE

# A harmless fake agent: it prints what the mode tells it to, optionally moves
# one card through karr's own store, and exits. It never leaves the temp repo
# and it never calls anything real.
sub write_fake_agent {
  my ( $dir ) = @_;
  my $lib    = path('lib')->absolute->stringify;
  my $script = path($dir)->child('fake-agent.pl');
  $script->spew_utf8(<<'PERL');
use strict;
use warnings;
require App::karr::Git;
require App::karr::BoardStore;
require App::karr::ActivityLog;

my $repo   = $ENV{KARR_REPO} or die "no KARR_REPO\n";
my $noise  = $ENV{KARR_FAKE_NOISE}  // '';
my $result = $ENV{KARR_FAKE_RESULT} // '';
my $where  = $ENV{KARR_FAKE_WHERE}  // 'last';   # last | middle | none
my $move   = $ENV{KARR_FAKE_MOVE}   // '';
my $code   = $ENV{KARR_FAKE_EXIT}   // 0;

if ( $move ) {
  my $store = App::karr::BoardStore->new(
    git => App::karr::Git->new( dir => $repo ) );
  my ( $t ) = grep {
    $_ && !$_->has_blocked && $_->status ne 'done' && $_->status ne 'archived'
  } $store->load_tasks;
  if ( $t ) {
    $t->status('done');
    $store->save_task( $t );
    App::karr::ActivityLog->new( git => $store->git, role => 'agent' )
      ->log_entry( agent => 'fake-agent', action => 'move',
                   task_id => $t->id + 0, detail => 'done' );
  }
}

print "$result\n" if $result && $where eq 'middle';
print $noise if length $noise;
print "$result\n" if $result && $where eq 'last';
exit $code;
PERL
  return qq{$^X -I"$lib" "$script"};
}

# ---------------------------------------------------------------------------
# Unit: finding the report
# ---------------------------------------------------------------------------

subtest 'a result object is found at the tail of the output, and only there' => sub {
  my $f  = App::karr::Foundation->new( _config_data => {} );
  my $js = result_json();

  is $f->_run_result( undef ), undef, 'no output, no report';
  is $f->_run_result( '' ),    undef, 'empty output, no report';

  my $bare = $f->_run_result( "$js\n" );
  is ref $bare, 'HASH', 'the object on its own is read';
  is $bare->{num_turns}, 7, 'and its fields come through';

  my $after_prose = $f->_run_result( "${NOISE}$js\n" );
  is ref $after_prose, 'HASH',
    'prose before the object does not hide it -- a wrapper banner, a warning '
    . 'that reached the shared pipe earlier';

  is $f->_run_result( "$js\n$NOISE" ), undef,
    'the same object quoted mid-transcript is not a report: an agent that '
    . 'prints a result it read somewhere must not classify its own run';

  is $f->_run_result( "$js\nall done, bye\n" ), undef,
    'and anything printed after it makes the run unstructured again';

  is $f->_run_result( $NOISE ), undef, 'prose alone: no report';
  is $f->_run_result( qq({"type":"stream_event","event":{}}\n) ), undef,
    'a JSON object that is not a result is not a report';
  is $f->_run_result( qq(["type","result"]\n) ), undef,
    'and neither is a JSON array';
  is $f->_run_result( "{ not json at all }\n" ), undef, 'nor broken JSON';

  is ref $f->_run_result( "$js\n\n  \n" ), 'HASH',
    'trailing blank lines are not output';
};

# ---------------------------------------------------------------------------
# Unit: reading the report
# ---------------------------------------------------------------------------

subtest 'the report says how the run ended, and whether that is a common error' => sub {
  my $f = App::karr::Foundation->new( _config_data => {} );

  my ( $err, $ended ) = $f->_result_error( json_decode( result_json() ) );
  is $err,   undef,     'a successful run is not an error';
  is $ended, 'success', 'and is logged as one';

  ( $err, $ended ) = $f->_result_error( json_decode( result_json(
    is_error => \1, subtype => 'error_max_turns', terminal_reason => 'max_turns',
  ) ) );
  is $ended, 'max turns', 'a spent turn budget is named';
  is $err, undef,
    'but it is not a common error: the agent worked and the provider '
    . 'answered, so parking the whole board for an hour is the wrong answer';

  ( $err, $ended ) = $f->_result_error( json_decode( result_json(
    is_error => \1, subtype => 'error_during_execution', api_error_status => 429,
  ) ) );
  is $err,   'api 429', 'a provider status is the case the scan existed for';
  is $ended, 'api 429', 'and reads the same in the log';

  ( $err, $ended ) = $f->_result_error( json_decode( result_json(
    is_error => \1, subtype => 'error_during_execution',
  ) ) );
  is $err, 'error_during_execution', 'any other reported error keeps its name';
};

# ---------------------------------------------------------------------------
# The headline: a report outranks the scan
# ---------------------------------------------------------------------------

subtest 'an agent that reports success is not reclassified by its own prose' => sub {
  my $repo = make_git_repo();
  seed_board( $repo, 'retry the network fetch on 503' );
  my $agent = write_fake_agent( $repo );

  # Nothing moved, so #160's guard does not apply and the scan is all that
  # used to be left: this run printed a verbatim 429 and used to be charged
  # as a rate limit, cooldown and all.
  local $ENV{KARR_FAKE_NOISE}  = $NOISE;
  local $ENV{KARR_FAKE_RESULT} = result_json();

  my $f = App::karr::Foundation->new( _config_data => {} );
  my $res = $f->_drain_repo( $repo, { command => $agent, max_runtime => 60 } );

  isnt $res->{outcome}, 'common-error',
    'the run reported success, so the words in its transcript do not count';
  is $res->{outcome}, 'idle', 'it moved nothing, which is idle';
  ok ! exists state_data( $repo )->{last_error}, 'no last_error recorded';
  unlike log_of( $repo ), qr/COMMON-ERROR/, 'and nothing in the log says otherwise';
  like log_of( $repo ), qr/RESULT success/, 'the report is logged';
  like log_of( $repo ), qr/RESULT success \(7 turns, 1\.5s, \$0\.0470\)/,
    'with the turns, the duration and the cost the report carried';
};

subtest 'an agent that reports nothing is still scanned, exactly as before' => sub {
  my $repo = make_git_repo();
  seed_board( $repo, 'tidy the parser' );
  my $agent = write_fake_agent( $repo );

  local $ENV{KARR_FAKE_NOISE}  = $NOISE;
  local $ENV{KARR_FAKE_RESULT} = '';

  my $f = App::karr::Foundation->new( _config_data => {} );
  my $res = $f->_drain_repo( $repo, { command => $agent, max_runtime => 60 } );

  is $res->{outcome}, 'common-error', 'the fallback is untouched';
  is state_data( $repo )->{last_error}, 'rate limit', 'and still names it';
};

subtest 'a report quoted mid-transcript classifies nothing' => sub {
  my $repo = make_git_repo();
  seed_board( $repo, 'tidy the parser' );
  my $agent = write_fake_agent( $repo );

  # The object is printed first and the prose after it, which is what an agent
  # pasting a result into its report looks like. It must not turn a genuine
  # rate limit into a success.
  local $ENV{KARR_FAKE_NOISE}  = $NOISE;
  local $ENV{KARR_FAKE_RESULT} = result_json();
  local $ENV{KARR_FAKE_WHERE}  = 'middle';

  my $f = App::karr::Foundation->new( _config_data => {} );
  my $res = $f->_drain_repo( $repo, { command => $agent, max_runtime => 60 } );

  is $res->{outcome}, 'common-error',
    'no report was made, so the scan decides and the 429 still counts';
  unlike log_of( $repo ), qr/RESULT /, 'and nothing was read as a report';
};

# ---------------------------------------------------------------------------
# A reported error is a hard signal, and its kind decides the cooldown
# ---------------------------------------------------------------------------

subtest 'a reported provider error backs the board off' => sub {
  my $repo = make_git_repo();
  seed_board( $repo, 'tidy the parser' );
  my $agent = write_fake_agent( $repo );

  # Exit 0 and a transcript with nothing quotable in it: without the report
  # this run is indistinguishable from an agent that found nothing to do.
  local $ENV{KARR_FAKE_NOISE}  = "working\n";
  local $ENV{KARR_FAKE_RESULT} = result_json(
    is_error => \1, subtype => 'error_during_execution', api_error_status => 429,
    result => undef );

  my $f = App::karr::Foundation->new( _config_data => {} );
  my $res = $f->_drain_repo( $repo, { command => $agent, max_runtime => 60 } );

  is $res->{outcome}, 'common-error', 'the report is believed';
  is state_data( $repo )->{last_error}, 'api 429', 'and names the status';
  ok ! ( grep { $_->has_blocked } tasks_of( $repo ) ), 'no task penalized for it';
};

subtest 'a spent turn budget is not a reason to park the board' => sub {
  my $repo = make_git_repo();
  seed_board( $repo, 'tidy the parser', 'update the docs' );
  my $agent = write_fake_agent( $repo );

  # claude exits 1 on error_max_turns. Before the report was read that exit
  # code was the whole story and the board went into an exponential cooldown
  # for running out of turns -- which the next run has no reason to repeat.
  local $ENV{KARR_FAKE_MOVE}   = 1;
  local $ENV{KARR_FAKE_EXIT}   = 1;
  local $ENV{KARR_FAKE_RESULT} = result_json(
    is_error => \1, subtype => 'error_max_turns', terminal_reason => 'max_turns',
    result => undef );

  my $f = App::karr::Foundation->new( _config_data => {} );
  my $res = $f->_drain_repo( $repo,
    { command => $agent, max_runtime => 60, max_iterations => 2 } );

  is $res->{outcome}, 'progress', 'the run did move a card, so it is progress';
  is $res->{exit}, 1, 'even though the agent exited non-zero';
  ok ! exists state_data( $repo )->{last_error},
    'and nothing was recorded as an error';
  like log_of( $repo ), qr/RESULT max turns/, 'the log says how it ended';
};

subtest 'an exit the report does not explain is still a common error' => sub {
  my $repo = make_git_repo();
  seed_board( $repo, 'tidy the parser' );
  my $agent = write_fake_agent( $repo );

  # A wrapper that failed after claude succeeded: the report says the run was
  # fine, the exit code says the pipeline was not, and the exit code is about
  # something the report has no opinion on.
  local $ENV{KARR_FAKE_EXIT}   = 3;
  local $ENV{KARR_FAKE_RESULT} = result_json();

  my $f = App::karr::Foundation->new( _config_data => {} );
  my $res = $f->_drain_repo( $repo, { command => $agent, max_runtime => 60 } );

  is $res->{outcome}, 'common-error', 'the exit code is not swallowed';
  is state_data( $repo )->{last_error}, 'exit=3', 'and it is what gets recorded';
};

# ---------------------------------------------------------------------------
# Ticket mode: what a stall was
# ---------------------------------------------------------------------------

subtest 'a ticket-mode stall says which stall it was' => sub {
  my $repo = make_git_repo();
  seed_board( $repo, { status => 'todo' } );
  my $agent = write_fake_agent( $repo );
  my $karr  = { command => $agent, max_runtime => 60, mode => 'ticket',
                max_attempts => 99 };

  local $ENV{KARR_FAKE_RESULT} = result_json( num_turns => 1 );
  my $f = App::karr::Foundation->new( _config_data => {} );
  my $first = $f->_drain_repo( $repo, $karr );
  is $first->{outcome}, 'stall', 'the card did not move';
  like log_of( $repo ),
    qr/STALL task#1 -- the agent reported success but the card did not move/,
    'an agent that thinks it is finished is one kind of stall';

  path( $repo )->child('.karr.log')->remove;
  local $ENV{KARR_FAKE_RESULT} = result_json(
    is_error => \1, subtype => 'error_max_turns', terminal_reason => 'max_turns',
    result => undef );
  local $ENV{KARR_FAKE_EXIT} = 1;
  my $second = $f->_drain_repo( $repo, $karr );
  is $second->{outcome}, 'stall', 'so is an agent that ran out of room';
  like log_of( $repo ), qr/STALL task#1 -- the agent ran out of turns/,
    'but the coordinator can tell the two apart';

  path( $repo )->child('.karr.log')->remove;
  local $ENV{KARR_FAKE_RESULT} = '';
  local $ENV{KARR_FAKE_EXIT}   = 0;
  my $third = $f->_drain_repo( $repo, $karr );
  is $third->{outcome}, 'stall', 'and an agent that reported nothing still stalls';
  like log_of( $repo ), qr/STALL task#1 -- no report from the agent/,
    'said as the absence it is, not guessed at';
};

# ---------------------------------------------------------------------------
# The report reaches .karr.state
# ---------------------------------------------------------------------------

subtest 'the last run report is kept in .karr.state, and dropped again' => sub {
  my $repo = make_git_repo();
  seed_board( $repo, 'tidy the parser', 'update the docs' );
  my $agent = write_fake_agent( $repo );
  $repo->child('.karr')->spew_utf8( "command: $agent\nmax_runtime: 60\ndrain: false\n" );

  my $f = App::karr::Foundation->new( _config_data => {}, force => 1 );

  {
    local $ENV{KARR_FAKE_MOVE}   = 1;
    local $ENV{KARR_FAKE_RESULT} = result_json();
    $f->_process_repo( $repo );
  }
  my $kept = state_data( $repo )->{last_result};
  is ref $kept, 'HASH', 'the report is recorded';
  is $kept->{ended},    'success', 'how the run ended';
  is $kept->{turns},    7,         'how many turns it took';
  is $kept->{duration}, 1490,      'how long it ran';
  cmp_ok $kept->{cost_usd}, '==', 0.04704, 'and what it cost';

  {
    local $ENV{KARR_FAKE_MOVE}   = 1;
    local $ENV{KARR_FAKE_RESULT} = '';
    $f->_process_repo( $repo );
  }
  ok ! exists state_data( $repo )->{last_result},
    'a run that reported nothing leaves no report behind describing an '
    . 'older one (#160: a stale key is a contradiction nobody can resolve)';
};

done_testing;
