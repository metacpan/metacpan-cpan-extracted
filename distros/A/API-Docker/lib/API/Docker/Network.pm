package API::Docker::Network;
# ABSTRACT: Docker network entity
our $VERSION = '0.002';
use Moo;
use namespace::clean;


has client => (
  is       => 'ro',
  weak_ref => 1,
);


has Id         => (is => 'ro');


has Name       => (is => 'ro');


has Created    => (is => 'ro');
has Scope      => (is => 'ro');
has Driver     => (is => 'ro');


has EnableIPv6 => (is => 'ro');
has IPAM       => (is => 'ro');
has Internal   => (is => 'ro');
has Attachable => (is => 'ro');
has Ingress    => (is => 'ro');
has Options    => (is => 'ro');
has Labels     => (is => 'ro');
has Containers => (is => 'ro');
has ConfigFrom => (is => 'ro');
has ConfigOnly => (is => 'ro');

sub inspect {
  my ($self) = @_;
  return $self->client->networks->inspect($self->Id);
}


sub remove {
  my ($self) = @_;
  return $self->client->networks->remove($self->Id);
}


sub connect {
  my ($self, %opts) = @_;
  return $self->client->networks->connect($self->Id, %opts);
}


sub disconnect {
  my ($self, %opts) = @_;
  return $self->client->networks->disconnect($self->Id, %opts);
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Network - Docker network entity

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    my $docker = API::Docker->new;
    my $networks = $docker->networks->list;
    my $network = $networks->[0];

    say $network->Name;
    say $network->Driver;

    $network->connect(Container => $container_id);
    $network->disconnect(Container => $container_id);
    $network->remove;

=head1 DESCRIPTION

This class represents a Docker network. Instances are returned by
L<API::Docker::API::Networks> methods.

=head2 client

Reference to L<API::Docker> client.

=head2 Id

Network ID.

=head2 Name

Network name.

=head2 Driver

Network driver (e.g., C<bridge>, C<overlay>).

=head2 inspect

    my $updated = $network->inspect;

Get fresh network information.

=head2 remove

    $network->remove;

Remove the network.

=head2 connect

    $network->connect(Container => $container_id);

Connect a container to this network.

=head2 disconnect

    $network->disconnect(Container => $container_id, Force => 1);

Disconnect a container from this network.

=head1 SEE ALSO

=over

=item * L<API::Docker::API::Networks> - Network API operations

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
