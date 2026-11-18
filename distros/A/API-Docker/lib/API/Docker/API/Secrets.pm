package API::Docker::API::Secrets;
# ABSTRACT: Docker Engine Secrets API
our $VERSION = '0.006';
use Moo;
with 'API::Docker::Role::Filters', 'API::Docker::Role::Using';
use API::Docker::Role::Entity::Secret;
use API::Docker::Type::Secret;
use Carp qw( croak );
use MIME::Base64 qw( encode_base64 );
use namespace::clean;


has client => (
  is       => 'ro',
  required => 1,
  weak_ref => 1,
);


# The class is the caller's argument, as it is on the resource classes whose
# list and inspect really are two definitions -- here both are the swagger's
# one `Secret`, and passing it keeps the seam in the same place.
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

# The wire field is base64; the public contract is raw bytes. Guarding the
# character range here keeps the failure a croak naming this class instead of
# MIME::Base64's "Wide character in subroutine entry" from two frames down.
sub _encode_data {
  my ($self, $method, $data) = @_;
  croak __PACKAGE__ . "->$method Data must be a byte string, not decoded "
    . 'characters -- encode it first (Encode::encode_utf8)'
    if $data =~ /[^\x00-\xff]/;
  return encode_base64($data, '');
}

sub list {
  my ($self, %opts) = @_;
  my %params;
  $params{filters} = $self->_normalise_filters($opts{filters})
    if defined $opts{filters};
  return $self->_wrap_list('API::Docker::Type::Secret',
    $self->client->get('/secrets',
      params => \%params,
      %{ $self->_request_options },
    ) // []);
}


sub create {
  my ($self, %spec) = @_;
  croak __PACKAGE__ . '->create Name required'
    unless defined $spec{Name} && length $spec{Name};
  croak __PACKAGE__ . '->create Data required'
    unless defined $spec{Data} && length $spec{Data};
  $spec{Data} = $self->_encode_data('create', $spec{Data});
  return $self->client->post('/secrets/create', \%spec);
}


sub inspect {
  my ($self, $id) = @_;
  croak __PACKAGE__ . '->inspect secret ID or name required'
    unless defined $id && length $id;
  return $self->_wrap('API::Docker::Type::Secret',
    $self->client->get("/secrets/$id",
      %{ $self->_request_options },
    ));
}


sub update {
  my ($self, $id, $version, %spec) = @_;
  croak __PACKAGE__ . '->update secret ID or name required'
    unless defined $id && length $id;
  croak __PACKAGE__ . '->update requires the current version as its second '
    . 'argument: the Version.Index from inspect($id), which the daemon uses '
    . 'as an optimistic-concurrency token and will not accept the update '
    . 'without'
    unless defined $version;
  croak __PACKAGE__ . '->update version must be the numeric Version.Index '
    . "from inspect(\$id), got '$version'"
    unless $version =~ /\A[0-9]+\z/;
  $spec{Data} = $self->_encode_data('update', $spec{Data})
    if defined $spec{Data};
  return $self->client->post("/secrets/$id/update", \%spec,
    params => { version => $version });
}


sub remove {
  my ($self, $id) = @_;
  croak __PACKAGE__ . '->remove secret ID or name required'
    unless defined $id && length $id;
  return $self->client->delete_request("/secrets/$id",
    %{ $self->_request_options },
  );
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::API::Secrets - Docker Engine Secrets API

=head1 VERSION

version 0.006

=head1 SYNOPSIS

    my $docker = API::Docker->new;

    # List secrets
    my $secrets = $docker->secrets->list;

    # Create a secret -- Data is RAW BYTES, this class base64-encodes it
    my $created = $docker->secrets->create(
        Name   => 'my-secret',
        Data   => "hunter2\n",
        Labels => { env => 'prod' },
    );

    # Inspect a secret -- an API::Docker::Type::Secret
    my $secret = $docker->secrets->inspect($created->{ID});
    say $secret->spec->name;

    # Update: the version comes from the inspect above, and is mandatory
    my %spec = %{ $secret->spec->TO_JSON };
    $spec{Labels} = { env => 'staging' };
    $secret->update(%spec);

    # Remove
    $docker->secrets->remove($created->{ID});

=head1 DESCRIPTION

This module provides methods for managing Docker secrets (C</secrets>):
listing, creation, inspection, update and removal.

Accessed via C<< $docker->secrets >>, or through
L<API::Docker::Role::Using/using> for a run of calls that needs its own
transport bound: C<< $docker->secrets->using(read_timeout => 5) >>.

L</list> and L</inspect> return L<API::Docker::Type::Secret> objects carrying
the convenience methods of L<API::Docker::Role::Entity::Secret>. It is B<one>
class for both, where containers and images have two: the swagger answers
C<GET /secrets> with an array of the C<Secret> definition and
C<GET /secrets/{id}> with that same definition. Field names are the
swagger's own spelling in snake_case -- C<ID> is C<< ->id >>, C<CreatedAt> is
C<< ->created_at >> -- and the nested ones are generated classes rather than
the raw HashRefs the old entity kept: C<< $secret->spec >> is an
L<API::Docker::Type::SecretSpec> and C<< $secret->version >> an
L<API::Docker::Type::ObjectVersion>, whose C<< ->index >> is what
C<version_index> reaches.

The value of a secret is write-only. L</list> and L</inspect> return the
metadata -- C<< ->id >>, C<< ->spec >>, C<< ->created_at >>,
C<< ->version >> -- and never the payload; the engine hands that out to
containers, not over this API. If you need to read the value back, this is
the wrong storage: use L<API::Docker::API::Configs>, whose entity offers a
C<decoded_data> because the daemon actually sends one.

=head2 Data is raw bytes; this class does the base64

The wire field C<Data> carries base64. B<This class encodes it for you.> Pass
L</create> raw bytes and they go out encoded; do not pre-encode, or the daemon
faithfully stores your base64 text as the secret.

That division of labour is not a matter of taste, because the daemon does not
validate what it decodes. Measured against Podman 5.4.2: a C<Data> of the
plain text C<"hello there!"> was accepted with B<HTTP 200> and stored three
bytes of garbage -- Go's decoder consumed the leading C<"hell">, stopped at
the space, and reported nothing. A caller left to encode their own payload can
therefore corrupt a secret and be told it succeeded. Doing it here removes
that failure mode from the caller entirely.

The alphabet is B<standard> base64 with padding (C<+> and C</>), not the
URL-safe one, and unwrapped. The Engine API reference calls the field
"base64-url-safe-encoded"; that is measurably not what the engine accepts. The
same four bytes sent as C<-v_--w==> were rejected with B<500>
C<"secret data must be larger than 0 and less than 512000 bytes"> -- the
URL-safe alphabet decoded to nothing -- where C<+v/++w==> was stored correctly.

C<Data> must be a byte string. A string holding characters above C<U+00FF>
croaks here rather than reaching L<MIME::Base64>, which would die with a bare
C<Wide character in subroutine entry>. Encode it first, for instance with
C<Encode::encode_utf8>.

To send an already-encoded value verbatim, bypass this class and use the
transport directly:

    $docker->post('/secrets/create', { Name => 'my-secret', Data => $b64 });

=head2 update takes the current version, and it is mandatory

C<POST /secrets/{id}/update> carries a C<version> query parameter, and the
daemon rejects the request without it. The value is the C<Version.Index> of
the secret as it stands right now, which is what L</inspect> returns:

    my $secret = $docker->secrets->inspect($id);
    $docker->secrets->update($id, $secret->version_index, %spec);

It is an optimistic-concurrency token, not a serial number to invent. If
anything else changed the secret since that C<inspect>, the index has moved on
and the daemon refuses the write instead of silently overwriting that change.
Read it immediately before the update, and read it again before a retry.

This class makes it the second positional argument and croaks when it is
missing or not numeric, so the mistake is caught here rather than one round
trip later. L<API::Docker::Role::Entity::Secret/update> supplies it from the
entity's own C<< ->version->index >> instead, which is the same value read at
the same moment.

The Engine API reference states that only C<Labels> may actually change: every
other field of the spec must be sent back unchanged from what C<inspect>
returned. Hence the C<< %spec = %{ $secret->spec->TO_JSON } >> in the
SYNOPSIS -- C<TO_JSON> renders the spec object back into the daemon's own
spelling, and the whole spec goes back with the one key edited, not just the
key you edited.

=head2 Swarm, and what Podman serves instead

The Engine API groups C</secrets> with Swarm. A Docker daemon that is not a
swarm manager answers B<503> C<"This node is not a swarm manager."> to every
one of these endpoints, and this client turns that into a croak. That is the
engine behaving as documented, not a fault at this end: it needs
C<docker swarm init>, or a manager to talk to -- and a single-node install
that has never run it is the ordinary case, not an edge one.

C<GET /info>'s C<Swarm.LocalNodeState> does not tell you which of those two
you are looking at. Measured fresh against both engines with no swarm
initialized anywhere, it reports C<"inactive"> on Docker and on Podman alike
-- and Podman still serves C</secrets> with B<200> and real data in that
state, while Docker still answers B<503>. Whether C</secrets> works is a
property of the engine, not of that field.

Podman is the useful exception. Measured against Podman 5.4.2 (API 1.41) with
no swarm involved anywhere, C</secrets> is served from Podman's own local
secret store: L</list>, L</create>, L</inspect> and L</remove> all work, and
the objects carry a C<Version.Index> just as Docker's do. Two differences
worth knowing:

=over

=item * L</create> answers B<200> where Docker documents B<201>. The body is
the same C<< { ID => ... } >>, so only code inspecting the status code notices.

=item * L</update> is not implemented at all: B<501>
C<"update is not supported">, with or without a C<version> parameter.

=back

L<API::Docker::API::Configs> gets none of this -- Podman does not serve
C</configs> from a real store the way it does C</secrets>; see
L<API::Docker::API::Configs/"Swarm, and Podman"> for what it answers instead,
which is not simply "no route" on every path.

=head2 client

Reference to L<API::Docker> client. Weak reference to avoid circular dependencies.

=head2 list

    my $secrets = $secrets->list;
    my $secrets = $secrets->list(filters => { label => ['env=prod'] });

List secrets. Returns an ArrayRef of L<API::Docker::Type::Secret> objects,
each carrying the methods of L<API::Docker::Role::Entity::Secret>.

Options:

=over

=item * C<filters> - HashRef of filters, JSON-encoded by the transport. The
Engine API accepts C<id>, C<label>, C<name> and C<names>; values are always
ArrayRefs of strings, shape-checked and normalised by
L<API::Docker::Role::Filters>.

=back

=head2 create

    my $created = $secrets->create(
        Name   => 'my-secret',
        Data   => "hunter2\n",
        Labels => { env => 'prod' },
    );

Create a secret. Returns the daemon's response, a HashRef carrying C<ID> --
not an L<API::Docker::Type::Secret>, because C<ID> is all the daemon answers
with
and an entity built from it would carry no C<Spec> and no C<Version>. Call
L</inspect> on that C<ID> for the object.

Options:

=over

=item * C<Name> - Required. The secret's name.

=item * C<Data> - Required. The secret's value as B<raw bytes>; this method
base64-encodes it. See L</"Data is raw bytes; this class does the base64">.

=item * C<Labels> - HashRef of labels.

=item * C<Driver> - HashRef naming an external secret driver, C<< { Name =>
..., Options => {...} } >>.

=item * C<Templating> - HashRef naming a templating driver, same shape.

=back

=head2 inspect

    my $secret = $secrets->inspect($id);
    my $index  = $secret->version_index;      # what update needs

Get a secret's metadata by ID or name. Returns an
L<API::Docker::Type::Secret> -- the same class L</list> returns -- with
C<< ->id >>, C<< ->spec >>, C<< ->created_at >>, C<< ->updated_at >> and
C<< ->version >>. Never the value -- see
L<API::Docker::Role::Entity::Secret/"There is no accessor for the value">.

=head2 update

    my $secret = $secrets->inspect($id);
    my %spec   = %{ $secret->spec->TO_JSON };
    $spec{Labels} = { env => 'staging' };

    $secrets->update($id, $secret->version_index, %spec);
    $secret->update(%spec);                   # the same call, via the entity

Update a secret. Returns nothing on success -- the daemon answers 200 with an
empty body.

C<$version> is mandatory and is the C<Version.Index> from L</inspect>; see
L</"update takes the current version, and it is mandatory"> for why it cannot
be guessed and why the whole spec goes back.
L<API::Docker::Role::Entity::Secret/update> fills it in from the entity it
was called on. Podman does not implement this
endpoint and answers 501.

=head2 remove

    $secrets->remove($id);

Remove a secret by ID or name. The daemon answers 204 with no body, so this
returns nothing; a secret that is not there is a 404 and croaks.

=head1 SEE ALSO

=over

=item * L<API::Docker> - Main Docker client

=item * L<API::Docker::Role::Entity::Secret> - the convenience methods the
returned objects carry

=item * L<API::Docker::Type::Secret> - the fields L</list> and L</inspect>
return

=item * L<API::Docker::API::Configs> - Configs, the same shape without the
secrecy

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
