package API::Docker::Role::Entity::Secret;
# ABSTRACT: Secret operations, on the generated secret type
our $VERSION = '0.006';
use Moo::Role;
with 'API::Docker::Role::Entity';
requires 'id';
use API::Docker::Type::Secret;
use Carp qw( croak );
use Package::Stash;
use namespace::clean;


sub version_index {
  my ($self) = @_;
  my $version = $self->version;
  return unless defined $version;
  return $version->index;
}


sub inspect {
  my ($self) = @_;
  return $self->client->secrets->inspect($self->id);
}


sub update {
  my ($self, %opts) = @_;
  my $version
    = exists $opts{version} ? delete $opts{version} : $self->version_index;
  return $self->client->secrets->update($self->id, $version, %opts);
}


sub remove {
  my ($self) = @_;
  return $self->client->secrets->remove($self->id);
}


# --- composition -----------------------------------------------------------
#
# Here rather than in API::Docker::API::Secrets, for the reason spelled out in
# API::Docker::Role::Entity::Container: loading this role is what puts the
# methods on the class.
#
# The clash check is not decoration. Moo composes a role into a class the
# class-wins way, so a generated accessor of the same name as a method here
# would silently keep its place and the method would be missing -- and the
# generated classes are written from a specification that grows fields
# without asking. None of the four names collides today; a future one says so
# on the first `use`. `version_index` is the one to watch: the class already
# declares `version`.
{
  my @provided = Package::Stash->new(__PACKAGE__)->list_all_symbols('CODE');
  for my $class ('API::Docker::Type::Secret') {
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

API::Docker::Role::Entity::Secret - Secret operations, on the generated secret type

=head1 VERSION

version 0.006

=head1 SYNOPSIS

    my $docker = API::Docker->new;
    my ($secret) = @{ $docker->secrets->list };

    say $secret->id;
    say $secret->spec->name;
    say $secret->version_index;

    my %spec = %{ $secret->spec->TO_JSON };
    $spec{Labels} = { env => 'staging' };
    $secret->update(%spec);

    $secret->remove;

=head1 DESCRIPTION

The convenience methods of a Docker secret. This role is composed, at load
time, into L<API::Docker::Type::Secret>, the generated class the daemon
answers secret requests with -- the same definition for C<GET /secrets> and
C<GET /secrets/{id}>, so L<API::Docker::API::Secrets/list> and
L<API::Docker::API::Secrets/inspect> hand back one class and there is no
list-versus-inspect shape to keep apart.

=head2 There is no accessor for the value

A secret carries no payload on this API at all. The daemon hands the value to
containers, never back over C</secrets>: neither C<list> nor C<inspect>
returns a C<< spec->data >>, so there is nothing here to decode. That is why
this role has no C<decoded_data>, where
L<API::Docker::Role::Entity::Config> does -- the difference is in what the
engine sends, not in what the two choose to offer. In the C<GET /secrets>
response captured from Podman 5.4.2 (API 1.41) in
F<t/fixtures/secrets_list.json>, each object carries C<ID>, C<CreatedAt>,
C<UpdatedAt>, C<Spec> and C<Version>, and the C<Spec> has C<Name>, C<Driver>
and C<Labels> but no C<Data> key whatsoever. The swagger agrees: it documents
C<SecretSpec.Data> as used to I<create> a secret and not returned by other
endpoints.

C<< $secret->spec->data >> therefore exists as an accessor -- the field is in
the definition -- and reads C<undef> on anything an engine sent back.

If you need to read a value back, a secret is the wrong storage -- put it in
a config, see L<API::Docker::API::Configs>.

=head2 The spec goes back as a whole

C<< $secret->spec >> is an L<API::Docker::Type::SecretSpec> object rather
than the raw HashRef the hand-written entity kept, so the idiom for an update
is C<< %{ $secret->spec->TO_JSON } >>: C<TO_JSON> renders the spec back into
the daemon's own spelling, which is what L</update> puts in the request body.

Why the whole spec and not the one key you changed:
L<API::Docker::API::Secrets/"update takes the current version, and it is
mandatory">.

Why the methods are a role applied to a generated class rather than a class
of their own: L<API::Docker::Role::Entity/DESCRIPTION>.

=head2 version_index

    my $index = $secret->version_index;

The C<< ->index >> out of C<< ->version >>, which is what the daemon wants as
the C<version> query parameter on an update. Returns nothing when the object
carries no C<Version> -- including the case where the daemon sent one the
model could not use, which leaves the attribute unset and the raw value in
C<< ->unknown_fields->{Version} >>.

It is the version as of the moment this object was fetched, which is exactly
the token's meaning: an update built on a stale entity is refused by the
daemon rather than silently overwriting whatever changed in between.

=head2 inspect

    my $fresh = $secret->inspect;

Get fresh secret information. Returns another L<API::Docker::Type::Secret> --
the same class, since the daemon describes a secret one way.

=head2 update

    my %spec = %{ $secret->spec->TO_JSON };
    $spec{Labels} = { env => 'staging' };
    $secret->update(%spec);

Update the secret. Passes C<< ->id >> and, by default, L</version_index> to
L<API::Docker::API::Secrets/update>; everything else is the spec and becomes
the request body.

The default is only a default. A C<version> key in the arguments is used
verbatim and removed before the spec goes out -- the spec's own fields are all
capitalised (C<Name>, C<Labels>, C<Data>, ...), so a lowercase C<version>
cannot collide with one:

    $secret->update(version => $index, %spec);

Send the whole spec back with the one key edited; the Engine API accepts a
change to C<Labels> only and wants every other field unchanged. Podman does
not implement this endpoint and answers 501.

=head2 remove

    $secret->remove;

Remove the secret. The daemon answers 204 with no body, so this returns
nothing.

=head1 SEE ALSO

=over

=item * L<API::Docker::API::Secrets> - the operations these forward to

=item * L<API::Docker::Type::Secret> - the fields C<list> and C<inspect>
return

=item * L<API::Docker::Role::Entity::Config> - the same shape with a readable
value

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
