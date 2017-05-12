package Dwarf::Module::SocialMedia::Facebook;
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
	access_token access_token_secret
	user_id name profile_image
	on_error
/;

sub init {
	my $self = shift;

	$self->{ua}       ||= LWP::UserAgent->new;
	$self->{ua_async} ||= Dwarf::HTTP::Async->new;

	$self->{urls} ||= {
		api           => 'https://graph.facebook.com',
		old_api       => 'https://api.facebook.com',
		authorization => 'https://graph.facebook.com/oauth/authorize',
		access_token  => 'https://graph.facebook.com/oauth/access_token',
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

sub init_user {
	my $self = shift;
	$self->authorized;
	my $user = $self->show_user;
	$self->{user_id}       = $user->{uid};
	$self->{name}          = $user->{name};
	$self->{profile_image} = $user->{pic_square};
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

	my $user = $self->show_user;
	my $is_login = 0;

	# ARRAY 以外のフォーマットが返ってきた時はエラー
	if (ref $user eq 'HASH') {
		$is_login = 1;
		$self->{user_id}       = $user->{uid};
		$self->{name}          = $user->{name};
		$self->{profile_image} = $user->{pic_square};
	}

	return $is_login;
}

sub publish {
	my ($self, $message, %data) = @_;
	$data{message} = $message;
	$self->call('me/feed', 'POST', \%data);
}

sub reply {
	my ($self, $id, $message, %data) = @_;
	$data{message} = $message;
	$self->call("$id/feed", 'POST', \%data);
}

sub upload {
	my ($self, $src, $id, $message, %data) = @_;
	$id //= 'me';
	$data{source} = [ $src ],
	$data{message} = $message if defined $message;
	$self->call("$id/photos", 'MULTIPART_POST', \%data);
}

sub create_album {
	my ($self, $name, $message, %data) = @_;
	$data{name} = $name;
	$data{message} = $message;
	$self->call('me/albums', 'POST', \%data);
}

sub is_following {
	my ($self, $target_id) = @_;
	die 'target_id must be specified.' unless defined $target_id;

	my $like = 0;
	my $data = $self->call('me/likes', 'GET');

	for my $row (@{ $data->{data} }) {
		if ($row->{id} eq $self->target_id) {
			$like = 1;
		}
	}

	return $like;
}

sub show_user {
	my ($self, $id) = @_;
	$id ||= 'me()';

	my $data = eval { 
		$self->call(
			'method/fql.query',
			'GET',
			{ query => 'SELECT uid, name, pic_square FROM user WHERE uid = ' . $id }
		);
	};
	if ($@) {
		warn $@;
	}

	if (ref $data eq 'ARRAY' and @$data == 1) {
		return $data->[0];
	}
}

sub get_timeline {
	my ($self, $id) = @_;
	$id ||= 'me';
	my $res = $self->call("$id/posts", 'GET');
	return $res->{data};
}

sub get_mentions {
	my ($self, $id) = @_;
	$id ||= 'me';
	my $res = $self->call("$id/feed", 'GET');
	my $feed = $res->{data};
	my @mentions;
	for my $f (@{ $feed }) {
		push @mentions, $f
			if $f->{from}->{id} ne $self->user_id;
	}
	return \@mentions;
}

sub get_likes {
	my ($self, $id) = @_;
	$id ||= 'me';
	my $res = $self->call("$id/likes", 'GET');
	return $res->{data};
}

sub get_albums {
	my ($self, $id) = @_;
	$id ||= 'me';
	my $res = $self->call("$id/albums", 'GET');
	return $res->{data};
}

sub get_friends_ids {
	my ($self, $id) = @_;
	$id ||= $self->user_id;

	my $result = $self->call('method/fql.query', 'GET', {
		query => "SELECT uid2 FROM friend WHERE uid1 = me()"
	});
	$result = [] if ref $result ne 'ARRAY';

	return [ map { $_->{uid2} } @{ $result } ];
}

sub lookup_users {
	my ($self, $ids, $rows, $offset) = @_;
	$ids = join ',', @{ $ids };

	my $fql = "SELECT uid, name, pic_square FROM user WHERE uid IN";
	$fql .= " (" . $ids . ")";
	$fql .= " LIMIT $rows" if defined $rows;
	$fql .= " OFFSET $offset" if defined $offset;

	my $result = $self->call('method/fql.query', 'GET', { query => $fql });
	$result = [] if ref $result ne 'ARRAY';

	return @{ $result };
}

sub get_authorization_url {
	my ($self, %params) = @_;

	die 'key must be specified.' unless defined $self->key;
	die 'secret must be specified.' unless defined $self->secret;
	die "redirect_uri must be specified." unless defined $params{redirect_uri};

	$params{client_id} ||= $self->key;
	$params{scope}     ||= 'publish_stream,read_stream,user_photos,user_likes';

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

	my $uri = URI->new($self->urls->{access_token});
	$uri->query_form(%params);

	my $res = $self->ua->get($uri);

	if ($res->code !~ /^2/) {
		$self->on_error->('Facebook OAuth Error: Could not get access token.');
		return;
	}

	my $access_token = $res->decoded_content;
	$access_token =~ s/^access_token=//;
	$access_token =~ s/&expires=[0-9]+$//;

	$self->access_token($access_token);
}

sub _make_request {
	my ($self, $command, $method, $params) = @_;

	$method = uc $method;
	$params->{access_token} ||= $self->access_token;
	$params->{format}       ||= 'json';

	my $base_url = $command =~ /^method\//
			? $self->urls->{'old_api'}
			: $self->urls->{'api'};

	my $uri = URI->new($base_url . '/' . $command);
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
	my $content = eval { decode_json($res->decoded_content) };
	if ($@) {
		warn "Couldn't decode JSON: $@";
		$content = $res->decoded_content;
	}

	if ($res->code !~ /^2/) {
		if ($content) {
			if (ref $content) {
				my $error_code = $content->{error}->{code} // '';

				# 506 = 二重投稿
				if ($error_code eq '506') {
					warn 'Facebook API Error: ', $content->{error}->{message};
					return $content;
				}

				$self->on_error->($content->{error}->{message});
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
	return DateTime::Format::HTTP
		->parse_datetime($value)
		->set_time_zone('Asia/Tokyo');
}

1;
