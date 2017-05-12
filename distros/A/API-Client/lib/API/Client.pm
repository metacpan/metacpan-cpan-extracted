# ABSTRACT: General-Purpose API Client Abstraction
package API::Client;

use Data::Object::Class;
use Data::Object::Signatures;

use Data::Object::Library qw(
    InstanceOf
    Int
    Str
);

extends 'API::Client::Core';

use Carp ();
use Scalar::Util ();

our $VERSION = '0.04'; # VERSION

# ATTRIBUTES

has casing => (
    is       => 'rw',
    isa      => Str,
    default  => 'lowercase',
    required => 0,
);

has credentials => (
    is       => 'ro',
    isa      => InstanceOf['API::Client::Credentials'],
    required => 0,
);

has identifier => (
    is       => 'rw',
    isa      => Str,
    default  => 'API::Client (Perl)',
    required => 0,
);

has version => (
    is       => 'rw',
    isa      => Str,
    default  => 0,
    required => 0,
);

# METHOD-RESOLUTION

method AUTOLOAD () {

    my @words = split /::/, our $AUTOLOAD;

    my $method  = pop @words;
    my $package = join '::', @words;

    Carp::croak("Undefined subroutine &${package}::$method called")
        unless Scalar::Util::blessed($self) && $self->isa(__PACKAGE__);

    my @segments = @_;
    my @results  = ();

    # attempt to automate path casing
    while (my ($path, $param) = splice @segments, 0, 2) {
        my $casing = $self->casing;

        if (defined $param and $casing eq 'lowercase') {
            $path = lc $path;
        }
        elsif (defined $param and $casing eq 'snakecase') {
            my ($first, @remaining) = split /_/, $path;
            $path = join '', $first, map ucfirst, @remaining;
        }
        elsif (defined $param and $casing eq 'camelcase') {
            my ($first, @remaining) = split /_/, $path;
            $path = join '', $first, map ucfirst, @remaining;
        }
        elsif (defined $param and $casing eq 'pascalcase') {
            $path = join '', map ucfirst, split /_/, $path;
        }
        elsif (defined $param and $casing eq 'uppercase') {
            $path = uc $path;
        }

        push @results, $path, defined $param ? $param : ();
    }

    # return new resource instance dynamically
    return $self->resource($method, @results);

}

# CONSTRUCTION

method BUILD () {

    my $ident = $self->identifier;
    my $agent = $self->user_agent;

    # identify the API client
    $agent->transactor->name($ident);

    return $self;

}

# METHODS

method PREPARE ($ua, $tx, %args) {

    if (my $credentials = $self->credentials) {

        # process credentials
        $credentials->process($tx);

    }

    my $headers = $tx->req->headers;
    my $url     = $tx->req->url;

    # default headers
    $headers->header('Content-Type' => 'application/json');

    return $self;

}

method action ($method, %args) {

    $method = uc($method || 'get');

    # execute transaction and return response
    return $self->$method(%args);

}

method create (%args) {

    # execute transaction and return response
    return $self->POST(%args);

}

method delete (%args) {

    # execute transaction and return response
    return $self->DELETE(%args);

}

method fetch (%args) {

    # execute transaction and return response
    return $self->GET(%args);

}

method resource (@segments) {

    my $class = ref($self);

    # build new resource instance
    my $instance = $class->new(
        debug      => $self->debug,
        fatal      => $self->fatal,
        retries    => $self->retries,
        timeout    => $self->timeout,
        user_agent => $self->user_agent,
        identifier => $self->identifier,
        version    => $self->version,
        # attempt to deduce other attributes
        %$self
    );

    # resource locator
    my $url = $instance->url;

    # modify resource locator if possible
    $url->path(join '/', $self->url->path, @segments);

    # return resource instance
    return $instance;

}

method update (%args) {

    # execute transaction and return response
    return $self->PUT(%args);

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Client - General-Purpose API Client Abstraction

=head1 VERSION

version 0.04

=head1 SYNOPSIS

    use API::Client;

    my $client = API::Client->new(url => "https://api.example.com");

    $client->debug(1);
    $client->fatal(1);

    my $resource = $client->resource;
    my $results  = $resource->fetch;

    # after some introspection

    $resource->update(...);

=head1 DESCRIPTION

This distribution provides an API client abstraction for rapidly developing
client to interact with web services. Although this module can be used to
interact with APIs directly, API::Client was designed to be consumed
(subclassed) by higher-level purpose-specific API client code.

=head1 THIN CLIENT

The thin api-client library is advantageous as it has complete API coverage and
can easily adapt to changes in the API with minimal effort. As a thin-client
library, this module does not map specific HTTP requests to specific routines,
nor does it provide parameter validation, pagination, or other conventions
found in typical API client implementations; Instead, it simply provides a
simple and consistent mechanism for dynamically generating HTTP requests.
Additionally, this module has support for debugging and retrying API calls as
well as throwing exceptions when 4xx and 5xx server response codes are
returned.

=head2 Building

    my $user = $client->users('c09e91a');

    $user->action; # GET /users/c09e91a
    $user->action('head'); # HEAD /users/c09e91a
    $user->action('patch'); # PATCH /users/c09e91a

Building up an HTTP request object is extremely easy, simply call method names
which correspond to the API's path segments in the resource you wish to execute
a request against. This module uses autoloading and returns a new instance with
each method call. The following is the equivalent:

=head2 Chaining

    my $user = $client->resource('users', 'c09e91a');

    # or

    my $users = $client->users;
    my $user  = $users->resource('c09e91a');

    # then

    $user->action('put', %args); # PUT /users/c09e91a

Because each call returns a new API instance configured with a resource locator
based on the supplied parameters, reuse and request isolation are made simple,
i.e., you will only need to configure the client once in your application.

=head2 Fetching

    my $users = $client->users;

    # query-string parameters

    $users->fetch( query => { ... } );

    # equivalent to

    my $users = $client->resource('users');

    $users->action( get => ( query => { ... } ) );

This example illustrates how you might fetch an API resource.

=head2 Creating

    my $users = $client->users;

    # content-body parameters

    $users->create( data => { ... } );

    # query-string parameters

    $users->create( query => { ... } );

    # equivalent to

    $client->resource('users')->action(
        post => ( query => { ... }, data => { ... } )
    );

This example illustrates how you might create a new API resource.

=head2 Updating

    my $users = $client->users;
    my $user  = $users->resource('c09e91a');

    # content-body parameters

    $user->update( data => { ... } );

    # query-string parameters

    $user->update( query => { ... } );

    # or

    my $user = $client->users('c09e91a');

    $user->update(...);

    # equivalent to

    $client->resource('users')->action(
        put => ( query => { ... }, data => { ... } )
    );

This example illustrates how you might update a new API resource.

=head2 Deleting

    my $users = $client->users;
    my $user  = $users->resource('c09e91a');

    # content-body parameters

    $user->delete( data => { ... } );

    # query-string parameters

    $user->delete( query => { ... } );

    # or

    my $user = $client->users('c09e91a');

    $user->delete(...);

    # equivalent to

    $client->resource('users')->action(
        delete => ( query => { ... }, data => { ... } )
    );

This example illustrates how you might delete an API resource.

=head2 Transacting

    my $users = $client->resource('users', 'c09e91a');

    my ($results, $transaction) = $users->action( ... );

    my $request  = $transaction->req;
    my $response = $transaction->res;

    my $headers;

    $headers = $request->headers;
    $headers = $response->headers;

    # etc

This example illustrates how you can access the transaction object used to
represent and process the HTTP transaction.

=head2 Casing

    $client->casing('lowercase');

    my $settings = $client->users('c09e91a')->profile_settings;

    # given casing as 'lowercase'
    $settings->fetch( ... ); # GET /users/c09e91a/profile_settings

    # given casing as 'uppercase'
    $settings->fetch( ... ); # GET /USERS/C09E91A/PROFILE_SETTINGS

    # given casing as 'camelcase'
    $settings->fetch( ... ); # GET /users/c09e91a/profileSettings

    # given casing as 'snakecase'
    $settings->fetch( ... ); # GET /users/c09e91a/profileSettings

    # given casing as 'pascalcase'
    $settings->fetch( ... ); # GET /Users/c09e91a/ProfileSettings

This example illustrates how you can configure the client to automatically
handle the casing of path segments while continuing to use lowercase-userscore 
separated string in your code. This is useful when interacting with an API that
uses convetions foreign to that of your codebase.

=head1 ATTRIBUTES

=head2 casing

    $client->casing;
    $client->casing('lowercase');

The casing attribute should be set to either C<lowercase>, C<snakecase>,
C<camelcase>, C<pascalcase>, or C<uppercase>, which determines how URL segments
should be formatted.

=head2 credentials

    $client->credentials;
    $client->credentials(API::Client::Credentials->new(...));

The credentials attribute sets the pre-configured Credentials object
that, if defined, will be used to modify the Transaction object to include
authentication credentials. This attribute expects an object derived from the
L<API::Client::Credentials> class.

=head2 identifier

    $client->identifier;
    $client->identifier('API::Client (Perl)');

The identifier attribute should be set to a string that identifies your
application.

=head2 debug

    $client->debug;
    $client->debug(1);

The debug attribute if true prints HTTP requests and responses to standard out.

=head2 fatal

    $client->fatal;
    $client->fatal(1);

The fatal attribute if true promotes 4xx and 5xx server response codes to
exceptions, a L<API::Client::Exception> object.

=head2 retries

    $client->retries;
    $client->retries(10);

The retries attribute determines how many times an HTTP request should be
retried if a 4xx or 5xx response is received. This attribute defaults to 0.

=head2 timeout

    $client->timeout;
    $client->timeout(5);

The timeout attribute determines how long an HTTP connection should be kept
alive. This attribute defaults to 10.

=head2 url

    $client->url;
    $client->url(Mojo::URL->new('https://api.example.com'));

The url attribute sets the base/pre-configured URL object that will be used in
all HTTP requests. This attribute expects a L<Mojo::URL> object.

=head2 user_agent

    $client->user_agent;
    $client->user_agent(Mojo::UserAgent->new);

The user_agent attribute sets the pre-configured UserAgent object that will be
used in all HTTP requests. This attribute expects a L<Mojo::UserAgent> object.

=head1 METHODS

=head2 action

    my $result = $client->action($verb, %args);

    # e.g.

    $client->action('head', %args);    # HEAD request
    $client->action('options', %args); # OPTIONS request
    $client->action('patch', %args);   # PATCH request

The action method issues a request to the API resource represented by the
object. The first parameter will be used as the HTTP request method. The
arguments, expected to be a list of key/value pairs, will be included in the
request if the key is either C<data> or C<query>.

=head2 create

    my $results = $client->create(%args);

    # or

    $client->POST(%args);

The create method issues a C<POST> request to the API resource represented by
the object. The arguments, expected to be a list of key/value pairs, will be
included in the request if the key is either C<data> or C<query>.

=head2 delete

    my $results = $client->delete(%args);

    # or

    $client->DELETE(%args);

The delete method issues a C<DELETE> request to the API resource represented by
the object. The arguments, expected to be a list of key/value pairs, will be
included in the request if the key is either C<data> or C<query>.

=head2 fetch

    my $results = $client->fetch(%args);

    # or

    $client->GET(%args);

The fetch method issues a C<GET> request to the API resource represented by the
object. The arguments, expected to be a list of key/value pairs, will be
included in the request if the key is either C<data> or C<query>.

=head2 update

    my $results = $client->update(%args);

    # or

    $client->PUT(%args);

The update method issues a C<PUT> request to the API resource represented by
the object. The arguments, expected to be a list of key/value pairs, will be
included in the request if the key is either C<data> or C<query>.

=head1 AUTHOR

Al Newkirk <anewkirk@ana.io>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Al Newkirk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
