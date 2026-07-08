# ABSTRACT: Single-shot foundation daemon — periodic agent execution across karr boards

package App::karr::Foundation;
our $VERSION = '0.400';
use Moo;
use MooX::Options (
  usage_string => 'USAGE: karr-foundation [options]',
);
use Carp qw( croak );
use Path::Tiny;
use YAML::XS ();
use Time::Piece;
use Digest::MD5 qw( md5_hex );
use Try::Tiny;
use App::karr::Git;
use App::karr::BoardStore;
use App::karr::Foundation::Runner;
use App::karr::Foundation::State;
use App::karr::Foundation::Overview;

# Instruction handed to a synthesized agent command via the $PROMPT variable
# when neither the .karr file nor the config overrides it.
our $DEFAULT_PROMPT =
    'Use the karr-coordinator skill: pick the next actionable task on this '
  . 'board, complete it, and move it forward. If you cannot proceed, block '
  . 'the task with a reason.';

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
  doc => 'Run agent even if no board change detected and no open tasks',
);

option dry_run => (
  is  => 'ro',
  doc => 'Print what would run without executing',
);

option verbose => (
  is  => 'ro',
  doc => 'Extra output',
);

option status => (
  is  => 'ro',
  doc => 'Print a read-only overview of every board and exit (no agent runs)',
);

has _stream_to_terminal => (
  is      => 'lazy',
  builder => sub { -t STDOUT || $_[0]->verbose },
);

has _config_data => (
  is      => 'lazy',
  builder => '_build_config_data',
);

sub _build_config_data {
  my ( $self ) = @_;
  my $cfg_path = defined $self->config
    ? path( $self->config )
    : path( $ENV{HOME} )->child( '.config', 'karr-foundation', 'config.yml' );

  unless ( $cfg_path->exists ) {
    warn "karr-foundation: config not found at $cfg_path — nothing to do\n";
    return {};
  }

  my $data = try {
    YAML::XS::LoadFile("$cfg_path");
  } catch {
    croak "Cannot parse config $cfg_path: $_";
  };
  croak "Config must be a YAML mapping" unless ref $data eq 'HASH';
  return $data;
}

# Collaborators split out of this module along its natural seams (see the
# App::karr::Foundation::* classes). Each holds a weak back-reference to this
# foundation for shared options/helpers; delegation keeps the historical
# method names callable directly on the foundation object.

has _runner => (
  is      => 'lazy',
  handles => [qw( _run_command _error_patterns _match_error )],
);

sub _build__runner {
  my ( $self ) = @_;
  return App::karr::Foundation::Runner->new( foundation => $self );
}

has _state => (
  is      => 'lazy',
  handles => [qw(
    _lock_held _acquire_lock _release_lock
    _state_get _state_set
    _cooldown_active _set_cooldown _clear_cooldown
    _bump_attempts _reset_attempts
  )],
);

sub _build__state {
  my ( $self ) = @_;
  return App::karr::Foundation::State->new( foundation => $self );
}

has _overview => (
  is      => 'lazy',
  handles => [qw( _print_overview )],
);

sub _build__overview {
  my ( $self ) = @_;
  return App::karr::Foundation::Overview->new( foundation => $self );
}


# ---------------------------------------------------------------------------
# Public
# ---------------------------------------------------------------------------

sub run {
  my ( $self ) = @_;
  my @repos = $self->_discover_repos;
  unless ( @repos ) {
    warn "karr-foundation: no repos found — check config\n";
    return 1;
  }

  # --status forces the read-only overview regardless of agent config.
  if ( $self->status ) {
    $self->_print_overview( \@repos );
    return 0;
  }

  # foundation is a multi-board coordinator: agent execution is opt-in. When no
  # board has an agent configured, the default action is the overview — a human
  # can use foundation purely to see what is happening across boards.
  my $any_agent = grep {
    defined $self->_agent_command( $_, $self->_load_karr($_) )
  } @repos;
  unless ( $any_agent ) {
    print "No agent configured on any board. Showing overview "
        . "(set 'claude: true' or 'command:' in a .karr file to enable agents).\n\n";
    $self->_print_overview( \@repos );
    return 0;
  }

  for my $repo ( @repos ) {
    try {
      $self->_process_repo( $repo );
    } catch {
      warn "karr-foundation: error in $repo: $_\n";
    };
  }
  return 0;
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

  return @repos;
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

sub _process_repo {
  my ( $self, $repo ) = @_;

  # Check if repo has karr board (either .karr file or karr refs). Resolve the
  # ref via libgit2 so packed refs and worktrees are handled — $repo is an
  # already-known repo root here, so open_ext's walk-up cannot false-match.
  my $has_karr = $repo->child('.karr')->exists
              || App::karr::Git->new( dir => "$repo" )->ref_exists('refs/karr/config');
  unless ( $has_karr ) {
    $self->_say_verbose("skip $repo — no karr board");
    return;
  }

  my $karr = $self->_load_karr( $repo );

  # Resolve the agent command (CLI > default_command > .karr command >
  # claude: true synthesis). Agent execution is opt-in: a board with no agent
  # is shown in the overview, not run.
  my $cmd = $self->_agent_command( $repo, $karr );
  unless ( defined $cmd ) {
    $self->_say_verbose("skip $repo — no agent configured (see --status)");
    return;
  }

  # Check lock — skip if another instance is running
  if ( $self->_lock_held( $repo ) ) {
    $self->_say_verbose("skip $repo — locked by running agent");
    return;
  }

  # Respect exponential cooldown left by a previous common-error run
  if ( $self->_cooldown_active( $repo ) ) {
    my $until = $self->_state_get( $repo, 'cooldown_until' ) // 0;
    $self->_say_verbose( "skip $repo — in cooldown for " . ( $until - time ) . "s" );
    return;
  }

  # Pull latest refs
  $self->_sync_pull( $repo );

  # Decide whether to start a drain at all
  my $should_run = $self->force;
  unless ( $should_run ) {
    my $prev_hash = $self->_state_get( $repo, 'hash' ) // '';
    my $curr_hash = $self->_ref_hash( $repo ) // '';
    my $on_idle   = $karr->{on_idle} // 'skip';
    $should_run = ( $curr_hash ne $prev_hash )
               || $self->_has_actionable_tasks( $repo )
               || ( $on_idle eq 'always-run' );
  }

  unless ( $should_run ) {
    $self->_say_verbose("skip $repo — no board change and no actionable tasks");
    return;
  }

  # Acquire lock, drain, release
  $self->_acquire_lock( $repo );
  my $result = try {
    $self->_drain_repo( $repo, $karr, $cmd );
  } catch {
    warn "karr-foundation: drain error in $repo: $_\n";
    { outcome => 'error', exit => 1 };
  };
  $self->_release_lock( $repo );

  # Exponential cooldown bookkeeping: grow on common-error, reset otherwise
  if ( ( $result->{outcome} // '' ) eq 'common-error' ) {
    $self->_set_cooldown( $repo, $karr );
  } else {
    $self->_clear_cooldown( $repo );
  }

  # Update state
  $self->_state_set( $repo,
    hash      => $self->_ref_hash( $repo ) // '',
    last_run  => localtime->datetime,
    last_exit => $result->{exit} // 0,
  );
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

# Tasks the agent engaged (claimed / in-progress) but did not move across a
# run — still actionable and byte-identical before/after. These are the only
# tasks that count toward an auto-block.
sub _stuck_tasks {
  my ( $self, $before, $after ) = @_;
  my @stuck;
  for my $id ( sort { $a <=> $b } keys %$after ) {
    my $a = $after->{$id};
    next unless $self->_is_actionable( $a );
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
# { outcome => progress|idle|common-error|error, exit => N }.
sub _drain_repo {
  my ( $self, $repo, $karr, $cmd ) = @_;
  my $max_runtime  = $karr->{max_runtime}    // 1800;
  my $max_attempts = $karr->{max_attempts}   // 2;
  my $max_iter     = $karr->{max_iterations} // 50;
  my $drain        = exists $karr->{drain} ? $karr->{drain} : 1;
  my $patterns     = $self->_error_patterns( $karr );

  # Use the resolved command, not $karr->{command}
  $cmd //= $karr->{command};

  my $loop_start = time;
  my $last_exit  = 0;
  my $outcome    = 'idle';
  my $first      = 1;
  my $iter       = 0;

  while ( 1 ) {
    my %before = $self->_task_states( $repo );
    my @actionable = grep { $self->_is_actionable( $before{$_} ) } keys %before;

    # Once we have run at least once, stop when the board is drained, the
    # wall-clock budget is spent, or we hit the hard iteration cap.
    last if !$first && !@actionable;
    last if !$first && ( time - $loop_start ) >= $max_runtime;
    last if $iter >= $max_iter;

    my $hash_before = $self->_ref_hash( $repo ) // '';
    my ( $exit, $output ) = $self->_run_command( $repo, $karr, $cmd );
    $last_exit = $exit;
    $first     = 0;
    $iter++;

    # Common error we can observe (bad exit, timeout, or a known log pattern):
    # don't penalize any task — leave the board untouched and back off.
    my $err = ( $exit != 0 ) ? "exit=$exit" : undef;
    $err //= $self->_match_error( $output, $patterns );
    if ( defined $err ) {
      $self->_append_log( $repo, "COMMON-ERROR $err" );
      $self->_state_set( $repo, last_error => $err );
      $outcome = 'common-error';
      last;
    }

    my $hash_after = $self->_ref_hash( $repo ) // '';
    my $progressed = ( $hash_before ne $hash_after ) ? 1 : 0;
    $outcome = 'progress' if $progressed;

    my %after = $self->_task_states( $repo );
    my @stuck = $self->_stuck_tasks( \%before, \%after );

    # Reset the attempt counter for any task that is no longer stuck
    # (advanced, blocked, or gone), then bump/auto-block the stuck ones.
    my %is_stuck = map { $_ => 1 } @stuck;
    my $attempts = $self->_state_get( $repo, 'attempts' ) // {};
    $self->_reset_attempts( $repo, $_ ) for grep { !$is_stuck{$_} } keys %$attempts;

    for my $id ( @stuck ) {
      my $n = $self->_bump_attempts( $repo, $id );
      next if $n < $max_attempts;
      $self->_autoblock_task( $repo, $id,
        "auto-block: no progress after $n attempts (foundation)" );
      $self->_reset_attempts( $repo, $id );
    }

    # Agent did nothing useful and grabbed nothing — stop, nothing to attribute.
    if ( !$progressed && !@stuck ) {
      $outcome = 'idle';
      last;
    }

    last unless $drain;   # drain disabled → single run
  }

  return { outcome => $outcome, exit => $last_exit };
}

# ---------------------------------------------------------------------------
# Auto-block (in-process via BoardStore, no karr CLI)
# ---------------------------------------------------------------------------

sub _autoblock_task {
  my ( $self, $repo, $id, $reason ) = @_;
  return if $self->dry_run;
  my $git = App::karr::Git->new( dir => "$repo" );
  return unless $git->is_repo;
  my $store = App::karr::BoardStore->new( git => $git );
  my $task  = $store->find_task( $id ) or return;
  $task->blocked( $reason );
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

# The resolved agent command string, or undef when no agent is configured.
# Priority: CLI --command > config default_command > .karr command >
# 'claude: true' shorthand (per-repo, then global).
sub _agent_command {
  my ( $self, $repo, $karr ) = @_;
  my $cfg = $self->_config_data;

  for my $candidate ( $self->command, $cfg->{default_command}, $karr->{command} ) {
    return $candidate if defined $candidate && length $candidate;
  }

  my $claude = exists $karr->{claude} ? $karr->{claude} : $cfg->{claude};
  return $self->_claude_command($karr) if $claude;

  return undef;
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
sub _prompt_for {
  my ( $self, $karr ) = @_;
  return $karr->{prompt}
      // $self->_config_data->{default_prompt}
      // $DEFAULT_PROMPT;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::karr::Foundation - Single-shot foundation daemon — periodic agent execution across karr boards

=head1 VERSION

version 0.400

=head1 SYNOPSIS

    # Typical cron entry — run every 5 minutes
    */5 * * * * /path/to/karr-foundation

    # Force a run regardless of board state
    karr-foundation --force

    # Preview what would run
    karr-foundation --dry-run --verbose

    # Read-only overview of every board (no agent runs)
    karr-foundation --status

=head1 DESCRIPTION

F<karr-foundation> is a single-shot, idempotent CLI meant to be invoked
periodically (cron, systemd-timer, while-loop). It scans configured karr
boards, detects changes or open work, and B<drains> each board by invoking the
configured agent command repeatedly until no actionable task remains.

B<Config file:> C<~/.config/karr-foundation/config.yml> (or C<--config>).

  dirs:
    - /path/to/repo1
    - /path/to/repo2

  scan:
    - /path/to/parent-dir   # finds all direct subdirs that have a .karr file

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
  drain: true               # loop until drained (default) | false for single run
  max_attempts: 2           # stalls on one task before auto-block (default: 2)
  max_iterations: 50        # hard cap on drain iterations (default: 50)
  cooldown_base: 1          # cooldown minutes at level 0 (default: 1)
  cooldown_max: 64          # cooldown ceiling in minutes (default: 64)
  error_patterns:           # extra case-insensitive substrings → common-error
    - my custom api error

C<claude>, C<claude_bin>, C<claude_max_turns>, C<claude_permission_mode>,
C<command> and C<prompt>/C<default_prompt> may also be set globally in the
config file; the per-repo F<.karr> value wins.

B<Coordinator and overview.> Agent execution is opt-in — a board runs an agent
only via C<command> or C<< claude: true >>. When B<no> board has an agent
configured, the default action is a read-only B<overview> of every board
(status counts, in-progress/blocked tasks, lock and cooldown state); a human
can use foundation purely to coordinate their own work. C<--status> forces the
overview regardless of configuration.

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
result from what foundation can observe — exit code, board ref movement, and
the run's captured output:

=over 4

=item * B<progress> — the board changed; keep draining.

=item * B<stall> — a task the agent claimed / left C<in-progress> did not move.
That task's attempt counter is bumped; at C<max_attempts> it is auto-blocked
(C<blocked: auto-block: no progress after N attempts (foundation)>) so it drops
out of the actionable set and the drain can finish. The agent may always set a
better reason itself with C<karr edit --block>; the auto-block is a fallback.

=item * B<common-error> — a non-zero/timeout exit or a C<error_patterns> match
(rate limit, auth, network, 5xx, …). No task is penalized; the repo enters an
exponential cooldown (C<cooldown_base> × 2^level minutes, capped at
C<cooldown_max>, reset on the next clean run) and is skipped until it expires.

=item * B<idle> — the agent did nothing and grabbed nothing; stop.

=back

All state files are gitignored: C<.karr.state> (board hash, per-task attempts,
cooldown, last error), C<.karr.lock>, C<.karr.log>.

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

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
