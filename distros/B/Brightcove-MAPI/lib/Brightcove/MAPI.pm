package Brightcove::MAPI;

# ABSTRACT: Brightcove Media API Wrapper

our $VERSION = '0.1';

use URI;
use JSON;
use Any::Moose;
use LWP::UserAgent;

has read_api_url => (
	is	=> 'rw',
	required=> 1,
	default	=> 'https://api.brightcove.com/services/library',
);

has write_api_url => (
	is	=> 'rw',
	required=> 1,
	default	=> 'https://api.brightcove.com/services/post',
);

has token => (
	is	=> 'rw',
	required=> 1,
);

has user_agent => (
	is	=> 'ro',
	default	=> sub {
		my $self = shift;
		my $ua = LWP::UserAgent->new;
		$ua->agent(__PACKAGE__.'/'.$VERSION);
		return $ua;
	},
);


sub get {
	my $self = shift;
	my $command = shift;
	my $params = shift || {};

	$params->{command} = $command;
	$params->{token} = $self->token;

	my $url = URI->new($self->read_api_url);
	$url->query_form(%$params);
	my $res = $self->user_agent->get($url->as_string);

	if ($res->is_success) {
		return decode_json($res->decoded_content);
	} else {
		confess $res->status_line;
	}
}


sub post {
	my $self = shift;
	my $method = shift;
	my $params = shift || {};
	my $file = shift;

	$params->{token} = $self->token;

	my $jsonrpc = encode_json({
		method => $method,
		params => $params,
	});

	my $res;
	if (defined($file) and -f $file) {
		$res = $self->user_agent->post(
			$self->write_api_url,
			Content_Type => 'form-data',
			Content => [
				json => $jsonrpc,
				file => [ $file ]
			]
		);
	} else {
		$res = $self->user_agent->post(
			$self->write_api_url,
			Content => [ json => $jsonrpc ]
		);
	}

	if ($res->is_success) {
		my $content = $res->decoded_content;
		return decode_json($content);
	} else {
		confess $res->status_line;
	}
}

1;


__END__
=pod

=head1 NAME

Brightcove::MAPI - Brightcove Media API Wrapper

=head1 VERSION

version 0.1

=head1 SYNOPSIS

	use Brightcove::MAPI;

	my $mapi = Brightcove::MAPI->new(token => '..');

	my $read = $mapi->get(
		'search_videos', {
			page_size => 10,
		}
	);

	my $write = $mapi->post(
		'create_video', {
			video => {
				name => 'file name',
				shortDescription => 'short file description',
			}
		}, '/tmp/video.mp4'
	);

=head1 DESCRIPTION

This distribution provides a wrapper around the Brightcove Media API:

L<http://support.brightcove.com/en/docs/media-api-reference/>

=head1 METHODS

=head2 $mapi->get($mapi_method, \%params)

Wrapper for the read media api

=head2 $mapi->post($mapi_method, \%params)

Wrapper for the write media api

=head2 $mapi->post($mapi_method, \%params, $file_name)

Wrapper for the write media api with file upload

=head1 SEE ALSO

=head2 Brightcove Media API Reference 

L<http://docs.brightcove.com/en/media/>

=head2 Open Source @ Brightcove

L<http://opensource.brightcove.com/>

=head1 AUTHOR

Maroun NAJM <mnajm@cinemoz.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Cinemoz.

This is free software, licensed under:

  The (three-clause) BSD License

=cut

