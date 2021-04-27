package CGI::Tiny;
# ABSTRACT: Common Gateway Interface, with no frills

use strict;
use warnings;
use Carp ();
use IO::Handle ();
use Exporter 'import';

our $VERSION = '0.007';

use constant DEFAULT_REQUEST_BODY_LIMIT => 16777216;
use constant DEFAULT_REQUEST_BODY_BUFFER => 131072;

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

my @DAYS_OF_WEEK = qw(Sun Mon Tue Wed Thu Fri Sat);
my @MONTH_NAMES = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
my %MONTH_NUMS;
@MONTH_NUMS{@MONTH_NAMES} = 0..11;

sub epoch_to_date {
  my ($sec,$min,$hour,$mday,$mon,$year,$wday) = gmtime $_[0];
  return sprintf '%s, %02d %s %04d %02d:%02d:%02d GMT',
    $DAYS_OF_WEEK[$wday], $mday, $MONTH_NAMES[$mon], $year + 1900, $hour, $min, $sec;
}

sub date_to_epoch {
  # RFC 1123 (Sun, 06 Nov 1994 08:49:37 GMT)
  my ($mday,$mon,$year,$hour,$min,$sec) = $_[0] =~ m/^ (?:Sun|Mon|Tue|Wed|Thu|Fri|Sat),
    [ ] ([0-9]{2}) [ ] (Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec) [ ] ([0-9]{4})
    [ ] ([0-9]{2}) : ([0-9]{2}) : ([0-9]{2}) [ ] GMT $/x;

  # RFC 850 (Sunday, 06-Nov-94 08:49:37 GMT)
  ($mday,$mon,$year,$hour,$min,$sec) = $_[0] =~ m/^ (?:Sun|Mon|Tues|Wednes|Thurs|Fri|Satur)day,
    [ ] ([0-9]{2}) - (Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec) - ([0-9]{2})
    [ ] ([0-9]{2}) : ([0-9]{2}) : ([0-9]{2}) [ ] GMT $/x unless defined $mday;

  # asctime (Sun Nov  6 08:49:37 1994)
  ($mon,$mday,$hour,$min,$sec,$year) = $_[0] =~ m/^ (?:Sun|Mon|Tue|Wed|Thu|Fri|Sat)
    [ ] (Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec) [ ]{1,2} ([0-9]{1,2})
    [ ] ([0-9]{2}) : ([0-9]{2}) : ([0-9]{2}) [ ] ([0-9]{4}) $/x unless defined $mday;

  return undef unless defined $mday;

  require Time::Local;
  # 4 digit years interpreted literally, but may have leading zeroes
  # 2 digit years interpreted with best effort heuristic
  return scalar Time::Local::timegm($sec, $min, $hour, $mday, $MONTH_NUMS{$mon},
    (length($year) == 4 && $year < 1900) ? $year - 1900 : $year);
}

# for cleanup in END in case of premature exit
my %PENDING_CGI;

sub cgi (&) {
  my ($handler) = @_;
  my $cgi = bless {pid => $$}, __PACKAGE__;
  my $cgi_key = 0+$cgi;
  $PENDING_CGI{$cgi_key} = $cgi; # don't localize, so premature exit can clean up in END
  my ($error, $errored);
  {
    local $@;
    eval { local $_ = $cgi; $handler->(); 1 } or do { $error = $@; $errored = 1 };
  }
  if ($errored) {
    _handle_error($cgi, $error);
  } elsif (!$cgi->{headers_rendered}) {
    _handle_error($cgi, "cgi completed without rendering a response\n");
  }
  delete $PENDING_CGI{$cgi_key};
  1;
}

# cleanup of premature exit, more reliable than potentially doing this in global destruction
# ModPerl::Registry or CGI::Compile won't run END after each request,
# but they override exit to throw an exception which we handle already
END {
  foreach my $key (keys %PENDING_CGI) {
    my $cgi = delete $PENDING_CGI{$key};
    _handle_error($cgi, "cgi exited without rendering a response\n") unless $cgi->{headers_rendered};
  }
}

sub _handle_error {
  my ($cgi, $error) = @_;
  return unless $cgi->{pid} == $$; # in case of fork
  $cgi->{response_status} = "500 $HTTP_STATUS{500}" unless $cgi->{headers_rendered} or defined $cgi->{response_status};
  if (defined(my $handler = $cgi->{on_error})) {
    my ($error_error, $error_errored);
    {
      local $@;
      eval { $handler->($cgi, $error); 1 } or do { $error_error = $@; $error_errored = 1 };
    }
    return unless $cgi->{pid} == $$; # in case of fork in error handler
    if ($error_errored) {
      warn "Exception in error handler: $error_error";
      warn "Original error: $error";
    }
  } else {
    warn $error;
  }
  $cgi->render(text => $cgi->{response_status}) unless $cgi->{headers_rendered};
}

sub set_error_handler          { $_[0]{on_error} = $_[1]; $_[0] }
sub set_request_body_buffer    { $_[0]{request_body_buffer} = $_[1]; $_[0] }
sub set_request_body_limit     { $_[0]{request_body_limit} = $_[1]; $_[0] }
sub set_multipart_form_charset { $_[0]{multipart_form_charset} = $_[1]; $_[0] }
sub set_input_handle           { $_[0]{input_handle} = $_[1]; $_[0] }
sub set_output_handle          { $_[0]{output_handle} = $_[1]; $_[0] }

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

sub query_params      { [map { [@$_] } @{$_[0]->_query_params->{ordered}}] }
sub query_param_names { [keys %{$_[0]->_query_params->{keyed}}] }
sub query_param       { my $p = $_[0]->_query_params->{keyed}; exists $p->{$_[1]} ? $p->{$_[1]}[-1] : undef }
sub query_param_array { my $p = $_[0]->_query_params->{keyed}; exists $p->{$_[1]} ? [@{$p->{$_[1]}}] : [] }

sub _query_params {
  my ($self) = @_;
  unless (exists $self->{query_params}) {
    $self->{query_params} = {ordered => \my @ordered, keyed => \my %keyed};
    foreach my $pair (split /[&;]/, $self->query) {
      my ($name, $value) = split /=/, $pair, 2;
      $value = '' unless defined $value;
      do { tr/+/ /; s/%([0-9a-fA-F]{2})/chr hex $1/ge; utf8::decode $_ } for $name, $value;
      push @ordered, [$name, $value];
      push @{$keyed{$name}}, $value;
    }
  }
  return $self->{query_params};
}

sub headers {
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
  return {%{$self->{request_headers}}};
}

sub header { (my $name = $_[1]) =~ tr/-/_/; $ENV{"HTTP_\U$name"} }

sub cookies      { [map { [@$_] } @{$_[0]->_cookies->{ordered}}] }
sub cookie_names { [keys %{$_[0]->_cookies->{keyed}}] }
sub cookie       { my $c = $_[0]->_cookies->{keyed}; exists $c->{$_[1]} ? $c->{$_[1]}[-1] : undef }
sub cookie_array { my $c = $_[0]->_cookies->{keyed}; exists $c->{$_[1]} ? [@{$c->{$_[1]}}] : [] }

sub _cookies {
  my ($self) = @_;
  unless (exists $self->{request_cookies}) {
    my (@ordered, %keyed);
    if (defined $ENV{HTTP_COOKIE}) {
      foreach my $pair (split /\s*;\s*/, $ENV{HTTP_COOKIE}) {
        next unless length $pair;
        my ($name, $value) = split /=/, $pair, 2;
        next unless defined $value;
        push @ordered, [$name, $value];
        push @{$keyed{$name}}, $value;
      }
    }
    $self->{request_cookies} = {ordered => \@ordered, keyed => \%keyed};
  }
  return $self->{request_cookies};
}

sub body {
  my ($self) = @_;
  unless (exists $self->{body_content} or exists $self->{body_parts}) {
    $self->{body_content} = '';
    my $length = $self->_body_length;
    my $in_fh = defined $self->{input_handle} ? $self->{input_handle} : *STDIN;
    binmode $in_fh;
    while ($length > 0) {
      my $chunk = $self->{request_body_buffer} || $ENV{CGI_TINY_REQUEST_BODY_BUFFER} || DEFAULT_REQUEST_BODY_BUFFER;
      $chunk = $length if $length < $chunk;
      last unless my $read = read $in_fh, $self->{body_content}, $chunk, length $self->{body_content};
      $length -= $read;
    }
  }
  return $self->{body_content};
}

sub body_params      { [map { [@$_] } @{$_[0]->_body_params->{ordered}}] }
sub body_param_names { [keys %{$_[0]->_body_params->{keyed}}] }
sub body_param       { my $p = $_[0]->_body_params->{keyed}; exists $p->{$_[1]} ? $p->{$_[1]}[-1] : undef }
sub body_param_array { my $p = $_[0]->_body_params->{keyed}; exists $p->{$_[1]} ? [@{$p->{$_[1]}}] : [] }

sub _body_params {
  my ($self) = @_;
  unless (exists $self->{body_params}) {
    $self->{body_params} = {ordered => \my @ordered, keyed => \my %keyed};
    if ($ENV{CONTENT_TYPE} and $ENV{CONTENT_TYPE} =~ m/^application\/x-www-form-urlencoded\b/i) {
      foreach my $pair (split /&/, $self->body) {
        my ($name, $value) = split /=/, $pair, 2;
        $value = '' unless defined $value;
        do { tr/+/ /; s/%([0-9a-fA-F]{2})/chr hex $1/ge; utf8::decode $_ } for $name, $value;
        push @ordered, [$name, $value];
        push @{$keyed{$name}}, $value;
      }
    } elsif ($ENV{CONTENT_TYPE} and $ENV{CONTENT_TYPE} =~ m/^multipart\/form-data\b/i) {
      my $default_charset = $self->{multipart_form_charset};
      $default_charset = 'UTF-8' unless defined $default_charset;
      foreach my $part (@{$self->_body_multipart}) {
        next if defined $part->{filename};
        my ($name, $value, $headers) = @$part{'name','content','headers'};
        if (uc $default_charset eq 'UTF-8' and do { local $@; eval { require Unicode::UTF8; 1 } }) {
          $name = Unicode::UTF8::decode_utf8($name);
        } elsif (length $default_charset) {
          require Encode;
          $name = Encode::decode($default_charset, "$name");
        }
        if (!defined $headers->{'content-type'} or $headers->{'content-type'} =~ m/^text\/plain\b/i) {
          my $value_charset = $default_charset;
          if (defined $headers->{'content-type'}) {
            if (my ($charset_quoted, $charset_unquoted) = $headers->{'content-type'} =~ m/;\s*charset=(?:"([^"]+)"|([^";]+))/i) {
              $value_charset = defined $charset_quoted ? $charset_quoted : $charset_unquoted;
            }
          }
          if (uc $value_charset eq 'UTF-8' and do { local $@; eval { require Unicode::UTF8; 1 } }) {
            $value = Unicode::UTF8::decode_utf8($value);
          } elsif (length $value_charset) {
            require Encode;
            $value = Encode::decode($value_charset, "$value");
          }
        }
        push @ordered, [$name, $value];
        push @{$keyed{$name}}, $value;
      }
    }
  }
  return $self->{body_params};
}

sub body_json {
  my ($self) = @_;
  unless (exists $self->{body_json}) {
    $self->{body_json} = undef;
    if ($ENV{CONTENT_TYPE} and $ENV{CONTENT_TYPE} =~ m/^application\/json\b/i) {
      $self->{body_json} = $self->_json->decode($self->body);
    }
  }
  return $self->{body_json};
}

sub body_parts {
  my ($self) = @_;
  return [] unless $ENV{CONTENT_TYPE} and $ENV{CONTENT_TYPE} =~ m/^multipart\/form-data\b/i;
  return [map { +{%$_} } @{$self->_body_multipart}];
}

sub uploads      { [map { [@$_] } @{$_[0]->_body_uploads->{ordered}}] }
sub upload_names { [keys %{$_[0]->_body_uploads->{keyed}}] }
sub upload       { my $u = $_[0]->_body_uploads->{keyed}; exists $u->{$_[1]} ? $u->{$_[1]}[-1] : undef }
sub upload_array { my $u = $_[0]->_body_uploads->{keyed}; exists $u->{$_[1]} ? [@{$u->{$_[1]}}] : [] }

sub _body_uploads {
  my ($self) = @_;
  unless (exists $self->{body_uploads}) {
    $self->{body_uploads} = {ordered => \my @ordered, keyed => \my %keyed};
    if ($ENV{CONTENT_TYPE} and $ENV{CONTENT_TYPE} =~ m/^multipart\/form-data\b/i) {
      my $default_charset = $self->{multipart_form_charset};
      $default_charset = 'UTF-8' unless defined $default_charset;
      foreach my $part (@{$self->_body_multipart}) {
        next unless defined $part->{filename};
        my ($name, $filename, $file, $size, $headers) = @$part{'name','filename','file','size','headers'};
        if (uc $default_charset eq 'UTF-8' and do { local $@; eval { require Unicode::UTF8; 1 } }) {
          $name = Unicode::UTF8::decode_utf8($name);
          $filename = Unicode::UTF8::decode_utf8($filename);
        } elsif (length $default_charset) {
          require Encode;
          $name = Encode::decode($default_charset, "$name");
          $filename = Encode::decode($default_charset, "$filename");
        }
        my $upload = {
          filename     => $filename,
          file         => $file,
          size         => $size,
          content_type => $headers->{'content-type'},
        };
        push @ordered, [$name, $upload];
        push @{$keyed{$name}}, $upload;
      }
    }
  }
  return $self->{body_uploads};
}

sub _body_length {
  my ($self) = @_;
  my $limit = $self->{request_body_limit};
  $limit = $ENV{CGI_TINY_REQUEST_BODY_LIMIT} unless defined $limit;
  $limit = DEFAULT_REQUEST_BODY_LIMIT unless defined $limit;
  my $length = $ENV{CONTENT_LENGTH} || 0;
  if ($limit and $length > $limit) {
    $self->{response_status} = "413 $HTTP_STATUS{413}" unless $self->{headers_rendered};
    die "Request body limit exceeded\n";
  }
  return $length;
}

sub _body_multipart {
  my ($self) = @_;
  unless (exists $self->{body_parts}) {
    $self->{body_parts} = [];
    my ($boundary_quoted, $boundary_unquoted) = $ENV{CONTENT_TYPE} =~ m/;\s*boundary\s*=\s*(?:"([^"]+)"|([^";]+))/i;
    my $boundary = defined $boundary_quoted ? $boundary_quoted : $boundary_unquoted;
    unless (defined $boundary) {
      $self->{response_status} = "400 $HTTP_STATUS{400}" unless $self->{headers_rendered};
      die "Malformed multipart/form-data request\n";
    }

    my ($input, $length);
    if (exists $self->{body_content}) {
      $length = length $self->{body_content};
      $input = \$self->{body_content};
    } else {
      $length = $self->_body_length;
      $input = defined $self->{input_handle} ? $self->{input_handle} : *STDIN;
      binmode $input;
    }
    my $parts = _parse_multipart($input, $length, $boundary, $self->{request_body_buffer});
    unless (defined $parts) {
      $self->{response_status} = "400 $HTTP_STATUS{400}" unless $self->{headers_rendered};
      die "Malformed multipart/form-data request\n";
    }
    $self->{body_parts} = $parts;
  }
  return $self->{body_parts};
}

sub _parse_multipart {
  my ($input, $length, $boundary, $buffer_size) = @_;
  my $buffer = "\r\n";
  my (%state, @parts);
  READER: while ($length > 0) {
    if (ref $input eq 'SCALAR') {
      $buffer .= $$input;
      $length = 0;
    } else {
      my $chunk = $buffer_size || $ENV{CGI_TINY_REQUEST_BODY_BUFFER} || DEFAULT_REQUEST_BODY_BUFFER;
      $chunk = $length if $length < $chunk;
      last unless my $read = read $input, $buffer, $chunk, length $buffer;
      $length -= $read;
    }

    if (!$state{started} and (my $pos = index $buffer, "\r\n--$boundary\r\n") >= 0) {
      substr $buffer, 0, $pos + length($boundary) + 6, '';
      $state{started} = 1;
      push @parts, $state{part} = {headers => {}, name => undef, filename => undef, size => 0};
    }
    next unless $state{started}; # read more to find start of multipart data

    while (length $buffer) {
      if ($state{parsing_body}) {
        my $append = '';
        my $pos;
        if (($pos = index $buffer, "\r\n--$boundary\r\n") >= 0) {
          $append = substr $buffer, 0, $pos, '';
          substr $buffer, 0, length($boundary) + 6, '';
          $state{parsing_body} = 0;
        } elsif (($pos = index $buffer, "\r\n--$boundary--") >= 0) {
          $append = substr $buffer, 0, $pos; # no replacement, we're done here
          $state{parsing_body} = 0;
          $state{done} = 1;
        } elsif (length($buffer) > length($boundary) + 6) {
          $append = substr $buffer, 0, length($buffer) - length($boundary) - 6, '';
        }

        if (defined $state{part}{filename}) {
          # create temp file even if empty
          unless (defined $state{part}{file}) {
            require File::Temp;
            $state{part}{file} = File::Temp->new;
            binmode $state{part}{file};
          }
          if (length $append) {
            $state{part}{file}->print($append);
            $state{part}{size} += length $append;
          }
          unless ($state{parsing_body}) { # finalize temp file
            $state{part}{file}->flush;
            seek $state{part}{file}, 0, 0;
          }
        } else {
          $state{part}{content} = '' unless defined $state{part}{content};
          if (length $append) {
            $state{part}{content} .= $append;
            $state{part}{size} += length $append;
          }
        }

        last READER if $state{done};         # end of multipart data
        next READER if $state{parsing_body}; # read more to find end of part

        # new part started
        push @parts, $state{part} = {headers => {}, name => undef, filename => undef, size => 0};
      } else { # part headers
        while ((my $pos = index $buffer, "\r\n") >= 0) {
          if ($pos == 0) { # end of headers
            substr $buffer, 0, 2, '';
            $state{parsing_body} = 1;
            last;
          }

          my $header = substr $buffer, 0, $pos + 2, '';
          my ($name, $value) = split /\s*:\s*/, $header, 2;
          return undef unless defined $value;
          $value =~ s/\s*\z//;

          $state{part}{headers}{lc $name} = $value;
          if (lc $name eq 'content-disposition') {
            if (my ($name_quoted, $name_unquoted) = $value =~ m/;\s*name\s*=\s*(?:"((?:\\"|[^";])*)"|([^";]*))/i) {
              $state{part}{name} = defined $name_quoted ? $name_quoted : $name_unquoted;
            }
            if (my ($filename_quoted, $filename_unquoted) = $value =~ m/;\s*filename\s*=\s*(?:"((?:\\"|[^"])*)"|([^";]*))/i) {
              $state{part}{filename} = defined $filename_quoted ? $filename_quoted : $filename_unquoted;
            }
          }
        }
        next READER unless $state{parsing_body}; # read more to find end of headers
      }
    }
  }
  return undef unless $state{done};

  return \@parts;
}

sub set_nph {
  my ($self, $value) = @_;
  if ($self->{headers_rendered}) {
    Carp::carp "Attempted to set NPH response mode but headers have already been rendered";
  } else {
    $self->{nph} = $value;
  }
  return $self;
}

sub set_response_status {
  my ($self, $status) = @_;
  if ($self->{headers_rendered}) {
    Carp::carp "Attempted to set HTTP response status but headers have already been rendered";
  } else {
    if ($status =~ m/\A[0-9]+ [^\r\n]*\z/) {
      $self->{response_status} = $status;
    } else {
      Carp::croak "Attempted to set unknown HTTP response status $status" unless exists $HTTP_STATUS{$status};
      $self->{response_status} = "$status $HTTP_STATUS{$status}";
    }
  }
  return $self;
}

sub set_response_content_type {
  my ($self, $content_type) = @_;
  if ($self->{headers_rendered}) {
    Carp::carp "Attempted to set HTTP response content type but headers have already been rendered";
  } else {
    Carp::croak "Newline characters not allowed in HTTP response content type" if $content_type =~ tr/\r\n//;
    $self->{response_content_type} = $content_type;
  }
  return $self;
}

sub set_response_charset {
  my ($self, $charset) = @_;
  Carp::croak "Space characters not allowed in HTTP response charset" if $charset =~ m/\s/;
  $self->{response_charset} = $charset;
  return $self;
}

sub add_response_header {
  my ($self, $name, $value) = @_;
  if ($self->{headers_rendered}) {
    Carp::carp "Attempted to add HTTP response header '$name' but headers have already been rendered";
  } else {
    Carp::croak "Newline characters not allowed in HTTP response header '$name'" if $value =~ tr/\r\n//;
    push @{$self->{response_headers}}, [$name, $value];
  }
  return $self;
}

my %COOKIE_ATTR_VALUE = (expires => 1, domain => 1, path => 1, secure => 0, httponly => 0, samesite => 1, 'max-age' => 1);
sub add_response_cookie {
  my ($self, $name, $value, @attrs) = @_;
  if ($self->{headers_rendered}) {
    Carp::carp "Attempted to add HTTP response cookie '$name' but headers have already been rendered";
  } else {
    my $cookie_str = "$name=$value";
    my $i = 0;
    while ($i <= $#attrs) {
      my ($key, $val) = @attrs[$i, $i+1];
      my $has_value = $COOKIE_ATTR_VALUE{lc $key};
      if (!defined $has_value) {
        Carp::carp "Attempted to set unknown cookie attribute '$key' for HTTP response cookie '$name'";
      } elsif ($has_value) {
        $cookie_str .= "; $key=$val" if defined $val;
      } else {
        $cookie_str .= "; $key" if $val;
      }
    } continue {
      $i += 2;
    }
    Carp::croak "Newline characters not allowed in HTTP response cookie '$name'" if $cookie_str =~ tr/\r\n//;
    push @{$self->{response_headers}}, ['Set-Cookie', $cookie_str];
  }
  return $self;
}

sub headers_rendered { $_[0]{headers_rendered} }

my %known_types = (json => 1, html => 1, xml => 1, text => 1, data => 1, redirect => 1);

sub render {
  my ($self, $type, $data) = @_;
  $type = '' unless defined $type;
  Carp::croak "Don't know how to render '$type'" if length $type and !exists $known_types{$type};
  my $charset = $self->{response_charset};
  $charset = 'UTF-8' unless defined $charset;
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
      Carp::croak "Newline characters not allowed in HTTP redirect" if $data =~ tr/\r\n//;
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
    if (!$headers_set{date}) {
      my $date_str = epoch_to_date(time);
      $headers_str = "Date: $date_str\r\n$headers_str";
    }
    my $status = $self->{response_status};
    $status = "302 $HTTP_STATUS{302}" if !defined $status and $type eq 'redirect';
    if ($self->{nph}) {
      $status = "200 $HTTP_STATUS{200}" unless defined $status;
      my $protocol = $ENV{SERVER_PROTOCOL};
      $protocol = 'HTTP/1.0' unless defined $protocol and length $protocol;
      $headers_str = "$protocol $status\r\n$headers_str";
      my $server = $ENV{SERVER_SOFTWARE};
      $headers_str .= "Server: $server\r\n" if defined $server and length $server;
    } elsif (!$headers_set{status} and defined $status) {
      $headers_str = "Status: $status\r\n$headers_str";
    }
    binmode $out_fh;
    $out_fh->printflush("$headers_str\r\n");
    $self->{headers_rendered} = 1;
  } elsif ($type eq 'redirect') {
    Carp::carp "Attempted to render a redirect but headers have already been rendered";
  }
  if ($type eq 'json') {
    $out_fh->printflush($self->_json->encode($data));
  } elsif ($type eq 'html' or $type eq 'xml' or $type eq 'text') {
    if (uc $charset eq 'UTF-8' and do { local $@; eval { require Unicode::UTF8; 1 } }) {
      $out_fh->printflush(Unicode::UTF8::encode_utf8($data));
    } else {
      require Encode;
      $out_fh->printflush(Encode::encode($charset, "$data"));
    }
  } elsif ($type eq 'data') {
    $out_fh->printflush($data);
  }
}

sub _json {
  my ($self) = @_;
  unless (exists $self->{json}) {
    if (do { local $@; eval { require Cpanel::JSON::XS; Cpanel::JSON::XS->VERSION('4.09'); 1 } }) {
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
