package Business::TrueLayer::Request;

=head1 NAME

Business::TrueLayer::Request - abstract class to handle low level request
traffic to TrueLayer, you probably don't need to use this and should use
the main L<Business::TrueLayer> module instead.

=cut

use strict;
use warnings;
use feature qw/ signatures postderef /;

use Moose;

no warnings qw/ experimental::signatures experimental::postderef /;

use Business::TrueLayer::Types;
use Business::TrueLayer::Authenticator;
use Business::TrueLayer::Signer;

use Try::Tiny::SmartCatch;
use Mojo::UserAgent;
use Carp qw/ croak /;
use JSON;
use Data::GUID;

my $MAX_REDIRECTS = 5;

has [ qw/ client_id client_secret kid / ] => (
    is        => 'ro',
    isa       => 'Str',
    required  => 0,
);

has 'host' => (
    is        => 'ro',
    isa       => 'Str',
    required  => 0,
    default   => sub ( $self ) {
        'truelayer.com',
    }
);

has api_host => (
    is        => 'ro',
    isa       => 'Str',
    required  => 0,
    lazy      => 1,
    default   => sub ( $self ) {
        return join( '.','api',$self->host );
    }
);

has auth_host => (
    is        => 'ro',
    isa       => 'Str',
    required  => 0,
    lazy      => 1,
    default   => sub ( $self ) {
        return join( '.','auth',$self->host );
    }
);

has payment_host => (
    is        => 'ro',
    isa       => 'Str',
    required  => 0,
    lazy      => 1,
    default   => sub ( $self ) {
        return join( '.','payment',$self->host );
    }
);

has 'private_key' => (
    is       => 'ro',
    isa      => 'EC512:PrivateKey',
    coerce   => 1,
    required => 0,
);

has '_ua' => (
    is        => 'ro',
    isa       => 'UserAgent',
    required  => 0,
    default   => sub {
        return Mojo::UserAgent->new
            ->max_redirects( $MAX_REDIRECTS )
            ->connect_timeout( 5 )
            ->inactivity_timeout( 5 )
            ->request_timeout( 30 )
        ;
    },
);

has 'authenticator' => (
    is        => 'ro',
    isa       => 'Authenticator',
    lazy      => 1,
    default   => sub ( $self ) {

        Business::TrueLayer::Authenticator->new(
            client_id     => $self->client_id,
            client_secret => $self->client_secret,
            host          => $self->auth_host,
            _ua           => $self->_ua,
        );
    },
);

has 'signer' => (
    is        => 'ro',
    isa       => 'Signer',
    lazy      => 1,
    default   => sub ( $self ) {

        Business::TrueLayer::Signer->new(
            kid         => $self->kid,
            private_key => $self->private_key,
        );
    },
);

sub idempotency_key ( $self ) {
    return Data::GUID->new->as_string;
}

sub api_post (
    $self,
    $absolute_path,
    $http_request_body = undef,
    $expect_json = 1,
) {
    # sign the request
    my $idempotency_key = $self->idempotency_key;

    my $json = $http_request_body
        ? JSON->new->utf8->canonical->encode( $http_request_body )
        : undef;

    my ( $jws ) = $self->signer->sign_request(
        'POST',
        $absolute_path,
        $idempotency_key,
        $json,
    );

    return $self->_ua_request(
        "https://" . $self->api_host . $absolute_path,
        $json,
        [
            'Authorization' => "Bearer " . $self->authenticator->access_token,
            'Tl-Signature'  => $jws,
            'Idempotency-Key' => $idempotency_key,
        ],
        'POST',
        $expect_json
    );
}

sub _ua_request (
    $self,
    $url,
    $body,
    $headers = undef,
    $method = 'POST',
    $expect_json = 1
) {

    my $ua = $self->_ua;
    my $res = $ua->start($ua->build_tx(
        $method,
        $url,
        {
            'Accept'        => 'application/json; charset=UTF-8',
            'Content-Type'  => 'application/json; charset=UTF-8',
            @{ $headers // [] },
        },
        # Mojo::UserAgent::Transactor::tx calls $self->generators and then the
        # callbacks based on the count of @_, and does not expect undef here
        (defined $body ? ($body) : ()),
    ))->result;

    # Easiest to deal with this first, even though it should be very rare:
    if ( $res->code == 301 ) {
        # possibly a redirect loop
        croak( "TrueLayer $method $url failed > $MAX_REDIRECTS levels of redirect" );
    }

    if ( !$expect_json && !$res->is_success ) {
        # All error responses are documented as returning JSON
        $expect_json = 1;
    }

    my $code = $res->code;

    # no content
    return if $code == '204';

    my $type = $res->headers->content_type;
    croak( "TrueLayer $method $url returned $code with no MIME type" )
        unless defined $type;

    $body = $res->body;

    return $body
        if !$expect_json && $res->is_success;

    # Either 2xx and expecting JSON, or an error response

    croak( "TrueLayer $method $url returned $code $type not JSON, status line: "
               . $res->message)
        unless $type =~ m!\Aapplication/(?:problem\+)?JSON\b!i;

    croak( "TrueLayer $method $url returned $code with an empty body" )
        unless length $body;

    my $res_content = try sub {
        JSON->new->canonical->decode( $body );
    },
    catch_default sub {
            croak( "TrueLayer $method $url returned $code with malformed JSON length @{[ length $body ]}: $_" );
    };
    croak( "TrueLayer $method $url returned $code JSON $res_content" )
        unless ref $res_content eq 'HASH';

   return $res_content
        if $res->is_success;

    # From here onward, it's all error handling, as best we can:
    my $title = $res_content->{title};
    if ( length $title ) {
        # This is looking like an error format we expect:
        # https://docs.truelayer.com/docs/payments-api-errors
        my $detail = $res_content->{detail};
        my $message = defined $detail ? "$title - $detail" : $title;

        if ( $res_content->{errors} ) {
            $message .= ' ';
            $message .= join( "; ",$_->@* )
                for values $res_content->{errors}->%*
        }

        croak( "TrueLayer $method $url returned $code: $message" );
    }

    my $error = $res_content->{error};
    if ( length $error ) {
        # This is looking like the error format for the Access tokens
        # and the Data API
        # https://docs.truelayer.com/reference/generateaccesstoken
        my $detail = $res_content->{error_description};
        my $message = defined $detail ? "'$error' - $detail" : "'$error'";
        # There's no : in this message so that we distinguish it from the
        # message generated for the croak above.
        # (ie we can tell which format the API is actually responding
        # with, whatever the docs might claim)
        croak( "TrueLayer $method $url returned $code $message" );
    }

    # This is not in spec:
    croak( "TrueLayer $method $url returned $code with JSON keys "
               . join( ', ', map { "'$_'" } sort keys %$res_content )
               . ' and status line: '  . $res->message);
}

sub api_get (
    $self,
    $absolute_path,
    $expect_json = 1
) {
    # GET requests don't need to be signed or require an Idempotency-Key
    return $self->_ua_request(
        "https://" . $self->api_host . $absolute_path,
        undef,
        [
            'Authorization' => "Bearer " . $self->authenticator->access_token,
        ],
        'GET',
        $expect_json
    );
}

1;

# vim: ts=4:sw=4:et
