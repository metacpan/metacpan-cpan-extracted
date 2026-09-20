# ABSTRACT: karr-foundation agent definitions, invocation contract and availability

package App::karr::Foundation::Agents;
our $VERSION = '0.601';
use Moo;
use Path::Tiny;
use Fcntl qw( LOCK_EX );
use App::karr::Error qw( user_error clean_error );
use App::karr::Encoding qw( json_encode json_decode );
use Try::Tiny;



has foundation => (
  is       => 'ro',
  weak_ref => 1,
  required => 1,
);

# How long to wait before trying an agent that stopped working, when nobody
# said. Short enough that a five-minute blip does not park a fleet for an hour,
# long enough that a hard rate limit is not hammered once a minute. An operator
# who knows the real rhythm writes probe_every and stops guessing.
our $DEFAULT_PROBE_SECONDS = 600;

# How many recoveries are kept per agent. The record exists so somebody can see
# a rhythm in it; an unbounded list in a state file is a leak, and twenty
# outages are already more shape than anyone needs.
our $MAX_RECOVERIES = 20;

# The invocation contracts karr knows. 'shell' is the historical `command:` --
# a complete shell template karr appends nothing to, because it has no idea
# what the thing at the other end understands. 'claude-code' is the one
# contract it does know.
my %KIND = map { $_ => 1 } qw( shell claude-code );

# The roles a definition may carry, which is how karr-foundation finds the one
# agent that is its judgement layer (App::karr::Foundation::Coordinator). A
# marker on a definition rather than a second config key naming an agent that
# is already named: two names for one thing are two things to keep in step.
# An unknown role is a hard error for the same reason an unknown kind is --
# `role: coordinater` would leave a fleet with no judgement layer at all and
# say nothing about it, on every tick, quietly.
my %ROLE = map { $_ => 1 } qw( coordinator );

# Keys a definition may carry. Not a schema for its own sake: a typo in
# 'description' silently drops the one thing that decides where work goes, and
# there is no other feedback loop -- an agent definition is never "run" until
# something goes wrong. Unknown keys warn rather than die, so a config written
# for a newer karr still starts.
my %KNOWN_KEY = map { $_ => 1 } qw(
  command kind probe_every description concurrent role
  permission_mode max_turns allowed_tools
);

# ---------------------------------------------------------------------------
# Definitions
# ---------------------------------------------------------------------------


has definitions => (
  is      => 'lazy',
  builder => '_build_definitions',
);

sub _build_definitions {
  my ( $self ) = @_;
  my $raw = $self->foundation->_config_data->{agents};
  return {} unless defined $raw;
  user_error("Config key 'agents' must be a mapping of name => definition")
    unless ref $raw eq 'HASH';

  my %defs;
  for my $name ( sort keys %$raw ) {
    my $def = $raw->{$name};
    user_error("Agent '$name' must be a mapping") unless ref $def eq 'HASH';
    my %d = %$def;

    my $cmd = $d{command};
    user_error("Agent '$name' has no command") unless defined $cmd && length $cmd;

    my $kind = $d{kind} // 'shell';
    user_error(
      "Agent '$name' has unknown kind '$kind' "
      . '(expected: ' . join( ' or ', sort keys %KIND ) . ')' )
      unless $KIND{$kind};
    $d{kind} = $kind;

    if ( defined( my $role = $d{role} ) ) {
      user_error(
        "Agent '$name' has unknown role '$role' "
        . '(expected: ' . join( ' or ', sort keys %ROLE ) . ')' )
        unless $ROLE{$role};
    }

    $d{probe_seconds} = defined $d{probe_every}
      ? _duration( "Agent '$name' probe_every", $d{probe_every} )
      : undef;

    my @unknown = grep { !$KNOWN_KEY{$_} && $_ ne 'probe_seconds' } sort keys %d;
    warn "karr-foundation: agent '$name': unknown key(s): @unknown\n" if @unknown;

    $defs{$name} = \%d;
  }
  return \%defs;
}

# A duration as a config writes one: 45, 90s, 15m, 2h, 1d. Bare numbers are
# seconds. Anything else is a config error, not a default -- a probe_every of
# "15min" silently meaning ten minutes is exactly the kind of quiet wrong
# answer this file exists to avoid.
sub _duration {
  my ( $what, $value ) = @_;
  user_error("$what must be a duration, not a structure") if ref $value;
  my $v = "$value";
  $v =~ s/\A\s+//;
  $v =~ s/\s+\z//;
  return $v + 0 if $v =~ /\A[0-9]+\z/;
  my ( $n, $unit ) = $v =~ /\A([0-9]+)\s*([smhd])\z/i
    or user_error("$what: cannot read '$value' as a duration (e.g. 90s, 15m, 2h, 1d)");
  my %mult = ( s => 1, m => 60, h => 3600, d => 86400 );
  return $n * $mult{ lc $unit };
}


sub definition {
  my ( $self, $name ) = @_;
  my $def = $self->definitions->{$name}
    or user_error( "No agent named '$name' is defined"
      . ( %{ $self->definitions }
          ? ' (known: ' . join( ', ', sort keys %{ $self->definitions } ) . ')'
          : " (the config has no 'agents:' section)" ) );
  return $def;
}


sub names { return sort keys %{ $_[0]->definitions } }

# ---------------------------------------------------------------------------
# The invocation contract
# ---------------------------------------------------------------------------


# Everything foundation needs to run one named agent: the assembled shell
# command, the name to log it under, and how to render its live output.
sub invocation {
  my ( $self, $name ) = @_;
  my $def = $self->definition( $name );
  my $kind = $def->{kind};
  return {
    name        => $name,
    kind        => $kind,
    command     => $kind eq 'claude-code'
                     ? $self->_claude_code_command( $def )
                     : $def->{command},
    render      => $kind eq 'claude-code' ? 'stream-json' : undef,
    description => $def->{description},
  };
}

# `kind: claude-code` -- the one contract karr knows how to append arguments
# to. The definition's `command` stays a template karr does not quote (it may
# be `claude`, a wrapper, or `env FOO=1 claude --model x`, exactly as
# claude_bin always could); everything appended after it is karr's, and every
# value that came out of the config is quoted, because a permission mode with a
# space in it must not become two arguments.
#
# --output-format is the reason this is a contract rather than a flag list. The
# run's own report (App::karr::Foundation::Runner::_run_result) is only there to
# read when the agent emits one, so a claude-code agent has to be asked for
# structured output. Plain `--output-format json` would buy that by printing
# nothing at all until the run ends, which silently breaks the live output this
# module's own documentation promises for a TTY. `stream-json` ends with the
# same result object AND streams on the way, so the Runner renders it (render =>
# 'stream-json' above) and both halves survive. --verbose is not optional next
# to it: claude refuses `-p --output-format stream-json` without it.
#
# The assignment of a ticket-mode run is deliberately NOT appended here. claude
# has no flag for it, so the id keeps travelling the way #185 sends it -- as a
# closing sentence in $PROMPT and as $KARR_TASK in the environment.
sub _claude_code_command {
  my ( $self, $def ) = @_;
  my @argv = ( $def->{command}, '-p', '"$PROMPT"' );
  push @argv, '--output-format', 'stream-json', '--verbose',
              '--include-partial-messages';
  push @argv, '--permission-mode',
              _shq( $def->{permission_mode} // 'bypassPermissions' );
  # max_turns: 0 drops the flag, the same "no limit" spelling max_runtime uses.
  my $turns = exists $def->{max_turns} ? $def->{max_turns} : 30;
  push @argv, '--max-turns', _shq( $turns ) if $turns;
  if ( defined( my $tools = $def->{allowed_tools} ) ) {
    my @tools = grep { defined && length } ref $tools eq 'ARRAY' ? @$tools : ( $tools );
    push @argv, '--allowed-tools', _shq( join ',', @tools ) if @tools;
  }
  return join ' ', @argv;
}

# Single-quote a config value for /bin/sh, and only when it needs it -- an
# unquoted 30 and bypassPermissions keep .karr.log's START line readable, which
# is what an operator reads it for.
sub _shq {
  my ( $v ) = @_;
  $v = defined $v ? "$v" : '';
  return $v if length $v && $v =~ m{\A[A-Za-z0-9_.:,/=+-]+\z};
  $v =~ s/'/'\\''/g;
  return "'$v'";
}

# ---------------------------------------------------------------------------
# Availability
# ---------------------------------------------------------------------------

# WHERE THIS LIVES, and why it is neither of the two obvious places.
#
# Not .karr.state: that file is per repository, and an agent's availability is
# not a property of a repository. Two repos driven by the same agent have to
# share one piece of knowledge -- that the command stopped working -- or the
# second one spends its own window discovering it again, and a repo that has
# not been visited yet learns nothing at all.
#
# Not the board (refs/karr/config, where `karr disable` lives): that syncs, and
# this must not. An agent command that exists on one machine does not exist on
# the next, and a spent account limit belongs to a person, not to a project.
# Pushing "minimax is failing" to a shared remote parks a colleague's fleet on
# an outage that is not theirs.
#
# So it is machine-local and agent-scoped, and it lives beside the config file
# that defines the agents. That also makes it follow --config: a second fleet
# (or a test) pointed at another config gets its own availability and cannot
# write over the real one.

has state_file => (
  is      => 'lazy',
  builder => '_build_state_file',
);

sub _build_state_file {
  my ( $self ) = @_;
  return $self->foundation->_config_path->sibling('agents.state');
}

# Read fresh every time rather than cached in the object. The file is a few
# hundred bytes; what the read buys is that two foundation ticks that overlap
# (#162 is the same story for .karr.lock) see each other's outages, and that an
# operator who edits the file by hand is not talking to a copy taken minutes
# ago. A bare read takes no lock: the worst a torn read can produce is
# undecodable JSON, which yields {} and one cautious probe. The read that is
# part of a read-modify-write is a different matter and happens inside
# _mutate's lock.
sub _read_state {
  my ( $self ) = @_;
  my $file = $self->state_file;
  return {} unless $file->exists;
  my $data = try { json_decode( $file->slurp_utf8 ) } catch { undef };
  return ref $data eq 'HASH' ? $data : {};
}

sub _mutate {
  my ( $self, $edit ) = @_;

  # A dry run writes nothing, so there is nothing to serialise.
  if ( $self->foundation->dry_run ) {
    $edit->( $self->_read_state );
    return;
  }

  my $file = $self->state_file;
  my $dir_ok = try {
    $file->parent->mkpath unless $file->parent->is_dir;
    1;
  } catch {
    warn "karr-foundation: cannot create " . $file->parent . ': '
       . clean_error($_) . "\n";
    0;
  };
  return 0 unless $dir_ok;

  # Read AND write inside one exclusive lock (#186). This is a read-modify-
  # write over a file every board on the machine shares, and the concurrent
  # runner has several drains going at once: two of them read "minimax: ok",
  # one records a failure and the other a success, and last-writer-wins throws
  # one of the two away. Losing "it works again" is the expensive direction --
  # it parks every board on that agent for another probe interval -- so the
  # whole sequence is serialised, not just the write.
  #
  # The lock is a sibling file rather than agents.state itself, because
  # spew_utf8 writes a temporary file and renames it over the target: an flock
  # on the state file would be a lock on an inode that is about to be replaced.
  my $guard = $self->_lock_state;
  my $state = $self->_read_state;
  $edit->( $state );
  my $ok = try {
    $file->spew_utf8( json_encode( $state ) );
    1;
  } catch {
    warn "karr-foundation: cannot write $file: " . clean_error($_) . "\n";
    0;
  };
  close $guard if $guard;
  return $ok;
}

# The exclusive lock around one read-modify-write of agents.state, returned as
# an open file handle the caller closes when it is done -- closing the handle
# is what drops an flock. undef when the lock file cannot be opened at all (a
# read-only config directory), in which case the update goes through
# unserialised: that is what this did before, and the write itself reports the
# real problem a moment later.
#
# The wait is blocking on purpose. The critical section is a few hundred bytes
# of JSON, and the kernel drops an flock when its holder dies, so there is no
# stuck holder to time out against -- a non-blocking attempt would only turn a
# microsecond of waiting back into the lost update this exists to prevent.
sub _lock_state {
  my ( $self ) = @_;
  my $file = $self->state_file;
  my $lock = $file->sibling( $file->basename . '.lock' );
  open( my $fh, '>>', "$lock" ) or return undef;
  unless ( flock( $fh, LOCK_EX ) ) {
    close $fh;
    return undef;
  }
  return $fh;
}

# What is known about one agent right now, as the three states the spec names:
#   { state => 'ok' }
#   { state => 'failing', failing_since => EPOCH, next_attempt => EPOCH, ... }
# Timestamps are epoch seconds, as .karr.state's cooldown_until is; rendering
# them for a human is --status's job.

sub availability {
  my ( $self, $name ) = @_;
  my $rec = $self->_read_state->{$name};
  return { state => 'ok' } unless ref $rec eq 'HASH';
  return { %$rec, state => 'ok' } unless ( $rec->{state} // 'ok' ) eq 'failing';
  return { %$rec };
}

# May this agent be run right now? A failing agent whose next attempt has come
# round answers yes -- that IS the probe. There is no separate probing run:
# retrying the agent on the work that is waiting is the probe, and a probe that
# did not do the work would be a second kind of run to reason about.

sub available {
  my ( $self, $name ) = @_;
  my $rec = $self->_read_state->{$name};
  return 1 unless ref $rec eq 'HASH';
  return 1 unless ( $rec->{state} // 'ok' ) eq 'failing';
  return ( $rec->{next_attempt} // 0 ) <= time ? 1 : 0;
}


sub probe_seconds {
  my ( $self, $name ) = @_;
  my $def = $self->definitions->{$name};
  return $def->{probe_seconds} if $def && defined $def->{probe_seconds};
  return $self->default_probe_seconds;
}


has default_probe_seconds => (
  is      => 'lazy',
  builder => '_build_default_probe_seconds',
);

sub _build_default_probe_seconds {
  my ( $self ) = @_;
  my $cfg = $self->foundation->_config_data->{probe_every};
  return $DEFAULT_PROBE_SECONDS unless defined $cfg;
  return _duration( 'Config probe_every', $cfg );
}

# The command stopped working. Which of the many reasons it can stop working is
# not asked: a rate limit, a spent budget, a revoked key and a wrapper that is
# not installed on this machine all present as "it does not work now", and the
# same fixed-interval retry is the right answer to all of them. $reason is kept
# verbatim so an operator (and --status) can see what it was, not so anything
# branches on it.

sub record_failure {
  my ( $self, $name, $reason ) = @_;
  my $now = time;
  my $wait = $self->probe_seconds( $name );
  $self->_mutate( sub {
    my ( $state ) = @_;
    my $rec = $state->{$name} ||= {};
    # failing_since is the START of the outage and survives every further
    # failure: "failing since 09:12" is what a coordinator needs, and a value
    # that moved forward on each attempt would only ever say "just now".
    $rec->{failing_since} = $now
      unless ( $rec->{state} // '' ) eq 'failing' && defined $rec->{failing_since};
    $rec->{state}        = 'failing';
    $rec->{next_attempt} = $now + $wait;
    if ( defined $reason && length $reason ) { $rec->{last_error} = $reason }
    else                                     { delete $rec->{last_error} }
  } );
  return;
}

# It worked. For an agent that was already ok this writes nothing at all --
# every ordinary run would otherwise rewrite the file for no news.
#
# For one that was failing it records WHEN IT WORKED AGAIN, which is the whole
# point of the fixed-interval retry: karr does not learn the reset rhythm, it
# leaves a legible trail of outages for whoever (a person, the coordination
# agent) wants to read one out of it.

sub record_success {
  my ( $self, $name ) = @_;
  my $rec = $self->_read_state->{$name};
  return 0 unless ref $rec eq 'HASH' && ( $rec->{state} // 'ok' ) eq 'failing';
  my $now = time;
  $self->_mutate( sub {
    my ( $state ) = @_;
    my $old   = $state->{$name} // $rec;
    my $since = $old->{failing_since} // $now;
    my @recovered = @{ $old->{recovered} // [] };
    push @recovered, {
      failing_since => $since,
      recovered_at  => $now,
      seconds       => $now - $since,
      ( defined $old->{last_error} ? ( error => $old->{last_error} ) : () ),
    };
    shift @recovered while @recovered > $MAX_RECOVERIES;
    $state->{$name} = { state => 'ok', recovered => \@recovered };
  } );
  return 1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::karr::Foundation::Agents - karr-foundation agent definitions, invocation contract and availability

=head1 VERSION

version 0.601

=head1 DESCRIPTION

L<App::karr::Foundation::Agents> owns the named agent definitions from
F<karr-foundation>'s B<local> config and the availability record kept for each
of them.

A definition says what to run (C<command>), under which invocation contract
(C<kind>), how often to retry it once it has stopped working (C<probe_every>),
roughly how many of it may run side by side (C<concurrent>, the operator's
estimate -- see L<App::karr::Foundation::Limits>) and, in prose, what it is
good at (C<description>). karr never reads the description; it is carried for
the coordination agent that routes work, because the thing choosing is a
language model and prose is what it reads best.

Availability is the least karr can know: C<ok>, or C<failing> since a moment
with a next attempt due at another. No cost, no tokens, no quotas -- a rate
limit and an exhausted budget look identical from the outside (the command
stops working), so one mechanism covers both. Where the reset rhythm is known
it is configured as C<probe_every>; where it is not, the agent is retried at a
fixed interval and every recovery is recorded, so a pattern can be read out of
the record later. Reading that pattern is the coordination agent's job, never a
learning algorithm in here.

That record is shared by every board on the machine and several of them run at
once (#186), so a read-modify-write of it is serialised through an F<flock(2)>
on a sibling F<agents.state.lock>. Losing one of two overlapping updates is
cheap in one direction and not in the other: a lost "it is failing" costs one
more attempt, a lost "it works again" parks every board on that agent for
another probe interval.

=head2 foundation

The owning L<App::karr::Foundation> instance, held C<weak_ref> to avoid a
reference cycle (Agents lives inside the Foundation it belongs to). Required.
Definitions and the default probe interval are read from its C<_config_data>;
the availability state file sits beside its C<_config_path>.

=head2 definitions

Every configured agent definition, keyed by name, lazily parsed and
validated from L</foundation>'s C<agents:> config section. Each value is a
hashref carrying at least C<command> and C<kind> (defaulted to C<shell>),
plus whatever else the config gave it -- C<probe_seconds> is added during
parsing from C<probe_every> (see L</probe_seconds>), and C<role> (only
C<coordinator> today) marks the one agent that is the fleet's judgement layer
(L<App::karr::Foundation::Coordinator>). An empty hashref when
the config has no C<agents:> section at all; a malformed section or
definition (not a mapping, no C<command>, an unknown C<kind>) dies rather
than starting with a fleet that silently cannot run.

=head2 definition

    my $def = $agents->definition('claude-code');

The parsed definition hashref for C<$name> (see L</definitions>), or dies
naming the known agents -- or saying the config has none at all -- rather
than handing back C<undef> for a typo'd name.

=head2 names

    my @names = $agents->names;

Every configured agent name, sorted.

=head2 invocation

    my $inv = $agents->invocation('claude-code');
    # { name => 'claude-code', kind => 'claude-code',
    #   command => '...', render => 'stream-json', description => '...' }

Everything L<App::karr::Foundation::Runner> needs to run one named agent: the
assembled shell command, the C<kind> and C<name> to log it under, a
C<render> hint (C<stream-json> for C<kind: claude-code>, C<undef>
otherwise), and the definition's C<description>. For C<kind: shell> the
command is the config's C<command> template verbatim; for C<kind:
claude-code> it is built by appending karr's own arguments --
C<--output-format stream-json --verbose> (so the run streams live output
I<and> ends with the structured result L<App::karr::Foundation::Runner>
reads), C<--permission-mode>, C<--max-turns>, and C<--allowed-tools> as
configured.

=head2 state_file

The path to F<agents.state>, the machine-local, agent-scoped availability
record -- lazily built as a sibling of L</foundation>'s C<_config_path>, so
it follows C<--config> the way the config itself does.

It lives neither in C<.karr.state> (per-repository, and availability is not
a property of a repository -- two boards driven by the same agent must share
one answer, or the second rediscovers the outage on its own) nor on the
board (C<refs/karr/config> syncs, and an agent command or a spent account
limit is local to this machine, not something to push at a colleague's
fleet). Config-adjacent and unsynced is the one place both constraints allow.

=head2 availability

    my $rec = $agents->availability('minimax');
    # { state => 'ok' }
    # { state => 'failing', failing_since => EPOCH, next_attempt => EPOCH, ... }

What is known about C<$name> right now, as one of the two states the spec
names -- C<ok>, or C<failing> with C<failing_since>, C<next_attempt>, and
(when one was given) C<last_error>. Timestamps are epoch seconds, as
C<.karr.state>'s C<cooldown_until> are; rendering them for a human is
C<karr-foundation --status>'s job, not this method's.

=head2 available

    next unless $agents->available('minimax');

May C<$name> be run right now? True for an agent that is C<ok>, and true
again for a C<failing> one whose L</probe_seconds> has elapsed since
C<failing_since> -- that elapsed check IS the probe. There is no separate
probing run: retrying the agent on the work already waiting is the probe,
and a probe that skipped the work would be a second kind of run to reason
about.

=head2 probe_seconds

    my $wait = $agents->probe_seconds('minimax');

How long a failing C<$name> waits before it is retried: the agent's own
C<probe_every> when its definition set one, otherwise L</default_probe_seconds>.

=head2 default_probe_seconds

The fallback probe interval for an agent whose definition sets no
C<probe_every> of its own: lazily read from the config's top-level
C<probe_every>, or C<600> (ten minutes) when that is absent too -- short
enough that a five-minute blip does not park a fleet for an hour, long
enough that a hard rate limit is not hammered once a minute.

=head2 record_failure

    $agents->record_failure('minimax', 'rate limited');

Records that C<$name> just failed and schedules its next probe
L</probe_seconds> out. Which of the many reasons it can fail is not asked --
a rate limit, a spent budget, a revoked key, and a wrapper missing on this
machine all present the same way (it does not work now), and the same
fixed-interval retry is the right answer to all of them. C<$reason> (optional)
is kept verbatim as C<last_error>, for an operator or C<--status> to read,
not for anything to branch on. C<failing_since> is set once, on the first
failure of a run, and survives every further one, so it keeps saying when the
outage started rather than resetting on each attempt.

=head2 record_success

    $agents->record_success('minimax');

Records that C<$name> worked. A no-op, both for the caller (returns C<0>) and
for the state file (nothing is written), when the agent was already C<ok> --
an ordinary successful run would otherwise rewrite the file for no news. For
one that was C<failing> it moves the record to C<ok> and appends a recovery
entry (C<failing_since>, C<recovered_at>, C<seconds>, and the last
C<last_error> if there was one) to a capped history, and returns C<1>. karr
does not learn a reset rhythm from that history; it leaves a legible trail of
outages for whoever -- a person, the coordination agent -- wants to read one
out of it.

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
