# Copyright 2001-2006 The Apache Software Foundation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# Some code is Copyright 2005, Six Apart, Ltd, used with permission, and licensed
# under the same terms as Perl itself.

package AxKit2::HTTPHeaders;

=head1 NAME

AxKit2::HTTPHeaders - HTTP Request and Response header class

=head1 DESCRIPTION

This class parses and encapsulates HTTP headers, including the request/response
line (e.g. I<GET / HTTP/1.0>).

=head1 API

=cut

use strict;
use warnings;
no  warnings qw(deprecated);

use AxKit2::Utils qw(uri_decode uri_encode http_date);

use fields (
            'headers',      # href; lowercase header -> comma-sep list of values
            'origcase',     # href; lowercase header -> provided case
            'hdorder',      # aref; order headers were received (canonical order)
            'method',       # scalar; request method (if GET request)
            'uri',          # scalar; request URI (if GET request)
            'file',         # scalar; request File
            'querystring',  # scalar: request querystring
            'mime_type',    # scalar: request file mime type
            'path_info',    # scalar: request path-info
            'params',       # parsed params
            'paramkeys',    # all parsed param keys
            'type',         # 'res' or 'req'
            'code',         # HTTP response status code
            'codetext',     # status text that for response code
            'ver',          # version (string) "1.1"
            'vernum',       # version (number: major*1000+minor): "1.1" => 1001
            'responseLine', # first line of HTTP response (if response)
            'requestLine',  # first line of HTTP request (if request)
            'parsed_cookies',  # parsed cookie data
            'lame'          # HTTP/0.9
            );

our $HTTPCode = {
    200 => 'OK',
    204 => 'No Content',
    206 => 'Partial Content',
    302 => 'Found',
    304 => 'Not Modified',
    400 => 'Bad request',
    403 => 'Forbidden',
    404 => 'Not Found',
    416 => 'Request range not satisfiable',
    500 => 'Internal Server Error',
    501 => 'Not Implemented',
    503 => 'Service Unavailable',
};

=head2 C<< CLASS->new( STRREF, IS_RESPONSE, IS_LAME ) >>

Construct a new header object from the given C<STRREF>. Assumes the header is
a response header if C<IS_RESPONSE> is set. Assumes C<HTTP/0.9> if C<IS_LAME> is
set.

=cut

sub new {
    my AxKit2::HTTPHeaders $self = shift;
    $self = fields::new($self) unless ref $self;

    my ($hstr_ref, $is_response, $lame) = @_;
    # hstr: headers as a string ref

    my $absoluteURIHost = undef;

    my @lines = split(/\r?\n/, $$hstr_ref);

    $self->{headers}    = {};
    $self->{origcase}   = {};
    $self->{hdorder}    = [];
    $self->{paramkeys}  = [];
    $self->{params}     = {};
    $self->{method}     = undef;
    $self->{uri}        = undef;
    $self->{type}       = ($is_response ? "res" : "req");
    $self->{lame}       = $lame;

    # check request line
    if ($is_response) {
        $self->{responseLine} = (shift @lines) || "";

        # check for valid response line
        return fail("Bogus response line") unless
            $self->{responseLine} =~ m!^HTTP\/(\d+)\.(\d+)\s+(\d+)\s+(.+)$!;

        my ($ver_ma, $ver_mi, $code) = ($1, $2, $3);
        $self->code($code, $4);

        # version work so we know what version the backend spoke
        unless (defined $ver_ma) {
            ($ver_ma, $ver_mi) = (0, 9);
        }
        $self->{ver} = "$ver_ma.$ver_mi";
        $self->{vernum} = $ver_ma*1000 + $ver_mi;
    }
    elsif ($lame) {
        $self->{requestLine} = (shift @lines) || "";
        $self->{requestLine} =~ /^GET ([^ ]+)$/m
            || die "Strange program interaction - not a lame request at all";
        
        $self->{method} = 'GET';
        $self->{uri} = $1;
        
        $self->{ver} = "0.9";
        $self->{vernum} = 9;
    }
    else {
        $self->{requestLine} = (shift @lines) || "";
    
        # check for valid request line
        return fail("Bogus request line") unless
            $self->{requestLine} =~ m!^(\w+) ((?:\*|(?:\S*?)))(?: HTTP/(\d+)\.(\d+))$!;
    
        $self->{method} = $1;
        $self->{uri} = $2;
    
        my ($ver_ma, $ver_mi) = ($3, $4);
    
        # now check uri for not being a uri
        if ($self->{uri} =~ m!^http://([^/:]+?)(?::\d+)?(/.*)?$!) {
            $absoluteURIHost = lc($1);
            $self->{uri} = $2 || "/"; # "http://www.foo.com" yields no path, so default to "/"
        }
        $self->parse_uri;
    
        # default to HTTP/0.9
        unless (defined $ver_ma) {
            ($ver_ma, $ver_mi) = (0, 9);
        }
    
        $self->{ver} = "$ver_ma.$ver_mi";
        $self->{vernum} = $ver_ma*1000 + $ver_mi;
    }
    
    my $last_header = undef;
    foreach my $line (@lines) {
        if ($line =~ /^\s/) {
            next unless defined $last_header;
            $self->{headers}{$last_header} .= $line;
        } elsif ($line =~ /^([^\x00-\x20\x7f()<>@,;:\\\"\/\[\]?={}]+):\s*(.*)$/) {
            # RFC 2616:
            # sec 4.2:
            #     message-header = field-name ":" [ field-value ]
            #     field-name     = token
            # sec 2.2:
            #     token          = 1*<any CHAR except CTLs or separators>

            $last_header = lc($1);
            if (defined $self->{headers}{$last_header}) {
                if ($last_header eq "set-cookie") {
                    # cookie spec doesn't allow merged headers for set-cookie,
                    # so instead we do this hack so to_string below does the right
                    # thing without needing to be arrayref-aware or such.  also
                    # this lets client code still modify/delete this data
                    # (but retrieving the value of "set-cookie" will be broken)
                    $self->{headers}{$last_header} .= "\r\nSet-Cookie: $2";
                } else {
                    # normal merged header case (according to spec)
                    $self->{headers}{$last_header} .= ", $2";
                }
            } else {
                $self->{headers}{$last_header} = $2;
                $self->{origcase}{$last_header} = $1;
                push @{$self->{hdorder}}, $last_header;
            }
        } else {
            return fail("unknown header line");
        }
    }

    # override the host header if an absolute URI was provided
    $self->header('Host', $absoluteURIHost)
        if defined $absoluteURIHost;

    # now error if no host
    return fail("HTTP 1.1 requires host header")
        if !$is_response && $self->{vernum} >= 1001 && !$self->header('Host');

    return $self;
}


=head2 C<< CLASS->new_response( [ CODE ] ) >>

Create a new response header with response code C<CODE> (default: 200 "OK").

Assumes response is HTTP/1.0.

=cut

sub new_response {
    my AxKit2::HTTPHeaders $self = shift;
    $self = fields::new($self) unless ref $self;

    my $code = shift || 200;
    $self->{headers} = {};
    $self->{origcase} = {};
    $self->{hdorder} = [];
    $self->{method} = undef;
    $self->{uri} = undef;

    $self->{responseLine} = "HTTP/1.0 $code " . $self->http_code_english($code);
    $self->{code} = $code;
    $self->{type} = "res";
    $self->{vernum} = 1000;

    return $self;
}

=head2 C<< $obj->parse_uri >>

Parse the request URI for querystring parameters.

=cut

sub parse_uri {
    my AxKit2::HTTPHeaders $self = shift;
    my ($path, $qs) = split(/\?/, $self->{uri});
    $qs = "" if !defined $qs;
    my (@item) = split(/[&;]/, $qs);
    foreach (@item) {
        my ($key, $value) = split('=',$_,2);
        next unless defined $key;
        $value  = '' unless defined $value; # what I wouldn't give for //=
        $key    = uri_decode($key);
        $value  = uri_decode($value);
        push @{$self->{paramkeys}}, $key unless exists $self->{params}{$key};
        push @{$self->{params}{$key}}, $value;
    }
}

=head2 C<< $obj->add_param( KEY, VALUE ) >>

Add a new param (see C<< $obj->param >> below).

=cut

sub add_param {
    my AxKit2::HTTPHeaders $self = shift;
    my ($key, $value) = @_;
    $value = '' unless defined $value;
    push @{$self->{paramkeys}}, $key unless exists $self->{params}{$key};
    push @{ $self->{params}{$key} }, $value;
}


=head2 C<< $obj->param( [ KEY ] ) >>

Returns all params for C<KEY> in LIST context, or the last param for C<KEY> in
SCALAR context.

Returns a list of current params if C<KEY> is not supplied.

=cut

sub param {
    my AxKit2::HTTPHeaders $self = shift;
    my $key = shift;
    return @{$self->{paramkeys}} unless defined $key;
    return unless exists $self->{params}{$key};
    return wantarray ? @{ $self->{params}{$key} } : $self->{params}{$key}[-1];
}

=head2 C<< $obj->http_code_english( [ CODE ] ) >>

Returns the english equivalent for HTTP response code C<CODE>. If code is not
supplied uses the current I<response> code (not valid for request headers).

=cut

sub http_code_english {
    my AxKit2::HTTPHeaders $self = shift;
    if (@_) {
        return $HTTPCode->{shift()} || "";
    } else {
        return "" unless $self->response_code;
        return $HTTPCode->{$self->response_code} || "";
    }
}

sub fail {
    return undef unless $::DEBUG >= 1;

    my $reason = shift;
    print "HTTP parse failure: $reason\n" if $::DEBUG >= 1;
    return undef;
}

sub _codetext {
    my AxKit2::HTTPHeaders $self = shift;
    return $self->{codetext} if $self->{codetext};
    return $self->http_code_english;
}

=head2 C<< $obj->code( CODE [, TEXT] ) >>

Sets the response code to C<CODE> with optional C<TEXT>.

=cut

sub code {
    my AxKit2::HTTPHeaders $self = shift;
    my ($code, $text) = @_;
    $self->{codetext} = $text;
    if (! defined $self->{code} || $code != $self->{code}) {
        $self->{code} = $code+0;
        if ($self->{responseLine}) {
            $self->{responseLine} = "HTTP/1.0 $code " . $self->http_code_english;
        }
    }
}

=head2 C<< $obj->response_code >>

Gets the response code.

=cut

sub response_code {
    my AxKit2::HTTPHeaders $self = $_[0];
    return $self->{code};
}

=head2 C<< $obj->request_method >>

Gets the request method (e.g. "GET", "POST", etc).

=cut

sub request_method {
    my AxKit2::HTTPHeaders $self = shift;
    return $self->{method};
}


=head2 C<< $obj->request_uri >>

Gets the request URI. Returns the full URI inclusive of query string.

Also callable as C<< $obj->uri >>.

=cut

sub request_uri {
    my AxKit2::HTTPHeaders $self = shift;
    @_ and $self->{uri} = shift;
    return $self->{uri};
}

*uri = \&request_uri;

# Parse the Cookie header.
sub parse_cookies {
    my AxKit2::HTTPHeaders $self = shift;
    my $raw_cookies = $self->header('Cookie') || '';
    $self->{parsed_cookies} = {};
    foreach (split(/;\s+/, $raw_cookies)) {
        my ($key, $value) = split("=", $_, 2);
        my (@values) = map { uri_decode($_) } split(/&/, $value);
        $key = uri_decode($key);
        $self->{parsed_cookies}{$key} = \@values;
    }
}

# From RFC-2109
#    cookie-av       =       "Comment" "=" value
#                    |       "Domain" "=" value
#                    |       "Max-Age" "=" value
#                    |       "Path" "=" value
#                    |       "Secure"
#                    |       "Version" "=" 1*DIGIT

=head2 C<< $obj->cookie( NAME ) >>

Returns a list of values for the given cookie C<NAME> in LIST context, or the
last set cookie for the given cookie C<NAME> in scalar context. Only works on request
headers. 

=head2 C<< $obj->cookie( NAME, VALUE [, PARAMS] ) >>

Set the cookie called C<NAME> with value C<VALUE>.

If value is an arrayref sets a multi-valued cookie.

Optional params are key-value pairs as per the cookie spec, e.g.:

  $header->cookie( foo => "bar", path => "/", secure => 1 );

Expiration via C<expires> is not parsed and does not take formats such as "+1d".
It is suggested to use C<max-age> instead (as per RFC 2109) which is a timeout in
seconds from the current time.

=cut
sub cookie {
    my AxKit2::HTTPHeaders $self = shift;
    my $name = shift;
    if (@_) {
        die "Cannot set cookies in the request"
            if $self->{type} eq 'req';
        # set cookie
        my $value = shift;
        my %params = @_;
        
        # special case for "secure"
        my @params = delete($params{secure}) ? ("secure") : ();
        # rest are key-value pairs
        push @params, map { "$_=$params{$_}" } keys %params;
        
        my $key = uri_encode($name);
        my $cookie = "$key=" . join("&", map uri_encode($_), ref($value) ? @$value : $value);
        $cookie = join('; ', $cookie, @params);
        if (my $oldcookie = $self->header('Set-Cookie')) {
            $cookie = "$oldcookie, $cookie";
        }
        $self->header('Set-Cookie', $cookie);
        $self->header('Expires', http_date(0)) unless $self->header('Expires');
        return;
    }
    die "Cannot extract cookies from the response"
        if $self->{type} eq 'res';
    $self->parse_cookies unless $self->{parsed_cookies};
    if (exists $self->{parsed_cookies}{$name}) {
        return wantarray ? @{$self->{parsed_cookies}{$name}} : $self->{parsed_cookies}{$name}[-1];
    }
}

=head2 C<< $obj->filename( [ STRING ] ) >>

Gets/Sets the request filename value.

=cut
sub filename {
    my AxKit2::HTTPHeaders $self = shift;
    @_ and $self->{file} = shift;
    return $self->{file};
}

=head2 C<< $obj->mime_type( [ STRING ] ) >>

Gets/Sets the request MIME type.

=cut
sub mime_type {
    my AxKit2::HTTPHeaders $self = shift;
    @_ and $self->{mime_type} = shift;
    return $self->{mime_type};
}

=head2 C<< $obj->path_info( [ STRING ] ) >>

Gets/Sets the request path-info value.

=cut
sub path_info {
    my AxKit2::HTTPHeaders $self = shift;
    @_ and $self->{path_info} = shift;
    return $self->{path_info};
}

=head2 C<< $obj->version_number( [ VER ] ) >>

Gets/Sets the header version number. Uses the form C<MAJOR * 1000 + MINOR>, so
HTTP/1.0 will return C<1000> and HTTP/0.9 will return C<9>.

=cut
sub version_number {
    my AxKit2::HTTPHeaders $self = shift;
    @_ and $self->{vernum} = shift;
    $self->{vernum};
}

=head2 C<< $obj->request_line >>

Returns the very first line of the request as seen.

=cut
sub request_line {
    my AxKit2::HTTPHeaders $self = shift;
    $self->{requestLine};
}

=head2 C<< $obj->header( KEY [, VALUE ] ) >>

Get/Set the value for a given header.

=cut
sub header {
    my AxKit2::HTTPHeaders $self = shift;
    my $key = shift;
    return $self->{headers}{lc($key)} unless @_;

    # adding a new header
    my $origcase = $key;
    $key = lc($key);
    unless (exists $self->{headers}{$key}) {
        push @{$self->{hdorder}}, $key;
        $self->{origcase}{$key} = $origcase;
    }

    return $self->{headers}{$key} = shift;
}

=head2 C<< $obj->lame_request >>

Returns true if the request was a HTTP/0.9 request.

=cut
sub lame_request {
    my AxKit2::HTTPHeaders $self = shift;
    return $self->{lame};
}

=head2 C<< $obj->to_string_ref >>

Returns a reference to a string representing the headers in full.

=cut
sub to_string_ref {
    my AxKit2::HTTPHeaders $self = shift;
    my $st = join("\r\n",
                  $self->{requestLine} || $self->{responseLine},
                  (map { "$self->{origcase}{$_}: $self->{headers}{$_}" }
                   grep { defined $self->{headers}{$_} }
                   @{$self->{hdorder}}),
                  '', '');  # final \r\n\r\n
    return \$st;
}

=head2 C<< $obj->clone >>

Clone the current header object. Returns a new C<AxKit2::HTTPHeaders> object.

=cut
sub clone {
    my AxKit2::HTTPHeaders $self = shift;
    my $new = fields::new($self);
    foreach (qw(method uri type code codetext ver vernum responseLine requestLine)) {
        $new->{$_} = $self->{$_};
    }

    # TODO - parse cookies and things
    $new->{headers} = { %{$self->{headers}} };
    $new->{origcase} = { %{$self->{origcase}} };
    $new->{hdorder} = [ @{$self->{hdorder}} ];
    return $new;
}

=head2 C<< $obj->set_version( VER ) >>

Set the HTTP version using the C<N.N> format.

=cut
sub set_version {
    my AxKit2::HTTPHeaders $self = shift;
    my $ver = shift;

    die "Bogus version" unless $ver =~ /^(\d+)\.(\d+)$/;
    my ($ver_ma, $ver_mi) = ($1, $2);

    # check for req, as the other can be res or httpres
    if ($self->{type} eq 'req') {
        $self->{requestLine} = "$self->{method} $self->{uri} HTTP/$ver";
    } else {
        $self->{responseLine} = "HTTP/$ver $self->{code} " . $self->_codetext;
    }
    $self->{ver} = "$ver_ma.$ver_mi";
    $self->{vernum} = $ver_ma*1000 + $ver_mi;
    return $self;
}

=head2 C<< $obj->content_length >>

Using all available information, attempt to determine the content length of
the message body being sent to us.

=cut
sub content_length {
    my AxKit2::HTTPHeaders $self = shift;

    # shortcuts depending on our method/code, depending on what we are
    if ($self->{type} eq 'req') {
        # no content length for head requests
        return 0 if $self->{method} eq 'HEAD';
    } elsif ($self->{type} eq 'res' || $self->{type} eq 'httpres') {
        # no content length in any of these
        if ($self->{code} == 304 || $self->{code} == 204 ||
            ($self->{code} >= 100 && $self->{code} <= 199)) {
            return 0;
        }
    }

    # the normal case for a GET/POST, etc.  real data coming back
    # also, an OPTIONS requests generally has a defined but 0 content-length
    if (defined(my $clen = $self->header("Content-Length"))) {
        return $clen;
    }

    # if we get here, nothing matched, so we don't definitively know what the
    # content length is.  this is usually an error, but we try to work around it.
    return undef;
}

=head2 C<< $obj->req_keep_alive( RESPONSE_HEADERS ) >>

Given C<$obj> is the request headers, answers the question: "should a response
to this person specify keep-alive, given the request and the given response?"

This is used in proxy mode to determine based on the client's request and the
backend's response whether or not the response from the proxy (us) should do
keep-alive.

For normal responses (should a response be kept alive) see C<res_keep_alive>.

=cut
sub req_keep_alive {
    my AxKit2::HTTPHeaders $self = $_[0];
    my AxKit2::HTTPHeaders $res = $_[1] or Carp::confess("ASSERT: No response headers given");

    # get the connection header now (saves warnings later)
    my $conn = lc ($self->header('Connection') || '');

    # check the client
    if ($self->version_number < 1001) {
        # they must specify a keep-alive header
        return 0 unless $conn =~ /\bkeep-alive\b/i;
    }

    # so it must be 1.1 which means keep-alive is on, unless they say not to
    return 0 if $conn =~ /\bclose\b/i;

    # if we get here, the user wants keep-alive and seems to support it,
    # so we make sure that the response is in a form that we can understand
    # well enough to do keep-alive.  FIXME: support chunked encoding in the
    # future, which means this check changes.
    return 1 if defined $res->header('Content-length') ||
        $res->response_code == 304 || # not modified
        $res->response_code == 204 || # no content
        $self->request_method eq 'HEAD';

    # fail-safe, no keep-alive
    return 0;
}

=head2 C<< $obj->res_keep_alive_options >>

Determine if an options response from a backend looks like it can do keep-alive.

=cut
sub res_keep_alive_options {
    my AxKit2::HTTPHeaders $self = $_[0];
    return $self->res_keep_alive(undef, 1);
}

=head2 C<< $obj->res_keep_alive( REQUEST_HEADERS ) >>

Given C<$obj> is the response headers, answers the question: "is the backend
expected to stay open?"  this is a combination of the request we sent to it and
the response they sent...

You don't normally need to call this - it is automatically performed by the
backend.

=cut
sub res_keep_alive {
    my AxKit2::HTTPHeaders $self = $_[0];
    my AxKit2::HTTPHeaders $req = $_[1];
    my $is_options = $_[2];
    Carp::confess("ASSERT: No request headers given") unless $req || $is_options;

    # get the connection header now (saves warnings later)
    my $conn = lc ($self->header('Connection') || '');

    # if they said Connection: close, it's always not keep-alive
    return 0 if $conn =~ /\bclose\b/i;

    # handle the http 1.0/0.9 case which requires keep-alive specified
    if ($self->version_number < 1001) {
        # must specify keep-alive, and must have a content length OR
        # the request must be a head request
        return 1 if
            $conn =~ /\bkeep-alive\b/i &&
            ($is_options ||
             defined $self->header('Content-length') ||
             $req->request_method eq 'HEAD' ||
             $self->response_code == 304 || # not modified
             $self->response_code == 204
             ); # no content

        return 0;
    }

    # HTTP/1.1 case.  defaults to keep-alive, per spec, unless
    # asked for otherwise (checked above)
    # FIXME: make sure we handle a HTTP/1.1 response from backend
    # with connection: close, no content-length, going to a
    # HTTP/1.1 persistent client.  we'll have to add chunk markers.
    # (not here, obviously)
    return 1;
}

=head2 C<< $obj->range( SIZE ) >>

Given a size, returns C<STATUS, RANGE_START, RANGE_END>.

Status will be one of:

=over 4

=item * 200 - Invalid or non-existant range header. Serve normally.

=item * 206 - Parsable range is good. Serve partial content.

=item * 416 - Range is unsatisfiable.

=back

=cut
sub range {
    my AxKit2::HTTPHeaders $self = $_[0];
    my $size = $_[1];

    my $not_satisfiable;
    my $range = $self->header("Range");

    return 200 unless
        $range &&
        defined $size &&
        $range =~ /^bytes=(\d*)-(\d*)$/;

    my ($range_start, $range_end) = ($1, $2);

    undef $range_start if $range_start eq '';
    undef $range_end if $range_end eq '';
    return 200 unless defined($range_start) or defined($range_end);

    if (defined($range_start) and defined($range_end) and $range_start > $range_end)  {
        return 416;
    } elsif (not defined($range_start) and defined($range_end) and $range_end == 0)  {
        return 416;
    } elsif (defined($range_start) and $size <= $range_start) {
        return 416;
    }

    $range_start = 0        unless defined($range_start);
    $range_end  = $size - 1 unless defined($range_end) and $range_end < $size;

    return (206, $range_start, $range_end);
}


1;
