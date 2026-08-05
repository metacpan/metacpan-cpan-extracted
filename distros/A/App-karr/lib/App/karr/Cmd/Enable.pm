# ABSTRACT: Re-enable automated agent runs on this board

package App::karr::Cmd::Enable;
our $VERSION = '0.402';
use Moo;
use MooX::Cmd;
use MooX::Options (
  usage_string => 'USAGE: karr enable [--json]',
);
use App::karr::Role::BoardAccess;
use App::karr::Role::Output;

with 'App::karr::Role::BoardAccess', 'App::karr::Role::Output';


sub execute {
  my ($self, $args_ref, $chain_ref) = @_;

  $self->check_positional_args($args_ref, 0);

  $self->sync_before;
  $self->store->set_foundation_enabled(1);
  $self->sync_after;

  if ($self->json) {
    $self->print_json({ foundation => { enabled => 1 } });
    return;
  }

  print "Board enabled for automated agent runs (karr-foundation).\n";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::karr::Cmd::Enable - Re-enable automated agent runs on this board

=head1 VERSION

version 0.402

=head1 SYNOPSIS

    karr enable
    karr enable --json

=head1 DESCRIPTION

Reverses L<App::karr::Cmd::Disable>: automated agent runs are allowed on this
board again. Any reason stored with the disable is dropped, and because
C<foundation.enabled> is back at its code default the C<foundation> key
disappears from the sparse overrides in C<refs/karr/config> entirely.

Boards are enabled by default, so running this on a board that was never
disabled is a harmless no-op.

=head1 OPTIONS

=over 4

=item * C<--json>

Emit the resulting state as JSON instead of text.

=back

=head1 SEE ALSO

L<karr>, L<App::karr>, L<App::karr::Cmd::Disable>, L<App::karr::Cmd::Config>,
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
