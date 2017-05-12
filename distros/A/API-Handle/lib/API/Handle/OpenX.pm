package API::Handle::OpenX;
{
  $API::Handle::OpenX::VERSION = '0.02';
}
use Moose;
use namespace::autoclean;
use Carp;
use feature ':5.10';
use OX::OAuth;

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
			 -base => 'config/openx'
		 );
	}
);

# This is where we configure how the user-agent transforms
# outgoing and incoming requests and responses.
# See also: API::Handle::Google::DFP.

around BUILD => sub {
	my ( $next, $self, @args, $prev ) = @_;

	my $conf = $self->config;

	$self->uri( $conf->{oauth}{api_url} );

	# Uncomment this to view loaded configuration.
	# $self->dumper( 'config', $conf );

	# Steal UA from lib provided by OpenX.
	my $oauth = new OX::OAuth ( $conf->{oauth} );

	$oauth->login or carp $oauth->error;
	$oauth->token or carp "no oauth token?";

	$self->ua( $oauth->{_ua} );

	# Put code that pre-empts API::Handle::BUILD before this $prev line.
	$prev = $self->$next( @args );
	# Put code that depends on API::Handle::BUILD after this $prev line.

	# Setup match-spec vars for request_prepare.
	my ( $scheme, $host, $path ) = $self->uri =~ /^(https?):\/\/([^\/]+)(\/.+)$/;

	# Add request wrapper.
	$self->ua->add_handler(
		request_prepare => sub {
			my ( $req, $ua, $h ) = @_;

			# Create SOAP envelope.
			if ( my $data = $req->content ) {
				my $json = $self->_encode( type => 'json', data => $data );
				$req->content( $json );
				$req->headers->header( 'Content-Type' => 'application/json; charset=utf-8' );

				# Uncomment this to view generated JSON content.
				# $self->debug( $json );
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
				$data = $self->_decode( type => 'json', data => $data );
				$res->content( $data );
			}
		}
		, m_scheme => $scheme
		, m_host => $host
		, m_path_match => qr/^\Q$path\E/
		, m_code => 200
	);

	return $prev;
};

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

API::Handle::OpenX

=head1 VERSION

version 0.02

=head1 AUTHOR

Nour Sharabash <amirite@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Nour Sharabash.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
