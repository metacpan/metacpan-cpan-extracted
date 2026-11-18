package API::Docker::Role::Entity;
# ABSTRACT: The client reference an entity delegates through
our $VERSION = '0.006';
use Moo::Role;
use namespace::clean;


has client => (
  is       => 'ro',
  weak_ref => 1,
);

# The hook API::Docker::Role::Type's BUILDARGS reads. Its constructor sorts
# every key into "a field of this definition" or "a field the daemon sent
# that the model has not heard of", and `client` is neither: without this it
# would land in unknown_fields and TO_JSON would try to send the client
# object back to the engine. Anything an entity role adds as an attribute of
# its own belongs in this list.
sub _entity_attributes { return ('client') }


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Role::Entity - The client reference an entity delegates through

=head1 VERSION

version 0.006

=head1 SYNOPSIS

    package API::Docker::Role::Entity::Container;
    use Moo::Role;
    with 'API::Docker::Role::Entity';
    requires 'id';
    use API::Docker::Type::ContainerSummary;
    use namespace::clean;

    sub start {
      my ($self) = @_;
      return $self->client->containers->start($self->id);
    }

    # at the bottom of the same file: the methods land on the generated class
    Moo::Role->apply_roles_to_package(
      'API::Docker::Type::ContainerSummary', __PACKAGE__);

=head1 DESCRIPTION

An entity is a generated L<API::Docker::Type> class that has been given the
convenience methods of its resource -- C<< $container->start >>,
C<< $container->logs >>, C<< $image->remove >>. The methods live in a role
that is applied to the generated class at load time; they are never written
into the generated file.

=head2 Why the methods are not in the generated class

They cannot be. C<maint/spec-to-type.pl --verify> renders every class under
C<lib/API/Docker/Type/> out of C<spec/v1.51.yaml> and requires the result to
match what is shipped B<byte for byte> (F<t/spec_to_type.t>), and the
generator refuses to overwrite a file that exists. A hand-added C<with> line
or method in one of those files fails the suite; there is no mode of the
generator that would put it back.

=head2 Why a role, and not a class that contains the type object

Because the daemon answers C<GET /containers/json> and
C<GET /containers/{id}/json> with two different definitions, which are two
different generated classes -- L<API::Docker::Type::ContainerSummary> and
L<API::Docker::Type::ContainerInspectResponse>. Both need the same methods.

A wrapper class holding a type object would be a second model beside the
generated one: every field access would have to be forwarded, and
C<< $container->state >> would return either the wrapper's idea of a state
or the type object's, depending on which one the caller happened to hold.
Composing a role into both generated classes leaves exactly one model.
C<< $docker->containers->list >> hands back real
L<API::Docker::Type::ContainerSummary> objects, C<TO_JSON> still produces
the daemon's own spelling, and the methods are written once.

Applying the role to each B<object> instead (C<apply_roles_to_object>) would
also work and was rejected: it reblesses every entity into a generated
subclass, which costs something per object and makes C<ref> report a name no
documentation mentions.

=head2 What this role contributes

The half every entity shares: the client the methods delegate through. The
resource-specific methods are in a role per resource, which composes this
one.

=head2 client

The L<API::Docker> client, held as a C<weak_ref> -- the client owns the
resource classes, which produce the entities, so a strong reference here
would close the cycle.

Being weak, it is C<undef> as soon as nothing else holds the client:
C<< API::Docker->new->containers->list >> returns entities whose C<client>
has already gone, and the first delegating call on one of them dies. Keep
the client in a live variable.

=head1 SEE ALSO

=over

=item * L<API::Docker::Role::Entity::Container> - the container entity

=item * L<API::Docker::Role::Type> - the generated classes' own behaviour

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
