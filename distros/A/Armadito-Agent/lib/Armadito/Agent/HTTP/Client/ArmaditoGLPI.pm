package Armadito::Agent::HTTP::Client::ArmaditoGLPI;

use strict;
use warnings;
use base 'Armadito::Agent::HTTP::Client';

use English qw(-no_match_vars);
use HTTP::Request;
use HTTP::Request::Common qw{ POST };
use UNIVERSAL::require;
use URI;
use Encode;
use Data::Dumper;
use URI::Escape;

sub new {
	my ( $class, %params ) = @_;
	my $self = $class->SUPER::new(%params);

	return $self;
}

sub _prepareVal {
	my ( $self, $val ) = @_;

	return '' unless length($val);

	# forbid too long argument.
	while ( length( URI::Escape::uri_escape_utf8($val) ) > 1500 ) {
		$val =~ s/^.{5}/…/;
	}

	return URI::Escape::uri_escape_utf8($val);
}

sub _prepareURL {
	my ( $self, %params ) = @_;

	my $url = ref $params{url} eq 'URI' ? $params{url} : URI->new( $params{url} );

	if ( $params{method} eq 'GET' ) {

		my $urlparams = 'agent_id=' . uri_escape( $params{args}->{agent_id} );

		foreach my $k ( keys %{ $params{args} } ) {
			if ( ref( $params{args}->{$k} ) eq 'ARRAY' ) {
				foreach ( @{ $params{args}->{$k} } ) {
					$urlparams .= '&' . $k . '[]=' . $self->_prepareVal( $_ || '' );
				}
			}
			elsif ( ref( $params{args}->{$k} ) eq 'HASH' ) {
				foreach ( keys %{ $params{args}->{$k} } ) {
					$urlparams .= '&' . $k . '[' . $_ . ']=' . $self->_prepareVal( $params{args}->{$k}{$_} );
				}
			}
			elsif ( $k ne 'action' && length( $params{args}->{$k} ) ) {
				$urlparams .= '&' . $k . '=' . $self->_prepareVal( $params{args}->{$k} );
			}
		}

		$url .= '?' . $urlparams;
	}

	return $url;
}

sub sendRequest {
	my ( $self, %params ) = @_;

	my $url = $self->_prepareURL(%params);

	$self->{logger}->debug2($url) if $self->{logger};

	my $headers = HTTP::Headers->new(
		'Content-Type' => 'application/json',
		'Referer'      => $url
	);

	my $request = HTTP::Request->new(
		$params{method} => $url,
		$headers
	);

	if ( $params{message} && $params{method} eq 'POST' ) {
		$request->content( encode( 'UTF-8', $params{message} ) );
	}

	return $self->request($request);
}

1;
__END__

=head1 NAME

Armadito::Agent::HTTP::Client::ArmaditoGLPI - HTTP Client for armadito plugin for GLPI.

=head1 DESCRIPTION

This is the class used by Armadito agent to communicate with armadito plugin in GLPI.

=head1 METHODS

=head2 $task->sendRequest(%params)

Send a request according to params given. If this is a GET request, params are formatted into URL with _prepareURL method. If this is a POST request, a message must be given in params. This should be a valid JSON message.

The following parameters are allowed, as keys of the %params hash :

=over

=item I<url>

the url to send the message to (mandatory)

=item I<method>

the method used: GET or POST. (mandatory)

=item I<message>

the message to send (mandatory if method is POST)

=back

The return value is a response object. See L<HTTP::Request> and L<HTTP::Response> for a description of the interface provided by these classes.
