package App::Raider::Plugin::Situation;
our $VERSION = '0.003';
# ABSTRACT: Inject situational context (current time, timezone, host, user) at the start of the first raid

use Moose;
use Future::AsyncAwait;
use POSIX qw( strftime );
use Sys::Hostname ();

extends 'Langertha::Plugin';


has _injected => (
  is      => 'rw',
  isa     => 'Bool',
  default => 0,
);

sub _situation_text {
  my $now = time;
  my $local  = strftime('%Y-%m-%d %H:%M', localtime($now));
  my $offset = strftime('%z',            localtime($now));
  my $tzname = strftime('%Z',            localtime($now)) || 'local';
  my $host   = Sys::Hostname::hostname();
  my $user   = $ENV{USER} // $ENV{LOGNAME} // getpwuid($<) // 'unknown';
  return "[situation] $local $tzname (UTC$offset), host=$host user=$user\n\n";
}

async sub plugin_before_raid {
  my ($self, $messages) = @_;
  return $messages if $self->_injected;
  $self->_injected(1);

  my @msgs = @$messages;
  return \@msgs unless @msgs;

  my $prefix = _situation_text();

  # Prepend to the first user-visible message. Messages may be plain strings
  # or hashrefs with content; handle both.
  my $first = $msgs[0];
  if (!ref $first) {
    $msgs[0] = $prefix . $first;
  }
  elsif (ref $first eq 'HASH') {
    my %copy = %$first;
    if (defined $copy{content} && !ref $copy{content}) {
      $copy{content} = $prefix . $copy{content};
    }
    else {
      # Structured content — unshift a simple text note in front.
      unshift @msgs, { role => 'user', content => $prefix };
      return \@msgs;
    }
    $msgs[0] = \%copy;
  }
  return \@msgs;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Raider::Plugin::Situation - Inject situational context (current time, timezone, host, user) at the start of the first raid

=head1 VERSION

version 0.003

=head1 SYNOPSIS

    my $raider = Langertha::Raider->new(
        engine  => $engine,
        plugins => ['+App::Raider::Plugin::Situation'],
    );

=head1 DESCRIPTION

Prepends a small C<[situation]> context block to the very first user message
of a session: current local time, UTC offset, timezone, hostname, and
C<$USER>. The model then knows what "now" means without needing to call
C<bash "date">.

The block is injected only once per Raider instance (on the first
C<plugin_before_raid>) so it does not bloat subsequent raids — the model
already has the info in its history.

=head1 SEE ALSO

=over

=item * L<App::Raider>

=item * L<Langertha::Plugin>

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-app-raider/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
