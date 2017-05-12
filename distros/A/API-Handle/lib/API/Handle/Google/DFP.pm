package API::Handle::Google::DFP;
{
  $API::Handle::Google::DFP::VERSION = '0.02';
}
use Moose;
use namespace::autoclean;
use HTTP::Request;
use Carp;
use Data::Dumper;
use feature ':5.10';

with 'API::Handle';
has _config => (
	is => 'rw'
	, isa => 'Nour::Config'
	, handles => {
		  config => 'config'
		, merge_config => 'merge'
		, write_config => 'write'
	}
	, required => 1
	, lazy => 1
	, default => sub {
		my $self = shift;
		require Nour::Config;
		 return new Nour::Config (
			 -base => 'config/google/dfp'
		 );
	}
);

# This is where we configure how the user-agent transforms
# outgoing and incoming requests and responses.
# perldoc LWP::UserAgent.

around BUILD => sub {
	my ( $next, $self, @args, $prev ) = @_;

	# Put code that pre-empts API::Handle::BUILD before this $prev line.
	$prev = $self->$next( @args );
	# Put code that depends on API::Handle::BUILD after this $prev line.

	my $conf = $self->config;
	my $time = time;

	# Uncomment this to view loaded configuration.
	# $self->dumper( 'config', $conf );

	if ( $conf->{auth}{token}{access_token} and $conf->{auth}{token}{expires_at} and $conf->{auth}{token}{expires_at} > $time ) {
		$self->ua->default_header( 'Authorization' => "$conf->{auth}{token}{token_type} $conf->{auth}{token}{access_token}" );
	}
	elsif ( $conf->{auth}{token}{refresh_token} ) {
		my $req = new HTTP::Request;

		$req->headers->header( 'Content-Type' => 'application/x-www-form-urlencoded' );
		$req->method( 'POST' );
		$req->uri( $conf->{auth}{uri}{token} );

		my $data = $self->_encode( type => 'form', data => {
			grant_type => 'refresh_token'
			, client_id => $conf->{auth}{client}{id}
			, client_secret => $conf->{auth}{client}{secret}
			, refresh_token => $conf->{auth}{token}{refresh_token}
		} );

		$req->content( $data );

		my $res = $self->ua->request( $req );

		if ( $res->code == 200 ) {
			my $data = $self->_decode( type => 'json', data => $res->content );
			$data->{expires_at} = time + $data->{expires_in};
			$self->merge_config( $conf->{auth}->{token}, $data );
			$self->write_config( 'config/google/dfp/auth/private/token.yml', $conf->{auth}->{token} );
		}
	}

	if ( $conf->{auth}{token}{access_token} and $conf->{auth}{token}{expires_at} and $conf->{auth}{token}{expires_at} > $time ) {
		$self->ua->default_header( 'Authorization' => "$conf->{auth}{token}{token_type} $conf->{auth}{token}{access_token}" );
	}
	else {
		carp 'no access token';
	}

	# Setup match-spec vars for request_prepare.
	my ( $scheme, $host, $path ) = $self->uri =~ /^(https?):\/\/([^\/]+)(\/.+)$/;

	# Add request wrapper.
	$self->ua->add_handler(
		request_prepare => sub {
			my ( $req, $ua, $h ) = @_;

			# Create SOAP envelope.
			if ( my $data = $req->content ) {
				$self->_camelize( $data );

				$data = {
					'soap:Envelope' => {
						'-xmlns' => $self->uri
						, '-xmlns:soap' => 'http://schemas.xmlsoap.org/soap/envelope/'
						, '-xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance'
						, 'soap:Header' => {
							'RequestHeader' => {
								 'networkCode' => $conf->{network_code}
								,'applicationName' => $conf->{application_name}
							}
						}
						, 'soap:Body' => $data
					}
				};

				my $xml = $self->_xml->write( $data );

				$req->content( $xml );
				$req->headers->header( 'Content-Type' => 'text/xml; charset=utf-8' );

				# Uncomment this to view generated SOAP xml/envelope.
				# $self->debug( $xml );
			}
		}
		, m_scheme => $scheme
		, m_host => $host
		, m_path_match => qr/^\Q$path\E/
	);

	# Add response wrapper.
	$self->ua->add_handler(
		response_done => sub {
			my ( $res, $ua, $h ) = @_;
			if ( my $data = $res->content ) {
				$data = $self->_xml->parse( $data );
				$data = delete $data->{ 'soap:Envelope' }{ 'soap:Body' };
				$self->_decamelize( $data );
				$res->content( $data );
			}
		}
		, m_scheme => $scheme
		, m_host => $host
		, m_path_match => qr/^\Q$path\E/
		, m_code => 200
		, m_media_type => 'text/xml'
	);

	return $prev;
};

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

API::Handle::Google::DFP

=head1 VERSION

version 0.02

=head1 AUTHOR

Nour Sharabash <amirite@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Nour Sharabash.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
