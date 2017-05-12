# Client Core Class
package API::Client::Core;

use Data::Object::Class;
use Data::Object::Signatures;

use Data::Object::Library qw(
    InstanceOf
    Int
);

use Mojo::Transaction;
use Mojo::UserAgent;
use Mojo::URL;

use API::Client::Exception;

our $VERSION = '0.04'; # VERSION

# ATTRIBUTES

has debug => (
    is       => 'rw',
    isa      => Int,
    default  => 0,
    required => 0,
);

has fatal => (
    is       => 'rw',
    isa      => Int,
    default  => 0,
    required => 0,
);

has retries => (
    is       => 'rw',
    isa      => Int,
    default  => 0,
    required => 0,
);

has timeout => (
    is       => 'rw',
    isa      => Int,
    default  => 10,
    required => 0,
);

has url => (
    is       => 'ro',
    isa      => InstanceOf['Mojo::URL'],
    coerce   => fun { ref($_[0]) ? $_[0] : Mojo::URL->new($_[0]) },
    required => 0,
);

has user_agent => (
    is       => 'ro',
    isa      => InstanceOf['Mojo::UserAgent'],
    default  => fun { Mojo::UserAgent->new },
    required => 0,
);

# DELEGATES

my @methods = qw(
    DELETE
    GET
    HEAD
    OPTIONS
    PATCH
    POST
    PUT
);

around [@methods] => fun ($orig, $self, %args) {

    my $retries = $self->retries;
    my $ua      = $self->user_agent;

    # client timeouts
    $ua->max_redirects(0);
    $ua->connect_timeout($self->timeout);
    $ua->request_timeout($self->timeout);

    # request initialization
    $ua->on(start => fun ($ua, $tx) {

        $self->PREPARE($ua, $tx, %args);

    });

    # retry entry point
    RETRY:

    # execute transaction
    my $tx = $self->$orig(%args);

    # fetch transaction objects
    my $req = $tx->req;
    my $res = $tx->res;

    # determine success/failure
    my $ok = $res->code ? $res->code !~ /(4|5)\d\d/ : 0;

    # attempt logging where applicable
    if ($req and $res and $self->debug) {

        my $reqstr = $req->to_string;
        my $resstr = $res->to_string;

        $reqstr =~ s/\s*$/\n\n\n/;
        $resstr =~ s/\s*$/\n\n\n/;

        print STDOUT $reqstr;
        print STDOUT $resstr;

    }

    # retry transaction where applicable
    goto RETRY if $retries-- > 0 and not $ok;

    # throw exception if fatal is enabled
    if ($req and $res and $self->fatal and not $ok) {

        API::Client::Exception->throw(
            tx     => $tx,
            code   => $res->code,
            method => $req->method,
            url    => $req->url,
        );

    }

    # return JSON
    return $res->json;

};

# METHODS

method DELETE (Str :$path = '', HashRef :$data = {}, HashRef :$query = {}) {

    my $ua  = $self->user_agent;
    my $url = $self->url->clone;

    $url->path(join '/', $url->path, $path)  if $path;
    $url->query($url->query->merge(%$query)) if keys %$query;

    return $ua->delete($url, ({}, keys(%$data) ? (json => $data) : ()));

}

fun DESTROY {

    ; # Protect subclasses using AUTOLOAD

}

method GET (Str :$path = '', HashRef :$data = {}, HashRef :$query = {}) {

    my $ua  = $self->user_agent;
    my $url = $self->url->clone;

    $url->path(join '/', $url->path, $path)  if $path;
    $url->query($url->query->merge(%$query)) if keys %$query;

    return $ua->get($url, ({}, keys(%$data) ? (json => $data) : ()));

}

method HEAD (Str :$path = '', HashRef :$data = {}, HashRef :$query = {}) {

    my $url = $self->url->clone;
    my $ua  = $self->user_agent;

    $url->path(join '/', $url->path, $path)  if $path;
    $url->query($url->query->merge(%$query)) if keys %$query;

    return $ua->head($url, ({}, keys(%$data) ? (json => $data) : ()));

}

method OPTIONS (Str :$path = '', HashRef :$data = {}, HashRef :$query = {}) {

    my $url = $self->url->clone;
    my $ua  = $self->user_agent;

    $url->path(join '/', $url->path, $path)  if $path;
    $url->query($url->query->merge(%$query)) if keys %$query;

    return $ua->options($url, ({}, keys(%$data) ? (json => $data) : ()));

}

method PATCH (Str :$path = '', HashRef :$data = {}, HashRef :$query = {}) {

    my $url = $self->url->clone;
    my $ua  = $self->user_agent;

    $url->path(join '/', $url->path, $path)  if $path;
    $url->query($url->query->merge(%$query)) if keys %$query;

    return $ua->patch($url, ({}, keys(%$data) ? (json => $data) : ()));

}

method POST (Str :$path = '', HashRef :$data = {}, HashRef :$query = {}) {

    my $url = $self->url->clone;
    my $ua  = $self->user_agent;

    $url->path(join '/', $url->path, $path)  if $path;
    $url->query($url->query->merge(%$query)) if keys %$query;

    return $ua->post($url, ({}, keys(%$data) ? (json => $data) : ()));

}

method PUT (Str :$path = '', HashRef :$data = {}, HashRef :$query = {}) {

    my $url = $self->url->clone;
    my $ua  = $self->user_agent;

    $url->path(join '/', $url->path, $path)  if $path;
    $url->query($url->query->merge(%$query)) if keys %$query;

    return $ua->put($url, ({}, keys(%$data) ? (json => $data) : ()));

}

1;
