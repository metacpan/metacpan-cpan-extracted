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

=head2 merchant_id

Your gocardless merchant identifier, defaults to $ENV{GOCARDLESS_MERCHANT_ID}
or will exit if not set.

=head2 user_agent

The user agent string used in requests to the gocardless API, defaults to
business-gocardless/perl/v . $version_of_this_library . - . $api_version

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
    my ( $self,$redirect_flow_id ) = @_;

    # first find the original session token
    my $RedirectFlow = Business::GoCardless::RedirectFlow->new(
        client => $self,
        id => $redirect_flow_id,
    );

    $RedirectFlow->find_with_client( 'redirect_flows' );

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

Make a request to the gocardless API:

    my $data = $Client->api_get( '/merchants/123ABCD/bills',\%params );

In list context returns the links and pagination headers:

    my ( $data,$links,$info ) = $Client->api_get( ... );

=cut

sub api_get {
    my ( $self,$path,$params ) = @_;
    return $self->_api_request( 'GET',$path,$params );
}

sub api_post {
    my ( $self,$path,$params ) = @_;
    return $self->_api_request( 'POST',$path,$params );
}

sub api_put {
    my ( $self,$path,$params ) = @_;
    return $self->_api_request( 'PUT',$path,$params );
}

sub _api_request {
    my ( $self,$method,$path,$params ) = @_;

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

    if ( $method =~ /POST|PUT/ ) {
        if ( $self->api_version > 1 ) {
            $req->content_type( 'application/json' );
            my $json;
            $json = JSON->new->utf8->canonical->encode( $params ) if $params;
            $req->content( $json ) if $json;
            say STDERR "GOCARDLESS -> $json" if $ENV{GOCARDLESS_DEBUG} && $json;
        } else {
            $req->content_type( 'application/x-www-form-urlencoded' );
            $req->content( my $normalize_params = $self->normalize_params( $params ) );
            say STDERR "GOCARDLESS -> $normalize_params" if $ENV{GOCARDLESS_DEBUG} && $normalize_params;
        }
    }

    my $res = $ua->request( $req );

    if ( $res->is_success ) {
        say STDERR "GOCARDLESS <- " . $res->content if $ENV{GOCARDLESS_DEBUG};
        my $data  = JSON->new->canonical->decode( $res->content );
        my $links = $res->header( 'link' );
        my $info  = $res->header( 'x-pagination' );
        return wantarray ? ( $data,$links,$info ) : $data;
    }
    else {
        Business::GoCardless::Exception->throw({
            message  => $res->content,
            code     => $res->code,
            response => $res->status_line,
        });
    }
}

=head1 AUTHOR

Lee Johnson - C<leejo@cpan.org>

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. If you would like to contribute documentation,
features, bug fixes, or anything else then please raise an issue / pull request:

    https://github.com/Humanstate/business-gocardless

=cut

1;

# vim: ts=4:sw=4:et
