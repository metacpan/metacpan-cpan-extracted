package API::Docker::API::Networks;
# ABSTRACT: Docker Engine Networks API
our $VERSION = '0.006';
use Moo;
with 'API::Docker::Role::Filters', 'API::Docker::Role::Using',
  'API::Docker::Role::JSONBody';
use API::Docker::Role::Entity::Network;
use API::Docker::Type::Network;
use Carp qw( croak );
use namespace::clean;


has client => (
  is       => 'ro',
  required => 1,
  weak_ref => 1,
);


# The class is the caller's argument, as it is on the resource classes whose
# list and inspect really are two definitions -- here both are the swagger's
# one `Network`, and passing it keeps the seam in the same place.
#
# from_data, not new: this is a daemon response, and the two entry points of
# API::Docker::Role::Type read it differently. from_data takes the swagger's
# wire names and nothing else, so a key it has not heard of keeps its own
# spelling instead of being read as the Perl name of one it has, and a value
# that disagrees with the swagger costs its own field rather than the whole
# response. `client` is ours rather than the engine's, so it goes beside the
# data instead of into it.
sub _wrap {
  my ($self, $class, $data) = @_;
  return $class->from_data($data, client => $self->client);
}

sub _wrap_list {
  my ($self, $class, $list) = @_;
  return [ map { $self->_wrap($class, $_) } @$list ];
}

sub list {
  my ($self, %opts) = @_;
  my %params;
  $params{filters} = $self->_normalise_filters($opts{filters})
    if defined $opts{filters};
  my $result = $self->client->get('/networks',
    params => \%params,
    %{ $self->_request_options },
  );
  return $self->_wrap_list('API::Docker::Type::Network', $result // []);
}


sub inspect {
  my ($self, $id) = @_;
  croak "Network ID required" unless $id;
  my $result = $self->client->get("/networks/$id",
    %{ $self->_request_options },
  );
  return $self->_wrap('API::Docker::Type::Network', $result);
}


# The NetworkCreateRequest booleans of spec/v1.51.yaml. The engine rejects a
# number for any of them, so 1/0 is normalised to a JSON boolean on the way
# out; a caller may still pass 1/0 or a JSON boolean and it goes out correctly.
my @NETWORK_CREATE_BOOLS = qw(
  Attachable ConfigOnly EnableIPv4 EnableIPv6 Ingress Internal
);

sub create {
  my ($self, %config) = @_;
  croak "Network name required" unless $config{Name};
  $self->_json_bools(\%config, @NETWORK_CREATE_BOOLS);
  my $result = $self->client->post('/networks/create', \%config);
  return $result;
}


sub remove {
  my ($self, $id) = @_;
  croak "Network ID required" unless $id;
  return $self->client->delete_request("/networks/$id",
    %{ $self->_request_options },
  );
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
  $self->_json_bools(\%opts, 'Force');
  return $self->client->post("/networks/$id/disconnect", \%opts);
}


sub prune {
  my ($self, %opts) = @_;
  my %params;
  $params{filters} = $self->_normalise_filters($opts{filters})
    if defined $opts{filters};
  return $self->client->post('/networks/prune', undef,
    params => \%params,
    %{ $self->_request_options },
  );
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::API::Networks - Docker Engine Networks API

=head1 VERSION

version 0.006

=head1 SYNOPSIS

    my $docker = API::Docker->new;

    # Create a network
    my $result = $docker->networks->create(
        Name   => 'my-network',
        Driver => 'bridge',
    );

    # List networks
    my $networks = $docker->networks->list;
    say $_->name, ' ', $_->driver for @$networks;

    # Connect/disconnect containers
    $docker->networks->connect($network_id, Container => $container_id);
    $docker->networks->disconnect($network_id, Container => $container_id);

    # Remove network
    $docker->networks->remove($network_id);

=head1 DESCRIPTION

This module provides methods for managing Docker networks including creation,
listing, connecting containers, and removal.

L</list> and L</inspect> both return L<API::Docker::Type::Network> objects
carrying the convenience methods of L<API::Docker::Role::Entity::Network>, so
C<< $network->connect >> and C<< $network->remove >> work on either. The
field names are the swagger's own spelling in snake_case: C<Id> is
C<< ->id >>, C<EnableIPv6> is C<< ->enable_ipv6 >>, and C<IPAM> is
C<< ->ipam >>, an L<API::Docker::Type::IPAM> whose C<< ->config >> is an
ArrayRef of L<API::Docker::Type::IPAMConfig>.

Unlike containers and images this is B<one> class for both calls: the
swagger answers C<GET /networks> and C<GET /networks/{id}> with the same
C<Network> definition, so there is no list-versus-inspect shape to keep
apart -- see L<API::Docker::Role::Entity::Network/"One class, not two">.

Accessed via C<< $docker->networks >>, or through
L<API::Docker::Role::Using/using> for a run of calls that needs its own
transport bound: C<< $docker->networks->using(read_timeout => 5) >>.

=head2 client

Reference to L<API::Docker> client. Weak reference to avoid circular dependencies.

=head2 list

    my $networks = $networks->list;
    my $bridges  = $networks->list(filters => { driver => ['bridge'] });

List networks. Returns an ArrayRef of L<API::Docker::Type::Network> objects,
each carrying the methods of L<API::Docker::Role::Entity::Network>.

Options:

=over

=item * C<filters> - HashRef of filter name to ArrayRef of string values; the
engine accepts C<dangling>, C<driver>, C<id>, C<label>, C<name>, C<scope> and
C<type> here. Shape-checked and normalised by L<API::Docker::Role::Filters>

=back

=head2 inspect

    my $network = $networks->inspect($id);

Get detailed information about a network. Returns an
L<API::Docker::Type::Network> -- the same class L</list> returns, since the
swagger describes a network one way.

=head2 create

    my $result = $networks->create(
        Name   => 'my-network',
        Driver => 'bridge',
    );

Create a network. Returns hashref with C<Id> and C<Warning>.

Boolean flags (C<Internal>, C<Attachable>, C<Ingress>, C<ConfigOnly>,
C<EnableIPv4>, C<EnableIPv6>) may be given as a Perl C<1>/C<0> or as a JSON
boolean; either goes out as a real JSON C<true>/C<false>, which the engine's
body type-check requires.

=head2 remove

    $networks->remove($id);

Remove a network.

=head2 connect

    $networks->connect($network_id, Container => $container_id);

Connect a container to a network.

=head2 disconnect

    $networks->disconnect($network_id, Container => $container_id, Force => 1);

Disconnect a container from a network. Optional C<Force> parameter, given as a
Perl C<1>/C<0> or a JSON boolean; it goes out as a real JSON C<true>/C<false>,
which the engine's body type-check requires.

=head2 prune

    my $result = $networks->prune;
    my $result = $networks->prune(filters => { until => ['24h'] });

Delete unused networks. Returns hashref with C<NetworksDeleted>.

Options:

=over

=item * C<filters> - HashRef of filter name to ArrayRef of string values; the
engine accepts C<until> and C<label> here. Shape-checked and normalised by
L<API::Docker::Role::Filters>

=back

=head1 SEE ALSO

=over

=item * L<API::Docker> - Main Docker client

=item * L<API::Docker::Role::Entity::Network> - the convenience methods the
returned objects carry

=item * L<API::Docker::Type::Network> - the fields C<list> and C<inspect>
return

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests at
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
