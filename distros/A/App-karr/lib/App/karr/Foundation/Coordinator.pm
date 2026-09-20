# ABSTRACT: karr-foundation's judgement layer -- the coordination agent, called only on deviation

package App::karr::Foundation::Coordinator;
our $VERSION = '0.601';
use Moo;
use POSIX qw( strftime );
use Path::Tiny;
use Try::Tiny;
use App::karr::Error qw( user_error clean_error );
use App::karr::Encoding qw( yaml_load );



has foundation => (
  is       => 'ro',
  weak_ref => 1,
  required => 1,
);

# The literal an assignment chain uses for "rather wait than take anything
# below this line". Matched case-insensitively: it is written by a language
# model, and refusing `wait` because it is not `WAIT` would park a board over
# a shift key.
my $WAIT = 'wait';

sub _stamp {
  my ( $epoch ) = @_;
  return '?' unless defined $epoch && "$epoch" =~ /\A[0-9]+\z/;
  return strftime( '%Y-%m-%dT%H:%M:%SZ', gmtime($epoch) );
}

# ---------------------------------------------------------------------------
# Which agent
# ---------------------------------------------------------------------------


has name => (
  is      => 'lazy',
  builder => '_build_name',
);

sub _build_name {
  my ( $self ) = @_;
  my $defs = $self->foundation->_agents->definitions;
  my @named = grep { ( $defs->{$_}{role} // '' ) eq 'coordinator' } sort keys %$defs;
  return undef unless @named;
  user_error( 'Agents ' . join( ' and ', @named )
    . " are both marked 'role: coordinator'; exactly one agent can be the "
    . 'fleet\'s judgement layer' ) if @named > 1;
  return $named[0];
}


sub configured { return defined $_[0]->name }

# ---------------------------------------------------------------------------
# The assignment
# ---------------------------------------------------------------------------


has assignment_file => (
  is      => 'lazy',
  builder => '_build_assignment_file',
);

sub _build_assignment_file {
  my ( $self ) = @_;
  return $self->foundation->_config_path->sibling('assignment.yml');
}


has assignment => (
  is      => 'lazy',
  builder => '_build_assignment',
);

sub _build_assignment {
  my ( $self ) = @_;
  my $file = $self->assignment_file;
  return { repos => {} } unless $file->exists;

  my $data = try {
    # slurp_utf8 gives characters and yaml_load takes them: the two halves of
    # the one crossing App::karr::Encoding owns.
    yaml_load( $file->slurp_utf8 );
  } catch {
    warn "karr-foundation: cannot read $file: " . clean_error($_) . "\n";
    undef;
  };
  return { repos => {}, broken => "the assignment in $file could not be read" }
    unless ref $data eq 'HASH';

  my $repos = $data->{repos};
  return { repos => {}, broken => "the assignment in $file has no 'repos:' mapping" }
    unless ref $repos eq 'HASH';

  my %by_path;
  for my $key ( keys %$repos ) {
    my $chain = $repos->{$key};
    # A one-element list written as a scalar is what YAML invites and what the
    # chain's own `needs` already accepts; refusing it here would be pedantry.
    $chain = [ $chain ] if defined $chain && !ref $chain;
    next unless ref $chain eq 'ARRAY';
    my @names = grep { defined && length } map { ref $_ ? undef : $_ } @$chain;
    $by_path{ _key( $key ) } = \@names;
  }
  return { repos => \%by_path };
}

# One spelling for a repository path, so a board discovered through `scan:` and
# the same board written into the assignment by hand match. realpath needs the
# path to exist; where it does not, the string is the best answer there is.
sub _key {
  my ( $path ) = @_;
  my $p = try { path("$path")->realpath } catch { undef };
  return defined $p ? "$p" : "$path";
}


sub route {
  my ( $self, $repo ) = @_;
  my $assignment = $self->assignment;

  if ( defined( my $broken = $assignment->{broken} ) ) {
    $self->want( reason => $broken );
    return undef;
  }

  my $chain = $assignment->{repos}{ _key($repo) };
  unless ( $chain && @$chain ) {
    $self->want( repo => "$repo",
      reason => 'no assignment names this repository' );
    return undef;
  }

  my $agents = $self->foundation->_agents;
  my @failing;
  for my $entry ( @$chain ) {
    return { wait => 'the assignment says WAIT for this board'
      . ( @failing ? ' (after ' . join( ', ', @failing ) . ', which '
                     . ( @failing == 1 ? 'is' : 'are' ) . ' failing)' : '' ) }
      if lc $entry eq $WAIT;

    # An agent this machine does not define is dropped with a note rather than
    # refused, the way a chain header's per-agent limit is: agent definitions
    # are local and only local, so a table written where more of them exist is
    # a normal thing to meet, not a broken one.
    unless ( $agents->definitions->{$entry} ) {
      $self->foundation->_say_verbose(
        "assignment: no agent '$entry' is defined here, trying the next" );
      next;
    }
    return { agent => $entry } if $agents->available( $entry );
    push @failing, $entry;
  }

  return { wait => 'every agent the assignment names for this board is failing ('
    . join( ', ', @failing ) . ')' } if @failing;

  $self->want( repo => "$repo",
    reason => 'the assignment names no agent this machine has for this repository' );
  return undef;
}

# ---------------------------------------------------------------------------
# Wants
# ---------------------------------------------------------------------------


has wanted => (
  is      => 'ro',
  default => sub { [] },
);

# Which entries have already been recorded, so one tick that meets the same
# deviation twice -- _plan_repos and _process_repo both resolve every board --
# does not say it twice in the prompt.
has _seen => (
  is      => 'ro',
  default => sub { {} },
);


sub want {
  my ( $self, %what ) = @_;
  return 0 unless $self->configured;
  my $reason = $what{reason};
  return 0 unless defined $reason && length $reason;
  my $key = join "\0", map { defined $what{$_} ? $what{$_} : '' }
    qw( step repo reason );
  return 0 if $self->_seen->{$key}++;
  push @{ $self->wanted }, {
    reason => $reason,
    ( defined $what{step} ? ( step => "$what{step}" ) : () ),
    ( defined $what{repo} ? ( repo => "$what{repo}" ) : () ),
  };
  return 1;
}

# One deviation as the prompt says it: what it is about, then what it was.
sub _line {
  my ( $want ) = @_;
  my $what = defined $want->{step} ? "step $want->{step}"
           : defined $want->{repo} ? $want->{repo}
           :                         undef;
  return defined $what ? "$what: $want->{reason}" : $want->{reason};
}

# ---------------------------------------------------------------------------
# The call
# ---------------------------------------------------------------------------


sub dispatch {
  my ( $self ) = @_;
  my @wanted = @{ $self->wanted };
  return 0 unless @wanted;

  # Emptied first: whatever happens below, this tick has had its one call, and
  # a second dispatch must not turn one deviation into two runs.
  @{ $self->wanted } = ();

  my $f    = $self->foundation;
  my $name = $self->name or return 0;
  my $why  = join '; ', map { _line($_) } @wanted;

  if ( $f->dry_run ) {
    print "would call the coordination agent '$name' for "
        . scalar(@wanted) . " deviation(s): $why\n";
    return 0;
  }

  my $git = $f->_hub_git;
  unless ( $git ) {
    warn "karr-foundation: the coordination agent '$name' is wanted ($why) but "
       . "this machine has no hub -- name one with 'hub: /path/to/repo' in "
       . $f->_config_path . "\n";
    return 0;
  }
  my $hub = $git->dir;

  # An agent like any other, including this: while it is failing, it is not
  # run. The place that wanted it waits, which is the behaviour F<karr-foundation>
  # had before there was a coordination agent at all, and the wait ends by
  # itself when probe_every comes round.
  unless ( $f->_agents->available( $name ) ) {
    my $av   = $f->_agents->availability( $name );
    my $wait = ( $av->{next_attempt} // 0 ) - time;
    print "the coordination agent '$name' is failing"
        . ( defined $av->{last_error} ? " ($av->{last_error})" : '' )
        . ", next attempt in ${wait}s -- the plan waits\n";
    return 0;
  }

  unless ( $f->_acquire_lock( $hub ) ) {
    print "the coordination agent '$name' is wanted, but the hub $hub is busy "
        . "-- the plan waits for the next tick\n";
    return 0;
  }

  print "calling the coordination agent '$name' for " . scalar(@wanted)
      . " deviation(s): $why\n";
  $f->_append_log( $hub, 'COORDINATION wanted: ' . $why );

  my $ran = try {
    $self->_invoke( $hub, $name, \@wanted );
  } catch {
    warn "karr-foundation: the coordination agent failed to start: "
       . clean_error($_) . "\n";
    0;
  };
  $f->_release_lock( $hub );
  return $ran;
}

# The invocation itself, once the tick has decided it may happen: the agent's
# own command under its own contract (#188), the deviations as its prompt, and
# its own result object as the verdict (#187).
sub _invoke {
  my ( $self, $hub, $name, $wanted ) = @_;
  my $f   = $self->foundation;
  my $inv = $f->_agents->invocation( $name );

  my ( $exit, $output ) = $f->_run_command(
    $hub, $f->_load_karr( $hub ), $inv->{command}, undef, $inv,
    role   => 'coordinator',
    prompt => $self->prompt( $wanted ),
  );

  my ( $err, $ended );
  my $report = $f->_run_result( $output );
  if ( $report ) {
    ( $err, $ended ) = $f->_result_error( $report );
    # The same reading the drain makes of an exit the report does not account
    # for: the report is the agent's, the exit code may be a wrapper's.
    $err //= "exit=$exit" if $exit != 0 && !$report->{is_error};
    $f->_append_log( $hub, $f->_result_line( $report, $ended ) );
  }
  elsif ( $exit != 0 ) {
    $err = "exit=$exit";
  }

  if ( defined $err ) {
    $f->_agents->record_failure( $name, $err );
    $f->_append_log( $hub, "COORDINATION failed: $err" );
    print "the coordination agent '$name' failed: $err\n";
    return 0;
  }

  $f->_agents->record_success( $name );
  $f->_append_log( $hub, 'COORDINATION ' . ( $ended // 'done' ) );
  print "the coordination agent '$name' finished ("
      . ( $ended // 'no report' ) . "); the next tick runs what it wrote\n";
  return 1;
}

# ---------------------------------------------------------------------------
# The prompt
# ---------------------------------------------------------------------------


sub prompt {
  my ( $self, $wanted ) = @_;
  my $f   = $self->foundation;
  my $hub = $f->_hub_git ? $f->_hub_git->dir : '(none)';

  my @out;
  push @out, <<'INTRO';
You are the coordination agent of this karr fleet -- its judgement layer.
karr-foundation works through written plans on its own and calls you only when
a plan is missing or has broken; between two of those calls no AI runs at all.
Everything you write is read back by machinery that runs without you, so write
it in the shapes below and in no other.
INTRO

  push @out, "WHY YOU WERE CALLED\n"
    . join( '', map { '  - ' . _line($_) . "\n" } @$wanted );

  push @out, "WHERE THINGS ARE\n"
    . sprintf( "  fleet config   %s\n", $f->_config_path )
    . sprintf( "  assignment     %s\n", $self->assignment_file )
    . sprintf( "  availability   %s  (karr writes it; read it, never edit it)\n",
        $f->_agents->state_file )
    . sprintf( "  hub repository %s  (refs/karr-foundation/*: chain, run log, questions)\n", $hub )
    . "  Read a board with 'karr list --compact', 'karr board', 'karr show ID'\n"
    . "  in its repository, and the fleet with 'karr-foundation --status --verbose'.\n";

  push @out, $self->_agent_block;

  my $routing = $f->_config_data->{routing};
  push @out, "HOW THE OPERATOR WANTS THEM USED\n"
    . ( defined $routing && length $routing
        ? _indent( $routing )
        : "  Nothing written. The operator can put prose in the config's "
          . "'routing:' key.\n" );

  push @out, $self->_writes_block;

  push @out, <<'LIMITS';
WHAT YOU MUST NOT DO
  - Name an agent in a chain step. The chain is shared with every machine in
    the fleet and an agent exists on one machine and not on the next; routing
    is the assignment's job and the assignment is local.
  - Lift a block on a card. A cross-board link is a fact and 'blocked' is a
    decision: 'karr needs --resolve' or a person makes it.
  - Plan two agents into one repository at the same time. One agent per
    repository is the fleet's one hard rule; concurrency is across
    repositories.
  - Teach karr anything domain-specific. What "done" means for a project, how
    a release is verified and which project depends on which reach karr only
    through a board's on_drained hook and through the prose above.
LIMITS

  return join "\n", @out;
}

# The agents this machine has, with what is known about each right now. The
# description is printed as written: it is the selection criterion, and a
# language model reads prose better than it matches a taxonomy, so nothing
# here reformats or truncates it.
sub _agent_block {
  my ( $self ) = @_;
  my $agents = $self->foundation->_agents;
  my $defs   = $agents->definitions;
  my @names  = sort keys %$defs;
  return "THE AGENTS ON THIS MACHINE\n  None are defined.\n" unless @names;

  my $out = "THE AGENTS ON THIS MACHINE\n";
  for my $name ( @names ) {
    my $def = $defs->{$name};
    $out .= sprintf "  %s  kind: %s  %s%s\n", $name, $def->{kind},
      $self->_availability( $name ),
      ( ( $def->{role} // '' ) eq 'coordinator' ? '  [you]' : '' );
    next unless defined $def->{description} && length $def->{description};
    my $text = $def->{description};
    $text =~ s/\s+\z//;
    $out .= "    $_\n" for split /\n/, $text;
  }
  return $out;
}

sub _availability {
  my ( $self, $name ) = @_;
  my $av = $self->foundation->_agents->availability( $name );
  return 'ok' unless ( $av->{state} // 'ok' ) eq 'failing';
  return 'failing since ' . _stamp( $av->{failing_since} )
    . ', next attempt at ' . _stamp( $av->{next_attempt} )
    . ( defined $av->{last_error} ? " ($av->{last_error})" : '' );
}

# The three things it may write, each with the exact shape karr reads back. Two
# of them are commands and are spelled out as commands: an agent that has to
# guess at an interface writes something nobody can execute. Until #213 the
# chain was the exception -- there was no command for it, so this block carried
# a perl -e one-liner against ChainStore, which made a storage API an agent's
# interface and left every rename in that class breaking a prompt instead of a
# call.
sub _writes_block {
  my ( $self ) = @_;
  my $file = $self->assignment_file;
  my $karr = $self->_foundation_command;
  return <<"WRITES";
WHAT YOU MAY WRITE

1. THE ASSIGNMENT -- $file
   Repository path to the ordered list of agents that may work that board.
   karr-foundation takes the first entry that currently works, and WAIT means
   "rather wait than use anything further down". Only the names above, plus
   WAIT. Name every repository of the fleet: one that is missing calls you
   again on the next tick, so a board nothing should run on gets a chain of
   its own that is just WAIT.

     repos:
       /path/to/repo:
         - agent-name
         - another-agent
         - WAIT

2. A CHAIN, in the hub. Keep it short: a long chain goes stale faster than it
   is worked through. A step carries id, kind (ticket | shell | question |
   plan), repo, ticket, needs (step ids -- the edges of the DAG), timeout,
   precheck, command and note. A precheck is '<fact> == <value>' or '!=' over
   board_actionable, ticket_status, ticket_blocked, ticket_claimed,
   ticket_links and question_state; a step whose precheck no longer holds is
   not executed -- it goes stale and calls you again. Write the whole chain as
   one YAML (or JSON) document on stdin; it REPLACES the chain that is there,
   so it is the plan as you now think it should be, not an addition to it:

     $karr plan <<'CHAIN'
     steps:
       - id: 1
         kind: ticket
         repo: /path/to/repo
         ticket: 7
         precheck: ticket_status == todo
       - id: 2
         kind: shell
         repo: /path/to/repo
         needs: [ 1 ]
         command: ./gate.sh
     limits:
       concurrent: 2
     note: what this plan is for
     CHAIN

   Add --dry-run to have a chain checked and told back to you without writing
   it. A chain that still has a step running is refused rather than replaced;
   --force replaces it anyway, and is not what you want unless you know what
   that step was doing.

3. A QUESTION, always in advance and never from inside a step:

     $karr ask "which registry do we publish to?" \\
       --context "the release gate is waiting" \\
       --options cpan,darkpan --default cpan --policy use_default \\
       --wait 3600 --step 2

   A kind: question step waits until every question naming it is settled.
WRITES
}

# How this agent has to spell karr-foundation for it to find the fleet it was
# called for. Without --config the binary reads ~/.config/karr-foundation, and
# a fleet started with one somewhere else would have its plan written into a
# config that does not exist -- the agent would be told a command that cannot
# work and would have no way of knowing.
sub _foundation_command {
  my ( $self ) = @_;
  my $config = $self->foundation->config;
  return 'karr-foundation' unless defined $config && length $config;
  return "karr-foundation --config '$config'";
}

sub _indent {
  my ( $text ) = @_;
  $text =~ s/\s+\z//;
  return join '', map { "  $_\n" } split /\n/, $text;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::karr::Foundation::Coordinator - karr-foundation's judgement layer -- the coordination agent, called only on deviation

=head1 VERSION

version 0.601

=head1 DESCRIPTION

The third layer of the fleet design. Coordination is shared (tickets,
dependencies, the chain, the questions -- all in git refs), execution is local
(which agent commands exist here, whether they work, how many may run), and
B<judgement> is an agent: planning, routing, and reacting to what nobody
planned for.

It is an agent like every other one -- an entry in the config's C<agents:>
section, invoked through its own C<command> under its own C<kind> contract
(L<App::karr::Foundation::Agents>), classified from the result object it
leaves behind (L<App::karr::Foundation::Runner/_run_result>), and marked
C<failing> by the same availability record when it stops working. What
separates it from a board agent is B<when> it runs: never in the hot path.
F<karr-foundation> works through written plans on its own, and calls this one
only where a plan is missing or has broken. The AI is the compiler, the chain
is the program, F<karr-foundation> is the VM -- and between two deviations no
AI runs at all, which is what makes the whole arrangement affordable.

=head2 Which agent is the coordinator

The one whose definition says C<< role: coordinator >>. That is a marker on a
definition the config already carries and B<not> a second place to configure a
fleet: a top-level C<coordinator: name> key would be a second name for an
agent that is already named, and two names for one thing are two things to
keep in step. A config that marks two agents refuses to guess between them.

A fleet that marks none has no judgement layer, and everything below is a
no-op: the deviations are still recorded and still printed, exactly as they
were before this class existed. That is the fallback everywhere here -- the
behaviour F<karr-foundation> had when the planner was a person.

=head2 The four deviations

They are the places that already recorded "the planner is wanted" and nothing
else, and they are extended rather than replaced:

=over 4

=item * a C<kind: plan> step, which this VM does not execute;

=item * a question past its deadline whose policy is C<escalate_to_ai>;

=item * a step gone B<stale> -- its precheck no longer holds, so the plan has
gone out of date;

=item * a repository the L</assignment> cannot route, which is this class's
own (see below).

=back

The first three arrive through L<App::karr::Foundation::Executor>, which
already collects them for its closing report; the fourth is L</route>.

=head2 One call per tick, not one per deviation

A tick that finds five stale steps has learned B<one> thing -- the plan is out
of date -- and telling the coordination agent five times would cost five runs
to answer it once. So L</want> only records, deduplicating identical entries,
and L</dispatch> makes exactly one call at the end of the tick with everything
that was recorded. That is also why a call happens at the B<end>: a planner
called half way through would be planning against a board its own tick was
still moving.

Nothing re-reads the assignment or the chain afterwards. Whatever the
coordination agent wrote is picked up by the next tick, which is the same rule
as everywhere else here -- no AI in the hot path, and no tick that runs the
plan it has just written without anybody having seen it.

=head2 The assignment: routing without an AI in the way

    repos:
      /path/to/repo:
        - minimax
        - claude
        - WAIT

Repository path to an ordered list of agents, with an explicit C<WAIT> for
"rather wait than use something unsuitable here". F<karr-foundation> looks the
repository up and takes the first entry that currently works; that lookup is
the whole of the hot path, and no AI is in it.

It is B<execution> state, so it is local and never in refs: an agent command
that exists on one machine does not exist on the next, so a routing table
naming agents cannot be shared any more than the definitions it names can. It
therefore lives beside F<agents.state> and the config that defines the agents,
and follows C<--config> the way both of those do.

=head2 What it is not

Nothing domain-specific reaches karr through it: what "done" means for a
project, how a release is verified, which project depends on which, arrives
through a board's C<on_drained> hook and through the operator's prose, and
this class only carries that prose to the agent. There is no learning
algorithm either -- the recovery records L<App::karr::Foundation::Agents>
keeps are read by the agent, not by karr. It lifts no block (a link is a fact,
C<blocked> is a decision), and it does not touch the one hard rule that one
repository has one agent.

=head1 SEE ALSO

L<App::karr::Foundation>, L<App::karr::Foundation::Agents>,
L<App::karr::Foundation::Executor>, L<App::karr::Foundation::ChainStore>

=head2 foundation

The owning L<App::karr::Foundation>, held C<weak_ref> (the foundation owns
this class). Required. The config, the agent definitions, the hub and the
runner all come from it.

=head2 name

The name of the agent definition marked C<< role: coordinator >>, or C<undef>
when the config marks none -- in which case this whole class is a no-op and
F<karr-foundation> behaves exactly as it did before it existed.

Two marked definitions are a user error rather than a choice: "which of these
is the judgement layer" has no safe default, and picking the alphabetically
first one would be a guess nobody could see.

=head2 configured

    next unless $coordinator->configured;

True when this fleet has a coordination agent at all. Everything this class
does is gated on it, so a fleet that names none records nothing, calls nothing
and prints nothing new.

=head2 assignment_file

The path to F<assignment.yml>, the machine-local routing table -- a sibling of
the foundation's C<_config_path>, beside F<agents.state>, so C<--config>
relocates it with everything else local.

=head2 assignment

The parsed routing table: C<< { repos => { PATH => [ NAME, ... ] } } >>, plus
C<broken> with a sentence when the file is there and cannot be used. An
absent file is not broken -- it is the ordinary state of a fleet before the
first plan, and it routes nothing.

Repository keys are normalised through C<realpath> where the path exists, so a
board reached through a symlink or a C<scan:> directory matches the table the
coordination agent wrote from its own view of the fleet.

=head2 route

    my $routed = $coordinator->route( $repo );
    # undef                     -- nothing routes this board; resolve it as before
    # { agent => 'minimax' }    -- the first agent in its chain that works
    # { wait  => 'why' }        -- its chain says wait; no agent runs here now

What the assignment says about one repository. This is the hot path: a lookup
and an availability check, with no AI anywhere in it.

The first entry that names a defined and currently available agent wins. A
C<WAIT> entry ends the search -- "rather wait than use anything further down"
is the one thing an ordered list cannot say by itself -- and so does a chain
whose agents are all failing, because the coordination agent wrote that chain
and going past its end would be karr routing on its own.

A repository the table does not name, or names with nothing usable, is the
fourth deviation: it records that the coordination agent is wanted (L</want>)
and returns C<undef>, so resolution carries on exactly as it did before --
C<default_agent>, C<< claude: true >>, or no agent at all.

=head2 wanted

The deviations recorded so far this tick, in the order they were seen, each
C<< { reason => ..., step => ..., repo => ... } >>. L</dispatch> empties it.

=head2 want

    $coordinator->want( step => 4, reason => 'kind: plan is not executed here' );
    $coordinator->want( repo => "$repo", reason => 'no assignment names it' );

Records that the coordination agent is wanted, and returns true when it was
recorded. A B<no-op> for a fleet that marks no coordinator: the caller has
already said what it wanted out loud and written it into its own log, and this
class refuses to be a second such record when nobody can act on it.

Identical entries collapse, which is what makes one tick one call.

=head2 dispatch

    $coordinator->dispatch;

The one call a tick may make. Returns true when the coordination agent ran.

Nothing happens without a deviation, without a coordinator, or without a hub:
the agent's outputs -- a chain, a question -- live in
C<refs/karr-foundation/*>, so a fleet with no hub has nowhere to put them, and
that is said once rather than worked around.

The run happens B<in the hub> and B<under the hub's own> F<.karr.lock>, which
is the same rule every other run here obeys: one agent per repository, however
many ticks knock. It carries C<KARR_ROLE=coordinator>, so whatever C<karr>
writes it makes land in their own activity log instead of counting as a board
agent's engagement with a card (#158).

Its result decides the agent's availability exactly as a drain's does: a
reported error or a non-zero exit marks it C<failing> and every board on it
waits for one probe interval, anything else says it works. The transcript is
B<not> scanned. That scan exists for a board run that moved nothing and
printed a rate limit (#160); this run moves no board by definition, and a
planner that prints a backlog would trip it on the backlog's own words.

=head2 prompt

    my $text = $coordinator->prompt( \@wanted );

The instruction the coordination agent is given, as C<$PROMPT>: why it was
called, where the fleet's files are, which agents exist here with their
availability and their prose, the operator's own prose about how to use them
(config key C<routing:>), the shapes it may write, and the boundaries it may
not cross.

There is deliberately no key to replace this text with another. What an
operator has to say about routing is prose and belongs in C<routing:>, where
the agent reads it in context; a second prompt key would be a place to
overwrite the part that says what karr can actually read back.

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
