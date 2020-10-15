package Async::MicroserviceReq;

use strict;
use warnings;
use 5.010;

use Moose;
use namespace::autoclean;
use URI;
use AnyEvent::IO qw(aio_load);
use Try::Tiny;
use JSON::XS;
use Plack::MIME;
use MooseX::Types::Path::Class;

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
has 'plack_respond' => (is => 'rw', isa => 'CodeRef',          required => 0);
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
}

sub DEMOLISH {
    $pending_req--;
}

sub get_pending_req {
    return $pending_req;
}

sub text_plain {
    my ($self, @text) = @_;
    return $self->respond(200, [], join("\n", @text));
}

sub respond {
    my ($self, $status, $headers, $payload) = @_;
    my %headers_as_hash = map {defined($_) ? lc($_) : $_} @$headers;

    unless ($headers_as_hash{'content-type'}) {
        my $content_type = ($self->want_json ? 'application/json' : 'text/plain');
        push(@$headers, ('Content-Type' => $content_type));
    }

    if ($self->want_json                      # json wanted via accept headerts
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
            $payload = $json->encode($payload);
        }
        catch {
            $payload =
                $json->encode(CRS::Exception::Internal->as_data('failed to serialize json: ' . $_));
        };
    }
    return $self->plack_respond->([$status, [@no_cache_headers, @$headers], [$payload]]);
}

sub redirect {
    my ($self, $location_path) = @_;
    my $location = $self->base_url->clone;
    $location->path($location_path);
    return $self->respond(302, ["Location" => $location], "redirect to " . $location);
}

sub static {
    my ($self, $file_name, $content_cb) = @_;

    my $static_file = $self->static_dir->file($file_name)->stringify;
    unless (-r $static_file) {
        return $self->respond(404, [], $file_name . ' not found');
    }

    my $content_type = Plack::MIME->mime_type($static_file) || 'text/plain';
    my ($content) = _fetch_file($static_file);
    $content = $content_cb->($content)
        if $content_cb;

    return $self->respond(200, ['Content-Type' => $content_type], $content);
}

sub _fetch_file {
    my ($file) = @_;

    my $filedata = AE::cv;
    aio_load(
        $file,
        sub {
            my ($content) = @_
                or die('failed to slurp "' . $file . '"');
            $filedata->($content);
        }
    );

    return $filedata->recv;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Async::MicroserviceReq - async microservice request class

=head1 SYNOPSYS

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
It is passed to all request handling functions as first argument and
it provides some request info and response helper methods.

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

=head2 static($file_name, $content_cb)

Send static file, can be updated/modified using optional callback.

=head2 get_pending_req

Returns number of currently pending async requests.

=cut
