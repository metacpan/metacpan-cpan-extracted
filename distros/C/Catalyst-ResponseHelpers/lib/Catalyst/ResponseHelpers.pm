use 5.010;
use strict;
use warnings;
use utf8;
package Catalyst::ResponseHelpers;
use parent qw< Exporter::Tiny >;
use HTTP::Status qw< :constants :is status_message >;
use Path::Tiny;
use Safe::Isa qw< $_isa >;
use Encode qw< encode_utf8 >;
use IO::String;
use URI;
use URI::QueryParam;

our $VERSION = '1.02';

=encoding utf-8

=head1 NAME

Catalyst::ResponseHelpers - Concise response constructors for Catalyst controllers

=head1 SYNOPSIS

    use Catalyst::ResponseHelpers qw< :helpers :status >;

    sub show_user : Chained('/') PathPart('user') Args(1) {
        my ($c, $id) = @_;
        my $user = load_user($id)
            or return NotFound($c, "The user id <$id> couldn't be found.");
        ...
    }

=head1 DESCRIPTION

Various helper functions for setting up the current L<Catalyst::Response>
object.  All response helpers call C<Catalyst/detach> to stop request
processing.  For clarity in your controller actions, it is nevertheless
recommended that you call these helpers as values to L<return()|perlfunc/return>.

=head1 EXPORTS

By default, only the helper methods documented below are exported.  You may
explicitly request them using the C<:helpers> tag.

You may also request C<:status>, which re-exports the C<:constants> from
L<HTTP::Status> into your package.  This is useful for custom status codes.

=cut

our %EXPORT_TAGS = (
    status  => $HTTP::Status::EXPORT_TAGS{constants},
    helpers => [qw[
        Ok
        Forbidden
        NotFound
        ClientError
        ServerError
        TextPlain
        AsJSON
        FromFile
        FromCharString
        FromByteString
        FromHandle
        Redirect
        RedirectToUrl
        ReturnWithMsg
    ]],
);
our @EXPORT    = @{ $EXPORT_TAGS{helpers} };
our @EXPORT_OK = map { @$_ } values %EXPORT_TAGS;

=head1 FUNCTIONS

=head2 ReturnWithMsg($c, $mid)

Redirects to the request’s C<return> parameter, or C</> if no such parameter
exists or if the given URI appears to be external to the app.  The given
C<$mid> is set as a query parameter, and should be the result of a
C<< $c->set_status_msg >> or C<< $c->set_error_msg >> call.  These context
methods are normally provided by L<Catalyst::Plugin::StatusMessage>.

=head2 Redirect($c, $action_or_action_path, @args?)

Passes arguments to L<Catalyst/uri_for_action> and redirects to the returned
URL.

=head2 RedirectToUrl($c, $url, $status?)

Redirects to the given URL, with an optional custom status.  Status defaults to
302 (HTTP_FOUND).

=cut

sub ReturnWithMsg {
    my ($c, $mid) = @_;
    my $base   = $c->req->base;
    my $return = URI->new( $c->req->param('return') );
       $return = $c->uri_for('/') unless $return and $return =~ m{^\Q$base\E}i;
       $return->query_param_append( mid => $mid );
    RedirectToUrl($c, $return);
}

sub Redirect {
    my ($c, $action, @rest) = @_;
    RedirectToUrl($c, $c->uri_for_action($action, @rest));
}

sub RedirectToUrl {
    my ($c, $url, $status) = @_;
    $c->response->redirect($url, $status);
    $c->detach;
}

=head2 Ok($c, $status?, $msg?)

Sets a body-less 204 No Content response by default, switching to a 200 OK with
a body via L</TextPlain> iff a message is provided.  Both the status and
message may be omitted or provided.  If the message is omitted, a body-less
response is set.

Note that if you're using L<Catalyst::Action::RenderView> and you specify a
status other than 204 but don't provide a message (e.g. C<Ok($c, 200)>),
RenderView will intercept the response and try to render a template.  This
probably isn't what you wanted.  A workaround is to use the proper status code
when sending no content (204) or specify a message (the empty string is OK).

=cut

sub Ok {
    my ($c, $status, $msg) = @_;
    ($status, $msg) = (undef, $status)
        if @_ == 2 and not is_success($status);

    if (defined $msg) {
        $status //= HTTP_OK;
        TextPlain($c, $status, $msg);
    } else {
        $status //= HTTP_NO_CONTENT;
        $c->response->status($status);
        $c->response->body(undef);
        $c->detach;
    }
}

=head2 Forbidden($c, $msg?)

Sets a plain text 403 Forbidden response, with an optional custom message.

=head2 NotFound($c, $msg?)

Sets a plain text 404 Not Found response, with an optional custom message.

=cut

sub Forbidden {
    my ($c, $msg) = @_;
    TextPlain($c, HTTP_FORBIDDEN, $msg);
}

sub NotFound {
    my ($c, $msg) = @_;
    TextPlain($c, HTTP_NOT_FOUND, $msg);
}

=head2 ClientError($c, $status?, $msg?)

Sets a plain text 400 Bad Request response by default, with an optional
custom message.  Both the status and message may be omitted or provided.

=head2 ServerError($c, $status?, $msg?)

Sets a plain text 500 Internal Server Error response by default, with an
optional custom message.  Both the status and message may be omitted or
provided.  The error is logged via L<Catalyst/log>.

=cut

sub ClientError {
    my ($c, $status, $msg) = @_;
    ($status, $msg) = (undef, $status)
        if @_ == 2 and not is_client_error($status);
    TextPlain($c, $status // HTTP_BAD_REQUEST, $msg);
}

sub ServerError {
    my ($c, $status, $msg) = @_;
    ($status, $msg) = (undef, $status)
        if @_ == 2 and not is_server_error($status);
    $status //= HTTP_INTERNAL_SERVER_ERROR;
    $c->log->error("HTTP $status: $msg");
    TextPlain($c, $status, $msg);
}

=head2 TextPlain($c, $status?, $msg?)

Sets a plain text 200 OK response by default, with an optional custom
message.  Both the status and message may be omitted or provided.

=cut

sub TextPlain {
    my ($c, $status, $msg) = @_;
    ($status, $msg) = (undef, $status)
        if @_ == 2 and not status_message($status);
    $status //= HTTP_OK;
    $c->response->status($status);
    $c->response->content_type("text/plain");
    $c->response->body($msg // status_message($status));
    $c->detach;
}

=head2 AsJSON($c, $status?, $data)

Sets a JSON 200 OK response by default, with an optional custom status.  Data
should be serializable by a view named C<JSON> provided by your application
(e.g. via L<Catalyst::View::JSON>).

=cut

sub AsJSON {
    my ($c, $status, $data) = @_;
    ($status, $data) = (undef, $status)
        if @_ == 2;
    $status //= HTTP_OK;
    $c->response->status($status);
    $c->stash( json => $data );
    $c->view('JSON')->process($c);
    $c->detach;
}

=head2 FromFile($c, $filename, $mime_type, $headers?)

Sets a response from the contents of the filename using the specified MIME
type.  C<Content-Length> and C<Last-Modified> are set from the file.

The C<Content-Disposition> is set to C<attachment> by default, usually forcing
a download.

An optional arrayref of additional headers may also be provided, which is
passed through to L</FromHandle>.

=head2 FromCharString($c, $string, $mime_type, $headers?)

Sets a response from the contents of a B<character> string using the specified
MIME type.  The character string will be encoded as UTF-8 bytes.

The C<Content-Disposition> is set to C<attachment> by default, usually forcing
a download.

An optional arrayref of additional headers may also be provided, which is
passed through to L</FromHandle>.

=head2 FromByteString($c, $string, $mime_type, $headers?)

Sets a response from the contents of a B<byte> string using the specified
MIME type.  The character string will B<NOT> be encoded.

The C<Content-Disposition> is set to C<attachment> by default, usually forcing
a download.

An optional arrayref of additional headers may also be provided, which is
passed through to L</FromHandle>.

=head2 FromHandle($c, $handle, $mime_type, $headers?)

Sets a response from the contents of the filehandle using the specified MIME
type.  An optional arrayref of additional headers may also be provided, which
is passed to L<the response’s|Catalyst::Response> L<HTTP::Headers> object.

The C<Content-Disposition> is set to C<attachment> by default, usually forcing
a download.

=cut

sub FromFile {
    my ($c, $file) = (shift, shift);
    $file = path($file)
        unless $file->$_isa("Path::Tiny");
    return FromHandle($c, $file->openr_raw, @_);
}

sub FromByteString {
    my ($c, $string) = (shift, shift);
    my $handle = IO::String->new( $string );
    return FromHandle($c, $handle, @_);
}

sub FromCharString {
    my ($c, $string) = (shift, shift);
    return FromByteString($c, encode_utf8($string), @_);
}

sub FromHandle {
    my ($c, $handle, $mime, $headers) = @_;
    my $h = $c->response->headers;

    $c->response->body( $handle );
    $c->response->header('Content-Disposition' => 'attachment');

    # Default to UTF-8 for text content unless otherwise specified
    $h->content_type( $mime );
    $h->content_type( "$mime; charset=utf-8" )
        if $h->content_is_text and not $h->content_type_charset;

    $h->header( @$headers )
        if $headers;
    $c->detach;
}

=head1 AUTHOR

Thomas Sibley E<lt>trsibley@uw.eduE<gt>

=head1 THANKS

Inspired in part by seeing John Napiorkowski’s (jnap)
L<experimental response helpers in CatalystX::Example::Todo|https://github.com/jjn1056/CatalystX-Example-Todo/blob/master/lib/Catalyst/ResponseHelpers.pm>.

=head1 COPYRIGHT

Copyright 2015- by the University of Washington

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
