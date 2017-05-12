# ABSTRACT: Name.com API Client
package API::Name;

use Data::Object::Class;
use Data::Object::Signatures;

use Data::Object::Library qw(
    Str
);

extends 'API::Client';

our $VERSION = '0.06'; # VERSION

our $DEFAULT_URL = "https://www.name.com";

# ATTRIBUTES

has user => (
    is       => 'rw',
    isa      => Str,
    required => 1,
);

has token => (
    is       => 'rw',
    isa      => Str,
    required => 1,
);

# DEFAULTS

has '+identifier' => (
    default  => 'API::Name (Perl)',
    required => 0,
);

has '+url' => (
    default  => $DEFAULT_URL,
    required => 0,
);

has '+version' => (
    default  => 1,
    required => 0,
);

# CONSTRUCTION

after BUILD => method {

    my $identifier = $self->identifier;
    my $version    = $self->version;
    my $agent      = $self->user_agent;
    my $url        = $self->url;

    $agent->transactor->name($identifier);

    # $url->path("/api/$version");
    $url->path("/api");

    return $self;

};

# METHODS

method PREPARE ($ua, $tx, %args) {

    my $headers = $tx->req->headers;
    my $url     = $tx->req->url;

    my $user  = $self->user;
    my $token = $self->token;

    # default headers
    $headers->header('Content-Type' => 'application/json');
    $headers->header('Api-Username' => $user);
    $headers->header('Api-Token'    => $token);

}

method resource (@segments) {

    # build new resource instance
    my $instance = __PACKAGE__->new(
        debug      => $self->debug,
        fatal      => $self->fatal,
        retries    => $self->retries,
        timeout    => $self->timeout,
        user_agent => $self->user_agent,
        identifier => $self->identifier,
        token      => $self->token,
        user       => $self->user,
        version    => $self->version,
    );

    # resource locator
    my $url = $instance->url;

    # modify resource locator if possible
    $url->path(join '/', $self->url->path, @segments);

    # return resource instance
    return $instance;

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Name - Name.com API Client

=head1 VERSION

version 0.06

=head1 SYNOPSIS

    use API::Name;

    my $name = API::Name->new(
        user       => 'USER',
        token      => 'TOKEN',
        identifier => 'APPLICATION NAME',
    );

    $name->debug(1);
    $name->fatal(1);

    my $domain = $name->domains(get => 'example.com');
    my $results = $domain->fetch;

    # after some introspection

    $domain->update( ... );

=head1 DESCRIPTION

This distribution provides an object-oriented thin-client library for
interacting with the Name (L<https://www.name.com>) API. For usage and
documentation information visit L<https://www.name.com/reseller/API-documentation>.
API::Name is derived from L<API::Client> and inherits all of it's
functionality. Please read the documentation for API::Client for more usage
information.

=head1 ATTRIBUTES

=head2 token

    $name->token;
    $name->token('TOKEN');

The token attribute should be set to the API token assigned to the account
holder.

=head2 user

    $name->user;
    $name->user('USER');

The user attribute should be set to the API user assgined to the account
holder.

=head2 identifier

    $name->identifier;
    $name->identifier('IDENTIFIER');

The identifier attribute should be set to a string that identifies your
application.

=head2 debug

    $name->debug;
    $name->debug(1);

The debug attribute if true prints HTTP requests and responses to standard out.

=head2 fatal

    $name->fatal;
    $name->fatal(1);

The fatal attribute if true promotes 4xx and 5xx server response codes to
exceptions, a L<API::Client::Exception> object.

=head2 retries

    $name->retries;
    $name->retries(10);

The retries attribute determines how many times an HTTP request should be
retried if a 4xx or 5xx response is received. This attribute defaults to 0.

=head2 timeout

    $name->timeout;
    $name->timeout(5);

The timeout attribute determines how long an HTTP connection should be kept
alive. This attribute defaults to 10.

=head2 url

    $name->url;
    $name->url(Mojo::URL->new('https://www.name.com'));

The url attribute set the base/pre-configured URL object that will be used in
all HTTP requests. This attribute expects a L<Mojo::URL> object.

=head2 user_agent

    $name->user_agent;
    $name->user_agent(Mojo::UserAgent->new);

The user_agent attribute set the pre-configured UserAgent object that will be
used in all HTTP requests. This attribute expects a L<Mojo::UserAgent> object.

=head1 METHODS

=head2 action

    my $result = $name->action($verb, %args);

    # e.g.

    $name->action('head', %args);    # HEAD request
    $name->action('options', %args); # OPTIONS request
    $name->action('patch', %args);   # PATCH request

The action method issues a request to the API resource represented by the
object. The first parameter will be used as the HTTP request method. The
arguments, expected to be a list of key/value pairs, will be included in the
request if the key is either C<data> or C<query>.

=head2 create

    my $results = $name->create(%args);

    # or

    $name->POST(%args);

The create method issues a C<POST> request to the API resource represented by
the object. The arguments, expected to be a list of key/value pairs, will be
included in the request if the key is either C<data> or C<query>.

=head2 delete

    my $results = $name->delete(%args);

    # or

    $name->DELETE(%args);

The delete method issues a C<DELETE> request to the API resource represented by
the object. The arguments, expected to be a list of key/value pairs, will be
included in the request if the key is either C<data> or C<query>.

=head2 fetch

    my $results = $name->fetch(%args);

    # or

    $name->GET(%args);

The fetch method issues a C<GET> request to the API resource represented by the
object. The arguments, expected to be a list of key/value pairs, will be
included in the request if the key is either C<data> or C<query>.

=head2 update

    my $results = $name->update(%args);

    # or

    $name->PUT(%args);

The update method issues a C<PUT> request to the API resource represented by
the object. The arguments, expected to be a list of key/value pairs, will be
included in the request if the key is either C<data> or C<query>.

=head1 RESOURCES

=head2 account

    $name->account;

The account method returns a new instance representative of the API
I<account> resource requested. This method accepts a list of path
segments which will be used in the HTTP request. The following documentation
can be used to find more information. L<https://www.name.com/reseller/API-documentation>.

=head2 dns

    $name->dns;

The dns method returns a new instance representative of the API
I<dns> resource requested. This method accepts a list of path
segments which will be used in the HTTP request. The following documentation
can be used to find more information. L<https://www.name.com/reseller/API-documentation>.

=head2 domain

    $name->domain;

The domain method returns a new instance representative of the API
I<domain> resource requested. This method accepts a list of path
segments which will be used in the HTTP request. The following documentation
can be used to find more information. L<https://www.name.com/reseller/API-documentation>.

=head2 host

    $name->host;

The host method returns a new instance representative of the API
I<host> resource requested. This method accepts a list of path
segments which will be used in the HTTP request. The following documentation
can be used to find more information. L<https://www.name.com/reseller/API-documentation>.

=head2 login

    $name->login;

The login method returns a new instance representative of the API
I<login> resource requested. This method accepts a list of path
segments which will be used in the HTTP request. The following documentation
can be used to find more information. L<https://www.name.com/reseller/API-documentation>.

=head2 logout

    $name->logout;

The logout method returns a new instance representative of the API
I<logout> resource requested. This method accepts a list of path
segments which will be used in the HTTP request. The following documentation
can be used to find more information. L<https://www.name.com/reseller/API-documentation>.

=head2 order

    $name->order;

The order method returns a new instance representative of the API
I<order> resource requested. This method accepts a list of path
segments which will be used in the HTTP request. The following documentation
can be used to find more information. L<https://www.name.com/reseller/API-documentation>.

=head1 AUTHOR

Al Newkirk <anewkirk@ana.io>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Al Newkirk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
