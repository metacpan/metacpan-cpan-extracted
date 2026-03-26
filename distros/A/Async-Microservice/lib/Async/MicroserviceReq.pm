package Async::MicroserviceReq;

use strict;
use warnings;
use 5.010;

our $VERSION = '0.08';

use Moose;
use namespace::autoclean;
use URI;
use AnyEvent::IO qw(aio_load);
use Try::Tiny;
use JSON::XS;
use Plack::MIME;
use MooseX::Types::Path::Class;
use Future::AsyncAwait;
use Log::Any        qw($log);
use HTTP::Negotiate qw(choose);
use Scalar::Util    qw(weaken);

our $json = JSON::XS->new->utf8->pretty->canonical;
our @no_cache_headers =
    ( 'Cache-Control' => 'private, max-age=0', 'Expires' => '-1' );
our $pending_req = 0;

has 'method'  => ( is => 'ro', isa => 'Str',    required => 1 );
has 'headers' => ( is => 'ro', isa => 'Object', required => 1 );
has 'path'    => ( is => 'ro', isa => 'Str',    required => 1 );
has 'content' => ( is => 'ro', isa => 'Str',    required => 1 );
has 'json_content' => (
    is       => 'ro',
    isa      => 'Ref',
    required => 0,
    lazy     => 1,
    builder  => '_build_json_content'
);
has 'params' => ( is => 'ro', isa => 'Object', required => 1 );
has 'plack_respond' => (
    is       => 'rw',
    isa      => 'CodeRef',
    required => 0,
    clearer  => 'clear_plack_respond'
);
has 'static_dir' =>
    ( is => 'ro', isa => 'Path::Class::Dir', required => 1, coerce => 1 );

has 'base_url' => (
    is       => 'ro',
    isa      => 'URI',
    required => 1,
    lazy     => 1,
    builder  => '_build_base_url'
);
has 'want_json' => (
    is       => 'ro',
    isa      => 'Bool',
    required => 1,
    lazy     => 1,
    builder  => '_build_want_json'
);
has 'jsonp' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);
has 'using_frontend_proxy' => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
);
has 'pending_ref' => (
    is       => 'ro',
    isa      => 'ScalarRef[Int]',
    required => 1,
);
has 'request_start' => (
    is       => 'ro',
    isa      => 'Num',
    required => 1,
    default  => sub { time() },
);
has 'request_timeout' => ( is => 'ro', isa => 'Num', required => 1 );
has '_warn_running_too_long' => (
    is      => 'ro',
    isa     => 'ArrayRef',
    lazy    => 1,
    builder => '_build_warn_running_too_long'
);

after 'BUILD' => sub {
    my ($self) = @_;
    $self->_warn_running_too_long;    # init timer
    return;
};

sub _build_base_url {
    my ($self) = @_;
    return URI->new('/') if !$self->using_frontend_proxy;

    my $https_on = '';
    $https_on = $self->headers->header('HTTP_X_FORWARDED_HTTPS')
        if $self->headers->header('HTTP_X_FORWARDED_HTTPS');
    $https_on = 'ON'
        if $self->headers->header('HTTP_X_FORWARDED_PROTO')
        && $self->headers->header('HTTP_X_FORWARDED_PROTO') eq
        'https';    # Pound
    my $url_scheme = ( $https_on && uc $https_on eq 'ON' ? 'https' : 'http' );
    my $default_port = $url_scheme eq 'https' ? 443 : 80;

    my $redirect_host;
    my $redirect_port = $default_port;
    if ( $self->headers->header('HTTP_X_FORWARDED_HOST') ) {

        # in apache1 ServerName example.com:443
        if ( $self->headers->header('HTTP_X_FORWARDED_SERVER') ) {
            my ( $host, ) =
                $self->headers->header('HTTP_X_FORWARDED_SERVER') =~
                /([^,\s]+)$/;
            if ( $host =~ /^(.+):(\d+)$/ ) {
                $redirect_port = $2;
                $host          = $1;
            }
            $redirect_host = $host;
        }
        my ( $host, ) =
            $self->headers->header('HTTP_X_FORWARDED_HOST') =~ /([^,\s]+)$/;
        if ( $host =~ /^(.+):(\d+)$/ ) {
            $redirect_port = $2;
            $host          = $1;
        }
        elsif ( $self->headers->header('HTTP_X_FORWARDED_PORT') ) {

            # in apache2 httpd.conf (RequestHeader set X-Forwarded-Port 8443)
            $redirect_port = $self->headers->header('HTTP_X_FORWARDED_PORT');
        }
        $redirect_host = $host;
    }

    unless ($redirect_host) {
        $log->warn(
            'using front-end proxy but no host information in headers, check if your proxy is configured to send correct headers'
        );
        return URI->new('/');
    }

    my $redirect_host_port;
    if (   ( ( $redirect_port eq '80' ) && ( $url_scheme eq 'http' ) )
        || ( ( $redirect_port eq '443' ) && ( $url_scheme eq 'https' ) ) ) {
        $redirect_host_port = $redirect_host;
    }
    else {
        $redirect_host_port = $redirect_host . ':' . $redirect_port;
    }

    return URI->new( $url_scheme . '://' . $redirect_host_port . '/' );
}

sub _build_warn_running_too_long {
    my ($o_self) = @_;

    weaken( my $self = $o_self );
    return AnyEvent->timer(
        'after'    => $self->request_timeout,
        'interval' => $self->request_timeout,
        'cb'       => sub {
            $log->errorf(
                'request %s %s running too long for %d seconds',
                $self->method, $self->path, ( time - $self->request_start ),
            );
        },
    );
}

sub _build_want_json {
    my ($self) = @_;

    my $accept = $self->headers->header('Accept');
    return 0
        unless defined($accept) && length($accept);

    my $chosen =
        choose( [ [ 'json', 1.0, 'application/json' ] ], $self->headers, );
    return defined($chosen) ? 1 : 0;
}

sub _build_json_content {
    my ($self) = @_;
    return $json->decode( $self->content );
}

sub BUILD {
    ${ $_[0]->pending_ref }++;
    return;
}

sub DEMOLISH {
    ${ $_[0]->pending_ref }--;
    return;
}

sub text_plain {
    my ( $self, @text ) = @_;
    return $self->respond( 200, [], join( "\n", ( @text, q{} ) ) );
}

sub _should_wrap_payload_as_json {
    my ( $self, $headers_as_hash, $payload ) = @_;
    return (   $self->want_json
            && !ref($payload)
            && !$headers_as_hash->{'content-type'} ) ? 1 : 0;
}

sub _wrap_payload {
    my ( $self, $state ) = @_;

    return $state->{payload}
        unless $self->_should_wrap_payload_as_json( $state->{headers_as_hash},
        $state->{payload} );

    if ( $state->{status} < 400 ) {
        return { 'data' => $state->{payload} };
    }

    return {
        'error' => {
            err_status => $state->{status},
            err_msg    => $state->{payload},
        }
    };
}

sub _encode_jsonp_payload {
    my ( $self, $state ) = @_;

    if ( my $jsonp = $self->jsonp ) {
        if ( my $js_func = $self->params->{$jsonp} ) {
            if ( $js_func !~ m/^[a-zA-Z_\$][0-9a-zA-Z_\$\.]*$/ ) {
                $state->{status}  = 405;
                $state->{payload} = {
                    'error' => {
                        err_status => $state->{status},
                        err_msg    => 'unsupported call-back function name',
                    }
                };
            }
            else {
                $state->{payload} = sprintf( '%s(%s);',
                    $js_func, $json->encode( $state->{payload} ) );
                $state->{content_type} = 'application/javascript';
            }
        }
    }

    return $state;
}

sub _set_serialization_failure {
    my ( $self, $state, $err ) = @_;

    $state->{status}  = 500;
    $state->{payload} = eval {
        $json->encode(
            {   'error' => {
                    err_status => $state->{status},
                    err_msg    => 'failed to serialize response: ' . $err,
                }
            }
        );
    } // eval {
        $json->encode(
            {   'error' => {
                    err_status => $state->{status},
                    err_msg    =>
                        'failed to serialize response and error message',
                }
            }
        );
    };

    if ( $state->{payload} ) {
        $state->{content_type} = 'application/json';
    }
    else {
        $state->{payload} = 'failed to serialize json';
        delete $state->{content_type};
    }

    return $state;
}

sub _serialize_payload {
    my ( $self, $state ) = @_;

    return $state
        unless ref( $state->{payload} );

    try {
        $state = $self->_encode_jsonp_payload($state);

        if ( ref( $state->{payload} ) ) {
            $state->{payload}      = $json->encode( $state->{payload} );
            $state->{content_type} = 'application/json';
        }
    }
    catch {
        $state = $self->_set_serialization_failure( $state, $_ );
    };

    return $state;
}

sub _emit_response {
    my ( $self, $state ) = @_;

    push(
        @{ $state->{headers} },
        ( 'Content-Type' => ( $state->{content_type} || 'text/plain' ) )
    ) unless ( $state->{headers_as_hash}->{'content-type'} );

    return $self->plack_respond->(
        [   $state->{status},
            [ @no_cache_headers, @{ $state->{headers} } ],
            [ $state->{payload} ]
        ]
    );
}

sub respond {
    my ( $self, $status, $headers, $payload ) = @_;

    my %headers_as_hash = map { defined($_) ? lc($_) : $_ } @$headers;
    my $state           = {
        status          => $status,
        headers         => $headers,
        headers_as_hash => \%headers_as_hash,
        payload         => $payload,
    };

    $state->{payload} = $self->_wrap_payload($state);
    $state = $self->_serialize_payload($state);

    return $self->_emit_response($state);
}

sub redirect {
    my ( $self, $location_path ) = @_;
    my $location = $self->base_url->clone;
    $location->path($location_path);
    return $self->respond(
        302,
        [ "Location" => $location ],
        "redirect to " . $location
    );
}

async sub static_ft {
    my ( $self, $file_name, $content_cb ) = @_;
    my $static_file  = $self->static_dir->file($file_name)->stringify;
    my $content_type = Plack::MIME->mime_type($static_file) || 'text/plain';
    return await _fetch_file_ft($static_file)->then(
        sub {
            my ($content) = @_;
            $content = $content_cb->($content) if $content_cb;
            return [ 200, [ 'Content-Type' => $content_type ], $content ];
        }
    )->catch(
        sub {
            return [ 404, [@no_cache_headers], 'no such static file' ];
        }
    );
}

sub _fetch_file_ft {
    my ($file) = @_;

    my $aio_load_f = Future->new;
    $aio_load_f->retain;
    aio_load(
        $file,
        sub {
            my ($content) = @_;
            $aio_load_f->done($content);
        }
    );

    my $fetch_file_ft = Future->new;
    $aio_load_f->on_done(
        sub {
            my ($content) = @_;
            unless ( defined($content) ) {
                $fetch_file_ft->fail(
                    'failed to load content of file: ' . $file );
                return;
            }
            $fetch_file_ft->done($content);
        }
    );

    return $fetch_file_ft;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Async::MicroserviceReq - async microservice request class

=head1 SYNOPSIS

    my $this_req  = Async::MicroserviceReq->new(
        method     => $plack_req->method,
        headers    => $plack_req->headers,
        content    => $plack_req->content,
        path       => $plack_req->path_info,
        params     => $plack_req->parameters,
        static_dir => $self->static_dir,
    );

    ...

    my $plack_handler_sub = sub {
        my ($plack_respond) = @_;
        $this_req->plack_respond($plack_respond);
    ...

=head1 DESCRIPTION

This is an object created for each request handled by L<Async::Microservice>.
It is passed to all request handling functions as the first argument and
it provides request information and response helper methods.

=head1 ATTRIBUTES

    method
    headers
    path
    params
    plack_respond
    static_dir
    base_url
    want_json
    content
    json_content

=head1 METHODS

=head2 text_plain(@text_lines)

Send text plain response.

=head2 respond($status, $headers, $payload)

Send a PSGI/Plack response.

C<$headers> must be an array reference of header key/value pairs.

If C<$payload> is not a reference, it is sent as plain text by default.
When the request C<Accept> header allows JSON and no explicit
C<Content-Type> header is already present, plain scalar payloads are wrapped
automatically as JSON:

    { "data": "..." }

For error statuses (C<< $status >= 400 >>), scalar payloads are wrapped as:

    { "error": { err_status => ..., err_msg => ... } }

If C<$payload> is a reference, it is serialized as JSON. When JSONP is
enabled and a valid callback parameter is present, the response is emitted as
C<application/javascript> instead of C<application/json>.

=head2 redirect($location_path)

Send redirect.

=head2 static_ft($file_name, $content_cb)

Send static file, can be updated/modified using optional callback.

=head2 get_pending_req

Returns number of currently pending async requests.

=cut
