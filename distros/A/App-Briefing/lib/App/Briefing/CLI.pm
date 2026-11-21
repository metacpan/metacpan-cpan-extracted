package App::Briefing::CLI;
# ABSTRACT: Command-line interface for App::Briefing

use Moo;
use App::Briefing;
use App::Briefing::Team;
use Encode qw( encode_utf8 );
use JSON::MaybeXS ();
use namespace::clean;

our $VERSION = '0.006000';

has _json => ( is => 'lazy', init_arg => undef );

sub app_class { 'App::Briefing' }


sub _build__json {
  my ( $self ) = @_;
  return JSON::MaybeXS->new(
    allow_nonref    => 0,
    canonical       => 1,
    convert_blessed => 1,
    utf8            => 1,
  );
}

sub _usage {
  my ( $self ) = @_;
  return <<'USAGE';
Usage:
  briefing hook [subagent-start|pre-tool-use|session-start]
  briefing hook marketplace-notice
  briefing doctor [--cwd DIR] [--harness claude|codex|both]
  briefing doctor --tsv [--cwd DIR]
  briefing notice
  briefing --help
  briefing --version
USAGE
}

sub _write_stdout {
  my ( $self, $text ) = @_;
  print STDOUT encode_utf8($text);
  return;
}

sub _write_stderr {
  my ( $self, $text ) = @_;
  print STDERR encode_utf8($text);
  return;
}

sub _write_json {
  my ( $self, $output, $newline ) = @_;
  print STDOUT $self->_json->encode($output);
  print STDOUT "\n" if $newline;
  return;
}

sub _application {
  my ( $self, %attributes ) = @_;
  my $class = $self->app_class;
  return $class->new(%attributes);
}

my %HOOK_EVENTS = (
  subagentstart => 'SubagentStart',
  pretooluse    => 'PreToolUse',
  sessionstart  => 'SessionStart',
);

sub _hook_event {
  my ( $self, $name ) = @_;
  ( my $key = lc $name ) =~ s/[-_]//g;
  return $HOOK_EVENTS{$key};
}

sub _run_hook {
  my ( $self, $event ) = @_;
  local $/;
  my $raw = <STDIN>;
  return 0 unless defined $raw && length $raw;
  my $payload = eval { $self->_json->decode($raw) };
  return 0 unless ref $payload eq 'HASH';

  my $result = $self->_application->process_hook(
    $payload,
    defined $event ? ( event => $event ) : (),
  );
  $self->_write_stderr( $result->{stderr} ) if length $result->{stderr};
  $self->_write_json( $result->{output}, 0 ) if defined $result->{output};
  return $result->{exit_code};
}

sub _doctor_options {
  my ( $self, $arguments ) = @_;
  my %options = ( cwd => '.', harness => 'both', tsv => 0 );
  while (@{$arguments}) {
    my $argument = shift @{$arguments};
    if ($argument eq '--help') {
      return ( \%options, undef, 1 );
    }
    if ($argument eq '--tsv') {
      $options{tsv} = 1;
      next;
    }
    if ($argument eq '--cwd' || $argument eq '--harness') {
      return ( undef, $argument.' requires a value', 0 ) unless @{$arguments};
      my $key = substr( $argument, 2 );
      $options{$key} = shift @{$arguments};
      next;
    }
    if ($argument =~ /\A--(cwd|harness)=(.*)\z/s) {
      $options{$1} = $2;
      next;
    }
    return ( undef, 'unknown doctor option: '.$argument, 0 );
  }

  return ( undef, '--cwd requires a non-empty value', 0 )
    unless defined $options{cwd} && length $options{cwd};
  return ( undef, '--harness must be claude, codex, or both', 0 )
    unless $options{harness} eq 'claude'
      || $options{harness} eq 'codex'
      || $options{harness} eq 'both';
  return ( undef, '--tsv checks the Claude Code team only; use --harness claude or both', 0 )
    if $options{tsv} && $options{harness} eq 'codex';
  return ( \%options, undef, 0 );
}

sub _doctor_problems {
  my ( $self, $result ) = @_;
  my ( @failures, @warnings );
  push @failures, 'unknown skill(s): '.join( ', ', @{ $result->{missing} } )
    if @{ $result->{missing} };
  push @failures,
    '[briefing] table '."\x{2014}".' Codex 0.153+ ignores this whole agent; use # briefing: skills = [...]'
    if $result->{legacy};
  push @warnings,
    int( $result->{size} / 1024 ).' kB of skill text, over 64 kB'
    if $result->{size} > 64 * 1024;
  return ( \@failures, \@warnings );
}

sub _harness_label {
  my ( $self, $harness ) = @_;
  return $harness eq 'claude' ? 'Claude Code' : 'Codex';
}

sub _run_doctor_tsv {
  my ( $self, $base, $cwd ) = @_;
  if (!$base->filesystem->is_dir($cwd)) {
    $self->_write_stderr(
      "briefing doctor: '".$cwd."' is not a directory.\n"
      ."briefing doctor: pass the repository that holds the team.\n"
    );
    return 2;
  }
  my $app = $self->_application(
    cwd        => $cwd,
    home       => $base->home,
    codex_home => $base->codex_home,
    filesystem => $base->filesystem,
  );
  my $findings = App::Briefing::Team->new( briefing => $app )->findings;
  my $failed = 0;
  my $text = '';
  for my $finding (@{$findings}) {
    $failed = 1 if $finding->{status} eq 'missing';
    $text .= join( "\t", @{$finding}{qw( what status name text )} )."\n";
  }
  $self->_write_stdout($text);
  return $failed ? 1 : 0;
}

sub _run_doctor {
  my ( $self, $arguments ) = @_;
  my ( $options, $error, $help ) = $self->_doctor_options($arguments);
  if ($help) {
    $self->_write_stdout($self->_usage);
    return 0;
  }
  if (defined $error) {
    $self->_write_stderr('briefing doctor: '.$error."\n".$self->_usage);
    return 2;
  }

  my $base = $self->_application;
  my $cwd = $base->filesystem->absolute( $options->{cwd} );
  return $self->_run_doctor_tsv( $base, $cwd ) if $options->{tsv};
  my $app = $self->_application(
    cwd        => $cwd,
    home       => $base->home,
    codex_home => $base->codex_home,
    filesystem => $base->filesystem,
  );
  my $results = $app->check_agents( harness => $options->{harness} );
  my $text = 'briefing doctor '."\x{2014}".' '.$cwd."\n";
  if (!@{$results}) {
    $self->_write_stdout( $text.'  no agents declare skills'."\n" );
    return 0;
  }

  my @harnesses = $options->{harness} eq 'both'
    ? qw( claude codex )
    : ($options->{harness});
  my $failed = 0;
  for my $harness (@harnesses) {
    my @entries = grep { $_->{harness} eq $harness } @{$results};
    next unless @entries;
    $text .= "\n".$self->_harness_label($harness)."\n";
    for my $result (@entries) {
      my ( $failures, $warnings ) = $self->_doctor_problems($result);
      my $where = $app->filesystem->within( $result->{path}, $cwd )
        ? $app->filesystem->relative( $result->{path}, $cwd )
        : $result->{path};
      my $status = @{$failures} ? 'FAIL' : @{$warnings} ? 'WARN' : 'ok';
      $failed = 1 if @{$failures};
      $text .= sprintf "  %-4s  %s  (%s)\n",
        $status,
        $result->{agent},
        $where;
      $text .= '        '.join( ', ', @{ $result->{skills} } ).'  ('
        .int( $result->{size} / 1024 ).' kB)'."\n";
      $text .= '        '."\x{2192}".' '.$_."\n"
        for ( @{$failures}, @{$warnings} );
    }
  }
  $self->_write_stdout($text);
  return $failed ? 1 : 0;
}

sub _run_notice {
  my ( $self ) = @_;
  # A courtesy note never takes a session down: any failure is silence with exit 0, as in
  # hooks/briefing-marketplace-notice.
  my $result = eval { $self->_application->process_notice({}) };
  return 0 unless ref $result eq 'HASH';
  $self->_write_stderr( $result->{stderr} ) if length $result->{stderr};
  $self->_write_json( $result->{output}, 1 ) if defined $result->{output};
  return $result->{exit_code};
}

sub run {
  my ( $invocant, $arguments ) = @_;
  my $self = ref $invocant ? $invocant : $invocant->new;
  $arguments = [] unless ref $arguments eq 'ARRAY';
  my @arguments = @{$arguments};

  binmode STDIN,  ':raw';
  binmode STDOUT, ':raw';
  binmode STDERR, ':raw';

  my $command = @arguments ? shift @arguments : '--help';
  if ($command eq '--help' || $command eq 'help') {
    $self->_write_stdout($self->_usage);
    return 0;
  }
  if ($command eq '--version') {
    $self->_write_stdout('briefing '.$App::Briefing::VERSION."\n");
    return 0;
  }
  if ($command eq 'hook') {
    return $self->_run_hook if !@arguments;
    if (@arguments == 1) {
      # The marketplace notice is a SessionStart hook of its own: it owns a state file, which
      # process_hook never writes. The word is exact, as the starters match it to pick the
      # notice's fallback.
      return $self->_run_notice if $arguments[0] eq 'marketplace-notice';
      my $event = $self->_hook_event( $arguments[0] );
      return $self->_run_hook($event) if defined $event;
      # An unknown EVENT word is hook input, not a usage error: a hook never blocks (exit 0).
      # Every other malformed command line below stays a usage error (exit 2).
      $self->_write_stderr('briefing: unknown hook event: '.$arguments[0]."\n");
      return 0;
    }
  }
  elsif ($command eq 'doctor') {
    return $self->_run_doctor(\@arguments);
  }
  elsif ($command eq 'notice') {
    return $self->_run_notice if !@arguments;
  }

  $self->_write_stderr('briefing: unknown command or arguments'."\n".$self->_usage);
  return 2;
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Briefing::CLI - Command-line interface for App::Briefing

=head1 VERSION

version 0.006000

=head1 DESCRIPTION

The terminal side of the L<briefing> command. It parses the command line,
reads a hook payload from standard input, and writes JSON answers, the
doctor's report and error messages to standard output and standard error as
UTF-8. Hook processing, agent resolution and the notice state belong to
L<App::Briefing>; the team findings of C<briefing doctor --tsv> come from
L<App::Briefing::Team>.

=head2 app_class

The class each command builds its L<App::Briefing> context from,
C<App::Briefing>. A subclass can return its own.

=head2 run

    exit App::Briefing::CLI->run(\@ARGV);

Runs one command line, given as an array reference, and returns its exit
status; it works as a class or an object method. The commands, their options,
output and exit statuses are documented in L<briefing>. C<--help> and
C<--version> answer without building a briefing context. C<hook
marketplace-notice> behaves exactly like C<notice>: it reads no input, prints
the note or nothing, and returns 0 even when it fails.

=head1 SEE ALSO

=over

=item * L<briefing> - the command and its options

=item * L<App::Briefing> - what briefing does, and the library

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests at
L<https://github.com/Getty/briefing/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
