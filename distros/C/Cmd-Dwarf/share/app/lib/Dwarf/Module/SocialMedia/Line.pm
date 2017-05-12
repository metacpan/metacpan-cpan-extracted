package Dwarf::Module::SocialMedia::Line;
use Dwarf::Pragma;
use parent 'Dwarf::Module';
use Dwarf::HTTP::Async;
use DateTime;
use DateTime::Format::HTTP;
use HTTP::Request::Common ();
use JSON;
use LWP::UserAgent;
use Data::Dumper;

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
		api           => 'https://api.line.me/v1',
		authorization => 'https://access.line.me/dialog/oauth/weblogin',
		access_token  => 'https://api.line.me/v1/oauth/accessToken',
	};

	$self->{on_error} ||= sub { die @_ };
}

sub authorized {
	my ($self, $will_die) = @_;
	$will_die ||= 1;
	my $authorized = defined $self->access_token;
	if ($will_die && !$authorized) {
		$self->on_error("Unauthorized");
	}
	return $authorized;
}

sub show_user {
	my $self = shift;

	die 'access token must be specified.' unless defined $self->access_token;

	return $self->call('profile', 'GET');
}

sub get_authorization_url {
	my ($self, %params) = @_;

	die 'key must be specified.' unless defined $self->key;
	die 'secret must be specified.' unless defined $self->secret;
	die "redirect_uri must be specified." unless defined $params{redirect_uri};

	$params{response_type}  = "code";
	$params{client_id}    ||= $self->key;
	# [todo] 
	# 	add state parameters. 
	# 	https://developers.line.me/web-login/integrating-web-login#guidance_to_login_screen

	my $uri = URI->new($self->urls->{authorization});
	$uri->query_form(%params);
	return $uri;
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
		$self->on_error->('Line OAuth Error: Could not get access token.');
		return;
	}

	my $decoded = decode_json $res->{_content};
	my $access_token = $decoded->{access_token};

	$self->access_token($access_token);
}

sub _make_request {
	my ($self, $command, $method, $params) = @_;

	$method = uc $method;

	my $uri = URI->new($self->urls->{api} . '/' . $command);
	$uri->query_form(%{ $params }) if $method =~ /^(GET|DELETE)$/;

	my %data = %{ $params };

	if ($method eq 'MULTIPART_POST') {
		$method = 'POST';
		my $source = $params->{source};
		delete $params->{source};
		$uri->query_form(%{ $params });
		%data = (
			Content_Type => 'multipart/form-data',
			Content      => [ source => $source ],
		);
	} elsif ($method eq 'POST') {
		%data = (Content => $params)
	}

	no strict 'refs';
	my $req = &{"HTTP::Request::Common::$method"}($uri, %data);
	$req->header("Content-Length", 0) if $method eq 'DELETE';
	$req->header(Authorization => "Bearer " . $self->access_token);

	return $req;
}

sub call {
	my ($self, $command, $method, $params) = @_;
	$self->authorized;
	my $req = $self->_make_request($command, $method, $params);
	my $res = $self->ua->request($req);
	return $self->validate($res);
}

sub validate {
	my ($self, $res) = @_;
	my $content = eval { decode_json($res->decoded_content) };
	if ($@) {
		warn "Couldn't decode JSON: $@";
		$content = $res->decoded_content;
	}

	# [todo] 
	# 	check error status codes

	return $content;
}

1;
