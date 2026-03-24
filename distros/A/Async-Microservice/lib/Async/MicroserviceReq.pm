package Async::MicroserviceReq;

use strict;
use warnings;
use 5.010;

our $VERSION = '0.05';

use Moose;
use namespace::autoclean;
use URI;
use AnyEvent::IO qw(aio_load);
use Try::Tiny;
use JSON::XS;
use Plack::MIME;
use MooseX::Types::Path::Class;
use Future::AsyncAwait;

our $json             = JSON::XS->new->utf8->pretty->canonical;
our @no_cache_headers = ('Cache-Control' => 'private, max-age=0', 'Expires' => '-1');
our $pending_req      = 0;

has 'method'  => (is => 'ro', isa => 'Str',    required => 1);
has 'headers' => (is => 'ro', isa => 'Object', required => 1);
has 'path'    => (is => 'ro', isa => 'Str',    required => 1);
has 'content' => (is => 'ro', isa => 'Str',    required => 1);
has 'json_content' =>
    (is => 'ro', isa => 'Ref', required => 0, lazy => 1, builder => '_build_json_content');
has 'params'        => (is => 'ro', isa => 'Object',           required => 1);
has 'plack_respond' => (is => 'rw', isa => 'CodeRef',          required => 0, clearer => 'clear_plack_respond');
has 'static_dir'    => (is => 'ro', isa => 'Path::Class::Dir', required => 1, coerce => 1);

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

sub _build_base_url {
    my ($self) = @_;
    return URI->new('http://' . $self->headers->header('Host') . '/'),;
}

sub _build_want_json {
    my ($self) = @_;
    return (
        ($self->headers->header('Accept') // '') eq 'application/json'
        ? 1
        : 0
    );
}

sub _build_json_content {
    my ($self) = @_;
    return $json->decode($self->content);
}

sub BUILD {
    $pending_req++;
    return;
}

sub DEMOLISH {
    $pending_req--;
    return;
}

sub get_pending_req {
    return $pending_req;
}

sub text_plain {
    my ( $self, @text ) = @_;
    return $self->respond( 200, [], join( "\n", ( @text, q{} ) ) );
}

sub respond {
    my ($self, $status, $headers, $payload) = @_;

    my %headers_as_hash = map {defined($_) ? lc($_) : $_} @$headers;
    my $content_type;

    if ($self->want_json                      # json wanted via accept headers
        && !ref($payload)                     # payload not a reference
        && !$headers_as_hash{'content-type'}  # and content type is not forced (statics for example)
    ) {
        if ($status < 400) {
            $payload = {'data' => $payload};
        }
        else {
            $payload = {
                'error' => {
                    err_status => $status,
                    err_msg    => $payload,
                }
            };
        }
    }

    # encode any reference as json
    if (ref($payload)) {
        try {
            if (my $jsonp = $self->jsonp) {
                if (my $js_func = $self->params->{$jsonp}) {
                    if ($js_func !~ m/^[a-zA-Z_\$][0-9a-zA-Z_\$\.]*$/) {
                        $status  = 405;
                        $payload = {
                            'error' => {
                                err_status => $status,
                                err_msg    => 'unsupported call-back function name',
                            }
                        };
                    }
                    else {
                        $payload      = sprintf('%s(%s);', $js_func, $json->encode($payload));
                        $content_type = 'application/javascript';
                    }
                }
            }
            if (ref($payload)) {
                $payload      = $json->encode($payload);
                $content_type = 'application/json';
            }
        }
        catch {
            $payload = $json->encode('failed to serialize json: ' . $_);
        };
    }

    push(@$headers, ('Content-Type' => ($content_type || 'text/plain')))
        unless ($headers_as_hash{'content-type'});

    return $self->plack_respond->([$status, [@no_cache_headers, @$headers], [$payload]]);
}

sub redirect {
    my ($self, $location_path) = @_;
    my $location = $self->base_url->clone;
    $location->path($location_path);
    return $self->respond(302, ["Location" => $location], "redirect to " . $location);
}

async sub static_ft {
    my ($self, $file_name, $content_cb) = @_;

    my $static_file = $self->static_dir->file($file_name)->stringify;
    unless (-r $static_file) {
        return $self->respond(404, [], $file_name . ' not found');
    }

    my $content_type = Plack::MIME->mime_type($static_file) || 'text/plain';
    my ($content) = await _fetch_file_ft($static_file)
        ->catch(sub { return $self->respond(404, [], 'failed to load static file') });
    return $self->respond(404, [], 'failed to load static file')
        unless defined($content);
    $content = $content_cb->($content)
        if $content_cb;

    return [ 200, [ 'Content-Type' => $content_type ], $content ];
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
    $aio_load_f->on_done(sub {
        my ($content) = @_;
        unless (defined($content)) {
            $fetch_file_ft->fail('failed to load content of file: ' . $file);
            return;
        }
        $fetch_file_ft->done($content);
    });

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

Send plack response.

=head2 redirect($location_path)

Send redirect.

=head2 static_ft($file_name, $content_cb)

Send static file, can be updated/modified using optional callback.

=head2 get_pending_req

Returns number of currently pending async requests.

=cut
