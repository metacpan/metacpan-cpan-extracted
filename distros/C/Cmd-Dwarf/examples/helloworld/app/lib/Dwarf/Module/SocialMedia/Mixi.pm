package Dwarf::Module::SocialMedia::Mixi;
use Dwarf::Pragma;
use parent 'Dwarf::Module';
use Dwarf::HTTP::Async;
use Dwarf::Util qw/encode_utf8 decode_utf8 shuffle_array/;
use HTTP::Request::Common ();
use JSON;
use LWP::UserAgent;

use Dwarf::Accessor qw/
	ua ua_async urls
	key secret
	access_token refresh_token expires_in got_access_token_at
	user_id name profile_image friends
	on_error
/;

sub init {
	my $self = shift;

	$self->{ua}       ||= LWP::UserAgent->new;
	$self->{ua_async} ||= Dwarf::HTTP::Async->new;

	$self->{urls} ||= {
		api           => 'http://api.mixi-platform.com/2',
		authorization => 'https://mixi.jp/connect_authorize.pl',
		access_token  => 'https://secure.mixi-platform.com/2/token',
	};

	$self->{on_error} ||= sub { die @_ };
}

sub _build_name {
	my $self = shift;
	$self->init_user unless defined $self->{name};
	return $self->{name};
}

sub _build_profile_image {
	my $self = shift;
	$self->init_user unless defined $self->{profile_image};
	return $self->{profile_image};
}

sub _bulid_friends {
	my $self = shift;
	my $data = $self->call('people/@me/@friends', 'GET', { count => 1000 });
	return $data->{entry};
}

sub init_user {
	my $self = shift;
	$self->authorized;
	my $user = $self->show_user;
	$self->{name}          = encode_utf8($user->{displayName});
	$self->{profile_image} = encode_utf8($user->{thumbnailUrl});
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

sub is_login {
	my ($self, $check_connection) = @_;

	return 0 unless $self->authorized(0);
	return 1 unless $check_connection;

	my $data = eval { $self->call('people/@me/@self', 'GET') };

	my $is_login = 0;

	if (ref $data eq 'HASH') {
		$is_login = 1;
		$self->user_id($data->{entry}->{id});
		$self->name(encode_utf8($data->{entry}->{displayName}));
		$self->profile_image(encode_utf8($data->{entry}->{thumbnailUrl}));
	}

	return $is_login;
}

sub publish {
	my ($self, $message) = @_;
	$self->call('voice/statuses', 'POST', { status => $message });
}

sub send_dm {
	my ($self, $id, $title, $text) = @_;
	
	my $json = encode_json {
		title      => $title,
		body       => $text,
		recipients => [$id]
	};

	$self->call('messages/@me/@self/@outbox', 'POST', {}, $json);
}

sub is_following {
	my ($self, $target_id) = @_;
	die 'target_id must be specified.' unless defined $target_id;

	unless ($self->friends) {
		my $data = $self->call('people/@me/@friends', 'GET');
		$self->{friends} = $data->{entry};
	}
	
	my $like = 0;

	for my $row (@{ $self->friends }) {
		if ($row->{id} eq $target_id) {
			$like = 1;
		}
	}

	return $like;
}

sub show_user {
	my ($self, $id) = @_;
	my $data = $self->call('people/' . $id . '/@self', 'GET');
	if (ref $data eq 'HASH') {
		return $data->{entry};
	}
}

sub get_friends_ids {
	my $self = shift;
	return map { $_->{id} } $self->get_friends;
}

sub get_friends {
	my ($self, $rows, $offset) = @_;
	$offset ||= 0;
	my @a = @{ $self->friends };
	return @a unless defined $rows;
	return grep { defined $_ } @a[$offset .. $offset + $rows - 1];
}

sub get_authorization_url {
	my ($self, %params) = @_;

	die 'key must be specified.' unless defined $self->{key};
	die 'secret must be specified.' unless defined $self->{secret};

	$params{client_id}     ||= $self->key;
	$params{response_type} ||= 'code';
	$params{display}       ||= 'pc';
	$params{scope}         ||= 'r_profile';

	my $uri = URI->new($self->urls->{authorization});
	$uri->query_form(%params);
	return $uri;
}

sub request_access_token {
	my ($self, %params) = @_;

	die 'key must be specified.' unless defined $self->{key};
	die 'secret must be specified.' unless defined $self->{secret};
	die "grant_type must be specified." unless defined $params{grant_type};
	
	$params{client_id}     ||= $self->key;
	$params{client_secret} ||= $self->secret;

	my $now = time;

	my $res = $self->ua->post(
		$self->urls->{access_token},
		\%params
	);

	my $data = $self->validate($res);
	$self->access_token($data->{access_token});
	$self->refresh_token($data->{refresh_token});
	$self->expires_in($data->{expires_in});
	$self->got_access_token_at($now);
}

sub renew_access_token {
	my $self = shift;
	my $now = time;

	if (defined $self->expires_in and defined $self->got_access_token_at) {
		if ($now > $self->got_access_token_at + $self->expires_in) {
			$self->request_access_token(
				grant_type    => "refresh_token",
				refresh_token => $self->refresh_token,
			);
		}
	}
}

sub _make_request {
	my ($self, $command, $method, $params, $content) = @_;

	$method = uc $method;

	my $uri = URI->new($self->urls->{api} . '/' . $command);

	my @p;
	if ($method eq 'GET') {
		$uri->query_form(%{ $params });
		@p = ($uri, 'Authorization' => 'OAuth ' . $self->access_token);
	} else {
		@p = ($uri, $params, 'Authorization' => 'OAuth ' . $self->access_token);
		if (defined $content) {
			push @p, (
				'Content-Type' => 'application/json',
				'Content'      => $content
			);
		}
	}

	no strict 'refs';
	my $req = &{"HTTP::Request::Common::$method"}(@p);

	return $req;
}

sub call {
	my ($self, $command, $method, $params, $content) = @_;
	$self->authorized;
	$self->renew_access_token;
	my $req = $self->_make_request($command, $method, $params);
	my $res = $self->ua->request($req);
	return $self->validate($res);
}

sub call_async {
	my $self = shift;
	$self->authorized;
	$self->renew_access_token;

	my @requests;
	for my $row (@_) {
		push @requests, $self->_make_request(@{ $row });
	}

	my @responses = $self->ua_async->request_in_parallel(@requests);

	my @contents;
	for my $res (@responses) {
		push @contents, $self->validate($res);
	}

	return @contents;
}

sub validate {
	my ($self, $res) = @_;
	my $content = eval { decode_json($res->content) };
	if ($@) {
		$content = $res->content;
	}

	unless ($res->code =~ /^2/) {
		if (my $error = $res->header("www-authenticate")) {
			$self->on_error->($error);
		}
		$self->on_error->("Unknown Error.");
	}

	return $content;
}

1;
