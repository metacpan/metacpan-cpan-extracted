# ABSTRACT: Github.com API Client
package API::Github;

use Data::Object::Class;
use Data::Object::Signatures;

use Data::Object::Library qw(
    Str
);

extends 'API::Client';

our $VERSION = '0.06'; # VERSION

our $DEFAULT_URL = "https://api.github.com";

# ATTRIBUTES

has username => (
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
    default  => 'API::Github (Perl)',
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
    my $username   = $self->username;
    my $token      = $self->token;
    my $version    = $self->version;

    my $userinfo   = "$username:$token";
    my $agent      = $self->user_agent;
    my $url        = $self->url;

    $agent->transactor->name($identifier);
    $url->userinfo($userinfo);

    return $self;

};

method PREPARE ($ua, $tx, %args) {

    my $headers = $tx->req->headers;
    my $url     = $tx->req->url;

    # default headers
    $headers->header('Content-Type' => 'application/json');

    return $self;

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
        username   => $self->username,
        token      => $self->token,
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

API::Github - Github.com API Client

=head1 VERSION

version 0.06

=head1 SYNOPSIS

    use API::Github;

    my $github = API::Github->new(
        username   => 'USERNAME',
        token      => 'TOKEN',
        identifier => 'APPLICATION NAME',
    );

    $github->debug(1);
    $github->fatal(1);

    my $user = $github->users('h@x0r');
    my $results = $user->fetch;

    # after some introspection

    $user->update( ... );

=head1 DESCRIPTION

This distribution provides an object-oriented thin-client library for
interacting with the Github (L<http://github.com>) API. For usage and
documentation information visit L<https://developer.github.com/v3>.
API::Github is derived from L<API::Client> and inherits all of it's
functionality. Please read the documentation for API::Client for more usage
information.

=head1 ATTRIBUTES

=head2 identifier

    $github->identifier;
    $github->identifier('IDENTIFIER');

The identifier attribute should be set to a string that identifies your
application.

=head2 token

    $github->token;
    $github->token('TOKEN');

The token attribute should be set to the API user's personal access token.

=head2 username

    $github->username;
    $github->username('USERNAME');

The username attribute should be set to the API user's username.

=head2 debug

    $github->debug;
    $github->debug(1);

The debug attribute if true prints HTTP requests and responses to standard out.

=head2 fatal

    $github->fatal;
    $github->fatal(1);

The fatal attribute if true promotes 4xx and 5xx server response codes to
exceptions, a L<API::Client::Exception> object.

=head2 retries

    $github->retries;
    $github->retries(10);

The retries attribute determines how many times an HTTP request should be
retried if a 4xx or 5xx response is received. This attribute defaults to 0.

=head2 timeout

    $github->timeout;
    $github->timeout(5);

The timeout attribute determines how long an HTTP connection should be kept
alive. This attribute defaults to 10.

=head2 url

    $github->url;
    $github->url(Mojo::URL->new('https://api.github.com'));

The url attribute set the base/pre-configured URL object that will be used in
all HTTP requests. This attribute expects a L<Mojo::URL> object.

=head2 user_agent

    $github->user_agent;
    $github->user_agent(Mojo::UserAgent->new);

The user_agent attribute set the pre-configured UserAgent object that will be
used in all HTTP requests. This attribute expects a L<Mojo::UserAgent> object.

=head1 METHODS

=head2 action

    my $result = $github->action($verb, %args);

    # e.g.

    $github->action('head', %args);    # HEAD request
    $github->action('options', %args); # OPTIONS request
    $github->action('patch', %args);   # PATCH request

The action method issues a request to the API resource represented by the
object. The first parameter will be used as the HTTP request method. The
arguments, expected to be a list of key/value pairs, will be included in the
request if the key is either C<data> or C<query>.

=head2 create

    my $results = $github->create(%args);

    # or

    $github->POST(%args);

The create method issues a C<POST> request to the API resource represented by
the object. The arguments, expected to be a list of key/value pairs, will be
included in the request if the key is either C<data> or C<query>.

=head2 delete

    my $results = $github->delete(%args);

    # or

    $github->DELETE(%args);

The delete method issues a C<DELETE> request to the API resource represented by
the object. The arguments, expected to be a list of key/value pairs, will be
included in the request if the key is either C<data> or C<query>.

=head2 fetch

    my $results = $github->fetch(%args);

    # or

    $github->GET(%args);

The fetch method issues a C<GET> request to the API resource represented by the
object. The arguments, expected to be a list of key/value pairs, will be
included in the request if the key is either C<data> or C<query>.

=head2 update

    my $results = $github->update(%args);

    # or

    $github->PUT(%args);

The update method issues a C<PUT> request to the API resource represented by
the object. The arguments, expected to be a list of key/value pairs, will be
included in the request if the key is either C<data> or C<query>.

=head1 RESOURCES

=head2 emojis

    $github->emojis;

The emojis method returns a new instance representative of the API
I<emojis> resource requested. This method accepts a list of path
segments which will be used in the HTTP request. The following documentation
can be used to find more information. L<https://developer.github.com/v3/emojis>.

=head2 events

    $github->events;

The events method returns a new instance representative of the API
I<events> resource requested. This method accepts a list of path
segments which will be used in the HTTP request. The following documentation
can be used to find more information. L<https://developer.github.com/v3/activity/events>.

=head2 feeds

    $github->feeds;

The feeds method returns a new instance representative of the API
I<feeds> resource requested. This method accepts a list of path
segments which will be used in the HTTP request. The following documentation
can be used to find more information. L<https://developer.github.com/v3/activity/feeds>.

=head2 gists

    $github->gists;

The gists method returns a new instance representative of the API
I<gists> resource requested. This method accepts a list of path
segments which will be used in the HTTP request. The following documentation
can be used to find more information. L<https://developer.github.com/v3/gists>.

=head2 gitignore

    $github->gitignore;

The gitignore method returns a new instance representative of the API
I<gitignore> resource requested. This method accepts a list of path
segments which will be used in the HTTP request. The following documentation
can be used to find more information. L<https://developer.github.com/v3/gitignore>.

=head2 issues

    $github->issues;

The issues method returns a new instance representative of the API
I<issues> resource requested. This method accepts a list of path
segments which will be used in the HTTP request. The following documentation
can be used to find more information. L<https://developer.github.com/v3/issues>.

=head2 licenses

    $github->licenses;

The licenses method returns a new instance representative of the API
I<licenses> resource requested. This method accepts a list of path
segments which will be used in the HTTP request. The following documentation
can be used to find more information. L<https://developer.github.com/v3/licenses>.

=head2 markdown

    $github->markdown;

The markdown method returns a new instance representative of the API
I<markdown> resource requested. This method accepts a list of path
segments which will be used in the HTTP request. The following documentation
can be used to find more information. L<https://developer.github.com/v3/markdown>.

=head2 meta

    $github->meta;

The meta method returns a new instance representative of the API
I<meta> resource requested. This method accepts a list of path
segments which will be used in the HTTP request. The following documentation
can be used to find more information. L<https://developer.github.com/v3/meta>.

=head2 notifications

    $github->notifications;

The notifications method returns a new instance representative of the API
I<notifications> resource requested. This method accepts a list of path
segments which will be used in the HTTP request. The following documentation
can be used to find more information. L<https://developer.github.com/v3/activity/notifications>.

=head2 orgs

    $github->orgs;

The orgs method returns a new instance representative of the API
I<orgs> resource requested. This method accepts a list of path
segments which will be used in the HTTP request. The following documentation
can be used to find more information. L<https://developer.github.com/v3/orgs>.

=head2 rate_limit

    $github->rate_limit;

The rate_limit method returns a new instance representative of the API
I<rate_limit> resource requested. This method accepts a list of path
segments which will be used in the HTTP request. The following documentation
can be used to find more information. L<https://developer.github.com/v3/rate_limit>.

=head2 repos

    $github->repos;

The repos method returns a new instance representative of the API
I<repos> resource requested. This method accepts a list of path
segments which will be used in the HTTP request. The following documentation
can be used to find more information. L<https://developer.github.com/v3/repos>.

=head2 search

    $github->search;

The search method returns a new instance representative of the API
I<search> resource requested. This method accepts a list of path
segments which will be used in the HTTP request. The following documentation
can be used to find more information. L<https://developer.github.com/v3/search>.

=head2 users

    $github->users;

The users method returns a new instance representative of the API
I<users> resource requested. This method accepts a list of path
segments which will be used in the HTTP request. The following documentation
can be used to find more information. L<https://developer.github.com/v3/users>.

=head1 AUTHOR

Al Newkirk <anewkirk@ana.io>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Al Newkirk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
