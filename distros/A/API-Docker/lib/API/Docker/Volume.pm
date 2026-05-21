package API::Docker::Volume;
# ABSTRACT: Docker volume entity
our $VERSION = '0.002';
use Moo;
use namespace::clean;


has client => (
  is       => 'ro',
  weak_ref => 1,
);


has Name       => (is => 'ro');


has Driver     => (is => 'ro');


has Mountpoint => (is => 'ro');


has CreatedAt  => (is => 'ro');
has Status     => (is => 'ro');
has Labels     => (is => 'ro');
has Scope      => (is => 'ro');
has Options    => (is => 'ro');
has UsageData  => (is => 'ro');

sub inspect {
  my ($self) = @_;
  return $self->client->volumes->inspect($self->Name);
}


sub remove {
  my ($self, %opts) = @_;
  return $self->client->volumes->remove($self->Name, %opts);
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Volume - Docker volume entity

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    my $docker = API::Docker->new;
    my $volumes = $docker->volumes->list;
    my $volume = $volumes->[0];

    say $volume->Name;
    say $volume->Driver;
    say $volume->Mountpoint;

    $volume->remove;

=head1 DESCRIPTION

This class represents a Docker volume. Instances are returned by
L<API::Docker::API::Volumes> methods.

=head2 client

Reference to L<API::Docker> client.

=head2 Name

Volume name.

=head2 Driver

Volume driver (usually C<local>).

=head2 Mountpoint

Filesystem path where the volume is mounted on the host.

=head2 inspect

    my $updated = $volume->inspect;

Get fresh volume information.

=head2 remove

    $volume->remove(force => 1);

Remove the volume.

=head1 SEE ALSO

=over

=item * L<API::Docker::API::Volumes> - Volume API operations

=item * L<API::Docker> - Main Docker client

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-api-docker/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
