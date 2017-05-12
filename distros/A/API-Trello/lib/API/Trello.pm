# ABSTRACT: Trello.com API Client
package API::Trello;

use Data::Object::Class;
use Data::Object::Signatures;

use Data::Object::Library qw(
    Str
);

extends 'API::Client';

our $VERSION = '0.06'; # VERSION

our $DEFAULT_URL = "https://api.trello.com";

# ATTRIBUTES

has key => (
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

has '+casing' => (
    default  => 'camelcase',
    required => 0,
);

has '+identifier' => (
    default  => 'API::Trello (Perl)',
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

    my $key        = $self->key;
    my $token      = $self->token;
    my $version    = $self->version;
    my $url        = $self->url;

    $url->path("/$version");
    $url->query(key => $key, $token ? (token => $token) : ());

    return $self;

};

# METHODS

method PREPARE ($ua, $tx, %args) {

    my $headers = $tx->req->headers;
    my $url     = $tx->req->url;

    # default headers
    $headers->header('Content-Type' => 'application/json');

}

method resource (@segments) {

    # build new resource instance
    my $instance = __PACKAGE__->new(
        debug      => $self->debug,
        fatal      => $self->fatal,
        retries    => $self->retries,
        timeout    => $self->timeout,
        user_agent => $self->user_agent,
        key        => $self->key,
        token      => $self->token,
        identifier => $self->identifier,
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

API::Trello - Trello.com API Client

=head1 VERSION

version 0.06

=head1 SYNOPSIS

    use API::Trello;

    my $trello = API::Trello->new(
        key        => 'KEY',
        token      => 'TOKEN',
        identifier => 'APPLICATION NAME',
    );

    $trello->debug(1);
    $trello->fatal(1);

    my $board = $trello->boards('4d5ea62fd76a');
    my $results = $board->fetch;

    # after some introspection

    $board->update( ... );

=head1 DESCRIPTION

This distribution provides an object-oriented thin-client library for
interacting with the Trello (L<http://trello.com>) API. For usage and
documentation information visit L<https://trello.com/docs/gettingstarted/index.html>.
API::Trello is derived from L<API::Client> and inherits all of it's
functionality. Please read the documentation for API::Client for more usage
information.

=head1 ATTRIBUTES

=head2 identifier

    $trello->identifier;
    $trello->identifier('IDENTIFIER');

The identifier attribute should be set to a string that identifies your application.

=head2 key

    $trello->key;
    $trello->key('KEY');

The key attribute should be set to the account holder's API key.

=head2 token

    $trello->token;
    $trello->token('TOKEN');

The token attribute should be set to the account holder's API access token.

=head2 identifier

    $trello->identifier;
    $trello->identifier('IDENTIFIER');

The identifier attribute should be set using a string to identify your app.

=head2 debug

    $trello->debug;
    $trello->debug(1);

The debug attribute if true prints HTTP requests and responses to standard out.

=head2 fatal

    $trello->fatal;
    $trello->fatal(1);

The fatal attribute if true promotes 4xx and 5xx server response codes to
exceptions, a L<API::Client::Exception> object.

=head2 retries

    $trello->retries;
    $trello->retries(10);

The retries attribute determines how many times an HTTP request should be
retried if a 4xx or 5xx response is received. This attribute defaults to 0.

=head2 timeout

    $trello->timeout;
    $trello->timeout(5);

The timeout attribute determines how long an HTTP connection should be kept
alive. This attribute defaults to 10.

=head2 url

    $trello->url;
    $trello->url(Mojo::URL->new('https://api.trello.com'));

The url attribute set the base/pre-configured URL object that will be used in
all HTTP requests. This attribute expects a L<Mojo::URL> object.

=head2 user_agent

    $trello->user_agent;
    $trello->user_agent(Mojo::UserAgent->new);

The user_agent attribute set the pre-configured UserAgent object that will be
used in all HTTP requests. This attribute expects a L<Mojo::UserAgent> object.

=head1 METHODS

=head2 action

    my $result = $trello->action($verb, %args);

    # e.g.

    $trello->action('head', %args);    # HEAD request
    $trello->action('options', %args); # OPTIONS request
    $trello->action('patch', %args);   # PATCH request

The action method issues a request to the API resource represented by the
object. The first parameter will be used as the HTTP request method. The
arguments, expected to be a list of key/value pairs, will be included in the
request if the key is either C<data> or C<query>.

=head2 create

    my $results = $trello->create(%args);

    # or

    $trello->POST(%args);

The create method issues a C<POST> request to the API resource represented by
the object. The arguments, expected to be a list of key/value pairs, will be
included in the request if the key is either C<data> or C<query>.

=head2 delete

    my $results = $trello->delete(%args);

    # or

    $trello->DELETE(%args);

The delete method issues a C<DELETE> request to the API resource represented by
the object. The arguments, expected to be a list of key/value pairs, will be
included in the request if the key is either C<data> or C<query>.

=head2 fetch

    my $results = $trello->fetch(%args);

    # or

    $trello->GET(%args);

The fetch method issues a C<GET> request to the API resource represented by the
object. The arguments, expected to be a list of key/value pairs, will be
included in the request if the key is either C<data> or C<query>.

=head2 update

    my $results = $trello->update(%args);

    # or

    $trello->PUT(%args);

The update method issues a C<PUT> request to the API resource represented by
the object. The arguments, expected to be a list of key/value pairs, will be
included in the request if the key is either C<data> or C<query>.

=head1 RESOURCES

=head2 actions

    $trello->actions;

The actions method returns a new instance representative of the API
I<actions> resource requested. This method accepts a list of path
segments which will be used in the HTTP request. The following documentation
can be used to find more information. L<https://trello.com/docs/api/action/index.html>.

=head2 batch

    $trello->batch;

The batch method returns a new instance representative of the API
I<batch> resource requested. This method accepts a list of path
segments which will be used in the HTTP request. The following documentation
can be used to find more information. L<https://trello.com/docs/api/batch/index.html>.

=head2 boards

    $trello->boards;

The boards method returns a new instance representative of the API
I<boards> resource requested. This method accepts a list of path
segments which will be used in the HTTP request. The following documentation
can be used to find more information. L<https://trello.com/docs/api/board/index.html>.

=head2 cards

    $trello->cards;

The cards method returns a new instance representative of the API
I<cards> resource requested. This method accepts a list of path
segments which will be used in the HTTP request. The following documentation
can be used to find more information. L<https://trello.com/docs/api/card/index.html>.

=head2 checklists

    $trello->checklists;

The checklists method returns a new instance representative of the API
I<checklists> resource requested. This method accepts a list of path
segments which will be used in the HTTP request. The following documentation
can be used to find more information. L<https://trello.com/docs/api/checklist/index.html>.

=head2 labels

    $trello->labels;

The labels method returns a new instance representative of the API
I<labels> resource requested. This method accepts a list of path
segments which will be used in the HTTP request. The following documentation
can be used to find more information. L<https://trello.com/docs/api/label/index.html>.

=head2 lists

    $trello->lists;

The lists method returns a new instance representative of the API
I<lists> resource requested. This method accepts a list of path
segments which will be used in the HTTP request. The following documentation
can be used to find more information. L<https://trello.com/docs/api/list/index.html>.

=head2 members

    $trello->members;

The members method returns a new instance representative of the API
I<members> resource requested. This method accepts a list of path
segments which will be used in the HTTP request. The following documentation
can be used to find more information. L<https://trello.com/docs/api/member/index.html>.

=head2 notifications

    $trello->notifications;

The notifications method returns a new instance representative of the API
I<notifications> resource requested. This method accepts a list of path
segments which will be used in the HTTP request. The following documentation
can be used to find more information. L<https://trello.com/docs/api/notification/index.html>.

=head2 organizations

    $trello->organizations;

The organizations method returns a new instance representative of the API
I<organizations> resource requested. This method accepts a list of path
segments which will be used in the HTTP request. The following documentation
can be used to find more information. L<https://trello.com/docs/api/organization/index.html>.

=head2 search

    $trello->search;

The search method returns a new instance representative of the API
I<search> resource requested. This method accepts a list of path
segments which will be used in the HTTP request. The following documentation
can be used to find more information. L<https://trello.com/docs/api/search/index.html>.

=head2 sessions

    $trello->sessions;

The sessions method returns a new instance representative of the API
I<sessions> resource requested. This method accepts a list of path
segments which will be used in the HTTP request. The following documentation
can be used to find more information. L<https://trello.com/docs/api/session/index.html>.

=head2 tokens

    $trello->tokens;

The tokens method returns a new instance representative of the API
I<tokens> resource requested. This method accepts a list of path
segments which will be used in the HTTP request. The following documentation
can be used to find more information. L<https://trello.com/docs/api/token/index.html>.

=head2 types

    $trello->types;

The types method returns a new instance representative of the API
I<types> resource requested. This method accepts a list of path
segments which will be used in the HTTP request. The following documentation
can be used to find more information. L<https://trello.com/docs/api/type/index.html>.

=head2 webhooks

    $trello->webhooks;

The webhooks method returns a new instance representative of the API
I<webhooks> resource requested. This method accepts a list of path
segments which will be used in the HTTP request. The following documentation
can be used to find more information. L<https://trello.com/docs/api/webhook/index.html>.

=head1 AUTHOR

Al Newkirk <anewkirk@ana.io>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Al Newkirk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
