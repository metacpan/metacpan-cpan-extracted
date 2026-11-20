package Browser::OIDC;

use 5.020;
use warnings;
use experimental qw/signatures postderef lexical_subs/;

use Carp;
use List::Util 1.33 qw/first none/;
use MIME::Base64 qw/encode_base64url/;
use Mojo::URL;
use Mojo::Util qw/random_bytes/;

use Browser::OAuth2;
use Browser::OIDC::TokenResponse;

our $VERSION = '0.005';

my $ua = Mojo::UserAgent->new;

my sub validate_url($name, $url) {
	croak "$name is undefined" unless defined $url;
	my $uri = Mojo::URL->new($url);
	croak "Invalid URL for $name" unless ($uri->scheme // '') eq 'https' && length $uri->host;
}

sub new_from_discovery($class, $target_base) {
	validate_url('target_base', $target_base);
	my $response = $ua->get("$target_base/.well-known/openid-configuration")->result;
	croak "Error: ". $response->code if not $response->is_success;
	my $config = $response->json;
	croak "Error: non-matching issuer" if $config->{issuer} ne $target_base;
	return $class->new_from_config($config);
}

sub new_from_config($class, $config) {
	validate_url($_, $config->{$_}) for qw/issuer authorization_endpoint token_endpoint jwks_uri/;
	defined $config->{$_} && validate_url($_, $config->{$_}) for qw/userinfo_endpoint/;
	my $auth_methods_supported = $config->{token_endpoint_auth_methods_supported} // ['client_secret_basic'];
	my %auth_methods_supported = map { $_ => 1 } $auth_methods_supported->@*;
	my $auth_method = first { $auth_methods_supported{$_} } qw/client_secret_post client_secret_basic none/;
	croak("Don't know how to authenticate token") unless $auth_method;
	my $grant_types_supported = $config->{grant_types_supported} // ['authorization_code'];
	croak "Only Authorization Code Flow is supported yet" if none { $_ eq 'authorization_code' } $grant_types_supported->@*;
	my $response_types_supported = $config->{response_types_supported} // ['code'];
	croak "code is required for authorization code flow"  if none { $_ eq 'code' } $response_types_supported->@*;

	return bless {
		$config->%{qw/issuer authorization_endpoint token_endpoint userinfo_endpoint claims_supported scopes_supported jwks_uri/},
		auth_method  => $auth_method,
		response_iss => !!$config->{authorization_response_iss_parameter_supported},
		ua           => $ua,
	}, $class;
}

sub get_token($self, %options) {
	my $oauth2 = Browser::OAuth2->new(
		delete %options{'client_id', 'client_secret'},
		auth_method => $self->{auth_method},
	);

	unshift $options{scope}->@*, 'openid';
	$options{nonce} = encode_base64url(random_bytes(32)) if not exists $options{nonce};
	$options{response_iss} = $self->{issuer} if $self->{response_iss};

	my $payload = $oauth2->get_authorization($self->{authorization_endpoint}, %options);
	my $response = $oauth2->get_token($self->{token_endpoint}, $payload->%*);
	return Browser::OIDC::TokenResponse->new(parent => $self, value => $response, nonce => $options{nonce});
}

sub issuer($self) {
	return $self->{issuer};
}

sub claims_supported($self) {
	return ($self->{claims_supported} // [])->@*;
}

sub scopes_supported($self) {
	return ($self->{scopes_supported} // [])->@*;
}

sub jwks($self) {
	return $self->{jwks} //= do {
		my $response = $ua->get($self->{jwks_uri})->result;
		croak "Could not fetch JSON Web Key Set" if not $response->is_success;
		$response->json;
	};
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Browser::OIDC - Get an OIDC token for a CLI application

=head1 SYNOPSIS

 my $oidc = Browser::OIDC->new_from_discovery($base_url);
 my $token = $oidc->get_token(
	 client_id => 'me',
	 scope     => [ 'email' ],
 );

=head1 DESCRIPTION

This module will open a browser for you to log into some OIDC provider, and will temporarily run a webserver on localhost to receive the redirect with the results from your browser.

=head1 METHODS

=head2 new_from_discovery

 my $oidc = Browser::OIDC->new($base_url);

This creates a new C<Browser::OIDC> object. This will fetch the configuration for the given C<$base_url>.

=head2 new_from_config

 my $oidc = Browser::OIDC->new($config);

This creates a new C<Browser::OIDC> object. This use a OIDC discovery configuration instead of fetching it.

=head2 get_token

 $oidc->get_token(%options);

This fetches OIDC tokens from the endpoint. Note though that this module only fetches the tokens, it will not perform any decoding or verification on them.

It takes the following options:

=over 4

=item client_id

The client identifier. Mandatory.

=item client_secret

The client secret, if any.

=item scope

This list will be the scopes of the request. C<'openid'> is automatically added to this list so does not need to be given.

=item nonce

The nonce used in the request. If none if given one will be generated automatically.

=item message

The message that will be shown to the user in the browser on completion.

=item message_type

The content type of the message e.g. C<text/plain> or C<text/html>.

=item display

ASCII string value that specifies how the Authorization Server displays the authentication and consent user interface pages to the End-User. The defined values are: C<page>, C<popup>, C<touch>, and C<wap>.

=item prompt

Case-sensitive list of ASCII string values that specifies whether the Authorization Server prompts the End-User for reauthentication and consent. The defined values are: C<none>, C<login>, C<consent>, and C<select_account>.

=item max_age

Maximum Authentication Age. Specifies the allowable elapsed time in seconds since the last time the End-User was actively authenticated by the OP. Note that C<max_age=0> is equivalent to C<prompt=login>.

=item login_hint

Hint to the Authorization Server about the login identifier the End-User might use to log in (if necessary).

=back

=head2 issuer

 $oidc->issuer;

This returns the issuer. This should match the C<iss> values in the tokens.

=head2 claims_supported

 $oidc->claims_supported;

This returns the list of supported claims.

=head2 scopes_supported

 $oidc->scopes_supported;

This returns the list of supported scopes.

=head2 jwks

 my $keyset = $oidc->jwks;

This fetches JSON Web Key Set for this OIDC provider, and returns it as a hash, with keys as a arrayref of JWK entries. This value will be cached.

=head1 TODO

Open ID Connect and OAuth2 are large standards, so far only a tiny fraction is implemented here. Feel free to request specific features if you need them. Patches are welcome.

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
