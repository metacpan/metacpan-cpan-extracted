# ABSTRACT: Twitter.com API Client
package API::Twitter;

use Data::Object::Class;
use Data::Object::Signatures;

use Data::Object::Library qw(
    Str
);

use Net::OAuth ();

extends 'API::Client';

our $VERSION = '0.05'; # VERSION

our $DEFAULT_URL = "https://api.twitter.com";

$Net::OAuth::PROTOCOL_VERSION = Net::OAuth::PROTOCOL_VERSION_1_0A;

our $VERSION = '0.05'; # VERSION

# ATTRIBUTES

has consumer_key => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has consumer_secret => (
    is       => 'rw',
    isa      => Str,
    required => 1,
);

has access_token => (
    is       => 'rw',
    isa      => Str,
    required => 0,
);

has access_token_secret => (
    is       => 'rw',
    isa      => Str,
    required => 0,
);

has oauth_type => (
    is       => 'rw',
    isa      => Str,
    default  => 'protected resource',
    required => 0,
);

# DEFAULTS

has '+identifier' => (
    default  => 'API::Twitter (Perl)',
    required => 0,
);

has '+url' => (
    default  => $DEFAULT_URL,
    required => 0,
);

has '+version' => (
    default  => 1.1,
    required => 0,
);

# CONSTRUCTION

after BUILD => method {

    my $identifier = $self->identifier;
    my $version    = $self->version;
    my $agent      = $self->user_agent;
    my $url        = $self->url;

    $agent->transactor->name($identifier);

    $url->path("/$version");

    return $self;

};

# METHODS

method PREPARE ($ua, $tx, %args) {

    my $req     = $tx->req;
    my $headers = $req->headers;
    my $params  = $req->params->to_hash;
    my $url     = $req->url;

    # default headers
    $headers->header('Content-Type' => 'application/json');

    # append path suffix
    $url->path("@{[$url->path]}.json") if $url->path !~ /\.json$/;

    # oauth data
    my $consumer_key        = $self->consumer_key;
    my $consumer_secret     = $self->consumer_secret;
    my $access_token        = $self->access_token;
    my $access_token_secret = $self->access_token_secret;

    # oauth variables
    my $oauth_consumer_key     = $consumer_key;
    my $oauth_nonce            = Digest::SHA::sha1_base64(time . $$ . rand);
    my $oauth_signature_method = 'HMAC-SHA1',
    my $oauth_timestamp        = time,
    my $oauth_token            = $access_token,
    my $oauth_version          = '1.0';

    # oauth object
    my $base  = $url->clone; $base->query(undef);
    my $oauth = Net::OAuth->request($self->oauth_type)->new(%$params,
        version          => '1.0',
        consumer_key     => $consumer_key,
        consumer_secret  => $consumer_secret,
        request_method   => uc($req->method),
        request_url      => $base,
        signature_method => 'HMAC-SHA1',
        timestamp        => time,
        token            => $access_token,
        token_secret     => $access_token_secret,
        nonce            => Digest::SHA::sha1_base64(time . $$ . rand),
    );

    # oauth signature
    $oauth->sign;

    # authorization header
    $headers->header('Authorization' => $oauth->to_authorization_header);

}

method resource (@segments) {

    # build new resource instance
    my $instance = __PACKAGE__->new(
        debug               => $self->debug,
        fatal               => $self->fatal,
        retries             => $self->retries,
        timeout             => $self->timeout,
        user_agent          => $self->user_agent,
        identifier          => $self->identifier,
        version             => $self->version,
        access_token        => $self->access_token,
        access_token_secret => $self->access_token_secret,
        consumer_key        => $self->consumer_key,
        consumer_secret     => $self->consumer_secret,
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

API::Twitter - Twitter.com API Client

=head1 VERSION

version 0.05

=head1 SYNOPSIS

    use API::Twitter;

    my $twitter = API::Twitter->new(
        consumer_key        => 'CONSUMER_KEY',
        consumer_secret     => 'CONSUMER_SECRET',
        access_token        => 'ACCESS_TOKEN',
        access_token_secret => 'ACCESS_TOKEN_SECRET',
        identifier          => 'IDENTIFIER',
    );

    $twitter->debug(1);
    $twitter->fatal(1);

    my $user = $twitter->users('lookup');
    my $results = $user->fetch;

    # after some introspection

    $user->update( ... );

=head1 DESCRIPTION

This distribution provides an object-oriented thin-client library for
interacting with the Twitter (L<http://twitter.com>) API. For usage and
documentation information visit L<https://dev.twitter.com/rest/public>.
API::Twitter is derived from L<API::Client> and inherits all of it's
functionality. Please read the documentation for API::Client for more
usage information.

=head1 ATTRIBUTES

=head2 access_token

    $twitter->access_token;
    $twitter->access_token('ACCESS_TOKEN');

The access_token attribute should be set to an API access_token associated with
your account.

=head2 access_token_secret

    $twitter->access_token_secret;
    $twitter->access_token_secret('ACCESS_TOKEN_SECRET');

The access_token_secret attribute should be set to an API access_token_secret
associated with your account.

=head2 consumer_key

    $twitter->consumer_key;
    $twitter->consumer_key('CONSUMER_KEY');

The consumer_key attribute should be set to an API consumer_key associated with
your account.

=head2 consumer_secret

    $twitter->consumer_secret;
    $twitter->consumer_secret('CONSUMER_SECRET');

The consumer_secret attribute should be set to an API consumer_secret
associated with your account.

=head2 identifier

    $twitter->identifier;
    $twitter->identifier('IDENTIFIER');

The identifier attribute should be set to a string that identifies your app.

=head2 debug

    $twitter->debug;
    $twitter->debug(1);

The debug attribute if true prints HTTP requests and responses to standard out.

=head2 fatal

    $twitter->fatal;
    $twitter->fatal(1);

The fatal attribute if true promotes 4xx and 5xx server response codes to
exceptions, a L<API::Client::Exception> object.

=head2 retries

    $twitter->retries;
    $twitter->retries(10);

The retries attribute determines how many times an HTTP request should be
retried if a 4xx or 5xx response is received. This attribute defaults to 1.

=head2 timeout

    $twitter->timeout;
    $twitter->timeout(5);

The timeout attribute determines how long an HTTP connection should be kept
alive. This attribute defaults to 10.

=head2 url

    $twitter->url;
    $twitter->url(Mojo::URL->new('https://api.twitter.com'));

The url attribute set the base/pre-configured URL object that will be used in
all HTTP requests. This attribute expects a L<Mojo::URL> object.

=head2 user_agent

    $twitter->user_agent;
    $twitter->user_agent(Mojo::UserAgent->new);

The user_agent attribute set the pre-configured UserAgent object that will be
used in all HTTP requests. This attribute expects a L<Mojo::UserAgent> object.

=head1 METHODS

=head2 action

    my $result = $twitter->action($verb, %args);

    # e.g.

    $twitter->action('head', %args);    # HEAD request
    $twitter->action('options', %args); # OPTIONS request
    $twitter->action('patch', %args);   # PATCH request

The action method issues a request to the API resource represented by the
object. The first parameter will be used as the HTTP request method. The
arguments, expected to be a list of key/value pairs, will be included in the
request if the key is either C<data> or C<query>.

=head2 create

    my $results = $twitter->create(%args);

    # or

    $twitter->POST(%args);

The create method issues a C<POST> request to the API resource represented by
the object. The arguments, expected to be a list of key/value pairs, will be
included in the request if the key is either C<data> or C<query>.

=head2 delete

    my $results = $twitter->delete(%args);

    # or

    $twitter->DELETE(%args);

The delete method issues a C<DELETE> request to the API resource represented by
the object. The arguments, expected to be a list of key/value pairs, will be
included in the request if the key is either C<data> or C<query>.

=head2 fetch

    my $results = $twitter->fetch(%args);

    # or

    $twitter->GET(%args);

The fetch method issues a C<GET> request to the API resource represented by the
object. The arguments, expected to be a list of key/value pairs, will be
included in the request if the key is either C<data> or C<query>.

=head2 update

    my $results = $twitter->update(%args);

    # or

    $twitter->PUT(%args);

The update method issues a C<PUT> request to the API resource represented by
the object. The arguments, expected to be a list of key/value pairs, will be
included in the request if the key is either C<data> or C<query>.

=head1 RESOURCES

=head2 account

    $twitter->account;

The account method returns a new instance representative of the API
resource requested. This method accepts a list of path segments which will be
used in the HTTP request. The following documentation can be used to find more
information. L<https://dev.twitter.com/rest/public#account>.

=head2 application

    $twitter->application;

The application method returns a new instance representative of the API
resource requested. This method accepts a list of path segments which will be
used in the HTTP request. The following documentation can be used to find more
information. L<https://dev.twitter.com/rest/public#application>.

=head2 blocks

    $twitter->blocks;

The blocks method returns a new instance representative of the API
resource requested. This method accepts a list of path segments which will be
used in the HTTP request. The following documentation can be used to find more
information. L<https://dev.twitter.com/rest/public#blocks>.

=head2 direct_messages

    $twitter->direct_messages;

The direct_messages method returns a new instance representative of the API
resource requested. This method accepts a list of path segments which will be
used in the HTTP request. The following documentation can be used to find more
information. L<https://dev.twitter.com/rest/public#direct_messages>.

=head2 favorites

    $twitter->favorites;

The favorites method returns a new instance representative of the API
resource requested. This method accepts a list of path segments which will be
used in the HTTP request. The following documentation can be used to find more
information. L<https://dev.twitter.com/rest/public#favorites>.

=head2 followers

    $twitter->followers;

The followers method returns a new instance representative of the API
resource requested. This method accepts a list of path segments which will be
used in the HTTP request. The following documentation can be used to find more
information. L<https://dev.twitter.com/rest/public#followers>.

=head2 friends

    $twitter->friends;

The friends method returns a new instance representative of the API
resource requested. This method accepts a list of path segments which will be
used in the HTTP request. The following documentation can be used to find more
information. L<https://dev.twitter.com/rest/public#friends>.

=head2 friendships

    $twitter->friendships;

The friendships method returns a new instance representative of the API
resource requested. This method accepts a list of path segments which will be
used in the HTTP request. The following documentation can be used to find more
information. L<https://dev.twitter.com/rest/public#friendships>.

=head2 geo

    $twitter->geo;

The geo method returns a new instance representative of the API
resource requested. This method accepts a list of path segments which will be
used in the HTTP request. The following documentation can be used to find more
information. L<https://dev.twitter.com/rest/public#geo>.

=head2 help

    $twitter->help;

The help method returns a new instance representative of the API
resource requested. This method accepts a list of path segments which will be
used in the HTTP request. The following documentation can be used to find more
information. L<https://dev.twitter.com/rest/public#help>.

=head2 lists

    $twitter->lists;

The lists method returns a new instance representative of the API
resource requested. This method accepts a list of path segments which will be
used in the HTTP request. The following documentation can be used to find more
information. L<https://dev.twitter.com/rest/public#lists>.

=head2 media

    $twitter->media;

The media method returns a new instance representative of the API
resource requested. This method accepts a list of path segments which will be
used in the HTTP request. The following documentation can be used to find more
information. L<https://dev.twitter.com/rest/public#media>.

=head2 mutes

    $twitter->mutes;

The mutes method returns a new instance representative of the API
resource requested. This method accepts a list of path segments which will be
used in the HTTP request. The following documentation can be used to find more
information. L<https://dev.twitter.com/rest/public#mutes>.

=head2 saved_searches

    $twitter->saved_searches;

The saved_searches method returns a new instance representative of the API
resource requested. This method accepts a list of path segments which will be
used in the HTTP request. The following documentation can be used to find more
information. L<https://dev.twitter.com/rest/public#saved_searches>.

=head2 search

    $twitter->search;

The search method returns a new instance representative of the API
resource requested. This method accepts a list of path segments which will be
used in the HTTP request. The following documentation can be used to find more
information. L<https://dev.twitter.com/rest/public#search>.

=head2 statuses

    $twitter->statuses;

The statuses method returns a new instance representative of the API
resource requested. This method accepts a list of path segments which will be
used in the HTTP request. The following documentation can be used to find more
information. L<https://dev.twitter.com/rest/public#statuses>.

=head2 trends

    $twitter->trends;

The trends method returns a new instance representative of the API
resource requested. This method accepts a list of path segments which will be
used in the HTTP request. The following documentation can be used to find more
information. L<https://dev.twitter.com/rest/public#trends>.

=head2 users

    $twitter->users;

The users method returns a new instance representative of the API
resource requested. This method accepts a list of path segments which will be
used in the HTTP request. The following documentation can be used to find more
information. L<https://dev.twitter.com/rest/public#users>.

=head1 AUTHOR

Al Newkirk <anewkirk@ana.io>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Al Newkirk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
