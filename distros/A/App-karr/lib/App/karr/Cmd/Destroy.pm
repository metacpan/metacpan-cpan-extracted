# ABSTRACT: Destroy the ref-backed karr board

package App::karr::Cmd::Destroy;
our $VERSION = '0.401';
use Moo;
use MooX::Cmd;
use MooX::Options (
  usage_string => 'USAGE: karr destroy --yes',
);
use App::karr::Role::BoardDiscovery;
use App::karr::Role::SyncLifecycle;

with 'App::karr::Role::BoardDiscovery';
with 'App::karr::Role::SyncLifecycle';


option yes => (
  is => 'ro',
  short => 'y',
  doc => 'Acknowledge destructive deletion of refs/karr/*',
);

sub execute {
  my ($self, $args_ref, $chain_ref) = @_;

  die "Board destroy is destructive and deletes refs/karr/*. Re-run with --yes.\n"
    unless $self->yes;

  # store honours --dir (both call forms) and dies loudly if the target is
  # not a Git repository, instead of hardcoding the current directory.
  my $store = $self->store;

  # Destroy deletes refs/karr/*: run the full sync lifecycle so the pull (which
  # may bring a remote-only board into view before we decide it is missing) and
  # the pruning push both retry, and the guard insures the push on a crash.
  $self->sync_before;

  die "No karr board found. Run 'karr init' to create one.\n"
    unless $store->board_exists;

  $store->delete_all_karr_refs;

  $self->sync_after;

  print STDERR "Deleted refs/karr/*\n";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::karr::Cmd::Destroy - Destroy the ref-backed karr board

=head1 VERSION

version 0.401

=head1 SYNOPSIS

    karr destroy --yes

=head1 DESCRIPTION

Deletes the complete C<refs/karr/*> namespace for the current repository. This
is the destructive inverse of C<karr init> and removes board config, tasks,
logs, metadata, and any other refs kept under the board namespace.

If the repository has a configured remote, the command also pushes the empty
namespace so the remote board state is pruned to match.

=head1 OPTIONS

=over 4

=item * C<--yes>

Required acknowledgement for the destructive board removal.

=back

=head1 SEE ALSO

L<karr>, L<App::karr>, L<App::karr::Cmd::Backup>,
L<App::karr::Cmd::Restore>, L<App::karr::Cmd::Init>

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
