package Dwarf::Module::SocialMedia::Twitter;
use Dwarf::Pragma;
use parent 'Dwarf::Module';
use Dwarf::HTTP::Async;
use Data::Dumper;
use DateTime;
use DateTime::Format::HTTP;
use Digest::SHA qw//;
use Encode qw/encode_utf8/;
use HTTP::Request::Common;
use HTTP::Response;
use JSON;
use LWP::UserAgent;
use Net::OAuth;

use Dwarf::Accessor qw/
	ua ua_async urls
	key secret
	request_token request_token_secret
	access_token access_token_secret
	user_id screen_name name profile_image
	on_error
/;

$Net::OAuth::PROTOCOL_VERSION = Net::OAuth::PROTOCOL_VERSION_1_0A;

sub init {
	my $self = shift;
	my $c = $self->c;

	$self->{ua} ||= LWP::UserAgent->new(
		timeout => 120
	);

	$self->{ua_async} ||= Dwarf::HTTP::Async->new;

	$self->{urls} ||= {
		api            => 'https://api.twitter.com/1.1',
		request_token  => 'https://api.twitter.com/oauth/request_token',
		authentication => 'https://api.twitter.com/oauth/authenticate',
 		authorization  => 'https://api.twitter.com/oauth/authorize',
		access_token   => 'https://api.twitter.com/oauth/access_token',
	};

	$self->{on_error} ||= sub { die @_ };
}

sub _build_user_id {
	my $self = shift;
	$self->init_user unless defined $self->{user_id};
	return $self->{user_id};
}

sub _build_screen_name {
	my $self = shift;
	$self->init_user unless defined $self->{screen_name};
	return $self->{screen_name};
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

sub init_user {
	my $self = shift;
	my $user = $self->show_user;
	$self->{user_id}       = $user->{id};
	$self->{screen_name}   = $user->{screen_name};
	$self->{name}          = encode_utf8($user->{name});
	$self->{profile_image} = encode_utf8($user->{profile_image_url});
}

sub authorized {
	my ($self, $will_die) = @_;
	$will_die ||= 1;
	my $authorized = defined $self->access_token && defined $self->access_token_secret;
	if ($will_die && !$authorized) {
		$self->on_error("Unauthorized");
	}
	return $authorized;
}

sub is_login {
	my ($self, $check_connection) = @_;

	return 0 unless $self->authorized;
	return 1 unless $check_connection;

	my $data;
	eval {
		$data = $self->show_user;
	};
	if ($@) {
		warn $@;
	}

	my $is_login = 0;
	if (ref $data eq 'HASH') {
		$is_login = 1;
		$self->{user_id}       = $data->{id};
		$self->{screen_name}   = $data->{screen_name};
		$self->{name}          = encode_utf8($data->{name});
		$self->{profile_image} = encode_utf8($data->{profile_image_url});
	}

	return $is_login;
}

sub show_user {
	my ($self, $id) = @_;
	$id ||= $self->{user_id};

	my $data;
	unless ($self->{user_id}) {
		$data = $self->call(
			'account/verify_credentials',
			'GET'
		);
	} else {
		# accout/verify_credentials を節約するために
		# users/lookup で代替出来るケースでは代替する
		$data = $self->call('users/lookup', 'POST', { user_id => $id });
		if (ref $data eq 'ARRAY') {
			$data = $data->[0];
		}
	}

	return $data;
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

	my $url = $self->urls->{api} . '/statuses/update_with_media.json';

	my $oauth = Net::OAuth->request('protected resource')->new(
		version          => '1.0',
		request_url      => $url,
		request_method   => 'POST',
		token            => $self->access_token,
		token_secret     => $self->access_token_secret,
		consumer_key     => $self->key,
		consumer_secret  => $self->secret,
		signature_method => 'HMAC-SHA1',
		timestamp        => time,
		nonce            => Digest::SHA::sha1_base64(time . $$ . rand),
	);
	$oauth->sign;

	my $req = POST($url,
		Content_type  => 'multipart/form-data',
		Authorization => $oauth->to_authorization_header,
		Content       => [
			status    => $message,
			'media[]' => [ $src ]
		],
	);
	my $res = $self->ua->request($req);

	return $self->validate($res);
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
	return $data->{relationship}->{source}->{following} ? 1 : 0;
}

sub get_rate_limit_status {
	my ($self) = @_;
	return $self->call('account/rate_limit_status', 'GET');
}

sub get_timeline {
	my ($self, $id, $data) = @_;
	$id ||= $self->user_id;
	$data ||= {};
	$data->{uid} = $id;
	return $self->call('statuses/user_timeline', 'GET', $data);
}

sub get_mentions {
	my ($self, $id, $data) = @_;
	$id ||= $self->user_id;
	$data ||= {};
	$data->{uid} = $id;
	my $res = $self->call('statuses/mentions', 'GET', $data);
	return $res;
}

sub get_sent_messages {
	my ($self) = @_;
	return $self->call('direct_messages/sent', 'GET');
}

sub get_friends_ids {
	my ($self, $id) = @_;
	$id ||= $self->user_id;

	my $cursor = -1;
	my @ids = ();

	while ($cursor != 0) {
		my $result = $self->call('friends/ids', 'GET', {
			user_id => $id,
			cursor  => $cursor,
		});

		$cursor = $result->{next_cursor_str};
		push @ids, @{ $result->{ids} };
	}

	return \@ids;
}

sub get_followers_ids {
	my ($self, $id) = @_;
	$id ||= $self->user_id;

	my $cursor = -1;
	my @ids;

	while ($cursor != 0) {
		my $result = $self->call('followers/ids', 'GET', {
			user_id => $id,
			cursor  => $cursor,
		});

		$cursor = $result->{next_cursor_str};
		push @ids, @{ $result->{ids} };
	}

	return @ids;
}

sub lookup_users {
	my ($self, $ids, $rows, $offset) = @_;
	$offset ||= 0;

	my @ids = @$ids;
	@ids = grep { defined $_ } @ids[$offset .. $offset + $rows - 1];
	return () if @ids == 0;

	my $rpp = 100;
	my $len = int(@ids / $rpp);

	my $users;
	my @requests;

	for my $i (0 .. $len) {
		my @a = @ids;
		@a = grep { defined $_ } @a[$i * $rpp .. ($i + 1) * $rpp - 1];
		next if @a == 0;

		push @requests, [
			'users/lookup',
			'POST',
			{ user_id => join ',', @a }
		];
	}

	my @contents = $self->call_async(@requests);
	for my $content (@contents) {
		for my $user (@$content) {
			$users->{ $user->{id} } = $user;
		}
	}
	return map { $users->{$_} } grep { exists $users->{$_} } @ids;
}

sub make_oauth_request {
	my ($self, $type, %params) = @_;

	die 'key must be specified.' unless defined $self->key;
	die 'secret must be specified.' unless defined $self->secret;

	local $Net::OAuth::SKIP_UTF8_DOUBLE_ENCODE_CHECK = 1;

	my $req = Net::OAuth->request($type)->new(
		version          => '1.0',
		consumer_key     => $self->key,
		consumer_secret  => $self->secret,
		signature_method => 'HMAC-SHA1',
		timestamp        => time,
		nonce            => Digest::SHA::sha1_base64(time . $$ . rand),
		%params,
	);
	$req->sign;

	if ($req->request_method eq 'POST') {
		return POST $req->normalized_request_url, $req->to_hash;
	}

	return GET $req->to_url;
}

sub get_authorization_url {
	my ($self, %params) = @_;

	die "callback must be specified." unless defined $params{callback};

	$params{request_url}    ||= $self->urls->{request_token};
	$params{request_method} ||= 'GET';

	my $req = $self->make_oauth_request('request token', %params);
	my $res = $self->ua->request($req);

	# Twitter が落ちている
	if ($res->code =~ /^5/) {
		$self->on_error->('Twitter OAuth Error: Could not get authorization url.');
		return;
	}

	my $uri = URI->new;
	$uri->query($res->content);
	my %res_param = $uri->query_form;

	$self->request_token($res_param{oauth_token});
	$self->request_token_secret($res_param{oauth_token_secret});

	$uri = URI->new($self->urls->{authentication});
	$uri->query_form(oauth_token => $self->request_token);

	return $uri;
}

sub request_access_token {
	my ($self, %params) = @_;

	die "verifier must be specified." unless defined $params{verifier};

	$params{request_url}    ||= $self->urls->{access_token};
	$params{request_method} ||= 'GET';
	$params{token}          ||= $self->request_token;
	$params{token_secret}   ||= $self->request_token_secret;

	my $req = $self->make_oauth_request('access token', %params);
	my $res = $self->ua->request($req);

	# Twitter が落ちている
	if ($res->code !~ /^2/) {
		$self->on_error->('Twitter OAuth Error: Could not get access token.');
		return;
	}

	delete $self->{request_token};
	delete $self->{request_token_secret};

	my $uri = URI->new;
	$uri->query($res->content);
	my %res_param = $uri->query_form;

	$self->user_id($res_param{user_id});
	$self->screen_name($res_param{screen_name});
	$self->access_token($res_param{oauth_token});
	$self->access_token_secret($res_param{oauth_token_secret});
}

sub _make_request {
	my ($self, $command, $method, $params) = @_;
	my $req = $self->make_oauth_request(
		'protected resource',
		request_url    => $self->urls->{api} . '/' . $command . '.json',
		request_method => $method,
		extra_params   => $params,
		token          => $self->access_token,
		token_secret   => $self->access_token_secret
	);

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
	my $c = $self->c;

	my $content = eval { decode_json($res->content) };
	if ($@) {
		warn "Couldn't decode JSON: $@";
		warn $res->content;
		$content = $res->content;
	}

	my $hdr = $res->headers;
	my $code = $res->code;

	if ($c->config_name ne 'production' and defined $hdr->{"x-ratelimit-remaining"}) {
		warn "Ratelimit: " . $hdr->{"x-ratelimit-remaining"} . "/" . $hdr->{"x-ratelimit-limit"};
	}

	unless ($code =~ /^2/) {
		# 400 系
		if ($code =~ /^4/) {
			unless (ref $content) {
				warn Dumper $res;
				$content ||= $res->code;
				$self->on_error->('Twitter API Error: ' . $content);
				return;
			}

			my $error_code = $content->{errors}->[0]->{code} // '';
			#  89 = トークン切れ
			if ($error_code eq '89') {
				$self->on_error->('Twitter API Error: ' . $content->{errors}->[0]->{message});
				return;
			}
			#  64 = アカウント凍結
			elsif ($error_code eq '64') {
				$self->on_error->('Twitter API Error: ' . $content->{errors}->[0]->{message});
				return;
			}
			# 187 = 二重投稿
			elsif ($error_code eq '187') {
				warn "Twitter API Error: ", $content->{errors}->[0]->{message};
				return $content;
			}
			#  88 = Rate Limit オーバー
			elsif ($error_code eq '88') {
				$self->on_error->('Twitter API Error: ' . $content->{errors}->[0]->{message});
				return;
			}
		}
		# 500 系
		else {
			# LWP::UserAgent 内部エラー
			if ($hdr->{'client-warning'}) {
				# タイムアウト
				if ($content =~ /timeout/) {
					$self->on_error->('Twitter API Internal Error: Request Timeout.');
					return;
				}
			}
			else {
				my $error_code = $content->{errors}->[0]->{code} // '';
				#  130 = Over Capacity
				if ($error_code eq '130') {
					$self->on_error->('Twitter API Internal Error: ' . $content->{errors}->[0]->{message});
					return;
				}
				# 131 = Internal Error
				elsif ($error_code eq '131') {
					$self->on_error->('Twitter API Internal Error: ' . $content->{errors}->[0]->{message});
					return;
				}
			}

			use Data::Dumper;
			warn Dumper $res;

			$self->on_error->('Twitter API Unknown Error: ' . $res->content);
		}
	}

	return $content;
}

sub parse_date {
	my ($self, $value) = @_;
	$value =~ s/\+\d{4} //;
	return DateTime::Format::HTTP
		->parse_datetime($value)
		->add(hours => 9)
		->set_time_zone('Asia/Tokyo');
}

1;
