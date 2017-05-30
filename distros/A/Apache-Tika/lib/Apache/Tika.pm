use strict;
use warnings;

package Apache::Tika;

use Encode qw/decode_utf8/;
use LWP::UserAgent;
use JSON::MaybeXS();

our $VERSION = '0.07';

sub new {
	my ($this, %pars) = @_;

	my $self = bless {}, $this;
	$self->{ua} = $pars{ua} // LWP::UserAgent->new();
	$self->{url} = $pars{url} // 'http://localhost:9998';
	$self->{json} = JSON::MaybeXS->new();

	return $self;
}

sub _request {
	my ($self, $method, $path, $headers, $bodyBytes) = @_;

	# Perform request
	my $response = $self->{ua}->$method(
		$self->{url} . '/' . $path,
		%$headers,
		Content => $bodyBytes
	);

	# Check for errors
	# TODO

	return decode_utf8($response->decoded_content(charset => 'none'));
}

sub meta {
	my ($self, $bytes, $contentType) = @_;
	my $meta = $self->_request(
		'put',
		'meta',
		{
			'Accept' => 'application/json',
			$contentType? ('Content-type' => $contentType) : ()
		},
		$bytes
	);

	return $self->{json}->decode($meta);
}

sub rmeta {
	my ($self, $bytes, $contentType, $format) = @_;
	my $meta = $self->_request(
		'put',
		'rmeta' . ($format? "/$format" : ''),
		{
			'Accept' => 'application/json',
			$contentType? ('Content-type' => $contentType) : ()
		},
		$bytes
	);

	return $self->{json}->decode($meta);
}

sub tika {
	my ($self, $bytes, $contentType) = @_;
	return $self->_request(
		'put',
		'tika',
		{
			'Accept' => 'text/plain',
			$contentType? ('Content-type' => $contentType) : ()
		},
		$bytes
	);
}

sub detect_stream {
	my ($self, $bytes) = @_;
	return $self->_request(
		'put',
		'detect/stream',
		{'Accept' => 'text/plain'},
		$bytes
	);
}

sub language_stream {
	my ($self, $bytes) = @_;
	return $self->_request(
		'put',
		'language/stream',
		{'Accept' => 'text/plain'},
		$bytes
	);
}

1;
