# ABSTRACT: karr-foundation per-repo state — lock file, JSON state, cooldown backoff

package App::karr::Foundation::State;
our $VERSION = '0.401';
use Moo;
use Path::Tiny;
use JSON::MaybeXS qw( encode_json decode_json );
use Try::Tiny;


has foundation => (
  is       => 'ro',
  weak_ref => 1,
  required => 1,
);

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
  return if $self->foundation->dry_run;
  $self->_lock_file( $repo )->spew_utf8( "$$\n" );
}

sub _release_lock {
  my ( $self, $repo ) = @_;
  return if $self->foundation->dry_run;
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
  return if $self->foundation->dry_run;
  my $state_file = $self->_state_file( $repo );
  my $data = {};
  if ( $state_file->exists ) {
    $data = try { decode_json( $state_file->slurp_utf8 ) } catch { {} };
  }
  $data->{$_} = $kv{$_} for keys %kv;
  $state_file->spew_utf8( encode_json( $data ) );
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
  $self->foundation->_say_verbose( "cooldown $repo — ${minutes}m (level " . ( $level + 1 ) . ")" );
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

version 0.401

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
