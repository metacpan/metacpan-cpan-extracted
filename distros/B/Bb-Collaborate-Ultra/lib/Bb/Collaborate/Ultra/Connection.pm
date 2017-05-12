package Bb::Collaborate::Ultra::Connection;
use warnings; use strict;
use Crypt::JWT qw(encode_jwt decode_jwt);
use JSON;
use Mouse;
use REST::Client;
use Try::Tiny;
use Bb::Collaborate::Ultra::Connection::Token;

=head1 NAME

Bb::Collaborate::Ultra::Connection - manage a server connection

=head2 DESCRIPTION

This class is used to maintain connections to Blackboard Ultra virtual
classroom servers.

	require Bb::Collaborate::Ultra::Connection;
	my %params = (
	    issuer => 'my-client-key',
            secret => 'sssh!',
            host => 'https://xx-csa.bbcollab.com',
	);
	my $connection = Bb::Collaborate::Ultra::Connection->new(\%params);


=head1 METHODS

=cut

has 'issuer' => (is => 'rw', isa => 'Str', required => 1);
has 'secret' => (is => 'rw', isa => 'Str', required => 1);
has 'host'   => (is => 'rw', isa => 'Str', required => 1);

has '_client' => (is => 'rw', isa => 'REST::Client' );

=head2 auth

Holds the authorization token, obtained from the Collaborate server.

The connect method mast be invoked to obtain an C<auth> token. The C<renew_lease> method may be later used to extend the session, obtaining
an new C<auth> token.

=head2 debug

    $connection->debug(1);  # enable debugging

When set, a trace is enabled of requests and responses to and from the Collaborate server

=cut

has 'auth'  =>  (is => 'rw', isa => 'Bb::Collaborate::Ultra::Connection::Token' ); 
has 'debug'  =>  (is => 'rw', isa => 'Int' );

sub _response {
    my $self = shift;
    my $client = shift || $self->client;
    my $response_content = $client->responseContent;
    my $response_code = $client->responseCode;
    warn "RESPONSE: [$response_code] ". $response_content. "\n\n"
	if $self->debug;
    my $response_data;
    if ($response_content) {
	try {
	    $response_data = from_json( $response_content);
	}
	catch {
	    die "[$response_code] $response_content";
	};

	die "[$response_code] $response_data->{errorKey} : $response_data->{errorMessage}\n"
	    if $response_data->{errorKey};
    }
    die "bad HTTP response code: $response_code"
	unless $response_code == 200;
    $response_data;
}

use constant JWS_RSA_256 => 'HS256';
use constant JWT_EXPIRY => 4 * 60; # 4 minutes

=head2 connect

This method should be called once, with a newly created L<Bb::Collaborate::Ultra::Connection> object to contact the server and authorize the credentials.

	my %credentials = (
	  issuer => 'OUUK-REST-API12340ABCD',
	  secret => 'ABCDEF0123456789AA',
	  host => 'https://xx-csa.bbcollab.com',
	);

	# connect to server
	my $connection = Bb::Collaborate::Ultra::Connection->new(\%credentials);
        $connection->connect;

=cut

sub connect {
    my $self = shift;

    my $client = $self->client;

    $self->renew_lease
	unless $self->auth;
}

=head2 client

Returns the underlying client connection of type L<REST::Client>.

=cut

sub client {
    my $self = shift;
    my $client = $self->_client;
    unless ($client) {
	$client= REST::Client->new;
	$client->setHost($self->host);
	$self->_client($client);
    }
    $client;
}

=head2 renew_lease

    if ($connection->auth->expires_in < time() + 60) {
        # connection is about to expire; keep it alive.
        $connection->renew_lease;
    }

A authorization token typically remains valid for several minutes. This method
can be used to extend the lease, whilst keeping the current connection.

=cut

sub renew_lease {
    my $self = shift;
    my $expiry = shift || time()  +  JWT_EXPIRY;
    my $class = 'Bb::Collaborate::Ultra::Connection::Token';
    my $client = $self->client;

    my $claims = {
	iss => $self->issuer,
	sub => $self->issuer,
	exp => $expiry,
    };

    my $jwt = encode_jwt( payload => $claims, key => $self->secret, alg => JWS_RSA_256);

    my $query = $client->buildQuery({
	grant_type => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
	assertion => $jwt,
    });

    my $path = $class->path;
    warn "POST: $path$query\n" if $self->debug;
    $client->POST($path . $query, '', { 'Content-Type' => 'application/x-www-form-urlencoded' });
    my $auth_msg = $self->_response($client);
    my $auth = $class->construct($auth_msg, connection => $self);
    $auth->_leased( time() );
    $self->auth( $auth );
}

=head2 POST

Low level method. Posts JSON data formatted data, along with
appropriate authorization headers.

    my $response = $connection->POST('sessions', '{"startTime":"2016-09-27T05:10:04Z","endTime":"2016-09-27T05:25:04Z","name":"Test Session"}');
    my $session = Bb::Collaborate::Ultra::Session->construct($response, connection => $connection);

Generally, you should be using higher level class-specific `post` methods:

    my $session = Bb::Collaborate::Ultra::Session->post({startTime => time(), endTime => time() + 900, name => 'Test Session'});

=cut

sub POST {
    my $self = shift;
    my $path = shift;
    my $json = shift;
    warn "POST: $path    $json\n" if $self->debug;
    $self->renew_lease unless $self->auth; # auto-connect
    $self->client->POST($path, $json, {
	'Content-Type' => 'application/json',
	'Authorization' => 'Bearer ' . $self->auth->access_token,
    },);
    $self->_response;
}

=head2 PATCH

Low level method. Put JSON data formatted data.

    my $session_id = $session->id;
    my $response = $connection->PATCH('sessions/'.$session_id, '{"name":"Test Session - Updated"}');

=cut

sub PATCH {
    my $self = shift;
    my $path = shift;
    my $json = shift;
    warn "PATCH: $path   $json\n" if $self->debug;
    $self->client->PATCH($path, $json, {
	'Content-Type' => 'application/json',
	'Authorization' => 'Bearer ' . $self->auth->access_token,
    },);
    $self->_response;
}

=head2 GET

Low level method. Get by path

    my $session_id = $session->id;
    my $response = $connection->GET('sessions/'.$session_id);
    $session = Bb::Collaborate::Ultra::Session->construct($response, connection => $connection);

=cut

sub GET {
    my $self = shift;
    my $path = shift;
    warn "GET: $path\n" if $self->debug;
    $self->renew_lease unless $self->auth; # auto-connect
    $self->client->GET($path, {
	'Content-Type' => 'application/json',
	'Authorization' => 'Bearer ' . $self->auth->access_token,
    },);
    $self->_response;
}

=head2 DELETE

Low level method. Delete by path

    my $session_id = $session->id;
    my $response = $connection->DELETE('sessions/'.$session_id);

=cut

sub DELETE {
    my $self = shift;
    my $path = shift;
    my $query_data = shift || {};

    die "id required for deletion"
	unless $query_data->{id};
    $path .= '/' . $query_data->{id};

    warn "DELETE: $path\n" if $self->debug;
    $self->renew_lease unless $self->auth; # auto-connect
    $self->client->DELETE($path, {
	'Content-Type' => 'application/json',
	'Authorization' => 'Bearer ' . $self->auth->access_token,
    },);
    $self->_response;
}

1;
