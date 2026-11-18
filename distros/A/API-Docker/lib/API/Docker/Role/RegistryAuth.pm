package API::Docker::Role::RegistryAuth;
# ABSTRACT: AuthConfig encoding shared by the registry-facing endpoints
our $VERSION = '0.006';
use Moo::Role;
use Carp qw( croak );
use JSON::MaybeXS qw( decode_json encode_json );
use MIME::Base64 qw( decode_base64 encode_base64 );
use namespace::clean;


sub _registry_auth_header {
  my ($self, $auth) = @_;
  return $self->_registry_b64url($auth);
}

sub _registry_config_header {
  my ($self, $config) = @_;
  return $self->_registry_b64url($config);
}

# The single encoding both header shapes share: X-Registry-Auth carries one
# AuthConfig, X-Registry-Config a map of registry hostname to AuthConfig, but
# each is nothing more than a JSON value in padded base64url. Keeping it in one
# place is the whole reason this role exists -- two copies of a base64 routine
# are what drifted apart before it.
sub _registry_b64url {
  my ($self, $value) = @_;

  my $payload;
  if (!defined $value) {
    $payload = '{}';
  }
  elsif (ref $value eq 'HASH') {
    $payload = encode_json($value);
  }
  else {
    # Already pre-built JSON or a pre-encoded string. A base64-looking one
    # (no braces) passes through -- but respelled into the URL-safe alphabet
    # first, because the engine decodes with Go's base64.URLEncoding and a
    # '+' or '/' left over from standard base64 makes it fail. This is the
    # inverse of the tr{-_}{+/} in _registry_auth_config below.
    if ($value =~ /^[A-Za-z0-9+\/=_\-]+$/) {
      $value =~ tr{+/}{-_};
      return $value;
    }
    $payload = $value;
  }

  # Padded base64url, and the padding is not optional -- see above.
  my $b64 = encode_base64($payload, '');
  $b64 =~ tr{+/}{-_};
  return $b64;
}

sub _registry_auth_config {
  my ($self, $auth) = @_;

  return undef unless defined $auth;
  return { %$auth } if ref $auth eq 'HASH';
  croak __PACKAGE__ . '->_registry_auth_config auth must be a HashRef, a '
    . 'JSON object or a base64url-encoded one' if ref $auth;

  # The inverse of _registry_auth_header, so a caller can hand POST /auth
  # exactly what it was going to push with -- including a header value it
  # built earlier. The same "looks base64-like" test decides, and in the same
  # order, or the two would disagree about a given string.
  my $json = $auth;
  unless ($auth =~ /^\s*\{/) {
    my $b64 = $auth;
    $b64 =~ tr{-_}{+/};
    # decode_base64 tolerates missing padding, so a value that lost its '='
    # somewhere still decodes here; the header side is where the pad matters.
    $json = decode_base64($b64);
  }

  my $config = eval { decode_json($json) };
  croak __PACKAGE__ . '->_registry_auth_config could not read auth as an '
    . 'AuthConfig: ' . $@ unless ref $config eq 'HASH';
  return $config;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Role::RegistryAuth - AuthConfig encoding shared by the registry-facing endpoints

=head1 VERSION

version 0.006

=head1 SYNOPSIS

    package API::Docker::API::Whatever;
    use Moo;
    with 'API::Docker::Role::RegistryAuth';

    # The header form: X-Registry-Auth on a registry-facing request
    my $header = $self->_registry_auth_header($opts{auth});

    # The map-header form: X-Registry-Config on /build, hostname -> AuthConfig
    my $cfg_header = $self->_registry_config_header($opts{registry_config});

    # The body form: the same credentials as a plain HashRef
    my $config = $self->_registry_auth_config($opts{auth});

=head1 DESCRIPTION

One AuthConfig, three carriers. The Docker Engine takes registry credentials
as a JSON object with the keys C<username>, C<password>, C<serveraddress>,
C<identitytoken> and C<email>, and moves it around in three shapes:

=over

=item * base64url-encoded in the C<X-Registry-Auth> request header, for
C<< POST /images/{name}/push >>, C<< POST /images/create >>,
C<< GET /distribution/{name}/json >> and the C</plugins> family

=item * as a base64url-encoded B<map> of registry hostname to AuthConfig in
the C<X-Registry-Config> request header, for C<< POST /build >> -- one build
may pull base images from several registries, so it carries a set of
credentials rather than one

=item * as the plain JSON request body of C<< POST /auth >>

=back

This role carries the conversion in both directions so every class that
speaks to a registry agrees on it, and so a caller can hand the same C<auth>
argument to any of them.

B<It carries the encoding, not the policy.> Whether a header is sent at all
differs per endpoint on purpose and stays with the endpoint:
L<API::Docker::API::Images/push> sends C<X-Registry-Auth> on B<every> push
because the engine rejects an image push without it, while an anonymous
plugin or distribution call sends B<no> header -- their routers decode the
header and discard the error, so an absent one is the anonymous case rather
than a failure.

=head2 The padding is not optional

The engine decodes C<X-Registry-Auth> with Go's C<base64.URLEncoding>, not
C<RawURLEncoding>, so the C<=> padding is required. Stripping it makes every
push fail with
C<< failed to parse "X-Registry-Auth" header ... unexpected EOF >> -- the
anonymous case included, where the payload C<{}> encodes to C<e30=>: three
characters and one pad.

=head1 METHODS

These are private and composed into the resource classes; they are documented
here because the shapes are one decision, not several.

C<_registry_auth_header($auth)> returns the padded base64url value for
C<X-Registry-Auth>. C<undef> gives the anonymous encoding C<e30=>, a HashRef
is JSON-encoded, and a string that already looks base64-encoded is passed
through -- but respelled into the URL-safe alphabet, so a value pre-encoded in
standard base64 (with C<+> or C</>) reaches the wire as the C<->/C<_> the
engine's C<base64.URLEncoding> decoder expects rather than failing there.

C<_registry_config_header($map)> is the same encoding for C<X-Registry-Config>
on C<< POST /build >>. It takes the same shapes, but the HashRef it JSON-encodes
is a B<map> of registry hostname to AuthConfig
(C<< { 'registry.example:5000' => { username => ..., password => ... } } >>),
not a single AuthConfig.

C<_registry_auth_config($auth)> returns the same credentials as a plain
HashRef for a JSON request body. C<undef> gives C<undef> -- whether that is
an error is the endpoint's call, not this role's. A HashRef is copied, a JSON
object is decoded, and a base64url string is decoded back through both
layers. Anything that does not read as an AuthConfig croaks.

=head1 SEE ALSO

=over

=item * L<API::Docker::API::Images> - C<push>, which always sends the header

=item * L<API::Docker::API::System> - C<auth>, which sends the body form

=item * L<API::Docker::API::Distribution> - registry manifest lookups

=item * L<API::Docker::API::Plugins> - the plugin family, which sends the
header only when credentials were given

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
