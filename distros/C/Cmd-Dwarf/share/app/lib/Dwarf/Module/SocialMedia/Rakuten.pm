package Dwarf::Module::SocialMedia::Rakuten;
use Dwarf::Pragma;
use parent 'Dwarf::Module';
use Dwarf::HTTP::Async;
use HTTP::Request::Common ();
use JSON;
use LWP::UserAgent;
use MIME::Base64 qw/decode_base64 encode_base64url/;
use Dwarf::Util qw/safe_decode_json encode_utf8/;
use Digest::SHA qw/hmac_sha256_base64/;
use URI::Escape;

use Dwarf::Accessor qw/
	ua urls
	key secret
	access_token
	user_id name profile_image
	on_error
/;

sub init {
	my $self = shift;

	$self->{ua}       ||= LWP::UserAgent->new;

	$self->{urls} ||= {
		api           => 'https://app.rakuten.co.jp/engine/api/MemberInformation/GetOpenIdUserInfo/20160715',
		access_token  => 'https://app.rakuten.co.jp/engine/idtoken',
	};

	$self->{on_error} ||= sub { die @_ };
}

sub show_user {
	my $self = shift;

	die 'access token must be specified.' unless defined $self->access_token;

	my $params = {};
	$params->{access_token} = $self->access_token;

	my $uri = URI->new($self->urls->{api});
	$uri->query_form(%$params);

	my $res = $self->ua->post($uri);

	my $content = eval { safe_decode_json(encode_utf8 $res->decoded_content) };
	if ($@) {
		warn "Couldn't decode JSON: $@";
		$content = $res->decoded_content;
	}

	return $content;
}

sub request_access_token {
	my ($self, %params) = @_;

	die 'key must be specified.' unless defined $self->key;
	die 'secret must be specified.' unless defined $self->secret;
	die "redirect_uri must be specified." unless defined $params{redirect_uri};
	die "code must be specified." unless defined $params{code};

	$params{grant_type}      = "authorization_code";
	$params{client_id}     ||= $self->key;
	$params{client_secret} ||= $self->secret;

	my $uri = URI->new($self->urls->{access_token});
	$uri->query_form(%params);

	my $res = $self->ua->post($uri);

	if ($res->code !~ /^2/) {
		$self->on_error->('Rakuten OAuth Error: Could not get access token.');
		return;
	}

	my $content = eval { decode_json $res->decoded_content };
	if ($@) {
		warn "Couldn't decode JSON: $@";
		$content = $res->decoded_content;
	}

	$self->_validate_id_token($content->{id_token});

	my $access_token = $content->{access_token};

	$self->access_token($access_token);
}

sub _validate_id_token {
	my ($self, $id_token) = @_;

	my ($header, $payload, $signature) = split /\./, $id_token;

	my $alg = eval { decode_json(decode_base64 $header)->{alg} };
	die "Something wrong with JWT header. " if $@;

	my $data = eval { decode_json(decode_base64 $payload) };
	die "Something wrong with JWT payload." if $@;

	my $valid_signature;
	if ($alg eq "HS256") {
		$valid_signature = hmac_sha256_base64($header . "." . $payload, $self->secret);
		while (length($valid_signature) % 4) {
			$valid_signature .= "=";
		}

		# hmac_sha256 -> base64url encode のやり方が分からないので一旦これで...
		$valid_signature = encode_base64url decode_base64 $valid_signature;
	}

	die "Something wrong with JWT header. Couldn't specify hash algorythm." unless $valid_signature;
	die "Invalid signature." unless $signature eq $valid_signature;

	die "Wrong value: payload.iss" unless $data->{iss} && $data->{iss} eq "https://app.rakuten.co.jp/";
	die "Wrong value: payload.aud" unless $data->{aud} && $data->{aud} eq $self->key;

	die "Wrong value: payload.exp" unless $data->{exp} && $data->{exp} > time();
	die "Wrong value: payload.iat" unless $data->{iat} && $data->{iat} <= time() && time() <= ($data->{iat} + 300);
}

1;
