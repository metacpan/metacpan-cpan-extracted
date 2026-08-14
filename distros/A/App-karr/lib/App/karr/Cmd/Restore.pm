# ABSTRACT: Restore the ref-backed karr board from YAML

package App::karr::Cmd::Restore;
our $VERSION = '0.500';
use Moo;
use MooX::Cmd;
use MooX::Options (
  usage_string => 'USAGE: karr restore --yes [--input PATH]',
);
use Path::Tiny;
use App::karr::Encoding qw( yaml_load from_octets );
use App::karr::Error qw( user_error clean_error );
use App::karr::Role::BoardDiscovery;
use App::karr::Role::SyncLifecycle;

with 'App::karr::Role::BoardDiscovery';
with 'App::karr::Role::SyncLifecycle';


option input => (
  is => 'ro',
  format => 's',
  doc => 'Read YAML snapshot from a file instead of stdin',
);

option yes => (
  is => 'ro',
  doc => 'Acknowledge destructive replacement of refs/karr/*',
);

sub execute {
  my ($self, $args_ref, $chain_ref) = @_;

  die "Ref restore is destructive and replaces all refs/karr/*. Re-run with --yes.\n"
    unless $self->yes;

  # store honours --dir (both call forms) and dies loudly if the target is
  # not a Git repository, instead of hardcoding the current directory.
  my $store = $self->store;

  # Restore rewrites refs/karr/*: run the full sync lifecycle so the pull and
  # the mirror-back push both retry, and the guard insures the push on a crash.
  $self->sync_before;

  my $payload = $self->_load_payload;
  my $snapshot = eval { yaml_load($payload) };
  die "Backup payload is not valid YAML\n" if $@;
  die "Backup payload must be a hash document\n" unless ref $snapshot eq 'HASH';
  die "Backup payload version 1 is required\n"
    unless ($snapshot->{version} // '') eq '1';
  die "Backup payload must contain a refs hash\n"
    unless ref $snapshot->{refs} eq 'HASH';

  $store->restore_snapshot($snapshot);

  $self->sync_after;

  print STDERR "Restored refs/karr/* from snapshot\n";
}

sub _load_payload {
  my ($self) = @_;

  if ( $self->input ) {
    # An unreadable --input is the user's path, not karr's: Path::Tiny's own
    # error would hand them this file and line instead (#77).
    my $content = eval { path( $self->input )->slurp_utf8 };
    defined $content
      or user_error( "Could not read ", $self->input, ": ", clean_error($@) );
    return $content;
  }

  # STDIN is the one input edge App::karr::Encoding leaves without a PerlIO
  # layer, precisely so this decode is explicit and happens exactly once.
  binmode STDIN, ':raw';
  my $content = do { local $/; <STDIN> };
  die "No backup payload received on stdin\n"
    unless defined $content && length $content;
  return from_octets($content);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::karr::Cmd::Restore - Restore the ref-backed karr board from YAML

=head1 VERSION

version 0.500

=head1 SYNOPSIS

    karr restore --yes < karr-backup.yml
    karr restore --yes --input karr-backup.yml

=head1 DESCRIPTION

Replaces the complete C<refs/karr/*> namespace with a previously exported YAML
snapshot. This is intentionally destructive: refs currently present but absent
from the snapshot are deleted as part of the restore.

It is not destructive on the way in, though. Every ref name in the snapshot is
checked and every commit object written before the first ref moves, so a
snapshot karr cannot apply -- an unusable ref name, or one outside
C<refs/karr/> -- is refused with the board exactly as it was. Nothing is
deleted up front, so a restore that fails can no longer leave the board empty.

=head1 OPTIONS

=over 4

=item * C<--input>

Read the YAML snapshot from the given file instead of standard input.

=item * C<--yes>

Required acknowledgement for the destructive restore operation.

=back

=head1 SEE ALSO

L<karr>, L<App::karr>, L<App::karr::Cmd::Backup>,
L<App::karr::Cmd::Destroy>, L<App::karr::Cmd::Sync>

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
