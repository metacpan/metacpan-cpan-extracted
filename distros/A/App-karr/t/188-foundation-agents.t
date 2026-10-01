use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestGit qw( require_git_c );
require_git_c();
use Path::Tiny qw( path tempdir );
use YAML::XS ();

use App::karr::Foundation;
use App::karr::Foundation::Agents;
use App::karr::Git;
use App::karr::BoardStore;
use App::karr::Task;
use App::karr::Encoding qw( json_decode json_encode );

# Ticket #188: named agent definitions in the LOCAL config, the claude-code
# invocation contract, and per-agent availability.
#
# Three things are pinned here, and each of them is a decision that could have
# gone another way:
#
#   1. Definitions are local. An agent command that exists on this machine does
#      not exist on the next, and a spent account limit belongs to a person,
#      not to a project -- so nothing about agents goes near refs/karr/*.
#   2. `kind: claude-code` is the whole invocation contract: which arguments
#      karr appends, and (through --output-format) how the result is read. The
#      reader landed with #187; this wires it up, and it does so with
#      stream-json rather than json, because plain json prints nothing until
#      the run ends and would silently cancel the live output foundation
#      promises for a TTY.
#   3. Availability is ok / failing since X / next attempt at Y and nothing
#      else -- no cost, no tokens, no quotas -- and it is shared by every board
#      that uses the agent, because "the command stopped working" is a fact
#      about the command, not about a repository.
#
# Everything runs against throwaway repositories and a fake agent that is a
# perl script printing canned text. No real agent is ever started.

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
    # todo, not backlog: the board has to hold open work, and backlog is held
    # back and not actionable (ticket k306).
    $store->save_task( App::karr::Task->new(
      id => $id, status => 'todo', title => $title ) );
  }
}

sub tasks_of {
  return App::karr::BoardStore->new(
    git => App::karr::Git->new( dir => "$_[0]" ) )->load_tasks;
}

sub log_of {
  my $file = path( $_[0] )->child('.karr.log');
  return $file->exists ? $file->slurp_utf8 : '';
}

# A config directory of this test's own. Every Foundation built here points at
# it, so the per-machine agents.state can never be the developer's real one.
# STDOUT capture through a real file, not an in-memory scalar. The runner
# forks and dups the child's stdout onto a pipe; a scalar filehandle has no
# file descriptor to dup onto, so the agent's output escapes to the real
# terminal and the capture comes back empty.
sub capture_stdout {
  my ( $code ) = @_;
  my $file = Path::Tiny->tempfile;
  open my $save, '>&', \*STDOUT or die "dup stdout: $!";
  open STDOUT, '>', "$file"      or die "redirect stdout: $!";
  my $err;
  eval { $code->(); 1 } or $err = $@;
  open STDOUT, '>&', $save or die "restore stdout: $!";
  close $save;
  die $err if defined $err;
  return $file->slurp_utf8;
}

my @KEEP_TMP;   # Path::Tiny tempdirs vanish with their object; hold them
sub write_config {
  my ( %data ) = @_;
  my $dir = tempdir( CLEANUP => 1 );
  push @KEEP_TMP, $dir;
  my $file = $dir->child('config.yml');
  $file->spew_utf8( YAML::XS::Dump( \%data ) );
  return $file;
}

sub foundation {
  my ( $cfg, %args ) = @_;
  return App::karr::Foundation->new( config => "$cfg", %args );
}

# App::karr::Foundation::Agents holds its foundation weakly, exactly as the
# other three collaborators do, so a test that only kept the Agents object
# would watch its back-reference evaporate. Keep the foundation alive.
my @KEEP_ALIVE;
sub agents {
  my ( $cfg, %args ) = @_;
  my $f = foundation( $cfg, %args );
  push @KEEP_ALIVE, $f;
  return $f->_agents;
}

sub agents_state {
  my ( $cfg ) = @_;
  my $file = path( $cfg )->sibling('agents.state');
  return $file->exists ? json_decode( $file->slurp_utf8 ) : undef;
}

sub set_agents_state {
  my ( $cfg, $data ) = @_;
  path( $cfg )->sibling('agents.state')->spew_utf8( json_encode( $data ) );
}

# The fake agent. It ignores its arguments entirely -- which is exactly what
# makes it usable behind `kind: claude-code`, where karr appends a flag set the
# script has no opinion about -- prints the file it is pointed at, optionally
# moves one card, and records that it ran.
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

my $repo    = $ENV{KARR_REPO} or die "no KARR_REPO\n";
my $flag    = $ENV{KARR_FAKE_FLAG} // '';
my $failing = ( length $flag && -e $flag ) ? 1 : 0;

if ( my $runs = $ENV{KARR_FAKE_RUNS} ) {
  open my $fh, '>>', $runs or die $!;
  print {$fh} "run\n";
  close $fh;
}

if ( !$failing && $ENV{KARR_FAKE_MOVE} ) {
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

my $out = $failing ? ( $ENV{KARR_FAKE_OUT_FAIL} // '' )
                   : ( $ENV{KARR_FAKE_OUT}      // '' );
if ( length $out && -e $out ) {
  open my $fh, '<', $out or die $!;
  local $/;
  print <$fh>;
  close $fh;
}
exit( $failing ? ( $ENV{KARR_FAKE_EXIT_FAIL} // 0 ) : 0 );
PERL
  return qq{$^X -I"$lib" "$script"};
}

# One line of `claude -p --output-format stream-json --include-partial-messages`
# as it really arrives: a text delta wrapped in a stream_event envelope.
sub delta {
  my ( $text ) = @_;
  return json_encode( {
    type  => 'stream_event',
    event => { type => 'content_block_delta',
               delta => { type => 'text_delta', text => $text } },
  } );
}

sub result_json {
  my ( %over ) = @_;
  return json_encode( {
    type             => 'result',
    subtype          => 'success',
    is_error         => \0,
    num_turns        => 3,
    duration_ms      => 1200,
    total_cost_usd   => 0.01,
    session_id       => 'abc',
    api_error_status => undef,
    %over,
  } );
}

# ---------------------------------------------------------------------------
# Definitions live in the local config, and are read strictly
# ---------------------------------------------------------------------------

subtest 'agent definitions are read from the local config' => sub {
  my $cfg = write_config( agents => {
    minimax => {
      command     => 'claude_with_minimax',
      kind        => 'claude-code',
      probe_every => '15m',
      description => "Cheap and fast.\nWeak on long refactors.\n",
    },
    scripted => { command => 'run-agent --board "$KARR_REPO"' },
  } );
  my $a = agents( $cfg );

  is_deeply [ $a->names ], [qw( minimax scripted )], 'both agents are known';
  is $a->definition('minimax')->{kind}, 'claude-code', 'the kind is kept';
  is $a->definition('scripted')->{kind}, 'shell',
    'a definition that names no kind is a plain shell template, because karr '
    . 'has no idea what the thing at the other end understands';
  like $a->definition('minimax')->{description}, qr/Weak on long refactors/,
    'the prose description survives verbatim -- it is the selection criterion, '
    . 'not a field karr ever branches on';
  is $a->probe_seconds('minimax'), 900, '15m is fifteen minutes';
  is $a->probe_seconds('scripted'),
     $App::karr::Foundation::Agents::DEFAULT_PROBE_SECONDS,
    'an agent whose reset rhythm nobody knows gets the fixed interval';
};

subtest 'probe_every accepts the durations a config writes' => sub {
  for my $case ( [ 45 => 45 ], [ '90s' => 90 ], [ '15m' => 900 ],
                 [ '2h' => 7200 ], [ '1d' => 86400 ] ) {
    my ( $written, $seconds ) = @$case;
    my $cfg = write_config( agents => { x => { command => 'c', probe_every => $written } } );
    is agents( $cfg )->probe_seconds('x'), $seconds, "probe_every: $written";
  }

  my $bad = write_config( agents => { x => { command => 'c', probe_every => '15min' } } );
  my $err = do { local $@; eval { agents( $bad )->probe_seconds('x') }; $@ };
  like $err, qr/cannot read '15min' as a duration/,
    'a duration karr cannot read is a config error, never a quiet default';
};

subtest 'a definition karr cannot use is refused, not guessed at' => sub {
  my $no_cmd = write_config( agents => { x => { kind => 'claude-code' } } );
  like do { local $@; eval { agents( $no_cmd )->names }; $@ },
    qr/Agent 'x' has no command/, 'an agent without a command';

  my $bad_kind = write_config( agents => { x => { command => 'c', kind => 'sorcery' } } );
  like do { local $@; eval { agents( $bad_kind )->names }; $@ },
    qr/unknown kind 'sorcery'/, 'an invocation contract karr does not know';

  my $not_map = write_config( agents => [ 'minimax' ] );
  like do { local $@; eval { agents( $not_map )->names }; $@ },
    qr/must be a mapping/, 'an agents: section that is not a mapping';

  my $unknown = write_config( agents => { x => { command => 'c', descripton => 'typo' } } );
  my @warned;
  {
    local $SIG{__WARN__} = sub { push @warned, $_[0] };
    agents( $unknown )->names;
  }
  like "@warned", qr/unknown key\(s\): descripton/,
    'a misspelled key is said out loud: it is the one thing here with no '
    . 'other feedback loop';
};

# ---------------------------------------------------------------------------
# kind: claude-code -- the invocation contract
# ---------------------------------------------------------------------------

subtest 'kind: claude-code appends the contract, and nothing else does' => sub {
  my $cfg = write_config( agents => {
    plain  => { command => 'claude_with_minimax', kind => 'claude-code' },
    shelly => { command => 'run-agent --board x' },
  } );
  my $a = agents( $cfg );

  my $inv = $a->invocation('plain');
  is $inv->{name}, 'plain', 'the invocation carries the name it was found under';
  is $inv->{command},
     'claude_with_minimax -p "$PROMPT" --output-format stream-json --verbose '
     . '--include-partial-messages --permission-mode bypassPermissions --max-turns 30',
    'the contract: -p, a structured output format, the permission mode, the turn cap';
  is $inv->{render}, 'stream-json',
    'and the runner is told to render that stream, because plain json would '
    . 'print nothing at all until the run ended';

  my $shell = $a->invocation('shelly');
  is $shell->{command}, 'run-agent --board x',
    'a shell agent is run exactly as written -- karr appends nothing it cannot '
    . 'know the other end understands';
  is $shell->{render}, undef, 'and its output is passed through untouched';
};

subtest 'the claude-code knobs, and the quoting of what came out of a config' => sub {
  my $cfg = write_config( agents => {
    picky => {
      command         => 'claude',
      kind            => 'claude-code',
      permission_mode => 'plan',
      max_turns       => 5,
      allowed_tools   => [ 'Bash', 'Edit' ],
    },
    loose  => { command => 'claude', kind => 'claude-code', max_turns => 0 },
    spacey => { command => 'claude', kind => 'claude-code',
                allowed_tools => 'Bash(git log:*)' },
  } );
  my $a = agents( $cfg );

  my $picky = $a->invocation('picky')->{command};
  like $picky, qr/--permission-mode plan/,     'permission_mode is passed through';
  like $picky, qr/--max-turns 5/,              'so is max_turns';
  like $picky, qr/--allowed-tools Bash,Edit/,  'and the allowed tool list';

  unlike $a->invocation('loose')->{command}, qr/--max-turns/,
    'max_turns: 0 drops the flag, the same "no limit" spelling max_runtime uses';

  like $a->invocation('spacey')->{command},
    qr/\Q--allowed-tools 'Bash(git log:*)'\E/,
    'a value with shell metacharacters in it is quoted, so it stays one '
    . 'argument instead of becoming three';
};

# ---------------------------------------------------------------------------
# Resolution: where a named agent sits, and what it must not disturb
# ---------------------------------------------------------------------------

subtest 'a board picks an agent by name, and the literal commands still win' => sub {
  my $cfg = write_config(
    agents => { fast => { command => 'fast-agent' },
                slow => { command => 'slow-agent' } },
    default_agent => 'slow',
  );
  my $repo = path( tempdir( CLEANUP => 1 ) );
  my $f = foundation( $cfg );

  my ( $cmd, $inv ) = $f->_resolve_agent( $repo, { agent => 'fast' } );
  is $cmd, 'fast-agent', ".karr 'agent:' resolves to that agent's command";
  is $inv->{name}, 'fast', 'and the run knows which agent it is running';

  ( $cmd, $inv ) = $f->_resolve_agent( $repo, {} );
  is $cmd, 'slow-agent', 'config default_agent applies to a board that names none';
  is $inv->{name}, 'slow', 'still a named agent';

  ( $cmd, $inv ) = $f->_resolve_agent( $repo, { agent => 'fast', command => 'literal' } );
  is $cmd, 'literal',
    "a board's own 'command:' is the most specific thing it can say and still wins";
  is $inv, undef,
    'and it resolves to no named agent, so nothing is recorded against one';

  ( $cmd, $inv ) = foundation( $cfg, command => 'cli' )->_resolve_agent( $repo, { agent => 'fast' } );
  is $cmd, 'cli',   '--command still beats everything';
  is $inv, undef,   'and is nobody in particular';

  ( $cmd, $inv ) = $f->_resolve_agent( $repo, { agent => 'fast', claude => 1 } );
  is $cmd, 'fast-agent',
    "a named agent beats 'claude: true', which is the oldest and vaguest of these";
};

subtest 'a board that names no agent is untouched by any of this' => sub {
  my $cfg = write_config( agents => { fast => { command => 'fast-agent' } } );
  my $repo = path( tempdir( CLEANUP => 1 ) );
  my $f = foundation( $cfg );

  my ( $cmd, $inv ) = $f->_resolve_agent( $repo, {} );
  is $cmd, undef, 'no agent configured is still no agent configured';

  ( $cmd, $inv ) = $f->_resolve_agent( $repo, { claude => 1 } );
  is $cmd, 'claude -p "$PROMPT" --permission-mode bypassPermissions --max-turns 30',
    "'claude: true' synthesizes exactly the command it always did -- adding "
    . '--output-format to it is what kind: claude-code is for';
  is $inv, undef, 'and it is not a named agent';
};

subtest 'a board naming an agent that is not defined says so' => sub {
  my $cfg  = write_config( agents => { fast => { command => 'fast-agent' } } );
  my $repo = path( tempdir( CLEANUP => 1 ) );
  my $err  = do {
    local $@;
    eval { foundation( $cfg )->_resolve_agent( $repo, { agent => 'fst' } ) };
    $@;
  };
  like $err, qr/No agent named 'fst' is defined \(known: fast\)/,
    'a typo is an error that skips the board, not a board that quietly stops '
    . 'running forever';
};

# ---------------------------------------------------------------------------
# Live output: the streaming trap
# ---------------------------------------------------------------------------

subtest 'a claude-code stream is rendered, not dumped as JSON' => sub {
  my $repo  = make_git_repo();
  seed_board( $repo, 'tidy the parser' );
  my $agent = write_fake_agent( $repo );
  my $cfg   = write_config( agents => {
    fake => { command => $agent, kind => 'claude-code' } } );

  my $out_file = path( $repo )->child('stream.txt');
  $out_file->spew_utf8( join "\n",
    qq({"type":"system","subtype":"init","tools":[]}),
    'a wrapper warning on the shared pipe',
    delta('Picked up '), delta('task 1.'),
    result_json(),
  );

  local $ENV{KARR_FAKE_OUT}  = "$out_file";
  local $ENV{KARR_FAKE_MOVE} = 1;

  my $f = foundation( $cfg, verbose => 1 );
  my ( $cmd, $inv ) = $f->_resolve_agent( path($repo), { agent => 'fake' } );

  my $res;
  my $shown = capture_stdout( sub {
    $res = $f->_drain_repo( path($repo),
      { max_runtime => 60, max_iterations => 1 }, $cmd, $inv );
  } );

  like $shown, qr/Picked up task 1\./,
    'the assistant text reaches the terminal as it is produced -- the live '
    . 'output foundation promises for a TTY survives the contract';
  like $shown, qr/a wrapper warning on the shared pipe/,
    'and a line that is not JSON at all is passed through, because the pipe '
    . 'is shared with the command stderr';
  unlike $shown, qr/stream_event|content_block_delta/,
    'the envelopes are machinery and stay out of a human being s way';
  unlike $shown, qr/"type":"result"/, 'so does the result object';

  my $log = log_of( $repo );
  like $log, qr/Picked up task 1\./, '.karr.log keeps the readable half too';
  unlike $log, qr/stream_event/,
    'rather than filling with a megabyte of JSON nobody can grep';
  like $log, qr/START agent=fake command=/,
    'and the START line names which agent ran';

  is $res->{outcome}, 'progress',
    'the run was still classified from the result object at the tail of the '
    . 'raw stream (#187), which rendering must not consume';
  like $log, qr/RESULT success/, 'and the report was read';
};

subtest 'a board with no agent definition streams exactly as it always did' => sub {
  my $repo  = make_git_repo();
  seed_board( $repo, 'tidy the parser' );
  my $agent = write_fake_agent( $repo );
  my $cfg   = write_config();

  my $out_file = path( $repo )->child('stream.txt');
  $out_file->spew_utf8( delta('hello') . "\n" );
  local $ENV{KARR_FAKE_OUT} = "$out_file";

  my $f = foundation( $cfg, verbose => 1 );
  my $shown = capture_stdout( sub {
    $f->_run_command( path($repo), { max_runtime => 60 }, $agent );
  } );
  like $shown, qr/stream_event/,
    'without an agent definition the octets the command printed go through '
    . 'untouched -- rendering is the contract is, not a sniffer';
  like log_of( $repo ), qr/^\[[^\]]+\] \d+: START command=/m,
    'and the START line is the one it always was';
  is agents_state( $cfg ), undef, 'no availability is recorded for nobody';
};

# ---------------------------------------------------------------------------
# Availability
# ---------------------------------------------------------------------------

subtest 'an agent that stopped working is recorded, and shared across boards' => sub {
  my $repo_a = make_git_repo();
  my $repo_b = make_git_repo();
  seed_board( $_, 'tidy the parser', 'update the docs' ) for $repo_a, $repo_b;
  my $agent  = write_fake_agent( $repo_a );
  my $cfg    = write_config( agents => {
    fake => { command => $agent, probe_every => '15m' } } );

  for my $r ( $repo_a, $repo_b ) {
    path($r)->child('.karr')->spew_utf8( "agent: fake\nmax_runtime: 60\n" );
  }

  my $fail_out = path( $repo_a )->child('fail.txt');
  $fail_out->spew_utf8(
    qq(API Error: 429 {"type":"error","error":{"type":"rate_limit_error"}}\n) );
  my $ok_out = path( $repo_a )->child('ok.txt');
  $ok_out->spew_utf8( "working\n" );

  my $flag = path( $repo_a )->child('RATE-LIMITED');
  $flag->spew_utf8('1');
  my $runs = path( $repo_a )->child('runs.txt');

  local $ENV{KARR_FAKE_FLAG}     = "$flag";
  local $ENV{KARR_FAKE_OUT}      = "$ok_out";
  local $ENV{KARR_FAKE_OUT_FAIL} = "$fail_out";
  local $ENV{KARR_FAKE_MOVE}     = 1;
  local $ENV{KARR_FAKE_RUNS}     = "$runs";

  my $f = foundation( $cfg, force => 1 );

  $f->_process_repo( path($repo_a) );
  my $state = agents_state( $cfg );
  is $state->{fake}{state}, 'failing', 'the agent is marked failing';
  ok $state->{fake}{failing_since}, 'with the moment the outage started';
  is $state->{fake}{last_error}, 'rate limit',
    'and what it looked like from the outside -- no cost, no tokens, no quota';
  cmp_ok $state->{fake}{next_attempt}, '>', time + 800,
    'the next attempt is a probe_every away, because this config knows the rhythm';

  my $after_a = $runs->exists ? $runs->slurp_utf8 : '';
  is scalar( () = $after_a =~ /run/g ), 1, 'repo A ran the agent once';

  # The whole point: repo B has never failed and is not in cooldown, but the
  # agent it wants is the one that just stopped working.
  $f->_process_repo( path($repo_b) );
  my $after_b = $runs->exists ? $runs->slurp_utf8 : '';
  is $after_b, $after_a,
    'the second board did not start the agent at all: two repos on one agent '
    . 'share the outage instead of each burning a window discovering it';
  ok !grep( { $_->status eq 'done' } tasks_of( $repo_b ) ),
    'so nothing on it moved';

  ok $f->_cooldown_active( path($repo_a) ),
    'the per-board cooldown is still its own mechanism, one level down';

  # Time passes: the probe comes round. Nothing else changes -- the rate limit
  # is still on -- so the probe fails and the next attempt moves out again.
  set_agents_state( $cfg, { fake => { %{ $state->{fake} }, next_attempt => 1 } } );
  $f->_state_set( path($repo_b), cooldown_until => 1 );
  $f->_process_repo( path($repo_b) );
  is scalar( () = $runs->slurp_utf8 =~ /run/g ), 2,
    'when the next attempt comes round the agent is simply run again: the '
    . 'probe is the work, not a separate kind of run';
  my $again = agents_state( $cfg );
  is $again->{fake}{failing_since}, $state->{fake}{failing_since},
    'a failed probe does not restart the clock -- "failing since 09:12" is '
    . 'what a coordinator asks for, not "failing since just now"';
  cmp_ok $again->{fake}{next_attempt}, '>', time + 800, 'but it does move the next attempt';

  # The limit lifts.
  $flag->remove;
  set_agents_state( $cfg, { fake => { %{ $again->{fake} }, next_attempt => 1 } } );
  $f->_state_set( path($repo_b), cooldown_until => 1 );
  $f->_process_repo( path($repo_b) );

  my $back = agents_state( $cfg );
  is $back->{fake}{state}, 'ok', 'a run that was not a common error ends the outage';
  ok !exists $back->{fake}{next_attempt}, 'and there is nothing left to wait for';
  is scalar @{ $back->{fake}{recovered} }, 1, 'the recovery is recorded';
  my $rec = $back->{fake}{recovered}[0];
  is $rec->{failing_since}, $state->{fake}{failing_since}, 'from when it broke';
  ok $rec->{recovered_at} >= $rec->{failing_since},
    'to when it worked again -- which is the trail a coordination agent reads '
    . 'a rhythm out of, instead of karr learning one';
  is $rec->{error}, 'rate limit', 'carrying what the outage looked like';
};

subtest 'availability is machine-local: beside the config, never in the repo' => sub {
  my $repo  = make_git_repo();
  seed_board( $repo, 'tidy the parser' );
  my $agent = write_fake_agent( $repo );
  my $cfg   = write_config( agents => { fake => { command => $agent } } );
  path($repo)->child('.karr')->spew_utf8( "agent: fake\nmax_runtime: 60\n" );

  my $fail = path( $repo )->child('fail.txt');
  $fail->spew_utf8(
    qq(API Error: 429 {"type":"error","error":{"type":"rate_limit_error"}}\n) );
  my $flag = path( $repo )->child('RATE-LIMITED');
  $flag->spew_utf8('1');
  local $ENV{KARR_FAKE_FLAG}     = "$flag";
  local $ENV{KARR_FAKE_OUT_FAIL} = "$fail";

  foundation( $cfg, force => 1 )->_process_repo( path($repo) );

  ok path( $cfg )->sibling('agents.state')->exists,
    'the record sits beside the config that defines the agents, so --config '
    . 'relocates it and a second fleet cannot write over the first';

  my $board_state = json_decode( path($repo)->child('.karr.state')->slurp_utf8 );
  ok !grep( { /agent/i } keys %$board_state ),
    '.karr.state carries nothing about the agent: it is per repository, and '
    . 'availability is not';

  my $git = App::karr::Git->new( dir => "$repo" );
  my $refs = $git->ref_oids('refs/karr/') // {};
  ok !grep( { /agent|foundation/ } keys %$refs ),
    'and nothing was pushed into the board, which would sync an outage that '
    . 'belongs to this machine to everybody else';
};

subtest 'a spent turn budget is not an outage' => sub {
  my $repo  = make_git_repo();
  seed_board( $repo, 'tidy the parser', 'update the docs' );
  my $agent = write_fake_agent( $repo );
  my $cfg   = write_config( agents => {
    fake => { command => $agent, kind => 'claude-code' } } );
  path($repo)->child('.karr')->spew_utf8( "agent: fake\nmax_runtime: 60\n" );

  my $out = path( $repo )->child('stream.txt');
  $out->spew_utf8( join "\n",
    delta('half done'),
    result_json( is_error => \1, subtype => 'error_max_turns',
                 terminal_reason => 'max_turns' ) );
  local $ENV{KARR_FAKE_OUT}  = "$out";
  local $ENV{KARR_FAKE_MOVE} = 1;

  foundation( $cfg, force => 1 )->_process_repo( path($repo) );

  is agents_state( $cfg ), undef,
    'the agent worked and the provider answered -- the task was just bigger '
    . 'than the budget, so nothing about availability changed (#187)';
};

subtest 'an agent that never failed is never written down' => sub {
  my $repo  = make_git_repo();
  seed_board( $repo, 'tidy the parser' );
  my $agent = write_fake_agent( $repo );
  my $cfg   = write_config( agents => { fake => { command => $agent } } );
  path($repo)->child('.karr')->spew_utf8( "agent: fake\nmax_runtime: 60\n" );
  local $ENV{KARR_FAKE_MOVE} = 1;

  foundation( $cfg, force => 1 )->_process_repo( path($repo) );
  is agents_state( $cfg ), undef,
    'an ordinary good run rewrites nothing: the file holds outages, not a '
    . 'heartbeat';
};

# ---------------------------------------------------------------------------
# What a human sees
# ---------------------------------------------------------------------------

subtest 'the overview says which agent, and whether it works' => sub {
  my $repo = make_git_repo();
  seed_board( $repo, 'tidy the parser' );
  my $cfg  = write_config( agents => {
    fake => { command => 'fake-agent', kind => 'claude-code',
              description => 'Cheap. Bad at long refactors.' },
    idle => { command => 'other-agent' },
  } );
  path($repo)->child('.karr')->spew_utf8("agent: fake\n");

  my $when = time - 300;
  set_agents_state( $cfg, { fake => {
    state => 'failing', failing_since => $when,
    next_attempt => $when + 900, last_error => 'api 429' } } );

  my $f = foundation( $cfg );
  my $out = capture_stdout( sub { $f->_print_overview( [ path($repo) ] ) } );
  like $out, qr/\[agent:fake failing\]/,
    'the board flag names its agent and says it is not currently working';
  like $out, qr/^Agents$/m, 'and there is one block for the agents themselves';
  like $out, qr/fake\s+failing since \S+, next attempt at \S+ \(api 429\)/,
    'ok / failing since X / next attempt at Y, and nothing else';
  like $out, qr/idle\s+ok/, 'an agent nobody has had trouble with is ok';
  unlike $out, qr/Bad at long refactors/,
    'the prose stays out of the default view: it is for the router, not the '
    . 'dashboard';

  my $fv = foundation( $cfg, verbose => 1 );
  my $verbose = capture_stdout( sub { $fv->_print_overview( [ path($repo) ] ) } );
  like $verbose, qr/kind: claude-code/, '--verbose shows the invocation contract';
  like $verbose, qr/Bad at long refactors/, 'and the description that routes work';
};

subtest 'the overview survives a board naming an agent that is gone' => sub {
  my $repo = make_git_repo();
  seed_board( $repo, 'tidy the parser' );
  my $cfg  = write_config( agents => { fake => { command => 'fake-agent' } } );
  path($repo)->child('.karr')->spew_utf8("agent: retired\n");

  my $fo = foundation( $cfg );
  my $out = capture_stdout( sub { $fo->_print_overview( [ path($repo) ] ) } );
  like $out, qr/\[agent-error\]/, 'the board is flagged rather than skipped';
  like $out, qr/agent-error: No agent named 'retired'/,
    'and the read-only view says what is wrong instead of dying on the operator';
};

done_testing;
