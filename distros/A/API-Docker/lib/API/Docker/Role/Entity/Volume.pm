package API::Docker::Role::Entity::Volume;
# ABSTRACT: Volume operations, on the generated volume type
our $VERSION = '0.006';
use Moo::Role;
with 'API::Docker::Role::Entity';
requires 'name';
use API::Docker::Type::Volume;
use Carp qw( croak );
use Package::Stash;
use namespace::clean;


sub inspect {
  my ($self) = @_;
  return $self->client->volumes->inspect($self->name);
}


sub remove {
  my ($self, %opts) = @_;
  return $self->client->volumes->remove($self->name, %opts);
}


# --- composition -----------------------------------------------------------
#
# Here rather than in API::Docker::API::Volumes, for the reason spelled out in
# API::Docker::Role::Entity::Container: loading this role is what puts the
# methods on the class.
#
# The clash check is not decoration. Moo composes a role into a class the
# class-wins way, so a generated accessor of the same name as a method here
# would silently keep its place and the method would be missing -- and the
# generated classes are written from a specification that grows fields
# without asking. Neither of the two names collides today; a future one says
# so on the first `use`.
{
  my @provided = Package::Stash->new(__PACKAGE__)->list_all_symbols('CODE');
  for my $class ('API::Docker::Type::Volume') {
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

API::Docker::Role::Entity::Volume - Volume operations, on the generated volume type

=head1 VERSION

version 0.006

=head1 SYNOPSIS

    my $docker = API::Docker->new;
    my ($volume) = @{ $docker->volumes->list };

    say $volume->name;
    say $volume->driver;
    say $volume->mountpoint;

    $volume->remove;

=head1 DESCRIPTION

The convenience methods of a volume. This role is composed, at load time,
into L<API::Docker::Type::Volume>, the generated class the daemon answers
volume requests with.

=head2 One class for all three calls

A volume has B<one> shape. The swagger answers C<GET /volumes/{name}> and
C<POST /volumes/create> with the C<Volume> definition outright, and
C<GET /volumes> with a C<VolumeListResponse> whose C<Volumes> is an array of
that same definition -- which is why
L<API::Docker::API::Volumes/list> unwraps that one key and returns the
entries, and why C<create> hands back an entity where the other resources
return the daemon's raw response.

=head2 The entity is addressed by name, not by id

A volume has no C<Id>. Its name is its identifier on every endpoint, which is
why this role C<requires 'name'> where the container, image and network ones
require C<id>.

Every method here forwards to L<API::Docker::API::Volumes> with the volume's
own C<name> and returns whatever that method returns; the options are that
method's options, undocumented here on purpose so there is one place to
correct when the engine's are found to be something else.

Why the methods are a role applied to a generated class rather than a class
of their own: L<API::Docker::Role::Entity/DESCRIPTION>.

=head2 inspect

    my $fresh = $volume->inspect;

Get fresh volume information. Returns another L<API::Docker::Type::Volume> --
the same class, since the daemon describes a volume one way.

=head2 remove

    $volume->remove(force => 1);

Remove the volume.

=head1 SEE ALSO

=over

=item * L<API::Docker::API::Volumes> - the operations these forward to

=item * L<API::Docker::Type::Volume> - the fields C<list>, C<inspect> and
C<create> return

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
