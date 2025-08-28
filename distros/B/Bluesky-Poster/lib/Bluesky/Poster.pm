package Bluesky::Poster;

use strict;
use warnings;

use Carp;
use LWP::UserAgent;
use JSON::MaybeXS qw(encode_json decode_json);
use Object::Configure;
use Params::Validate::Strict;
use Params::Get;
use URI;

=head1 NAME

Bluesky::Poster - Simple interface for posting to Bluesky (AT Protocol)

=head1 SYNOPSIS

  use Bluesky::Poster;

  my $poster = Bluesky::Poster->new(
	  identifier	 => 'your-identifier.bsky.social',
	  password => 'abcd-efgh-ijkl-mnop',
  );

  my $result = $poster->post("Hello from Perl!");
  print "Post URI: $result->{uri}\n";

=head1 DESCRIPTION

I've all but given up with X/Twitter.
It's API is overly complex and no longer freely available,
so I'm trying Bluesky.

This module authenticates with Bluesky using app passwords and posts text
messages using the AT Protocol API.

=head1 METHODS

=head2 new(identifier => ..., password => ...)

Constructs a new poster object and logs in.
The indentifier and password can also be read in from a configuration file,
as per L<Object::Configure>.

=cut

our $VERSION = '0.02';

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;

	# Allow the identified and password to be read from a file
        my $params = Params::Validate::Strict::validate_strict({
		args => Object::Configure::configure($class, Params::Get::get_params(undef, @_ ? \@_ : undef)),
		schema => {
			# letters, numbers and full stops
			'identifier' => { type => 'string', 'min' => 2, matches => qr/^[a-zA-Z0-9.]+$/i },
			# 16 character hex 4-4-4-4
			'password' => { type => 'string', 'min' => 19, 'max' => 19, matches => qr/^[a-z0-9]{4}(?:\-[a-z0-9]{4}){3}$/ },
			'logger' => {},
			'config_path' => {}
		}
	});

	for my $required (qw(identifier password)) {
		if(!defined($params->{$required})) {
			if(my $logger = $params->{'logger'}) {
				$logger->error("Missing required parameter: $required");
			}
			croak "Missing required parameter: $required"
		}
	}

	my $self = {
		%{$params},
		agent	=> LWP::UserAgent->new,
		json => JSON::MaybeXS->new()->utf8->canonical,
		session	=> undef,
	};

	bless $self, $class;

	$self->_login();

	return $self;
}

sub _login {
	my $self = shift;

	my $ua = $self->{agent};

	my $res = $ua->post(
		'https://bsky.social/xrpc/com.atproto.server.createSession',
		'Content-Type' => 'application/json',
		Content => $self->{json}->encode({
			identifier => $self->{identifier},
			password => $self->{password},
		}),
	);

	unless ($res->is_success) {
		if(my $logger = $self->{'logger'}) {
			$logger->error('Login failed: ', $res->status_line, "\n", $res->decoded_content());
		}
		croak('Login failed: ', $res->status_line, "\n", $res->decoded_content());
	}

	$self->{session} = $self->{json}->decode($res->decoded_content);
}

=head2 post($text)

Posts the given text to your Bluesky feed.

=cut

sub post {
	my $self = shift;
	my $params = Params::Get::get_params('text', @_);
	my $text = $params->{'text'};

	if(!defined($text)) {
		if(my $logger = $self->{'logger'}) {
			$logger->error('Text is required');
		}
		croak 'Text is required';
	}

	my $iso_timestamp = _iso8601(time());

	my $payload = {
		repo => $self->{session}{did},
		collection => 'app.bsky.feed.post',
		record => {
			'$type' => 'app.bsky.feed.post',
			text => $text,
			createdAt => $iso_timestamp,
		},
	};

	my $res = $self->{agent}->post(
		'https://bsky.social/xrpc/com.atproto.repo.createRecord',
		'Content-Type' => 'application/json',
		'Authorization' => 'Bearer ' . $self->{session}{accessJwt},
		Content => $self->{json}->encode($payload),
	);

	unless ($res->is_success) {
		if(my $logger = $self->{'logger'}) {
			$logger->error('Post failed: ' . $res->status_line . "\n" . $res->decoded_content());
		}
		croak('Post failed: ', $res->status_line, "\n", $res->decoded_content());
	}

	return $self->{json}->decode($res->decoded_content);
}

sub _iso8601 {
	my $t = $_[0];
	my @gmt = gmtime($t);

	return sprintf(
		"%04d-%02d-%02dT%02d:%02d:%02dZ",
		$gmt[5]+1900, $gmt[4]+1, $gmt[3],
		$gmt[2], $gmt[1], $gmt[0],
	);
}

1;

=head1 AUTHOR

Nigel Horne, with some help from ChatGPT

=head1 SUPPORT

This module is provided as-is without any warranty.

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

__END__
