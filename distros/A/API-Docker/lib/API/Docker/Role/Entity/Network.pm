package API::Docker::Role::Entity::Network;
# ABSTRACT: Network operations, on the generated network type
our $VERSION = '0.006';
use Moo::Role;
with 'API::Docker::Role::Entity';
requires 'id';
use API::Docker::Type::Network;
use Carp qw( croak );
use Package::Stash;
use namespace::clean;


sub inspect {
  my ($self) = @_;
  return $self->client->networks->inspect($self->id);
}


sub remove {
  my ($self) = @_;
  return $self->client->networks->remove($self->id);
}


sub connect {
  my ($self, %opts) = @_;
  return $self->client->networks->connect($self->id, %opts);
}


sub disconnect {
  my ($self, %opts) = @_;
  return $self->client->networks->disconnect($self->id, %opts);
}


# --- composition -----------------------------------------------------------
#
# Here rather than in API::Docker::API::Networks, for the reason spelled out
# in API::Docker::Role::Entity::Container: loading this role is what puts the
# methods on the class.
#
# The clash check is not decoration. Moo composes a role into a class the
# class-wins way, so a generated accessor of the same name as a method here
# would silently keep its place and the method would be missing -- and the
# generated classes are written from a specification that grows fields
# without asking. None of the four names collides today; a future one says so
# on the first `use`.
{
  my @provided = Package::Stash->new(__PACKAGE__)->list_all_symbols('CODE');
  for my $class ('API::Docker::Type::Network') {
    my $fields = $class->docker_attributes;
    my @clash = sort grep { $fields->{$_} } @provided;
    croak __PACKAGE__ . ': ' . $class . ' declares ' . join(', ', @clash)
      . ' as a daemon field; the generated accessor would win over the '
      . 'method of that name and it would be missing without a word'
      if @clash;
    Moo::Role->apply_roles_to_package($class, __PACKAGE__);
  }
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Role::Entity::Network - Network operations, on the generated network type

=head1 VERSION

version 0.006

=head1 SYNOPSIS

    my $docker = API::Docker->new;
    my ($network) = @{ $docker->networks->list };

    say $network->name;
    say $network->driver;
    say $network->ipam->config->[0]->subnet;

    $network->connect(Container => $container_id);
    $network->disconnect(Container => $container_id);
    $network->remove;

=head1 DESCRIPTION

The convenience methods of a network. This role is composed, at load time,
into L<API::Docker::Type::Network>, the generated class the daemon answers
network requests with.

=head2 One class, not two

Unlike containers and images, a network has B<one> shape. The swagger answers
both C<GET /networks> -- an array of them -- and C<GET /networks/{id}> with
the same C<Network> definition, so L<API::Docker::API::Networks/list> and
L<API::Docker::API::Networks/inspect> hand back the same class and nothing
here has to tell two apart. What can still differ between the two calls is
which fields the engine fills in, not which fields exist -- no network in
F<t/fixtures/networks_list.json> carries C<Containers> at all, and a field
the engine omits reads as C<undef> rather than as a shape of its own.

Every method here forwards to L<API::Docker::API::Networks> with the
network's own C<id> and returns whatever that method returns; the options are
that method's options, undocumented here on purpose so there is one place to
correct when the engine's are found to be something else.

Why the methods are a role applied to a generated class rather than a class
of their own: L<API::Docker::Role::Entity/DESCRIPTION>.

=head2 inspect

    my $fresh = $network->inspect;

Get fresh network information. Returns another
L<API::Docker::Type::Network> -- the same class, since the daemon describes a
network one way.

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

=item * L<API::Docker::API::Networks> - the operations these forward to

=item * L<API::Docker::Type::Network> - the fields C<list> and C<inspect>
return

=item * L<API::Docker::Role::Entity> - why the methods live in a role

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
