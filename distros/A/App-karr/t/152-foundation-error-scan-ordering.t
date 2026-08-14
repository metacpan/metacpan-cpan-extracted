use strict;
use warnings;
use Test::More;
use Path::Tiny qw( path tempdir );

use App::karr::Foundation;
use App::karr::Git;
use App::karr::BoardStore;
use App::karr::Task;
use App::karr::Encoding qw( json_decode );

# Ticket #160: foundation scanned an agent's whole transcript for bare
# substrings -- network, quota, credentials, 401, 403, 429, 503 -- before it
# looked at what the run had done. An agent working a karr board prints the
# board, so a backlog line reading "retry the network fetch on 503" and a
# diffstat of 403 changed lines both classified a run that exited 0 and moved
# a card as a common error: the drain aborted, the progress was credited to
# nobody, and the cooldown climbed 1m, 2m, 4m ... 64m without ever resetting,
# because the next run printed the same words.
#
# Two rules come out of that, and this file holds both halves of each: what the
# run DID outranks what it PRINTED (a run that moved the board is never
# reclassified by its own output), and a symptom word only counts next to a
# failure word or inside a phrase an API really emits. Neither may cost the
# feature its reason to exist -- a genuine rate limit reported by an agent that
# still exits 0 has to keep triggering the backoff.

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
  my ( $repo, @titles ) = @_;
  my $store = App::karr::BoardStore->new(
    git => App::karr::Git->new( dir => "$repo" ) );
  for my $title ( @titles ) {
    my $id = $store->allocate_next_id;
    $store->save_task( App::karr::Task->new(
      id => $id, title => $title, status => 'backlog' ) );
  }
}

sub tasks_of {
  my ( $repo ) = @_;
  return App::karr::BoardStore->new(
    git => App::karr::Git->new( dir => "$repo" ) )->load_tasks;
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

# A harmless fake agent driven by $KARR_FAKE_MODE, acting on $KARR_REPO through
# karr's own store -- never a real agent, and it never leaves the temp repo.
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

my $repo = $ENV{KARR_REPO} or die "no KARR_REPO\n";
my $mode = $ENV{KARR_FAKE_MODE} // 'chatty';
my $flag = $ENV{KARR_FAKE_FLAG} // '';

# Verbatim in shape: what a rate-limited claude CLI prints before exiting 0.
my $RATE_LIMIT =
  qq(API Error: 429 {"type":"error","error":{"type":"rate_limit_error"}}\n);

my $store = App::karr::BoardStore->new(
  git => App::karr::Git->new( dir => $repo ) );
my @open = grep {
  $_ && !$_->has_blocked && $_->status ne 'done' && $_->status ne 'archived'
} $store->load_tasks;

sub move_one {
  my $t = $open[0] or return;
  $t->status('done');
  $store->save_task( $t );
  # The other half of what `karr move --claim` writes: foundation's only
  # evidence of engagement is the board's activity log (#158).
  App::karr::ActivityLog->new( git => $store->git, role => 'agent' )
    ->log_entry( agent => 'fake-agent', action => 'move',
                 task_id => $t->id + 0, detail => 'done' );
  print "moved #" . $t->id . " to done\n";
}

$mode = ( $flag && -e $flag ) ? 'limited' : 'quiet' if $mode eq 'flagged';

if ( $mode eq 'chatty' ) {
  # What the agent's own `karr list --compact` prints, plus a diffstat.
  printf "#%s %s %s\n", $_->id, $_->status, $_->title for @open;
  print " lib/App/karr/Foundation.pm | 403 ++++++++-----\n";
  print " 1 file changed, 403 insertions(+), 261 deletions(-)\n";
  move_one();
}
elsif ( $mode eq 'limited' ) {
  print $RATE_LIMIT;      # and nothing moves: the agent could not work
}
elsif ( $mode eq 'limited-progress' ) {
  move_one();
  print $RATE_LIMIT;      # hit the wall after getting one card moved
}
elsif ( $mode eq 'quiet' ) {
  move_one();
}
exit 0;
PERL
  return qq{$^X -I"$lib" "$script"};
}

# ---------------------------------------------------------------------------
# The patterns: ordinary agent output
# ---------------------------------------------------------------------------

subtest 'ordinary agent output is not a common error' => sub {
  my $f   = App::karr::Foundation->new;
  my $pat = $f->_error_patterns( {} );

  my @mundane = (
    [ 'a backlog line about networking'    =>
      "#1 backlog retry the network fetch on 503\n#2 backlog tidy the parser\n" ],
    [ 'a diffstat with 403 changed lines'  =>
      " lib/App/karr/Foundation.pm | 403 ++++++++-----\n"
      . " 1 file changed, 403 insertions(+), 261 deletions(-)\n" ],
    [ 'a commit hash'                      => "commit 4291d403b529f401e503bc0e\n" ],
    [ 'a source line number'               => "at lib/App/karr/Foundation.pm line 403.\n" ],
    [ 'a ticket about rate limiting'       => "#12 todo add rate limiting to the api client\n" ],
    [ 'a ticket about credentials'         => "#13 todo document the credentials file format\n" ],
    [ 'a ticket about quotas'              => "#15 backlog quota accounting for the runner\n" ],
    [ 'byte and millisecond counts'        => "read 429 bytes in 503ms\n" ],
    [ 'a ref path holding a task id'       => "wrote refs/karr/tasks/403/data\n" ],
    [ 'an ordinary success line'           => "all tests passed\n" ],
  );

  for my $case ( @mundane ) {
    my ( $what, $text ) = @$case;
    is $f->_match_error( $text, $pat ), undef, "not an error: $what";
  }
};

# ---------------------------------------------------------------------------
# The patterns: what the scan exists for
# ---------------------------------------------------------------------------

my @GENUINE = (
    [ 'rate limit'            =>
      'API Error: 429 {"type":"error","error":{"type":"rate_limit_error"}}' ],
    [ 'rate limit'            => 'Error: rate limit exceeded, retry later' ],
    [ 'usage limit'           => 'Claude AI usage limit reached|1786560000' ],
    [ 'authentication'        =>
      'API Error: 401 {"type":"error","error":{"type":"authentication_error"}}' ],
    [ 'invalid api key'       => 'Invalid API key - Please run /login' ],
    [ 'credentials'           => 'invalid credentials for the configured account' ],
    [ '403'                   => 'Request failed with status code 403' ],
    [ 'too many requests'     => '429 Too Many Requests' ],
    [ 'service unavailable'   => 'HTTP/1.1 503 Service Unavailable' ],
    [ 'overloaded'            =>
      'API Error: 529 {"type":"error","error":{"type":"overloaded_error"}}' ],
    [ 'quota'                 => 'your quota has been exceeded, try again tomorrow' ],
    [ 'network'               => 'Error: network error while contacting the API' ],
    [ 'connection'            => 'connection reset by peer' ],
    [ 'connection'            => 'connect ECONNREFUSED 127.0.0.1:443' ],
    [ 'name resolution'       => 'could not resolve host: api.anthropic.invalid' ],
    [ 'timed out'             => 'request timed out after 30s' ],
    [ 'internal server error' => '500 Internal Server Error' ],
);

subtest 'genuine API failures are still caught' => sub {
  my $f   = App::karr::Foundation->new;
  my $pat = $f->_error_patterns( {} );

  for my $case ( @GENUINE ) {
    my ( $name, $text ) = @$case;
    is $f->_match_error( "$text\n", $pat ), $name, "caught as '$name': $text";
  }
};

subtest 'the pre-filter agrees with the patterns it skips for' => sub {
  # Each default pattern carries the lowercase literals it cannot match
  # without, and _match_error runs index() for those before the regex — a
  # transcript is megabytes and these patterns are not substrings any more. A
  # trigger that does not occur in what its own pattern matches would switch
  # that pattern off in silence, so the two are checked against each other.
  my $f   = App::karr::Foundation->new;
  my $pat = $f->_error_patterns( {} );

  for my $entry ( @$pat ) {
    my ( $name, $triggers, $re ) = @$entry;
    ok scalar @$triggers, "'$name' carries at least one trigger";
    is scalar( grep { $_ ne lc $_ } @$triggers ), 0,
      "'$name' triggers are lowercase (index() is not case-insensitive)";
    for my $case ( @GENUINE ) {
      my $text = $case->[1];
      next unless $text =~ $re;    # this pattern claims that string
      ok scalar( grep { index( lc $text, $_ ) >= 0 } @$triggers ),
        "'$name' triggers on a string its own regex matches: $text";
    }
  }
};

subtest 'custom error_patterns stay literal substrings' => sub {
  my $f  = App::karr::Foundation->new;
  my $cp = $f->_error_patterns( { error_patterns => [ 'my custom api error' ] } );
  is $f->_match_error( "blah MY CUSTOM API ERROR blah", $cp ), 'my custom api error',
    'a board-configured pattern matches as written, case-insensitively';
  is $f->_match_error( "nothing to see here\n", $cp ), undef, 'and only where it occurs';
};

# ---------------------------------------------------------------------------
# Ordering: what the run did outranks what it printed
# ---------------------------------------------------------------------------

subtest 'a chatty healthy board drains and never cools down' => sub {
  my $repo = make_git_repo();
  seed_board( $repo,
    'retry the network fetch on 503', 'tidy the parser', 'update the docs' );
  my $agent = write_fake_agent( $repo );
  $repo->child('.karr')->spew_utf8( "command: $agent\nmax_runtime: 60\n" );

  my $f = App::karr::Foundation->new( _config_data => {}, force => 1 );
  local $ENV{KARR_FAKE_MODE} = 'chatty';
  $f->_process_repo( $repo );

  my $log = log_of( $repo );
  like $log, qr/retry the network fetch on 503/,
    'the agent really printed the backlog line that used to trip the scan';
  like $log, qr/\Q| 403 ++++\E/,
    'and the diffstat that used to trip it on 403';
  unlike $log, qr/COMMON-ERROR/, 'neither was classified as a common error';

  is scalar( grep { $_->status ne 'done' } tasks_of( $repo ) ), 0,
    'the whole board drained in this one run';

  my $state = state_data( $repo );
  ok ! $state->{cooldown_level}, 'no cooldown level was raised';
  ok ! $state->{cooldown_until}, 'and no cooldown is pending';
  ok ! exists $state->{last_error}, 'nothing was recorded as the last error';
};

subtest 'progress outranks an error the same run reported' => sub {
  my $repo = make_git_repo();
  seed_board( $repo, 'tidy the parser', 'update the docs' );
  my $agent = write_fake_agent( $repo );

  my $f = App::karr::Foundation->new( _config_data => {} );
  local $ENV{KARR_FAKE_MODE} = 'limited-progress';
  my $res = $f->_drain_repo( $repo,
    { command => $agent, max_runtime => 60, max_iterations => 3 } );

  is $res->{outcome}, 'progress',
    'a run that moved a card is progress even though it printed a real 429';
  like log_of( $repo ), qr/NOTE 'rate limit' in output, but the board moved/,
    'the suppressed match is still told to the operator';
  unlike log_of( $repo ), qr/COMMON-ERROR rate limit/,
    'but it is not charged as a common error';
  ok ! exists state_data( $repo )->{last_error},
    'and no last_error is left behind for it';
};

# ---------------------------------------------------------------------------
# The other half: a genuine failure must still back off
# ---------------------------------------------------------------------------

subtest 'a real rate limit with nothing moved is still a common error' => sub {
  my $repo = make_git_repo();
  seed_board( $repo, 'tidy the parser' );
  my $agent = write_fake_agent( $repo );

  my $f = App::karr::Foundation->new( _config_data => {} );
  local $ENV{KARR_FAKE_MODE} = 'limited';
  my $res = $f->_drain_repo( $repo, { command => $agent, max_runtime => 60 } );

  is $res->{outcome}, 'common-error', 'outcome common-error';
  is $res->{exit}, 0, 'even though the agent exited 0';
  is state_data( $repo )->{last_error}, 'rate limit', 'last_error recorded';
  like log_of( $repo ), qr/COMMON-ERROR rate limit \x{2014} agent exited 0, run discarded/,
    'the log says why an exit-0 run did not count';
  ok ! ( grep { $_->has_blocked } tasks_of( $repo ) ), 'no task penalized for it';
};

subtest 'the cooldown grows on a real error and resets after a good run' => sub {
  my $repo = make_git_repo();
  seed_board( $repo, 'tidy the parser', 'update the docs' );
  my $agent = write_fake_agent( $repo );
  $repo->child('.karr')->spew_utf8(
    "command: $agent\nmax_runtime: 60\ncooldown_base: 1\ncooldown_max: 8\n" );

  my $flag = $repo->child('RATE-LIMITED');
  $flag->spew_utf8('1');
  local $ENV{KARR_FAKE_MODE} = 'flagged';
  local $ENV{KARR_FAKE_FLAG} = "$flag";

  my $f = App::karr::Foundation->new( _config_data => {}, force => 1 );

  $f->_process_repo( $repo );
  is state_data( $repo )->{cooldown_level}, 1, 'first failure => level 1';
  is state_data( $repo )->{last_error}, 'rate limit', 'and last_error names it';
  ok $f->_cooldown_active( $repo ), 'the board is now in cooldown';

  # The one place a human looks at a parked board says why it is parked.
  my $out = '';
  {
    local *STDOUT;
    open STDOUT, '>', \$out or die $!;
    $f->_print_overview( [ $repo ] );
  }
  like $out, qr/cooldown \d+s \(rate limit\)/,
    'the overview names the error that parked the board, not just the wait';

  # A second failing run once that cooldown has expired (no waiting: the
  # deadline is state, so move it into the past).
  $f->_state_set( $repo, cooldown_until => 1 );
  $f->_process_repo( $repo );
  is state_data( $repo )->{cooldown_level}, 2, 'second failure => level 2';

  # Rate limit lifted.
  $flag->remove;
  $f->_state_set( $repo, cooldown_until => 1 );
  $f->_process_repo( $repo );

  my $state = state_data( $repo );
  is $state->{cooldown_level}, 0, 'a good run resets the level to 0';
  is $state->{cooldown_until}, 0, 'and clears the pending cooldown';
  ok ! exists $state->{last_error},
    'the stale last_error is gone, so last_exit: 0 no longer contradicts it';
  is scalar( grep { $_->status ne 'done' } tasks_of( $repo ) ), 0,
    'and the board drained once the agent could work again';
};

done_testing;
