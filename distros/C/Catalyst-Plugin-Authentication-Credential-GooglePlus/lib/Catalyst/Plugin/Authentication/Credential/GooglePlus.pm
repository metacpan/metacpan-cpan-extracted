package Catalyst::Plugin::Authentication::Credential::GooglePlus;

use Crypt::OpenSSL::X509;
use JSON::WebToken;
use JSON::MaybeXS;
use MIME::Base64;
use LWP::Simple qw(get);
use Date::Parse qw(str2time);
use Try::Tiny;

use strictures 1;

our $VERSION = 0.1;

=head1 NAME

Catalyst::Authentication::Credential::GooglePlus - Authenticates a user using a
Google Plus token.

=head1 SYNOPSIS

'Plugin::Authentication' => {
    default => {
        credential => {
            class           => 'GooglePlus',
            token_field     => 'id_token',
            public_cert_url => 'https://www.googleapis.com/oauth2/v1/certs',
        },
        store => {
            class => 'DBIx::Class',
            user_model => 'DB::User',
            ...
        },
    },
},

=head1 DESCRIPTION

Retrieves Google's public certificates, and then retrieves the key from the
cert using L<Crypt::OpenSSL::X509>. Finally, uses the pubkey to decrypt a
Google token using L<JSON::WebToken>.

See https://github.com/errietta/Catalyst-Plugin-Authentication-Credential-GooglePlus-example
for an example.

=cut

sub new {
    my ($class, $config, $app, $realm) = @_;
    $class = ref $class || $class;

    my $self = {
        %{ $config },
        %{ $realm->{config} },
        _app => $app,
        _realm => $realm,
    };

    # Google names it id_token
    $self->{token_field} ||= "id_token";

    bless $self, $class;
}

=head1 METHODS

=head2 authenticate

Retrieves a JSON web token from either $authinfo, or GET or POST query
parameters. If null, throws exception.

Otherwise, decodes (with L</decode>) the token, and calls find_user on the
given L<Catalyst::Authentication::Realm> object with the data retrieved from
decoding the token.

=head3 ARGUMENTS

=over

=item $c

Catalyst object.

=item $realm

Catalyst::Authentication::Realm (or subclass) object.

=item $authinfo

Optional, authentication info that can contain the token.  If not given, the
token is retrieved from GET or POST parameters.

=back

=head3 RETURNS

User found by calling L<Catalyst::Authentication::Realm/find_user> with the
decoded token's information, if any.

=cut

sub authenticate {
    my ($self, $c, $realm, $authinfo) = @_;

    my $field = $self->{token_field};

    if (my $cache = $self->get_cache($c)) {
        $self->{cache} ||= $cache;
    }

    my $id_token = $authinfo->{$field};

    $id_token ||= $c->req->method eq 'GET' ?
        $c->req->query_params->{$field} : $c->req->body_params->{$field};

    unless ($id_token) {
        Catalyst::Exception->throw("$field not specified.");
    }

    my $userinfo = $self->decode($id_token);

    my $sub = $userinfo->{sub};
    my $openid = $userinfo->{openid_id};

    unless ($sub && $openid) {
        Catalyst::Exception->throw(
            'Could not retrieve sub and openid from token! Is the token
            correct? Token was ' . $id_token
        );
    }

    return $realm->find_user($userinfo, $c);
}

=head2 retrieve_certs

Retrieves a pair of JSON-encoded certificates from the given $url (defaults to
Google's public cert url), and returns the decoded JSON object.

If a cache plugin is loaded, the certificate pair is cached; however one of the
certificates is expired, a new pair is fetched from $url.

=head3 ARGUMENTS

=over

=item url

Optional. Location where certificates are located.

This can also be configured as the
'Authentication::Credential::Google::public_cert_url' key in your catalyst
configuration.

Defaults to https://www.googleapis.com/oauth2/v1/certs.

=back

=head3 RETURNS

Decoded JSON object containing certificates.

=cut

sub retrieve_certs {
    my ($self, $url) = @_;

    my $c = $self->{_app};
    my $cached = 0;
    my $certs;
    my $cache;

    $url ||= ( $self->{public_cert_url} || 'https://www.googleapis.com/oauth2/v1/certs' );

    if ( $cache = $self->{cache} ) {
        if ($certs = $cache->get($self->{cache_key})) {
            try {
                $certs = decode_json($certs);
            } catch  {
                Catalyst::Exception->throw("Could not decode cached JSON of certs: $_!");
            };

            foreach my $key (keys %$certs) {
                my $cert = $certs->{$key};
                my $x509 = Crypt::OpenSSL::X509->new_from_string($cert);

                if ($self->is_cert_expired($x509)) {
                    $cached = 0;
                    last;
                } else {
                    $cached = 1;
                }
            }
        }
    }

    unless ($cached) {
        my $certs_encoded = get($url);

        unless ($certs_encoded) {
            Catalyst::Exception->throw("Could not GET $url! Please check the value of your public_cert_url config!");
        }

        try {
            $certs = decode_json($certs_encoded);
        } catch {
            Catalyst::Exception->throw("Could not decode JSON cert content from $url, is URL correct?");
        };

        if ($cache) {
            $cache->set($self->{cache_key}, $certs_encoded);
        }
    }

    return $certs;
}

=head2 get_key_from_cert

Given a pair of certificates $certs (defaults to L</retrieve_certs>),
this function returns the public key of the cert identified by $kid.

=head3 ARGUMENTS

=over

=item $kid

Required. Index of the certificate hash $hash where the cert we want is
located.

=item $certs

Optional. A (hashref) pair of certificates.
It's retrieved using L</retrieve_certs> if not given,
or if the pair is expired.

=item $recursive

This will be set to true if this function calls itself to renew an expired
certificate. Used to prevent infinite recursion.

=back

=head3 RETURNS

Public key of certificate.

=cut

sub get_key_from_cert {
    my ($self, $kid, $certs, $recursive) = @_;

    $certs ||= $self->retrieve_certs;
    my $cert = $certs->{$kid};
    my $x509;

    try {
        $x509 = Crypt::OpenSSL::X509->new_from_string($cert);
    } catch {
        Catalyst::Exception->throw("Could not get public key from provided certificate, is the certificate valid?\nCert was:" . $cert );
    };

    if ($self->is_cert_expired($x509)) {
        unless ($recursive) {
            # If we ended up here, we were given
            # an old $certs string from the user.
            # Let's force getting another.
            return $self->get_key_from_cert($kid, undef, 1);
        } else {
            Catalyst::Exception->throw("Something is very wrong; we were given
                an expired cert and got another expired cert trying to get a
                new one! \nCert was:" . $cert);
        }
    }

    return $x509->pubkey;
}

=head2 is_cert_expired

Returns if a given L<Crypt::OpenSSL::X509> certificate is expired.

=cut

sub is_cert_expired {
    my ($self, $x509) = @_;

    my $expiry = str2time($x509->notAfter);

    return time > $expiry;
}

=head2 decode

Returns the decoded information contained in a user's token.

=head3 ARGUMENTS

=over

=item $token

Required. The user's token from Google+.

=item $certs

Optional. A pair of public key certs retrieved from Google.
If not given, or if the certificates have expired, a new
pair of certificates is retrieved.

=item $pubkey

Optional. A public key string with which to decode the token.
If not given, the public key will be retrieved from $certs.

=back

=head2 RETURNS

Decoded JSON object from the decrypted token.

=cut

sub decode {
    my ($self, $token, $certs, $pubkey) = @_;

    unless ($pubkey) {
        my $details;

        try {
            $details = decode_json(
                MIME::Base64::decode_base64(
                    substr( $token, 0, CORE::index($token, '.') )
                )
            );
        } catch {
            Catalyst::Exception->throw("Could not decode token, is the token valid? token is " . $token);
        };

        my $kid = $details->{kid};

        unless ($kid) {
            Catalyst::Exception->throw("Decoded token has no `kid` member; is token valid? token is " . $token);
        }

        $pubkey = $self->get_key_from_cert($kid, $certs);
    }

    my $result;

    try {
        $result = JSON::WebToken->decode($token, $pubkey);
    } catch {
        Catalyst::Exception->throw("Could not decode the given token with the public key! Token is " . $token . " and pubkey is " . $pubkey);
    };

    return $result;
}

sub get_cache {
    my ($self, $c) = @_;

    if ($self->{use_context_cache}) {
        return $c->cache;
    } else {
        return $self->{cache};
    }
}

=head1 CAVEATS

=over

=item
We currently have no automated (unit) tests..

=item
The code that verifies the key from Google (L</get_key_from_cert> only checks
if the key has expired. It does not check that the key is signed by the right
people - i.e. a correctly formatted self-signed key would still work...

=back

=head1 AUTHOR

Errietta Kostala <e.kostala@shadowcat.co.uk>

=head1 CONTRIBUTORS

=over

=item
Matt S. Trout <mst@shadowcat.co.uk>

=item
Chris Jackson <c.jackson@shadowcat.co.uk>

=item
Jess Robinson <j.robinson@shadowcat.co.uk>

=back

=head1 SPONSORS

=over

=item
Shadowcat Systems LTD. (L<http://shadow.cat>)

=item
Tara L Andrews, Digital Humanities, University of Bern

=back

=head1 COPYRIGHT

Copyright (c) 2015 the Catalyst::Plugin::Authentication::Credential::GooglePlus
L</AUTHOR> and L</CONTRIBUTORS> as listed above.

=head1 LICENSE

This library is free software and may be distributed under the same terms as
perl itself. See L<http://dev.perl.org/licenses/>.

=cut

1;
