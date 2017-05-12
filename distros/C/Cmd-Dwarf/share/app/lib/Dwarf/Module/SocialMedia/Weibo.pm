package Dwarf::Module::SocialMedia::Weibo;
use Dwarf::Pragma;
use parent 'Dwarf::Module';
use Dwarf::HTTP::Async;
use DateTime;
use DateTime::Format::HTTP;
use HTTP::Request::Common ();
use JSON;
use LWP::UserAgent;

use Dwarf::Accessor qw/
	ua ua_async urls
	key secret
	access_token access_token_secret expires_in
	user_id screen_name name profile_image
	on_error
/;

sub init {
	my $self = shift;

	$self->{ua}       ||= LWP::UserAgent->new;
	$self->{ua_async} ||= Dwarf::HTTP::Async->new;

	$self->{urls} ||= {
		api           => 'https://api.weibo.com/2',
		authorization => 'https://api.weibo.com/oauth2/authorize',
		access_token  => 'https://api.weibo.com/oauth2/access_token',
	};

	$self->{on_error} ||= sub { die @_ };
}

sub _build_screen_name {
	my $self = shift;
	$self->init_user;
	return $self->{screen_name};
}

sub _build_name {
	my $self = shift;
	$self->init_user;
	return $self->{name};
}

sub _build_profile_image {
	my $self = shift;
	$self->init_user;
	return $self->{profile_image};
}

sub init_user {
	my $self = shift;
	my $user = $self->show_user;
	$self->{screen_name}   = $user->{screen_name};
	$self->{name}          = $user->{name};
	$self->{profile_image} = $user->{profile_image_url};
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
	$check_connection //= 1;

	return 0 unless $self->authorized(0);
	return 1 unless $check_connection;

	my $data = eval {
		$self->call(
			'account/get_uid',
			'GET'
		)
	};

	my $is_login = 0;

	if (ref $data eq 'HASH') {
		$is_login = 1;
		$self->user_id($data->{uid});
	}

	return $is_login;
}

sub publish {
	my ($self, $message) = @_;
	$self->call('statuses/update', 'POST', { status => $message });
}

sub reply {
	my ($self, $in_reply_to_status_id, $message, $screen_name) = @_;
	$message = "@" . $screen_name . " " . $message if defined $screen_name;
	$self->call('statuses/update', 'POST', {
		status                => $message,
		in_reply_to_status_id => $in_reply_to_status_id,
	});
}

sub upload {
	my ($self, $src, $message) = @_;
	my $data = {
		status => $message,
		pic    => [ $src ],
	};
	$self->call("statuses/upload", 'MULTIPART_POST', $data);
}

sub send_dm {
	my ($self, $id, $text) = @_;
	$self->call('direct_messages/new', 'POST', {
		user_id => $id,
		text    => $text,
	});
}

sub follow {
	my ($self, $target_screen_name) = @_;
	return $self->call('friendships/create', 'POST', {
		screen_name => $target_screen_name
	});
}

sub is_following {
	my ($self, $target_screen_name) = @_;
	my $data = $self->call('friendships/show', 'GET', {
		source_id          => $self->user_id,
		target_screen_name => $target_screen_name,
	});
	return $data->{source}->{following} ? 1 : 0;
}

sub get_rate_limit_status {
	my ($self) = @_;
	return $self->call('account/rate_limit_status', 'GET');
}

sub show_user {
	my ($self, $id) = @_;
	$id ||= $self->user_id;
	return $self->call('users/show', 'GET', { uid => $id });
}

sub get_timeline {
	my ($self, $id, $data) = @_;
	$id ||= $self->user_id;
	$data ||= {};
	$data->{uid} = $id;
	my $res = $self->call('statuses/user_timeline', 'GET', $data);
	if (ref $res eq 'HASH') {
		return $res->{statuses};
	}
	return [];
}

sub get_mentions {
	my ($self, $id, $data) = @_;
	$id ||= $self->user_id;
	$data ||= {};
	$data->{uid} = $id;
	my $res = $self->call('statuses/mentions', 'GET', $data);
	if (ref $res eq 'HASH') {
		return $res->{statuses};
	}
	return [];
}

sub get_direct_messages {
	my ($self, $id) = @_;
	$id ||= $self->user_id;
	die "This method has not implemented yet.";
	return;
}

sub get_friends_ids {
	my ($self, $id) = @_;
	$id ||= $self->user_id;

	my $cursor = -1;
	my @ids;

	while ($cursor != 0) {
		my $result = $self->call('friendships/friends/ids', 'GET', {
			uid    => $id,
			cursor => $cursor,
		});

		$cursor = $result->{next_cursor};
		push @ids, @{ $result->{ids} };
	}

	return \@ids;
}

sub get_followers_ids {
	my $self = shift;
	die "This method has not implemented yet.";
	return;
}

sub lookup_users {
	my ($self, $ids, $rows, $offset) = @_;
	$offset ||= 0;
	die "This method has not implemented yet.";
	return;
}

sub get_authorization_url {
	my ($self, %params) = @_;

	die 'key must be specified.' unless defined $self->key;
	die 'secret must be specified.' unless defined $self->secret;
	die "redirect_uri must be specified." unless defined $params{redirect_uri};

	$params{client_id}     ||= $self->key;
	$params{response_type} ||= 'code';

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

	$params{client_id}     ||= $self->key;
	$params{client_secret} ||= $self->secret;
	$params{grant_type}    ||= 'authorization_code';

	my $uri = URI->new($self->urls->{access_token});
	$uri->query_form(%params);

	my $res = $self->ua->post($uri);
	$self->validate($res);

	my $json = $res->content;
	my $data = eval { decode_json($json) };
	if ($@) {
		warn $data;
	}

	$self->access_token($data->{access_token});
	$self->expires_in($data->{expires_in});
}

sub _make_request {
	my ($self, $command, $method, $params) = @_;

	$method = uc $method;
	$params->{source}       ||= $self->key;
	$params->{access_token} ||= $self->access_token;

	my $uri = URI->new($self->urls->{'api'} . '/' . $command . '.json');
	$uri->query_form(%{ $params }) if $method =~ /^(GET|DELETE)$/;

	my %data = %{ $params };

	if ($method eq 'MULTIPART_POST') {
		$method = 'POST';
		%data = (
			Content_Type => 'multipart/form-data',
			Content      => [ %{ $params} ],
		);
	} elsif ($method eq 'POST') {
		%data = (Content => $params)
	}

	no strict 'refs';
	my $req = &{"HTTP::Request::Common::$method"}($uri, %data);
	$req->header("Content-Length", 0) if $method eq 'DELETE';

	return $req;
}

sub call {
	my ($self, $command, $method, $params) = @_;
	$self->authorized;
	my $req = $self->_make_request($command, $method, $params);
	my $res = $self->ua->request($req);
	return $self->validate($res);
}

sub call_async {
	my $self = shift;
	return if @_ == 0;

	$self->authorized;

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
	my $content = eval {
		my $ct = $res->content;
		$ct =~ s/0\r\n\r\n$//;
		decode_json($ct);
	};
	if ($@) {
		warn "Couldn't decode JSON: $@";
		$content = $res->content;
	}

	if ($res->code !~ /^2/) {
		if ($content) {
		 	if (ref $content) {
				if ($content->{error} =~ /rate limit/) {
					my $limit = $self->get_rate_limit_status;
					my $reset = DateTime
						->from_epoch(epoch => time + $limit->{reset_time_in_seconds})
						->set_time_zone('Asia/Tokyo');
					$self->on_error->($reset);
				}

				$self->on_error->($content->{error}, $content->{error_code});
			} else {
				$self->on_error->($content);
			}
		}

		$self->on_error->("Invalid Response Header");
	}

	return $content;
}

sub parse_date {
	my ($self, $value) = @_;
	$value =~ s/\+\d{4} //;
	return DateTime::Format::HTTP
		->parse_datetime($value)
		->add(hours => 1)
		->set_time_zone('Asia/Tokyo');
}

1;
