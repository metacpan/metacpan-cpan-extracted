package API::Docker::API::Configs;
# ABSTRACT: Docker Engine Configs API
our $VERSION = '0.006';
use Moo;
with 'API::Docker::Role::Filters', 'API::Docker::Role::Using';
use API::Docker::Role::Entity::Config;
use API::Docker::Type::Config;
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
# one `Config`, and passing it keeps the seam in the same place.
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
  return $self->_wrap_list('API::Docker::Type::Config',
    $self->client->get('/configs',
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
  return $self->client->post('/configs/create', \%spec);
}


sub inspect {
  my ($self, $id) = @_;
  croak __PACKAGE__ . '->inspect config ID or name required'
    unless defined $id && length $id;
  return $self->_wrap('API::Docker::Type::Config',
    $self->client->get("/configs/$id",
      %{ $self->_request_options },
    ));
}


sub update {
  my ($self, $id, $version, %spec) = @_;
  croak __PACKAGE__ . '->update config ID or name required'
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
  return $self->client->post("/configs/$id/update", \%spec,
    params => { version => $version });
}


sub remove {
  my ($self, $id) = @_;
  croak __PACKAGE__ . '->remove config ID or name required'
    unless defined $id && length $id;
  return $self->client->delete_request("/configs/$id",
    %{ $self->_request_options },
  );
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::API::Configs - Docker Engine Configs API

=head1 VERSION

version 0.006

=head1 SYNOPSIS

    my $docker = API::Docker->new;

    # List configs
    my $configs = $docker->configs->list;

    # Create a config -- Data is RAW BYTES, this class base64-encodes it
    my $created = $docker->configs->create(
        Name   => 'my-config',
        Data   => "listen 8080;\n",
        Labels => { app => 'web' },
    );

    # Inspect a config -- an API::Docker::Type::Config; spec->data stays base64
    my $config = $docker->configs->inspect($created->{ID});
    my $text   = $config->decoded_data;

    # Update: the version comes from the inspect above, and is mandatory
    my %spec = %{ $config->spec->TO_JSON };
    delete $spec{Data};                       # already base64 -- see below
    $spec{Labels} = { app => 'web', tier => 'edge' };
    $config->update(%spec);

    # Remove
    $docker->configs->remove($created->{ID});

=head1 DESCRIPTION

This module provides methods for managing Docker configs (C</configs>):
listing, creation, inspection, update and removal.

Accessed via C<< $docker->configs >>, or through
L<API::Docker::Role::Using/using> for a run of calls that needs its own
transport bound: C<< $docker->configs->using(read_timeout => 5) >>.

L</list> and L</inspect> return L<API::Docker::Type::Config> objects carrying
the convenience methods of L<API::Docker::Role::Entity::Config>. It is B<one>
class for both, where containers and images have two: the swagger answers
C<GET /configs> with an array of the C<Config> definition and
C<GET /configs/{id}> with that same definition. Field names are the
swagger's own spelling in snake_case -- C<ID> is C<< ->id >>, C<CreatedAt> is
C<< ->created_at >> -- and the nested ones are generated classes rather than
the raw HashRefs the old entity kept: C<< $config->spec >> is an
L<API::Docker::Type::ConfigSpec> and C<< $config->version >> an
L<API::Docker::Type::ObjectVersion>, whose C<< ->index >> is what
C<version_index> reaches.

Configs are L<API::Docker::API::Secrets> without the secrecy: the same five
endpoints, the same spec shape, the same mandatory C<version> on update. The
one behavioural difference is that a config's value can be read back --
L</inspect> returns it in C<< $config->spec->data >>, and
L<API::Docker::Role::Entity::Config/decoded_data> decodes it, where a secret
returns no payload at all. Which is the whole point of the split: put configuration in
a config, and anything you would mind seeing in a C<docker config inspect> in
a secret.

=head2 Data is raw bytes on the way out, base64 on the way back

The wire field C<Data> carries base64. B<L</create> and L</update> encode it
for you> -- pass them raw bytes, and do not pre-encode, or the daemon stores
your base64 text as the config's content.

Doing it here is not a convenience, it is a guard. The daemon does not
validate what it decodes: measured against Podman 5.4.2's C</secrets>, which
takes the identical field, a C<Data> of the plain text C<"hello there!"> was
accepted with B<HTTP 200> and stored three bytes of garbage -- Go's decoder
took the leading C<"hell">, stopped at the space, and said nothing. A caller
left to encode their own payload can corrupt the value and be told it worked.

The alphabet is B<standard> base64 with padding (C<+> and C</>), unwrapped,
and not the URL-safe one. The Engine API reference calls the field
"base64-url-safe-encoded" and that is measurably not what the engine takes:
four bytes sent as C<-v_--w==> were rejected B<500>, the same four as
C<+v/++w==> stored correctly.

C<Data> must be a byte string. Characters above C<U+00FF> croak here rather
than reaching L<MIME::Base64> and dying with a bare
C<Wide character in subroutine entry>; encode first, e.g. with
C<Encode::encode_utf8>.

B<The reverse trip is not symmetric, deliberately.> L</inspect> and L</list>
hand back what the daemon sent with nothing rewritten, so
C<< $config->spec->data >> is still base64. Decoding is a separate,
explicit call on the entity:

    my $text = $config->decoded_data;

The asymmetry follows one rule: this class encodes where getting it wrong is
silent, and rewrites nothing where getting it wrong is visible. An unencoded
C<Data> going out is stored as garbage with a 200; a base64 string coming back
is obvious the moment you look at it. So the decode is offered where it costs
nothing -- L<API::Docker::Role::Entity::Config/decoded_data> derives the bytes
on demand and leaves the spec verbatim -- rather than by replacing a field of a daemon
response, which nothing in this distribution does.

To send an already-encoded value verbatim, bypass this class:

    $docker->post('/configs/create', { Name => 'my-config', Data => $b64 });

=head2 update takes the current version, and it is mandatory

C<POST /configs/{id}/update> carries a C<version> query parameter and the
daemon rejects the request without it. The value is the C<Version.Index> of
the config as it stands right now, which is what L</inspect> returns:

    my $config = $docker->configs->inspect($id);
    $docker->configs->update($id, $config->version_index, %spec);

It is an optimistic-concurrency token, not a serial number to invent. If
anything else changed the config since that C<inspect>, the index has moved on
and the daemon refuses the write rather than silently overwriting that change.
Read it immediately before the update, and again before a retry.

This class makes it the second positional argument and croaks when it is
missing or not numeric, so the mistake surfaces here instead of one round trip
later. L<API::Docker::Role::Entity::Config/update> supplies it from the
entity's own C<< ->version->index >> instead, which is the same value read at
the same moment.

The Engine API reference states that only C<Labels> may actually change: the
rest of the spec must go back unchanged from what C<inspect> returned. Hence
C<< %spec = %{ $config->spec->TO_JSON } >> in the SYNOPSIS -- C<TO_JSON>
renders the spec object back into the daemon's own spelling, and the whole
spec goes back with the one key edited. Note that a spec from C<inspect>
carries C<Data> already base64-encoded, so passing it straight to L</update>
would encode it a second time; delete the key, or pass
L<API::Docker::Role::Entity::Config/decoded_data> in its place, before
sending it back.

=head2 Swarm, and Podman

The Engine API groups C</configs> with Swarm. A Docker daemon that is not a
swarm manager answers B<503> C<"This node is not a swarm manager."> to all of
these endpoints, which this client turns into a croak. That is documented
engine behaviour, not a fault at this end -- the daemon needs
C<docker swarm init>, or a manager to talk to, and a single-node install that
has never run it is the ordinary case, not an edge one.

B<Podman does not serve C</configs>,> though what it answers for "not served"
differs by path. Measured against the rootless socket on Podman 5.8.4 (API
1.44): C<GET /configs> -- the collection listing -- still answers B<404> with
the plain-text body C<Not Found>, not a JSON error, so the croak from this
client reads C<Docker API error (404): Not Found>. Every other path under it
-- C<GET /configs/{id}>, C<POST /configs/create>, C<DELETE /configs/{id}> and
C<POST /configs/{id}/update> -- answers B<503> instead, with a JSON body
naming the route it refuses, e.g. C<< {"cause":"Podman does not support
service: /v1.44/configs/xyz","message":"...","response":503} >>.

An earlier pass measured every path here as a flat 404 against Podman 5.4.2
(API 1.41). That measurement is not reproducible on this machine any more --
5.4.2 is gone from it -- so whether 5.8.4 actually changed this or the
original pass only ever exercised the collection endpoint is not something
this distribution can decide from here; it is recorded as what 5.8.4 answers,
not as a change from 5.4.2. Either way, the split this section used to draw
between the two engines -- Docker's 503 "not a swarm manager" against a flat
Podman 404 -- no longer holds cleanly: most C</configs> paths on Podman answer
503 too now, just with a different body and for a different reason.

There is no Podman-side equivalent to fall back on and no socket setting that
enables it. This remains the one class in the distribution that cannot be
exercised for real against the engine the rest of it is tested on --
L<API::Docker::API::Secrets>, the same five endpoints, is served by Podman
from its own local secret store.

=head2 client

Reference to L<API::Docker> client. Weak reference to avoid circular dependencies.

=head2 list

    my $configs = $configs->list;
    my $configs = $configs->list(filters => { label => ['app=web'] });

List configs. Returns an ArrayRef of L<API::Docker::Type::Config> objects,
each carrying the methods of L<API::Docker::Role::Entity::Config>. Each
carries a C<< ->spec->data >> that is still base64;
L<API::Docker::Role::Entity::Config/decoded_data> is the decode.

Options:

=over

=item * C<filters> - HashRef of filters, JSON-encoded by the transport. The
Engine API accepts C<id>, C<label>, C<name> and C<names>; values are always
ArrayRefs of strings, shape-checked and normalised by
L<API::Docker::Role::Filters>.

=back

=head2 create

    my $created = $configs->create(
        Name   => 'my-config',
        Data   => "listen 8080;\n",
        Labels => { app => 'web' },
    );

Create a config. Returns the daemon's response, a HashRef carrying C<ID> --
not an L<API::Docker::Type::Config>, because C<ID> is all the daemon answers
with and an entity built from it would carry no C<Spec> and no C<Version>. Call
L</inspect> on that C<ID> for the object.

Options:

=over

=item * C<Name> - Required. The config's name.

=item * C<Data> - Required. The config's content as B<raw bytes>; this method
base64-encodes it. See L</"Data is raw bytes on the way out, base64 on the way back">.

=item * C<Labels> - HashRef of labels.

=item * C<Templating> - HashRef naming a templating driver,
C<< { Name => ..., Options => {...} } >>.

=back

=head2 inspect

    my $config = $configs->inspect($id);
    my $index  = $config->version_index;      # what update needs
    my $text   = $config->decoded_data;

Get a config by ID or name. Returns an L<API::Docker::Type::Config> -- the
same class L</list> returns -- with C<< ->id >>, C<< ->spec >>,
C<< ->created_at >>, C<< ->updated_at >> and C<< ->version >> as the daemon
sent them. C<< ->spec->data >> is base64 and is B<not> rewritten;
L<API::Docker::Role::Entity::Config/decoded_data> derives the bytes from it
on demand.

=head2 update

    my $config = $configs->inspect($id);
    my %spec   = %{ $config->Spec };
    delete $spec{Data};                       # already base64 -- see below
    $spec{Labels} = { app => 'web', tier => 'edge' };

    $configs->update($id, $config->version_index, %spec);
    $config->update(%spec);                   # the same call, via the entity

Update a config. Returns nothing on success -- the daemon answers 200 with an
empty body.

C<$version> is mandatory and is the C<Version.Index> from L</inspect>; see
L</"update takes the current version, and it is mandatory"> for why it cannot
be guessed and why the whole spec goes back.
L<API::Docker::Role::Entity::Config/update> fills it in from the entity it
was called on.

A C<Data> passed here is treated like L</create>'s: raw bytes, encoded on the
way out. The C<Data> in a spec from L</inspect> is already base64, so drop
it, or replace it with
L<API::Docker::Role::Entity::Config/decoded_data>, before handing that spec
back -- otherwise it gets encoded twice.

=head2 remove

    $configs->remove($id);

Remove a config by ID or name. The daemon answers 204 with no body, so this
returns nothing; a config that is not there is a 404 and croaks.

=head1 SEE ALSO

=over

=item * L<API::Docker> - Main Docker client

=item * L<API::Docker::Role::Entity::Config> - the convenience methods the
returned objects carry

=item * L<API::Docker::Type::Config> - the fields L</list> and L</inspect>
return

=item * L<API::Docker::API::Secrets> - Secrets, the same shape for values that
must not be readable back

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
