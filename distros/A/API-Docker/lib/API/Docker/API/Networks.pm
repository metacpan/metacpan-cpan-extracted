package API::Docker::API::Networks;
# ABSTRACT: Docker Engine Networks API
our $VERSION = '0.002';
use Moo;
use API::Docker::Network;
use Carp qw( croak );
use namespace::clean;


has client => (
  is       => 'ro',
  required => 1,
  weak_ref => 1,
);


sub _wrap {
  my ($self, $data) = @_;
  return API::Docker::Network->new(
    client => $self->client,
    %$data,
  );
}

sub _wrap_list {
  my ($self, $list) = @_;
  return [ map { $self->_wrap($_) } @$list ];
}

sub list {
  my ($self, %opts) = @_;
  my %params;
  $params{filters} = $opts{filters} if defined $opts{filters};
  my $result = $self->client->get('/networks', params => \%params);
  return $self->_wrap_list($result // []);
}


sub inspect {
  my ($self, $id) = @_;
  croak "Network ID required" unless $id;
  my $result = $self->client->get("/networks/$id");
  return $self->_wrap($result);
}


sub create {
  my ($self, %config) = @_;
  croak "Network name required" unless $config{Name};
  my $result = $self->client->post('/networks/create', \%config);
  return $result;
}


sub remove {
  my ($self, $id) = @_;
  croak "Network ID required" unless $id;
  return $self->client->delete_request("/networks/$id");
}


sub connect {
  my ($self, $id, %opts) = @_;
  croak "Network ID required" unless $id;
  croak "Container required" unless $opts{Container};
  return $self->client->post("/networks/$id/connect", \%opts);
}


sub disconnect {
  my ($self, $id, %opts) = @_;
  croak "Network ID required" unless $id;
  croak "Container required" unless $opts{Container};
  return $self->client->post("/networks/$id/disconnect", \%opts);
}


sub prune {
  my ($self, %opts) = @_;
  my %params;
  $params{filters} = $opts{filters} if defined $opts{filters};
  return $self->client->post('/networks/prune', undef, params => \%params);
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::API::Networks - Docker Engine Networks API

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    my $docker = API::Docker->new;

    # Create a network
    my $result = $docker->networks->create(
        Name   => 'my-network',
        Driver => 'bridge',
    );

    # List networks
    my $networks = $docker->networks->list;

    # Connect/disconnect containers
    $docker->networks->connect($network_id, Container => $container_id);
    $docker->networks->disconnect($network_id, Container => $container_id);

    # Remove network
    $docker->networks->remove($network_id);

=head1 DESCRIPTION

This module provides methods for managing Docker networks including creation,
listing, connecting containers, and removal.

Accessed via C<< $docker->networks >>.

=head2 client

Reference to L<API::Docker> client. Weak reference to avoid circular dependencies.

=head2 list

    my $networks = $networks->list;

List networks. Returns ArrayRef of L<API::Docker::Network> objects.

=head2 inspect

    my $network = $networks->inspect($id);

Get detailed information about a network. Returns L<API::Docker::Network> object.

=head2 create

    my $result = $networks->create(
        Name   => 'my-network',
        Driver => 'bridge',
    );

Create a network. Returns hashref with C<Id> and C<Warning>.

=head2 remove

    $networks->remove($id);

Remove a network.

=head2 connect

    $networks->connect($network_id, Container => $container_id);

Connect a container to a network.

=head2 disconnect

    $networks->disconnect($network_id, Container => $container_id, Force => 1);

Disconnect a container from a network. Optional C<Force> parameter.

=head2 prune

    my $result = $networks->prune;

Delete unused networks. Returns hashref with C<NetworksDeleted>.

=head1 SEE ALSO

=over

=item * L<API::Docker> - Main Docker client

=item * L<API::Docker::Network> - Network entity class

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
