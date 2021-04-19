package CGI::Tiny;

use strict;
use warnings;
use Carp ();
use IO::Handle ();
use Exporter 'import';

our $VERSION = '0.002';

our @EXPORT = 'cgi';

# List from HTTP::Status 6.29
# Unmarked codes are from RFC 7231 (2017-12-20)
my %HTTP_STATUS = (
    100 => 'Continue',
    101 => 'Switching Protocols',
    102 => 'Processing',                      # RFC 2518: WebDAV
    103 => 'Early Hints',                     # RFC 8297: Indicating Hints
    200 => 'OK',
    201 => 'Created',
    202 => 'Accepted',
    203 => 'Non-Authoritative Information',
    204 => 'No Content',
    205 => 'Reset Content',
    206 => 'Partial Content',                 # RFC 7233: Range Requests
    207 => 'Multi-Status',                    # RFC 4918: WebDAV
    208 => 'Already Reported',                # RFC 5842: WebDAV bindings
    226 => 'IM Used',                         # RFC 3229: Delta encoding
    300 => 'Multiple Choices',
    301 => 'Moved Permanently',
    302 => 'Found',
    303 => 'See Other',
    304 => 'Not Modified',                    # RFC 7232: Conditional Request
    305 => 'Use Proxy',
    307 => 'Temporary Redirect',
    308 => 'Permanent Redirect',              # RFC 7528: Permanent Redirect
    400 => 'Bad Request',
    401 => 'Unauthorized',                    # RFC 7235: Authentication
    402 => 'Payment Required',
    403 => 'Forbidden',
    404 => 'Not Found',
    405 => 'Method Not Allowed',
    406 => 'Not Acceptable',
    407 => 'Proxy Authentication Required',   # RFC 7235: Authentication
    408 => 'Request Timeout',
    409 => 'Conflict',
    410 => 'Gone',
    411 => 'Length Required',
    412 => 'Precondition Failed',             # RFC 7232: Conditional Request
    413 => 'Payload Too Large',
    414 => 'URI Too Long',
    415 => 'Unsupported Media Type',
    416 => 'Range Not Satisfiable',           # RFC 7233: Range Requests
    417 => 'Expectation Failed',
    418 => 'I\'m a teapot',                   # RFC 2324: HTCPC/1.0  1-april
    421 => 'Misdirected Request',             # RFC 7540: HTTP/2
    422 => 'Unprocessable Entity',            # RFC 4918: WebDAV
    423 => 'Locked',                          # RFC 4918: WebDAV
    424 => 'Failed Dependency',               # RFC 4918: WebDAV
    425 => 'Too Early',                       # RFC 8470: Using Early Data in HTTP
    426 => 'Upgrade Required',
    428 => 'Precondition Required',           # RFC 6585: Additional Codes
    429 => 'Too Many Requests',               # RFC 6585: Additional Codes
    431 => 'Request Header Fields Too Large', # RFC 6585: Additional Codes
    451 => 'Unavailable For Legal Reasons',   # RFC 7725: Legal Obstacles
    500 => 'Internal Server Error',
    501 => 'Not Implemented',
    502 => 'Bad Gateway',
    503 => 'Service Unavailable',
    504 => 'Gateway Timeout',
    505 => 'HTTP Version Not Supported',
    506 => 'Variant Also Negotiates',         # RFC 2295: Transparant Ngttn
    507 => 'Insufficient Storage',            # RFC 4918: WebDAV
    508 => 'Loop Detected',                   # RFC 5842: WebDAV bindings
    509 => 'Bandwidth Limit Exceeded',        #           Apache / cPanel
    510 => 'Not Extended',                    # RFC 2774: Extension Framework
    511 => 'Network Authentication Required', # RFC 6585: Additional Codes
);

sub cgi (&) {
  my ($handler) = @_;
  my $cgi = bless {}, __PACKAGE__;
  my ($error, $errored);
  {
    local $@;
    eval { $handler->($cgi); die "No response rendered by cgi\n" unless $cgi->{headers_rendered}; 1 }
      or do { $error = $@; $errored = 1 };
  }
  if ($errored) {
    my $caller = caller;
    $cgi->set_response_status(500) unless $cgi->{headers_rendered} or defined $cgi->{response_status};
    if (defined(my $handler = $cgi->{on_error})) {
      my ($error_error, $error_errored);
      {
        local $@;
        eval { $handler->($cgi, $error); 1 } or do { $error_error = $@; $error_errored = 1 };
      }
      if ($error_errored) {
        warn "Exception in error handler: $error_error";
        warn "Original error: $error";
      }
    } else {
      warn $error;
    }
    $cgi->render(text => 'Internal Server Error') unless $cgi->{headers_rendered};
  }
  1;
}

sub set_error_handler { $_[0]{on_error} = $_[1]; $_[0] }
sub request_body_limit {
  return defined $_[0]{request_body_limit} ? $_[0]{request_body_limit} :
    ($_[0]{request_body_limit} = defined $ENV{CGI_TINY_REQUEST_BODY_LIMIT} ? $ENV{CGI_TINY_REQUEST_BODY_LIMIT} : 16777216);
}
sub set_request_body_limit { $_[0]{request_body_limit} = $_[1]; $_[0] }
sub set_input_handle       { $_[0]{input_handle} = $_[1]; $_[0] }
sub set_output_handle      { $_[0]{output_handle} = $_[1]; $_[0] }

sub auth_type         { defined $ENV{AUTH_TYPE} ? $ENV{AUTH_TYPE} : '' }
sub content_length    { defined $ENV{CONTENT_LENGTH} ? $ENV{CONTENT_LENGTH} : '' }
sub content_type      { defined $ENV{CONTENT_TYPE} ? $ENV{CONTENT_TYPE} : '' }
sub gateway_interface { defined $ENV{GATEWAY_INTERFACE} ? $ENV{GATEWAY_INTERFACE} : '' }
sub path_info         { defined $ENV{PATH_INFO} ? $ENV{PATH_INFO} : '' }
sub path_translated   { defined $ENV{PATH_TRANSLATED} ? $ENV{PATH_TRANSLATED} : '' }
sub query_string      { defined $ENV{QUERY_STRING} ? $ENV{QUERY_STRING} : '' }
sub remote_addr       { defined $ENV{REMOTE_ADDR} ? $ENV{REMOTE_ADDR} : '' }
sub remote_host       { defined $ENV{REMOTE_HOST} ? $ENV{REMOTE_HOST} : '' }
sub remote_ident      { defined $ENV{REMOTE_IDENT} ? $ENV{REMOTE_IDENT} : '' }
sub remote_user       { defined $ENV{REMOTE_USER} ? $ENV{REMOTE_USER} : '' }
sub request_method    { defined $ENV{REQUEST_METHOD} ? $ENV{REQUEST_METHOD} : '' }
sub script_name       { defined $ENV{SCRIPT_NAME} ? $ENV{SCRIPT_NAME} : '' }
sub server_name       { defined $ENV{SERVER_NAME} ? $ENV{SERVER_NAME} : '' }
sub server_port       { defined $ENV{SERVER_PORT} ? $ENV{SERVER_PORT} : '' }
sub server_protocol   { defined $ENV{SERVER_PROTOCOL} ? $ENV{SERVER_PROTOCOL} : '' }
sub server_software   { defined $ENV{SERVER_SOFTWARE} ? $ENV{SERVER_SOFTWARE} : '' }
*method = \&request_method;
*path = \&path_info;
*query = \&query_string;

sub query_pairs { [@{$_[0]->_query_params->{ordered}}] }
sub query_params {
  my ($self) = @_;
  my %params;
  my $keyed = $self->_query_params->{keyed};
  foreach my $key (keys %$keyed) {
    my @values = @{$keyed->{$key}};
    $params{$key} = @values > 1 ? \@values : $values[0];
  }
  return \%params;
}
sub query_param       { my $p = $_[0]->_query_params->{keyed}; exists $p->{$_[1]} ? $p->{$_[1]}[-1] : undef }
sub query_param_array { my $p = $_[0]->_query_params->{keyed}; exists $p->{$_[1]} ? [@{$p->{$_[1]}}] : [] }

sub _query_params {
  my ($self) = @_;
  unless (exists $self->{query_params}) {
    my (@ordered, %keyed);
    foreach my $pair (split /[&;]/, $self->query) {
      my ($key, $value) = split /=/, $pair, 2;
      $value = '' unless defined $value;
      do { tr/+/ /; s/%([0-9a-fA-F]{2})/chr hex $1/ge; utf8::decode $_ } for $key, $value;
      push @ordered, [$key, $value];
      push @{$keyed{$key}}, $value;
    }
    $self->{query_params} = {ordered => \@ordered, keyed => \%keyed};
  }
  return $self->{query_params};
}

sub headers { +{%{$_[0]->_headers}} }
sub header { (my $name = $_[1]) =~ tr/-/_/; $ENV{"HTTP_\U$name"} }

sub _headers {
  my ($self) = @_;
  unless (exists $self->{request_headers}) {
    my %headers;
    foreach my $key (keys %ENV) {
      my $name = $key;
      next unless $name =~ s/^HTTP_//;
      $name =~ tr/_/-/;
      $headers{lc $name} = $ENV{$key};
    }
    $self->{request_headers} = \%headers;
  }
  return $self->{request_headers};
}

sub body {
  my ($self) = @_;
  unless (exists $self->{content}) {
    my $limit = $self->request_body_limit;
    my $length = $ENV{CONTENT_LENGTH} || 0;
    if ($limit and $length > $limit) {
      $self->set_response_status(413);
      die "Request body limit exceeded\n";
    }
    $_[0]{content} = '';
    my $offset = 0;
    my $in_fh = defined $self->{input_handle} ? $self->{input_handle} : *STDIN;
    binmode $in_fh;
    while ($length > 0) {
      my $chunk = 131072;
      $chunk = $length if $length and $length < $chunk;
      last unless my $read = read $in_fh, $_[0]{content}, $chunk, $offset;
      $offset += $read;
      $length -= $read;
    }
  }
  return $self->{content};
}

sub body_pairs { [@{$_[0]->_body_params->{ordered}}] }
sub body_params {
  my ($self) = @_;
  my %params;
  my $keyed = $self->_body_params->{keyed};
  foreach my $key (keys %$keyed) {
    my @values = @{$keyed->{$key}};
    $params{$key} = @values > 1 ? \@values : $values[0];
  }
  return \%params;
}
sub body_param       { my $p = $_[0]->_body_params->{keyed}; exists $p->{$_[1]} ? $p->{$_[1]}[-1] : undef }
sub body_param_array { my $p = $_[0]->_body_params->{keyed}; exists $p->{$_[1]} ? [@{$p->{$_[1]}}] : [] }

sub _body_params {
  my ($self) = @_;
  unless (exists $self->{body_params}) {
    my (@ordered, %keyed);
    my $content_type = $self->content_type;
    if (defined $content_type and $content_type =~ m/^application\/x-www-form-urlencoded/i) {
      foreach my $pair (split /&/, $self->body) {
        my ($key, $value) = split /=/, $pair, 2;
        $value = '' unless defined $value;
        do { tr/+/ /; s/%([0-9a-fA-F]{2})/chr hex $1/ge; utf8::decode $_ } for $key, $value;
        push @ordered, [$key, $value];
        push @{$keyed{$key}}, $value;
      }
    }
    $self->{body_params} = {ordered => \@ordered, keyed => \%keyed};
  }
  return $self->{body_params};
}

sub body_json {
  my ($self) = @_;
  unless (exists $self->{body_json}) {
    my $content_type = $self->content_type;
    if (defined $content_type and $content_type =~ m/^application\/json/i) {
      $self->{body_json} = $self->_json->decode($self->body);
    }
  }
  return $self->{body_json};
}

sub set_response_status {
  my ($self, $status) = @_;
  if ($self->{headers_rendered}) {
    Carp::carp "Attempted to set HTTP response status but headers have already been rendered";
  } else {
    Carp::croak "Attempted to set unknown HTTP response status $status" unless exists $HTTP_STATUS{$status};
    $self->{response_status} = "$status $HTTP_STATUS{$status}";
  }
  return $self;
}

sub set_response_content_type {
  my ($self, $content_type) = @_;
  if ($self->{headers_rendered}) {
    Carp::carp "Attempted to set HTTP response content type but headers have already been rendered";
  } else {
    $self->{response_content_type} = $content_type;
  }
  return $self;
}

sub add_response_header {
  my ($self, $name, $value) = @_;
  if ($self->{headers_rendered}) {
    Carp::carp "Attempted to add HTTP response header '$name' but headers have already been rendered";
  } else {
    push @{$self->{response_headers}}, [$name, $value];
  }
  return $self;
}

sub response_charset     { defined $_[0]{response_charset} ? $_[0]{response_charset} : ($_[0]{response_charset} = 'UTF-8') }
sub set_response_charset { $_[0]{response_charset} = $_[1]; $_[0] }

sub headers_rendered { $_[0]{headers_rendered} }

my %known_types = (json => 1, html => 1, xml => 1, text => 1, data => 1, redirect => 1);

sub render {
  my ($self, $type, $data) = @_;
  $type = '' unless defined $type;
  Carp::croak "Don't know how to render '$type'" if length $type and !exists $known_types{$type};
  my $charset = $self->response_charset;
  my $out_fh = defined $self->{output_handle} ? $self->{output_handle} : *STDOUT;
  if (!$self->{headers_rendered}) {
    my @headers = @{$self->{response_headers} || []};
    my $headers_str = '';
    my %headers_set;
    foreach my $header (@headers) {
      my ($name, $value) = @$header;
      $headers_str .= "$name: $value\r\n";
      $headers_set{lc $name} = 1;
    }
    if (!$headers_set{location} and $type eq 'redirect') {
      $headers_str = "Location: $data\r\n$headers_str";
    }
    if (!$headers_set{'content-type'} and $type ne 'redirect') {
      my $content_type = $self->{response_content_type};
      $content_type =
          $type eq 'json' ? 'application/json;charset=UTF-8'
        : $type eq 'html' ? "text/html;charset=$charset"
        : $type eq 'xml'  ? "application/xml;charset=$charset"
        : $type eq 'text' ? "text/plain;charset=$charset"
        : 'application/octet-stream'
        unless defined $content_type;
      $headers_str = "Content-Type: $content_type\r\n$headers_str";
    }
    if (!$headers_set{status}) {
      if (defined(my $status = $self->{response_status})) {
        $headers_str = "Status: $status\r\n$headers_str";
      } elsif ($type eq 'redirect') {
        $headers_str = "Status: 302 $HTTP_STATUS{302}\r\n$headers_str";
      }
    }
    $headers_str .= "\r\n";
    binmode $out_fh;
    $out_fh->printflush($headers_str);
    $self->{headers_rendered} = 1;
  } elsif ($type eq 'redirect') {
    Carp::carp "Attempted to render a redirect but headers have already been rendered";
  }
  if ($type eq 'json') {
    $out_fh->printflush($self->_json->encode($data));
  } elsif ($type eq 'html' or $type eq 'xml' or $type eq 'text') {
    require Encode;
    $out_fh->printflush(Encode::encode($charset, "$data"));
  } elsif ($type eq 'data') {
    $out_fh->printflush($data);
  }
}

sub _json {
  my ($self) = @_;
  unless (exists $self->{json}) {
    local $@;
    if (eval { require Cpanel::JSON::XS; Cpanel::JSON::XS->VERSION('4.09'); 1 }) {
      $self->{json} = Cpanel::JSON::XS->new->allow_dupkeys->stringify_infnan;
    } else {
      require JSON::PP;
      $self->{json} = JSON::PP->new;
    }
    $self->{json}->utf8->canonical->allow_nonref->allow_unknown->allow_blessed->convert_blessed->escape_slash;
  }
  return $self->{json};
}

1;

=head1 NAME

CGI::Tiny - Common Gateway Interface, with no frills

=head1 SYNOPSIS

  #!/usr/bin/perl
  use strict;
  use warnings;
  use CGI::Tiny;

  cgi {
    my ($cgi) = @_;
    $cgi->set_error_handler(sub {
      my ($cgi, $error) = @_;
      warn $error;
      $cgi->render(json => {error => 'Internal Error'}) unless $cgi->headers_rendered;
    });
    my $method = $cgi->method;
    my $fribble;
    if ($method eq 'GET') {
      $fribble = $cgi->query_param('fribble');
    } elsif ($method eq 'POST') {
      $fribble = $cgi->body_param('fribble');
    } else {
      $cgi->set_response_status(405);
      return $cgi->render;
    }
    die "Invalid fribble parameter" unless length $fribble;
    $cgi->render(json => {fribble => $fribble});
  };

=head1 DESCRIPTION

CGI::Tiny provides a modern interface to write
L<CGI|https://en.wikipedia.org/wiki/Common_Gateway_Interface> scripts to
dynamically respond to HTTP requests. It is intended to be:

=over

=item * Minimal

CGI::Tiny contains a small amount of code and (on modern Perls) no non-core
requirements. No framework needed.

=item * Simple

CGI::Tiny is straightforward to use, avoids anything magical or surprising, and
provides easy access to the most commonly needed features.

=item * Robust

CGI::Tiny's interface is designed to help the developer avoid common pitfalls
and vulnerabilities by default.

=item * Lazy

CGI::Tiny only loads code or processes information once it is needed, so simple
requests can be handled without unnecessary overhead.

=item * Restrained

CGI::Tiny is designed for the CGI protocol which executes the program again for
every request. It is not suitable for persistent protocols like FastCGI or
PSGI.

=item * Flexible

CGI::Tiny can be used with other modules to handle tasks like routing and
templating, and doesn't impose unnecessary constraints to reading input or
rendering output.

=back

This module's interface is currently I<EXPERIMENTAL> and may be changed
incompatibly if needed.

=head1 USAGE

=for Pod::Coverage cgi

CGI::Tiny's interface is a regular function called C<cgi> exported by default.

  cgi {
    my ($cgi) = @_;
    # set up error handling on $cgi
    # inspect request data via $cgi
    # set response headers if needed via $cgi
    # render response data with $cgi->render
  };

The code block is immediately run and passed a CGI::Tiny object, which
L</"METHODS"> can be called on to read request information and render a
response.

If an exception is thrown within the code block, or the code block does not
render a response, it will run the handler set by L</"set_error_handler"> if
any, or by default emit the error as a warning and (if nothing has been
rendered yet) render a 500 Internal Server Error.

=head1 EXTENDING

CGI::Tiny is a minimal interface to the CGI protocol, but can be extended with
the use of other CPAN modules.

=head2 JSON

CGI::Tiny has built in support for parsing and rendering JSON content with
L<JSON::PP>. CGI scripts that deal with JSON content will greatly benefit from
installing L<Cpanel::JSON::XS> version C<4.09> or newer for efficient encoding
and decoding, which will be used automatically if available.

=head2 Templating

HTML and XML responses are most easily managed with templating. A number of
CPAN modules provide this capability.

L<Text::Xslate> is an efficient template engine designed for HTML/XML.

  #!/usr/bin/perl
  use strict;
  use warnings;
  use utf8;
  use CGI::Tiny;
  use Text::Xslate;
  use Data::Section::Simple 'get_data_section';

  cgi {
    my ($cgi) = @_;
    my $foo = $cgi->query_param('foo');
    my $tx = Text::Xslate->new(path => ['templates'], cache => 0);

    # from templates/
    $cgi->render(html => $tx->render('index.tx', {foo => $foo}));

    # from __DATA__
    my $template = get_data_section 'index.tx';
    $cgi->render(html => $tx->render_string($template, {foo => $foo}));
  };

  __DATA__
  @@ index.tx
  <html><body><h1><: $foo :></h1></body></html>

L<Mojo::Template> is a lightweight HTML/XML template engine in the L<Mojo>
toolkit.

  #!/usr/bin/perl
  use strict;
  use warnings;
  use utf8;
  use CGI::Tiny;
  use Mojo::Template;
  use Mojo::File 'curfile';
  use Mojo::Loader 'data_section';

  cgi {
    my ($cgi) = @_;
    my $foo = $cgi->query_param('foo');
    my $mt = Mojo::Template->new(auto_escape => 1, vars => 1);

    # from templates/
    my $template_path = curfile->sibling('templates', 'index.html.ep');
    $cgi->render(html => $mt->render_file($template_path, {foo => $foo}));

    # from __DATA__
    my $template = data_section __PACKAGE__, 'index.html.ep';
    $cgi->render(html => $mt->render($template, {foo => $foo}));
  };

  __DATA__
  @@ index.html.ep
  <html><body><h1><%= $foo %></h1></body></html>

=head2 Routing

Web applications use routing to serve multiple types of requests from one
application. L<Routes::Tiny> can be used to organize this with CGI::Tiny, using
C<REQUEST_METHOD> and C<PATH_INFO> (which is the URL path after the CGI script
name).

  #!/usr/bin/perl
  use strict;
  use warnings;
  use CGI::Tiny;
  use Routes::Tiny;

  my %dispatch = (
    foos => sub {
      my ($cgi) = @_;
      my $method = $cgi->method;
      ...
    },
    get_foo => sub {
      my ($cgi, $captures) = @_;
      my $id = $captures->{id};
      ...
    },
    put_foo => sub {
      my ($cgi, $captures) = @_;
      my $id = $captures->{id};
      ...
    },
  );

  cgi {
    my ($cgi) = @_;

    my $routes = Routes::Tiny->new;
    # /script.cgi/foo
    $routes->add_route('/foo', name => 'foos');
    # /script.cgi/foo/42
    $routes->add_route('/foo/:id', method => 'GET', name => 'get_foo');
    $routes->add_route('/foo/:id', method => 'PUT', name => 'put_foo');

    if (defined(my $match = $routes->match($cgi->path, method => $cgi->method))) {
      $dispatch{$match->name}->($cgi, $match->captures);
    } else {
      $cgi->set_response_status(404);
      $cgi->render(text => 'Not Found');
    }
  };

=head1 METHODS

The following methods can be called on the CGI::Tiny object provided to the
C<cgi> code block.

=head2 Setup

=head3 set_error_handler

  $cgi = $cgi->set_error_handler(sub {
    my ($cgi, $error) = @_;
    ...
  });

Sets an error handler to run in the event of an exception. If the response
status has not been set by L</"set_response_status"> or rendering headers, it
will default to 500 when this handler is called.

The error value can be any exception thrown by Perl or user code. It should
generally not be included in any response rendered to the client, but instead
warned or logged.

Exceptions may occur before or after response headers have been rendered, so
error handlers should render some response if L</"headers_rendered"> is
false. If no response has been rendered after the error handler completes, the
default 500 Internal Server Error response will be rendered.

=head3 request_body_limit

  my $limit = $cgi->request_body_limit;

Limit in bytes for parsing a request body into memory, defaults to the value of
the C<CGI_TINY_REQUEST_BODY_LIMIT> environment variable or 16777216 (16 MiB).
Since the request body is not parsed until needed, methods that parse the whole
request body into memory like L</"body"> will set the response status to
C<413 Payload Too Large> and throw an exception if the content length is over
the limit. A value of 0 will remove the limit (not recommended unless you have
other safeguards on memory usage).

=head3 set_request_body_limit

  $cgi = $cgi->set_request_body_limit(16*1024*1024);

Sets L</"request_body_limit">.

=head3 set_input_handle

  $cgi = $cgi->set_input_handle($fh);

Sets the input handle to read the request body from. If not set, reads from
C<STDIN>. The handle will have C<binmode> applied before reading to remove any
translation layers.

=head3 set_output_handle

  $cgi = $cgi->set_output_handle($fh);

Sets the output handle to print the response to. If not set, prints to
C<STDOUT>. The handle will have C<binmode> applied before printing to remove
any translation layers.

=head2 Request

=head3 auth_type

=head3 content_length

=head3 content_type

=head3 gateway_interface

=head3 path_info

=head3 path_translated

=head3 query_string

=head3 remote_addr

=head3 remote_host

=head3 remote_ident

=head3 remote_user

=head3 request_method

=head3 script_name

=head3 server_name

=head3 server_port

=head3 server_protocol

=head3 server_software

  my $type   = $cgi->content_type;   # CONTENT_TYPE
  my $method = $cgi->request_method; # REQUEST_METHOD
  my $port   = $cgi->server_port;    # SERVER_PORT

Access to L<request meta-variables|https://tools.ietf.org/html/rfc3875#section-4.1>
of the equivalent uppercase names. Since CGI does not distinguish between
missing and empty values, missing values will be normalized to an empty string.

=head3 method

=head3 path

=head3 query

  my $method = $cgi->method; # REQUEST_METHOD
  my $path   = $cgi->path;   # PATH_INFO
  my $query  = $cgi->query;  # QUERY_STRING

Short aliases for a few request meta-variables.

=head3 query_pairs

  my $pairs = $cgi->query_pairs;

Retrieve URL query string parameters as an array reference of two-element array
references.

=head3 query_params

  my $params = $cgi->query_params;

Retrieve URL query string parameters as a hash reference. If a parameter name
is passed multiple times, its value will be an array reference.

=head3 query_param

  my $value = $cgi->query_param('foo');

Retrieve value of a named URL query string parameter. If the parameter name is
passed multiple times, returns the last value. Use L</"query_param_array"> to
get multiple values of a parameter.

=head3 query_param_array

  my $arrayref = $cgi->query_param_array('foo');

Retrieve values of a named URL query string parameter as an array reference.

=head3 headers

  my $hashref = $cgi->headers;

Hash reference of available request header names and values. Header names are
represented in lowercase.

=head3 header

  my $value = $cgi->header('Accept');

Retrieve the value of a request header by name (case insensitive). CGI request
headers can only contain a single value, which may be combined from multiple
values.

=head3 body

  my $bytes = $cgi->body;

Retrieve the request body as bytes.

Note that this will read the whole request body into memory, so make sure the
L</"request_body_limit"> can fit well within the available memory.

=head3 body_pairs

  my $pairs = $cgi->body_pairs;

Retrieve C<x-www-form-urlencoded> body parameters as an array reference of
two-element array references.

Note that this will read the whole request body into memory, so make sure the
L</"request_body_limit"> can fit well within the available memory.

=head3 body_params

  my $params = $cgi->body_params;

Retrieve C<x-www-form-urlencoded> body parameters as a hash reference. If a
parameter name is passed multiple times, its value will be an array reference.

Note that this will read the whole request body into memory, so make sure the
L</"request_body_limit"> can fit well within the available memory.

=head3 body_param

  my $value = $cgi->body_param('foo');

Retrieve value of a named C<x-www-form-urlencoded> body parameter. If the
parameter name is passed multiple times, returns the last value. Use
L</"body_param_array"> to get multiple values of a parameter.

Note that this will read the whole request body into memory, so make sure the
L</"request_body_limit"> can fit well within the available memory.

=head3 body_param_array

  my $arrayref = $cgi->body_param_array('foo');

Retrieve values of a named C<x-www-form-urlencoded> body parameter as an array
reference.

Note that this will read the whole request body into memory, so make sure the
L</"request_body_limit"> can fit well within the available memory.

=head3 body_json

  my $data = $cgi->body_json;

Decode an C<application/json> request body from UTF-8-encoded JSON.

Note that this will read the whole request body into memory, so make sure the
L</"request_body_limit"> can fit well within the available memory.

=head2 Response

=head3 set_response_status

  $cgi = $cgi->set_response_status(404);

Sets the response HTTP status code. No effect after response headers have been
rendered. The CGI protocol assumes a status of C<200 OK> if no response status
is set.

=head3 set_response_content_type

  $cgi = $cgi->set_response_content_type('application/xml');

Sets the response Content-Type header, to override autodetection. No effect
after response headers have been rendered.

=head3 add_response_header

  $cgi = $cgi->add_response_header('Content-Disposition' => 'attachment');

Adds a response header. No effect after response headers have been rendered.

Note that header names are case insensitive and CGI::Tiny does not attempt to
deduplicate or munge headers that have been added manually. Headers are printed
in the response in the same order added, and adding the same header multiple
times will result in multiple instances of that response header.

=head3 response_charset

  my $charset = $cgi->response_charset;

Charset to use when rendering C<text>, C<html>, or C<xml> response data,
defaults to C<UTF-8>.

=head3 set_response_charset

  $cgi = $cgi->set_response_charset('UTF-8');

Sets L</"response_charset">.

=head3 headers_rendered

  my $bool = $cgi->headers_rendered;

Returns true if response headers have been rendered, such as by the first call
to L</"render">.

=head3 render

  $cgi->render;
  $cgi->render(html => $html);
  $cgi->render(xml  => $xml);
  $cgi->render(text => $text);
  $cgi->render(data => $bytes);
  $cgi->render(json => $ref);
  $cgi->render(redirect => $url);

Renders response data of a type indicated by the first parameter, if any. The
first time it is called will render response headers and set
L</"headers_rendered">, and it may be called additional times with more
response data.

The C<Content-Type> response header will be set according to
L</"set_response_content_type">, or autodetected depending on the data type
passed in the first call to C<render>, or to C<application/octet-stream> if
there is no more appropriate value.

C<html>, C<xml>, or C<text> data is expected to be decoded characters, and will
be encoded according to L</"response_charset">. C<json> data will be encoded to
UTF-8.

C<redirect> will print a redirection header if response headers have not yet
been rendered, and will set a response status of 302 if none has been set by
L</"set_response_status">. It will not set a C<Content-Type> response header.
If response headers have already been rendered a warning will be emitted.

=head1 ENVIRONMENT

CGI::Tiny recognizes the following environment variables, in addition to the
standard CGI environment variables.

=head2 CGI_TINY_REQUEST_BODY_LIMIT

Default value for L</"request_body_limit">.

=head1 CAVEATS

CGI is an extremely simplistic protocol and relies particularly on the global
state of environment variables and the C<STDIN> and C<STDOUT> standard
filehandles. CGI::Tiny does not prevent you from messing with these interfaces
directly, but it may result in confusion.

Most applications are better written in a L<PSGI>-compatible framework (e.g.
L<Dancer2> or L<Mojolicious>) and deployed in a persistent application server
so that the application does not have to start up again every time it receives
a request.

=head1 TODO

=over

=item * Uploads/multipart request

=item * Cookies

=item * NPH

=back

=head1 BUGS

Report any issues on the public bugtracker.

=head1 AUTHOR

Dan Book <dbook@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2021 by Dan Book.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=head1 SEE ALSO

L<CGI::Alternatives>, L<Mojolicious>, L<Dancer2>
