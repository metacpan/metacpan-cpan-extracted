# ABSTRACT: Disable automated agent runs on this board

package App::karr::Cmd::Disable;
our $VERSION = '0.402';
use Moo;
use MooX::Cmd;
use MooX::Options (
  usage_string => 'USAGE: karr disable [--reason "why"] [--json]',
);
use App::karr::Role::BoardAccess;
use App::karr::Role::Output;

with 'App::karr::Role::BoardAccess', 'App::karr::Role::Output';


option reason => (
  is     => 'ro',
  format => 's',
  doc    => 'Why this board is disabled (stored as foundation.reason)',
);

sub execute {
  my ($self, $args_ref, $chain_ref) = @_;

  $self->check_positional_args($args_ref, 0);

  $self->sync_before;
  $self->store->set_foundation_enabled( 0, $self->reason );
  $self->sync_after;

  my $reason = $self->store->foundation_reason;

  if ($self->json) {
    $self->print_json({
      foundation => {
        enabled => 0,
        ( defined $reason ? ( reason => $reason ) : () ),
      },
    });
    return;
  }

  print "Board disabled for automated agent runs (karr-foundation).\n";
  printf "  Reason: %s\n", $reason if defined $reason;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::karr::Cmd::Disable - Disable automated agent runs on this board

=head1 VERSION

version 0.402

=head1 SYNOPSIS

    karr disable
    karr disable --reason "abandoned driver, backlog parked"
    karr disable --json

=head1 DESCRIPTION

Turns the board-level agent switch off. The flag is board state, not machine
state: it is written to C<refs/karr/config> as C<foundation.enabled> (with the
optional C<foundation.reason>) and pushed with the rest of the board, so every
L<karr-foundation> instance on every machine sees it.

A disabled board is skipped by L<App::karr::Foundation> B<whole>: no drain, no
auto-block, no agent run. The flag is checked before the agent command is even
resolved, so it wins over C<karr-foundation --command>, the config's
C<default_command>, the per-repo F<.karr> C<command>, and C<< claude: true >>.
C<--force> does not override it — disabled means disabled.

Nothing else changes: the board stays fully usable for humans and for agents
driven by hand (C<karr list>, C<karr pick>, C<karr move>, …). Use it for a
repository whose backlog is parked rather than abandoned, so an automation host
that drains every discovered board leaves this one alone.

The same state is readable and writable through L<App::karr::Cmd::Config>
(C<karr config get foundation.enabled>,
C<karr config set foundation.enabled false>); there is one truth in the board
config, and this command is the ergonomic front door to it.

=head1 OPTIONS

=over 4

=item * C<--reason TEXT>

Free-text note stored as C<foundation.reason> and shown by
C<karr-foundation --status>. Omitting it clears any previously stored reason.

=item * C<--json>

Emit the resulting state as JSON instead of text.

=back

=head1 SEE ALSO

L<karr>, L<App::karr>, L<App::karr::Cmd::Enable>, L<App::karr::Cmd::Config>,
L<App::karr::Foundation>

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
