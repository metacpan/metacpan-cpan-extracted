package CPAN::Mini::Inject::REST::Client::API;

use Moose;
use Carp qw/confess/;
use HTTP::Request::Common;
use JSON;
use MIME::Base64;
use REST::Client;
use Try::Tiny;
use URI;

has 'host'     => (isa => 'Str', is => 'ro', required => 1);
has 'protocol' => (isa => 'Str', is => 'ro', required => 1);
has 'port'     => (isa => 'Int', is => 'ro', required => 1);
has 'username' => (isa => 'Str', is => 'ro');
has 'password' => (isa => 'Str', is => 'ro');
has 'client'   => (isa => 'REST::Client', is => 'ro', lazy => 1, builder => '_build_client');


#--Initiate a REST::Client object with optional HTTP authorisation--------------

sub _build_client {
    my $self = shift;
    
    my $client = REST::Client->new;
    if ($self->username && $self->password) {
        $client->addHeader('Authorization', 'Basic ' . encode_base64($self->username . ":" . $self->password));
    }
    
    return $client;
}


#--Define the API version to use------------------------------------------------

sub base_uri {
    return '/api/1.0';
}


#--Send an HTTP POST request to the server--------------------------------------

sub post {
    my ($self, $path, $params) = @_;

    my $request = POST(
        $self->uri($path),
        Content_Type => 'form-data',
        Content      => $params,
    );

    my $response = $self->client->POST(
        $self->uri($path),
        $request->content,
        {'Content-Type' => $request->header('Content-Type')},
    );
    
    return $self->process($response);
}


#--Send an HTTP GET request to the server---------------------------------------

sub get {
    my ($self, $path, $params) = @_;
    
    my $uri = $self->uri($path);
    $uri .= '?' . $self->query_string($params) if $params && %$params;
    
    my $response = $self->client->GET($uri);
    
    return $self->process($response);
}


#--Construct a complete URI from a path string----------------------------------

sub uri {
    my ($self, $path) = @_;
    
    return join '',
        $self->protocol, '://',
        $self->host, ':', $self->port,
        $self->base_uri, '/', $path;
}


#--Convert a hashref of parameters into a query string--------------------------

sub query_string {
    my ($self, $query_params) = @_;

    my $url = URI->new('http:');
    $url->query_form(%$query_params);
    my $query_string = $url->query;

    return $query_string;
}


#--Decode the result of an API request------------------------------------------

sub process {
    my ($self, $response) = @_;

    my $content = try {
        decode_json($response->responseContent);
    } catch {
        $response->responseContent;
    };
                  
    return ($response->responseCode, $content);
}


#-------------------------------------------------------------------------------

1;