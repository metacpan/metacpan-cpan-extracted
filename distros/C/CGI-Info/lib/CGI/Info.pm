package CGI::Info;

use warnings;
use strict;
use autodie qw(:all);

use 5.010;	# Minimum version for features used here

# Core modules
use boolean;
use Carp;
use Cwd ();
use Readonly;
use Scalar::Util;
use Socket;	# AF_INET constant

# CPAN modules
use Object::Configure 0.19;
use File::Spec;
use Log::Abstraction 0.10;
use Net::CIDR;
use Params::Get 0.13;
use Params::Validate::Strict 0.35;
use Return::Set;
use Sys::Path;
use Sub::Protected;

use namespace::clean;

# ---------------------------------------------------------------------------
# Module-level constants -- avoids magic numbers scattered through the code
# ---------------------------------------------------------------------------
Readonly my $MAX_UPLOAD_SIZE_DEFAULT => 512 * 1024;	# 512 KB default upload cap
Readonly my $MAX_PARAMS_DEFAULT       => 1000;		# Maximum number of input parameters
Readonly my $MAX_PARTS_DEFAULT        => 100;		# Maximum number of multipart parts
Readonly my $MAX_PART_HEADERS_DEFAULT => 20;		# Maximum header lines per multipart part
Readonly my $MAX_NESTING_DEPTH_DEFAULT => 8;		# Maximum [] nesting in parameter names
Readonly my $DTD_WARNING_INTERVAL_DEFAULT => 60;	# Seconds between allow_dtd audit warnings
Readonly my $DTD_WARNING_MAX_KEYS => 100;		# Request paths tracked by that limiter
Readonly my @COMPLEXITY_LIMITS      => qw(max_body_size max_params max_parts max_part_headers max_nesting_depth);
Readonly my $CACHE_TTL_ROBOT         => '1 day';	# TTL for robot-detection cache entries
Readonly my $CACHE_TTL_SEARCH        => '1 day';	# TTL for search-engine cache entries

# Compiled once at module-load time: replaces the 29-element @crawler_lists array
# that was re-allocated on every is_robot() call.  Building the alternation with
# quotemeta() is equivalent to the former List::Util::any { /^\Q$_\E/i } loop
# but avoids both per-call array construction and per-element regex compilation.
Readonly my $CRAWLER_REFERER_RE => do {
	my @domains = (
		'http://fix-website-errors.com',
		'http://keywords-monitoring-your-success.com',
		'http://free-video-tool.com',
		'http://magnet-to-torrent.com',
		'http://torrent-to-magnet.com',
		'http://dogsrun.net',
		'http://###.responsive-test.net',
		'http://uptime.com',
		'http://uptimechecker.com',
		'http://top1-seo-service.com',
		'http://fast-wordpress-start.com',
		'http://wordpress-crew.net',
		'http://dbutton.net',
		'http://justprofit.xyz',
		'http://video--production.com',
		'http://buttons-for-website.com',
		'http://buttons-for-your-website.com',
		'http://success-seo.com',
		'http://videos-for-your-business.com',
		'http://semaltmedia.com',
		'http://dailyrank.net',
		'http://uptimebot.net',
		'http://sitevaluation.org',
		'http://100dollars-seo.com',
		'http://forum69.info',
		'http://partner.semalt.com',
		'http://best-seo-offer.com',
		'http://best-seo-solution.com',
		'http://semalt.semalt.com',
		'http://semalt.com',
		'http://7makemoneyonline.com',
		'http://anticrawler.org',
		'http://baixar-musicas-gratis.com',
		'http://descargar-musica-gratis.net',
		'http://www.seokicks.de/robot.html',
	);
	my $alt = join '|', map { quotemeta $_ } @domains;
	qr/^(?:$alt)/i;
};

sub _sanitise_input;

=head1 NAME

CGI::Info - Information about the CGI environment

=head1 VERSION

Version 1.16

=cut

our $VERSION = '1.16';

=head1 SYNOPSIS

The C<CGI::Info> module is a Perl library designed to provide information about the environment in which a CGI script operates.
It aims to eliminate hard-coded script details,
enhancing code readability and portability.
Additionally, it offers a simple web application firewall to add a layer of security.

All too often,
Perl programs have information such as the script's name
hard-coded into their source.
Generally speaking,
hard-coding is a bad style since it can make programs difficult to read and reduces readability and portability.
CGI::Info attempts to remove that.

Furthermore, to aid script debugging, CGI::Info attempts to do sensible
things when you're not running the program in a CGI environment.

Whilst you shouldn't rely on it alone to provide security to your website,
it is another layer and every little helps.

    use CGI::Info;

    my $info = CGI::Info->new(allow => { id => qr/^\d+$/ });
    my $params = $info->params();

    if($info->is_mobile()) {
        print "Mobile view\n";
    } else {
        print "Desktop view\n";
    }

    my $id = $info->param('id');	# Validated against allow schema

=head1 SUBROUTINES/METHODS

=head2 new

Creates a CGI::Info object.

It takes optional arguments allow, logger and upload_dir,
which are documented in the params() method, plus the request-complexity
limits documented below.

It takes other optional parameters:

=over 4

=item * C<auto_load>

Enable/disable the AUTOLOAD feature.
The default is to have it enabled.

=item * C<config_dirs>

Where to look for C<config_file>

=item * C<config_file>

Points to a configuration file which contains the parameters to C<new()>.
The file can be in any common format,
including C<YAML>, C<XML>, and C<INI>.
This allows the parameters to be set at run time.

On non-Windows system,
the class can be configured using environment variables starting with "CGI::Info::".
For example:

  export CGI::Info::max_upload_size=65536

It doesn't work on Windows because of the case-insensitive nature of that system.

If the configuration file has a section called C<CGI::Info>,
only that section,
and the C<global> section,
if any exists,
is used.

=item * C<syslog>

Takes an optional parameter syslog, to log messages to
L<Sys::Syslog>.
It can be a boolean to enable/disable logging to syslog, or a reference
to a hash to be given to Sys::Syslog::setlogsock.

=item * C<cache>

An object that is used to cache IP lookups.
This cache object is an object that understands get() and set() messages,
such as a L<CHI> object.

=item * C<allow_dtd>

When false (the default), an XML request body containing a C<!DOCTYPE> or
C<!ENTITY> declaration is rejected before it is returned: C<params()>
returns undef and the status is set to C<403>.
Set this to a true value to accept such bodies, for example when parsing a
trusted feed that ships its own DTD.
Entity expansion and external entity resolution are then the caller's
responsibility: parse the body with a proper XML parser that has entity
expansion disabled.
Every body accepted under this option is logged as a warning naming the
declaration, so use of the exception is visible in the audit trail; see
C<dtd_warning_interval> for how those warnings are rate limited.
This is a constructor, configuration file or environment
(C<CGI__Info__allow_dtd>) setting; it cannot be overridden per C<params()>
call.

=item * C<dtd_warning_interval>

The minimum number of seconds between audit warnings for XML bodies accepted
because of C<allow_dtd>.
The default is 60.
Declarations that are accepted but not logged are counted, and the next
warning reports how many were suppressed, so a frequently polled feed does
not hide its traffic while still not writing a line per request.
Set this to C<0> to log every accepted declaration.

The limit is per process and per request path, so the warnings for
F</feed/a> and F</feed/b> are counted separately and one busy feed does not
silence another.
The path is taken from C<PATH_INFO>, falling back to C<SCRIPT_NAME> and then
to the path part of C<REQUEST_URI>, and normalised lexically: the query string
is dropped, C<%XX> escapes are decoded, repeated slashes are collapsed and
C<.> and C<..> segments are resolved, so the usual spellings of one feed
(F</feed/a>, F</feed/a/>, F</feed//a>, F</feed/%61>) share a single budget
instead of splitting it.
The limiter is not per object, so it also applies when a persistent handler
(such as mod_perl, FastCGI or PSGI) creates a new object for every request,
and C<reset()> does not clear it.
At most 100 paths are tracked at once; when that many are in use the table is
cleared, which can produce one extra warning per feed.
It is a constructor, configuration file or environment
(C<CGI__Info__dtd_warning_interval>) setting.

=item * C<max_upload_size>

The maximum file size in bytes you can upload.
Use C<-1> for no limit.
The default is 512 KB (524288 bytes).

=item * C<max_body_size>

The maximum number of bytes read from a POST body.
This is checked against C<CONTENT_LENGTH> before anything is read and
against any pre-populated body, so it caps the raw request rather than
the parsed parameter values.
Use C<-1> for no limit.
When omitted it falls back to C<max_upload_size>, preserving the historical
512 KB default.

=item * C<max_params>

The maximum number of parameters accepted from one request.
The check is made on the raw key=value pairs before decoding, so it also
bounds the amount of work done by the parser.
For XML bodies (C<text/xml>, C<application/xml> and structured
C<application/*+xml> types such as C<application/soap+xml>), this is the
number of XML elements, including the root element.
Use C<0> to reject every parameter and C<-1> for no limit.
The default is 1000.

=item * C<max_parts>

The maximum number of parts in a C<multipart/form-data> body.
Use C<0> to reject every part and C<-1> for no limit.
The default is 100.

=item * C<max_part_headers>

The maximum number of header lines allowed in one C<multipart/form-data>
part, including C<Content-Disposition> and C<Content-Type>.
Use C<0> to reject any part with headers and C<-1> for no limit.
The default is 20.

=item * C<max_nesting_depth>

The maximum depth of square-bracket nesting in a parameter name, for
example C<a[b][c]> has a depth of 2.
This applies to URL-encoded, JSON and multipart parameter names, not to
values.
For XML bodies (C<text/xml>, C<application/xml> and structured
C<application/*+xml> types such as C<application/soap+xml>), this is the XML
element nesting depth, where the root element is depth 1.
Use C<0> to reject any bracketed name (or any XML element) and C<-1> for no
limit.
The default is 8.

=back

Any of these limits can also be overridden for a single C<params()> call,
either individually or through its C<limits> hash reference; see L</params>.

The class can be configured at runtime using environment variables and configuration
files; for example, setting C<$ENV{'CGI__INFO__carp_on_warn'}> causes warnings to
use L<Carp>.  For more information see L<Object::Configure>.

=head3 API SPECIFICATION

=head4 INPUT

  {
    allow          => { type => 'hashref',  optional => 1 },
    allow_dtd      => { type => 'boolean',  optional => 1 },
    auto_load      => { type => 'boolean',  optional => 1 },
    cache          => { type => 'object',   optional => 1 },
    carp_on_warn   => { type => 'boolean',  optional => 1 },
    config_dirs    => { type => 'arrayref', optional => 1 },
    config_file    => { type => 'string',   optional => 1 },
    dtd_warning_interval => { type => 'integer', optional => 1, min => 0 },
    logger         => { type => 'object',   optional => 1 },
    max_body_size  => { type => 'integer',  optional => 1, min => -1 },
    max_nesting_depth => { type => 'integer', optional => 1, min => -1 },
    max_params     => { type => 'integer',  optional => 1, min => -1 },
    max_part_headers => { type => 'integer', optional => 1, min => -1 },
    max_parts      => { type => 'integer',  optional => 1, min => -1 },
    max_upload_size=> { type => 'integer',  optional => 1, min => -1 },
    upload_dir     => { type => 'string',   optional => 1 },
  }

=head4 OUTPUT

  { type => 'object', isa => 'CGI::Info' }

=head3 MESSAGES

=over 4

=item C<< use ->new() not ::new() to instantiate >>

B<Level>: fatal (croak).
B<Cause>: called as C<CGI::Info::new()> (double-colon) instead of C<< CGI::Info->new() >>.
B<Action>: change the call-site to use the arrow notation.

=item C<< Logger must be an object with info() and error() methods >>

B<Level>: fatal (croak).
B<Cause>: the C<logger> argument is not a blessed object, or does not
implement C<info()>, C<warn()>, and C<error()> methods.
B<Action>: pass a compliant logger such as a L<Log::Abstraction>-based object.

=item C<< expect has been deprecated, use allow instead >>

B<Level>: fatal (croak).
B<Cause>: the removed C<expect> parameter was passed to C<new()>.
B<Action>: replace C<expect =E<gt> [...]> with C<allow =E<gt> { key =E<gt> qr/.../ }>.

=back

=cut

our $stdin_data;	# Class variable storing STDIN in case the class
			# is instantiated more than once

# Rate limiter for the allow_dtd audit warning, keyed by request path so that
# different XML endpoints do not share one warning budget.  Process-wide rather
# than per object: a persistent handler (mod_perl, FastCGI, PSGI) creates a new
# object for each request while sharing one log, and reset() must not defeat
# the limit.
#   $DTD_WARNING_STATE{$path} = { last => <time>, suppressed => <count> }
our %DTD_WARNING_STATE = ();

sub new
{
	my $class = shift;

	# Handle hash or hashref arguments
	my $params = Params::Get::get_params(undef, \@_);

	if (defined($class)) {
		my $is_valid = Scalar::Util::blessed($class) || (eval { $class->isa(__PACKAGE__) });
		unless ($is_valid) {
			# Called as CGI::Info::new(...) or similar wrong function call
			croak(__PACKAGE__, ' use ->new() not ::new() to instantiate');
		}
	} else {
		# If class is undef, but there are arguments/params passed
		if (defined($params) && keys %{$params}) {
			croak(__PACKAGE__, ' use ->new() not ::new() to instantiate');
		}
		# Called as CGI::Info::new() with 0 arguments (undef $class)
		$class = __PACKAGE__;
	}

	if(Scalar::Util::blessed($class)) {
		# If $class is an object, clone it with new arguments
		$params ||= {};

		# Validate any new logger passed to the clone
		if(defined $params->{'logger'}) {
			unless(Scalar::Util::blessed($params->{'logger'}) && $params->{'logger'}->can('warn') && $params->{'logger'}->can('info') && $params->{'logger'}->can('error')) {
				Carp::croak('Logger must be an object with info() and error() methods');
			}
		}

		# expect is deprecated even when cloning
		if(defined($params->{'expect'})) {
			my $logger = $params->{'logger'} // $class->{'logger'};
			$logger->error(ref($class) . ': expect has been deprecated, use allow instead') if $logger;
			Carp::croak(ref($class) . ': expect has been deprecated, use allow instead');
		}

		# Drop cached params so a new allow schema is applied on next call
		my %merged = (%{$class}, %{$params});
		delete $merged{'paramref'};
		delete $merged{'_limits_key'};
		return bless \%merged, ref($class);
	}

	# Load the configuration from a config file, if provided
	$params = Object::Configure::configure($class, $params);

	# Validate logger object has required methods
	if(defined $params->{'logger'}) {
		unless(Scalar::Util::blessed($params->{'logger'}) && $params->{'logger'}->can('warn') && $params->{'logger'}->can('info') && $params->{'logger'}->can('error')) {
			Carp::croak("Logger must be an object with info() and error() methods");
		}
	}

	if(defined($params->{'expect'})) {
		# if(ref($params->{expect}) ne 'ARRAY') {
			# Carp::croak(__PACKAGE__, ': expect must be a reference to an array');
		# }
		# # warn __PACKAGE__, ': expect is deprecated, use allow instead';
		if(my $logger = $params->{'logger'}) {
			$logger->error("$class: expect has been deprecated, use allow instead");
		}
		Carp::croak("$class: expect has been deprecated, use allow instead");
	}

	# Return the blessed object with sensible defaults
	return bless {
		max_upload_size    => $MAX_UPLOAD_SIZE_DEFAULT,
		allow_dtd          => 0,		# Reject DOCTYPE/ENTITY declarations unless asked
		dtd_warning_interval => $DTD_WARNING_INTERVAL_DEFAULT,	# Rate-limit its audit warning
		max_body_size      => undef,	# Falls back to max_upload_size
		max_params         => $MAX_PARAMS_DEFAULT,
		max_parts          => $MAX_PARTS_DEFAULT,
		max_part_headers   => $MAX_PART_HEADERS_DEFAULT,
		max_nesting_depth  => $MAX_NESTING_DEPTH_DEFAULT,
		allow              => undef,
		upload_dir         => undef,
		%{$params}	# Caller-supplied args override the defaults above
	}, $class;
}

=head2 script_name

Retrieves the name of the executing CGI script.
This is useful for POSTing,
thus avoiding hard-coded paths into forms.

	use CGI::Info;

	my $info = CGI::Info->new();
	my $script_name = $info->script_name();
	# ...
	print "<form method=\"POST\" action=$script_name name=\"my_form\">\n";

=head3 API SPECIFICATION

=head4 INPUT

None.

=head4 OUTPUT

  {
    type => 'string',
    'min' => 1,
    'nomatch' => qr/^[\/\\]/	# Does not return absolute path
  }

=cut

sub script_name
{
	my $self = shift;

	unless($self->{script_name}) {
		$self->_find_paths();
	}
	return $self->{script_name};
}

sub _find_paths :Protected {
	my $self = shift;

	$self->_trace(__PACKAGE__ . ': entering _find_paths');

	require File::Basename && File::Basename->import() unless File::Basename->can('basename');

	# Determine script name
	my $script_name = $self->_get_env('SCRIPT_NAME') // $0;
	$self->{script_name} = $self->_untaint_filename({
		filename => File::Basename::basename($script_name)
	});

	# Determine script path
	if(my $script_path = $self->_get_env('SCRIPT_FILENAME')) {
		$self->{script_path} = $script_path;
	} elsif($script_name = $self->_get_env('SCRIPT_NAME')) {
		if(my $document_root = $self->_get_env('DOCUMENT_ROOT')) {
			$script_name = $self->_get_env('SCRIPT_NAME');

			# It's usually the case, e.g. /cgi-bin/foo.pl
			$script_name =~ s{^/}{};

			$self->{script_path} = File::Spec->catfile($document_root, $script_name);
		} else {
			if(File::Spec->file_name_is_absolute($script_name) && (-r $script_name)) {
				# Called from a command line with a full path
				$self->{script_path} = $script_name;
			} else {
				require Cwd unless Cwd->can('abs_path');

				if($script_name =~ /^\/(.+)/) {
					# It's usually the case, e.g. /cgi-bin/foo.pl
					$script_name = $1;
				}

				$self->{script_path} = File::Spec->catfile(Cwd::abs_path(), $script_name);
			}
		}
	} elsif(File::Spec->file_name_is_absolute($0)) {
		# Called from a command line with a full path
		$self->{script_path} = $0;
	} else {
		$self->{script_path} = File::Spec->rel2abs($0);
	}

	# Untaint and finalize script path
	$self->{script_path} = $self->_untaint_filename({
		filename => $self->{script_path}
	});
}

=head2 script_path

Finds the full path name of the script.

	use CGI::Info;

	my $info = CGI::Info->new();
	my $fullname = $info->script_path();
	my @statb = stat($fullname);

	if(@statb) {
		my $mtime = localtime $statb[9];
		print "Last-Modified: $mtime\n";
		# TODO: only for HTTP/1.1 connections
		# $etag = Digest::MD5::md5_hex($html);
		printf "ETag: \"%x\"\n", $statb[9];
	}
=cut

sub script_path {
	my $self = shift;

	unless($self->{script_path}) {
		$self->_find_paths();
	}
	return $self->{script_path};
}

=head2 script_dir

Returns the file system directory containing the script.

	use CGI::Info;
	use File::Spec;

	my $info = CGI::Info->new();

	print 'HTML files are normally stored in ', $info->script_dir(), '/', File::Spec->updir(), "\n";

	# or
	use lib CGI::Info::script_dir() . '../lib';

=cut

sub script_dir
{
	my $self = shift;

	# Ensure $self is an object
	$self = __PACKAGE__->new() unless ref $self;

	# Set script path if it is not already defined
	$self->_find_paths() unless $self->{script_path};

	# Extract directory from script path based on OS
	# Don't use File::Spec->splitpath() since that can leave the trailing slash
	my $dir_regex = $^O eq 'MSWin32' ? qr{(.+)\\.+?$} : qr{(.+)/.+?$};

	return $self->{script_path} =~ $dir_regex ? $1 : $self->{script_path};
}

=head2 host_name

Return the host-name of the current web server, according to CGI.
If the name can't be determined from the web server, the system's host-name
is used as a fall back.
This may not be the same as the machine that the CGI script is running on,
some ISPs and other sites run scripts on different machines from those
delivering static content.
There is a good chance that this will be domain_name() prepended with either
'www' or 'cgi'.

	use CGI::Info;

	my $info = CGI::Info->new();
	my $host_name = $info->host_name();
	my $protocol = $info->protocol();
	# ...
	print "Thank you for visiting our <A HREF=\"$protocol://$host_name\">Website!</A>";

=cut

sub host_name {
	my $self = shift;

	unless($self->{site}) {
		$self->_find_site_details();
	}

	return $self->{site};
}

sub _find_site_details :Protected {
	my $self = shift;

	# Log entry to the routine
	$self->_trace('Entering _find_site_details');

	return if $self->{site} && $self->{cgi_site};

	# Determine cgi_site using environment variables or hostname
	if (my $host = ($ENV{'HTTP_HOST'} || $ENV{'SERVER_NAME'} || $ENV{'SSL_TLS_SNI'})) {
		# Import necessary module
			require URI::Heuristic unless URI::Heuristic->can('uf_uristr');

		$self->{cgi_site} = URI::Heuristic::uf_uristr($host);
		# Remove trailing dots from the name.  They are legal in URLs
		# and some sites link using them to avoid spoofing (nice)
		$self->{cgi_site} =~ s/\.+$//;	# Trim trailing dots

		if($ENV{'SERVER_NAME'} && ($host eq $ENV{'SERVER_NAME'}) && (my $protocol = $self->protocol()) && $self->protocol() ne 'http') {
			$self->{cgi_site} =~ s/^http/$protocol/;
		}
	} else {
		# Import necessary module
		require Sys::Hostname unless Sys::Hostname->can('hostname');

		$self->_debug('Falling back to using hostname');
		$self->{cgi_site} = Sys::Hostname::hostname();
	}

	# Set site details if not already defined
	$self->{site} ||= $self->{cgi_site};
	$self->{site} =~ s/^https?:\/\/(.+)/$1/;
	$self->{cgi_site} = ($self->protocol() || 'http') . '://' . $self->{cgi_site}
		unless $self->{cgi_site} =~ /^https?:\/\//;

	# Warn if site details could not be determined
	$self->_warn('Could not determine site name') unless($self->{site} && $self->{cgi_site});

	# Log exit
	$self->_trace('Leaving _find_site_details');
}

=head2 domain_name

Domain_name is the name of the controlling domain for this website.
Usually it will be similar to host_name, but will lack the http:// or www prefixes.

Can be called as a class method.

=cut

sub domain_name {
	my $self = shift;

	if(!ref($self)) {
		$self = __PACKAGE__->new();
	}
	return $self->{domain} if $self->{domain};

	$self->_find_site_details();

	if(my $site = $self->{site}) {
		$self->{domain} = ($site =~ /^www\.(.+)/) ? $1 : $site;
	}

	return $self->{domain};
}

=head2 cgi_host_url

Return the URL of the machine running the CGI script.

=cut

sub cgi_host_url {
	my $self = shift;

	unless($self->{cgi_site}) {
		$self->_find_site_details();
	}

	return $self->{cgi_site};
}

=head2 params

Returns a reference to a hash list of the CGI arguments.

CGI::Info helps you to test your script before deployment on a website:
if it is not in a CGI environment (e.g., the script is being tested from the
command line), the program's command line arguments (a list of key=value pairs)
are used, if there are no command line arguments,
then they are read from stdin as a list of key=value lines.
Also,
you can give one of --tablet, --search-engine,
--mobile and --robot to mimic those agents. For example:

	./script.cgi --mobile name=Nigel

Returns undef if the parameters can't be determined or if none were given.

If an argument is given twice or more, then the values are put in a comma
separated string.

The returned hash value can be passed into L<CGI::Untaint>.

Takes the optional parameters allow, logger and upload_dir.
The request-complexity limits (C<max_body_size>, C<max_params>, C<max_parts>,
C<max_part_headers> and C<max_nesting_depth>) can be set on the constructor or
in the configuration file, and can also be overridden for a single call.
Pass them individually:

	my $params = $info->params(max_params => 50, max_nesting_depth => 2);

or use a shared C<limits> hash reference:

	my $params = $info->params(limits => {
		max_params        => 50,
		max_nesting_depth => 2,
	});

The C<limits> hash may contain any of the five limit names; unknown names are
rejected. Individual limit arguments take precedence over values in the
C<limits> hash. Passing a limit to C<params()> also makes that call re-parse
the request if the cached result was produced with different limits, so a
stricter limit cannot be bypassed by an earlier C<params()> call. The per-call
values apply only to that call; the instance's configured limits are unchanged
afterwards.
The parameters are passed in a hash, or a reference to a hash.
The latter is more efficient since it puts less on the stack.

Allow is a reference to a hash list of CGI parameters that you will allow.
The value for each entry is either a permitted value,
a regular expression of permitted values for
the key,
a code reference,
or a hash of L<Params::Validate::Strict> rules.
Subroutine exceptions propagate normally, allowing custom error handling.
This works alongside existing regex and Params::Validate::Strict patterns.
A undef value means that any value will be allowed.
Arguments not in the list are silently ignored.
This is useful to help to block attacks on your site.

Upload_dir is a string containing a directory where files being uploaded are to
be stored.
It must be a writeable directory inside a temporary area: the directory
returned by L</tmpdir>, a classic system temporary directory such as F</tmp>,
F</var/tmp> or F</usr/tmp>, the area named by C<TMPDIR>, C<TEMP> or C<TMP>, or
on macOS any directory below F</var/folders>.
This matters because a web server usually does not export C<TMPDIR>, so
L</tmpdir> can point somewhere different from the platform's temporary tree.

It has to be a directory I<inside> an area, not the area root itself: C</tmp>
and the like are shared and world-writable, so pass a subdirectory created for
the application instead.
The test is made against the resolved path, so a directory reached through
C<..> is judged by where it really is, and a sibling that merely shares a name
prefix with a temporary area is not accepted.
C<%XX> escapes are decoded first, so an encoded spelling of a path is judged
like its decoded form.
On Windows both C</> and C<\> separate directories, and that is applied after
decoding, so an encoded C<%5C> cannot hide a C<..> traversal either.
Two Windows spellings are refused because they cannot be checked against a
temporary area by comparing strings: a drive-relative path such as C<C:uploads>
(and a bare C<C:>), which starts at the current directory on that drive rather
than at its root, and an 8.3 short name such as C<PROGRA~1>, which is an alias
for a long name that only the filesystem can expand.
Pass a long, absolute path instead.
The filesystem root is never treated as a temporary area.

Takes an optional parameter logger, which is used for warnings and traces.
It can be an object that understands warn() and trace() messages,
such as a L<Log::Log4perl> or L<Log::Any> object,
a reference to code,
a reference to an array,
or a filename.

The allow, logger and upload_dir arguments can also be passed to the
constructor.

	use CGI::Info;
	use CGI::Untaint;
	# ...
	my $info = CGI::Info->new();
	my %params;
	if($info->params()) {
		%params = %{$info->params()};
	}
	# ...
	foreach(keys %params) {
		print "$_ => $params{$_}\n";
	}
	my $u = CGI::Untaint->new(%params);

	use CGI::Info;
	use CGI::IDS;
	# ...
	my $info = CGI::Info->new();
	my $allowed = {
		foo => qr/^\d*$/,	# foo must be a number, or empty
		bar => undef,		# bar can be given and be any value
		xyzzy => qr/^[\w\s-]+$/,	# must be alphanumeric
						# to prevent XSS, and non-empty
						# as a sanity check
	};
	# or
	$allowed = {
		email => { type => 'string', matches => qr/^[^@]+@[^@]+\.[^@]+$/ }, # String, basic email format check
		age => { type => 'integer', min => 0, max => 150 }, # Integer between 0 and 150
		bio => { type => 'string', optional => 1 }, # String, optional
		ip_address => { type => 'string', matches => qr/^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$/ }, #Basic IPv4 validation
	};
	my $paramsref = $info->params(allow => $allowed);
	if(defined($paramsref)) {
		my $ids = CGI::IDS->new();
		$ids->set_scan_keys(scan_keys => 1);
		if($ids->detect_attacks(request => $paramsref) > 0) {
			die 'horribly';
		}
	}

If the request is an XML request (i.e. the content type of the POST is
text/xml, application/xml or a structured application/*+xml type such as
application/soap+xml), CGI::Info will put the request into the params
element 'XML', thus:

	use CGI::Info;
	# ...
	my $info = CGI::Info->new();
	my $paramsref = $info->params();	# See BUGS below
	my $xml = $$paramsref{'XML'};
	# ... parse and process the XML request in $xml

Before returning the body, XML is checked against C<max_params> (the number
of elements, including the root) and C<max_nesting_depth> (element depth,
with the root at depth 1). Comments, CDATA sections and processing
instructions are ignored. A body containing a C<!DOCTYPE> or C<!ENTITY>
declaration is rejected with status C<403> and C<params()> returns undef,
because such declarations enable entity expansion and external entity
attacks. Pass C<< allow_dtd => 1 >> to the constructor to accept them for a
trusted feed; each accepted declaration is still logged as a warning, so the
exception is recorded. These are structural checks, not an XML parser; use a
proper parser with entity expansion disabled for untrusted XML.

Carp if logger is not set and we detect something serious.

Blocks some attacks,
such as SQL and XSS injections,
mustleak and directory traversals,
thus creating a primitive web application firewall (WAF).
Warning - this is an extra layer, not a replacement for your other security layers.

The request-complexity limits (C<max_body_size>, C<max_params>, C<max_parts>,
C<max_part_headers> and C<max_nesting_depth>) are applied before parameter
decoding and, for multipart bodies, while the body is parsed.
A request that exceeds one of them causes C<params()> to return undef
and sets the HTTP status to 413 (Payload Too Large).

=head3 Validation Subroutine Support

The C<allow> parameter accepts subroutine references for dynamic validation,
enabling complex parameter checks beyond static regex patterns.
These callbacks:

=over 4

=item * Receive three arguments: the parameter key, value and the C<CGI::Info> instance

=item * Must return a true value to allow the parameter, false to reject

=item * Can access other parameters through the instance for contextual validation

=back

Basic usage:

    CGI::Info->new(
        allow => {
            # Simple value check
            even_number => sub { ($_[1] % 2) == 0 },

            # Context-aware validation
            child_age => sub {
                my ($key, $value, $info) = @_;
                $info->param('is_parent') ? $value <= 18 : 0
            }
        }
    );

Advanced features:

    # Combine with regex validation
    mixed_validation => {
        email => qr/@/,  # Regex check
        promo_code => \&validate_promo_code  # Subroutine check
    }

    # Throw custom exceptions
    dangerous_param => sub {
        die 'Hacking attempt!' if $_[1] =~ /DROP TABLE/;
        return 1;
    }
=cut

# Validate one per-call limit.  Undef means "no override" so that
# max_body_size can still fall back to max_upload_size.
sub _validate_limit :Protected {
	my ($self, $name, $value) = @_;

	if(ref($value) || ($value !~ /\A[+-]?\d+\z/)) {
		Carp::croak(__PACKAGE__ . "::params: $name must be an integer");
	}

	return $value + 0;
}

# Collect per-call complexity-limit overrides from either a shared limits
# hash-ref, the individual limit arguments, or both.  Individual arguments
# take precedence over values in the shared profile.
sub _per_call_limits :Protected {
	my ($self, $params) = @_;

	return {} unless(defined($params) && (ref($params) eq 'HASH'));

	my %known = map { $_ => 1 } @COMPLEXITY_LIMITS;
	my %limits;

	if(exists($params->{limits}) && defined($params->{limits})) {
		my $profile = $params->{limits};
		unless(ref($profile) eq 'HASH') {
			Carp::croak(__PACKAGE__ . '::params: limits must be a hash reference');
		}

		foreach my $name (keys %{$profile}) {
			unless($known{$name}) {
				Carp::croak(__PACKAGE__ . "::params: unknown complexity limit '$name' in limits");
			}
			next unless(defined($profile->{$name}));
			$limits{$name} = $self->_validate_limit($name, $profile->{$name});
		}
	}

	foreach my $name (@COMPLEXITY_LIMITS) {
		next unless(exists($params->{$name}));
		next unless(defined($params->{$name}));
		$limits{$name} = $self->_validate_limit($name, $params->{$name});
	}

	return \%limits;
}

# The effective raw-body limit.  max_body_size is optional so that existing
# callers keep the historical max_upload_size behaviour when they do not set it.
sub _body_limit :Protected {
	my $self = shift;

	return $self->{max_body_size} if defined($self->{max_body_size});
	return $self->{max_upload_size};
}

# A negative limit means "unlimited"; the comparison is deliberately inclusive
# so that a body or parameter count exactly at the limit is accepted.
sub _over_limit :Protected {
	my ($self, $value, $limit) = @_;

	return 0 unless defined($limit);
	return 0 if($limit < 0);
	return $value > $limit;
}

# Maximum depth of square-bracket nesting in a parameter name:
# a[b][c] is 2, as is a[b[c]].  Counting opening brackets treats sibling
# groups as successive levels, which is how form-to-array names are used.
sub _param_nesting_depth :Protected {
	my ($self, $key) = @_;

	my $depth = () = $key =~ /\[/g;
	return $depth;
}

# Find the '>' that closes a tag, ignoring '>' inside quoted attribute values.
sub _xml_tag_end :Protected {
	my ($self, $xml, $pos) = @_;

	my $length = length($xml);
	my $quote;
	while($pos < $length) {
		my $char = substr($xml, $pos, 1);
		if(defined($quote)) {
			$quote = undef if($char eq $quote);
		} elsif(($char eq '"') || ($char eq "'")) {
			$quote = $char;
		} elsif($char eq '>') {
			return $pos;
		}
		$pos++;
	}

	return -1;
}

# Count XML elements and their maximum nesting depth without parsing the
# document.  Comments, CDATA sections and processing instructions are skipped.
# The root element is at depth 1.  A self-closing element counts as one
# element at depth + 1 but does not open a level for its siblings.
# A DOCTYPE or ENTITY declaration is reported as forbidden: it enables entity
# expansion and external entity attacks, so such a body is rejected unless the
# caller opted in with allow_dtd.
sub _xml_complexity :Protected {
	my ($self, $xml) = @_;

	my $elements = 0;
	my $depth = 0;
	my $max_depth = 0;
	my $forbidden;
	my $pos = 0;
	my $length = length($xml);

	while($pos < $length) {
		my $start = index($xml, '<', $pos);
		last if($start < 0);

		if(substr($xml, $start, 4) eq '<!--') {
			my $end = index($xml, '-->', $start + 4);
			last if($end < 0);
			$pos = $end + 3;
			next;
		}
		if(substr($xml, $start, 9) eq '<![CDATA[') {
			my $end = index($xml, ']]>', $start + 9);
			last if($end < 0);
			$pos = $end + 3;
			next;
		}

		my $end = $self->_xml_tag_end($xml, $start + 1);
		last if($end < 0);
		my $tag = substr($xml, $start + 1, $end - $start - 1);
		$pos = $end + 1;

		if($tag =~ /^\s*!\s*(DOCTYPE|ENTITY)\b/i) {
			$forbidden = uc($1);
		}

		# Declarations, DOCTYPE declarations and processing instructions.
		next if($tag =~ /^\s*[!?]/);

		if($tag =~ m{^/\s*[A-Za-z_][\w.:-]*\s*$}) {
			$depth-- if($depth > 0);
			next;
		}

		next unless($tag =~ m{^\s*[A-Za-z_][\w.:-]*});
		$elements++;

		my $element_depth = $depth + 1;
		$max_depth = $element_depth if($element_depth > $max_depth);
		$depth = $element_depth unless($tag =~ m{/\s*$});
	}

	return { elements => $elements, depth => $max_depth, forbidden => $forbidden };
}

# Identify the effective limits so a cached parameter set is only reused when
# it was produced under the same limits.  _body_limit() is used rather than
# max_body_size because an unset max_body_size falls back to max_upload_size.
sub _limits_key :Protected {
	my $self = shift;

	return join("\0", map { defined($_) ? $_ : 'undef' } (
		$self->_body_limit(),
		$self->{max_params},
		$self->{max_parts},
		$self->{max_part_headers},
		$self->{max_nesting_depth},
	));
}

# Record a complexity rejection once, set the status and log it.  The private
# flag lets callers such as _multipart_data() abort a nested parse and have
# params() stop without confusing an empty result with a successful parse.
sub _reject_complexity :Protected {
	my ($self, $what) = @_;

	$self->{_limit_exceeded} = 1;
	$self->status(413);
	$self->_warn("Request complexity limit exceeded: $what");
	return;
}

# The feed an audit warning belongs to.  This is the request path, so two XML
# endpoints served by one process each get their own warning budget.  The path
# is normalised lexically -- query string dropped, %XX decoded, repeated
# slashes collapsed and '.' or '..' segments resolved -- so the usual spellings
# of one feed share its budget instead of letting a client fragment it.
# Nothing is looked up on disk: these are URL paths, not files.
sub _dtd_audit_key :Protected {
	my $self = shift;

	foreach my $var (qw(PATH_INFO SCRIPT_NAME REQUEST_URI)) {
		my $path = $ENV{$var};
		next unless(defined($path) && length($path));

		$path =~ s/\?.*//s;

		my $key = $self->_tidy_path($path);
		next unless(defined($key) && length($key));
		return $key;
	}

	return '';
}

# Log that allow_dtd let a DOCTYPE/ENTITY declaration through, at most once per
# dtd_warning_interval seconds per request path.  A trusted feed that is polled
# continuously would otherwise write one warning per request; the number of
# declarations accepted for that feed but not logged is reported by its next
# warning.  An interval of 0 (or less) logs every occurrence.
sub _audit_allowed_dtd :Protected {
	my ($self, $declaration) = @_;

	my $interval = $self->{dtd_warning_interval};
	$interval = $DTD_WARNING_INTERVAL_DEFAULT unless defined($interval);

	my $key = $self->_dtd_audit_key();
	# The key comes from the request path, so cap the table: a server that sees
	# an unbounded number of paths must not accumulate entries forever.
	%DTD_WARNING_STATE = () if(scalar(keys %DTD_WARNING_STATE) >= $DTD_WARNING_MAX_KEYS);

	my $now = time();
	my $state = $DTD_WARNING_STATE{$key};
	if(($interval > 0) && defined($state) && $state->{last} && (($now - $state->{last}) < $interval)) {
		$state->{suppressed}++;
		return;
	}

	my $suppressed = defined($state) ? $state->{suppressed} : 0;
	$DTD_WARNING_STATE{$key} = { last => $now, suppressed => 0 };

	my $earlier = $suppressed
		? " ($suppressed earlier declaration" . (($suppressed == 1) ? '' : 's') . ' not logged)'
		: '';
	$self->_warn("XML $declaration declaration allowed by allow_dtd$earlier");

	return;
}

sub params {
	my $self = shift;

	my $params = Params::Get::get_params(undef, @_);
	my $overrides = $self->_per_call_limits($params);

	# Localise the limit slots so per-call values apply to the rest of this
	# call (including _multipart_data()) and are restored on return.
	local $self->{max_body_size} = exists($overrides->{max_body_size})
		? $overrides->{max_body_size} : $self->{max_body_size};
	local $self->{max_params} = exists($overrides->{max_params})
		? $overrides->{max_params} : $self->{max_params};
	local $self->{max_parts} = exists($overrides->{max_parts})
		? $overrides->{max_parts} : $self->{max_parts};
	local $self->{max_part_headers} = exists($overrides->{max_part_headers})
		? $overrides->{max_part_headers} : $self->{max_part_headers};
	local $self->{max_nesting_depth} = exists($overrides->{max_nesting_depth})
		? $overrides->{max_nesting_depth} : $self->{max_nesting_depth};

	my $limits_key = $self->_limits_key();

	if((defined($self->{paramref})) && (defined($self->{_limits_key})) && ($self->{_limits_key} eq $limits_key) && ((!defined($params->{'allow'})) || defined($self->{allow}) && ($params->{'allow'} eq $self->{allow}))) {
		return $self->{paramref};
	}

	if(defined($params->{allow})) {
		$self->{allow} = $params->{allow};
	}
	if(defined($params->{upload_dir})) {
		$self->{upload_dir} = $params->{upload_dir};
	}
	if(defined($params->{'logger'})) {
		$self->set_logger($params->{'logger'});
	}
	$self->_trace('Entering params');

	# A fresh parse may fail part-way through; do not leave a previous call's
	# accepted parameter set (or its limit key) available for a later call.
	delete $self->{paramref};
	delete $self->{_limits_key};
	delete $self->{_limit_exceeded};

	my @pairs;
	my $content_type = $ENV{'CONTENT_TYPE'};
	my %FORM;

	if((!$ENV{'GATEWAY_INTERFACE'}) || (!$ENV{'REQUEST_METHOD'})) {
		# require IO::Interactive;
		# IO::Interactive->import();

		if(@ARGV) {
			@pairs = @ARGV;
			if(defined($pairs[0])) {
				if($pairs[0] eq '--robot') {
					$self->{is_robot} = 1;
					shift @pairs;
				} elsif($pairs[0] eq '--mobile') {
					$self->{is_mobile} = 1;
					shift @pairs;
				} elsif($pairs[0] eq '--search-engine') {
					$self->{is_search_engine} = 1;
					shift @pairs;
				} elsif($pairs[0] eq '--tablet') {
					$self->{is_tablet} = 1;
					shift @pairs;
				}
			}
		} elsif($stdin_data) {
			# Re-use previously read STDIN (class variable shared across instances)
			@pairs = split(/\n/, $stdin_data);
		}
	} elsif(($ENV{'REQUEST_METHOD'} eq 'GET') || ($ENV{'REQUEST_METHOD'} eq 'HEAD')) {
		if(my $query = $ENV{'QUERY_STRING'}) {
			if((defined($content_type)) && ($content_type =~ /multipart\/form-data/i)) {
				if($ENV{'REMOTE_ADDR'}) {
					$self->_warn({ warning => "$ENV{REMOTE_ADDR}: Multipart/form-data not supported for GET (query string = $query)" });
				} else {
					$self->_warn('Multipart/form-data not supported for GET');
				}
				$self->status(501);	# Not implemented
				return;
			}
			$query =~ s/\\u0026/\&/g;
			@pairs = split(/&/, $query);
		} else {
			return;
		}
	} elsif($ENV{'REQUEST_METHOD'} eq 'POST') {
		my $content_length = $self->_get_env('CONTENT_LENGTH');
		if((!defined($content_length)) || ($content_length =~ /\D/)) {
			$self->{status} = 411;
			return;
		}
		my $body_limit = $self->_body_limit();
		if($self->_over_limit($content_length, $body_limit)) {
			# TODO: Design a way to tell the caller to send HTTP
			# status 413
			$self->{status} = 413;
			$self->_warn('Large upload prohibited');
			return;
		}
		if(($self->{max_upload_size} >= 0) && ($content_length > $self->{max_upload_size})) {	# Set maximum posts
			$self->{status} = 413;
			$self->_warn('Large upload prohibited');
			return;
		}
		if(defined($stdin_data) && $self->_over_limit(length($stdin_data), $body_limit)) {
			$self->{status} = 413;
			$self->_warn('Large upload prohibited');
			return;
		}

		if((!defined($content_type)) || ($content_type =~ /application\/x-www-form-urlencoded/)) {
			my $buffer;
			if($stdin_data) {
				$buffer = $stdin_data;
			} else {
				if(read(STDIN, $buffer, $content_length) != $content_length) {
					$self->_warn('POST failed: something else may have read STDIN');
				}
				$stdin_data = $buffer;
			}
			@pairs = split(/&/, $buffer);

			# if($ENV{'QUERY_STRING'}) {
				# my @getpairs = split(/&/, $ENV{'QUERY_STRING'});
				# push(@pairs, @getpairs);
			# }
		} elsif($content_type =~ /multipart\/form-data/i) {
			if(!defined($self->{upload_dir})) {
				if($ENV{'REMOTE_ADDR'}) {
					# This could be an attack
					$self->_warn({ warning => "$ENV{REMOTE_ADDR}: Attempt to upload a file of $content_length bytes when upload_dir has not been set" });
				} else {
					$self->_warn({ warning => 'Attempt to upload a file when upload_dir has not been set' });
				}
				$self->status(501);	# Not implemented
				return;
			}

			# Validate 'upload_dir'
			# Ensure the upload directory is safe and accessible
			# - Check permissions
			# - Validate path to prevent directory traversal attacks
			# TODO: Consider using a temporary directory for uploads and moving them later
			if(!File::Spec->file_name_is_absolute($self->{upload_dir})) {
				$self->_warn({
					warning => "upload_dir $self->{upload_dir} isn't a full pathname"
				});
				$self->status(500);
				delete $self->{upload_dir};
				return;
			}
			if(!-d $self->{upload_dir}) {
				$self->_warn({
					warning => "upload_dir $self->{upload_dir} isn't a directory"
				});
				$self->status(500);
				delete $self->{upload_dir};
				return;
			}
			if(!-w $self->{upload_dir}) {
				delete $self->{paramref};
				delete $self->{_limits_key};
				$self->_warn({
					warning => "upload_dir $self->{upload_dir} isn't writeable"
				});
				$self->status(500);
				delete $self->{upload_dir};
				return;
			}
			if(my $problem = $self->_win32_path_problem($self->{'upload_dir'})) {
				$self->_warn({
					warning => 'upload_dir ' . $self->{'upload_dir'} . " $problem, so it can't be checked against the temporary areas"
				});
				$self->status(500);
				delete $self->{upload_dir};
				return;
			}
			if(!$self->_in_temp_area($self->{'upload_dir'})) {
				my $root = $self->_temp_area_root($self->{'upload_dir'});
				$self->_warn({
					warning => defined($root)
						? 'upload_dir ' . $self->{'upload_dir'} . " is the temporary area root $root, not a directory inside it"
						: 'upload_dir ' . $self->{'upload_dir'} . " isn't in a temporary area ("
							. join(', ', $self->_temp_areas()) . ')'
				});
				$self->status(500);
				delete $self->{upload_dir};
				return;
			}
			if($content_type =~ /boundary=(\S+)$/) {
				@pairs = $self->_multipart_data({
					length => $content_length,
					boundary => $1
				});
				return if($self->{_limit_exceeded});
			}
		} elsif($content_type =~ m{^\s*(?:(?:text|application)/xml|application/[^/;\s]+\+xml)\s*(?:;.*)?$}i) {
			my $buffer;
			if($stdin_data) {
				$buffer = $stdin_data;
			} else {
				if(read(STDIN, $buffer, $content_length) != $content_length) {
					$self->_warn({
						warning => 'XML failed: something else may have read STDIN'
					});
				}
				$stdin_data = $buffer;
			}

			my $complexity = $self->_xml_complexity($buffer);
			if(defined($complexity->{forbidden})) {
				if(!$self->{allow_dtd}) {
					$self->status(403);
					$self->_warn("XML $complexity->{forbidden} declaration blocked");
					return;
				}
				# Audit trail: a DTD is only ever accepted because the caller
				# opted in, so record that the exception was used.
				$self->_audit_allowed_dtd($complexity->{forbidden});
			}
			if($self->_over_limit($complexity->{elements}, $self->{max_params})) {
				$self->_reject_complexity("more than $self->{max_params} XML elements");
				return;
			}
			if($self->_over_limit($complexity->{depth}, $self->{max_nesting_depth})) {
				$self->_reject_complexity("XML nesting deeper than $self->{max_nesting_depth}");
				return;
			}

			$FORM{XML} = $buffer;

			$self->{paramref} = \%FORM;
			$self->{_limits_key} = $limits_key;

			return \%FORM;
		} elsif($content_type =~ /application\/json/i) {
			require JSON::MaybeXS && JSON::MaybeXS->import() unless JSON::MaybeXS->can('parse_json');
			# require JSON::MaybeXS;
			# JSON::MaybeXS->import();

			my $buffer;

			if($stdin_data) {
				$buffer = $stdin_data;
			} else {
				if(read(STDIN, $buffer, $content_length) != $content_length) {
					$self->_warn({
						warning => 'read failed: something else may have read STDIN'
					});
				}
				$stdin_data = $buffer;
			}
			# JSON::Parse::assert_valid_json($buffer);
			# my $paramref = JSON::Parse::parse_json($buffer);
			my $paramref = decode_json($buffer);
			foreach my $key(keys(%{$paramref})) {
				push @pairs, "$key=" . $paramref->{$key};
			}
		} else {
			my $buffer;
			if($stdin_data) {
				$buffer = $stdin_data;
			} else {
				if(read(STDIN, $buffer, $content_length) != $content_length) {
					$self->_warn({
						warning => 'read failed: something else may have read STDIN'
					});
				}
				$stdin_data = $buffer;
			}

			$self->_warn({
				warning => "POST: Invalid or unsupported content type: $content_type: $buffer",
			});
		}
	} elsif($ENV{'REQUEST_METHOD'} eq 'OPTIONS') {
		$self->{status} = 405;
		return;
	} elsif($ENV{'REQUEST_METHOD'} eq 'DELETE') {
		$self->{status} = 405;
		return;
	} else {
		# TODO: Design a way to tell the caller to send HTTP
		# status 501
		$self->{status} = 501;
		$self->_warn({
			warning => 'Use POST, GET or HEAD, not ' . $ENV{REQUEST_METHOD}
		});
	}

	if($self->_over_limit(scalar(@pairs), $self->{max_params})) {
		$self->_reject_complexity("more than $self->{max_params} parameters");
		return;
	}

	unless(scalar @pairs) {
		return;
	}

	require String::Clean::XSS;
	String::Clean::XSS->import();
	# require String::EscapeCage;
	# String::EscapeCage->import();

	foreach my $arg (@pairs) {
		my($key, $value) = split(/=/, $arg, 2);

		next unless($key);

		$key =~ s/\0//g;	# Strip encoded NUL byte poison
		$key =~ s/%00//g;	# Strip NUL byte poison
		$key =~ s/%([a-fA-F\d][a-fA-F\d])/pack("C", hex($1))/eg;
		$key =~ tr/+/ /;
		if(defined($value)) {
			$value =~ s/%00//g;   # Strip encoded NUL byte poison
			$value =~ s/%([a-fA-F\d][a-fA-F\d])/pack("C", hex($1))/eg;   # URL-decode (1st pass)
			$value =~ s/%([a-fA-F\d][a-fA-F\d])/pack("C", hex($1))/eg;   # URL-decode (2nd pass: catches %252F -> %2F -> /)
			$value =~ tr/+/ /;
			$value =~ s/\0//g;    # Strip NUL: %2500 -> %00 -> NUL
			$value =~ s/%00//g;   # Strip literal %00
		} else {
			$value = '';
		}

		if($self->_over_limit($self->_param_nesting_depth($key), $self->{max_nesting_depth})) {
			$self->_reject_complexity("parameter name nesting deeper than $self->{max_nesting_depth}");
			return;
		}

		$key = _sanitise_input($key);

		if($self->{allow}) {
			# Is this a permitted argument?
			if(!exists($self->{allow}->{$key})) {
				$self->_info("Discard unallowed argument '$key'");
				$self->status(422);
				next;	# Skip to the next parameter
			}

			# Do we allow any value, or must it be validated?
			if(defined(my $schema = $self->{allow}->{$key})) {	# Get the schema for this key
				if(!ref($schema)) {
					# Can only contain one value
					if($value ne $schema) {
						$self->_info("Block $key = $value");
						$self->status(422);
						next;	# Skip to the next parameter
					}
				} elsif(ref($schema) eq 'Regexp') {
					if($value !~ $schema) {
						# Simple regex
						$self->_info("Block $key = $value");
						$self->status(422);
						next;	# Skip to the next parameter
					}
				} elsif(ref($schema) eq 'CODE') {
					unless($schema->($key, $value, $self)) {
						$self->_info("Block $key = $value");
						next;
					}
				} else {
					# Set of rules
					eval {
						$value = Params::Validate::Strict::validate_strict({
							schema => { $key => $schema },
							args => { $key => $value },
							unknown_parameter_handler => 'die',
							logger => $self->{'logger'}
						});
					};
					if($@) {
						$self->_info("Block $key = $value: $@");
						$self->status(422);
						next;	# Skip to the next parameter
					}
					if(scalar keys %{$value}) {
						$value = $value->{$key};
					} else {
						$self->_info("Block $key = $value");
						$self->status(422);
						next;	# Skip to the next parameter
					}
				}
			}
		}

		# if($self->{expect} && (List::Util::none { $_ eq $key } @{$self->{expect}})) {
			# next;
		# }
		my $orig_value = $value;
		$value = _sanitise_input($value);

		# WAF: inspect all methods (GET and POST) for injection patterns.
		# Previously gated on GET only, which allowed POST to bypass all checks.
		{
			   # ($value =~ /\/AND\/.++\(SELECT\//) || # United/**/States)/**/AND/**/(SELECT/**/6734/**/FROM/**/(SELECT(SLEEP(5)))lRNi)/**/AND/**/(8984=8984
			# From http://www.symantec.com/connect/articles/detection-sql-injection-and-cross-site-scripting-attacks
			# Facebook FBCLID can have "--"

			# Pre-filter: only run quote-based regexes if value contains injection chars.

			# Compute pre-filter flags from orig_value so quotes stripped by
			# convert_XSS don't cause injection patterns to be missed

			my $has_quote  = index($orig_value, "'")    >= 0 || index($orig_value, '%27') >= 0;
			my $has_hash   = index($orig_value, '#')    >= 0 || index($orig_value, '%23') >= 0;
			my $has_equals = index($orig_value, '=')    >= 0 || index($orig_value, '%3D') >= 0;
			my $has_semi   = index($orig_value, ';')    >= 0 || index($orig_value, '%3B') >= 0;
			my $has_dash   = index($orig_value, '--')   >= 0;

			# All WAF patterns run on $orig_value (pre-XSS-sanitisation)
			# convert_XSS encodes ', =, < etc. as HTML entities, which would hide
			# injection patterns from the WAF if we checked $value instead.
			if($has_quote || $has_hash || ($has_equals && $has_dash)) {
				if(($orig_value =~ /(?:%27|'|%23|#)/i) ||
				   (($has_equals && ($has_quote || $has_semi || $has_dash)) &&
				   $orig_value =~ /(?:%3D|=)[^-]*+(?:%27|'|--|%3B|;)/i) ||
				   ($has_quote &&
				   # Detect 'or'-style injection: word + quote + url-encoded or literal 'or' + SQL keyword.
				   # (?:%6F|o|%4F) = 'o', (?:%72|r|%52) = 'r', both case-folded via /i.
				    $orig_value =~ /\w*(?:%27|')(?:%6F|o|%4F)(?:%72|r|%52)\s*(?:OR|AND|UNION|SELECT|--)/ix) ||
				    ($has_quote &&
				    $orig_value =~ /(?:%27|')union/ix)) {
					$self->status(403);
					if($ENV{'REMOTE_ADDR'}) {
						$self->_warn($ENV{'REMOTE_ADDR'} . ": SQL injection attempt blocked for '$key=$orig_value'");
					} else {
						$self->_warn("SQL injection attempt blocked for '$key=$orig_value'");
					}
					return;
				}
			}

			my $has_select = index($orig_value, 'SELECT') >= 0 || index($orig_value, 'select') >= 0;
			my $has_dump   = index($orig_value, 'var_dump') >= 0;
			my $has_exec   = index($orig_value, 'exec') >= 0;
			my $has_or  = index($orig_value, ' OR ')  >= 0;
			my $has_and = index($orig_value, ' AND ') >= 0;
			my $has_slash  = index($orig_value, '/**/') >= 0 || index($orig_value, '/AND/') >= 0;

			if(# \b anchors prevent matching inside longer words.
			   # {1,500}? is lazy+bounded: avoids catastrophic backtracking on
			   # "SELECT aaaa...aaaa" (no FROM) while still catching real queries.
			   ($has_select && $orig_value =~ /\bselect\b.{1,500}?\bfrom\b/is) ||
			   ($has_and    && $orig_value =~ /\sAND\s1=1/ix) ||
			   # Numeric tautology without quotes: OR 1=1, OR 2=2, etc.
			   ($has_or     && $orig_value =~ /\bOR\s+\d+\s*=\s*\d+/i) ||
			   # Bounded lazy .{1,500}? avoids backtracking on "OR aaaa..." with no AND.
			   ($has_or && $has_and && $orig_value =~ /\sOR\s.{1,500}?\sAND\s/) ||
			   ($has_slash  && $orig_value =~ /\/\*\*\/ORDER\/\*\*\/BY\/\*\*/ix) ||
			   ($has_dump   && $orig_value =~ /var_dump[^m]*+md5/) ||
			   ($has_slash  && $has_select && $orig_value =~ /\/AND\/[^(]*+\(SELECT\//) ||
			   ($has_exec   && $orig_value =~ /exec[\s+]++[sx]p\w+/ix)) {
				$self->status(403);
				if($ENV{'REMOTE_ADDR'}) {
					$self->_warn($ENV{'REMOTE_ADDR'} . ": SQL injection attempt blocked for '$key=$orig_value'");
				} else {
					$self->_warn("SQL injection attempt blocked for '$key=$orig_value'");
				}
				return;
			}

			if(my $agent = $ENV{'HTTP_USER_AGENT'}) {
			# Bounded lazy .{1,500}? separates SQL keyword pairs without catastrophic backtracking.
			# Possessive .++ would consume the trailing anchor — never match. Unbounded .+ risks ReDoS.
			if(($agent =~ /\bSELECT\b.{1,500}?\bAND\b/i) || ($agent =~ /\bORDER\s+BY\b/i) || ($agent =~ /\bOR\s+NOT\b/i) || ($agent =~ /\bAND\b\s+\d+=\d+/) || ($agent =~ /\bTHEN\b.{1,300}?\bELSE\b.{1,300}?\bEND\b/i) || ($agent =~ /\bAND\b.{1,500}?\bSELECT\b/i) || ($agent =~ /\sAND\s.{1,500}?\sAND\s/)) {
					$self->status(403);
					if($ENV{'REMOTE_ADDR'}) {
						$self->_warn($ENV{'REMOTE_ADDR'} . ": SQL injection attempt blocked for '$agent'");
					} else {
						$self->_warn("SQL injection attempt blocked for '$agent'");
					}
					return;
				}
			}

			# XSS detection using [^>]+ instead of .+ or .++ :
			#   - [^>]+ stops naturally at '>' — no backtracking, no ReDoS.
			#   - [^>] also matches '\n', so multi-line payloads like
			#     "<img\nsrc=x\nonerror=alert(1)>" are caught without /s.
			#   - Replaces both the old [^\n]+ (stopped at newline — bypass)
			#     and the broken .++ (possessive consumed '>' — never matched).
			if(($value =~ /(?:%3C|<)(?:%2F|\/)*[a-z0-9%]+(?:%3E|>)/ix) ||
			   ($value =~ /(?:%3C|<)[^>]+(?:%3E|>)/i) ||
			   ($orig_value =~ /(?:%3C|<)(?:%2F|\/)*[a-z0-9%]+(?:%3E|>)/ix) ||
			   ($orig_value =~ /(?:%3C|<)[^>]+(?:%3E|>)/i)) {
				$self->status(403);
				$self->_warn("XSS injection attempt blocked for '$value'");
				return;
			}

			# Block javascript: URI scheme — no angle brackets, but still executes
			# script when used in href or src attributes.
			if($orig_value =~ /\bjavascript\s*:/i) {
				$self->status(403);
				$self->_warn("XSS injection attempt blocked for '$value'");
				return;
			}

			if($value =~ /mustleak\.com\//) {
				$self->status(403);
				$self->_warn("Blocked mustleak attack for '$key'");
				return;
			}

			if($value =~ /\.\.\//) {
				$self->status(403);
				$self->_warn("Blocked directory traversal attack for '$key'");
				return;
			}
		}
		if(length($value) > 0) {
			# Don't add if it's already there
			if($FORM{$key} && ($FORM{$key} ne $value)) {
				$FORM{$key} .= ",$value";
			} else {
				$FORM{$key} = $value;
			}
		}
	}

	unless(%FORM) {
		return;
	}

	if($self->{'logger'}) {
		while(my ($key,$value) = each %FORM) {
			$self->_debug("$key=$value");
		}
	}

	$self->{paramref} = \%FORM;
	$self->{_limits_key} = $limits_key;

	return Return::Set::set_return(\%FORM, { type => 'hashref', min => 1 });
}

=head2 param($field)

Get a single CGI parameter value by name.
When called without arguments it delegates to C<params()> and returns all parameters.
When called with a field name it returns that parameter's (sanitised) value,
or C<undef> if the parameter was not supplied or is not in the allow list.

	use CGI::Info;
	my $info = CGI::Info->new();
	my $bar  = $info->param('foo');

	# With an allow list:
	my $info2 = CGI::Info->new();
	my $allowed = { foo => qr/\d+/ };
	$info2->params(allow => $allowed);
	my $bar2 = $info2->param('bar');   # logs a warning; returns undef

=over 4

=item $field

Optional. The name of the CGI parameter to retrieve.
If omitted, all parameters (as a hash-ref) are returned via C<params()>.

=back

=head3 API SPECIFICATION

=head4 Input

	{
		field => { type => 'scalar', optional => 1 },
	}

=head4 Output

	# When $field is supplied
	{ type => 'scalar', optional => 1 }
	# When $field is omitted (delegates to params())
	{ type => 'hashref', optional => 1 }

=head3 MESSAGES

	| Level | Message                                  | Meaning                              | Action                                  |
	|-------|------------------------------------------|--------------------------------------|-----------------------------------------|
	| warn  | param: <field> isn't in the allow list   | Caller requested a parameter outside | Review the allow list passed to new()   |
	|       |                                          | the schema set by params(allow=>\%h) | or params(); add the key if legitimate  |

=cut

sub param {
	my ($self, $field) = @_;

	if(!defined($field)) {
		return $self->params();
	}
	# Is this a permitted argument?
	if($self->{allow} && !exists($self->{allow}->{$field})) {
		$self->_warn({
			warning => "param: $field isn't in the allow list"
		});
		return;
	}

	# Prevent deep recursion which can happen when a validation routine calls param()
	my $allow;
	if($self->{in_param} && $self->{allow}) {
		$allow = delete $self->{allow};
	}
	$self->{in_param} = 1;

	my $params = $self->params();

	$self->{in_param} = 0;
	$self->{allow} = $allow if($allow);

	if($params) {
		return Return::Set::set_return($params->{$field}, { type => 'string' });
	}
}

sub _sanitise_input :Protected {
	my $arg = shift;

	# Protected function: inline check because the ($) prototype means no $self,
	unless($ENV{HARNESS_ACTIVE}) {
		my $calling_pkg = (caller)[0];
		unless($calling_pkg && ($calling_pkg eq __PACKAGE__ || $calling_pkg->isa(__PACKAGE__))) {
			Carp::croak('_sanitise_input() is a protected function and cannot be called from outside ' . __PACKAGE__);
		}
	}

	return if(!defined($arg));

	# Remove hacking attempts and spaces
	$arg =~ s/[\r\n]//g;
	$arg =~ s/\s+$//;
	$arg =~ s/^\s+//;

	# Possessive quantifier prevents catastrophic backtracking when input
	# contains '<!--' with no matching closing '-->'.
	$arg =~ s/<!--[^-]*+(?:-(?!->)[^-]*+)*+-->//g;
	# Allow :
	# $arg =~ s/[;<>\*|`&\$!?#\(\)\[\]\{\}'"\\\r]//g;

	# return $arg;
	# return String::EscapeCage->new(convert_XSS($arg))->escapecstring();
	return convert_XSS($arg);
}

sub _multipart_data :Protected {
	my ($self, $args) = @_;

	$self->_trace('Entering _multipart_data');

	my $total_bytes = $$args{length};

	$self->_debug("_multipart_data: total_bytes = $total_bytes");

	if($total_bytes == 0) {
		return;
	}

	unless($stdin_data) {
		# Read no more than the declared body length.  The old line loop read
		# until EOF, which ignored CONTENT_LENGTH and could grow without bound
		# if the server passed more bytes than the declared request body.
		my $buffer = '';
		my $remaining = $total_bytes;
		while($remaining > 0) {
			my $chunk;
			my $got = read(STDIN, $chunk, $remaining);
			last unless(defined($got) && ($got > 0));
			$buffer .= $chunk;
			$remaining -= $got;
		}
		$buffer =~ s/\r//g;
		$stdin_data = $buffer;
		if(!$stdin_data) {
			return;
		}
	}

	my $boundary = $$args{boundary};

	my @pairs;
	my $writing_file = 0;
	my $key;
	my $value;
	my $in_header = 0;
	my $fout;
	my $part_count = 0;
	my $header_count = 0;

	foreach my $line(split(/\n/, $stdin_data)) {
		if($line =~ /^--\Q$boundary\E--$/) {
			last;
		}
		if($line =~ /^--\Q$boundary\E$/) {
			$part_count++;
			if($self->_over_limit($part_count, $self->{max_parts})) {
				close $fout if($writing_file);
				$self->_reject_complexity("more than $self->{max_parts} multipart parts");
				return;
			}
			if($writing_file) {
				close $fout;
				$writing_file = 0;
			} elsif(defined($key)) {
				push(@pairs, "$key=$value");
				$value = undef;
			}
			$in_header = 1;
			$header_count = 0;
		} elsif($in_header) {
			if(length($line) == 0) {
				$in_header = 0;
			} else {
				$header_count++;
				if($self->_over_limit($header_count, $self->{max_part_headers})) {
					close $fout if($writing_file);
					$self->_reject_complexity("more than $self->{max_part_headers} headers in a multipart part");
					return;
				}
				if($line =~ /^Content-Disposition: (.+)/i) {
					my $field = $1;
					if($field =~ /name="(.+?)"/) {
						$key = $1;
						if($self->_over_limit($self->_param_nesting_depth($key), $self->{max_nesting_depth})) {
							close $fout if($writing_file);
							$self->_reject_complexity("parameter name nesting deeper than $self->{max_nesting_depth}");
							return;
						}
					}
					# [^"]+ instead of .+ : stops at first '"' without backtracking,
					# and cannot accidentally capture across the closing delimiter.
					if($field =~ /filename="([^"]+)?"/) {
						my $filename = $1;
						unless(defined($filename)) {
							$self->_warn('No upload filename given');
						} elsif($filename =~ /[\\\/\|]/) {
							$self->_warn("Disallowing invalid filename: $filename");
						} else {
							$filename = $self->_create_file_name({
								filename => $filename
							});

							# Don't do this since it taints the string and I can't work out how to untaint it
							# my $full_path = Cwd::realpath(File::Spec->catfile($self->{upload_dir}, $filename));
							# $full_path = m/^(\/[\w\.]+)$/;
							my $full_path = File::Spec->catfile($self->{upload_dir}, $filename);
							unless(open($fout, '>', $full_path)) {
								$self->_warn("Can't open $full_path");
							}
							$writing_file = 1;
							push(@pairs, "$key=$filename");
						}
					}
				}
			}
			# TODO: handle Content-Type: text/plain, etc.
		} else {
			if($writing_file) {
				print $fout "$line\n";
			} else {
				$value .= $line;
			}
		}
	}

	if($writing_file) {
		close $fout;
	}

	$self->_trace('Leaving _multipart_data');

	return @pairs;
}

# Robust filename generation (preventing overwriting).
# Previously used "! -e $rc" which checked existence in the CURRENT WORKING
# DIRECTORY, not the upload directory — a logic bug and a TOCTOU race.
# Now checks in the actual upload directory and caps iterations to avoid
# an infinite loop if the directory fills up.
sub _create_file_name :Protected {
	my ($self, $args) = @_;

	my $upload_dir = $self->{upload_dir};
	my $filename   = $$args{filename} . '_' . time;

	my $counter = 0;
	my $rc;
	do {
		$rc = $filename . ($counter ? "_$counter" : '');
		$counter++;
		# Check in upload_dir when set; otherwise check relative to CWD.
		# File::Spec->catfile('', ...) produces an absolute path, so we
		# must not pass an empty string as the directory component.
	} until(
		! -e ($upload_dir ? File::Spec->catfile($upload_dir, $rc) : $rc)
		|| $counter > 1000
	);
	if($counter > 1000) {
		Carp::croak('_create_file_name: unable to find a unique filename after 1000 attempts');
	}

	return $rc;
}

# Untaint a filename. Regex from CGI::Untaint::Filenames
sub _untaint_filename :Protected {
	my ($self, $args) = @_;

	if($$args{filename} =~ /(^[\w\+_\040\#\(\)\{\}\[\]\/\-\^,\.:;&%@\\~]+\$?$)/) {
		return $1;
	}
	return;
}

=head2 is_mobile

Returns a boolean if the website is being viewed on a mobile
device such as a smartphone.
All tablets are mobile, but not all mobile devices are tablets.

Can be overridden by the IS_MOBILE environment setting

=cut

sub is_mobile {
	my $self = shift;

	if(defined($self->{is_mobile})) {
		return $self->{is_mobile};
	}

	if($ENV{'IS_MOBILE'}) {
		return $ENV{'IS_MOBILE'}
	}

	# Support Sec-CH-UA-Mobile
	if(my $ch_ua_mobile = $ENV{'HTTP_SEC_CH_UA_MOBILE'}) {
		if($ch_ua_mobile eq '?1') {
			$self->{is_mobile} = 1;
			return 1;
		}
	}

	if($ENV{'HTTP_X_WAP_PROFILE'}) {
		# E.g. Blackberry
		# TODO: Check the sanity of this variable
		$self->{is_mobile} = 1;
		return 1;
	}

	if(my $agent = $ENV{'HTTP_USER_AGENT'}) {
		# Was '.+(Android|iPhone).+' — .+ before and after adds no useful
		# constraint but causes ReDoS on long UAs without those tokens.
		if($agent =~ /\b(?:Android|iPhone)\b/) {
			$self->{is_mobile} = 1;
			return 1;
		}

		# From http://detectmobilebrowsers.com/
		if($agent =~ m/(android|bb\d+|meego).+mobile|avantgo|bada\/|blackberry|blazer|compal|elaine|fennec|hiptop|iemobile|ip(hone|od)|iris|kindle|lge |maemo|midp|mmp|mobile.+firefox|netfront|opera m(ob|in)i|palm( os)?|phone|p(ixi|re)\/|plucker|pocket|psp|series(4|6)0|symbian|treo|up\.(browser|link)|vodafone|wap|windows ce|xda|xiino/i || substr($ENV{'HTTP_USER_AGENT'}, 0, 4) =~ m/1207|6310|6590|3gso|4thp|50[1-6]i|770s|802s|a wa|abac|ac(er|oo|s\-)|ai(ko|rn)|al(av|ca|co)|amoi|an(ex|ny|yw)|aptu|ar(ch|go)|as(te|us)|attw|au(di|\-m|r |s )|avan|be(ck|ll|nq)|bi(lb|rd)|bl(ac|az)|br(e|v)w|bumb|bw\-(n|u)|c55\/|capi|ccwa|cdm\-|cell|chtm|cldc|cmd\-|co(mp|nd)|craw|da(it|ll|ng)|dbte|dc\-s|devi|dica|dmob|do(c|p)o|ds(12|\-d)|el(49|ai)|em(l2|ul)|er(ic|k0)|esl8|ez([4-7]0|os|wa|ze)|fetc|fly(\-|_)|g1 u|g560|gene|gf\-5|g\-mo|go(\.w|od)|gr(ad|un)|haie|hcit|hd\-(m|p|t)|hei\-|hi(pt|ta)|hp( i|ip)|hs\-c|ht(c(\-| |_|a|g|p|s|t)|tp)|hu(aw|tc)|i\-(20|go|ma)|i230|iac( |\-|\/)|ibro|idea|ig01|ikom|im1k|inno|ipaq|iris|ja(t|v)a|jbro|jemu|jigs|kddi|keji|kgt( |\/)|klon|kpt |kwc\-|kyo(c|k)|le(no|xi)|lg( g|\/(k|l|u)|50|54|\-[a-w])|libw|lynx|m1\-w|m3ga|m50\/|ma(te|ui|xo)|mc(01|21|ca)|m\-cr|me(rc|ri)|mi(o8|oa|ts)|mmef|mo(01|02|bi|de|do|t(\-| |o|v)|zz)|mt(50|p1|v )|mwbp|mywa|n10[0-2]|n20[2-3]|n30(0|2)|n50(0|2|5)|n7(0(0|1)|10)|ne((c|m)\-|on|tf|wf|wg|wt)|nok(6|i)|nzph|o2im|op(ti|wv)|oran|owg1|p800|pan(a|d|t)|pdxg|pg(13|\-([1-8]|c))|phil|pire|pl(ay|uc)|pn\-2|po(ck|rt|se)|prox|psio|pt\-g|qa\-a|qc(07|12|21|32|60|\-[2-7]|i\-)|qtek|r380|r600|raks|rim9|ro(ve|zo)|s55\/|sa(ge|ma|mm|ms|ny|va)|sc(01|h\-|oo|p\-)|sdk\/|se(c(\-|0|1)|47|mc|nd|ri)|sgh\-|shar|sie(\-|m)|sk\-0|sl(45|id)|sm(al|ar|b3|it|t5)|so(ft|ny)|sp(01|h\-|v\-|v )|sy(01|mb)|t2(18|50)|t6(00|10|18)|ta(gt|lk)|tcl\-|tdg\-|tel(i|m)|tim\-|t\-mo|to(pl|sh)|ts(70|m\-|m3|m5)|tx\-9|up(\.b|g1|si)|utst|v400|v750|veri|vi(rg|te)|vk(40|5[0-3]|\-v)|vm40|voda|vulc|vx(52|53|60|61|70|80|81|83|85|98)|w3c(\-| )|webc|whit|wi(g |nc|nw)|wmlb|wonu|x700|yas\-|your|zeto|zte\-/i) {
			$self->{is_mobile} = 1;
			return 1;
		}

		# Save loading and calling HTTP::BrowserDetect
		my $remote = $ENV{'REMOTE_ADDR'};
		if(defined($remote) && $self->{cache}) {
			if(my $type = $self->{cache}->get("$remote/$agent")) {
				return $self->{is_mobile} = ($type eq 'mobile');
			}
		}

		unless($self->{browser_detect}) {
			if(eval { require HTTP::BrowserDetect; }) {
				HTTP::BrowserDetect->import();
				$self->{browser_detect} = HTTP::BrowserDetect->new($agent);
			}
		}

		if($self->{browser_detect}) {
			my $device = $self->{browser_detect}->device();
			# Without the ?1:0 it will set to the empty string not 0
			my $is_mobile = (defined($device) && ($device =~ /blackberry|webos|iphone|ipod|ipad|android/i)) ? 1 : 0;
			if($is_mobile && $self->{cache} && defined($remote)) {
				$self->{cache}->set("$remote/$agent", 'mobile', $CACHE_TTL_SEARCH);
			}
			return $self->{is_mobile} = $is_mobile;
		}
	}

	return 0;
}

=head2 is_tablet

Returns a boolean if the website is being viewed on a tablet such as an iPad.

=cut

sub is_tablet {
	my $self = shift;

	if(defined($self->{is_tablet})) {
		return $self->{is_tablet};
	}

	# Was '.+(iPad|TabletPC).+' — same ReDoS risk as the mobile pattern above.
	if($ENV{'HTTP_USER_AGENT'} && ($ENV{'HTTP_USER_AGENT'} =~ /\b(?:iPad|TabletPC)\b/)) {
		# TODO: add others when I see some nice user_agents
		$self->{is_tablet} = 1;
	} else {
		$self->{is_tablet} = 0;
	}

	return $self->{is_tablet};
}

=head2 as_string

Converts CGI parameters into a formatted string representation with optional raw mode (no escaping of special characters).
Useful for debugging or generating keys for a cache.

    my $string_representation = $info->as_string();
    my $raw_string = $info->as_string({ raw => 1 });

=head3 API SPECIFICATION

=head4 INPUT

  {
    raw => {
      'type' => 'boolean',
      'optional' => 1,
    }
  }

=head4 OUTPUT

  {
    type => 'string',
    optional => 1,
  }

=cut

sub as_string
{
	my $self = shift;

	my $args = Params::Validate::Strict::validate_strict({
		args => Params::Get::get_params(undef, @_) || {},
		schema => {
			raw => {
				'type' => 'boolean',
				'optional' => 1
			}
		}
	});

	# Retrieve object parameters
	my $params = $self->params() || return '';

	my $rc;

	if($args->{'raw'}) {
		# Raw mode: return key=value pairs without escaping
		$rc = join '; ', map {
			"$_=" . $params->{$_}
		} sort keys %{$params};
	} else {
		# Escaped mode: escape special characters
		$rc = join '; ', map {
			my $value = $params->{$_};

			$value =~ s/\\/\\\\/g;	# Escape backslashes
			$value =~ s/(;|=)/\\$1/g;	# Escape semicolons and equals signs
			"$_=$value"
		} sort keys %{$params};
	}

	$rc ||= '';

	$self->_trace("as_string: returning '$rc'");

	return $rc;
}

=head2 protocol

Returns the connection protocol, presumably 'http' or 'https', or undef if
it can't be determined.

=cut

sub protocol {
	my $self = shift;

	# Cached: ENV is read-only during a CGI request, so the result never changes.
	# Use exists (not defined) so we cache undef for the "unknown" case too.
	# Guard with ref() because protocol() may be called as a class method.
	return $self->{'protocol'} if ref($self) && exists $self->{'protocol'};

	# RFC 3986 §3.1: scheme = ALPHA *( ALPHA / DIGIT / "+" / "-" / "." )
	# Character-class [^:]+ avoids the O(n) backtracking of the former (.+)://
	my $result;
	if($ENV{'SCRIPT_URI'} && ($ENV{'SCRIPT_URI'} =~ /^([a-zA-Z][a-zA-Z0-9+\-.]*):\/\//)) {
		$result = $1;
	} elsif($ENV{'SERVER_PROTOCOL'} && ($ENV{'SERVER_PROTOCOL'} =~ /^HTTP\//)) {
		$result = 'http';
	} elsif(my $port = $ENV{'SERVER_PORT'}) {
		if(defined(my $name = getservbyport($port, 'tcp'))) {
			if($name =~ /^https?$/) {
				$result = $name;
			} elsif($name eq 'www') {
				# e.g. NetBSD and OpenBSD
				$result = 'http';
			}
			# else: unrecognised service name — $result stays undef
		} elsif($port == 80) {
			# e.g. Solaris
			$result = 'http';
		} elsif($port == 443) {
			$result = 'https';
		}
	}

	if(!defined($result) && $ENV{'REMOTE_ADDR'}) {
		$self->_warn("Can't determine the calling protocol");
	}
	$self->{'protocol'} = $result if ref($self);
	return $result;
}

=head2 tmpdir

Returns the name of a directory that you can use to create temporary files
in.

The routine is preferable to L<File::Spec/tmpdir> since CGI programs are
often running on shared servers.  Having said that, tmpdir will fall back
to File::Spec->tmpdir() if it can't find somewhere better.

If the parameter 'default' is given, then use that directory as a
fall-back rather than the value in File::Spec->tmpdir().
No sanity tests are done, so if you give the default value of
'/non-existant', that will be returned.

Tmpdir allows a reference of the options to be passed.

	use CGI::Info;

	my $info = CGI::Info->new();
	my $dir = $info->tmpdir(default => '/var/tmp');
	$dir = $info->tmpdir({ default => '/var/tmp' });

	# or

	my $dir = CGI::Info->tmpdir();
=cut

sub tmpdir {
	my $self = shift;

	my $name = 'tmp';
	if($^O eq 'MSWin32') {
		$name = 'temp';
	}

	my $dir;

	if(!ref($self)) {
		$self = __PACKAGE__->new();
	}
	my $params = Params::Get::get_params(undef, @_);

	if($ENV{'C_DOCUMENT_ROOT'} && (-d $ENV{'C_DOCUMENT_ROOT'})) {
		$dir = File::Spec->catdir($ENV{'C_DOCUMENT_ROOT'}, $name);
		if((-d $dir) && (-w $dir)) {
			return $self->_untaint_filename({ filename => $dir });
		}
		$dir = $ENV{'C_DOCUMENT_ROOT'};
		if((-d $dir) && (-w $dir)) {
			return $self->_untaint_filename({ filename => $dir });
		}
	}
	if($ENV{'DOCUMENT_ROOT'} && (-d $ENV{'DOCUMENT_ROOT'})) {
		$dir = File::Spec->catdir($ENV{'DOCUMENT_ROOT'}, File::Spec->updir(), $name);
		if((-d $dir) && (-w $dir)) {
			return $self->_untaint_filename({ filename => $dir });
		}
	}
	if($params->{'default'} && ref($params->{'default'})) {
		croak(ref($self), ': tmpdir must be given a scalar');
	}
	return $params->{default} ? $params->{default} : File::Spec->tmpdir();
}

# Lexical tidy-up shared by the audit key and the upload directory check:
# decode %XX, collapse repeated slashes and resolve '.' and '..' segments
# without touching the filesystem.  A leading slash is preserved for absolute
# paths; an empty result means the path had no usable segments.  With
# $windows set, backslashes are separators too, and are translated after
# decoding so that an encoded '%5C' cannot hide a traversal from the segment
# resolution.
sub _tidy_path :Protected {
	my ($self, $path, $windows) = @_;

	return unless defined($path);

	# Decoding first means '%2e%2e' is treated like '..' and '%2F' like '/'.
	$path =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/ge;
	$path =~ tr{\\}{/} if($windows);
	$path =~ s{/+}{/}g;

	my $absolute = ($path =~ m{\A/}) ? 1 : 0;
	my @segments;
	foreach my $segment (split(m{/}, $path, -1)) {
		next if(($segment eq '') || ($segment eq '.'));
		if($segment eq '..') {
			pop(@segments);
			next;
		}
		push(@segments, $segment);
	}

	my $normalised = join('/', @segments);
	return $absolute ? "/$normalised" : $normalised;
}

# Canonicalise a path for comparison: resolve '.' and '..' and symlinks when
# the path exists (so '/tmp/../etc' cannot masquerade as '/tmp/...'), then
# apply the lexical tidy-up above.  Decoding there means an encoded spelling of
# a temporary path is judged like its decoded form, and on Windows both
# separator kinds are resolved, including an encoded '%5C'.
sub _temp_path :Protected {
	my $self = shift;
	my $path = shift;

	return unless(defined($path) && length($path));
	if(-d $path) {
		my $real = Cwd::abs_path($path);
		$path = $real if(defined($real) && length($real));
	}
	my $windows = ($^O eq 'MSWin32');
	$path = lc($path) if($windows);

	return $self->_tidy_path($path, $windows);
}

# Windows spellings that cannot be checked by comparing strings.  A
# drive-relative path (C:foo) starts from the per-drive current directory
# rather than from the drive root, so it can point anywhere; and an 8.3 short
# name (PROGRA~1) is an alias for a long name that cannot be expanded without
# asking the filesystem.  Both are refused rather than guessed at, so
# upload_dir is always judged by an unambiguous path.  A tilde that is not
# followed by digits is an ordinary character, not an alias.
sub _win32_path_problem :Protected {
	my ($self, $dir) = @_;

	return unless(defined($dir) && ($^O eq 'MSWin32'));

	my $path = $dir;
	$path =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/ge;
	$path =~ tr{\\}{/};

	# 'C:foo', and a bare 'C:', are relative to the working directory on that
	# drive, unlike 'C:/foo'.
	if($path =~ m{\A[A-Za-z]:(?!/)}) {
		return "is relative to the current directory on its drive";
	}

	foreach my $segment (split(m{/}, $path, -1)) {
		if($segment =~ m{\A[^~]*~\d{1,6}(?:\.[^.]*)?\z}) {
			return "uses the 8.3 short name '$segment'";
		}
	}

	return;
}

# The directories that count as temporary work areas for upload_dir.
# tmpdir() on its own is not enough: a web server normally does not export
# TMPDIR, so a directory that an operator created interactively in the
# platform's own temporary tree (for example /var/folders/... on macOS) would
# not be recognised and every upload would fail with a 500.  The classic
# system temp directories and the TMPDIR/TEMP/TMP overrides are accepted too.
sub _temp_areas :Protected {
	my $self = shift;

	my @areas = ($self->tmpdir(), File::Spec->tmpdir());
	push(@areas, @ENV{qw(TMPDIR TEMP TMP)});
	if($^O eq 'MSWin32') {
		push(@areas, map { File::Spec->catdir($_, 'Temp') } grep { defined($_) } @ENV{qw(SYSTEMROOT WINDIR)});
	} elsif($^O eq 'darwin') {
		# Core Perl has no confstr(_CS_DARWIN_USER_TEMP_DIR), but the whole of
		# /var/folders is the per-user temporary tree.
		push(@areas, '/var/folders', '/private/var/folders');
	} else {
		push(@areas, qw(/tmp /var/tmp /usr/tmp));
	}

	my %seen;
	# The filesystem root is never a temporary area: accepting it would defeat
	# the point of the check.
	return grep { defined($_) && (length($_) > 1) && !$seen{$_}++ }
		map { $self->_temp_path($_) } @areas;
}

# Is $dir a directory inside one of the temporary areas?  Compared on
# canonical paths and on directory boundaries, so '/tmpfoo' is not accepted
# for '/tmp'.  The root of an area is not accepted either: those directories
# are shared and world-writable, while an upload directory should be one the
# operator created for this application.  That applies even when the area is
# itself nested in another one, such as a TMPDIR of /tmp/1234.
sub _in_temp_area :Protected {
	my ($self, $dir) = @_;

	return if($self->_win32_path_problem($dir));

	my $path = $self->_temp_path($dir);
	return unless defined($path);

	my @areas = $self->_temp_areas();
	# An area root is never an upload directory, even when it sits inside
	# another area (a TMPDIR of /tmp/1234, for example).
	foreach my $area (@areas) {
		return if($path eq $area);
	}
	foreach my $area (@areas) {
		return 1 if(index($path, "$area/") == 0);
	}

	return;
}

# The temporary area whose root $dir is, if any.  Used to explain why such a
# directory was rejected rather than calling it "not in a temporary area".
sub _temp_area_root :Protected {
	my ($self, $dir) = @_;

	return if($self->_win32_path_problem($dir));

	my $path = $self->_temp_path($dir);
	return unless defined($path);
	foreach my $area ($self->_temp_areas()) {
		return $area if($path eq $area);
	}

	return;
}

=head2 rootdir

Returns the document root.  This is preferable to looking at DOCUMENT_ROOT
in the environment because it will also work when we're not running as a CGI
script, which is useful for script debugging.

This can be run as a class or object method.

	use CGI::Info;

	print CGI::Info->rootdir();

=cut

sub rootdir {
	if($ENV{'C_DOCUMENT_ROOT'} && (-d $ENV{'C_DOCUMENT_ROOT'})) {
		return $ENV{'C_DOCUMENT_ROOT'};
	} elsif($ENV{'DOCUMENT_ROOT'} && (-d $ENV{'DOCUMENT_ROOT'})) {
		return $ENV{'DOCUMENT_ROOT'};
	}
	# $0 is tainted under -T; untaint with a permissive but defined capture.
	# The leading . before cgi-bin was also a regex bug (matched any char);
	# corrected to match a path separator so the kludge fires only on real paths.
	my ($script_name) = $0 =~ /^(.+)$/;
	return '' unless defined $script_name;

	unless(File::Spec->file_name_is_absolute($script_name)) {
		$script_name = File::Spec->rel2abs($script_name);
	}
	if($script_name =~ /[\/\\]cgi-bin/) {
		$script_name =~ s/[\/\\]cgi-bin.*//;
	}
	if(-f $script_name) {	# More kludge
		if($^O eq 'MSWin32') {
			if($script_name =~ /(.+)\\.+?$/) {
				return $1;
			}
		} else {
			if($script_name =~ /(.+)\/.+?$/) {
				return $1;
			}
		}
	}
	return $script_name;
}

=head2 root_dir

Synonym of rootdir(), for compatibility with L<CHI>.

=cut

sub root_dir
{
	if($_[0] && ref($_[0])) {
		my $self = shift;

		return $self->rootdir(@_);
	}
	return __PACKAGE__->rootdir(@_);
}

=head2 documentroot

Synonym of rootdir(), for compatibility with Apache.

=cut

sub documentroot
{
	if($_[0] && ref($_[0])) {
		my $self = shift;

		return $self->rootdir(@_);
	}
	return __PACKAGE__->rootdir(@_);
}

=head2 logdir($dir)

Gets and sets the name of a directory where you can store logs.

=over 4

=item $dir

Path to the directory where logs will be stored.

=back

=cut

sub logdir {
	my $self = shift;
	my $dir = shift;

	if(!ref($self)) {
		$self = __PACKAGE__->new();
	}

	if($dir) {
		if(length($dir) && (-d $dir) && (-w $dir)) {
			return $self->{'logdir'} = $dir;
		}
		$self->_warn("Invalid logdir: $dir");
		Carp::croak("Invalid logdir: $dir");
	}

	foreach my $rc($self->{logdir}, $ENV{'LOGDIR'}, Sys::Path->logdir(), $self->tmpdir()) {
		if(defined($rc) && length($rc) && (-d $rc) && (-w $rc)) {
			$dir = $rc;
			last;
		}
	}
	$self->_warn("Can't determine logdir") if((!defined($dir)) || (length($dir) == 0));
	$self->{logdir} ||= $dir;

	return $dir;
}

=head2 is_robot

Is the visitor a real person or a robot?

	use CGI::Info;

	my $info = CGI::Info->new();
	unless($info->is_robot()) {
		# update site visitor statistics
	}

If the client is seen to be attempting an SQL injection,
set the HTTP status to 403,
and return 1.

=cut

sub is_robot {
	my $self = shift;

	if(defined($self->{is_robot})) {
		return $self->{is_robot};
	}

	my $agent = $ENV{'HTTP_USER_AGENT'};
	my $remote = $ENV{'REMOTE_ADDR'};

	unless($remote && $agent) {
		# Probably not running in CGI - assume real person
		return 0;
	}

	# SQL injection check MUST run before is_ai(): a WAF block must never be
	# bypassed just because the UA also identifies itself as an AI crawler.
	# See also params() — patterns here MUST stay in sync with those in params().
	# Bounded-lazy .{1,N}? replaces unbounded .+ to prevent O(n²/n³) backtracking
	# on long UAs that contain SQL keywords but not the complete injection sequence.
	# \b word boundaries prevent false positives on tokens like "SELECTFOO".
	if(($agent =~ /\bSELECT\b.{1,500}?\bAND\b/i)         ||
	   ($agent =~ /\bORDER\s+BY\b/i)                      ||
	   ($agent =~ /\bOR\s+NOT\b/i)                        ||
	   ($agent =~ /\bAND\b\s+\d+=\d+/)                    ||
	   ($agent =~ /\bTHEN\b.{1,300}?\bELSE\b.{1,300}?\bEND\b/i) ||
	   ($agent =~ /\bAND\b.{1,500}?\bSELECT\b/i)         ||
	   ($agent =~ /\sAND\s.{1,500}?\sAND\s/)) {
		$self->status(403);
		$self->{is_robot} = 1;
		if($ENV{'REMOTE_ADDR'}) {
			$self->_warn($ENV{'REMOTE_ADDR'} . ": SQL injection attempt blocked for '$agent'");
		} else {
			$self->_warn("SQL injection attempt blocked for '$agent'");
		}
		return 1;
	}

	# is_ai implies is_robot: check AI crawlers before the generic bot regex so
	# that UAs like ChatGPT-User or Google-Extended (no "bot"/"spider" token)
	# are still caught here.
	if($self->is_ai()) {
		return $self->{is_robot} = 1;
	}
	# '.+bot' was replaced with '\bbot\b' — the leading .+ caused catastrophic
	# backtracking on long UAs that contain no 'bot' substring.
	if($agent =~ /\bbot\b|axios\/1\.6\.7|bidswitchbot|bytespider|ClaudeBot|Clickagy\.Intelligence\.Bot|msnptc|CriteoBot|is_archiver|backstreet|fuzz faster|linkfluence\.com|spider|scoutjet|gingersoftware|heritrix|dodnetdotcom|yandex|nutch|ezooms|plukkie|nova\.6scan\.com|Twitterbot|adscanner|Go-http-client|python-requests|Mediatoolkitbot|NetcraftSurveyAgent|Expanse|serpstatbot|DreamHost SiteMonitor|techiaith\.cymru|trendictionbot|ias_crawler|WPsec|Yak\/1\.0|ZoominfoBot/i) {
		$self->{is_robot} = 1;
		return 1;
	}

	# TODO:
	# Download and use list from
	#	https://raw.githubusercontent.com/mitchellkrogza/apache-ultimate-bad-bot-blocker/refs/heads/master/_generator_lists/bad-user-agents.list

	my $key = "$remote/$agent";

	# Check the shared cache BEFORE the referrer scan: the 29-domain referrer
	# check is the most expensive path in is_robot() and is unnecessary when a
	# prior request already classified this remote/agent pair.
	# The SQL injection check above MUST remain before this (security gate).
	if($self->{cache}) {
		if(my $type = $self->{cache}->get($key)) {
			return $self->{is_robot} = ($type eq 'robot');
		}
	}

	if(my $referrer = $ENV{'HTTP_REFERER'}) {
		# $CRAWLER_REFERER_RE is compiled once at module load (see top of file):
		# replaces List::Util::any { /^\Q$_\E/i } @crawler_lists (29 per-call
		# regex compilations + array allocation eliminated).
		$referrer =~ s/\\/_/g;
		if(($referrer =~ /\)/) || ($referrer =~ $CRAWLER_REFERER_RE)) {
			$self->_debug("is_robot: blocked trawler $referrer");
			if($self->{cache}) {
				$self->{cache}->set($key, 'robot', $CACHE_TTL_ROBOT);
			}
			$self->{is_robot} = 1;
			return 1;
		}
	}

	# Don't use HTTP_USER_AGENT to detect more than we really have to since
	# that is easily spoofed
	if($agent =~ /www\.majestic12\.co\.uk|facebookexternal/) {
		# Mark Facebook as a search engine, not a robot
		if($self->{cache}) {
			$self->{cache}->set($key, 'search', $CACHE_TTL_SEARCH);
		}
		return 0;
	}

	unless($self->{browser_detect}) {
		if(eval { require HTTP::BrowserDetect; }) {
			HTTP::BrowserDetect->import();
			$self->{browser_detect} = HTTP::BrowserDetect->new($agent);
		}
	}
	if($self->{browser_detect}) {
		my $is_robot = $self->{browser_detect}->robot();
		if(defined($is_robot)) {
			$self->_debug("HTTP::BrowserDetect '$ENV{HTTP_USER_AGENT}' returns $is_robot");
		}
		$is_robot = (defined($is_robot) && ($is_robot)) ? 1 : 0;
		$self->_debug("is_robot: $is_robot");

		if($is_robot) {
			if($self->{cache}) {
				$self->{cache}->set($key, 'robot', $CACHE_TTL_ROBOT);
			}
			$self->{is_robot} = $is_robot;
			return $is_robot;
		}
	}

	if($self->{cache}) {
		$self->{cache}->set($key, 'unknown', $CACHE_TTL_ROBOT);
	}
	$self->{is_robot} = 0;
	return 0;
}

=head2 is_search_engine

Is the visitor a search engine?

    if(CGI::Info->new()->is_search_engine()) {
	# display generic information about yourself
    } else {
	# allow the user to pick and choose something to display
    }

Can be overridden by the IS_SEARCH_ENGINE environment setting

=cut

sub is_search_engine
{
	my $self = shift;

	if(defined($self->{is_search_engine})) {
		return $self->{is_search_engine};
	}

	if($ENV{'IS_SEARCH_ENGINE'}) {
		return $ENV{'IS_SEARCH_ENGINE'}
	}

	my $remote = $ENV{'REMOTE_ADDR'};
	my $agent = $ENV{'HTTP_USER_AGENT'};

	unless($remote && $agent) {
		# Probably not running in CGI - assume not a search engine
		return 0;
	}

	# Build the cache key once; reuse $key for every subsequent set() call.
	my $key = "$remote/$agent";

	if($self->{cache}) {
		if(my $type = $self->{cache}->get($key)) {
			# Write to is_search_engine (not the old is_search typo) so the
			# instance-level guard at the top of this method actually fires on
			# the next call, avoiding a redundant shared-cache round-trip.
			return $self->{is_search_engine} = ($type eq 'search');
		}
	}

	# Don't use HTTP_USER_AGENT to detect more than we really have to since
	# that is easily spoofed
	if($agent =~ /www\.majestic12\.co\.uk|facebookexternal/) {
		# Mark Facebook as a search engine, not a robot
		if($self->{cache}) {
			$self->{cache}->set($key, 'search', $CACHE_TTL_SEARCH);
		}
		return 1;
	}

	unless($self->{browser_detect}) {
		if(eval { require HTTP::BrowserDetect; }) {
			HTTP::BrowserDetect->import();
			$self->{browser_detect} = HTTP::BrowserDetect->new($agent);
		}
	}
	if(my $browser = $self->{browser_detect}) {
		my $is_search = ($browser->google() || $browser->msn() || $browser->baidu() || $browser->altavista() || $browser->yahoo() || $browser->bingbot());
		if(!$is_search) {
			if(($agent =~ /SeznamBot\//) ||
			   ($agent =~ /Google-InspectionTool\//) ||
			   ($agent =~ /Googlebot\//)) {
				$is_search = 1;
			}
		}
		if($is_search && $self->{cache}) {
			$self->{cache}->set($key, 'search', $CACHE_TTL_SEARCH);
		}
		return $self->{is_search_engine} = $is_search;
	}

	# Untaint $remote before passing to inet_aton: under -T, tainted data
	# causes a fatal "Insecure dependency" in inet_aton.  The strict IPv4
	# regex also rejects any non-address garbage that could reach this path.
	my ($safe_remote) = $remote =~ /^(\d{1,3}(?:\.\d{1,3}){3})$/;
	unless(defined $safe_remote) {
		$self->{is_search_engine} = 0;
		return 0;
	}
	# TODO: DNS lookup, not gethostbyaddr - though that will be slow
	my $hostname = gethostbyaddr(inet_aton($safe_remote), AF_INET) || $safe_remote;

	my @cidr_blocks = ('47.235.0.0/12');	# Alibaba

	# \b word boundaries prevent false positives like "notgoogle.example.com".
	# /i because DNS hostnames are case-insensitive.
	if((defined($hostname) && ($hostname =~ /\b(?:google|msnbot|bingbot|amazonbot|GPTBot)\b/i) && ($hostname !~ /^google-proxy/i)) ||
	   (Net::CIDR::cidrlookup($remote, @cidr_blocks))) {
		if($self->{cache}) {
			$self->{cache}->set($key, 'search', $CACHE_TTL_SEARCH);
		}
		$self->{is_search_engine} = 1;
		return 1;
	}

	$self->{is_search_engine} = 0;
	return 0;
}

=head2 is_ai

Returns a boolean indicating whether the visitor is a known AI training or
inference crawler (e.g. GPTBot, ClaudeBot, PerplexityBot).

Use this to withhold training data, serve an opt-out notice, or log AI traffic
separately from regular robot traffic.

B<Invariant>: when C<is_ai()> returns true, C<is_robot()> also returns true,
regardless of the order in which the two methods are called.

Can be overridden by the C<IS_AI> environment variable.

=head3 EXAMPLE

    use CGI::Info;

    my $info = CGI::Info->new();
    if ($info->is_ai()) {
        # Decline to serve training data to AI scrapers
        print "Status: 403 Forbidden\r\n\r\n";
        exit;
    }

    # Route AI crawlers to a lightweight page instead of blocking them
    if ($info->is_ai()) {
        serve_ai_summary();
    } else {
        serve_full_page();
    }

=head3 API SPECIFICATION

=head4 Input

No arguments beyond the implicit object reference (C<$self>).

    # Params::Validate::Strict schema -- no parameters
    {}

=head4 Output

    # Return::Set schema
    {
        type    => SCALAR,
        values  => [ 0, 1 ],
    }

Returns C<1> if the visiting client is identified as an AI training or
inference crawler; C<0> otherwise.

=head3 MESSAGES

This method produces no log messages of its own.  Upstream callers such as
C<is_robot()> may emit WAF warnings; see L</is_robot> for that table.

=head3 PSEUDOCODE

    function is_ai(self):
        if self.{is_ai} is defined:
            return self.{is_ai}                    # instance-level cache

        if IS_AI environment variable is set:
            return self.{is_ai} = IS_AI ? 1 : 0   # override; no robot sync needed
                                                   # because is_robot() calls is_ai()

        ua     = HTTP_USER_AGENT
        remote = REMOTE_ADDR

        if not (remote and ua):
            return 0                               # not a CGI request; assume human

        if ua matches any AI_PAT token (case-insensitive):
            self.{is_robot} = 1                    # enforce is_ai => is_robot
            return self.{is_ai} = 1

        return self.{is_ai} = 0

=cut

sub is_ai {
	my $self = shift;

	# Return cached result if already determined
	if(defined($self->{is_ai})) {
		return $self->{is_ai};
	}

	# Allow environment variable override for testing or manual classification
	if(defined(my $override = $ENV{'IS_AI'})) {
		return $self->{is_ai} = $override ? 1 : 0;
	}

	my $agent = $ENV{'HTTP_USER_AGENT'};
	my $remote = $ENV{'REMOTE_ADDR'};

	unless($remote && $agent) {
		# Probably not running in CGI - assume not an AI crawler
		return 0;
	}

	# Known AI training and inference crawlers, matched against the User-Agent.
	# We intentionally do not consult the shared IP/agent cache here: is_robot()
	# stores 'robot' for many of the same UAs, and reading 'robot' != 'ai' would
	# produce a false negative.  Instance-level caching ($self->{is_ai}) above is
	# sufficient to avoid redundant regex evaluation within a single request.
	# Sources: vendor documentation and public bot lists.
	# Anthropic: ClaudeBot, Claude-Web, anthropic-ai
	# OpenAI: GPTBot, ChatGPT-User, OAI-SearchBot
	# Google: Google-Extended (AI training opt-out token)
	# Meta: meta-externalagent, FacebookBot (AI training)
	# Apple: Applebot-Extended (AI training subset)
	# Perplexity: PerplexityBot
	# Amazon: Amazonbot (Amazon AI / Alexa AI)
	# You.com: YouBot
	# Diffbot: Diffbot
	# Cohere: cohere-ai
	# Common Crawl: CCBot (primary data source for many LLM trainers)
	# ByteDance: Bytespider (TikTok / AI training)
	# Allen AI: AI2Bot
	# Timpi: TimpiBot
	if($agent =~ /ClaudeBot|Claude-Web|anthropic-ai|GPTBot|ChatGPT-User|OAI-SearchBot|Google-Extended|meta-externalagent|FacebookBot|Applebot-Extended|PerplexityBot|Amazonbot|YouBot|Diffbot|cohere-ai|CCBot|Bytespider|AI2Bot|TimpiBot/i) {
		# Enforce is_ai => is_robot so callers need not check both
		$self->{is_robot} = 1;
		return $self->{is_ai} = 1;
	}

	$self->{is_ai} = 0;
	return 0;
}

=head2 browser_type

Returns a string classifying the visitor's client.  The possible values are:

=over 4

=item * C<'mobile'> -- smartphone or tablet (checked first)

=item * C<'ai'> -- known AI training or inference crawler (see L</is_ai>)

=item * C<'search'> -- search-engine crawler

=item * C<'robot'> -- other automated client

=item * C<'web'> -- ordinary desktop or laptop browser

=back

    use Carp;
    use Template;
    use CGI::Info;

    my $info = CGI::Info->new();
    my $dir  = $info->rootdir() . '/templates/' . $info->browser_type();

    my $filename = ref($info);
    $filename =~ s/::/\//g;
    $filename = "$dir/$filename.tmpl";

    (-f $filename && -r $filename)
        or croak "Cannot open template '$filename'";

    my $template = Template->new();
    $template->process($filename, {}) or croak $template->error();

=cut

sub browser_type {
	my $self = shift;

	if($self->is_mobile()) {
		return 'mobile';
	}
	if($self->is_ai()) {
		return 'ai';
	}
	if($self->is_search_engine()) {
		return 'search';
	}
	if($self->is_robot()) {
		return 'robot';
	}
	return 'web';
}

=head2 get_cookie

Returns a cookie's value, or undef if no name is given, or the requested
cookie isn't in the jar.

Deprecated - use cookie() instead.

    use CGI::Info;

    my $i = CGI::Info->new();
    my $name = $i->get_cookie(cookie_name => 'name');
    print "Your name is $name\n";
    my $address = $i->get_cookie('address');
    print "Your address is $address\n";

=cut

sub get_cookie {
	my $self = shift;

	return $self->cookie(\@_);
}

=head2 cookie

Returns a cookie's value, or undef if no name is given, or the requested
cookie isn't in the jar.
API is the same as "param",
it will replace the "get_cookie" method in the future.

    use CGI::Info;

    my $name = CGI::Info->new()->cookie('name');
    print "Your name is $name\n";


=head3 API SPECIFICATION

=head4 INPUT

  {
    cookie_name => {
      'type' => 'string',
      'min' => 1,
      'matches' => qr/^[!#-'*+\-.\^_`|~0-9A-Za-z]+$/	# RFC6265
    }
  }

=head4 OUTPUT

Cookie not set: C<undef>

Cookie set:

  {
    type => 'string',
    optional => 1,
    matches => qr/	# RFC6265
      ^
      (?:
        "[\x21\x23-\x2B\x2D-\x3A\x3C-\x5B\x5D-\x7E]*"   # quoted
      | [\x21\x23-\x2B\x2D-\x3A\x3C-\x5B\x5D-\x7E]*     # unquoted
      )
      $
    /x
  }

=cut

sub cookie
{
	my $self = shift;
	my $params = Params::Validate::Strict::validate_strict({
		args => Params::Get::get_params('cookie_name', @_),
		schema => {
			cookie_name => {
				'type' => 'string',
				'min' => 1,
				'matches' => qr/^[!#-'*+\-.\^_`|~0-9A-Za-z]+$/	# RFC6265
			}
		}
	});

	my $field = $params->{'cookie_name'};

	# TODO: Unreachable code detected during path analysis. Investigate for removal.
	# validate_strict() above enforces type=>string, min=>1 and croaks for undef/ref
	# inputs before control ever reaches these two guards.
	if(!defined($field)) {
		$self->_error('what cookie do you want?');
		Carp::croak('what cookie do you want?');
		return;	# TODO: Unreachable code detected during path analysis. Investigate for removal.
	}
	if(ref($field)) {
		$self->_error('Cookie name should be a string');
		Carp::croak('Cookie name should be a string');
		return;	# TODO: Unreachable code detected during path analysis. Investigate for removal.
	}

	# Load cookies if not already loaded
	unless($self->{jar}) {
		if(defined $ENV{'HTTP_COOKIE'}) {
			# Truncate at the first CR or LF before parsing.
			# HTTP header values cannot span lines; anything after a newline is
			# injected content (e.g. "session=abc\r\nSet-Cookie: admin=1").
			# Stripping rather than truncating would leave the injected text
			# concatenated onto a legitimate value, so we discard from \r/\n onward.
			(my $raw_cookie = $ENV{'HTTP_COOKIE'}) =~ s/[\r\n].*$//s;

			# grep { /=/ } filters out malformed tokens (empty strings, bare
			# semicolons, entries with no name=value separator) that would
			# otherwise cause split(/=/, $_, 2) to return a single-element list
			# and make the flattened list odd-length, corrupting the hash.
			$self->{jar} = {
				map  { split(/=/, $_, 2) }
				grep { /=/ }
				split(/; /, $raw_cookie)
			};
		}
	}

	# Return the cookie value if it exists, otherwise return undef
	return $self->{jar}{$field};
}

=head2 status($status)

Sets or returns the status of the object,
200 for OK,
otherwise an HTTP error code

=over 4

=item $status

Optional integer value to be set or retrieved.
If omitted, the value is retrieved.

=back

=cut

sub status
{
	my $self = shift;
	my $status = shift;

	# Set status if provided
	return $self->{status} = $status if(defined($status));

	# Determine status based on request method if status is not set
	unless (defined $self->{status}) {
		my $method = $ENV{'REQUEST_METHOD'};

		return 405 if $method && ($method eq 'OPTIONS' || $method eq 'DELETE');
		return 411 if $method && ($method eq 'POST' && !defined $ENV{'CONTENT_LENGTH'});

		return 200;
	}

	# Return current status or 200 by default
	return $self->{status} || 200;
}

=head2 messages

Returns the messages that the object has generated as a ref to an array of hashes.

    my @messages;
    if(my $w = $info->messages()) {
        @messages = map { $_->{'message'} } @{$w};
    } else {
        @messages = ();
    }
    print STDERR join(';', @messages), "\n";

=cut

sub messages
{
	my $self = shift;

	return $self->{'messages'};
}

=head2	messages_as_string

Returns the messages of that the object has generated as a string.

=cut

sub messages_as_string
{
	my $self = shift;

	if(scalar($self->{'messages'})) {
		my @messages = map { $_->{'message'} } @{$self->{'messages'}};
		return join('; ', @messages);
	}
	return '';
}

=head2 cache($cache)

Get/set the internal cache system.

Use this rather than pass the cache argument to C<new()> if you see these error messages,
"(in cleanup) Failed to get MD5_CTX pointer".
It's some obscure problem that I can't work out,
but calling this after C<new()> works.

=over 4

=item $cache

Optional cache object.
When not given,
returns the current cache object.

=back

=cut

sub cache
{
	my $self = shift;
	my $cache = shift;

	if($cache) {
		croak(ref($self), ':cache($cache) is not an object') if(!Scalar::Util::blessed($cache));
		croak(ref($self), ':cache($cache) does not support the get() method') if(!$cache->can('get'));
		croak(ref($self), ':cache($cache) does not support the set() method') if(!$cache->can('set'));
		$self->{'cache'} = $cache;
	}
	return $self->{'cache'};
}

=head2 set_logger

Sets the class, array, code reference, or file that will be used for logging.

Sometimes you don't know what the logger is until you've instantiated the class.
This function fixes the catch-22 situation.

=cut

sub set_logger
{
	my $self = shift;
	my $params = Params::Get::get_params('logger', @_);

	if(my $logger = $params->{'logger'}) {
		if(Scalar::Util::blessed($logger)) {
			$self->{'logger'} = $logger;
		} else {
			$self->{'logger'} = Log::Abstraction->new($logger);
		}
	} else {
		$self->{'logger'} = Log::Abstraction->new();
	}
	return $self;
}

# Log and remember a message
sub _log :Protected {
	my ($self, $level, @messages) = @_;

	# Filter once; reuse for both the in-memory store and the logger call.
	# The former inner scalar(@messages) guard was always true inside this block.
	my @defined_msgs = grep { defined } @messages;
	return unless @defined_msgs;

	# Note: consider adding caller's function name to log messages in a future release
	push @{$self->{'messages'}}, { level => $level, message => join(' ', @defined_msgs) };

	if(my $logger = $self->{'logger'}) {
		$logger->$level(join('', @defined_msgs));
	}
}

sub _debug :Protected {
	my $self = shift;
	$self->_log('debug', @_);
}

sub _info :Protected {
	my $self = shift;
	$self->_log('info', @_);
}

sub _notice :Protected {
	my $self = shift;
	$self->_log('notice', @_);
}

sub _trace :Protected {
	my $self = shift;
	$self->_log('trace', @_);
}

# Emit a warning message somewhere
sub _warn :Protected {
	my $self = shift;
	my $params = Params::Get::get_params('warning', @_);

	$self->_log('warn', $params->{'warning'});
	if(!defined($self->{'logger'})) {
		Carp::carp($params->{'warning'});
	}
}

# Emit an error message somewhere
sub _error :Protected {
	my $self = shift;
	my $params = Params::Get::get_params('warning', @_);

	$self->_log('error', $params->{'warning'});
	if(!defined($self->{'logger'})) {
		Carp::croak($params->{'warning'});
	}
}

# Ensure all environment variables are sanitized and validated before use.
# Use regular expressions to enforce strict input formats.
sub _get_env :Protected {
	my ($self, $var) = @_;

	return unless defined $ENV{$var};

	# Strict sanitization: allow alphanumeric and limited special characters
	if($ENV{$var} =~ /^[\w\.\-\/:\\]+$/) {
		return $ENV{$var};
	}
	$self->_warn("Invalid value in environment variable: $var");

	return;
}

=head2 reset

Class method to reset the class.
You should do this in an FCGI environment before instantiating,
but nowhere else.

=cut

sub reset {
	my $class = shift;

	unless($class eq __PACKAGE__) {
		carp('Reset is a class method');
		return;
	}

	$stdin_data = undef;
}

sub AUTOLOAD
{
	our $AUTOLOAD;

	my $self = shift or return;

	return if(!defined($AUTOLOAD));

	# Extract the method name from the AUTOLOAD variable
	my ($method) = $AUTOLOAD =~ /::(\w+)$/;

	# Skip if called on destruction
	return if($method eq 'DESTROY');

	Carp::croak(__PACKAGE__, ": Unknown method $method") if(!ref($self));

	# Allow the AUTOLOAD feature to be disabled
	Carp::croak(__PACKAGE__, ": Unknown method $method") if(exists($self->{'auto_load'}) && boolean($self->{'auto_load'})->isFalse());

	# Ensure the method is called on the correct package object or a subclass
	return unless((ref($self) eq __PACKAGE__) || (UNIVERSAL::isa((caller)[0], __PACKAGE__)));

	# TODO: Unreachable code detected during path analysis. Investigate for removal.
	# $method is captured via /::(\w+)$/ which only yields \w+ chars; a digit-leading
	# name is possible in theory but Perl's method dispatch never generates one.
	Carp::croak(__PACKAGE__, ": Invalid method name: $method") unless $method =~ /^[a-zA-Z_][a-zA-Z0-9_]*$/;

	# Delegate to the param method
	return $self->param($method);
}

=head1 BUGS

is_tablet() only currently detects the iPad and Windows PCs. Android strings
don't differ between tablets and smartphones.

params() returns a ref which means that calling routines can change the hash
for other routines.
Take a local copy before making amendments to the table if you don't want unexpected
things to happen.

=head1 SEE ALSO

=over 4

=item * L<Configure an Object at Runtime|Object::Configure>

=item * L<Test Dashboard|https://nigelhorne.github.io/CGI-Info/coverage/>

=item * L<HTTP::BrowserDetect>

=item * L<https://github.com/mitchellkrogza/apache-ultimate-bad-bot-blocker>

=back

=head1 REPOSITORY

L<https://github.com/nigelhorne/CGI-Info>

=head1 SUPPORT

This module is provided as-is without any warranty.

Please report any bugs or feature requests to C<bug-cgi-info at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CGI-Info>.
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

You can find documentation for this module with the perldoc command.

    perldoc CGI::Info

You can also look for information at:

=over 4

=item * MetaCPAN

L<https://metacpan.org/dist/CGI-Info>

=item * RT: CPAN's request tracker

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=CGI-Info>

=item * CPAN Testers' Matrix

L<http://matrix.cpantesters.org/?dist=CGI-Info>

=item * CPAN Testers Dependencies

L<http://deps.cpantesters.org/?module=CGI::Info>

=back

=encoding utf-8

=head2 FORMAL SPECIFICATION

=head3 new

  -- CGI::Info construction
  new : ClassName x Params --> CGIInfo

  -- Normal (non-clone) path
  new(class, params) ^=
    let configured == Object::Configure::configure(class, params)
    in  CGIInfo {
          max_upload_size |-> configured.max_upload_size ?? MAX_UPLOAD_SIZE_DEFAULT,
          allow           |-> configured.allow ?? null,
          upload_dir      |-> configured.upload_dir ?? null,
          ...configured
        }

  -- Pre-conditions
  pre new(class, params) ^=
    params.logger = null
    v (blessed(params.logger)
       ^ params.logger.can('warn')
       ^ params.logger.can('info')
       ^ params.logger.can('error'))
    ^ params.expect = null

  -- Clone path (invocant is an existing object)
  clone : CGIInfo x Params --> CGIInfo
  clone(self, params) ^=
    let merged == (self (+) params) \ {paramref}
    in  CGIInfo { ...merged }

=head3 param

Let F be the set of all possible CGI field names, V be the set of all
possible (sanitised) scalar values, and allow : F -> Regex | undef be the
current allow-list schema (undef means all fields are permitted).

  param : F? -> V | HashRef | undef

  param() =  params()

  param(f) =
    f not in dom(allow) /\ allow /= undef =>  warn; undef
    f in params()                          =>  params()(f)
    otherwise                              =>  undef

Safety invariant: for all f, param(f) /= undef => f in dom(allow) \/ allow = undef.

=head2 is_ai

    -- is_ai ---------------------------------------------------------
    -- Given CGIInfo state i, returns a boolean result.
    --
    -- AI_PAT is the set of known AI crawler token strings.
    --
    -- ENV denotes the process environment (a partial function from
    -- name to value).
    --
    AI_PAT == {ClaudeBot, Claude-Web, anthropic-ai, GPTBot,
               ChatGPT-User, OAI-SearchBot, Google-Extended,
               meta-externalagent, FacebookBot, Applebot-Extended,
               PerplexityBot, Amazonbot, YouBot, Diffbot,
               cohere-ai, CCBot, Bytespider, AI2Bot, TimpiBot}

    is_ai ≜ λ i : CGIInfo •
      -- Environment override takes absolute priority
      IS_AI ∈ dom ENV ⟹
          (ENV IS_AI ≠ '0' ∧ ENV IS_AI ≠ '')

      -- Without both IP and UA we cannot classify
    ∧ IS_AI ∉ dom ENV ∧
      (REMOTE_ADDR ∉ dom ENV ∨ HTTP_USER_AGENT ∉ dom ENV)
          ⟹ false

      -- UA-pattern match (case-insensitive substring)
    ∧ IS_AI ∉ dom ENV ∧
      REMOTE_ADDR ∈ dom ENV ∧ HTTP_USER_AGENT ∈ dom ENV
          ⟹ (∃ p : AI_PAT • p ⊑ᵢ ENV HTTP_USER_AGENT)

      -- Invariant: is_ai ⟹ is_robot
    ∧ is_ai i = true ⟹ is_robot i = true
    -- ---------------------------------------------------------------

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright 2010-2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.

=cut

1;
