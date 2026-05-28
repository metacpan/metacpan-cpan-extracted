# ABSTRACT: Single-shot foundation daemon — periodic agent execution across karr boards

package App::karr::Foundation;
our $VERSION = '0.300';
use Moo;
use MooX::Options (
  usage_string => 'USAGE: karr-foundation [options]',
);
use Carp qw( croak );
use Path::Tiny;
use YAML::XS ();
use JSON::MaybeXS qw( encode_json decode_json );
use Time::Piece;
use POSIX qw( WNOHANG );
use Digest::MD5 qw( md5_hex );
use Try::Tiny;
use App::karr::Git;
use App::karr::BoardStore;

option config => (
  is     => 'ro',
  format => 's',
  doc    => 'Path to config file (default: ~/.config/karr-foundation/config.yml)',
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
  for my $scan_dir ( @{ $self->_config_data->{scan} // [] } ) {
    my $p = path( $scan_dir );
    unless ( $p->is_dir ) {
      warn "karr-foundation: scan dir not found: $scan_dir\n";
      next;
    }
    for my $child ( $p->children ) {
      push @repos, $child
        if $child->is_dir && $child->child('.karr')->exists;
    }
  }

  return @repos;
}

# ---------------------------------------------------------------------------
# Per-repo processing
# ---------------------------------------------------------------------------

sub _process_repo {
  my ( $self, $repo ) = @_;
  my $dot_karr = $repo->child('.karr');
  unless ( $dot_karr->exists ) {
    $self->_say_verbose("skip $repo — no .karr file");
    return;
  }

  my $karr = $self->_load_karr( $repo );
  unless ( defined $karr->{command} ) {
    warn "karr-foundation: $repo/.karr has no 'command' key — skipping\n";
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
    $self->_drain_repo( $repo, $karr );
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
  my ( $self, $repo, $karr ) = @_;
  my $max_runtime  = $karr->{max_runtime}    // 1800;
  my $max_attempts = $karr->{max_attempts}   // 2;
  my $max_iter     = $karr->{max_iterations} // 50;
  my $drain        = exists $karr->{drain} ? $karr->{drain} : 1;
  my $patterns     = $self->_error_patterns( $karr );

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
    my ( $exit, $output ) = $self->_run_command( $repo, $karr );
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
# Common-error detection
# ---------------------------------------------------------------------------

sub _error_patterns {
  my ( $self, $karr ) = @_;
  my @default = (
    'rate limit', 'rate-limit', 'usage limit', 'quota exceeded', 'quota',
    'overloaded', 'too many requests', '429', '529',
    'unauthorized', 'forbidden', 'authentication', 'invalid api key',
    'credentials', '401', '403',
    'connection refused', 'connection reset', 'network', 'timed out',
    'service unavailable', '503', '500 internal',
  );
  return [ @default, @{ $karr->{error_patterns} // [] } ];
}

sub _match_error {
  my ( $self, $text, $patterns ) = @_;
  return undef unless defined $text && length $text;
  for my $p ( @$patterns ) {
    return $p if $text =~ /\Q$p\E/i;
  }
  return undef;
}

# ---------------------------------------------------------------------------
# Attempt counter (per task, persisted in .karr.state)
# ---------------------------------------------------------------------------

sub _bump_attempts {
  my ( $self, $repo, $id ) = @_;
  my $a = $self->_state_get( $repo, 'attempts' ) // {};
  $a->{$id} = ( $a->{$id} // 0 ) + 1;
  $self->_state_set( $repo, attempts => $a );
  return $a->{$id};
}

sub _reset_attempts {
  my ( $self, $repo, $id ) = @_;
  my $a = $self->_state_get( $repo, 'attempts' ) // {};
  return unless exists $a->{$id};
  delete $a->{$id};
  $self->_state_set( $repo, attempts => $a );
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
# Exponential cooldown (1, 2, 4, 8, ... minutes, capped) on common-error
# ---------------------------------------------------------------------------

sub _cooldown_active {
  my ( $self, $repo ) = @_;
  my $until = $self->_state_get( $repo, 'cooldown_until' ) or return 0;
  return time < $until ? 1 : 0;
}

sub _set_cooldown {
  my ( $self, $repo, $karr ) = @_;
  return if $self->dry_run;
  my $base    = $karr->{cooldown_base} // 1;    # minutes at level 0
  my $cap     = $karr->{cooldown_max}  // 64;   # minutes ceiling
  my $level   = $self->_state_get( $repo, 'cooldown_level' ) // 0;
  my $minutes = $base * ( 2 ** $level );
  $minutes = $cap if $minutes > $cap;
  $self->_state_set( $repo,
    cooldown_level => $level + 1,
    cooldown_until => time + $minutes * 60,
  );
  $self->_say_verbose( "cooldown $repo — ${minutes}m (level " . ( $level + 1 ) . ")" );
  return $minutes;
}

sub _clear_cooldown {
  my ( $self, $repo ) = @_;
  return if $self->dry_run;
  my $level = $self->_state_get( $repo, 'cooldown_level' ) // 0;
  return unless $level;
  $self->_state_set( $repo, cooldown_level => 0, cooldown_until => 0 );
}

# ---------------------------------------------------------------------------
# Command execution
# ---------------------------------------------------------------------------

sub _run_command {
  my ( $self, $repo, $karr ) = @_;
  my $command     = $karr->{command};
  my $max_runtime = $karr->{max_runtime} // 1800;

  # Env-var substitution in command string
  $command =~ s/\$\{(\w+)\}/$ENV{$1} \/\/ ''/ge;
  $command =~ s/\$(\w+)/$ENV{$1} \/\/ ''/ge;

  $self->_append_log( $repo, "START command=$command" );
  $self->_say_verbose("exec in $repo: $command");

  if ( $self->dry_run ) {
    $self->_append_log( $repo, "DRY-RUN (skipped)" );
    return ( 0, '' );
  }

  my $log_file = $repo->child('.karr.log');
  # Remember where this run's output begins so we can scan it afterwards.
  my $offset = $log_file->exists ? -s "$log_file" : 0;
  local $ENV{KARR_REPO} = "$repo";

  my $pid = fork;
  croak "fork failed: $!" unless defined $pid;

  if ( $pid == 0 ) {
    # child
    chdir "$repo" or die "chdir $repo: $!";
    open( STDOUT, '>>', "$log_file" ) or die "open log: $!";
    open( STDERR, '>&STDOUT' )       or die "dup stderr: $!";
    exec( '/bin/sh', '-c', $command ) or die "exec: $!";
  }

  # parent — wait with hard timeout
  my $started   = time;
  my $exit_code = 0;
  eval {
    local $SIG{ALRM} = sub { die "timeout\n" };
    alarm( $max_runtime );
    waitpid( $pid, 0 );
    alarm( 0 );
    $exit_code = $? >> 8;
  };
  if ( $@ ) {
    if ( $@ eq "timeout\n" ) {
      my $elapsed = time - $started;
      $self->_append_log( $repo, "TIMEOUT after ${elapsed}s — sending SIGTERM to $pid" );
      kill 'TERM', $pid;
      sleep 2;
      kill 'KILL', $pid;
      waitpid( $pid, WNOHANG );
      $exit_code = -1;
    } else {
      die $@;
    }
  }

  # Capture just this run's output (between $offset and now) for error scanning.
  my $output = '';
  if ( $log_file->exists ) {
    my $all = $log_file->slurp_utf8;
    $output = length($all) > $offset ? substr( $all, $offset ) : '';
  }

  my $elapsed = time - $started;
  $self->_append_log( $repo, "END elapsed=${elapsed}s exit=$exit_code" );
  return ( $exit_code, $output );
}

# ---------------------------------------------------------------------------
# Lock file
# ---------------------------------------------------------------------------

sub _lock_file { path( $_[1]->child('.karr.lock') ) }

sub _lock_held {
  my ( $self, $repo ) = @_;
  my $lock = $self->_lock_file( $repo );
  return 0 unless $lock->exists;
  my $pid = $lock->slurp_utf8;
  chomp $pid;
  return 0 unless $pid =~ /^\d+$/;
  # Check if PID is alive
  return kill( 0, $pid ) ? 1 : 0;
}

sub _acquire_lock {
  my ( $self, $repo ) = @_;
  return if $self->dry_run;
  $self->_lock_file( $repo )->spew_utf8( "$$\n" );
}

sub _release_lock {
  my ( $self, $repo ) = @_;
  return if $self->dry_run;
  my $lock = $self->_lock_file( $repo );
  $lock->remove if $lock->exists;
}

# ---------------------------------------------------------------------------
# State file
# ---------------------------------------------------------------------------

sub _state_file { path( $_[1]->child('.karr.state') ) }

sub _state_get {
  my ( $self, $repo, $key ) = @_;
  my $state_file = $self->_state_file( $repo );
  return undef unless $state_file->exists;
  my $data = try { decode_json( $state_file->slurp_utf8 ) } catch { {} };
  return $data->{$key};
}

sub _state_set {
  my ( $self, $repo, %kv ) = @_;
  return if $self->dry_run;
  my $state_file = $self->_state_file( $repo );
  my $data = {};
  if ( $state_file->exists ) {
    $data = try { decode_json( $state_file->slurp_utf8 ) } catch { {} };
  }
  $data->{$_} = $kv{$_} for keys %kv;
  $state_file->spew_utf8( encode_json( $data ) );
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

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::karr::Foundation - Single-shot foundation daemon — periodic agent execution across karr boards

=head1 VERSION

version 0.300

=head1 SYNOPSIS

    # Typical cron entry — run every 5 minutes
    */5 * * * * /path/to/karr-foundation

    # Force a run regardless of board state
    karr-foundation --force

    # Preview what would run
    karr-foundation --dry-run --verbose

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

  command: claude -p "Use karr-coordinator agent, pick next task"
  on_idle: skip             # 'skip' (default) | 'always-run'
  max_runtime: 1800         # seconds: per-command SIGKILL + total drain budget
  drain: true               # loop until drained (default) | false for single run
  max_attempts: 2           # stalls on one task before auto-block (default: 2)
  max_iterations: 50        # hard cap on drain iterations (default: 50)
  cooldown_base: 1          # cooldown minutes at level 0 (default: 1)
  cooldown_max: 64          # cooldown ceiling in minutes (default: 64)
  error_patterns:           # extra case-insensitive substrings → common-error
    - my custom api error

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
