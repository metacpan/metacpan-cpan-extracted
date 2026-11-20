package Browser::OAuth2;

use 5.020;
use warnings;
use experimental qw/signatures postderef lexical_subs/;

use Browser::Open 'open_browser';
use Carp;
use Digest::SHA 'sha256';
use MIME::Base64 qw/encode_base64 encode_base64url/;
use Mojo::Server::Daemon;
use Mojo::URL;
use Mojo::UserAgent;
use Mojo::Util qw/encode random_bytes url_escape xml_escape/;

my $ua = Mojo::UserAgent->new;

sub new($class, %options) {
	my $client_id = $options{client_id} // croak 'No client id given';
    return bless {
        %options{'client_id', 'client_secret'},
        auth_method => $options{auth_method} // 'client_secret_basic',
    }, $class;
}

my sub form_escape($input) {
	return url_escape(encode('UTF-8', $input))  =~ s/%20/+/gr;
}

my sub term_escape($input) {
	return $input =~ s/[[:cntrl:]]//gr;
}

sub get_authorization($self, $authorization_endpoint, %options) {
	my $state = encode_base64url(random_bytes(16));

	my $ioloop = Mojo::IOLoop->new;
	my $daemon = Mojo::Server::Daemon->new(ioloop => $ioloop, listen => ['http://localhost:0'], silent => 1);
	my ($code, $exception);
	$daemon->on(request => sub ($daemon, $tx) {
		my $request = $tx->req;
		my $parameters = $request->method eq 'POST' ? Mojo::Parameters->new($request->body) : $request->url->query;

		if ($request->url->path eq '/auth/callback') {
			my $received_state = $parameters->param('state');
			if ($received_state ne $state) {
				$tx->res->code(400);
				$tx->res->body('Invalid state');
				$tx->resume;
			} elsif (defined $options{response_iss} and $parameters->param('iss') ne $options{response_iss}) {
				$tx->res->code(400);
				$tx->res->body('Incorrect issuer');
				$tx->resume;
			} elsif (my $error = $parameters->param('error')) {
				my $message = $parameters->param('error_description') // $error;
				$tx->res->code(400);
				$tx->res->body(xml_escape($message));
				$exception = term_escape($message);
				$tx->on(finish => sub { $ioloop->stop });
				$tx->resume;
			} elsif (defined($code = $parameters->param('code'))) {
				$tx->res->code(200);
				$tx->res->headers->content_type($options{message_type}) if $options{message_type};
				$tx->res->body($options{message} // 'Authorization token received, you can close this now');
				$tx->on(finish => sub { $ioloop->stop });
				$tx->resume;
			} else {
				$tx->res->code(400);
				$tx->res->body('Missing code');
				$tx->resume;
				return;
			}
		} else {
			$tx->res->code(400);
			$tx->resume;
		}
	});
	$daemon->start;

	my ($port) = $daemon->ports->@*;
	my $redirect_uri = "http://localhost:$port/auth/callback";
	my $full_target = Mojo::URL->new($authorization_endpoint);
	$full_target->query->append(response_type => 'code');
	$full_target->query->append(redirect_uri => $redirect_uri);
	$full_target->query->append(client_id => $self->{client_id});
	my $code_verifier = encode_base64url(random_bytes(32));
	$full_target->query->append(code_challenge => encode_base64url(sha256($code_verifier)));
	$full_target->query->append(code_challenge_method => 'S256');
	$full_target->query->append(state => $state);
	for my $name (qw/response_mode nonce display max_age/) {
		$full_target->query->append($name => $options{$name}) if defined $options{$name};
	}
	for my $name (qw/scope prompt/) {
		$full_target->query->append($name => join ' ', $options{$name}->@*) if defined $options{$name};
	}

	my $timeout = $options{timeout} // 60;
	my $timer = $ioloop->timer($timeout, sub {
		$exception = 'Timeout';
		$ioloop->stop;
	});

	my $ok = open_browser($full_target);
	say "Could not open browser: please open $full_target manually" if not defined $ok or $ok != 0;

	$ioloop->start;
	$ioloop->remove($timer);
	croak $exception if $exception;
	croak 'No authorization code received' unless defined $code;

    return {
		grant_type    => 'authorization_code',
        code          => $code,
        code_verifier => $code_verifier,
        redirect_uri  => $redirect_uri,
    }
}

sub get_token($self, $token_endpoint, %payload) {
	my %headers;
	if ($self->{auth_method} eq 'client_secret_post') {
		$payload{client_id} = $self->{client_id};
		$payload{client_secret} = $self->{client_secret};
	} elsif ($self->{auth_method} eq 'client_secret_basic') {
		my $auth = join ':', form_escape($self->{client_id}), form_escape($self->{client_secret});
		$headers{Authorization} = 'Basic ' . encode_base64($auth, '');
	} else {
		$payload{client_id} = $self->{client_id};
	}
	my $response = $ua->post($token_endpoint, \%headers, form => \%payload)->result;
	if ($response->is_success) {
		return $response->json;
	} else {
		croak sprintf "Could not get token (%s): %s", $response->code , term_escape($response->body);
	}
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Browser::OAuth - Get an OIDC token for a CLI application

=head1 SYNOPSIS

 my $oidc = Browser::OAuth2->new(client_id => 'application');
 my $token = $oidc->get_token(
	 scope     => [ 'email' ],
 );

=head1 DESCRIPTION

This module will open a browser for you to log into some OIDC provider, and will temporarily run a webserver on localhost to receive the redirect with the results from your browser.

=head1 METHODS

=head2 new

 my $oauth2 = Browser::OAuth2->new(client_id => '...');

=over 4

=item client_id

The client identifier, this argument is mandatory.

=item client_secret

The client secret. This argument is optional.

=item auth_method

The client authentication method. This defaults to C<client_secret_basic>.

=back

=head2 get_authorization

=head2 get_token
