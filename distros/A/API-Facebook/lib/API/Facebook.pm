# ABSTRACT: Facebook.com API Client
package API::Facebook;

use Data::Object::Class;
use Data::Object::Signatures;

use Data::Object::Library qw(
    Str
);

extends 'API::Client';

our $VERSION = '0.04'; # VERSION

our $DEFAULT_URL = "https://graph.facebook.com";

# ATTRIBUTES

has access_token => (
    is       => 'rw',
    isa      => Str,
    required => 1,
);

# DEFAULTS

has '+identifier' => (
    default  => 'API::Facebook (Perl)',
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
    $url->path("/v$version");

    return $self;

};

# METHODS

method PREPARE ($ua, $tx, %args) {

    my $headers = $tx->req->headers;
    my $url     = $tx->req->url;

    # default headers
    $headers->header('Content-Type' => 'application/json');

    # access token parameter
    $url->query->merge(access_token => $self->access_token) if $self->access_token;

}

method resource (@segments) {

    # build new resource instance
    my $instance = __PACKAGE__->new(
        access_token => $self->access_token,
        debug        => $self->debug,
        fatal        => $self->fatal,
        retries      => $self->retries,
        timeout      => $self->timeout,
        user_agent   => $self->user_agent,
        identifier   => $self->identifier,
        version      => $self->version,

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

API::Facebook - Facebook.com API Client

=head1 VERSION

version 0.04

=head1 SYNOPSIS

    use API::Facebook;

    my $facebook = API::Facebook->new(
        access_token => 'ACCESS_TOKEN',
        identifier   => 'IDENTIFIER',
    );

    $facebook->debug(1);
    $facebook->fatal(1);

    my $feed = $facebook->me('feed');
    my $results = $feed->fetch;

    # after some introspection

    $feed->update( ... );

=head1 DESCRIPTION

This distribution provides an object-oriented thin-client library for
interacting with the Facebook (L<http://facebook.com>) API. For usage and
documentation information visit L<https://developers.facebook.com/docs/graph-api>.
API::Facebook is derived from L<API::Client> and inherits all of it's
functionality. Please read the documentation for API::Client for more usage
information.

=head1 ATTRIBUTES

=head2 access_token

    $facebook->access_token;
    $facebook->access_token('ACCESS_TOKEN');

The access_token attribute should be set to an API access token associated with
your account.

=head2 identifier

    $facebook->identifier;
    $facebook->identifier('IDENTIFIER');

The identifier attribute should be set to a string that identifies your app.

=head2 debug

    $facebook->debug;
    $facebook->debug(1);

The debug attribute if true prints HTTP requests and responses to standard out.

=head2 fatal

    $facebook->fatal;
    $facebook->fatal(1);

The fatal attribute if true promotes 4xx and 5xx server response codes to
exceptions, a L<API::Client::Exception> object.

=head2 retries

    $facebook->retries;
    $facebook->retries(10);

The retries attribute determines how many times an HTTP request should be
retried if a 4xx or 5xx response is received. This attribute defaults to 1.

=head2 timeout

    $facebook->timeout;
    $facebook->timeout(5);

The timeout attribute determines how long an HTTP connection should be kept
alive. This attribute defaults to 10.

=head2 url

    $facebook->url;
    $facebook->url(Mojo::URL->new('https://graph.facebook.com'));

The url attribute set the base/pre-configured URL object that will be used in
all HTTP requests. This attribute expects a L<Mojo::URL> object.

=head2 user_agent

    $facebook->user_agent;
    $facebook->user_agent(Mojo::UserAgent->new);

The user_agent attribute set the pre-configured UserAgent object that will be
used in all HTTP requests. This attribute expects a L<Mojo::UserAgent> object.

=head1 METHODS

=head2 action

    my $result = $facebook->action($verb, %args);

    # e.g.

    $facebook->action('head', %args);    # HEAD request
    $facebook->action('options', %args); # OPTIONS request
    $facebook->action('patch', %args);   # PATCH request

The action method issues a request to the API resource represented by the
object. The first parameter will be used as the HTTP request method. The
arguments, expected to be a list of key/value pairs, will be included in the
request if the key is either C<data> or C<query>.

=head2 create

    my $results = $facebook->create(%args);

    # or

    $facebook->POST(%args);

The create method issues a C<POST> request to the API resource represented by
the object. The arguments, expected to be a list of key/value pairs, will be
included in the request if the key is either C<data> or C<query>.

=head2 delete

    my $results = $facebook->delete(%args);

    # or

    $facebook->DELETE(%args);

The delete method issues a C<DELETE> request to the API resource represented by
the object. The arguments, expected to be a list of key/value pairs, will be
included in the request if the key is either C<data> or C<query>.

=head2 fetch

    my $results = $facebook->fetch(%args);

    # or

    $facebook->GET(%args);

The fetch method issues a C<GET> request to the API resource represented by the
object. The arguments, expected to be a list of key/value pairs, will be
included in the request if the key is either C<data> or C<query>.

=head2 update

    my $results = $facebook->update(%args);

    # or

    $facebook->PUT(%args);

The update method issues a C<PUT> request to the API resource represented by
the object. The arguments, expected to be a list of key/value pairs, will be
included in the request if the key is either C<data> or C<query>.

=head1 RESOURCES

=head2 achievement

    $facebook->resource(param('achievement'));

The achievement resource returns a new instance representative of the API
resource requested. This method accepts a list of path segments which will be
used in the HTTP request. The following documentation can be used to find more
information. L<https://developers.facebook.com/docs/graph-api/reference/achievement>.

=head2 achievement_type

    $facebook->resource(param('achievement_type'));

The achievement_type resource returns a new instance representative of the API
resource requested. This method accepts a list of path segments which will be
used in the HTTP request. The following documentation can be used to find more
information. L<https://developers.facebook.com/docs/graph-api/reference/achievement_type>.

=head2 ad_campaign

    $facebook->resource(param('ad-campaign'));

The ad_campaign resource returns a new instance representative of the API
resource requested. This method accepts a list of path segments which will be
used in the HTTP request. The following documentation can be used to find more
information. L<https://developers.facebook.com/docs/marketing-api/reference/ad-campaign>.

=head2 ad_campaign_group

    $facebook->resource(param('ad-campaign-group'));

The ad_campaign_group resource returns a new instance representative of the API
resource requested. This method accepts a list of path segments which will be
used in the HTTP request. The following documentation can be used to find more
information. L<https://developers.facebook.com/docs/marketing-api/reference/ad-campaign-group>.

=head2 ad_image

    $facebook->resource(param('ad-image'));

The ad_image resource returns a new instance representative of the API
resource requested. This method accepts a list of path segments which will be
used in the HTTP request. The following documentation can be used to find more
information. L<https://developers.facebook.com/docs/marketing-api/reference/ad-image>.

=head2 ad_label

    $facebook->resource(param('ad-label'));

The ad_label resource returns a new instance representative of the API
resource requested. This method accepts a list of path segments which will be
used in the HTTP request. The following documentation can be used to find more
information. L<https://developers.facebook.com/docs/marketing-api/reference/ad-label>.

=head2 app_request

    $facebook->resource(param('app-request'));

The app_request resource returns a new instance representative of the API
resource requested. This method accepts a list of path segments which will be
used in the HTTP request. The following documentation can be used to find more
information. L<https://developers.facebook.com/docs/graph-api/reference/app-request>.

=head2 application

    $facebook->resource(param('application'));

The application resource returns a new instance representative of the API
resource requested. This method accepts a list of path segments which will be
used in the HTTP request. The following documentation can be used to find more
information. L<https://developers.facebook.com/docs/graph-api/reference/application>.

=head2 application_context

    $facebook->resource(param('application-context'));

The application_context resource returns a new instance representative of the API
resource requested. This method accepts a list of path segments which will be
used in the HTTP request. The following documentation can be used to find more
information. L<https://developers.facebook.com/docs/graph-api/reference/application-context>.

=head2 friend_list

    $facebook->resource(param('friend-list'));

The friend_list resource returns a new instance representative of the API
resource requested. This method accepts a list of path segments which will be
used in the HTTP request. The following documentation can be used to find more
information. L<https://developers.facebook.com/docs/graph-api/reference/friend-list>.

=head2 hashtag

    $facebook->resource(param('hashtag'));

The hashtag resource returns a new instance representative of the API
resource requested. This method accepts a list of path segments which will be
used in the HTTP request. The following documentation can be used to find more
information. L<https://developers.facebook.com/docs/graph-api/reference/hashtag>.

=head2 life_event

    $facebook->resource(param('life-event'));

The life_event resource returns a new instance representative of the API
resource requested. This method accepts a list of path segments which will be
used in the HTTP request. The following documentation can be used to find more
information. L<https://developers.facebook.com/docs/graph-api/reference/life-event>.

=head2 mailing_address

    $facebook->resource(param('mailing-address'));

The mailing_address resource returns a new instance representative of the API
resource requested. This method accepts a list of path segments which will be
used in the HTTP request. The following documentation can be used to find more
information. L<https://developers.facebook.com/docs/graph-api/reference/mailing-address>.

=head2 offsite_pixel

    $facebook->resource(param('offsite-pixel'));

The offsite_pixel resource returns a new instance representative of the API
resource requested. This method accepts a list of path segments which will be
used in the HTTP request. The following documentation can be used to find more
information. L<https://developers.facebook.com/docs/graph-api/reference/offsite-pixel>.

=head2 open_graph_context

    $facebook->resource(param('open-graph-context'));

The open_graph_context resource returns a new instance representative of the API
resource requested. This method accepts a list of path segments which will be
used in the HTTP request. The following documentation can be used to find more
information. L<https://developers.facebook.com/docs/graph-api/reference/open-graph-context>.

=head2 page

    $facebook->resource(param('page'));

The page resource returns a new instance representative of the API
resource requested. This method accepts a list of path segments which will be
used in the HTTP request. The following documentation can be used to find more
information. L<https://developers.facebook.com/docs/graph-api/reference/page>.

=head2 photo

    $facebook->resource(param('photo'));

The photo resource returns a new instance representative of the API
resource requested. This method accepts a list of path segments which will be
used in the HTTP request. The following documentation can be used to find more
information. L<https://developers.facebook.com/docs/graph-api/reference/photo>.

=head2 place_tag

    $facebook->resource(param('place-tag'));

The place_tag resource returns a new instance representative of the API
resource requested. This method accepts a list of path segments which will be
used in the HTTP request. The following documentation can be used to find more
information. L<https://developers.facebook.com/docs/graph-api/reference/place-tag>.

=head2 product_catalog

    $facebook->resource(param('product-catalog'));

The product_catalog resource returns a new instance representative of the API
resource requested. This method accepts a list of path segments which will be
used in the HTTP request. The following documentation can be used to find more
information. L<https://developers.facebook.com/docs/marketing-api/reference/product-catalog>.

=head2 product_feed

    $facebook->resource(param('product-feed'));

The product_feed resource returns a new instance representative of the API
resource requested. This method accepts a list of path segments which will be
used in the HTTP request. The following documentation can be used to find more
information. L<https://developers.facebook.com/docs/graph-api/reference/product-feed>.

=head2 product_feed_upload

    $facebook->resource(param('product-feed-upload'));

The product_feed_upload resource returns a new instance representative of the API
resource requested. This method accepts a list of path segments which will be
used in the HTTP request. The following documentation can be used to find more
information. L<https://developers.facebook.com/docs/graph-api/reference/product-feed-upload>.

=head2 product_feed_upload_error

    $facebook->resource(param('product-feed-upload-error'));

The product_feed_upload_error resource returns a new instance representative of the API
resource requested. This method accepts a list of path segments which will be
used in the HTTP request. The following documentation can be used to find more
information. L<https://developers.facebook.com/docs/graph-api/reference/product-feed-upload-error>.

=head2 product_group

    $facebook->resource(param('product-group'));

The product_group resource returns a new instance representative of the API
resource requested. This method accepts a list of path segments which will be
used in the HTTP request. The following documentation can be used to find more
information. L<https://developers.facebook.com/docs/graph-api/reference/product-group>.

=head2 product_item

    $facebook->resource(param('product-item'));

The product_item resource returns a new instance representative of the API
resource requested. This method accepts a list of path segments which will be
used in the HTTP request. The following documentation can be used to find more
information. L<https://developers.facebook.com/docs/graph-api/reference/product-item>.

=head2 product_set

    $facebook->resource(param('product-set'));

The product_set resource returns a new instance representative of the API
resource requested. This method accepts a list of path segments which will be
used in the HTTP request. The following documentation can be used to find more
information. L<https://developers.facebook.com/docs/graph-api/reference/product-set>.

=head2 promotion_info

    $facebook->resource(param('promotion-info'));

The promotion_info resource returns a new instance representative of the API
resource requested. This method accepts a list of path segments which will be
used in the HTTP request. The following documentation can be used to find more
information. L<https://developers.facebook.com/docs/graph-api/reference/promotion-info>.

=head2 user

    $facebook->resource(param('user'));

The user resource returns a new instance representative of the API
resource requested. This method accepts a list of path segments which will be
used in the HTTP request. The following documentation can be used to find more
information. L<https://developers.facebook.com/docs/graph-api/reference/user>.

=head2 user_context

    $facebook->resource(param('user-context'));

The user_context resource returns a new instance representative of the API
resource requested. This method accepts a list of path segments which will be
used in the HTTP request. The following documentation can be used to find more
information. L<https://developers.facebook.com/docs/graph-api/reference/user-context>.

=head2 video

    $facebook->resource(param('video'));

The video resource returns a new instance representative of the API
resource requested. This method accepts a list of path segments which will be
used in the HTTP request. The following documentation can be used to find more
information. L<https://developers.facebook.com/docs/graph-api/reference/video>.

=head2 video_broadcast

    $facebook->resource(param('video-broadcast'));

The video_broadcast resource returns a new instance representative of the API
resource requested. This method accepts a list of path segments which will be
used in the HTTP request. The following documentation can be used to find more
information. L<https://developers.facebook.com/docs/graph-api/reference/video-broadcast>.

=head2 video_list

    $facebook->resource(param('video-list'));

The video_list resource returns a new instance representative of the API
resource requested. This method accepts a list of path segments which will be
used in the HTTP request. The following documentation can be used to find more
information. L<https://developers.facebook.com/docs/graph-api/reference/video-list>.

=head1 AUTHOR

Al Newkirk <anewkirk@ana.io>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Al Newkirk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
