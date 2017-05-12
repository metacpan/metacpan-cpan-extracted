# Client Exception Class
package API::Client::Exception;

use Data::Object::Class;
use Data::Object::Signatures;

use Data::Object::Library qw(
    InstanceOf
    Int
    Maybe
    Str
);

extends 'Data::Object::Exception';

our $VERSION = '0.04'; # VERSION

# ATTRIBUTES

has code => (
    is       => 'ro',
    isa      => Maybe[Int],
    required => 0,
);

has method => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has tx => (
    is       => 'ro',
    isa      => InstanceOf['Mojo::Transaction'],
    required => 1,
);

has url => (
    is       => 'ro',
    isa      => InstanceOf['Mojo::URL'],
    required => 1,
);

has '+message' => (
    is       => 'ro',
    isa      => Str,
    required => 0,
    lazy     => 1,
    builder  => 'default_message',
);

# METHODS

method default_message {

    my $code   = $self->code;
    my $method = $self->method;
    my $url    = $self->url;

    my $reason  = $code ? "response code $code" : "unexpected response";
    my $message = "$reason received while processing the request $method $url";

    return $message;

}

1;
