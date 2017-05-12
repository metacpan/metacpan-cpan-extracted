use strict;
use warnings;

package Dancer::Plugin::FakeCGI::Apache1;

BEGIN {
    foreach (
        'Apache.pm',       'Apache/Constants.pm', 'Apache/Request.pm', 'Apache/Log.pm',
        'Apache/Table.pm', 'Apache/Status.pm',    'mod_perl.pm'
      ) {
        $INC{$_} = $INC{'Dancer/Plugin/FakeCGI/Apache.pm'};
    }
}

=head1 NAME

Dancer::Plugin::FakeCGI::Apache1 - Simply emulation mod_perl version 1 for CGI

=head1 CONTRIBUTING

Thanks for developer B<Nigel Wetters Gourlay> from C<HTML::Mason> with his C<Apache::Emulator>

=cut

require Dancer;
use vars qw{$AUTOLOAD};

use Carp;

our $VERSION = "0.2";

our $CGI_obj = undef;    # Global variable for CGI->new handle

sub new {
    my $class = shift;
    my $self  = {};
    bless $self, $class;
    return $self;
}

sub AUTOLOAD {
    my $self = shift;

    my $name = $AUTOLOAD;
    $name =~ s/.*://;    # strip fully-qualified portion

    # In CGI method which we don't want emulated is given parametter get from ENV
    unless ($CGI_obj) {
        croak "Can't defined FakeCGI enviroment in Dancer for function '$name' with args: @_";

        #} elsif ($name eq 'auth_type')	{
    } elsif ($name eq 'request_method') {
        return Dancer->request->method();

        #} elsif ($name eq 'query_string')	{
        #} elsif ($name eq 'server_protocol')	{
        #	return Dancer->request->protocol();
        #} elsif ($name eq 'server_name')	{
        #} elsif ($name eq 'script_name')	{	# get from CGI
        #	return Dancer->request->script_name();
        #} elsif ($name eq 'path_info')	{
        #	return Dancer->request->path();
        #} elsif ($name eq 'content_type')	{
        #} elsif ($name eq 'http')	{
    } elsif ($CGI_obj->can($name)) {
        return $CGI_obj->$name(@_);
    } else {
        croak "Can't defined function '$name' with args: @_";
    }

}

# cgi_request_args ($cgi, $method)
#
# This function expects to receive a C<CGI.pm> object and the request
# method (GET, POST, etc).  Given these two things, it will return a
# hash in list context or a hashref in scalar context.  The hash(ref)
# will contain all the arguments passed via the CGI request.  The keys
# will be argument names and the values will be either scalars or array references.
sub _cgi_request_args {
    my ($q, $method) = @_;

    my %args;

    # Checking that there really is no query string when the method is
    # not POST is important because otherwise ->url_param returns a
    # parameter named 'keywords' with a value of () (empty array).
    # This is apparently a feature related to <ISINDEX> queries or
    # something (see the CGI.pm) docs.  It makes my head hurt. - dave
    my @methods = $method ne 'POST' || !$ENV{QUERY_STRING} ? ('param') : ('param', 'url_param');

    foreach my $key (map { $q->$_() } @methods) {
        next if exists $args{$key};
        my @values = map { $q->$_($key) } @methods;
        $args{$key} = @values == 1 ? $values[0] : \@values;
    }

    return wantarray ? %args : \%args;
}

DESTROY {
    my $self = shift;
}

package Apache;

use vars qw{$AUTOLOAD};

sub AUTOLOAD {
    my $self = shift;

    my $name = $AUTOLOAD;
    $name =~ s/.*://;    # strip fully-qualified portion

    return Apache->new() if ($name eq 'request');
    Dancer->debug("Can't defined function '$name' with args: @_");
}

sub register_cleanup {
    my ($self, $code) = @_;
    push @{$$self{'HANDLERS'}{'PerlCleanupHandler'}}, $code;
}

# Faked method for Apache->read is a built-in function, and so can do magic.
sub read() {
    my $self = shift;
    my $buf  = \$_[0];    # Must be setted as scalarref
    shift;

    my ($len, $offset) = @_;
    no strict 'refs';
    $$buf = substr(Dancer->request->body(), $offset, $len);
    return length($$buf);
}

# Destroy
DESTROY {
    my $self = shift;
    foreach my $code (@{$$self{'HANDLERS'}{'PerlCleanupHandler'}}) {
        no strict 'refs';
        &$code();
    }
}

##################################################################################

sub new {
    my $class = shift;
    my %p     = @_;

    return bless {

        #query           => $p{cgi} || CGI->new,
        query           => Dancer::Plugin::FakeCGI::Apache1->new,
        headers_out     => Apache::Table->new,
        err_headers_out => Apache::Table->new,
        pnotes          => {},
    }, $class;
}

# CGI request are _always_ main, and there is never a previous or a next
# internal request.
sub main           { }
sub prev           { }
sub next           { }
sub is_main        { 1 }
sub is_initial_req { 1 }

# What to do with this?
# sub allowed {}

sub method {
    $_[0]->{query}->request_method;
}

# There mut be a mapping for this.
# sub method_number {}

# Can CGI.pm tell us this?
# sub bytes_sent {0}

# The request line sent by the client." Poached from Apache::Emulator.
sub the_request {
    my $self = shift;
    $self->{the_request} ||= join ' ', $self->method,
      (   $self->{query}->query_string
        ? $self->uri . '?' . $self->{query}->query_string
        : $self->uri
      ),
      $self->{query}->server_protocol;
}

# Is CGI ever a proxy request?
# sub proxy_req {}

sub header_only { $_[0]->method eq 'HEAD' }

sub protocol { $ENV{SERVER_PROTOCOL} || 'HTTP/1.0' }

sub hostname { $_[0]->{query}->server_name }

# Fake it by just giving the current time.
sub request_time { time }

sub uri {
    my $self = shift;

    $self->{uri} ||= $self->{query}->script_name . $self->path_info || '';
}

# Is this available in CGI?
# sub filename {}

# "The $r->location method will return the path of the
# <Location> section from which the current "Perl*Handler"
# is being called." This is irrelevant, I think.
# sub location {}

sub path_info { $_[0]->{query}->path_info }

sub args {
    my $self = shift;

    my %all_params = Dancer->request->params;
    delete($all_params{"splat"});    # Delete 'splat' from params. Dancer put to this if use 'splat' function

    if (@_) {

        # Assign args here.
    }

    return unless keys %all_params;

    # Redirected when is only method 'GET' and not existed CONTENT_TYPE
    # we must return params as string with separator & or ;
    if ($ENV{'REQUEST_METHOD'} eq 'GET' && !$ENV{'CONTENT_TYPE'}) {
        my @a = ();
        while (my ($k, $d) = each %all_params) {
            push(@a, $k . "=" . ($d || ""));
        }
        return join("&", @a);
    }

    return %all_params if wantarray;
    return \%all_params;

    #return $self->{query}->Vars unless wantarray;

    # Do more here to return key => arg values.
}

sub headers_in {
    my $self = shift;

    # Create the headers table if necessary. Decided how to build it based on
    # information here:
    # http://cgi-spec.golux.com/draft-coar-cgi-v11-03-clean.html#6.1
    #
    # Try to get as much info as possible from CGI.pm, which has
    # workarounds for things like the IIS PATH_INFO bug.
    #
    $self->{headers_in} ||= Apache::Table->new(
        'Authorization' => $self->{query}->auth_type,    # No credentials though.

        #'Cookie' => $ENV{HTTP_COOKIE} || $ENV{COOKIE},
        'Content-Length' => $ENV{CONTENT_LENGTH},
        'Content-Type'   => (
              $self->{query}->can('content_type')
            ? $self->{query}->content_type
            : $ENV{CONTENT_TYPE}
        ),

        # Convert HTTP environment variables back into their header names.
        map {
            my $k = ucfirst lc;
            $k =~ s/_(.)/-\u$1/g;
            ($k => $self->{query}->http($_))
          } grep {
            s/^HTTP_//
          } keys %ENV
    );

    # Give 'em the hash list of the hash table.
    return wantarray ? %{$self->{headers_in}} : $self->{headers_in};
}

sub header_in {
    my ($self, $header) = (shift, shift);
    my $h = $self->headers_in;
    return @_ ? $h->set($header, shift) : $h->get($header);
}

# The $r->content method will return the entity body
# read from the client, but only if the request content
# type is "application/x-www-form-urlencoded".  When
# called in a scalar context, the entire string is
# returned.  When called in a list context, a list of
# parsed key => value pairs are returned.  *NOTE*: you
# can only ask for this once, as the entire body is read
# from the client.
# Not sure what to do with this one.
# sub content {}

# I think this may be irrelevant under CGI.
# sub read {}

# Use LWP?
sub get_remote_host    { }
sub get_remote_logname { }

sub http_header {
    my $self   = shift;
    my $h      = $self->headers_out;
    my $e      = $self->err_headers_out;
    my $method = exists $h->{Location}
      || exists $e->{Location} ? 'redirect' : 'header';

    #return $self->{query}->$method(tied(%$h)->cgi_headers, tied(%$e)->cgi_headers);
    return "";
}

sub send_http_header {
    my $self = shift;

    print STDOUT $self->http_header;

    $self->{http_header_sent} = 1;
}

sub http_header_sent { shift->{http_header_sent} }

# How do we know this under CGI?
# sub get_basic_auth_pw {}
# sub note_basic_auth_failure {}

# I think that this just has to be empty.
sub handler { }

sub notes {
    my ($self, $key) = (shift, shift);
    $self->{notes} ||= Apache::Table->new;
    return wantarray ? %{$self->{notes}} : $self->{notes}
      unless defined $key;
    return $self->{notes}{$key} = "$_[0]" if @_;
    return $self->{notes}{$key};
}

sub pnotes {
    my ($self, $key) = (shift, shift);
    return wantarray ? %{$self->{pnotes}} : $self->{pnotes}
      unless defined $key;
    return $self->{pnotes}{$key} = $_[0] if @_;
    return $self->{pnotes}{$key};
}

sub subprocess_env {
    my ($self, $key) = (shift, shift);
    unless (defined $key) {
        $self->{subprocess_env} = Apache::Table->new(%ENV);
        return wantarray
          ? %{$self->{subprocess_env}}
          : $self->{subprocess_env};

    }
    $self->{subprocess_env} ||= Apache::Table->new(%ENV);
    return $self->{subprocess_env}{$key} = "$_[0]" if @_;
    return $self->{subprocess_env}{$key};
}

sub content_type {
    shift->header_out('Content-Type', @_);
}

sub content_encoding {
    shift->header_out('Content-Encoding', @_);
}

sub content_languages {
    my ($self, $langs) = @_;
    return unless $langs;
    my $h = shift->headers_out;
    for my $l (@$langs) {
        $h->add('Content-Language', $l);
    }
}

sub status {
    shift->header_out('Status', @_);
}

sub status_line {

    # What to do here? Should it be managed differently than status?
    my $self = shift;
    if (@_) {
        my $status = shift =~ /^(\d+)/;
        return $self->header_out('Status', $status);
    }
    return $self->header_out('Status');
}

sub headers_out {
    my $self = shift;
    return wantarray ? %{$self->{headers_out}} : $self->{headers_out};
}

sub header_out {
    my ($self, $header) = (shift, shift);
    my $h = $self->headers_out;
    return @_ ? $h->set($header, shift) : $h->get($header);
}

sub err_headers_out {
    my $self = shift;
    return wantarray ? %{$self->{err_headers_out}} : $self->{err_headers_out};
}

sub err_header_out {
    my ($self, $err_header) = (shift, shift);
    my $h = $self->err_headers_out;
    return @_ ? $h->set($err_header, shift) : $h->get($err_header);
}

sub no_cache {
    my $self = shift;
    $self->header_out(Pragma          => 'no-cache');
    $self->header_out('Cache-Control' => 'no-cache');
}

sub print {
    print @_;
}

sub send_fd {
    my ($self, $fd) = @_;
    local $_;

    print STDOUT while defined($_ = <$fd>);
}

#sub print {
#	my $self = shift;
#	foreach my $arg (@_) {
#		$arg = $$arg if ref($arg) eq 'SCALAR';
#	}
#	CORE::print @_;
#}
#
#*CORE::GLOBAL::print = \&print;

#sub send_fd {
#	my ($self, $fh) = @_;
#	my $buf;
#	while (CORE::read($fh,$buf,16384) > 0) {
#		CORE::print $buf;
#	}
#}

sub rflush { flush STDOUT; flush STDERR; }

# Should this perhaps throw an exception?
# sub internal_redirect {}
# sub internal_redirect_handler {}

# Do something with ErrorDocument?
# sub custom_response {}

# I think we'ev made this essentially the same thing.
BEGIN {
    local $^W;
    *send_cgi_header = \&send_http_header;
}

# Does CGI support logging?
# sub log_reason {}
# sub log_error {}
sub warn {
    shift;
    Dancer->warn(@_);
}

sub params {
    my $self = shift;

    return Dancer::Plugin::FakeCGI::Apache1::_cgi_request_args($self->query, $self->query->request_method);
}

package Apache::Constants;

use vars qw (%EXPORT_TAGS @EXPORT_OK $EXPORT @ISA);
require Exporter;
@ISA = qw(Exporter);

my @common = qw(OK
  DECLINED
  DONE
  NOT_FOUND
  FORBIDDEN
  AUTH_REQUIRED
  SERVER_ERROR);

sub OK            { 0 }
sub DECLINED      { -1 }
sub DONE          { -2 }
sub NOT_FOUND     { 404 }
sub FORBIDDEN     { 403 }
sub AUTH_REQUIRED { 401 }
sub SERVER_ERROR  { 500 }

my (@methods) = qw(M_CONNECT
  M_DELETE
  M_GET
  M_INVALID
  M_OPTIONS
  M_POST
  M_PUT
  M_TRACE
  M_PATCH
  M_PROPFIND
  M_PROPPATCH
  M_MKCOL
  M_COPY
  M_MOVE
  M_LOCK
  M_UNLOCK
  METHODS);

my (@options) = qw(OPT_NONE OPT_INDEXES OPT_INCLUDES
  OPT_SYM_LINKS OPT_EXECCGI OPT_UNSET OPT_INCNOEXEC
  OPT_SYM_OWNER OPT_MULTI OPT_ALL);

my (@server) = qw(MODULE_MAGIC_NUMBER
  SERVER_VERSION SERVER_BUILT);

my (@response) = qw(DOCUMENT_FOLLOWS
  MOVED
  REDIRECT
  USE_LOCAL_COPY
  BAD_REQUEST
  BAD_GATEWAY
  RESPONSE_CODES
  NOT_IMPLEMENTED
  NOT_AUTHORITATIVE
  CONTINUE);

#define DOCUMENT_FOLLOWS    HTTP_OK
#define PARTIAL_CONTENT     HTTP_PARTIAL_CONTENT
#define MULTIPLE_CHOICES    HTTP_MULTIPLE_CHOICES
#define MOVED               HTTP_MOVED_PERMANENTLY
#define REDIRECT            HTTP_MOVED_TEMPORARILY
#define USE_LOCAL_COPY      HTTP_NOT_MODIFIED
#define BAD_REQUEST         HTTP_BAD_REQUEST
#define AUTH_REQUIRED       HTTP_UNAUTHORIZED
#define FORBIDDEN           HTTP_FORBIDDEN
#define NOT_FOUND           HTTP_NOT_FOUND
#define METHOD_NOT_ALLOWED  HTTP_METHOD_NOT_ALLOWED
#define NOT_ACCEPTABLE      HTTP_NOT_ACCEPTABLE
#define LENGTH_REQUIRED     HTTP_LENGTH_REQUIRED
#define PRECONDITION_FAILED HTTP_PRECONDITION_FAILED
#define SERVER_ERROR        HTTP_INTERNAL_SERVER_ERROR
#define NOT_IMPLEMENTED     HTTP_NOT_IMPLEMENTED
#define BAD_GATEWAY         HTTP_BAD_GATEWAY
#define VARIANT_ALSO_VARIES HTTP_VARIANT_ALSO_VARIES

my (@satisfy) = qw(SATISFY_ALL SATISFY_ANY SATISFY_NOSPEC);

my (@remotehost) = qw(REMOTE_HOST
  REMOTE_NAME
  REMOTE_NOLOOKUP
  REMOTE_DOUBLE_REV);

use constant REMOTE_HOST       => 0;
use constant REMOTE_NAME       => 1;
use constant REMOTE_NOLOOKUP   => 2;
use constant REMOTE_DOUBLE_REV => 3;

my (@http) = qw(HTTP_OK
  HTTP_MOVED_TEMPORARILY
  HTTP_MOVED_PERMANENTLY
  HTTP_METHOD_NOT_ALLOWED
  HTTP_NOT_MODIFIED
  HTTP_UNAUTHORIZED
  HTTP_FORBIDDEN
  HTTP_NOT_FOUND
  HTTP_BAD_REQUEST
  HTTP_INTERNAL_SERVER_ERROR
  HTTP_NOT_ACCEPTABLE
  HTTP_NO_CONTENT
  HTTP_PRECONDITION_FAILED
  HTTP_SERVICE_UNAVAILABLE
  HTTP_VARIANT_ALSO_VARIES);

use constant HTTP_OK                    => 200;
use constant HTTP_MOVED_TEMPORARILY     => 302;
use constant HTTP_MOVED_PERMANENTLY     => 301;
use constant HTTP_METHOD_NOT_ALLOWED    => 405;
use constant HTTP_NOT_MODIFIED          => 304;
use constant HTTP_UNAUTHORIZED          => 401;
use constant HTTP_FORBIDDEN             => 403;
use constant HTTP_NOT_FOUND             => 404;
use constant HTTP_BAD_REQUEST           => 400;
use constant HTTP_INTERNAL_SERVER_ERROR => 500;
use constant HTTP_NOT_ACCEPTABLE        => 406;
use constant HTTP_NO_CONTENT            => 204;
use constant HTTP_PRECONDITION_FAILED   => 412;
use constant HTTP_SERVICE_UNAVAILABLE   => 503;
use constant HTTP_VARIANT_ALSO_VARIES   => 506;

my (@config)   = qw(DECLINE_CMD);
my (@types)    = qw(DIR_MAGIC_TYPE);
my (@override) = qw(
  OR_NONE
  OR_LIMIT
  OR_OPTIONS
  OR_FILEINFO
  OR_AUTHCFG
  OR_INDEXES
  OR_UNSET
  OR_ALL
  ACCESS_CONF
  RSRC_CONF);
my (@args_how) = qw(
  RAW_ARGS
  TAKE1
  TAKE2
  ITERATE
  ITERATE2
  FLAG
  NO_ARGS
  TAKE12
  TAKE3
  TAKE23
  TAKE123);

my $rc = [@common, @response];

%EXPORT_TAGS = (
    common     => \@common,
    config     => \@config,
    response   => $rc,
    http       => \@http,
    options    => \@options,
    methods    => \@methods,
    remotehost => \@remotehost,
    satisfy    => \@satisfy,
    server     => \@server,
    types      => \@types,
    args_how   => \@args_how,
    override   => \@override,

    #deprecated
    response_codes => $rc,
);

@EXPORT_OK = (@response, @http, @options, @methods, @remotehost, @satisfy, @server, @config, @types, @args_how, @override,);

*EXPORT = \@common;

package Apache::TableHash;

sub TIEHASH {
    my $class = shift;
    return bless {}, ref $class || $class;
}

sub _canonical_key {
    my $key = lc shift;

    # CGI really wants a - before each header
    return substr($key, 0, 1) eq '-' ? $key : "-$key";
}

sub STORE {
    my ($self, $key, $value) = @_;
    $self->{_canonical_key $key} = [$key => ref $value ? "$value" : $value];
}

sub add {
    my ($self, $key) = (shift, shift);
    return unless defined $_[0];
    my $value = ref $_[0] ? "$_[0]" : $_[0];
    my $ckey = _canonical_key $key;
    if (exists $self->{$ckey}) {
        if (ref $self->{$ckey}[1]) {
            push @{$self->{$ckey}[1]}, $value;
        } else {
            $self->{$ckey}[1] = [$self->{$ckey}[1], $value];
        }
    } else {
        $self->{$ckey} = [$key => $value];
    }
}

sub DELETE {
    my ($self, $key) = @_;
    my $ret = delete $self->{_canonical_key $key};
    return $ret->[1];
}

sub FETCH {
    my ($self, $key) = @_;

    # Grab the values first so that we don't autovivicate the key.
    my $val = $self->{_canonical_key $key} or return;
    if (my $ref = ref $val->[1]) {
        return unless $val->[1][0];

        # Return the first value only.
        return $val->[1][0];
    }
    return $val->[1];
}

sub get {
    my ($self, $key) = @_;
    my $ckey = _canonical_key $key;
    return unless exists $self->{$ckey};
    return $self->{$ckey}[1] unless ref $self->{$ckey}[1];
    return wantarray ? @{$self->{$ckey}[1]} : $self->{$ckey}[1][0];
}

sub CLEAR {
    %{shift()} = ();
}

sub EXISTS {
    my ($self, $key) = @_;
    return exists $self->{_canonical_key $key};
}

sub FIRSTKEY {
    my $self = shift;

    # Reset perl's iterator.
    keys %$self;

    # Get the first key via perl's iterator.
    my $first_key = each %$self;
    return undef unless defined $first_key;
    return $self->{$first_key}[0];
}

sub NEXTKEY {
    my ($self, $nextkey) = @_;

    # Get the next key via perl's iterator.
    my $next_key = each %$self;
    return undef unless defined $next_key;
    return $self->{$next_key}[0];
}

sub cgi_headers {
    my $self = shift;
    map { $_ => $self->{$_}[1] } keys %$self;
}

package Apache::Table;

sub new {
    my $class = shift;
    my $self  = {};
    tie %{$self}, 'Apache::TableHash';
    %$self = @_ if @_;
    return bless $self, ref $class || $class;
}

sub set {
    my ($self, $header, $value) = @_;
    defined $value ? $self->{$header} = $value : delete $self->{$header};
}

sub unset {
    my $self = shift;
    delete $self->{shift()};
}

sub add {
    tied(%{shift()})->add(@_);
}

sub clear {
    %{shift()} = ();
}

sub get {
    tied(%{shift()})->get(@_);
}

sub merge {
    my ($self, $key, $value) = @_;
    if (defined $self->{$key}) {
        $self->{$key} .= ',' . $value;
    } else {
        $self->{$key} = "$value";
    }
}

sub do {
    my ($self, $code) = @_;
    while (my ($k, $val) = each %$self) {
        for my $v (ref $val ? @$val : $val) {
            return unless $code->($k => $v);
        }
    }
}

1;
__END__
