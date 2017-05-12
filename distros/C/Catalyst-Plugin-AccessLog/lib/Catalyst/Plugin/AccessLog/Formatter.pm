package Catalyst::Plugin::AccessLog::Formatter;

# ABSTRACT: Log formatter for Catalyst::Plugin::AccessLog
our $VERSION = '1.10'; # VERSION
our $AUTHORITY = 'cpan:ARODLAND'; # AUTHORITY

use namespace::autoclean;
use Moose;
use DateTime;

my %items;

sub item {
  my ($names, $code) = @_;
  $names = [ $names ] unless ref $names;

  $items{$_} = $code for @$names;
}

my %whitespace_escapes = (
  "\r" => "\\r",
  "\n" => "\\n",
  "\t" => "\\t",
  "\x0b" => "\\v",
);

# Approximate the rules for safely escaping headers/etc given in the apache docs
sub escape_string {
  my $str = shift;
  return "" unless defined $str and length $str;

  $str =~ s/(["\\])/\\$1/g;
  $str =~ s/([\r\n\t\x0b])/$whitespace_escapes{$1}/eg;
  $str =~ s/([^[:print:]])/sprintf '\x%02x', ord $1/eg;

  return $str;
}

sub get_item {
  my ($self, $c, $key, $arg) = @_;

  return "[unknown format key $key]" unless exists $items{$key};
  return $items{$key}->($self, $c, $arg);
}

sub format_line {
  my ($self, $c) = @_;
  my $format = $self->format;
  my $output = "";

  while (1) {
    my $argument = qr/\{ ( [^}]+ ) \}/x;
    my $longopt = qr/\[ ( [^]]+ ) \]/x;

    if ($format =~ /\G \Z/cgx) { # Found end of string.
      last;
    } elsif ($format =~ /\G ( [^%]+ )/cgx) { # Found non-percenty text.
      $output .= $1;
    } elsif ($format =~ /\G \%\% /cgx) { # Literal percent
      $output .= "%";
    } elsif ($format =~ /\G \% $argument $longopt/cgx) { # Long opt with argument
      $output .= $self->get_item($c, $2, $1);
    } elsif ($format =~ /\G \% $longopt/cgx) { # Long opt
      $output .= $self->get_item($c, $1);
    } elsif ($format =~ /\G \% $argument (.)/cgx) { # Short opt with argument
      $output .= $self->get_item($c, $2, $1);
    } elsif ($format =~ /\G \% (.)/cgx) { # Short opt
      $output .= $self->get_item($c, $1);
    } else {
      warn "Can't happen!";
    }
  }

  return $output;
}

=head1 DESCRIPTION

The log format argument is a string which will be used to generate each line
of the access log. The string consists of literal characters which will be
copied to the log output verbatim, and escapes, which will be replaced with
information about the request or the response. This format string is
intended to be compatible with the Apache C<LogFormat> directive, however it
contains some extensions and leaves a few features unimplemented.

Escapes can be either B<short escapes> or B<long escapes>. Both types begin
with the "C<%>" character. Short escapes consist of a C<%> followed by a
single character, for example C<%h> for the remote hostname. Long
escapes consist of a C<%> followed by a name inside B<square brackets>, for
example C<%[remote_hostname]> for the same option. Apache-compatible
options have both short escapes and long escapes, while incompatible options
have only long escapes.

Some escapes (currently C<%[time]>, C<%[apache_time]>, C<%[header]>, and
C<%[apache_header]>) may also take an argument, which can be optional or
required. The argument is placed inside B<curly braces> between the percent
sign and the name of the escape, for example C<%{User-agent}i> or
C<%{User-agent}[header]> to get the value of the C<User-agent> header.

A literal percent-sign can be produced in the output using the escape
sequence C<%%>.

=head2 Configuration

The following are optional arguments passed to
C<< Catalyst::Plugin::AccessLog::Formatter->new >>. Ordinarily these values
will be provided by L<Catalyst::Plugin::AccessLog> from its C<formatter>
config hash.

=over 4

=item format

B<Default:> C<'%h %l %u %t "%r" %s %b "%{Referer}i" "%{User-Agent}i"'> (Apache
C<common> log format).

The format string for each line of output. You can use Apache C<LogFormat>
strings, with a reasonably good level of compatibility, or you can use a
slightly more readable format. The log format is documented in detail in
L<Catalyst::Plugin::AccessLog::Formatter>.

=cut

has 'format' => (
  is => 'rw',
  default => '%h %l %u %t "%r" %s %b "%{Referer}i" "%{User-Agent}i"',
);

=item time_format

B<Default:> C<'%Y-%m-%dT%H:%M:%S'> (ISO 8601)

The default time format for the C<%t> / C<%[time]> escape. This is a
C<strftime> format string, which will be provided to L<DateTime>'s
C<strftime> method.

=cut

has 'time_format' => (
  is => 'rw',
  default => '%Y-%m-%dT%H:%M:%S',
);

=item time_zone

B<Default:> local

The timezone to use when printing times in access logs. This will be passed
to L<DateTime::TimeZone>'s constructor. Olson timezone names, POSIX TZ
values, and the keywords C<"local"> and C<"UTC"> are reasonable choices.

=cut

has 'time_zone' => (
  is => 'rw',
  default => 'local',
);

=item hostname_lookups

B<Default:> B<false>

If this option is set to a true value, then the C<%h> /
C<%[remote_hostname]> escape will resolve the client IP address using
reverse DNS. This is generally not recommended for reasons of performance
and security. Equivalent to the Apache option C<HostnameLookups>.

=cut

has 'hostname_lookups' => (
  is => 'rw',
  default => 0,
);

=back

=head2 Escapes

=over 4

=item %[remote_address], %a

The IP address of the remote client.

=cut

item ['a', 'remote_address'] => sub {
  return $_[1]->request->address;
};

=item %[clf_size], %b

The size of the response content in bytes. If the response content is empty,
produces a dash C<-> instead of 0. This is compatible with CLF.

=cut

item ['b', 'clf_size'] => sub {
  return $_[1]->response->content_length || "-";
};

=item %[size], %B

The size of the response content in bytes. Always numeric, even for 0.

=cut

item ['B', 'size'] => sub {
  return $_[1]->response->content_length;
};

=item %[remote_host], %h

The hostname of the remote client, if the C<hostname_lookups> config option
is true. Otherwise, the IP address of the remote client, as
C<%[remote_address]>.

=cut

item ['h', 'remote_host'] => sub {
  my ($self, $c) = @_;
  if ($self->hostname_lookups) {
    return $c->request->hostname;
  } else {
    return $c->request->address;
  }
};

=item %[header], %i

The value of the request header named in the (mandatory) argument, or "-" if
no such header was provided. Usage: C<%{User-agent}i> to get the
C<User-agent> request header.

=cut

item ['i', 'header'] => sub {
  my ($self, $c, $arg) = @_;
  my $header = $c->req->header($arg);
  return "-" unless defined($header);
  return escape_string($header);
};

=item %l

For Apache compatibility, this option produces a single dash C<->. In Apache
this option returns the remote username from an C<ident> check, if the
module is present, which it never is, which means it always produces a
single dash on Apache as well. We don't bother implementing ident.

=cut

item 'l' => sub { # for apache compat
  return "-";
};

=item %[method], %m

The request method (e.g. GET, POST).

=cut

item ['m', 'method'] => sub {
  return $_[1]->request->method;
};

=item %[port], %p

The port number that the request was received on. In apache this is the
server's "canonical port", however this is information that's not available
to Catalyst.

=cut

item ['p', 'port'] => sub {
  return $_[1]->req->base->port;
};

=item %[query], %q

The query string (beginning with a ? if there is a query string, otherwise
an empty string).

=cut

item ['q', 'query' ] => sub {
  my $qstring = $_[1]->req->uri->query;
  if (defined $qstring && length $qstring) {
    return "?$qstring";
  } else {
    return "";
  }
};

=item %[request_line], %r

The first line of the HTTP request, e.g. C<"GET / HTTP/1.0">.

=cut

item ['r', 'request_line'] => sub { # Mostly for apache's sake
  my ($self, $c) = @_;
  my $path = $c->req->path;
  my $query = $c->req->uri->query;
  if (defined $query && length $query) {
    $query = "?$query";
  } else {
    $query = "";
  }
  return $c->req->method . " /${path}${query} " . $c->req->protocol;
};

=item %[status], %s

The HTTP status of the response, e.g. 200 or 404.

=cut

item ['s', 'status'] => sub {
  return $_[1]->response->status;
};

=item %[apache_time], %t

The time that the request was received.

While this escape and the C<%[time]> escape both take an optional
C<strftime> argument, they differ in their default formats. This escape
defaults to a "human readable" format which is lousy to parse, but is
nonetheless compatible with apache.

=cut

item ['t', 'apache_time'] => sub {
  my ($self, $c, $arg) = @_;
  return "-" unless $c->use_stats;
  my $format = $arg || '[%d/%b/%Y:%H:%M:%S %z]'; # Apache default
  my @start_time = $c->stats->created;
  return DateTime->from_epoch(epoch => $start_time[0] + $start_time[1] / 1_000_000, 
    time_zone => $self->time_zone)->strftime($format);
};

=item %[time], %[datetime]

The time that the request was received.

While this escape and the C<%[apache_time]> escape both take an optional
C<strftime> argument, they differ in their default formats. This escape
defaults to the C<time_format> config option passed to the constructor.
If that option is not provided, the default is ISO 8601.

=cut

item ['time', 'datetime'] => sub {
  my ($self, $c, $arg) = @_;
  return "-" unless $c->use_stats;
  my $format = $arg || $self->time_format;
  my @start_time = $c->stats->created;
  return DateTime->from_epoch(epoch => $start_time[0] + $start_time[1] / 1_000_000,
    time_zone => $self->time_zone)->strftime($format);
};

=item %[remote_user], %u

The REMOTE_USER variable as set by HTTP basic auth, or certain frontend
authentication methods. Returns a dash C<-> if no such thing exists.

=cut

item ['u', 'remote_user'] => sub {
  return $_[1]->request->remote_user || '-';
};

=item %[host_port], %v, %V

The host and the port of the request URI. Apache specifies that these should
be the server's "canonical" host and port, but this information is
unavailable to Catalyst.

=cut

item ['V', 'v', 'host_port'] => sub {
  return $_[1]->request->base->host_port;
};

=item %[hostname]

The hostname of the request URI.

=cut

item 'hostname' => sub {
  return $_[1]->request->base->host;
};

=item %[path], %U

The request path (relative to the application root, but with a leading
slash).

=cut

# Possibly improvement: use uri_for to absolutize this with base, and then
# take the path component off of that...
item ['U', 'path'] => sub {
  return '/' . $_[1]->request->path;
};

=item %[handle_time], %T

The time spent handling this request, as provided by the C<< $c->stats >>
object. Returns a dash C<-> if stats are unavailable.

=cut

item ['T', 'handle_time'] => sub {
  my ($self, $c) = @_;
  if ($c->use_stats) {
    return sprintf "%f", $c->stats->elapsed;
  } else {
    return "-";
  }
};

=item %[action]

The private path of the Catalyst action that handled the request.

=cut

item 'action' => sub {
  return $_[1]->action->reverse;
};

=item %[sessionid]

The session ID, if there is one, otherwise "-".

=cut

item 'sessionid' => sub {
  my ($self, $c) = @_;
  return "-" unless $c->can('sessionid') && defined $c->sessionid;
  return $c->sessionid;
};

=item %[userid]

The user ID, if Authentication is enabled and a user exists, otherwise "-"

=cut

item 'userid' => sub {
  my ($self, $c) = @_;
  return "-" unless $c->can('user');
  return "-" unless $c->user_exists && defined $c->user->id;
  return $c->user->id;
};

=item %[request_count]

The request count for the current process, as displayed in debug info.

=cut

item 'request_count' => sub {
  $Catalyst::COUNT;
};

=item %[pid]

The process ID of the instance handling the request.

=cut

item 'pid' => sub {
  $$
};

=back

=cut

1;
