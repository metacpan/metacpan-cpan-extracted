package Browser::OIDC;

use 5.020;
use warnings;
use experimental qw/signatures postderef lexical_subs/;

use Browser::Open 'open_browser';
use Carp;
use Digest::SHA 'sha256';
use Crypt::SysRandom 0.008 'random_base64url';
use HTML::Entities 'encode_entities';
use HTTP::Daemon;
use HTTP::Headers;
use HTTP::Response;
use HTTP::Tiny;
use JSON::MaybeXS;
use List::Util 1.33 qw/first none/;
use MIME::Base64 qw/encode_base64 encode_base64url decode_base64url/;
use URI;
use URI::Escape 'uri_escape_utf8';

use Browser::OIDC::TokenResponse;

our $VERSION = '0.003';

my $tiny = HTTP::Tiny->new(verify_SSL => 1);

my sub validate_url($name, $url) {
	croak "$name is undefined" unless defined $url;
	my $uri = URI->new($url);
	croak "Invalid URL for $name" unless ($uri->scheme // '') eq 'https' && length $uri->host;
}

sub new_from_discovery($class, $target_base) {
	validate_url('target_base', $target_base);
	my $response = $tiny->get("$target_base/.well-known/openid-configuration");
	croak "Error: $response->{status}" if $response->{status} != 200;
	my $config = decode_json($response->{content});
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
		tiny         => $tiny,
	}, $class;
}

my sub form_escape($input) {
	return uri_escape_utf8($input) =~ s/%20/+/gr;
}

my sub term_escape($input) {
	return $input =~ s/[[:cntrl:]]//gr;
}

sub get_token($self, %options) {
	my $client_id = $options{client_id} // croak 'No client id given';

	my $daemon = HTTP::Daemon->new(LocalAddr => 'localhost', Timeout => $options{timeout} // 60);
	my $port = $daemon->sockport;
	my $redirect_uri = "http://localhost:$port/auth/callback";
	my $full_target = URI->new($self->{authorization_endpoint});
	$full_target->query_param_append(response_type => 'code');
	$full_target->query_param_append(redirect_uri => $redirect_uri);
	$full_target->query_param_append(client_id => $client_id);
	my $code_verifier = random_base64url(32);
	$full_target->query_param_append(code_challenge => encode_base64url(sha256($code_verifier)));
	$full_target->query_param_append(code_challenge_method => 'S256');
	my @scope = 'openid';
	push @scope, $options{scope}->@*  if $options{scope};
	$full_target->query_param_append(scope => join ' ', @scope);
	my $state = random_base64url(16);
	$full_target->query_param_append(state => $state);
	my $nonce = exists $options{nonce} ? $options{nonce} : random_base64url(32);
	$full_target->query_param_append(nonce => $nonce) if defined $nonce;
	for my $name (qw/display max_age/) {
		if (defined $options{$name}) {
			$full_target->query_param_append($name => $options{$name});
		}
	}
	if ($options{prompt}) {
		$full_target->query_param_append(prompt => join ' ', $options{prompt}->@*);
	}

	my $url = $full_target->canonical;
	my $ok = open_browser($url);
	say "Could not open browser: please open $url manually" if not defined $ok or $ok != 0;
	while (1) {
		my $sock = $daemon->accept or croak "Could not accept connection: $!";
		my $request = $sock->get_request or croak "Could not receive request";

		if ($request->uri->path eq '/auth/callback') {
			my $received_state = $request->uri->query_param('state');
			if ($received_state ne $state) {
				$sock->send_error(400, 'Invalid state');
				next;
			}

			if (my $error = $request->uri->query_param('error')) {
				my $message = $request->uri->query_param('error_description') // $error;
				$sock->send_error(400, encode_entities($message));
				croak term_escape($message);
			}

			my $code = $request->uri->query_param('code');
			if (not defined $code) {
				$sock->send_error(400, 'Missing code');
				croak 'Missing code';
			}

			if ($self->{response_iss} and $request->uri->query_param('iss') ne $self->{issuer}) {
				$sock->send_error(400, 'Incorrect issuer');
				croak 'Incorrect issuer';
			}

			my $message = $options{message} // 'Authorization token received, you can close this now';
			my $headers = HTTP::Headers->new;
			$headers->header('content-type', $options{message_type}) if $options{message_type};
			$sock->send_response(HTTP::Response->new(200, 'OK', $headers, $message));
			close $sock;

			my %arguments = (
				grant_type    => 'authorization_code',
				redirect_uri  => $redirect_uri,
				code          => $code,
				code_verifier => $code_verifier,
			);
			my %headers;
			my $client_secret = $options{client_secret} // '';
			if ($self->{auth_method} eq 'client_secret_post') {
				$arguments{client_id} = $client_id;
				$arguments{client_secret} = $client_secret;
			}
			elsif ($self->{auth_method} eq 'client_secret_post') {
				my $auth = join ':', form_escape($client_id), form_escape($client_secret);
				$headers{Authorization} = 'Basic ' . encode_base64($auth, '');
			}
			my $response = $tiny->post_form($self->{token_endpoint}, \%arguments, { headers => \%headers });
			if ($response->{status} == 200) {
				my $value = decode_json($response->{content});
				return Browser::OIDC::TokenResponse->new(parent => $self, value => $value, nonce => $nonce);
			} else {
				croak "Could not get token ($response->{status}): " , term_escape($response->{content});
			}
		} else {
			$sock->send_error(404);
			close $sock;
		}
	}
}

sub issuer($self) {
	return $self->{issuer};
}

sub claims_supported($self) {
	return $self->{claims_supported}->@*;
}

sub scopes_supported($self) {
	return $self->{scopes_supported}->@*;
}

sub jwks($self) {
	my $response = $tiny->get($self->{jwks_uri});
	croak "Could not fetch JSON Web Key Set" if $response->{status} != 200;
	return decode_json($response->{content});
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

This returns a JSON Web Key Set as a hash, with keys as a arrayref of JWK entries.

=head1 TODO

Open ID Connect and OAuth2 are large standards, so far only a tiny fraction is implemented here. Feel free to request specific features if you need them. Patches are welcome.

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
