package Business::GoCardless::Client;

=head1 NAME

Business::GoCardless::Client

=head1 DESCRIPTION

This is a class for the lower level requests to the gocardless API. generally
there is nothing you should be doing with this.

=cut

use strict;
use warnings;
use feature qw/ say /;

use Moo;
with 'Business::GoCardless::Utils';

use Business::GoCardless::Exception;
use Business::GoCardless::Bill;
use Business::GoCardless::Merchant;
use Business::GoCardless::Payout;
use Business::GoCardless::RedirectFlow;
use Business::GoCardless::Subscription;

use Carp qw/ confess /;
use POSIX qw/ strftime /;
use MIME::Base64 qw/ encode_base64 /;
use LWP::UserAgent;
use HTTP::Date ();
use Time::HiRes ();
use UUID 0.34 ();
use JSON ();

=head1 ATTRIBUTES

=head2 token

Your gocardless API token, this attribute is required.

=head2 base_url

The gocardless API URL, defaults to $ENV{GOCARDLESS_URL} or
https://gocardless.com.

=head2 api_path

The gocardless API path, defaults to /api/v1.

=head2 app_id

Your gocardless app identifier, defaults to $ENV{GOCARDLESS_APP_ID} or will
exit if not set.

=head2 app_secret

Your gocardless app secret, defaults to $ENV{GOCARDLESS_APP_SECRET} or will
exit if not set.

=head2 webhook_secret

Your gocardless webhook secret, defaults to $ENV{GOCARDLESS_WEBHOOK_SECRET} or will
exit if not set.

This can also be an arrayref of secrets, in which case a webhook is valid if its
signature matches any of them. This allows you to rotate your webhook secret, or
receive webhooks from more than one webhook endpoint, without rejecting webhooks:

    webhook_secret => [ $new_secret,$old_secret ],

=head2 merchant_id

Your gocardless merchant identifier, defaults to $ENV{GOCARDLESS_MERCHANT_ID}
or will exit if not set.

=head2 user_agent

The user agent string used in requests to the gocardless API, defaults to
business-gocardless/perl/v . $version_of_this_library . - . $api_version

The following attributes only apply to the Pro (v2) API:

=head2 max_retries

The number of times to retry a request that failed due to a network error, a
server error (500, 502, 503, 504), or being rate limited (429). Defaults to 3,
set to 0 to disable retries. Retry delays back off exponentially from 0.5s.

Requests are only retried if it is safe to do so: GET, PUT, and DELETE requests,
and POST requests that create a resource (as these have an idempotency key, see
L</IDEMPOTENCY KEYS>). POST requests to actions (e.g. cancelling a payment) are
only retried if they were rate limited, as the request will not have been
processed by GoCardless in that case.

=head2 max_retry_wait

When rate limited, requests are retried after the time given in the
C<ratelimit-reset> response header. If that is more than this many seconds away
the request is not retried and an exception is thrown. Defaults to 60.

=head2 raise_on_idempotency_conflict

If a create request gets an C<idempotent_creation_conflict> error, which means a
resource has already been created with the idempotency key, then by default the
existing resource is fetched and returned. Set this to true to throw an exception
instead, you can get the ID of the existing resource with the exception's
L<Business::GoCardless::Exception/conflicting_resource_id> method.

=head2 rate_limit

A hashref of the rate limit details from the most recent response from the API,
or undef if no request has been made yet:

    my $rate_limit = $Client->rate_limit;

    # {
    #     limit     => 1000,
    #     remaining => 999,
    #     reset     => 'Thu, 03 May 2018 16:00:00 GMT', # as sent by gocardless
    #     reset_at  => 1525363200,                     # reset as epoch seconds
    # }

=cut

has api_version => (
    is       => 'ro',
    required => 0,
    lazy     => 1,
    default  => sub { $ENV{GOCARDLESS_API_VERSION} // 1 },
);

has token => (
    is       => 'ro',
    required => 1,
);

has base_url => (
    is       => 'ro',
    required => 0,
    default  => sub {
        my ( $self ) = @_;

        if ( my $url = $ENV{GOCARDLESS_URL} ) {
            return $url;
        } else {
            return $self->api_version == 1
                ? 'https://gocardless.com'
                : 'https://api.gocardless.com';
        }
    },
);

has api_path => (
    is       => 'ro',
    required => 0,
    lazy     => 1,
    default  => sub {
        my ( $self ) = @_;

        if ( $self->api_version == 1 ) {
            return "/api/v" . $self->api_version;
        } else {
            return '';
        }
    },
);

has app_id => (
    is       => 'ro',
    required => 0,
    lazy     => 1,
    default  => sub {
        return undef if shift->api_version > 1;
        $ENV{'GOCARDLESS_APP_ID'}
            or confess( "Missing required argument: app_id" );
    }
);

has app_secret => (
    is       => 'ro',
    required => 0,
    lazy     => 1,
    default  => sub {
        return undef if shift->api_version > 1;
        $ENV{'GOCARDLESS_APP_SECRET'}
            or confess( "Missing required argument: app_secret" );
    }
);

has webhook_secret => (
    is       => 'ro',
    required => 0,
    lazy     => 1,
    default  => sub {
        $ENV{'GOCARDLESS_WEBHOOK_SECRET'}
            or confess( "Missing required argument: webhook_secret" );
    }
);

has merchant_id => (
    is       => 'ro',
    required => 0,
    lazy     => 1,
    default  => sub {
        my ( $self ) = @_;
        return undef if $self->api_version > 1;
        $ENV{'GOCARDLESS_MERCHANT_ID'}
            or confess( "Missing required argument: merchant_id" );
    }
);

has user_agent => (
    is      => 'ro',
    default => sub {
        my ( $self ) = @_;
        # maybe want more info in here, version of perl, platform, and such
        require Business::GoCardless;
        return "business-gocardless/perl/v"
            . $Business::GoCardless::VERSION
            . "-" . $self->api_version
        ;
    }
);

has max_retries => (
    is      => 'ro',
    default => sub { 3 },
);

has max_retry_wait => (
    is      => 'ro',
    default => sub { 60 },
);

has raise_on_idempotency_conflict => (
    is      => 'ro',
    default => sub { 0 },
);

has rate_limit => (
    is       => 'rw',
    required => 0,
);

# making these methods "private" to prevent confusion with the
# public methods of the same name in Business::GoCardless

sub _new_bill_url {
    my ( $self,$params ) = @_;
    return $self->_new_limit_url( 'bill',$params );
}

sub _new_pre_authorization_url {
    my ( $self,$params ) = @_;
    return $self->_new_limit_url( 'pre_authorization',$params );
}

sub _new_subscription_url {
    my ( $self,$params ) = @_;
    return $self->_new_limit_url( 'subscription',$params );
}

sub _new_limit_url {
    my ( $self,$type,$limit_params ) = @_;

    $limit_params->{merchant_id} = $self->merchant_id;

    my $params = {
        nonce     => $self->generate_nonce,
        timestamp => strftime( "%Y-%m-%dT%H:%M:%SZ",gmtime ),
        client_id => $self->app_id,
        ( map { ( $limit_params->{$_}
            ? ( $_ => delete( $limit_params->{$_} ) ) : ()
        ) } qw/ redirect_uri cancel_uri cancel_uri state / ),
        $type     => $limit_params,
    };

    $params->{signature} = $self->sign_params( $params,$self->app_secret );

    return sprintf(
        "%s/connect/%ss/new?%s",
        $self->base_url,
        $type,
        $self->normalize_params( $params )
    );
}

sub _new_redirect_flow_url {
    my ( $self,$params ) = @_;

    my $data = $self->api_post(
        '/redirect_flows',
        { redirect_flows => { %{ $params } } },
    );

    my $RedirectFlow = Business::GoCardless::RedirectFlow->new(
        client => $self,
        %{ $data->{redirect_flows} }
    );

    return $RedirectFlow->redirect_url;
}

sub _confirm_redirect_flow {
    my ( $self,$redirect_flow_id,$session_token ) = @_;

    # first find the original session token
    my $RedirectFlow = Business::GoCardless::RedirectFlow->new(
        client => $self,
        id => $redirect_flow_id,
    );

    $RedirectFlow->find_with_client( 'redirect_flows' );

    # only the session that started the redirect flow may confirm it
    if (
        ! length( $session_token // '' )
        || ( $RedirectFlow->session_token // '' ) ne $session_token
    ) {
        Business::GoCardless::Exception->throw({
            message => "session_token does not match redirect flow $redirect_flow_id",
        });
    }

    # redirect flows backed by a billing request are completed by gocardless
    # when the billing request is fulfilled, and trying to complete them again
    # is an error, so if we already have a mandate there's nothing left to do
    return $RedirectFlow if ( $RedirectFlow->links // {} )->{mandate};

    # now confirm the redirect flow
    my $data = $self->api_post(
        "/redirect_flows/$redirect_flow_id/actions/complete",
        { data => { session_token => $RedirectFlow->session_token } },
    );

    $RedirectFlow = Business::GoCardless::RedirectFlow->new(
        client => $self,
        %{ $data->{redirect_flows} }
    );

    return $RedirectFlow;
}

sub _confirm_resource {
    my ( $self,$params ) = @_;

    if ( ! $self->signature_valid( $params,$self->app_secret ) ) {
        Business::GoCardless::Exception->throw({
            message => "Invalid signature for confirm_resource"
        });
    }

    my $data = {
        resource_id   => $params->{resource_id},
        resource_type => $params->{resource_type},
    };

    my $credentials = encode_base64( $self->app_id . ':' . $self->app_secret );
    $credentials    =~ s/\s//g;

    my $ua = LWP::UserAgent->new;
    $ua->agent( $self->user_agent );

    my $req = HTTP::Request->new(
        POST => join( '/',$self->base_url . $self->api_path,'confirm' )
    );

    $req->header( 'Authorization' => "Basic $credentials" );
    $req->header( 'Accept' => 'application/json' );

    $req->content_type( 'application/x-www-form-urlencoded' );
    $req->content( $self->normalize_params( $data ) );

    my $res = $ua->request( $req );

    if ( $res->is_success ) {
        
        my $class_suffix = ucfirst( $params->{resource_type} );
        $class_suffix    =~ s/_([A-z])/uc($1)/ge;
        my $class = "Business::GoCardless::$class_suffix";
        my $obj   = $class->new(
            client => $self,
            id     => $params->{resource_id}
        );
        return $obj->find_with_client;
    }
    else {
        Business::GoCardless::Exception->throw({
            message  => $res->content,
            code     => $res->code,
            response => $res->status_line,
        });
    }
}

=head1 METHODS

    api_get
    api_post
    api_put
    api_delete

Make a request to the gocardless API:

    my $data = $Client->api_get( '/merchants/123ABCD/bills',\%params );

In list context returns the links and pagination headers:

    my ( $data,$links,$info ) = $Client->api_get( ... );

All of the methods take an optional hashref of additional headers to send with
the request as the third argument:

    my $data = $Client->api_post(
        '/payments',
        { payments => { ... } },
        { 'Idempotency-Key' => $your_idempotency_key },
    );

Failed requests will throw a L<Business::GoCardless::Exception>, and may be
retried before doing so (see L</max_retries>).

=head1 IDEMPOTENCY KEYS

When using the Pro (v2) API all requests that create a resource (POST requests
other than to actions) are sent with an C<Idempotency-Key> header, so that they
can be safely retried without creating duplicate resources (payments, etc). A
random key is generated for each request, or you can pass your own as shown
above if you want to make sure the same resource isn't created across separate
calls (for example on resubmission of a form). See
L<https://developer.gocardless.com/api-reference/#making-requests-idempotency-keys>
and L</raise_on_idempotency_conflict>.

=cut

sub api_get {
    my ( $self,$path,$params,$headers ) = @_;
    return $self->_api_request( 'GET',$path,$params,$headers );
}

sub api_post {
    my ( $self,$path,$params,$headers ) = @_;
    return $self->_api_request( 'POST',$path,$params,$headers );
}

sub api_put {
    my ( $self,$path,$params,$headers ) = @_;
    return $self->_api_request( 'PUT',$path,$params,$headers );
}

sub api_delete {
    my ( $self,$path,$params,$headers ) = @_;
    return $self->_api_request( 'DELETE',$path,$params,$headers );
}

sub _api_request {
    my ( $self,$method,$path,$params,$headers ) = @_;

    $headers = { %{ $headers // {} } };

    # the v1 API is left as it was, the following only applies to v2
    return $self->_handle_response( $self->_send_request( $method,$path,$params,$headers ) )
        if $self->api_version < 2;

    # creating a resource, as opposed to performing an action on one, so send
    # an idempotency key to make it safe to retry the request
    my $is_create = $method eq 'POST' && $path !~ m!/actions/!;

    $headers->{'Idempotency-Key'} //= $self->_generate_idempotency_key
        if $is_create;

    my $retry_safe = $method ne 'POST' || $is_create;

    for ( my $attempt = 0; ; $attempt++ ) {

        my $res = $self->_send_request( $method,$path,$params,$headers );
        $self->_set_rate_limit( $res );

        if ( ! $res->is_success ) {

            if ( defined( my $wait = $self->_retry_wait( $res,$attempt,$retry_safe ) ) ) {
                say STDERR "GOCARDLESS retrying in ${wait}s (@{[ $res->status_line ]})"
                    if $ENV{GOCARDLESS_DEBUG};
                $self->_sleep( $wait );
                next;
            }

            if ( $is_create && $res->code == 409 && ! $self->raise_on_idempotency_conflict ) {

                my $Exception = $self->_exception( $res );

                # the resource has already been created (most likely by an
                # earlier attempt of this request) so return that resource
                # the resource is in the collection, which is the first part
                # of the path (e.g. /instalment_schedules/create_with_dates)
                my ( $collection ) = $path =~ m!^(/[^/?]+)!;

                if ( my $id = $Exception->conflicting_resource_id and $collection ) {
                    return $self->api_get( "$collection/$id" );
                }

                $Exception->throw;
            }
        }

        return $self->_handle_response( $res );
    }
}

sub _handle_response {
    my ( $self,$res ) = @_;

    if ( $res->is_success ) {
        # the response body is UTF-8 encoded bytes, as is the request body
        my $json  = $res->content;
        my $data  = length( $json // '' )
            ? JSON->new->utf8->canonical->decode( $json )
            : {}; # e.g. 204 No Content
        say STDERR "GOCARDLESS <- $json" if $ENV{GOCARDLESS_DEBUG};
        my $links = $res->header( 'link' );
        my $info  = $res->header( 'x-pagination' );
        return wantarray ? ( $data,$links,$info ) : $data;
    }

    $self->_exception( $res )->throw;
}

sub _exception {
    my ( $self,$res ) = @_;

    return Business::GoCardless::Exception->new({
        message  => $res->content,
        code     => $res->code,
        response => $res->status_line,
    });
}

# returns the number of seconds to wait before retrying the request,
# or undef if the request shouldn't be retried
sub _retry_wait {
    my ( $self,$res,$attempt,$retry_safe ) = @_;

    return undef if $attempt >= $self->max_retries;

    my $code    = $res->code;
    my $backoff = 0.5 * ( 2 ** $attempt );

    if ( $code == 429 ) {
        # rate limited requests aren't processed so are always safe to retry
        my $reset_at = ( $self->rate_limit // {} )->{reset_at};
        my $wait     = $reset_at ? $reset_at - time : $backoff;
        $wait = 0 if $wait < 0;

        return $wait > $self->max_retry_wait ? undef : $wait;
    }

    return undef if ! $retry_safe;

    # server errors and timeouts. note that LWP will return a 500 response
    # for connection errors (with a Client-Warning header of "Internal response")
    return $backoff if grep { $code == $_ } 500,502,503,504;

    return undef;
}

sub _sleep {
    my ( $self,$seconds ) = @_;
    Time::HiRes::sleep( $seconds ) if $seconds > 0;
}

sub _set_rate_limit {
    my ( $self,$res ) = @_;

    my $limit = $res->header( 'ratelimit-limit' );
    return if ! defined $limit;

    my $reset = $res->header( 'ratelimit-reset' );

    $self->rate_limit({
        limit     => $limit,
        remaining => $res->header( 'ratelimit-remaining' ),
        reset     => $reset,
        reset_at  => defined $reset ? HTTP::Date::str2time( $reset ) : undef,
    });
}

# a v4 UUID, as recommended by gocardless for idempotency keys
sub _generate_idempotency_key { UUID::uuid4() }

sub _send_request {
    my ( $self,$method,$path,$params,$headers ) = @_;

    my $ua = LWP::UserAgent->new;
    $ua->agent( $self->user_agent );

    my $req = HTTP::Request->new(
        # passing through the absolute URL means we don't build it
        $method => my $uri = $path =~ /^http/
            ? $path : join( '/',$self->base_url . $self->api_path . $path ),
    );

    say STDERR "GOCARDLESS -> $uri" if $ENV{GOCARDLESS_DEBUG};

    $req->header( 'Authorization' => "Bearer " . $self->token );
    $req->header( 'Accept' => 'application/json' );

    if ( $self->api_version > 1 ) {
        # pegged to a specific version for this library and not user controlled
        # https://developer.gocardless.com/api-reference/#making-requests-versions
        $req->header( 'GoCardless-Version' => '2015-07-06' );
    }

    $req->header( $_ => $headers->{$_} ) for sort keys %{ $headers // {} };

    if ( $method =~ /POST|PUT/ ) {
        if ( $self->api_version > 1 ) {
            $req->content_type( 'application/json' );
            my $json;
            $json = JSON->new->utf8->canonical->encode( $params ) if $params;
            $req->content( $json ) if $json;
            $req->header( 'Content-Length' => 0 ) if ! $json; # always have a content length
            say STDERR "GOCARDLESS -> $json" if $ENV{GOCARDLESS_DEBUG} && $json;
        } else {
            $req->content_type( 'application/x-www-form-urlencoded' );
            $req->content( my $normalize_params = $self->normalize_params( $params ) );
            say STDERR "GOCARDLESS -> $normalize_params" if $ENV{GOCARDLESS_DEBUG} && $normalize_params;
        }
    }

    return $ua->request( $req );
}

=head1 AUTHOR

Lee Johnson - C<lee@payprop.com>

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. If you would like to contribute documentation,
features, bug fixes, or anything else then please raise an issue / pull request:

    https://github.com/payprop/business-gocardless

=cut

1;

# vim: ts=4:sw=4:et
