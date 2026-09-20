# ABSTRACT: Single-shot foundation daemon -- periodic agent execution across karr boards

package App::karr::Foundation;
our $VERSION = '0.601';
use Moo;
use MooX::Options (
  usage_string => 'USAGE: karr-foundation [ask QUESTION | answer ID ANSWER | chain | plan] [options]',
  # The mailbox commands (#191) are positional, and MooX::Options hands the
  # leftovers back in @ARGV only when it is allowed to consume the options out
  # of it. Nothing else in this class reads @ARGV, and F<bin/karr-foundation>
  # passes what is left to run().
  protect_argv => 0,
);
use App::karr::Error qw( user_error clean_error );
use App::karr::Encoding qw( from_octets yaml_load );
use App::karr::Role::ExitCodes;
use Path::Tiny;
use IO::Handle;
use POSIX qw( SIGTERM SIGINT SIGHUP WNOHANG );
use YAML::XS ();
use Time::Piece;
use Digest::MD5 qw( md5_hex );
use Try::Tiny;
use App::karr::Git;
use App::karr::BoardStore;
use App::karr::ActivityLog;
use App::karr::Foundation::Runner;
use App::karr::Foundation::State;
use App::karr::Foundation::Overview;
use App::karr::Foundation::Picker;
use App::karr::Foundation::Agents;
use App::karr::Foundation::ChainStore;
use App::karr::Foundation::Executor;
use App::karr::Foundation::Questions;
use App::karr::Foundation::Coordinator;
use App::karr::Foundation::Limits;

# An unknown option or an option value that does not parse exits 2, not 1
# (ADR 0002 exit-code contract). MooX::Options otherwise hands that failure a
# 1, which is the code a genuine runtime failure of a drain carries, and the
# central handler in F<bin/karr-foundation> never sees those exits at all.
with 'App::karr::Role::ExitCodes';

# An option name with a dash in it does not survive standing behind a boolean
# flag -- MooX::Options re-emits the token after a recognised option verbatim,
# so `karr-foundation --verbose --dry-run` reached Getopt::Long under a name
# the specification does not have (ticket #256). F<bin/karr> routes around it
# for every command class; this binary needs the same walk for the same
# reason, and `dry_run` -- the spelling the SYNOPSIS itself uses -- is the
# option it applies to here.
with 'App::karr::Role::CliArgs';

# Instruction handed to a synthesized agent command via the $PROMPT variable
# when neither the .karr file nor the config overrides it.
our $DEFAULT_PROMPT =
    'Use the karr-coordinator skill: pick the next actionable task on this '
  . 'board, complete it, and move it forward. If you cannot proceed, block '
  . 'the task with a reason.';

# The same, for a ticket-mode run. It cannot be $DEFAULT_PROMPT: that one opens
# by telling the agent to pick its own work, which is the one thing a run that
# has already been given a card must not do.
our $DEFAULT_TICKET_PROMPT =
    'Use the karr-coordinator skill: work on the one task named below, '
  . 'complete it, and move it forward. If you cannot proceed, block the task '
  . 'with a reason.';

# Appended to whatever prompt was resolved, ticket id spliced in by foundation
# itself. It has to be foundation that splices: the prompt reaches the agent as
# $PROMPT and /bin/sh does not rescan an expanded value, so a prompt writing
# $KARR_TASK would hand the agent those ten characters (#159). Last, not first,
# because it has to win over an operator prompt that says "pick the next task".
our $TICKET_ASSIGNMENT =
    'The task for this run is #%s: work on that one task and no other. Claim '
  . 'it before you start, and stop when it is done, handed off or blocked. Do '
  . 'not pick up another task.';

option config => (
  is     => 'ro',
  format => 's',
  doc    => 'Path to config file (default: ~/.config/karr-foundation/config.yml)',
);

option command => (
  is     => 'ro',
  format => 's',
  doc    => 'Global agent command; overrides .karr file per-repo',
);

option force => (
  is  => 'ro',
  doc => 'Run agent even if no board change detected and no open tasks; '
       . 'answer: replace an answer that is already there; plan: replace a '
       . 'chain that still has a step running',
);

option dry_run => (
  is  => 'ro',
  doc => 'Print what would run without executing; plan: check a chain and '
       . 'write nothing',
);

option verbose => (
  is  => 'ro',
  doc => 'Extra output',
);

option status => (
  is  => 'ro',
  doc => 'Print a read-only overview of every board and exit (no agent runs)',
);

# The question mailbox (#191). These belong to the `ask` and `answer` commands
# and are ignored by a drain, which is why their doc strings say which command
# reads them: this CLI has no per-command option namespace and inventing one
# for two commands would cost more than the prefix in the help text.
option context => (
  is     => 'ro',
  format => 's',
  doc    => 'ask: prose context for the question',
);

option options => (
  is     => 'ro',
  format => 's',
  doc    => 'ask: comma-separated answers the question offers',
);

option default => (
  is     => 'ro',
  format => 's',
  doc    => 'ask: the answer to fall back on (needs --policy use_default)',
);

option policy => (
  is     => 'ro',
  format => 's',
  doc    => 'ask: what happens when nobody answers: block (default), '
          . 'use_default, escalate_to_ai',
);

option wait => (
  is     => 'ro',
  format => 'i',
  doc    => 'ask: seconds before the policy takes over',
);

option step => (
  is     => 'ro',
  format => 's',
  doc    => 'ask: the chain step waiting on the answer',
);

option note => (
  is     => 'ro',
  format => 's',
  doc    => 'answer: a note to record beside the answer',
);

option input => (
  is     => 'ro',
  format => 's',
  doc    => 'plan: read the chain document from a file instead of stdin',
);

has _stream_to_terminal => (
  is      => 'lazy',
  builder => sub { -t STDOUT || $_[0]->verbose },
);

# The config file this run reads, whether or not it exists. Its own attribute
# because it is more than the source of _config_data: the per-machine agent
# availability lives beside it (App::karr::Foundation::Agents), so --config
# relocates that too.
has _config_path => (
  is      => 'lazy',
  builder => '_build_config_path',
);

sub _build_config_path {
  my ( $self ) = @_;
  return defined $self->config
    ? path( $self->config )
    : path( $ENV{HOME} )->child( '.config', 'karr-foundation', 'config.yml' );
}

has _config_data => (
  is      => 'lazy',
  builder => '_build_config_data',
);

sub _build_config_data {
  my ( $self ) = @_;
  my $cfg_path = $self->_config_path;

  unless ( $cfg_path->exists ) {
    warn "karr-foundation: config not found at $cfg_path -- nothing to do\n";
    return {};
  }

  # Both of these are "your config is wrong", not "karr is wrong", so neither
  # gets a Carp call site pointing into this file (#77). YAML::XS's own error
  # names the document, line and column and carries no call site of its own, so
  # it goes through whole rather than through clean_error, which would keep
  # only its "YAML::XS::Load Error: The problem:" header.
  my $data = try {
    YAML::XS::LoadFile("$cfg_path");
  } catch {
    user_error("Cannot parse config $cfg_path: $_");
  };
  user_error("Config must be a YAML mapping") unless ref $data eq 'HASH';
  return $data;
}

# Collaborators split out of this module along its natural seams (see the
# App::karr::Foundation::* classes). Each holds a weak back-reference to this
# foundation for shared options/helpers; delegation keeps the historical
# method names callable directly on the foundation object.

has _runner => (
  is      => 'lazy',
  handles => [qw(
    _run_command _error_patterns _match_error
    _run_result _result_error _result_summary _result_line
  )],
);

sub _build__runner {
  my ( $self ) = @_;
  return App::karr::Foundation::Runner->new( foundation => $self );
}

has _state => (
  is      => 'lazy',
  handles => [qw(
    _lock_held _acquire_lock _release_lock _force_release_lock
    _read_lock_metadata
    _state_get _state_set _state_del
    _cooldown_active _set_cooldown _clear_cooldown
    _bump_attempts _reset_attempts
  )],
);

sub _build__state {
  my ( $self ) = @_;
  return App::karr::Foundation::State->new( foundation => $self );
}

has _agents => (
  is => 'lazy',
);

sub _build__agents {
  my ( $self ) = @_;
  return App::karr::Foundation::Agents->new( foundation => $self );
}

# The judgement layer (#210): the coordination agent, the deviations that want
# it, and the assignment it writes so that routing needs no AI in the hot path.
# Lazy and mostly a no-op -- a fleet whose config marks no agent
# `role: coordinator` records nothing here and calls nothing.
has _coordinator => (
  is => 'lazy',
);

sub _build__coordinator {
  my ( $self ) = @_;
  return App::karr::Foundation::Coordinator->new( foundation => $self );
}

has _overview => (
  is      => 'lazy',
  handles => [qw( _print_overview )],
);

sub _build__overview {
  my ( $self ) = @_;
  return App::karr::Foundation::Overview->new( foundation => $self );
}

has _limits => (
  is => 'lazy',
);

sub _build__limits {
  my ( $self ) = @_;
  return App::karr::Foundation::Limits->new( foundation => $self );
}

# The hub repository, or undef when no hub is configured. One repository of a
# fleet carries refs/karr-foundation/* -- the chain of planned steps, the run
# logs, the question mailbox -- and which one that is is a property of this
# machine's view of the fleet, so it is named locally rather than discovered. A
# hub that is not there is a warning and not an error: everything foundation
# does without a chain it still does. The two stores below share this one
# resolution because they share the repository; a second copy of it would be a
# second thing to keep in step with `hub:`.
has _hub_git => (
  is => 'lazy',
);

sub _build__hub_git {
  my ( $self ) = @_;
  my $hub = $self->_config_data->{hub};
  return undef unless defined $hub && length $hub;
  my $dir = path( $hub );
  unless ( $dir->is_dir ) {
    warn "karr-foundation: hub not found: $hub\n";
    return undef;
  }
  my $git = App::karr::Git->new( dir => "$dir" );
  unless ( $git->is_repo ) {
    warn "karr-foundation: hub is not a git repository: $hub\n";
    return undef;
  }
  return $git;
}

# The chain of planned steps and the run logs (#189).
has _chain_store => (
  is => 'lazy',
);

sub _build__chain_store {
  my ( $self ) = @_;
  my $git = $self->_hub_git or return undef;
  return App::karr::Foundation::ChainStore->new( git => $git );
}

# The chain executor (#202): the layer above the repo modes that takes a ready
# step, checks its precheck, runs it through one of those modes and writes its
# state back. Built lazily and only reached by the `chain` command -- an
# ordinary tick drains boards and executes no step, because a cron entry
# written before the fleet had a chain must not start doing something else the
# day somebody writes one.
has _executor => (
  is => 'lazy',
);

sub _build__executor {
  my ( $self ) = @_;
  return App::karr::Foundation::Executor->new( foundation => $self );
}

# The question mailbox, in the same repository and for the same reason: a
# question is coordination, so it lives where every machine can see it (#191).
has _questions => (
  is => 'lazy',
);

sub _build__questions {
  my ( $self ) = @_;
  my $git = $self->_hub_git or return undef;
  return App::karr::Foundation::Questions->new( git => $git );
}

# Open file descriptors that hold flock(2) locks on .karr.lock files for the
# boards currently being drained. The fd is what keeps the lock — closing it
# would drop the flock immediately, so Foundation keeps it for the lifetime
# of the drain. _keep_lock_fh / _take_lock_fh are the only writers/readers.
has _lock_fhs => (
  is      => 'ro',
  default => sub { {} },
);

# The agent process this run currently has on the board: { repo, pid, pgid,
# lockfile }. Set by the runner immediately after fork, cleared by the drain
# after waitpid. The SIGTERM handler in run() reads it to know what to kill.
# Undef between agents — the handler is a no-op on those gaps.
has _live_agent => (
  is      => 'rw',
  default => sub { undef },
);

# The boards this run currently has a forked child on: pid => the plan entry
# for that board. Only the concurrent runner writes it, and only in the parent
# -- a child clears it the moment it is born, or its inherited SIGTERM handler
# would kill its siblings' agents (see _spawn_repo). Empty in the serial
# runner, which is what makes the handler's two halves exclusive rather than
# additive.
has _live_children => (
  is      => 'ro',
  default => sub { {} },
);

# fd stash accessors used by State.pm — kept private to the foundation/state
# pair because they leak the internal "lock = open fd" model. Nobody else
# should care.
sub _keep_lock_fh {
  my ( $self, $repo, $fh ) = @_;
  $self->_lock_fhs->{ "$repo" } = $fh;
  return;
}

sub _take_lock_fh {
  my ( $self, $repo ) = @_;
  my $key = "$repo";
  my $fh  = delete $self->_lock_fhs->{$key};
  return $fh;
}


# ---------------------------------------------------------------------------
# Public
# ---------------------------------------------------------------------------

sub run {
  my ( $self, @argv ) = @_;

  # The mailbox commands come first and never discover a board: a question is
  # fleet state in the hub, and `karr-foundation answer 7 yes` typed by a person
  # has nothing to do with which repositories this machine drains (#191).
  if ( @argv ) {
    my $command = shift @argv;
    return $self->_run_ask(@argv)    if $command eq 'ask';
    return $self->_run_answer(@argv) if $command eq 'answer';
    return $self->_run_chain(@argv)  if $command eq 'chain';
    return $self->_run_plan(@argv)   if $command eq 'plan';
    # "Unknown command:" is the marker App::karr::Error::is_usage_error keys on,
    # so a typo here exits 2 (you called this wrong) and not 1 (ADR 0002).
    user_error("Unknown command: '$command' (expected: answer, ask, chain, plan)");
  }

  my @repos = $self->_discover_repos;
  unless ( @repos ) {
    warn "karr-foundation: no repos found -- check config\n";
    return 1;
  }

  # --status forces the read-only overview regardless of agent config.
  if ( $self->status ) {
    $self->_print_overview( \@repos );
    return 0;
  }

  # foundation is a multi-board coordinator: agent execution is opt-in. When no
  # board has an agent configured, the default action is the overview — a human
  # can use foundation purely to see what is happening across boards. A board
  # disabled in its own karr state never counts as an agent board here either,
  # so a config of nothing but disabled boards falls back to the overview.
  # _plan_repos answers that per board, and the answer is kept: the concurrent
  # runner needs the agent name out of the same resolution to bucket its
  # per-agent limits, and resolving twice would be two chances to disagree.
  my @plan = $self->_plan_repos( @repos );
  unless ( grep { $_->{runs_agent} } @plan ) {
    print "No agent will run on any board. Showing overview "
        . "(set 'command:', 'agent:' or 'claude: true' in a .karr file to "
        . "enable agents; a board disabled with 'karr disable' never runs "
        . "one).\n\n";
    $self->_print_overview( \@repos );
    # And still the one call the tick may make (#210): a fleet whose boards
    # are routed by an assignment that does not exist yet reaches exactly this
    # branch -- no board resolves an agent, because nothing has said which one
    # -- and it is the branch that most needs the coordination agent.
    $self->_coordinator->dispatch;
    return 0;
  }

  # The fleet namespace, before anything reads it (#190). The chain is shared
  # state and this machine's copy of it is only as good as its last fetch, so a
  # tick that decided how much to run from a stale header would be deciding
  # from a plan somebody has already replaced. Nothing is pushed back here:
  # this run reads the chain header and writes no step state.
  $self->_sync_pull_foundation;

  # SIGTERM/SIGINT/SIGHUP mid-drain used to leave the agent reparented to init
  # and the .karr.lock naming a dead pid, and the next cron tick read the dead
  # pid as free and started a second agent on the same board (#163, #148).
  # The handler kills the agent's process group, releases the lock, and exits
  # non-zero — the same exit shape systemd/cron see on any other failure, so
  # the operator's monitoring does not need a special case for "killed cleanly
  # mid-drain". Installed for the lifetime of run() and restored to default on
  # the way out so a stray post-run signal goes to the OS, not back into us.
  $self->_install_signal_handlers;

  # One board after another unless the machine ceiling says otherwise, which is
  # what it says by default (App::karr::Foundation::Limits). --dry-run stays
  # serial whatever the ceiling: it starts no agent, so concurrency would buy
  # nothing and cost the deterministic order its output is read in.
  my $concurrent = $self->dry_run ? 1 : $self->_limits->concurrent;
  if ( $concurrent > 1 ) {
    $self->_run_concurrent( \@plan, $concurrent );
  }
  else {
    $self->_run_serially( map { $_->{repo} } @plan );
  }

  # The judgement layer, last and once (#210). Last, because a planner called
  # half way through would plan against a board this tick's own agents were
  # still moving; once, because a tick that met five deviations has learned one
  # thing and five calls would pay five times to hear it. Before the handlers
  # go back to default: the coordination agent is a forked agent like any
  # other, and a signal arriving during it has to take it down with us.
  $self->_coordinator->dispatch;

  $self->_restore_default_signal_handlers;
  return 0;
}

# ---------------------------------------------------------------------------
# The question mailbox (#191)
# ---------------------------------------------------------------------------

# The mailbox lives in the hub, so a machine without one has nowhere to put a
# question. That is an error and not a warning: the two commands do exactly one
# thing, and doing it locally where nobody would ever read it is not a smaller
# version of it.
sub _mailbox {
  my ( $self ) = @_;
  return $self->_questions // user_error(
      'No usable hub repository: the question mailbox lives in '
    . 'refs/karr-foundation/questions/* in the fleet hub, so name one with '
    . "'hub: /path/to/repo' in " . $self->_config_path );
}

# A mailbox that does not travel is a notepad, and neither does a plan. `ask`
# pulls before it mints an id -- ids are minted from what this clone can see,
# so the pull is what keeps two machines from picking the same one -- `plan`
# pulls before it measures whether the chain it replaces still has a step
# running, and all three push what they wrote. A transport failure is a
# warning: the ref is written locally either way and the next `karr sync` in
# the hub publishes it, which is a better answer than refusing to record a
# question because the network is down. `chain` is the one command that
# refuses instead, because the fallback there is running a step another
# machine is already running.
sub _namespace_sync {
  my ( $self, $verb ) = @_;
  my $git = $self->_hub_git or return;
  my $method = "${verb}_foundation";
  try {
    $git->$method;
  } catch {
    warn "karr-foundation: $verb of refs/karr-foundation/ failed: "
       . clean_error($_) . "\n";
  };
  return;
}

# --options a,b, the same comma-separated spelling `karr create --tags` uses,
# with the whitespace around a comma allowed: `--options "cpan, darkpan"` is
# what a person types and refusing it would teach nothing.
sub _option_list {
  my ( $self, $value ) = @_;
  return () unless defined $value;
  my @options = grep { length }
    map { my $o = $_; $o =~ s/\A\s+|\s+\z//g; $o } split /,/, $value;
  return @options ? ( options => \@options ) : ();
}

sub _run_ask {
  my ( $self, @argv ) = @_;
  user_error( 'Usage: karr-foundation ask QUESTION [--context PROSE] '
    . '[--options a,b] [--default a] [--policy block|use_default|escalate_to_ai] '
    . '[--wait SECONDS] [--step ID]: quote a question that contains spaces' )
    unless @argv == 1 && defined $argv[0] && length $argv[0];

  my $mailbox = $self->_mailbox;
  $self->_namespace_sync('pull');

  my $id = $mailbox->ask(
    question => $argv[0],
    $self->_option_list( $self->options ),
    ( defined $self->context ? ( context => $self->context ) : () ),
    ( defined $self->default ? ( default => $self->default ) : () ),
    ( defined $self->policy  ? ( policy  => $self->policy )  : () ),
    ( defined $self->wait    ? ( wait    => $self->wait )    : () ),
    ( defined $self->step    ? ( step    => $self->step )    : () ),
  );
  $self->_namespace_sync('push');

  # The id and the command that settles it, because the next thing whoever
  # reads this does is answer it -- from a terminal that has none of the
  # context this one has.
  my $q = $mailbox->question($id);
  printf "Asked question #%s: %s\n", $id, $q->{question};
  printf "  answer with: karr-foundation answer %s <%s>\n", $id,
    ( $q->{options} ? join( '|', @{ $q->{options} } ) : 'answer' );
  printf "  nobody answers: %s%s\n", $q->{policy},
    ( defined $q->{deadline} ? " after $q->{deadline}" : '' );
  return 0;
}

# The chain (#202). A command of its own, not something an ordinary tick picks
# up on the side: `karr-foundation` with no arguments has meant "drain the
# boards in my config" since it existed, and the day somebody wrote a chain into
# the hub every cron entry in the fleet would silently have started doing
# something else. Opting into execution is the rule agent execution itself
# follows here, and the chain is a bigger opt-in, not a smaller one.
sub _run_chain {
  my ( $self, @argv ) = @_;
  user_error( 'Usage: karr-foundation chain [--dry-run] [--verbose]'
    . ': the chain takes no arguments; what runs is what the plan in '
    . 'the hub says is ready' ) if @argv;
  my $exit = $self->_executor->run;
  # The three chain-side deviations -- a kind: plan step, an escalate_to_ai
  # question, a step gone stale -- are recorded by the executor as it meets
  # them and answered here, once, after the tick has worked through everything
  # it could (#210). The exit code is the executor's either way: whether a
  # planner was called says nothing about whether this binary did its job.
  $self->_coordinator->dispatch;
  return $exit;
}

# ---------------------------------------------------------------------------
# Writing the chain (#213)
# ---------------------------------------------------------------------------

# The chain had no command of its own: App::karr::Foundation::ChainStore's
# write_chain was Perl API, so the one writer that is not a person -- the
# coordination agent -- was handed a `perl -MApp::karr::Foundation::ChainStore
# -e ...` one-liner in its prompt and asked to type it out. That made a storage
# API somebody's interface, where everything else karr asks an agent to do is a
# command, and it meant a rename inside that class broke a prompt rather than a
# call: silently, and only on the tick where a plan was wanted.
#
# It takes a document rather than options because a chain is a DAG and a DAG is
# nested: `--step id=1,kind=ticket,needs=2,3` would be YAML with a worse syntax
# and a parser of its own, and the writer that matters most already produces
# structure. Stdin (or --input) is where `karr restore` takes a snapshot from,
# for the same reason, and the document is read as YAML -- which reads JSON
# too, so an agent that emits JSON has emitted a chain document.
#
# It replaces the chain rather than adding to it, because that is what
# write_chain does and what the header means: ready_steps only considers steps
# whose chain id matches the header, so "append" would be a new chain id over
# the old steps plus the new ones -- a merge with its own rules about ids that
# already exist and states that were already reached. The plan is what the
# planner currently thinks; a chain that still has a running step is refused
# unless --force, which is the guard that makes replacing safe.
sub _run_plan {
  my ( $self, @argv ) = @_;
  user_error( 'Usage: karr-foundation plan [--input PATH] [--force] '
    . '[--dry-run]: the chain itself arrives as YAML or JSON on stdin, or '
    . 'from the file --input names' ) if @argv;

  # The chain is fleet state, so a machine without a hub has nowhere to put
  # one. The same error the mailbox commands raise, for the same reason:
  # writing a plan only this clone can see is not a smaller version of writing
  # the fleet's plan.
  my $store = $self->_chain_store // user_error(
      'No usable hub repository: the chain lives in '
    . 'refs/karr-foundation/chain/* in the fleet hub, so name one with '
    . "'hub: /path/to/repo' in " . $self->_config_path );

  # Parsed before the network is touched, so a document that is not one costs
  # nothing; the steps themselves are checked by the store, which is where the
  # step schema lives and where the write path checks them anyway.
  my ( $steps, %header ) = $store->parse_chain_document( $self->_chain_document );
  my $force = $self->force ? 1 : 0;

  # Before either path: the guard against replacing a chain that still has a
  # running step is only as good as this machine's copy of that chain.
  $self->_namespace_sync('pull');

  if ( $self->dry_run ) {
    my $validated = $store->validate_chain( $steps, force => $force );
    print 'The chain is valid: ' . scalar(@$validated)
        . " step(s), nothing written (--dry-run)\n";
    print _plan_step_lines(@$validated);
    return 0;
  }

  my $chain_id = $store->write_chain( $steps, %header, force => $force );
  $self->_namespace_sync('push');

  # Read back rather than echoed: what is printed is what is in the hub, in
  # the order every other reader of the chain sees it.
  my @written = $store->steps;
  print "Wrote chain $chain_id: " . scalar(@written) . " step(s)\n";
  print _plan_step_lines(@written);
  print "  execute it with: karr-foundation chain\n";
  return 0;
}

# The steps as lines: what each one is, where it happens, and what it waits
# for -- the three things somebody reading back a chain they have just written
# checks it against. The ids share a column so the kinds line up under each
# other, which is what makes a mistyped kind visible at a glance.
sub _plan_step_lines {
  my ( @steps ) = @_;
  my $width = 0;
  for my $step ( @steps ) {
    my $len = length "$step->{id}";
    $width = $len if $len > $width;
  }
  my @lines;
  for my $step ( @steps ) {
    my @what = ( defined $step->{ticket}
      ? "$step->{kind} #$step->{ticket}" : $step->{kind} );
    push @what, "in $step->{repo}" if defined $step->{repo};
    push @what, 'needs ' . join( ', ', @{ $step->{needs} } )
      if $step->{needs} && @{ $step->{needs} };
    push @lines, sprintf "  %-*s  %s\n", $width, $step->{id}, join( ', ', @what );
  }
  return @lines;
}

# The document as characters, from --input or from stdin.
sub _chain_document {
  my ( $self ) = @_;
  my $payload;

  if ( defined $self->input ) {
    # An unreadable --input is the caller's path, not karr's: Path::Tiny's own
    # error would hand them this file and line instead (#77).
    $payload = try { path( $self->input )->slurp_utf8 }
    catch {
      user_error( 'Could not read ' . $self->input . ': ' . clean_error($_) );
    };
  }
  else {
    # A terminal has nothing queued and would sit there with no prompt, so the
    # invocation that forgot its input stays a usage error instead of becoming
    # a hang -- the reading App::karr::Cmd::SetRefs makes of the same edge.
    user_error( 'Usage: karr-foundation plan < chain.yml: the chain '
      . 'document arrives on stdin, or from the file --input names' )
      if -t STDIN;

    # STDIN is the one input edge App::karr::Encoding leaves without a PerlIO
    # layer, precisely so this decode is explicit and happens exactly once.
    binmode STDIN, ':raw';
    my $octets = do { local $/; <STDIN> };

    # An empty stdin is not an empty chain: a generator upstream that produced
    # nothing is a mistake, and a chain needs at least one step anyway. A
    # runtime failure and not a usage error -- the invocation was right, what
    # arrived on the pipe was not.
    user_error('No chain document received on stdin')
      unless defined $octets && length $octets;
    $payload = from_octets($octets);
  }

  my $doc = try { yaml_load($payload) }
  catch {
    # Through whole rather than through clean_error, the same way the config
    # loader above takes YAML::XS's errors: it names the document, the line and
    # the column and carries no call site of its own, and clean_error would
    # keep only its "YAML::XS::Load Error: The problem:" header -- which tells
    # the writer of a broken chain nothing at all.
    user_error("The chain document is not valid YAML or JSON: $_");
  };
  user_error('The chain document is empty') unless defined $doc;
  return $doc;
}

sub _run_answer {
  my ( $self, @argv ) = @_;
  user_error( 'Usage: karr-foundation answer ID ANSWER [--note TEXT] '
    . '[--force]: quote an answer that contains spaces' )
    unless @argv == 2 && defined $argv[1] && length $argv[1];

  my $mailbox = $self->_mailbox;
  $self->_namespace_sync('pull');

  my $a = $mailbox->settle( $argv[0], $argv[1],
    ( defined $self->note ? ( note => $self->note ) : () ),
    force => ( $self->force ? 1 : 0 ),
  );
  $self->_namespace_sync('push');

  printf "Answered question #%s: %s\n", $a->{id}, $a->{answer};
  printf "  %s\n", $a->{question};
  return 0;
}

# What each discovered repo is going to do this tick, decided once in the
# parent: whether it is disabled, whether an agent is meant to run on it at
# all, and -- where the command came from a named definition -- which agent,
# because that is the bucket the per-agent concurrency limit counts in. It is
# the same work run() has always done to choose between the overview and a run;
# the concurrent scheduler needs the agent name out of the same resolution, so
# it is computed once and handed on rather than resolved twice.
sub _plan_repos {
  my ( $self, @repos ) = @_;
  my @plan;
  for my $repo ( @repos ) {
    my %p = ( repo => $repo );
    push( @plan, \%p ), next if $self->_board_disabled( $repo );
    try {
      my ( $cmd, $inv, $wait ) = $self->_resolve_agent( $repo, $self->_load_karr( $repo ) );
      if ( defined $wait ) {
        # An agent board whose assignment says wait (#210). It counts as an
        # agent board -- it is one, and the overview fallback is for a config
        # with no agents at all, not for one whose agents are down -- and it
        # gets no fork: _process_repo says the skip and there is nothing to
        # spend a concurrency slot on. Exactly what a board in cooldown does.
        $p{runs_agent} = 1;
      }
      elsif ( defined $cmd ) {
        $p{runs_agent} = 1;
        $p{fork}       = 1;
        $p{agent}      = $inv->{name} if $inv;
      }
    }
    catch {
      # A board naming an agent this config does not define. _process_repo is
      # where that gets reported (run()'s per-repo catch turns it into a
      # warning and skips one board), so here it only says "an agent was meant
      # to run" -- enough to keep it out of the overview fallback, not enough
      # to spend a concurrency slot on a board that will start nothing.
      $p{runs_agent} = 1;
    };
    push @plan, \%p;
  }
  return @plan;
}

sub _run_serially {
  my ( $self, @repos ) = @_;
  for my $repo ( @repos ) {
    try {
      $self->_process_repo( $repo );
    } catch {
      warn "karr-foundation: error in $repo: $_\n";
    };
  }
  return;
}

# Several boards at once, one agent per board. The unit of concurrency is a
# forked child that runs the whole of _process_repo for exactly one repo, which
# is what keeps the one hard rule intact: .karr.lock stays per repository, and
# a board is held by the single child that took it for the length of its drain.
# Two agents in one working tree would collide over the index and the checkout,
# so concurrency here is across repositories and never inside one -- anything
# else needs a git worktree per agent and is deliberately out of scope.
#
# Forking the whole per-repo pass, rather than teaching the drain loop to
# interleave several agents, is the cheap half of that rule: every piece of
# per-board state -- the lock fd, .karr.state, the engagement record, the
# attempt counters -- keeps exactly one writer without a line of it changing.
# The state that is genuinely shared is agents.state, and that one is locked
# (App::karr::Foundation::Agents).
sub _run_concurrent {
  my ( $self, $plan, $max ) = @_;
  my $per = $self->_limits->per_agent;

  # Everything that will not start an agent is done here, in order, before the
  # first fork: a disabled board, a board with no agent, a board naming one
  # this config does not define. Each costs a couple of ref reads and produces
  # a skip line; forking for it would spend a slot on a no-op and scatter those
  # lines through the agent output for nothing.
  my @queue;
  for my $item ( @$plan ) {
    push( @queue, $item ), next if $item->{fork};
    $self->_run_serially( $item->{repo} );
  }

  my $live = $self->_live_children;
  my %busy;

  while ( @queue || %$live ) {
    my $started = 0;

    if ( keys %$live < $max ) {
      # Scanned rather than shifted: a board whose agent is at its own limit is
      # passed over, not waited for. Head-of-line blocking here would let one
      # busy agent idle the whole machine while boards on another agent wait.
      for my $i ( 0 .. $#queue ) {
        my $name = $queue[$i]{agent};
        next if defined $name
             && defined $per->{$name}
             && ( $busy{$name} // 0 ) >= $per->{$name};
        my ( $item ) = splice @queue, $i, 1;
        $started = 1;
        my $pid = $self->_spawn_repo( $item ) or last;
        $live->{$pid} = $item;
        $busy{$name}++ if defined $name;
        last;
      }
    }

    next if $started;

    unless ( %$live ) {
      # Nothing running, nothing startable: every queued board is held by a
      # per-agent limit no running child will ever give back. A positive limit
      # cannot produce this -- an empty bucket is always under one -- so this
      # is the guard for a zero that got past validation, and it says so
      # instead of spinning.
      warn 'karr-foundation: ' . scalar(@queue)
         . " board(s) left unrun -- no concurrency slot can free up\n";
      last;
    }

    my $pid = waitpid -1, 0;
    last if $pid <= 0;
    my $done = delete $live->{$pid} or next;
    my $name = $done->{agent};
    $busy{$name}-- if defined $name && $busy{$name};
  }
  return;
}

# Fork one child for one board. Returns the child's pid in the parent and never
# returns in the child.
sub _spawn_repo {
  my ( $self, $item ) = @_;
  my $repo = $item->{repo};

  # Anything still in a buffer would be written twice -- once by the parent
  # when it flushes, once by the child that inherited the same buffer.
  STDOUT->flush;
  STDERR->flush;

  my $pid = fork;
  unless ( defined $pid ) {
    warn "karr-foundation: fork failed for $repo: $!\n";
    return undef;
  }
  return $pid if $pid;

  # ----- child: it owns exactly this one board -----
  #
  # The parent's bookkeeping is the parent's. A child that kept the inherited
  # sibling list would kill its siblings' agents out of the SIGTERM handler it
  # also inherited, and a child that kept the inherited lock fds would release
  # locks it never took.
  %{ $self->_live_children } = ();
  %{ $self->_lock_fhs }      = ();
  $self->_live_agent( undef );

  my $ok = try {
    $self->_process_repo( $repo );
    1;
  } catch {
    warn "karr-foundation: error in $repo: $_\n";
    0;
  };

  # _exit, not exit: END blocks and global destruction belong to the process
  # that set them up. Running them in a forked copy would flush the parent's
  # buffers a second time and tear libgit2 down from a child that only borrowed
  # it -- the re-entrancy App::karr::Git refuses outright at teardown (#34).
  # _exit does not flush, so the flush is by hand.
  STDOUT->flush;
  STDERR->flush;
  POSIX::_exit( $ok ? 0 : 1 );
}

# SIGTERM/INT/HUP handler: kill the live agent's process group, release the
# lock, exit non-zero. Built once at run() time and shared by all three
# signals — the OS's default for SIGINT/SIGHUP is exit too, but those do not
# wait for the agent to die, which is the whole problem.
sub _install_signal_handlers {
  my ( $self ) = @_;
  my $handler = sub { $self->_handle_shutdown_signal(@_); };
  $SIG{TERM} = $handler;
  $SIG{INT}  = $handler;
  $SIG{HUP}  = $handler;
  return;
}

sub _restore_default_signal_handlers {
  $SIG{TERM} = 'DEFAULT';
  $SIG{INT}  = 'DEFAULT';
  $SIG{HUP}  = 'DEFAULT';
  return;
}

# Signal handler body. Perl signal handlers run in a restricted context — no
# malloc, no PerlIO ops beyond safe ones, and certainly no $self->method on an
# object whose class might be in the middle of compilation. Foundation is
# already running and the methods called here are simple attribute reads and
# POSIX ops, which are documented as safe in 5.16+. We do NOT call
# Foundation's own _append_log or anything that opens files — the agent is
# dying and the lock is going away; the operator gets the next run's log.
sub _handle_shutdown_signal {
  my ( $self, $sig_name ) = @_;
  my $agent = $self->_live_agent;
  if ( $agent && $agent->{pgid} ) {
    # Negative pid = process group (kill(2) group semantics). The agent's
    # pgid is the agent's own pid because Runner calls setpgrp(0,0) in the
    # child right after fork, so kill 'TERM', -$pgid signals the whole group
    # — including any grandchildren the agent itself forked (#148).
    kill 'TERM', -$agent->{pgid};
    # Give the group a moment to die. SIGTERM is catchable; a hung child
    # needs SIGKILL. Two seconds matches the timeout path in Runner.
    my $end = time + 2;
    while ( time < $end ) {
      last if kill( 0, $agent->{pid} ) == 0;
      select undef, undef, undef, 0.05;
    }
    kill 'KILL', -$agent->{pgid};
    # Reap without blocking — the SIGKILL will deliver but the actual wait
    # is best-effort because we are already on the way out.
    waitpid $agent->{pid}, 0 if $agent->{pid};
  }
  if ( $agent && $agent->{repo} ) {
    # Force-release the lock: we may have lost the fd through a process
    # restart, but the recorded pid in the file still matches $$ if this is
    # the foundation that took it. _force_release_lock verifies and unlinks.
    # Wrap the repo argument in path() in case it crossed a string boundary
    # (some callers keep agent->{repo} as a string); State.pm's helpers all
    # take a Path::Tiny object.
    $self->_force_release_lock( path( $agent->{repo} ) );
  }

  # The concurrent runner's children (#186). Each inherited this same handler
  # and has its own agent on its own board, so the parent does not reach past
  # them: it TERMs the children and lets every one of them run the branch above
  # for its own board -- kill its agent's process group, release its own lock.
  # Killing the children outright instead would leave every agent reparented to
  # init, which is #163's failure multiplied by the concurrency. SIGKILL is
  # only for a child that did not manage even that.
  my $kids = $self->_live_children;
  if ( %$kids ) {
    kill 'TERM', keys %$kids;
    # Long enough for a child to finish its own two-second TERM-then-KILL on
    # the agent and unlink its lock; short enough that an operator holding
    # Ctrl-C does not conclude that nothing is happening.
    my $end = time + 5;
    while ( time < $end ) {
      for my $pid ( keys %$kids ) {
        delete $kids->{$pid} if waitpid( $pid, WNOHANG ) != 0;
      }
      last unless %$kids;
      select undef, undef, undef, 0.05;
    }
    if ( %$kids ) {
      kill 'KILL', keys %$kids;
      waitpid $_, 0 for keys %$kids;
    }
  }
  # Restore defaults so the second delivery (e.g. impatient operator) kills us
  # for real instead of looping in the handler.
  $self->_restore_default_signal_handlers;
  # Exit non-zero so cron/systemd can see we did not finish a clean run.
  # $sig_name is "TERM" / "INT" / "HUP" — 128 + signal number is the
  # conventional shell exit code for signal death.
  my $sig_num = $sig_name eq 'TERM' ? SIGTERM
              : $sig_name eq 'INT'  ? SIGINT
              : $sig_name eq 'HUP'  ? SIGHUP
              : 15;
  POSIX::_exit( 128 + $sig_num );
}


# ---------------------------------------------------------------------------
# Discovery
# ---------------------------------------------------------------------------

sub _discover_repos {
  my ( $self ) = @_;
  my @repos;

  # Explicit repo roots
  for my $dir ( @{ $self->_config_data->{dirs} // [] } ) {
    my $p = path( $dir );
    if ( $p->is_dir ) {
      push @repos, $p;
    } else {
      warn "karr-foundation: dir not found: $dir\n";
    }
  }

  # Scanned parent directories — check direct children for .karr file
  # OR refs/karr/config (karr-init'd repo without .karr file)
  for my $scan_dir ( @{ $self->_config_data->{scan} // [] } ) {
    my $p = path( $scan_dir );
    unless ( $p->is_dir ) {
      warn "karr-foundation: scan dir not found: $scan_dir\n";
      next;
    }
    for my $child ( $p->children ) {
      next unless $child->is_dir;
      # .karr file takes precedence; also detect karr-init'd repos
      if ( $child->child('.karr')->exists ) {
        push @repos, $child;
      } elsif ( $self->_is_karr_board_root( $child ) ) {
        push @repos, $child;
      }
    }
  }

  # A repo reachable through both dirs: (explicit) and scan: (its parent) was
  # processed twice per tick — the agent ran twice and the overview printed
  # the board twice (#166). The two Path::Tiny objects can be the same string,
  # differ only by trailing slash, or even be a symlink and its target; the
  # key is the canonical filesystem path. First-seen wins so the explicit
  # dirs: order is preserved over whatever order scan: happened to find them.
  my %seen;
  my @uniq;
  for my $repo ( @repos ) {
    my $key = try { $repo->realpath } catch { $repo->absolute };
    next if $seen{$key}++;
    push @uniq, $repo;
  }
  return @uniq;
}

# True when $dir is *itself* the root of a karr-init'd repo — resolves via
# libgit2 so packed refs (git gc / pack-refs) and worktree gitdir indirection
# are handled, unlike a bare .git/refs/karr/config file check. libgit2's
# open_ext walks up to find an enclosing .git, so a plain directory nested
# inside a karr repo would spuriously match; guard by confirming the resolved
# repo root is $dir, not an ancestor.
sub _is_karr_board_root {
  my ( $self, $dir ) = @_;
  my $git = App::karr::Git->new( dir => "$dir" );
  return 0 unless $git->is_repo;
  my $root = $git->repo_root or return 0;
  return 0 unless $root->realpath eq path( $dir )->realpath;
  return $git->ref_exists('refs/karr/config');
}

# ---------------------------------------------------------------------------
# Per-repo processing
# ---------------------------------------------------------------------------

# One pass over one repository. Returns the drain's own result hash, or
# { outcome => 'skipped', reason => ... } for a repo this tick did not take up
# at all -- a shape the serial and concurrent runners ignore and the chain
# executor (#202) reads: a step whose board was locked, disabled, in cooldown or
# on a failing agent is a step to try again, not a step that failed.
#
# %opt is the chain's half of the contract, and only the chain passes it:
# `ticket` names the card this run is about (which forces ticket mode -- the
# plan has already decided what this run is, whatever the .karr file's `mode`
# says, and a chain step that named a card is by construction work to do, so it
# needs no board-movement check to justify starting) and `timeout` is the
# step's own budget for it.
sub _process_repo {
  my ( $self, $repo, %opt ) = @_;

  # Check if repo has karr board (either .karr file or karr refs). Resolve the
  # ref via libgit2 so packed refs and worktrees are handled — $repo is an
  # already-known repo root here, so open_ext's walk-up cannot false-match.
  my $has_karr = $repo->child('.karr')->exists
              || App::karr::Git->new( dir => "$repo" )->ref_exists('refs/karr/config');
  unless ( $has_karr ) {
    $self->_say_verbose("skip $repo -- no karr board");
    return { outcome => 'skipped', reason => 'no karr board' };
  }

  # Board-level disable flag, checked FIRST: before the agent command is even
  # resolved and before the drain decision. A disabled board is skipped whole —
  # no drain, no auto-block, no agent run — so the flag wins over --command,
  # the config's default_command, the .karr command and 'claude: true'. It is
  # deliberately absolute: --force does not override it.
  return { outcome => 'skipped', reason => 'the board is disabled' }
    if $self->_skip_disabled( $repo );

  my $karr = $self->_load_karr( $repo );

  # Resolve the agent command (CLI > default_command > .karr command > a named
  # agent definition > the assignment > claude: true synthesis). Agent
  # execution is opt-in: a board with no agent is shown in the overview, not
  # run.
  my ( $cmd, $agent, $wait ) = $self->_resolve_agent( $repo, $karr );

  # The assignment routes this board and says nothing may run on it right now
  # (#210): every agent in its fallback chain is failing, or the chain says
  # WAIT. Skipped like a board in cooldown and for the same reason -- the wait
  # is bounded and ends by itself -- and NOT reported as "no agent configured",
  # which is a different board and a different fix.
  if ( defined $wait ) {
    $self->_say_verbose("skip $repo -- $wait");
    return { outcome => 'skipped', reason => $wait };
  }

  unless ( defined $cmd ) {
    $self->_say_verbose("skip $repo -- no agent configured (see --status)");
    return { outcome => 'skipped', reason => 'no agent configured' };
  }

  # Check lock — skip if another instance is running
  if ( $self->_lock_held( $repo ) ) {
    $self->_say_verbose("skip $repo -- locked by running agent");
    return { outcome => 'skipped', reason => 'the board lock is held' };
  }

  # Respect exponential cooldown left by a previous common-error run
  if ( $self->_cooldown_active( $repo ) ) {
    my $until = $self->_state_get( $repo, 'cooldown_until' ) // 0;
    $self->_say_verbose( "skip $repo -- in cooldown for " . ( $until - time ) . "s" );
    return { outcome => 'skipped',
      reason => 'the board is in cooldown for ' . ( $until - time ) . 's' };
  }

  # And the agent's own availability, which is the same idea one level up. The
  # cooldown above parks THIS BOARD after a bad run; this parks EVERY board
  # that uses the agent that had it, because "the command stopped working" is a
  # fact about the command and the machine, not about the repository. Two repos
  # driven by the same agent share the outage instead of each burning a window
  # discovering it. Like the cooldown, --force does not override it: the wait
  # is bounded by probe_every and ends by itself.
  if ( $agent && !$self->_agents->available( $agent->{name} ) ) {
    my $av   = $self->_agents->availability( $agent->{name} );
    my $wait = ( $av->{next_attempt} // 0 ) - time;
    $self->_say_verbose( "skip $repo -- agent '$agent->{name}' failing"
      . ( defined $av->{last_error} ? " ($av->{last_error})" : '' )
      . ", next attempt in ${wait}s" );
    return { outcome => 'skipped',
      reason => "agent '$agent->{name}' is failing, next attempt in ${wait}s" };
  }

  # Pull latest refs. A pull that refuses -- the wholesale-wipe guard, the
  # board-identity guard, and (since #154) the unapplied-refs guard all die
  # rather than return false -- must not abort the drain loop. The other
  # per-repo step that can die (_drain_repo below) is wrapped in its own
  # try and turned into a structured error result; the pull sits at the same
  # level and is isolated the same way, so a refusal from one board warns
  # and is skipped here while the rest of run() continues to the next.
  # The pull happens before the lock is taken, so "release whatever it
  # holds" is a no-op today; the wrap is for the structural isolation
  # (clean separation, karr-shaped error message) and is forward-compatible
  # with any future caller that takes the lock before pulling.
  my $pull_ok = try {
    $self->_sync_pull( $repo );
    1;
  } catch {
    warn "karr-foundation: pull error in $repo: $_\n";
    0;
  };
  return { outcome => 'skipped', reason => 'the board could not be pulled' }
    unless $pull_ok;

  # The pull may have just brought the disable flag in from another machine —
  # re-check before committing to a drain, so a board disabled elsewhere is
  # never drained even once by this host.
  return { outcome => 'skipped', reason => 'the board is disabled' }
    if $self->_skip_disabled( $repo );

  # Decide whether to start a drain at all. A chain step naming a card is the
  # third answer beside --force and the board's own movement: the plan already
  # decided this run has something to do, and asking the board again could only
  # disagree with it.
  my $should_run = $self->force || defined $opt{ticket};
  unless ( $should_run ) {
    my $prev_hash = $self->_state_get( $repo, 'hash' ) // '';
    my $curr_hash = $self->_ref_hash( $repo ) // '';
    my $on_idle   = $karr->{on_idle} // 'skip';
    $should_run = ( $curr_hash ne $prev_hash )
               || $self->_has_actionable_tasks( $repo )
               || ( $on_idle eq 'always-run' );
  }

  unless ( $should_run ) {
    $self->_say_verbose("skip $repo -- no board change and no actionable tasks");
    return { outcome => 'skipped',
      reason => 'no board change and no actionable tasks' };
  }

  # Acquire lock — flock-based now, so two ticks that overlap race on the
  # file rather than on a check-then-act gap a git pull apart (#162). Failure
  # here means another foundation instance holds the board; we skip and move
  # on instead of spewing over the existing lock.
  unless ( $self->_acquire_lock( $repo ) ) {
    $self->_say_verbose("skip $repo -- lock contended (another tick holds it)");
    return { outcome => 'skipped', reason => 'the board lock is contended' };
  }
  my $result = try {
    $self->_drain_repo( $repo, $karr, $cmd, $agent, %opt );
  } catch {
    warn "karr-foundation: drain error in $repo: $_\n";
    { outcome => 'error', exit => 1 };
  };
  # The domain hook, still under the board's own lock (#193). A release gate
  # that builds and installs out of this working tree must not have another
  # tick's agent walk into it halfway through, and .karr.lock is the thing
  # that already says "one process in this repository at a time". Isolated the
  # same way the drain and the pull above are: a hook that throws warns and is
  # skipped, because dying here would carry the _release_lock below with it
  # and leave the board locked by a process that is no longer in it.
  try {
    $self->_run_on_drained( $repo, $karr, $result );
  } catch {
    warn "karr-foundation: on_drained error in $repo: $_\n";
  };
  $self->_release_lock( $repo );

  # Exponential cooldown bookkeeping: grow on common-error, reset otherwise.
  # A run that was not a common error also drops last_error — it describes the
  # last run, and one left standing outlives the cooldown it caused and reads
  # as a contradiction against the last_exit written just below (#160).
  #
  # The same verdict updates the named agent's availability, for boards that
  # use one. Nothing finer is asked of it: a rate limit, a spent budget, a
  # revoked key and a wrapper that is not installed here all arrive as
  # common-error, and the same bounded retry answers all of them. A run that
  # was NOT a common error says the command works, which is what ends an
  # outage and gets the moment it ended written down. A false positive costs
  # one probe interval of caution; a false negative costs every board on that
  # agent its next window.
  if ( ( $result->{outcome} // '' ) eq 'common-error' ) {
    $self->_set_cooldown( $repo, $karr );
    $self->_agents->record_failure( $agent->{name}, $result->{error} ) if $agent;
  } else {
    $self->_clear_cooldown( $repo );
    $self->_state_del( $repo, 'last_error' );
    if ( $agent && $self->_agents->record_success( $agent->{name} ) ) {
      $self->_say_verbose("agent '$agent->{name}' works again");
    }
  }

  # Update state
  my %state = (
    hash      => $self->_ref_hash( $repo ) // '',
    last_run  => localtime->datetime,
    last_exit => $result->{exit} // 0,
  );

  # The last run's own report, where it made one (#187): how it ended, how many
  # turns it took, how long it ran, what it cost. It is dropped again by a run
  # that reported nothing, for the same reason last_error is (#160): a key that
  # is still there describes the last run, and one describing a run three ticks
  # ago is a contradiction nobody reading .karr.state can resolve.
  if ( $result->{report} ) {
    $state{last_result} = $result->{report};
  }
  else {
    $self->_state_del( $repo, 'last_result' );
  }

  $self->_state_set( $repo, %state );

  return $result;
}

# ---------------------------------------------------------------------------
# The domain hook (#193)
# ---------------------------------------------------------------------------

# What to run when this board has drained, or undef when nothing is configured.
# .karr first, then the config file, like every other key here: a fleet can
# hang one gate on every board it drains, and a board can say something else --
# including `on_drained: ""`, which is how one board opts out of a fleet-wide
# one.
sub _on_drained_command {
  my ( $self, $karr ) = @_;
  my $cmd = exists $karr->{on_drained}
    ? $karr->{on_drained}
    : $self->_config_data->{on_drained};
  return undef unless defined $cmd && length $cmd;
  return $cmd;
}

# One resolved number for one of the hook's two settings, .karr before config
# before the built-in default.
sub _on_drained_setting {
  my ( $self, $karr, $key, $default ) = @_;
  return $karr->{$key} // $self->_config_data->{$key} // $default;
}

# Run the hook, if the board drained and if it is allowed to run at all.
#
# "The board drained" is the observable fact and not an outcome name: no
# actionable task is left on it. The outcome cannot answer this -- a drain that
# empties a board ends on `progress`, because progress is what the last
# iteration made, and `idle` is a run that did nothing on a board that was
# already quiet. Asking the board is also the only question that stays true
# across the run modes: `mode: ticket` does one card and returns, and whether
# that leaves the board empty is not something the mode knows.
#
# karr does not look at what the hook is or what it did. In the fleet this
# design came from it is a release gate that builds a distribution, installs
# it, tests every dependent against it and raises version requirements -- none
# of which belongs in a kanban tool, and all of which would arrive here as
# rules about what the exit code means. So the exit code is written down and
# interpreted by nobody: a hook that fails does not park the board, does not
# mark the board's agent failing, and does not become the run's last_error. It
# is not a run of the agent and is never classified as one.
sub _run_on_drained {
  my ( $self, $repo, $karr, $result ) = @_;
  my $cmd = $self->_on_drained_command( $karr ) or return;

  # A run that broke tells us nothing about the board. A rate-limited or
  # unauthenticated agent leaves a board looking exactly like one it worked
  # through, and the cooldown that is about to be set says foundation does not
  # believe this run -- so neither does the hook.
  my $outcome = $result->{outcome} // '';
  return if $outcome eq 'common-error' || $outcome eq 'error';
  return if $self->_has_actionable_tasks( $repo );

  my $hash   = $self->_ref_hash( $repo ) // '';
  my $rounds = $self->_state_get( $repo, 'on_drained_rounds' ) // 0;
  my $max    = $self->_on_drained_setting( $karr, 'on_drained_max_rounds', 3 );

  # Two guards, and between them the answer to "what stops this being a loop".
  # An empty board is not the same as finished work: the hook may fail and file
  # tickets, at which point the board is no longer drained, the next tick
  # works them, the board drains again and the hook is asked again. That cycle
  # is the point -- a gate that files what it found and is re-run once it is
  # fixed is exactly what it is for -- so neither guard tries to forbid it.
  # What they bound is the two ways it stops being that:
  #
  #   1. The same board twice. Without this, a repository nobody touches runs
  #      a release gate on every cron tick for ever, because a drained board
  #      stays drained. The hook has already had its say about this exact
  #      state; it is asked again when the state changes.
  #
  #   2. A chain that never settles. The hook files a ticket, the agent works
  #      it (or fails it into an auto-block), the board drains, the hook files
  #      another. Every round changes the board, so guard 1 is no help; the
  #      board moves for real each time, so nothing else notices either.
  #      Counting the consecutive rounds in which the hook itself put work back
  #      is the only thing foundation can observe about it, and it is enough:
  #      a run that leaves the board alone -- the gate that finally passed --
  #      clears the count, and a cap stops the ones that never do.
  #
  # --force overrides both. They are statements about board state, which is
  # what --force is documented to override, and unlike the cooldown and the
  # agent availability the cap is not time-bounded and does not end by itself,
  # so it needs a way out and the operator is it.
  unless ( $self->force ) {
    # `defined`, not a `// ''` default: a repository whose refs/karr/* cannot
    # be fingerprinted at all -- not a karr board, or not a git repository --
    # has a hash of '', and defaulting the unset state key to '' would make
    # its first drain look like a repeat and silence the hook there for good.
    my $last = $self->_state_get( $repo, 'on_drained_hash' );
    if ( defined $last && $hash eq $last ) {
      $self->_say_verbose(
        "skip on_drained in $repo -- the board has not moved since the last one" );
      return;
    }
    if ( $max > 0 && $rounds >= $max ) {
      $self->_append_log( $repo, "ON-DRAINED suppressed -- $rounds consecutive "
        . "run(s) put work back on the board without settling "
        . "(on_drained_max_rounds: $max); --force runs it again" );
      return;
    }
  }

  my ( $exit ) = $self->_run_command( $repo, $karr, $cmd, undef, undef,
    role        => 'hook',
    max_runtime => $self->_on_drained_setting( $karr, 'on_drained_max_runtime', 1800 ),
  );

  # Did it put work back? Asked of the board and not of the hook: the hook is
  # not obliged to say, and karr is not entitled to know.
  my $made_work = ( ( $self->_ref_hash( $repo ) // '' ) ne $hash ) ? 1 : 0;
  $self->_append_log( $repo, "ON-DRAINED exit=$exit"
    . ( $made_work ? " -- the board moved, so it is no longer drained" : '' ) );

  # on_drained_hash is the state that *triggered* the run, not the one the run
  # left behind: the invariant is "the hook is not asked twice about the same
  # board", and a hook that files a ticket and has it reverted is being asked
  # about a board it has already answered for.
  $self->_state_set( $repo,
    on_drained_hash   => $hash,
    on_drained_rounds => ( $made_work ? $rounds + 1 : 0 ),
    last_on_drained   => {
      at        => localtime->datetime,
      exit      => $exit,
      made_work => $made_work,
    },
  );
  return;
}

# ---------------------------------------------------------------------------
# Sync
# ---------------------------------------------------------------------------

sub _sync_pull {
  my ( $self, $repo ) = @_;
  $self->_say_verbose("sync --pull $repo");
  return if $self->dry_run;
  my $git = App::karr::Git->new( dir => "$repo" );
  return unless $git->is_repo;
  $git->pull;
}

# The fleet's own namespace, refs/karr-foundation/*, from the hub repository
# (#190). It is a separate call from _sync_pull above because it is a separate
# thing: _sync_pull brings one board up to date on its way into that board's
# drain, this brings the shared plan up to date once, before anything reads it.
#
# It runs before the concurrency limits are resolved, which is the only reader
# there is today: the chain header's `limits:` block. A tick that went on to
# execute chain steps would have to push this namespace back afterwards, with
# the step state and the run log in it, or two machines would run the same
# step -- this one writes nothing there, so there is nothing to push.
#
# A failed pull is a warning and not a refusal. What is lost is the newest
# chain header, and the fallback is this machine's own ceiling, which is the
# safe direction: the local limit is the one that protects the local CPU.
sub _sync_pull_foundation {
  my ( $self ) = @_;
  my $store = $self->_chain_store or return;
  return if $self->dry_run;
  $self->_say_verbose('sync --pull refs/karr-foundation/*');
  try {
    $store->git->pull_foundation;
  } catch {
    warn 'karr-foundation: pull of refs/karr-foundation/ failed: '
       . clean_error($_) . "\n";
  };
  return;
}

# ---------------------------------------------------------------------------
# Ref hash (detect board changes)
# ---------------------------------------------------------------------------

sub _ref_hash {
  my ( $self, $repo ) = @_;
  my $git = App::karr::Git->new( dir => "$repo" );
  return undef unless $git->is_repo;
  my $oids = $git->ref_oids('refs/karr/') or return undef;
  # Deterministic fingerprint of refs/karr/* (ref name + target OID).
  my $out = join '', map { "$_ $oids->{$_}\n" } sort keys %$oids;
  return md5_hex( $out );
}

# ---------------------------------------------------------------------------
# Board-level disable flag (refs/karr/config: foundation.enabled)
# ---------------------------------------------------------------------------

# The board's own opt-out, stored in karr state rather than in the local .karr
# file so it syncs with the board and every foundation instance on every machine
# honours it. Returns { reason => $text_or_undef } when the board is disabled
# and undef when it is enabled (the default for a board that never set it).
sub _board_disabled {
  my ( $self, $repo ) = @_;
  my $git = App::karr::Git->new( dir => "$repo" );
  return undef unless $git->is_repo;
  my $store = App::karr::BoardStore->new( git => $git );
  return undef if $store->foundation_enabled;
  return { reason => $store->foundation_reason };
}

# Skip predicate used at the two checkpoints in _process_repo. True (and a
# verbose note) when the board is disabled.
sub _skip_disabled {
  my ( $self, $repo ) = @_;
  my $off = $self->_board_disabled( $repo ) or return 0;
  my $reason = $off->{reason};
  $self->_say_verbose(
    "skip $repo -- board disabled" . ( defined $reason ? ": $reason" : '' ) );
  return 1;
}

# ---------------------------------------------------------------------------
# Task state / actionability
# ---------------------------------------------------------------------------

# A task is actionable when an agent could still pick it: not terminal
# (done/archived) and not blocked. Mirrors `karr pick` eligibility.
sub _is_actionable {
  my ( $self, $st ) = @_;
  return 0 unless $st;
  return 0 if $st->{blocked};
  my $status = $st->{status} // '';
  return 0 if $status eq 'done' || $status eq 'archived';
  return 1;
}

# Snapshot every task as id => { status, claimed_by, updated, blocked }.
sub _task_states {
  my ( $self, $repo ) = @_;
  my $git = App::karr::Git->new( dir => "$repo" );
  return () unless $git->is_repo;
  my $store = App::karr::BoardStore->new( git => $git );
  my %states;
  for my $t ( $store->load_tasks ) {
    next unless $t;
    $states{ $t->id } = {
      status     => $t->status,
      claimed_by => ( $t->has_claimed_by ? $t->claimed_by : undef ),
      updated    => $t->updated,
      blocked    => ( $t->has_blocked ? 1 : 0 ),
    };
  }
  return %states;
}

sub _has_actionable_tasks {
  my ( $self, $repo ) = @_;
  my %states = $self->_task_states( $repo );
  for my $id ( keys %states ) {
    return 1 if $self->_is_actionable( $states{$id} );
  }
  return 0;
}

# ---------------------------------------------------------------------------
# Agent engagement (who this run's agent is, and what it touched)
# ---------------------------------------------------------------------------

# The activity log of the identity foundation runs its agent under. The Runner
# exports KARR_ROLE=agent to the command, so every nested `karr` write during
# the run lands in refs/karr/log/agent/<git-email> — the same identity this
# builds, since the agent runs in this repo with this repo's git config. Any
# other actor on the board (a human, another machine's agent) writes elsewhere.
sub _agent_log_entries {
  my ( $self, $repo ) = @_;
  my $git = App::karr::Git->new( dir => "$repo" );
  return () unless $git->is_repo;
  my $log = App::karr::ActivityLog->new( git => $git, role => 'agent' );
  return try { $log->entries } catch { () };
}

# An engagement record for one drain: the log entries already present when the
# drain started (so only what this drain adds counts), the task ids this run's
# agent has written to, and the claim names it wrote them under.
sub _new_engagement {
  my ( $self, $repo ) = @_;
  my @seen = $self->_agent_log_entries( $repo );
  return { seen => scalar @seen, ids => {}, claims => {} };
}

# Fold the entries the last command added into the record. Nothing else is
# evidence of engagement: a task that never shows up here was never touched by
# this run's agent, whatever its status or claim says.
sub _note_engagement {
  my ( $self, $repo, $eng ) = @_;
  my @entries = $self->_agent_log_entries( $repo );
  return $eng if @entries <= $eng->{seen};
  for my $entry ( @entries[ $eng->{seen} .. $#entries ] ) {
    my $id = $entry->{task_id};
    $eng->{ids}{ $id + 0 } = 1 if defined $id && $id =~ /\A[0-9]+\z/;
    my $who = $entry->{agent};
    $eng->{claims}{$who} = 1 if defined $who && length $who;
  }
  $eng->{seen} = scalar @entries;
  return $eng;
}

# True when the card is the agent's to penalize: unclaimed, or held under a
# name this run's agent itself wrote with. A claim belonging to anybody else —
# a human, another machine's agent, or this agent's own abandoned claim from an
# earlier run — is never ours to auto-block.
sub _agent_holds {
  my ( $self, $state, $claims ) = @_;
  my $owner = $state->{claimed_by};
  return 1 unless defined $owner && length $owner;
  return ( $claims // {} )->{$owner} ? 1 : 0;
}

# Tasks this run's agent engaged but did not move — still actionable, written
# to by the agent during this drain, held by nobody but the agent, and
# byte-identical before/after the last command. These are the only tasks that
# count toward an auto-block.
#
# Engagement is proven, never assumed: without an entry of the agent's own in
# $eng, foundation has no evidence it ever attempted the task, and an
# auto-block would be a destructive write to somebody else's card carrying a
# reason that is factually wrong (#158). So an engagement it cannot establish —
# an agent that does not write through karr, an unreadable log, a stale claim
# nobody touched this run — yields no stuck tasks and no auto-block at all.
# Failing to block a genuinely stuck card only leaves the drain to end on its
# iteration cap; blocking a stranger's card takes their work out of the
# actionable set behind their back.
sub _stuck_tasks {
  my ( $self, $before, $after, $eng ) = @_;
  my $ids    = ( $eng // {} )->{ids}    // {};
  my $claims = ( $eng // {} )->{claims} // {};
  my @stuck;
  for my $id ( sort { $a <=> $b } keys %$after ) {
    my $a = $after->{$id};
    next unless $self->_is_actionable( $a );
    next unless $ids->{$id};                      # the agent never touched it
    next unless $self->_agent_holds( $a, $claims ); # somebody else holds it
    next unless defined $a->{claimed_by} || ( $a->{status} // '' ) eq 'in-progress';
    my $b = $before->{$id} or next;   # newly created this run — give it grace
    next if ( $b->{status}  // '' ) ne ( $a->{status}  // '' );
    next if ( $b->{updated} // '' ) ne ( $a->{updated} // '' );
    push @stuck, $id;
  }
  return @stuck;
}

# ---------------------------------------------------------------------------
# Drain loop
# ---------------------------------------------------------------------------

# Run the agent repeatedly until the board has no actionable tasks left,
# auto-blocking tasks the agent keeps failing on. Returns
# { outcome => progress|stall|idle|common-error|error, exit => N, ticket => ID,
#   report => {...}, error => STR } (ticket is undef outside mode: ticket;
# error is set only on a common-error outcome).
# $agent is the named agent definition behind $cmd, or undef.
#
# %opt is the chain executor's (#202): `ticket` is the card the plan named --
# which makes this a ticket-mode run whatever the .karr file says, because a
# step that names a card and a repo configured to drain cannot both be obeyed
# and the plan is the more specific statement -- and `timeout` is the step's own
# budget, which beats the board's default for the same reason.
sub _drain_repo {
  my ( $self, $repo, $karr, $cmd, $agent, %opt ) = @_;
  my $max_runtime  = $opt{timeout} // $karr->{max_runtime} // 1800;
  my $max_attempts = $karr->{max_attempts}   // 2;
  my $max_iter     = $karr->{max_iterations} // 50;
  my $mode         = defined $opt{ticket} ? 'ticket' : $self->_run_mode( $karr );
  my $drain        = $mode eq 'drain' ? 1 : 0;
  my $patterns     = $self->_error_patterns( $karr );

  # Use the resolved command, not $karr->{command}
  $cmd //= $karr->{command};

  # Ticket mode names the card before the agent starts, and the run is about
  # that card and nothing else. No card, no run: "run exactly one ticket" has
  # nothing to say when the board has no ticket to give, and an agent started
  # anyway would go looking for work of its own, which is the mode this one
  # exists to replace. --force and on_idle: always-run force the *check*, not a
  # run without a card.
  my $ticket;
  if ( $mode eq 'ticket' ) {
    $ticket = defined $opt{ticket} ? $opt{ticket} : $self->_select_ticket( $repo );
    unless ( defined $ticket ) {
      $self->_append_log( $repo, "TICKET none assignable -- no agent run" );
      return { outcome => 'idle', exit => 0, ticket => undef };
    }
    $self->_append_log( $repo, "TICKET task#$ticket" );
  }

  my $loop_start = time;
  my $last_exit  = 0;
  my $outcome    = 'idle';
  my $first      = 1;
  my $iter       = 0;

  # The last run's own report, summarised (Runner::_result_summary), or undef
  # while no run has made one. It survives the loop so a drain hands back what
  # its final iteration reported.
  my $last_report;

  # The common error that ended the drain, where one did. It leaves the loop
  # because the caller needs it for two things now: .karr.state's last_error,
  # which the drain writes itself, and the named agent's availability record,
  # which is the caller's to write.
  my $error;

  # What this run's agent engages, accumulated across the whole drain: the
  # iteration that claims a task is the one that moves the board, so the stall
  # only becomes visible one or more iterations later.
  my $eng = $self->_new_engagement( $repo );

  while ( 1 ) {
    my %before = $self->_task_states( $repo );
    my @actionable = grep { $self->_is_actionable( $before{$_} ) } keys %before;

    # Once we have run at least once, stop when the board is drained, the
    # wall-clock budget is spent, or we hit the hard iteration cap. The
    # wall-clock check is skipped when max_runtime is 0: that value disables
    # the per-run timeout entirely (documented, Runner.pm), and the drain's
    # budget must not silently inherit the same "no limit" sentinel as a
    # hard zero — `>= 0` is always true after the first iteration and would
    # turn drain: true into a single run (#165). With max_runtime: 0 the
    # drain runs until the board is drained or the iteration cap.
    last if !$first && !@actionable;
    last if !$first && $max_runtime > 0 && ( time - $loop_start ) >= $max_runtime;
    last if $iter >= $max_iter;

    my $hash_before = $self->_ref_hash( $repo ) // '';
    my ( $exit, $output ) = $self->_run_command( $repo, $karr, $cmd, $ticket, $agent,
      ( defined $opt{timeout} ? ( max_runtime => $opt{timeout} ) : () ) );
    $last_exit = $exit;
    $first     = 0;
    $iter++;

    my $hash_after = $self->_ref_hash( $repo ) // '';
    my $progressed = ( $hash_before ne $hash_after ) ? 1 : 0;

    # What the run said about itself, where it said anything: a claude-code
    # result object at the end of its output (Runner::_run_result explains how
    # foundation finds one and why it looks there and nowhere else). This is
    # the classification the text scan below has always been a stand-in for
    # (#187) — error flag, error kind, turns, duration, cost, stated by the
    # run rather than inferred from its prose.
    my ( $ended, $rerr );
    my $report = $self->_run_result( $output );
    if ( $report ) {
      ( $rerr, $ended ) = $self->_result_error( $report );
      $last_report = $self->_result_summary( $report, $ended );
      $self->_append_log( $repo, $self->_result_line( $report, $ended ) );
    }

    # Common error we can observe (bad exit, timeout, a report that says so, or
    # a known output pattern): don't penalize any task — leave the board
    # untouched and back off. What the run *did* is asked before what it
    # *printed* (#160): a run that exited 0 and moved the board did work,
    # whatever text went past on the way, and re-reading its own transcript is
    # the one way to lose that work — the drain aborted, the progress was
    # credited to nobody, and the cooldown climbed on every following run
    # because the board still said the same words. So the output is evidence
    # only where there is nothing else: a run that produced no board movement
    # at all. The genuine case the scan exists for looks exactly like that,
    # because an agent that hit a rate limit or a dead key could not move
    # anything.
    #
    # A report is not in that ordering at all, and this is the one place to be
    # careful not to invert it. The guard above protects the run from an
    # *inference*: a word search over megabytes the agent printed, which cannot
    # tell the agent's report from the board's own contents. A field in the
    # agent's own result object is not an inference, so it ranks with the exit
    # code rather than with the scan — and where there is a report, the scan
    # does not run at all. That is the whole point: an agent that prints a
    # backlog full of 503s and then reports success is a success.
    my $err;
    if ( $report ) {
      $err = $rerr;
      # A non-zero exit the report does not account for is still an error: the
      # report is claude's, the exit code may be the wrapper's, and a report of
      # success says nothing about a pipeline that failed after it (or about
      # the 128+SIGTERM the runner synthesizes for a run it had to kill). A
      # report that *does* carry an error flag has already accounted for it,
      # which is what lets a spent turn budget — claude exits 1 on
      # error_max_turns — stop parking the board for an hour.
      $err //= "exit=$exit" if $exit != 0 && !$report->{is_error};
    }
    elsif ( $exit != 0 ) {
      $err = "exit=$exit";     # or -1, the timeout — a hard signal, no scan
    }
    else {
      my $seen = $self->_match_error( $output, $patterns );
      if ( defined $seen && $progressed ) {
        # Worth saying once: an agent that reports a rate limit and still gets
        # a card moved is on its last legs, and the operator should hear it
        # from the log rather than from the next run's cooldown.
        $self->_append_log( $repo,
          "NOTE '$seen' in output, but the board moved -- not treated as an error" );
      }
      else {
        $err = $seen;
      }
    }

    if ( defined $err ) {
      # An exit-0 run that is thrown away is the surprising one; .karr.state
      # would otherwise carry last_exit: 0 next to last_error with nothing
      # anywhere saying why the run did not count.
      my $why = $exit == 0 ? " -- agent exited 0, run discarded" : '';
      $self->_append_log( $repo, "COMMON-ERROR $err$why" );
      $self->_state_set( $repo, last_error => $err );
      $outcome = 'common-error';
      $error   = $err;
      last;
    }

    my %after = $self->_task_states( $repo );
    $self->_note_engagement( $repo, $eng );

    my @stuck;
    if ( defined $ticket ) {
      # A ticket-mode run is judged by its own card, not by the board hash: an
      # agent that ignored its assignment and moved something else did move the
      # board, and calling that progress would tell the coordinator its ticket
      # was worked when it was not.
      if ( $self->_ticket_moved( \%before, \%after, $ticket ) ) {
        $outcome = 'progress';
      }
      else {
        $outcome = 'stall';
        # Which stall it was. "The agent reports it cannot proceed" and "the
        # agent did nothing" both end as a card that did not move, and until a
        # run reported for itself there was nothing to tell them apart with
        # (#187). Ticket mode is the caller that wants the difference most: it
        # is the one place foundation already knows what the run was supposed
        # to be about, so the only thing missing was what the agent made of it.
        $self->_append_log( $repo,
          "STALL task#$ticket -- " . $self->_stall_reason( $report, $ended ) );
        # foundation assigned this card, so it needs no activity-log evidence
        # that the agent engaged it -- the assignment is the evidence, and the
        # counter it bumps is foundation's own .karr.state. The auto-block a
        # few lines below is the destructive half, and that one keeps #158's
        # ownership guard: a card somebody else took during the run is never
        # blocked on our say-so.
        @stuck = ( $ticket )
          if $self->_agent_holds( $after{$ticket}, $eng->{claims} );
      }
    }
    else {
      $outcome = 'progress' if $progressed;
      @stuck = $self->_stuck_tasks( \%before, \%after, $eng );
    }

    # Reset the attempt counter for any task that is no longer stuck
    # (advanced, blocked, or gone), then bump/auto-block the stuck ones.
    my %is_stuck = map { $_ => 1 } @stuck;
    my $attempts = $self->_state_get( $repo, 'attempts' ) // {};
    $self->_reset_attempts( $repo, $_ ) for grep { !$is_stuck{$_} } keys %$attempts;

    for my $id ( @stuck ) {
      my $n = $self->_bump_attempts( $repo, $id );
      next if $n < $max_attempts;
      $self->_autoblock_task( $repo, $id,
        "auto-block: no progress after $n attempts (foundation)",
        $eng->{claims} );
      $self->_reset_attempts( $repo, $id );
    }

    # Agent did nothing useful and grabbed nothing — stop, nothing to attribute.
    # Not in ticket mode: there the run has already been judged against its own
    # card, and a stall foundation may not penalize (somebody else holds the
    # card now) is still a stall, not a run that found nothing to do.
    if ( !defined $ticket && !$progressed && !@stuck ) {
      $outcome = 'idle';
      last;
    }

    last unless $drain;   # single / ticket mode → one run and return
  }

  return {
    outcome => $outcome,
    exit    => $last_exit,
    ticket  => $ticket,
    report  => $last_report,
    error   => $error,
  };
}

# A ticket-mode stall, said in the terms a coordinator asks in. Without a
# report there is nothing to say and it says so, rather than guessing: an agent
# that produces no structured result is exactly the case foundation has no
# information about, and inventing a reason for it is how the text scan got
# into trouble in the first place (#160).
sub _stall_reason {
  my ( $self, $report, $ended ) = @_;
  return 'no report from the agent' unless defined $ended;
  return 'the agent ran out of turns'  if $ended eq 'max turns';
  return "the agent ended with $ended" if $ended ne 'success';
  return 'the agent reported success but the card did not move';
}

# Did the assigned card come out of the run different from how it went in?
# Gone, no longer actionable (done, blocked), or its blob rewritten — status or
# updated, the same two fields _stuck_tasks compares, so a claim, a status
# change and an appended note all count. Everything else is a run that did not
# touch its own ticket.
sub _ticket_moved {
  my ( $self, $before, $after, $id ) = @_;
  my $a = $after->{$id} or return 1;
  return 1 unless $self->_is_actionable( $a );
  my $b = $before->{$id} or return 1;
  return 1 if ( $b->{status}  // '' ) ne ( $a->{status}  // '' );
  return 1 if ( $b->{updated} // '' ) ne ( $a->{updated} // '' );
  return 0;
}

# ---------------------------------------------------------------------------
# Run mode / ticket selection
# ---------------------------------------------------------------------------

# What a run of this repo is: 'drain' (loop until the board stops moving, the
# historical default), 'single' (exactly one agent run, agent picks its own
# work) or 'ticket' (exactly one agent run, about a card foundation names).
#
# 'drain: true|false' said two thirds of this before there was a third answer,
# and it stays honoured rather than being deprecated into a warning: it is
# written in .karr files this foundation does not own. Two keys that both mean
# "one run" would be the trap, so they are one key with an alias, not two
# switches: 'mode' is asked first and 'drain' only answers when 'mode' is
# absent. Per-repo before global, as everywhere else here — a repo that says
# 'drain: false' means it against a config-wide 'mode: ticket', because the
# .karr file is the more specific statement.
sub _run_mode {
  my ( $self, $karr ) = @_;
  my $mode = $karr->{mode};
  unless ( defined $mode ) {
    return $karr->{drain} ? 'drain' : 'single' if exists $karr->{drain};
    $mode = $self->_config_data->{mode};
  }
  return 'drain' unless defined $mode;
  # A typo here is not a small mistake: 'ticekt' silently draining a board is
  # the opposite of what was asked for, on every tick, quietly. The caller
  # (_process_repo) turns this into a warning and skips the repo.
  user_error("Unknown mode '$mode' (expected: drain, single or ticket)")
    unless $mode eq 'drain' || $mode eq 'single' || $mode eq 'ticket';
  return $mode;
}

# The card a ticket-mode run is about, or undef when the board has none to
# give. Selection is a read: nothing is claimed and nothing is locked here —
# see App::karr::Foundation::Picker for why the claim stays the agent's.
sub _select_ticket {
  my ( $self, $repo ) = @_;
  my $git = App::karr::Git->new( dir => "$repo" );
  return undef unless $git->is_repo;
  my $store = App::karr::BoardStore->new( git => $git );
  return App::karr::Foundation::Picker->new( store => $store )->next_ticket;
}

# ---------------------------------------------------------------------------
# Auto-block (in-process via BoardStore, no karr CLI)
# ---------------------------------------------------------------------------

# $claims is the set of claim names this run's agent wrote under (see
# _note_engagement). The ownership test is repeated here, at the write itself,
# rather than trusted from _stuck_tasks: this is the one place that mutates
# somebody's card and pushes it, the board may have changed since the snapshot
# the caller decided on, and any future caller inherits the guarantee instead
# of having to remember it (#158).
sub _autoblock_task {
  my ( $self, $repo, $id, $reason, $claims ) = @_;
  return if $self->dry_run;
  my $git = App::karr::Git->new( dir => "$repo" );
  return unless $git->is_repo;
  my $store = App::karr::BoardStore->new( git => $git );
  my $task  = $store->find_task( $id ) or return;
  unless ( $self->_agent_holds(
      { claimed_by => ( $task->has_claimed_by ? $task->claimed_by : undef ) },
      $claims ) ) {
    $self->_append_log( $repo,
      "AUTOBLOCK-SKIP task#$id: claimed by " . $task->claimed_by );
    return 0;
  }
  $task->block( $reason );
  $store->save_task( $task );
  $git->push;   # best-effort propagate to remote
  $self->_append_log( $repo, "AUTOBLOCK task#$id: $reason" );
  return 1;
}

# ---------------------------------------------------------------------------
# Log file
# ---------------------------------------------------------------------------

sub _append_log {
  my ( $self, $repo, $msg ) = @_;
  my $ts  = localtime->strftime('%Y-%m-%dT%H:%M:%S');
  my $line = "[$ts] $$: $msg\n";
  print $line if $self->verbose;
  return if $self->dry_run;
  $repo->child('.karr.log')->append_utf8( $line );
}

sub _say_verbose {
  my ( $self, $msg ) = @_;
  print "$msg\n" if $self->verbose;
}

# ---------------------------------------------------------------------------
# .karr file
# ---------------------------------------------------------------------------

sub _load_karr {
  my ( $self, $repo ) = @_;
  my $karr_file = $repo->child('.karr');
  return {} unless $karr_file->exists;
  my $data = try {
    YAML::XS::LoadFile("$karr_file");
  } catch {
    warn "karr-foundation: cannot parse $karr_file: $_\n";
    {};
  };
  return ref $data eq 'HASH' ? $data : {};
}

# ---------------------------------------------------------------------------
# Agent command resolution
# ---------------------------------------------------------------------------

# What this repo runs, as ( $command, $invocation ). $command is the shell
# string, or undef when no agent is configured at all. $invocation is set only
# where the command came from a B<named> agent definition (see
# L<App::karr::Foundation::Agents>) and carries its name, kind and live-output
# rendering; it is undef for every other source, which is what keeps a board
# that knows nothing about agent definitions behaving exactly as before -- no
# availability is recorded against it, and nothing is appended to its command.
#
# Priority: CLI --command > config default_command > .karr command >
# .karr agent > the assignment (#210) > config default_agent >
# 'claude: true' shorthand.
#
# The third return value is a reason to WAIT: the assignment routes this board
# and every agent it names is currently failing, or it says WAIT outright. That
# is not "no agent configured" and must not read as one -- the board runs
# nothing this tick and runs again when an agent it is allowed to use comes
# back.
#
# A named agent sits below the literal command strings and above the claude
# shorthand: `command:` is the most specific thing a board can say (it is a
# whole invocation, written out), while `claude: true` is the oldest and least
# specific. A .karr `agent:` beats the config's `default_agent` for the same
# reason every other key here does -- the board is the more specific statement.
sub _resolve_agent {
  my ( $self, $repo, $karr ) = @_;
  my $cfg = $self->_config_data;

  for my $candidate ( $self->command, $cfg->{default_command}, $karr->{command} ) {
    return ( $candidate, undef ) if defined $candidate && length $candidate;
  }

  # The assignment (#210), between the board's own `agent:` and the fleet-wide
  # `default_agent`. A board that names an agent has said the most specific
  # thing there is to say about itself and is not routed; a board that has not
  # is exactly what the coordination agent's routing table is for, and that
  # table is per repository, so it beats a default that is per fleet.
  #
  # Three answers, and only the first two are this method's business: an agent
  # to run, a reason to wait (returned as the third value -- a board whose
  # chain is exhausted or says WAIT runs nothing this tick and is NOT the same
  # as a board with no agent configured), or nothing, in which case resolution
  # carries on exactly as it did before there was an assignment at all.
  my $named = $karr->{agent};
  unless ( defined $named && length $named ) {
    my $routed = $self->_coordinator->route( $repo );
    return ( undef, undef, $routed->{wait} ) if $routed && defined $routed->{wait};
    $named = $routed->{agent} if $routed && defined $routed->{agent};
    $named //= $cfg->{default_agent};
  }
  if ( defined $named && length $named ) {
    # An unknown name raises: a typo here is not a small mistake. Silently
    # falling back to no agent would park the board for good and say nothing,
    # which is what `mode:` refuses to do for the same reason. _process_repo
    # runs inside run()'s per-repo try, so this warns and skips one board.
    my $inv = $self->_agents->invocation( $named );
    return ( $inv->{command}, $inv );
  }

  my $claude = exists $karr->{claude} ? $karr->{claude} : $cfg->{claude};
  return ( $self->_claude_command($karr), undef ) if $claude;

  return ( undef, undef );
}

# The resolved agent command string, or undef when no agent is configured.
sub _agent_command {
  my ( $self, $repo, $karr ) = @_;
  my ( $cmd ) = $self->_resolve_agent( $repo, $karr );
  return $cmd;
}

# Synthesize the canonical claude invocation behind 'claude: true'. The $PROMPT
# variable is substituted from $ENV{PROMPT} at run time (see _run_command), so
# users never retype the long flag set. claude_bin / claude_max_turns /
# claude_permission_mode override the defaults (per-repo, then global).
sub _claude_command {
  my ( $self, $karr ) = @_;
  my $cfg = $self->_config_data;
  my $bin   = $karr->{claude_bin}             // $cfg->{claude_bin}             // 'claude';
  my $turns = $karr->{claude_max_turns}       // $cfg->{claude_max_turns}       // 30;
  my $perm  = $karr->{claude_permission_mode} // $cfg->{claude_permission_mode} // 'bypassPermissions';
  return qq{$bin -p "\$PROMPT" --permission-mode $perm --max-turns $turns};
}

# The agent instruction exposed as $PROMPT. .karr 'prompt' > config
# 'default_prompt' > the built-in default.
#
# With a $ticket the built-in default changes (the ordinary one opens by
# telling the agent to pick its own work) and the assignment sentence is
# appended to whatever prompt was resolved. Appending rather than replacing
# keeps a configured prompt doing its job — it is usually about which skill to
# use and how to report — while the last sentence, which is the one that wins
# with a language model, is the one naming the card. Without this the mode
# would be `drain: false` with extra steps: the agent would never learn which
# ticket it was given.
sub _prompt_for {
  my ( $self, $karr, $ticket ) = @_;
  my $configured = $karr->{prompt} // $self->_config_data->{default_prompt};
  return $configured // $DEFAULT_PROMPT unless defined $ticket;
  return ( $configured // $DEFAULT_TICKET_PROMPT ) . "\n\n"
       . sprintf( $TICKET_ASSIGNMENT, $ticket );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::karr::Foundation - Single-shot foundation daemon -- periodic agent execution across karr boards

=head1 VERSION

version 0.601

=head1 SYNOPSIS

    # Typical cron entry -- run every 5 minutes
    */5 * * * * /path/to/karr-foundation

    # Force a run regardless of board state
    karr-foundation --force

    # Preview what would run
    karr-foundation --dry-run --verbose

    # Read-only overview of every board (no agent runs)
    karr-foundation --status

    # Write the fleet's plan into the hub, and execute it out of there
    karr-foundation plan < chain.yml
    karr-foundation chain

=head1 DESCRIPTION

F<karr-foundation> is a single-shot, idempotent CLI meant to be invoked
periodically (cron, systemd-timer, while-loop). It scans configured karr
boards, detects changes or open work, and B<drains> each board by invoking the
configured agent command repeatedly until no actionable task remains.

B<Using this class as a library.> F<bin/karr-foundation> is what most callers
run, and it is also where karr's character/octet boundary gets set up (see
L<App::karr::Encoding>) before any command code runs: a C<:encoding(UTF-8)>
layer goes on C<STDOUT>/C<STDERR>, and C<@ARGV> is decoded before
C<new_with_options> reads it into option values. This class does not repeat
either step -- both are the program's decision, not one a class it merely
loads should make for it (see L<App::karr::Encoding/enable_std_utf8> and
L<App::karr::Encoding/decode_argv>). A caller that loads
C<App::karr::Foundation> directly, instead of invoking that script, is
responsible for both:

    use App::karr::Encoding qw( decode_argv enable_std_utf8 );

    enable_std_utf8();
    decode_argv();
    App::karr::Foundation->new_with_options->run(@ARGV);

Skipping the handles does not fail outright: every fixed message this class
prints or warns is plain ASCII (ticket #214). What it does not cover is data
-- a non-ASCII repo path folded into a C<skip $repo -- $wait> line, or a YAML
error carried through C<clean_error> into a C<warn> -- which still risks
C<Wide character in print>/C<warn> the first time it reaches a handle nobody
configured. Skipping C<@ARGV> is quieter, not safer: option values built from
it hold raw UTF-8 octets instead of decoded characters, with no warning to
say so.

B<Config file:> C<~/.config/karr-foundation/config.yml> (or C<--config>).

  dirs:
    - /path/to/repo1
    - /path/to/repo2

  scan:
    - /path/to/parent-dir   # finds all direct subdirs that have a .karr file

  concurrent: 4             # boards that may have an agent at once (default: 1)
  hub: /path/to/hub-repo    # the repository carrying refs/karr-foundation/*
  routing: >-               # prose for the coordination agent, never parsed
    minimax is cheap; never hand it a release.

B<Per-repo .karr file:>

  claude: true              # synthesize the canonical claude command (opt-in)
  claude_bin: claude        # binary for claude: true (default: claude)
  claude_max_turns: 30      # --max-turns for claude: true (default: 30)
  claude_permission_mode: bypassPermissions   # (default: bypassPermissions)
  prompt: >-                # agent instruction, exposed as $PROMPT
    Use the karr-coordinator skill: pick the next actionable task and move it.
  command: claude -p "$PROMPT"   # explicit command; wins over claude: true
  on_idle: skip             # 'skip' (default) | 'always-run'
  max_runtime: 1800         # seconds: per-command SIGKILL (0 = no limit)
  mode: drain               # drain (default) | single | ticket
  drain: true               # older spelling of mode: true=drain, false=single
  max_attempts: 2           # stalls on one task before auto-block (default: 2)
  max_iterations: 50        # hard cap on drain iterations (default: 50)
  cooldown_base: 1          # cooldown minutes at level 0 (default: 1)
  cooldown_max: 64          # cooldown ceiling in minutes (default: 64)
  error_patterns:           # extra case-insensitive substrings -> common-error
    - my custom api error   # (added to the defaults; matched as written)
  on_drained: ./release-gate.sh   # run when the board has no work left
  on_drained_max_runtime: 1800    # seconds for that command (0 = no limit)
  on_drained_max_rounds: 3        # see "The domain hook" (0 = no cap)

  agent: minimax            # a named agent from the config's 'agents:' section

C<claude>, C<claude_bin>, C<claude_max_turns>, C<claude_permission_mode>,
C<command>, C<mode>, C<on_drained>, C<on_drained_max_runtime>,
C<on_drained_max_rounds> and C<prompt>/C<default_prompt> may also be set
globally in the config file; the per-repo F<.karr> value wins.

B<Named agents.> A board has one C<command>. A fleet has several agent commands
with different strengths and different failure modes, so the config can name
them and a board can pick one:

  agents:
    minimax:
      command: claude_with_minimax
      kind: claude-code       # the invocation contract; default: shell
      probe_every: 15m        # optional -- see "Agent availability" below
      permission_mode: bypassPermissions    # kind: claude-code only
      max_turns: 30                         #   "     "        "
      allowed_tools: [ Bash, Edit ]         #   "     "        "
      concurrent: 2           # runs of THIS agent at once -- see "Concurrency"
      description: >-
        Prose. What this agent is good at, where it is weak, what it costs.
    planner:
      command: claude
      kind: claude-code
      role: coordinator     # the fleet's judgement layer -- see below

  default_agent: minimax    # for boards whose .karr names none
  probe_every: 10m          # fleet-wide default for agents that name none

C<description> is never read by karr. It is carried for the agent that routes
work across the fleet: the thing choosing is a language model, and it reads
prose better than it matches taxonomies, so there are no classes and no enums
here. C<karr-foundation --status --verbose> prints it.

Agent definitions are B<local and only local>. They are not board state and
never sync: an agent command that exists on one machine does not exist on the
next, and an account limit is a property of a person, not of a project.

C<agent:> resolves below the literal command strings and above C<< claude:
true >> -- the full order is C<--command>, C<default_command>, the F<.karr>
C<command>, the F<.karr> C<agent>, the B<assignment> (see "The coordination
agent" below), C<default_agent>, C<< claude: true >>. A board that names an
agent the config does not define is an error that skips B<that board>, not one
that silently stops running.

B<Invocation contracts.> C<kind> says what karr may append to a definition's
C<command>:

=over 4

=item * C<shell> (the default) - the command is a complete shell template and
karr appends B<nothing>. This is what a F<.karr> C<command> has always been:
karr cannot know what the thing at the other end understands.

=item * C<claude-code> - karr appends C<-p "$PROMPT">, an output format, and
C<--permission-mode>, C<--max-turns> and C<--allowed-tools> from the
definition. Permission escalation is therefore a property of the agent
definition rather than something baked into a wrapper script.

=back

The output format is C<stream-json --verbose --include-partial-messages>, not
plain C<json>, and that is the one deliberate choice in this contract. karr
needs the run's own report (see "The run's own report" below), which only a
structured format emits -- but plain C<json> prints B<nothing at all> until the
run ends, which would silently cancel the live output promised under "Live
output" below on exactly the runs that take half an hour. C<stream-json> ends
with the same result object and streams on the way, so
L<App::karr::Foundation::Runner> renders the assistant's text out of it for the
terminal and F<.karr.log> while the raw stream is what the run is classified
from. The ticket of a C<< mode: ticket >> run is B<not> appended: claude-code
has no flag for it, so the id keeps travelling as a closing sentence in
C<$PROMPT> and as C<$KARR_TASK>.

B<Agent availability.> karr keeps the least it can per named agent: C<ok>, or
C<failing> since a moment with a next attempt due at another. No cost, no
tokens, no quotas -- a rate limit and an exhausted budget look identical from
the outside (the command stops working), so B<one> mechanism covers both, and
every other reason a command can stop working comes along for free.

A drain that ends in a C<common-error> marks its agent failing; any other
outcome says it works. While an agent is failing, B<every> board that uses it
is skipped -- the fact is about the command and the machine, not about a
repository, so two boards on one agent share the outage instead of each burning
a window rediscovering it. That is a level above the per-board cooldown, which
keeps working exactly as before underneath it. Like the cooldown, C<--force>
does not override it; the wait is bounded by C<probe_every> and ends by itself.

When the next attempt comes round the agent is simply run again on the work
that was waiting: the probe B<is> the run. Where the reset rhythm is known it
is configured as C<probe_every>; where it is not, the retry is at a fixed
interval and every recovery is B<recorded> -- from when it broke to when it
worked again, with what it looked like. Reading a pattern out of those records
is the coordination agent's job, never a learning algorithm inside karr.

The record lives beside the config file that defines the agents
(F<agents.state> next to F<config.yml>, so C<--config> relocates it), because
it belongs to neither of the two obvious places: F<.karr.state> is per
repository and this is not, and the board's own config syncs, which would push
one person's spent limit at everybody else's fleet.

B<Concurrency.> By default F<karr-foundation> works one board at a time, which
is what it has always done. C<concurrent:> in the config raises that ceiling,
and three levels bound what actually runs -- B<the tightest one wins>
(L<App::karr::Foundation::Limits>):

=over 4

=item * C<concurrent:> in the config -- the B<machine ceiling>. It protects
this box's CPU and memory and is not a quota; it says nothing about what any
account may spend. Default C<1>.

=item * C<concurrent:> on a named agent definition -- the B<operator's
estimate> of where that agent's session limit sits. It is a guess and is
allowed to be wrong: being wrong makes the agent start failing, which marks it
so (see "Agent availability" above), skips every board on it for one probe
interval, and lets the fallback take over.

=item * C<limits:> in the chain header, for the fleet's current plan:

    limits:
      concurrent: 4
      per_agent:
        minimax: 2

The names under C<per_agent> are agent definition names. One this machine does
not define is dropped with a verbose note rather than refused -- agent
definitions are local and only local, so a chain written where C<minimax>
exists reaching a machine where it does not is the expected case.

=back

One hard rule stays: B<one agent per repository>. The unit of concurrency is
one board, run by one forked child that owns that board's F<.karr.lock> for the
length of its drain. Two agents in one working tree would collide over the
index and the checkout, so concurrency is across repositories and never inside
one; anything else would need a git worktree per agent and is deliberately out
of scope. Several ticks knocking at the same board at the same time is the case
F<.karr.lock> already answered (#162) and still answers: the C<flock(2)> admits
exactly one.

A signal to F<karr-foundation> takes every running agent with it. The parent
sends C<SIGTERM> to its children and each child runs the same shutdown path a
serial run does -- C<TERM> then C<KILL> to its agent's process group (#148),
then release its lock -- rather than being killed outright, which would leave
every agent reparented to init.

C<--dry-run> stays serial whatever the ceiling says: it starts no agent, so
concurrency would buy nothing and cost its output the order it is read in.

B<The hub.> C<hub:> names the one repository of a fleet that carries
C<refs/karr-foundation/*> -- the chain of planned steps and the run logs
(L<App::karr::Foundation::ChainStore>). That namespace is pulled once at the
start of a run, before anything reads it, so the limits a tick applies are the
fleet's current ones and not whatever this machine last happened to fetch. An
ordinary tick pushes nothing back: it reads the chain header for those limits
and writes no step state. Executing the chain is C<karr-foundation chain>, a
command of its own (see below), and that one does write and does push.

B<Running the chain.> C<karr-foundation chain> is the VM of the design's
"the AI is the compiler, the chain is the program": it takes the steps the plan
says are ready, checks each precheck against facts it measures, runs
C<kind: ticket> steps through B<ticket mode> in the target repository and
C<kind: shell> steps as a command under that repository's own lock, and writes
each step's state and the run log back to the hub.

It is deliberately B<not> a fourth C<mode:> beside C<drain>, C<single> and
C<ticket>. Those are per-repository settings and the chain is fleet-wide, so a
C<mode: chain> in a F<.karr> file could not answer the only question the chain
poses -- which step of the DAG is next. The executor is therefore the caller of
those modes, and a chain step inherits the board lock, the claim discipline, the
ownership guard and the run's own report from the mode it calls rather than
carrying a second copy of them.

It is also a command rather than something an ordinary tick does on the side:
C<karr-foundation> with no arguments has meant "drain the boards in my config"
for as long as it has existed, and picking the chain up automatically would have
changed what every cron entry in a fleet does on the day somebody wrote one.

  karr-foundation chain              # execute what is ready
  karr-foundation chain --dry-run    # list the ready set and its verdicts

With no C<hub:> configured this is an error and not a quiet no-op, exactly as
the mailbox commands are: the chain is fleet state, and executing a plan nobody
else can see is not a smaller version of executing the fleet's plan. With a hub
but no chain written, it says so and returns C<0> -- a fleet nobody has planned
for yet is a normal state, not a failure. The full argument, the fact vocabulary
a precheck may use and what a failed step does to the DAG are in
L<App::karr::Foundation::Executor>.

B<Writing the chain.> C<karr-foundation plan> is the other half of that
command: it reads a chain as one YAML document on stdin -- or out of the file
C<--input> names -- and replaces what the hub holds with it.

  karr-foundation plan < chain.yml            # replace the chain
  karr-foundation plan --dry-run < chain.yml  # check it, write nothing

  steps:
    - id: 1
      kind: ticket
      repo: /srv/karr
      ticket: 41
      precheck: ticket_status == todo
    - id: 2
      kind: shell
      repo: /srv/karr
      needs: [ 1 ]
      command: ./release-gate.sh
  limits:
    concurrent: 2
  note: what this plan is for

A document rather than options, because a chain is a DAG and a DAG is nested:
options that described one would be YAML with a worse syntax and a parser of
its own, and the writer that matters most -- the coordination agent -- already
produces structure. JSON is read by the same parser and needs no flag of its
own. A bare list of steps is a document too: that is what
L<App::karr::Foundation::ChainStore/write_chain>'s own first argument looks
like, so a planner that wrote only steps wrote a whole document.

It B<replaces> the chain rather than adding to it, which is what the header
already means: only steps whose chain id matches the header are ever ready, so
appending would be a new chain over the old steps plus the new ones, with a
merge policy of its own for an id that is already there and a state that has
already been reached. The plan is what the planner currently thinks. What makes
replacing safe is the guard: a chain that still has a step in state C<running>
is refused unless C<--force>, and the whole document -- every step, the ids,
the edges, the cycle check -- is validated before the first ref is written, so
a chain karr will not take leaves the one in the hub exactly as it was
(L<App::karr::Foundation::ChainStore/validate_chain>).

The command is what an agent gets because everything else karr asks an agent to
do is a command. Before it, writing a chain was C<write_chain> from Perl and
the coordination agent was handed that one-liner in its prompt to type out --
the one place karr gave an agent Perl instead of a call, where a rename in a
storage class broke a prompt and nothing said so (#213).

B<The question mailbox.> A question is a file with an answer field, not a
dialogue, which is what removes the special case for "a human happens to be
present". C<karr-foundation ask> writes one into the hub and returns; the chain
carries on with everything that does not depend on it, and only the steps that
do wait. Whoever answers -- a person at a terminal, a chat bridge, the
coordination agent -- types C<karr-foundation answer ID ANSWER> and needs to
know nothing about the chain. One mailbox, many writers.

  karr-foundation ask "Which registry do we publish to?" \
      --context "the release gate is waiting" \
      --options cpan,darkpan --default cpan --policy use_default --wait 3600

  karr-foundation answer 7 darkpan --note "this release is a private one"

C<--policy> is what happens when nobody answers: C<block> (the default: wait),
C<use_default> (C<--default> becomes the answer once C<--wait> has passed) or
C<escalate_to_ai> (the coordination agent decides). Both commands sync the fleet
namespace around what they write, and C<--status> lists the open mailbox with
the id each one is answered by. The storage, the retention and the argument for
why an answer is its own ref rather than a field in the question are in
L<App::karr::Foundation::Questions>.

B<The coordination agent.> The third layer of the design and the only one that
is an AI: coordination is shared state in refs, execution is local, and
B<judgement> -- planning, routing, reacting to what nobody planned for -- is an
agent. It is an agent like every other one: an entry in C<agents:>, invoked
through its own C<command> under its own C<kind> contract, classified from its
own result object, and marked C<failing> by the same availability record. What
sets it apart is B<when> it runs, which is never in the hot path.
F<karr-foundation> works through written plans by itself and calls this one only
where a plan is missing or has broken. Between two of those, no AI runs at all,
and that is what makes the arrangement affordable.

Which agent it is, is a marker on the definition:

  agents:
    planner:
      command: claude
      kind: claude-code
      role: coordinator

and not a second config key naming an agent that is already named. Two marked
definitions are refused rather than guessed between; C<< role: >> with anything
else in it is a config error, because a typo there would leave a fleet with no
judgement layer at all and say nothing about it.

There are four deviations, and every one of them was already a place that
recorded "the planner is wanted" and nothing else: a C<kind: plan> step, a
question past its deadline whose policy is C<escalate_to_ai>, a step whose
precheck no longer holds (stale), and a repository the assignment cannot route.
The first three come out of the chain executor, the fourth out of agent
resolution. A tick collects them and makes B<one> call at the end of itself,
carrying all of them: a tick that met five deviations has learned one thing --
the plan is out of date -- and five calls would pay five times to hear it. The
call is last because a planner called half way through would be planning
against a board the tick was still moving, and nothing is re-read afterwards:
what it wrote is what the B<next> tick runs.

The run happens in the hub, under the hub's own F<.karr.lock> (one agent per
repository holds there as everywhere), with C<KARR_ROLE=coordinator> so its own
C<karr> writes stay out of a board agent's activity log, and with its
instruction in C<$PROMPT>: the deviations, where the fleet's files are, the
agent list with each one's availability and prose, and the operator's own prose
from the config's C<routing:> key. That prose is the routing criterion and karr
never parses it -- the thing choosing is a language model, and it reads better
than it matches taxonomies.

B<The assignment> is what it writes so that routing needs no AI afterwards:

  repos:
    /path/to/repo:
      - minimax
      - claude
      - WAIT

Repository path to an ordered list of agents, with an explicit C<WAIT> for
"rather wait than use anything further down". F<karr-foundation> looks the
repository up and takes the first entry that currently works; a chain that
reaches C<WAIT>, or whose agents are all failing, means the board runs nothing
this tick and says so (C<agent-waiting> in the overview) rather than reading as
a board nobody configured. C<--force> does not override that, for the same
reason it overrides neither the cooldown nor an agent's availability: the wait
is bounded and ends by itself. It sits below a board's own C<agent:> -- a board
that names one has said the most specific thing there is to say about itself --
and above C<default_agent>, which is per fleet where this is per repository.

Like the agent definitions it names, the assignment is B<local and never in
refs>: an agent command that exists on one machine does not exist on the next,
so a table naming agents cannot be shared any more than they can. It lives
beside F<agents.state> and the config, as F<assignment.yml>, and follows
C<--config> with them. A fleet that marks no coordinator behaves exactly as it
did before any of this existed -- the deviations are printed, and the operator
is the planner. The details are in L<App::karr::Foundation::Coordinator>.

B<Run mode.> C<mode> says what one pass over a repo is:

=over 4

=item * C<drain> (the default) - run the agent again and again until the board
stops moving. This is what F<karr-foundation> has always done and what
"Drain semantics" below describes.

=item * C<single> - exactly one agent run; the agent still chooses its own work.

=item * C<ticket> - exactly one agent run, about B<one card foundation names>.

=back

C<< drain: true|false >> is the older spelling of the first two and stays
honoured: C<true> means C<drain>, C<false> means C<single>. Two keys that both
meant "one run" would be a trap, so they are one key with an alias rather than
two switches -- C<mode> is asked first, C<drain> answers only when C<mode> is
absent, and a per-repo C<drain> still beats a config-wide C<mode>. An
unrecognised C<mode> is an error that skips the repo, never a silent fallback
to draining it.

B<Ticket mode.> Before the agent starts, foundation picks the card the run is
about -- L<App::karr::Foundation::Picker>, applying C<karr pick>'s eligibility
and ranking (not terminal, not blocked, not held by a live claim; class, then
priority, then id). It is told to the agent twice: spliced into C<$PROMPT> as a
closing sentence naming the id, and exported as C<$KARR_TASK> for a command
template that wants the bare number. Nothing is appended to the command itself
-- how arguments are appended belongs to the per-agent contract (C<kind:>),
which is a separate piece of work, and an environment variable works with every
template that exists today.

Foundation names the card; it does B<not> claim it. The claim is the agent's
work session, minted with C<karr agentname> and reused across its own C<move>
and C<handoff> (#176), and the board's per-repo lock plus the one-agent-per-
repository rule already keep anybody else off the card for the length of the
run. So an agent that dies mid-work leaves at most its own claim -- released by
C<claim_timeout>, or by C<karr unlock> for a pick lock -- and costs one attempt
on foundation's counter.

The run is then judged by that card and not by the board hash: C<progress> when
it moved (status, claim or C<updated> changed, or it left the actionable set),
C<stall> when it did not, whatever else on the board did move. A stall bumps
the card's attempt counter and auto-blocks it at C<max_attempts>, under the same
ownership guard as a drain -- a card somebody else took during the run is never
blocked on foundation's say-so. With no assignable card at all, ticket mode runs
B<no agent>, logs C<TICKET none assignable>, and returns C<idle>; C<--force> and
C<< on_idle: always-run >> force the check, not a run without a card.

B<Board-level disable.> A board can opt out of automated agent runs in its own
karr state -- C<foundation.enabled> in C<refs/karr/config>, set with
C<karr disable [--reason "why"]> and cleared with C<karr enable>. Because the
flag is board state it syncs with the board, so every foundation instance on
every machine honours it. A disabled board is skipped B<whole>: the flag is
checked before the agent command is resolved and before the drain decision, so
there is no drain, no auto-block and no agent run. It therefore wins over
C<--command>, the config's C<default_command>, the F<.karr> C<command> and
C<< claude: true >>, and C<--force> does B<not> override it. Use it for a
repository whose backlog is parked (an abandoned project kept for reference)
that a globally configured C<default_command> would otherwise drain. C<--status>
shows such a board with a C<disabled> flag and its reason.

B<The domain hook.> When a board has drained, C<on_drained> runs a configured
command in it. B<karr does not know what that command does, and must not.> In
the fleet this design came from it starts a release gate that builds a
distribution, installs it, tests every dependent against it and raises version
requirements -- none of which belongs in a kanban tool, and all of which would
otherwise arrive here as rules about what an exit code means. So the exit code
is written to F<.karr.log> and F<.karr.state> and interpreted by nobody: a hook
that fails does not park the board, does not mark the board's agent failing,
and is never the run's C<last_error>. It is not an agent run and is not
classified as one -- no report is read out of it, no error pattern is matched
against it, no ticket is assigned to it.

It is told where it is and nothing else: C<KARR_REPO>, and C<KARR_ROLE=hook> so
that C<karr> writes of its own land in their own activity log rather than
counting as the agent's engagement with a card. C<PROMPT> is empty (the prompt
is the agent's instruction) and so is C<KARR_TASK>. It runs in the board's
directory, under the board's own F<.karr.lock>, with the same process-group
kill and the same tee to F<.karr.log> an agent gets -- a gate that backgrounds
a build must not outlive the run that started it -- but with its own budget,
C<on_drained_max_runtime>, because how long an agent may take says nothing
about how long a release gate may.

B<Drained> is a fact about the board, not a name for an outcome: no actionable
task is left on it -- everything done, archived or blocked. That is deliberately
the same question C<--force> and C<< on_idle: always-run >> are answers to, and
it is the only one that stays meaningful across the run modes. A drain that
ends in a C<common-error> does not count: a rate-limited agent leaves a board
that looks exactly like one it worked through, and foundation does not believe
that run itself.

B<An empty board is not the same as finished work.> The hook may fail and file
tickets, at which point the board is no longer drained; the next tick works
them, the board drains again, and the hook is asked again. That cycle is the
point -- a gate that reports what it found and is re-run once it is fixed is
what the hook is for -- so the two guards below bound it rather than forbid it:

=over 4

=item * B<The same board is not asked twice.> The board fingerprint the hook
last ran at is kept in F<.karr.state>; a board that has not moved since gets no
second run. Without this, a repository nobody touches would start a release
gate on every cron tick for ever, because a drained board stays drained.

=item * B<A chain that never settles is capped.> Every hook run that puts work
back on the board changes the fingerprint, so the first guard cannot see the
loop of "hook files a ticket, agent works it, board drains, hook files
another". Consecutive rounds in which the hook itself made work are counted;
a run that leaves the board alone -- the gate that finally passed -- clears the
count, and at C<on_drained_max_rounds> (default 3, C<0> disables) the hook is
suppressed with a line in F<.karr.log> saying so.

=back

C<--force> overrides both. They are statements about board state, which is what
C<--force> is documented to override, and unlike the cooldown and the agent
availability the cap is not time-bounded and does not end by itself -- so it
needs a way out, and the operator is it.

B<Coordinator and overview.> Agent execution is opt-in -- a board runs an agent
only via C<command>, a named C<agent> or C<< claude: true >>. When B<no> board
has an agent configured, the default action is a read-only B<overview> of every
board (status counts, in-progress/blocked tasks, lock and cooldown state, which
agent a board uses and whether it currently works); a human can use foundation
purely to coordinate their own work. C<--status> forces the overview regardless
of configuration.

B<Live output.> When run interactively (TTY) or with C<--verbose>, the agent's
output is streamed to the terminal in real time as foundation reads it; it is
always appended to F<.karr.log> regardless of TTY. To shape what is shown, the
command may emit stream-json and filter it, e.g.:

  command: >-
    claude -p "$PROMPT"
      --output-format stream-json --verbose --include-partial-messages
      --permission-mode bypassPermissions --max-turns 10
    2>&1 | jq -r 'select(.type == "stream_event") | .event.delta.text // empty'

Set C<max_runtime: 0> in F<.karr> to disable the per-run timeout entirely
(agent runs until completion with no SIGKILL).

B<Drain semantics.> Each iteration runs C<command> once, then classifies the
result from what foundation can observe -- the run's own report where it made
one, otherwise the exit code, board ref movement, and the run's captured
output:

=over 4

=item * B<progress> -- the board changed; keep draining.

=item * B<stall> -- a task B<this run's agent engaged> did not move. That task's
attempt counter is bumped; at C<max_attempts> it is auto-blocked
(C<blocked: auto-block: no progress after N attempts (foundation)>) so it drops
out of the actionable set and the drain can finish. The agent may always set a
better reason itself with C<karr edit --block>; the auto-block is a fallback.

B<Engaged> means foundation can prove the agent worked on that card during
B<this> drain: the agent runs with C<KARR_ROLE=agent>, so every C<karr> write
it makes is recorded in the board's own activity log under the C<agent>
identity, and only the tasks named there -- held by nobody, or by a claim name
the agent itself wrote under -- can be penalized. A card somebody else holds is
never touched, and neither is one the agent merely left claimed in an earlier
run: a stale claim is what C<claim_timeout> and C<karr unlock> are for. Where
that evidence is missing altogether -- an agent that does not write through
C<karr>, an unreadable log -- foundation auto-blocks B<nothing> rather than
guess: the drain then simply ends on its iteration cap, which is far cheaper
than blocking a human's in-progress card out from under them (#158).

=item * B<common-error> -- a non-zero/timeout exit, or an error pattern in the
output of a run that moved B<nothing> (rate limit, auth, network, 5xx, ...). No
task is penalized; the repo enters an exponential cooldown (C<cooldown_base> x
2^level minutes, capped at C<cooldown_max>, reset on the next clean run) and is
skipped until it expires.

What the run did is asked before what it printed: a run that exited 0 and moved
the board is progress whatever text scrolled past, and is never reclassified by
its own transcript. The scan is evidence only where there is no other -- a run
that produced no board movement at all, which is what a rate-limited or
unauthenticated agent looks like. A pattern seen in a run that B<did> move the
board is noted in F<.karr.log> and otherwise ignored.

The default patterns are correspondingly narrow: a symptom word counts next to
a failure word on the same line ("network error", "invalid credentials",
"quota exceeded"), not on its own, and an HTTP status counts only where
something adjacent marks it as one ("API error: 429", "429 Too Many Requests"),
not in a diffstat or a line number. Before this, an agent that printed its own
board tripped the scan on a backlog title, and a diffstat of 403 changed lines
tripped it on C<403> (#160).

=item * B<idle> -- the agent did nothing and grabbed nothing; stop.

=back

B<The run's own report.> An agent invoked with C<--output-format json> ends its
output with one line: a JSON object saying whether the run failed, how it
ended, how many turns it took, how long it ran and what it cost. Where a run
leaves one, foundation classifies from it and the text scan below does not run
at all.

Foundation is not configured for this and does not inspect the command string
for it -- it reads the tail of the output, because that is where the format puts
its result and nothing else has to be kept in step with anything. Only the
B<last> non-empty line counts: prose before the object is irrelevant, prose
containing one cannot be mistaken for it (an agent printing a board can print a
pasted result object the same way #160's board printed a C<503>), and anything
after it makes the run unstructured again, so the scan takes over. The
reasoning is written out at C<_run_result> in L<App::karr::Foundation::Runner>.

A reported error ranks with the exit code, not with the scan: it is the run's
statement about itself, not an inference drawn from its prose, so the
"what it did before what it printed" guard below does not apply to it. Its
B<kind> decides what happens next. A provider status (C<api_error_status>) is
the case the scan was written for and backs the board off as a rate limit
always did. A spent turn budget (C<error_max_turns>) is not: the agent worked,
the provider answered, and the task was simply larger than the budget it was
given -- so it is logged, the board is not parked, and the run is judged by what
it moved. Any other reported error keeps its own name (C<error_during_execution>)
and cools the board down. A non-zero exit a report of B<success> does not
account for is still a common error: the report is the agent's, the exit code
may be its wrapper's.

In ticket mode the report is what finally separates the two stalls that used to
look identical -- "the agent reports it could not proceed" and "the agent did
nothing" -- and F<.karr.log> names which one it was
(C<STALL task#N -- the agent ran out of turns>). With no report it says exactly
that rather than guessing.

All per-board state files are gitignored: C<.karr.state> (board hash, per-task
attempts, cooldown, last error, last report, and the hook's board fingerprint,
round count and last exit), C<.karr.lock>, C<.karr.log>.
Agent availability is not among them: it is not per board and does not live in
the repository at all (see "Agent availability" above). C<last_error>
describes the B<last> run and is removed again by the next run that is not a
common error, so it never outlives the cooldown it caused. C<last_result> is
the same for the report -- how the last run ended, its turns, duration and cost
-- and is dropped again by a run that reported nothing.

=head2 run

    exit App::karr::Foundation->new_with_options->run(@ARGV);

The single entry point, invoked by F<bin/karr-foundation>. What is left of
C<@ARGV> after option parsing is a hub command and is answered first: C<ask> and
C<answer> (see "The question mailbox" above) work on the hub alone, discover no
board and start no agent, and C<chain> (see "Running the chain" above) executes
the fleet's plan through L<App::karr::Foundation::Executor>. An argument that is
none of the three is a user error rather than a silent drain. With no arguments -- how cron invokes it --
it is one pass over every configured repo, then returns -- there is no internal loop; running
periodically is left to cron/systemd-timer/an external C<while> loop, per
L</DESCRIPTION>. Returns C<1> (a process exit code, not an exception) when
C<_discover_repos> finds nothing at all -- an empty C<dirs>/C<scan> in the
config, or a config file that does not exist -- and C<0> otherwise, including
when individual repos error out: a repo whose C<_process_repo> dies is
C<warn>ed and skipped, never propagated, so one broken board cannot stop the
rest of the run.

With C<--status> it prints L<App::karr::Foundation::Overview>'s read-only
overview and returns without touching any board. Without it, C<run> first
checks whether B<any> repo has an agent configured at all (per repo,
C<_agent_command>, excluding boards disabled via C<karr disable>); if none
do, it falls back to the same overview instead of doing nothing, since
agent execution is opt-in and a config with no agents configured is a
legitimate way to use foundation purely as a status board. Otherwise it calls
C<_process_repo> for each repo, which is what applies the disable flag, the
lock, the cooldown, the change/actionability check, and finally the drain loop
described under "Drain semantics" above.

One repo at a time unless the effective machine ceiling says otherwise, which
is what it says by default -- see "Concurrency" above for the three levels and
L<App::karr::Foundation::Limits> for how they combine. Above C<1>, each board
gets a forked child running the whole of C<_process_repo> for it, the parent
schedules within the global and per-agent caps, and the shutdown handler TERMs
the children rather than their agents so every board runs the cleanup it would
have run serially.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/karr/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
