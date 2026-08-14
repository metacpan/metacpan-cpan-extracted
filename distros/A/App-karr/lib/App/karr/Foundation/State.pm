# ABSTRACT: karr-foundation per-repo state — lock file, JSON state, cooldown backoff

package App::karr::Foundation::State;
our $VERSION = '0.500';
use Moo;
use Path::Tiny;
use Fcntl qw( LOCK_EX LOCK_NB LOCK_UN );
use App::karr::Encoding qw( json_encode json_decode );
use Try::Tiny;


has foundation => (
  is       => 'ro',
  weak_ref => 1,
  required => 1,
);

# ---------------------------------------------------------------------------
# Lock file — flock-gated, holds the work, not the watcher
# ---------------------------------------------------------------------------
#
# The lock names the work, not the foundation process: a stale foundation (a
# SIGTERM-restart, a segfault, a hung shell waiting for a child that has been
# reaped by init) used to leave a .karr.lock naming a pid nobody could ever
# own again, while the lock file was the only thing keeping the next tick from
# starting a second agent (#162, #163). The gate is now flock(2): the
# foundation that holds the exclusive lock on the file holds the board, and
# the recorded pid/pgid are evidence (for `karr-foundation --status` and the
# SIGTERM handler) rather than authority.
#
# File contents are JSON: { pid, pgid, agent_pid, started }. flock on an open
# fd is the source of truth: the Foundation instance keeps an open fd for the
# lifetime of the lock and only closes it on release. A stale .karr.lock — one
# nobody flocks — is not held even if the recorded pid is alive in some other
# context, and a process whose recorded pid matches $$ but which never flock'd
# the file has no claim.
#
# Two ticks that overlap, the normal case while a max_runtime-sized drain is
# still running and cron fires again, now race on flock: exactly one wins,
# exactly one is told to skip (#162). The "tight while-loop" the POD used to
# recommend no longer relies on the lock file as a polite signal — under the
# new semantics two consecutive tight loops cannot both pass _lock_held,
# because the second one will lose the flock race. That is intentional and
# desired.

sub _lock_file { path( $_[1]->child('.karr.lock') ) }

# Read the lock metadata — pid/pgid/agent_pid/started — without taking the
# flock. Used by the SIGTERM handler in Foundation.pm and by --status, which
# have to look at the file without acquiring it. Unreadable files (missing,
# corrupt) yield undef rather than dying — the caller can fall back to "no
# live agent" if it wants.
#
# We do NOT use Path::Tiny's slurp here: slurp opens a second fd and calls
# flock() LOCK_EX on it (blocking). When this foundation still holds the
# lock through its own fd, the second fd's flock blocks forever — the
# documented quirk is that flock per-open-file-description can deadlock
# when one process owns the only exclusive lock. Use raw sysread instead;
# the flock doesn't block our own reads, only other flocks.
sub _read_lock_metadata {
  my ( $self, $repo ) = @_;
  my $lock = $self->_lock_file( $repo );
  return undef unless $lock->exists;
  open( my $fh, '<', "$lock" ) or return undef;
  my $raw = '';
  my $buf = '';
  while (1) {
    my $n = sysread( $fh, $buf, 4096 );
    last unless defined $n && $n;
    $raw .= $buf;
    last if $n < 4096;
  }
  close $fh;
  return undef unless length $raw;
  my $data = try { json_decode($raw) } catch { return undef };
  return ref $data eq 'HASH' ? $data : undef;
}

# Held iff someone holds the flock. We probe with LOCK_EX LOCK_NB: on success
# the lock is stale (no holder), we release and report 0; on EWOULDBLOCK
# someone else owns it and we report 1. A file we can read but not flock is
# held; a file we can read and flock is not. Missing files are not held.
sub _lock_held {
  my ( $self, $repo ) = @_;
  my $lock = $self->_lock_file( $repo );
  return 0 unless $lock->exists;
  open( my $fh, '<', "$lock" ) or do {
    # Unlinked by another tick that just released; the next acquire will
    # recreate it. Treat as not held.
    return 0;
  };
  if ( flock( $fh, LOCK_EX | LOCK_NB ) ) {
    flock( $fh, LOCK_UN );
    close $fh;
    return 0;
  }
  close $fh;
  return 1;
}

# Try to take the lock. Returns 1 on success, 0 on EWOULDBLOCK (someone else
# holds it). On success the Foundation instance keeps an open fd to the file
# in $self->foundation->{_lock_fhs}{$repo}; the fd holds the flock until
# _release_lock closes it. Without that open fd the flock would evaporate on
# close — flock is per-process-per-fd, not per-path.
sub _acquire_lock {
  my ( $self, $repo, %meta ) = @_;
  return 1 if $self->foundation->dry_run;
  my $lock = $self->_lock_file( $repo );
  open( my $fh, '>>', "$lock" ) or return 0;
  unless ( flock( $fh, LOCK_EX | LOCK_NB ) ) {
    close $fh;
    return 0;
  }
  # We hold the exclusive lock. Truncate so a stale write from a previous
  # holder doesn't survive the upgrade — flock is process-scoped to us now,
  # but truncate ensures our write below is the only content.
  truncate $fh, 0;
  seek $fh, 0, 0;
  my $pid = $meta{pid} // $$;
  my $data = {
    pid       => $pid,
    pgid      => $meta{pgid},
    agent_pid => $meta{agent_pid},
    started   => $meta{started} // time,
  };
  $fh->autoflush(1);
  $fh->print( json_encode($data) );
  # Stash the open fd so the flock outlives this method. Closing the original
  # would drop the flock immediately and the next probe would find the lock
  # free. Foundation's instance attribute owns the fds until _release_lock.
  $self->foundation->_keep_lock_fh( $repo, $fh );
  return 1;
}

# Release iff we still own it. The Foundation holds the lock fd in its
# instance state; we recover it, close it (drops the flock — flock is per
# open file description), then read the recorded pid and unlink. We do NOT
# re-flock the same file from a second fd: on Linux flock locks are per open
# file description, not per process, so a second fd from the same process
# attempting LOCK_EX|LOCK_NB against the first fd's LOCK_EX fails with
# EWOULDBLOCK and we would skip the unlink — locking ourselves out forever.
# The fd is the proof we held the lock; trust it, and trust the recorded pid
# in the file to catch the only case it could be wrong (a recycled pid
# matching $$ by accident).
#
# Order matters: close the fd BEFORE reading the file. With the lock fd
# still open and flock'd, Path::Tiny's slurp_utf8 opens its own fd and then
# blocks indefinitely on read (a documented quirk of certain filesystems when
# a single process holds the only flock). Releasing the flock first makes
# the read return immediately.
sub _release_lock {
  my ( $self, $repo ) = @_;
  return if $self->foundation->dry_run;
  my $lock = $self->_lock_file( $repo );
  my $fh = $self->foundation->_take_lock_fh( $repo );
  return unless $fh;
  close $fh;
  my $meta = $self->_read_lock_metadata( $repo );
  if ( !$meta || !defined $meta->{pid} || $meta->{pid} == $$ ) {
    $lock->remove if $lock->exists;
  }
  # else: the file's recorded pid is not ours — somebody else's foundation
  # took the file out from under us (would only happen if _lock_held passed
  # spuriously, which flock LOCK_EX|LOCK_NB at acquire guarantees cannot).
  # Leave the file alone; the next tick that successfully acquires will see
  # its own pid and release its own lock.
  return;
}

# Force-release for the SIGTERM handler: we are on the way out and cannot
# trust the normal release path to run. Same rule — the open fd is proof,
# the recorded pid is the second check — but without writing to .karr.log
# or opening anything else. The handler is a process about to die, so
# leaving a stale fd behind doesn't matter.
sub _force_release_lock {
  my ( $self, $repo ) = @_;
  return if $self->foundation->dry_run;
  my $lock = $self->_lock_file( $repo );
  my $fh = $self->foundation->_take_lock_fh( $repo );
  return unless $fh;
  close $fh;
  my $meta = $self->_read_lock_metadata( $repo );
  if ( $meta && defined $meta->{pid} && $meta->{pid} != $$ ) {
    # Same protection as _release_lock: a recycled pid is not us.
    return;
  }
  $lock->remove if $lock->exists;
  return;
}

# ---------------------------------------------------------------------------
# State file
# ---------------------------------------------------------------------------

sub _state_file { path( $_[1]->child('.karr.state') ) }

sub _state_get {
  my ( $self, $repo, $key ) = @_;
  my $state_file = $self->_state_file( $repo );
  return undef unless $state_file->exists;
  my $data = try { json_decode( $state_file->slurp_utf8 ) } catch { {} };
  return $data->{$key};
}

sub _state_set {
  my ( $self, $repo, %kv ) = @_;
  return if $self->foundation->dry_run;
  my $state_file = $self->_state_file( $repo );
  my $data = {};
  if ( $state_file->exists ) {
    $data = try { json_decode( $state_file->slurp_utf8 ) } catch { {} };
  }
  $data->{$_} = $kv{$_} for keys %kv;
  $state_file->spew_utf8( json_encode( $data ) );
}

# Drop keys entirely rather than null them: .karr.state is read by an operator
# as much as by karr, and a key that is still there describes the last run. A
# last_error left behind by a run three cooldowns ago, sitting next to
# last_exit: 0, reads as a contradiction nobody can resolve (#160).
sub _state_del {
  my ( $self, $repo, @keys ) = @_;
  return if $self->foundation->dry_run;
  my $state_file = $self->_state_file( $repo );
  return unless $state_file->exists;
  my $data = try { json_decode( $state_file->slurp_utf8 ) } catch { {} };
  my $gone = 0;
  for my $key ( @keys ) {
    next unless exists $data->{$key};
    delete $data->{$key};
    $gone++;
  }
  return unless $gone;
  $state_file->spew_utf8( json_encode( $data ) );
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
  return if $self->foundation->dry_run;
  my $base    = $karr->{cooldown_base} // 1;    # minutes at level 0
  my $cap     = $karr->{cooldown_max}  // 64;   # minutes ceiling
  my $level   = $self->_state_get( $repo, 'cooldown_level' ) // 0;
  my $minutes = $base * ( 2 ** $level );
  $minutes = $cap if $minutes > $cap;
  $self->_state_set( $repo,
    cooldown_level => $level + 1,
    cooldown_until => time + $minutes * 60,
  );
  $self->foundation->_say_verbose( "cooldown $repo \x{2014} ${minutes}m (level " . ( $level + 1 ) . ")" );
  return $minutes;
}

sub _clear_cooldown {
  my ( $self, $repo ) = @_;
  return if $self->foundation->dry_run;
  my $level = $self->_state_get( $repo, 'cooldown_level' ) // 0;
  return unless $level;
  $self->_state_set( $repo, cooldown_level => 0, cooldown_until => 0 );
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

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::karr::Foundation::State - karr-foundation per-repo state — lock file, JSON state, cooldown backoff

=head1 VERSION

version 0.500

=head1 DESCRIPTION

L<App::karr::Foundation::State> owns the gitignored per-repo sidecar files that
L<App::karr::Foundation> keeps outside the board: the advisory C<.karr.lock>,
the JSON C<.karr.state> (board hash, per-task attempt counters, cooldown), and
the exponential cooldown backoff applied after a common-error run. It holds a
weak back-reference to the owning foundation for shared options (C<dry_run>) and
helpers (C<_say_verbose>).

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
