# ABSTRACT: Restore the ref-backed karr board from YAML

package App::karr::Cmd::Restore;
our $VERSION = '0.102';
use Moo;
use MooX::Cmd;
use MooX::Options (
  usage_string => 'USAGE: karr restore --yes [--input PATH]',
);
use Path::Tiny;
use YAML::XS qw( Load );
use App::karr::Git;
use App::karr::BoardStore;


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

  my $git = App::karr::Git->new( dir => '.' );
  die "Not a git repository. karr requires Git.\n" unless $git->is_repo;

  my $root = $git->repo_root;
  $git = App::karr::Git->new( dir => $root->stringify );
  $git->pull if $git->has_remote;

  my $payload = $self->_load_payload;
  my $snapshot = eval { Load($payload) };
  die "Backup payload is not valid YAML\n" if $@;
  die "Backup payload must be a hash document\n" unless ref $snapshot eq 'HASH';
  die "Backup payload version 1 is required\n"
    unless ($snapshot->{version} // '') eq '1';
  die "Backup payload must contain a refs hash\n"
    unless ref $snapshot->{refs} eq 'HASH';

  my $store = App::karr::BoardStore->new( git => $git );
  $store->restore_snapshot($snapshot);
  $git->push if $git->has_remote;

  print STDERR "Restored refs/karr/* from snapshot\n";
}

sub _load_payload {
  my ($self) = @_;

  if ( $self->input ) {
    return path( $self->input )->slurp_utf8;
  }

  my $content = do { local $/; <STDIN> };
  die "No backup payload received on stdin\n"
    unless defined $content && length $content;
  return $content;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::karr::Cmd::Restore - Restore the ref-backed karr board from YAML

=head1 VERSION

version 0.102

=head1 SYNOPSIS

    karr restore --yes < karr-backup.yml
    karr restore --yes --input karr-backup.yml

=head1 DESCRIPTION

Replaces the complete C<refs/karr/*> namespace with a previously exported YAML
snapshot. This is intentionally destructive: refs currently present but absent
from the snapshot are deleted as part of the restore.

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
L<https://github.com/Getty/p5-app-karr/issues>.

=head2 IRC

Join C<#ai> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
