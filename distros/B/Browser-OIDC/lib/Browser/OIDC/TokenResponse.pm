package Browser::OIDC::TokenResponse;

use 5.020;
use warnings;
use experimental qw/signatures postderef lexical_subs/;

use MIME::Base64 'decode_base64';

our $VERSION = '0.002';

sub new($class, %options) {
	return bless {
		parent => $options{parent},
		value  => $options{value},
	}, $class;
}

for my $name (qw/id_token access_token expires_in token_type/) {
	my $sub = sub($self) { return $self->{value}{$name} };
	no strict 'refs';
	*$name = $sub;
}

1;

=head1 SYNOPSIS

 my $oidc = Browser::OIDC->new($url);
 my $token_response = $oidc->get_token(%args);
 my $id_token = $token_response->id_token;

=head1 DESCRIPTION

This represents a token as returned by C<Browser::OIDC->get_token>. It should always contain an ID token, and usually an access token as well.

=head1 METHODS

=head2 id_token

This returns the raw ID token. This should be JWT formatted and is not validated.

=head2 access_token

This returns the raw access token.

=head2 expires_in

The amount of time from fetching until the access token expires, in seconds.

=head2 token_type

The type of the token. This will usually be C<'bearer'>.
