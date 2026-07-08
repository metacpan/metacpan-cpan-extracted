# ABSTRACT: karr-foundation command execution — fork/pipe/select tee + error classification

package App::karr::Foundation::Runner;
our $VERSION = '0.400';
use Moo;
use Carp qw( croak );
use IO::Select;
use IO::Handle ();


has foundation => (
  is       => 'ro',
  weak_ref => 1,
  required => 1,
);

# ---------------------------------------------------------------------------
# Command execution
# ---------------------------------------------------------------------------

sub _run_command {
  my ( $self, $repo, $karr, $cmd ) = @_;
  my $command      = $cmd // $karr->{command};
  my $max_runtime  = $karr->{max_runtime} // 1800;
  my $stream_terms = $self->foundation->_stream_to_terminal;

  # Environment for the child (and all karr calls it spawns). Set before the
  # substitution so a command template — including the synthesized claude
  # command — can reference $PROMPT, $KARR_REPO, etc.
  local $ENV{KARR_REPO} = "$repo";
  local $ENV{KARR_ROLE} = 'agent';
  local $ENV{PROMPT}    = $self->foundation->_prompt_for($karr);

  # Env-var substitution in command string
  $command =~ s/\$\{(\w+)\}/$ENV{$1} \/\/ ''/ge;
  $command =~ s/\$(\w+)/$ENV{$1} \/\/ ''/ge;

  $self->foundation->_append_log( $repo, "START command=$command" );
  $self->foundation->_say_verbose("exec in $repo: $command");

  if ( $self->foundation->dry_run ) {
    $self->foundation->_append_log( $repo, "DRY-RUN (skipped)" );
    return ( 0, '' );
  }

  my $log_file = $repo->child('.karr.log');

  # Native pipe: the child writes stdout+stderr, the parent reads. The parent
  # is the tee — it fans each chunk to the persistent log, the terminal (when
  # streaming), and an in-memory buffer for error scanning. No external tee
  # process to race, and the run's output is captured directly (no re-slurping
  # the log via byte offsets).
  pipe( my $reader, my $writer ) or croak "pipe failed: $!";

  my $pid = fork;
  croak "fork failed: $!" unless defined $pid;

  if ( $pid == 0 ) {
    # child
    close $reader;
    chdir "$repo" or die "chdir $repo: $!";
    open( STDOUT, '>&', $writer ) or die "dup stdout: $!";
    open( STDERR, '>&STDOUT' )    or die "dup stderr: $!";
    exec( '/bin/sh', '-c', $command ) or die "exec: $!";
  }

  # parent
  close $writer;
  open( my $log_fh, '>>', "$log_file" ) or croak "open log: $!";
  $log_fh->autoflush(1);

  my $started   = time;
  my $output    = '';
  my $timed_out = 0;
  my $sel       = IO::Select->new($reader);

  while (1) {
    my $wait;
    if ( $max_runtime > 0 ) {
      $wait = $max_runtime - ( time - $started );
      if ( $wait <= 0 ) { $timed_out = 1; last }
    }
    # undef $wait => block indefinitely (max_runtime: 0 disables the timeout).
    my @ready = $sel->can_read($wait);
    unless (@ready) {
      # Spurious wakeup (signal) or deadline. Only the deadline ends the loop.
      next unless $max_runtime > 0;
      if ( time - $started >= $max_runtime ) { $timed_out = 1; last }
      next;
    }
    my $chunk;
    my $n = sysread( $reader, $chunk, 65536 );
    last if !defined $n;   # read error
    last if $n == 0;       # EOF — the command closed its output
    print {$log_fh} $chunk;
    print $chunk if $stream_terms;
    $output .= $chunk;
  }

  my $exit_code;
  if ($timed_out) {
    my $elapsed = time - $started;
    $self->foundation->_append_log( $repo, "TIMEOUT after ${elapsed}s — sending SIGTERM to $pid" );
    kill 'TERM', $pid;
    sleep 2;
    kill 'KILL', $pid;
    waitpid( $pid, 0 );
    $exit_code = -1;
  } else {
    waitpid( $pid, 0 );
    $exit_code = $? >> 8;
  }

  close $reader;
  close $log_fh;

  my $elapsed = time - $started;
  $self->foundation->_append_log( $repo, "END elapsed=${elapsed}s exit=$exit_code" );
  return ( $exit_code, $output );
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

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::karr::Foundation::Runner - karr-foundation command execution — fork/pipe/select tee + error classification

=head1 VERSION

version 0.400

=head1 DESCRIPTION

L<App::karr::Foundation::Runner> runs a single agent command for
L<App::karr::Foundation>. It forks the command under C</bin/sh -c>, reads its
combined stdout/stderr over a native pipe, and tees each chunk to the
persistent C<.karr.log>, the terminal (when streaming), and an in-memory buffer
used for error scanning, enforcing the per-run C<max_runtime> timeout. It also
classifies observable common errors (rate limit, auth, network, 5xx, ...). A
weak back-reference to the owning foundation supplies shared options and helpers
(C<dry_run>, C<_stream_to_terminal>, C<_prompt_for>, C<_append_log>,
C<_say_verbose>).

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
