package API::Docker::Role::Entity::Config;
# ABSTRACT: Config operations, on the generated config type
our $VERSION = '0.006';
use Moo::Role;
with 'API::Docker::Role::Entity';
requires 'id';
use API::Docker::Type::Config;
use Carp qw( croak );
use MIME::Base64 qw( decode_base64 );
use Package::Stash;
use namespace::clean;


sub decoded_data {
  my ($self) = @_;
  my $spec = $self->spec;
  return unless defined $spec;
  my $data = $spec->data;
  return unless defined $data;
  return decode_base64($data);
}


sub version_index {
  my ($self) = @_;
  my $version = $self->version;
  return unless defined $version;
  return $version->index;
}


sub inspect {
  my ($self) = @_;
  return $self->client->configs->inspect($self->id);
}


sub update {
  my ($self, %opts) = @_;
  my $version
    = exists $opts{version} ? delete $opts{version} : $self->version_index;
  return $self->client->configs->update($self->id, $version, %opts);
}


sub remove {
  my ($self) = @_;
  return $self->client->configs->remove($self->id);
}


# --- composition -----------------------------------------------------------
#
# Here rather than in API::Docker::API::Configs, for the reason spelled out in
# API::Docker::Role::Entity::Container: loading this role is what puts the
# methods on the class.
#
# The clash check is not decoration. Moo composes a role into a class the
# class-wins way, so a generated accessor of the same name as a method here
# would silently keep its place and the method would be missing -- and the
# generated classes are written from a specification that grows fields
# without asking. None of the five names collides today; a future one says so
# on the first `use`. `version_index` is the one to watch: the class already
# declares `version`.
{
  my @provided = Package::Stash->new(__PACKAGE__)->list_all_symbols('CODE');
  for my $class ('API::Docker::Type::Config') {
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

API::Docker::Role::Entity::Config - Config operations, on the generated config type

=head1 VERSION

version 0.006

=head1 SYNOPSIS

    my $docker = API::Docker->new;
    my ($config) = @{ $docker->configs->list };

    say $config->id;
    say $config->spec->name;
    say $config->spec->data;        # still base64, as the daemon sent it
    say $config->decoded_data;      # the bytes

    my %spec = %{ $config->spec->TO_JSON };
    delete $spec{Data};             # already base64 -- see update
    $spec{Labels} = { app => 'web' };
    $config->update(%spec);

    $config->remove;

=head1 DESCRIPTION

The convenience methods of a Docker config. This role is composed, at load
time, into L<API::Docker::Type::Config>, the generated class the daemon
answers config requests with -- the same definition for C<GET /configs> and
C<GET /configs/{id}>, so L<API::Docker::API::Configs/list> and
L<API::Docker::API::Configs/inspect> hand back one class and there is no
list-versus-inspect shape to keep apart.

A config is a secret whose value can be read back: the daemon returns it in
C<< spec->data >> as base64, where a secret returns no payload at all --
L<API::Docker::Role::Entity::Secret/"There is no accessor for the value">.
L</decoded_data> is the accessor for it.

=head2 Decoding is offered here, not in the API class

L<API::Docker::API::Configs> hands back the daemon's response with nothing
rewritten, which is the rule the whole distribution follows -- so
C<< $config->spec->data >> is the base64 string the engine sent, unchanged,
and stays that way. L</decoded_data> does not touch it either: it decodes on
demand and returns the bytes, leaving the spec verbatim for anyone who wants
to compare it against the wire or hand it back.

That is the whole reason the accessor belongs on the entity rather than on
the API class: an entity may offer a derived view of a response, an API
method may not silently replace one.

=head2 The spec goes back as a whole

C<< $config->spec >> is an L<API::Docker::Type::ConfigSpec> object rather
than the raw HashRef the hand-written entity kept, so the idiom for an update
is C<< %{ $config->spec->TO_JSON } >>: C<TO_JSON> renders the spec back into
the daemon's own spelling, which is what L</update> puts in the request body.
Mind the C<Data> it brings with it -- see L</update>.

Why the methods are a role applied to a generated class rather than a class
of their own: L<API::Docker::Role::Entity/DESCRIPTION>.

=head2 decoded_data

    my $text = $config->decoded_data;

The config's content: C<< $config->spec->data >> run through
L<MIME::Base64/decode_base64>. Returns nothing when the object carries no
C<Spec> or no C<Data> in it.

The result is B<raw bytes>, symmetric with what
L<API::Docker::API::Configs/create> takes -- decode the character set yourself
if the config holds text above C<U+007F>, for instance with
C<Encode::decode_utf8>.

The spec is left alone; see
L</"Decoding is offered here, not in the API class">.

=head2 version_index

    my $index = $config->version_index;

The C<< ->index >> out of C<< ->version >>, which is what the daemon wants as
the C<version> query parameter on an update. Returns nothing when the object
carries no C<Version> -- including the case where the daemon sent one the
model could not use, which leaves the attribute unset and the raw value in
C<< ->unknown_fields->{Version} >>.

It is the version as of the moment this object was fetched, which is exactly
the token's meaning: an update built on a stale entity is refused by the
daemon rather than silently overwriting whatever changed in between.

=head2 inspect

    my $fresh = $config->inspect;

Get fresh config information. Returns another L<API::Docker::Type::Config> --
the same class, since the daemon describes a config one way.

=head2 update

    my %spec = %{ $config->spec->TO_JSON };
    delete $spec{Data};                 # already base64 -- see below
    $spec{Labels} = { app => 'web' };
    $config->update(%spec);

Update the config. Passes C<< ->id >> and, by default, L</version_index> to
L<API::Docker::API::Configs/update>; everything else is the spec and becomes
the request body.

The default is only a default. A C<version> key in the arguments is used
verbatim and removed before the spec goes out -- the spec's own fields are all
capitalised (C<Name>, C<Labels>, C<Data>, ...), so a lowercase C<version>
cannot collide with one:

    $config->update(version => $index, %spec);

A C<Data> passed here is raw bytes and gets encoded on the way out, so the
C<Data> that C<< $config->spec->TO_JSON >> brings along -- already base64 --
would be encoded a second time. Drop it, or pass L</decoded_data> in its
place.

=head2 remove

    $config->remove;

Remove the config. The daemon answers 204 with no body, so this returns
nothing.

=head1 SEE ALSO

=over

=item * L<API::Docker::API::Configs> - the operations these forward to

=item * L<API::Docker::Type::Config> - the fields C<list> and C<inspect>
return

=item * L<API::Docker::Role::Entity::Secret> - the same shape for a value
that cannot be read back

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
