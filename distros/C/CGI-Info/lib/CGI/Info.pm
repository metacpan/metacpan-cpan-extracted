package CGI::Info;

# TODO: remove the expect argument
# TODO:	look into params::check or params::validate

use warnings;
use strict;

use boolean;
use Carp;
use Object::Configure 0.10;
use File::Spec;
use Log::Abstraction 0.10;
use Params::Get;
use Params::Validate::Strict;
use Net::CIDR;
use Scalar::Util;
use Socket;	# For AF_INET
use 5.008;
use Log::Any qw($log);
# use Cwd;
# use JSON::Parse;
use List::Util ();	# Can go when expect goes
# use Sub::Private;
use Sys::Path;

use namespace::clean;

sub _sanitise_input($);

=head1 NAME

CGI::Info - Information about the CGI environment

=head1 VERSION

Version 1.05

=cut

our $VERSION = '1.05';

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

It takes four optional arguments: allow, logger, expect and upload_dir,
which are documented in the params() method.

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

=item * C<max_upload_size>

The maximum file size you can upload (-1 for no limit), the default is 512MB.

=back

=cut

our $stdin_data;	# Class variable storing STDIN in case the class
			# is instantiated more than once

sub new
{
	my $class = shift;

	# Handle hash or hashref arguments
	my $params = Params::Get::get_params(undef, @_) || {};

	if(!defined($class)) {
		if((scalar keys %{$params}) > 0) {
			# Using CGI::Info:new(), not CGI::Info->new()
			croak(__PACKAGE__, ' use ->new() not ::new() to instantiate');
		}

		# FIXME: this only works when no arguments are given
		$class = __PACKAGE__;
	} elsif(Scalar::Util::blessed($class)) {
		# If $class is an object, clone it with new arguments
		return bless { %{$class}, %{$params} }, ref($class);
	}

	# Load the configuration from a config file, if provided
	$params = Object::Configure::configure($class, $params);

	if(defined($params->{'expect'})) {
		# if(ref($params->{expect}) ne 'ARRAY') {
			# Carp::croak(__PACKAGE__, ': expect must be a reference to an array');
		# }
		# # warn __PACKAGE__, ': expect is deprecated, use allow instead';
		Carp::croak("$class: expect has been deprecated, use allow instead");
	}

	# Return the blessed object
	return bless {
		max_upload_size => 512 * 1024,
		allow => undef,
		upload_dir => undef,
		%{$params}	# Overwrite defaults with given arguments
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

=cut

sub script_name
{
	my $self = shift;

	unless($self->{script_name}) {
		$self->_find_paths();
	}
	return $self->{script_name};
}

sub _find_paths {
	my $self = shift;

	if(!UNIVERSAL::isa((caller)[0], __PACKAGE__)) {
		Carp::croak('Illegal Operation: This method can only be called by a subclass or ourself');
	}

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

sub _find_site_details
{
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
		$self->{cgi_site} =~ s/(.*)\.+$/$1/;  # Trim trailing dots

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

CGI::Info helps you to test your script prior to deployment on a website:
if it is not in a CGI environment (e.g. the script is being tested from the
command line), the program's command line arguments (a list of key=value pairs)
are used, if there are no command line arguments then they are read from stdin
as a list of key=value lines.
Also you can give one of --tablet, --search-engine,
--mobile and --robot to mimic those agents. For example:

	./script.cgi --mobile name=Nigel

Returns undef if the parameters can't be determined or if none were given.

If an argument is given twice or more, then the values are put in a comma
separated string.

The returned hash value can be passed into L<CGI::Untaint>.

Takes four optional parameters: allow, logger and upload_dir.
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
It must be a writeable directory in the temporary area.

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

If the request is an XML request (i.e. the content type of the POST is text/xml),
CGI::Info will put the request into the params element 'XML', thus:

	use CGI::Info;
	# ...
	my $info = CGI::Info->new();
	my $paramsref = $info->params();	# See BUGS below
	my $xml = $$paramsref{'XML'};
	# ... parse and process the XML request in $xml

Carp if logger is not set and we detect something serious.

Blocks some attacks,
such as SQL and XSS injections,
mustleak and directory traversals,
thus creating a primitive web application firewall (WAF).
Warning - this is an extra layer, not a replacement for your other security layers.

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

sub params {
	my $self = shift;

	my $params = Params::Get::get_params(undef, @_);

	if((defined($self->{paramref})) && ((!defined($params->{'allow'})) || defined($self->{allow}) && ($params->{'allow'} eq $self->{allow}))) {
		return $self->{paramref};
	}

	if(defined($params->{allow})) {
		$self->{allow} = $params->{allow};
	}
	# if(defined($params->{expect})) {
		# if(ref($params->{expect}) eq 'ARRAY') {
			# $self->{expect} = $params->{expect};
			# $self->_warn('expect is deprecated, use allow instead');
		# } else {
			# $self->_warn('expect must be a reference to an array');
		# }
	# }
	if(defined($params->{upload_dir})) {
		$self->{upload_dir} = $params->{upload_dir};
	}
	if(defined($params->{'logger'})) {
		$self->set_logger($params->{'logger'});
	}
	$self->_trace('Entering params');

	my @pairs;
	my $content_type = $ENV{'CONTENT_TYPE'};
	my %FORM;

	use IO::Interactive;

	if((!$ENV{'GATEWAY_INTERFACE'}) || (!$ENV{'REQUEST_METHOD'})) {
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
			@pairs = split(/\n/, $stdin_data);
		} elsif(IO::Interactive::is_interactive() && !$self->{args_read}) {
			my $oldfh = select(STDOUT);
			print "Entering debug mode\n",
				"Enter key=value pairs - end with quit\n";
			select($oldfh);

			# Avoid prompting for the arguments more than once
			# if just 'quit' is entered
			$self->{args_read} = 1;

			while(<STDIN>) {
				chop(my $line = $_);
				$line =~ s/[\r\n]//g;
				last if $line eq 'quit';
				push(@pairs, $line);
				$stdin_data .= "$line\n";
			}
		}
	} elsif(($ENV{'REQUEST_METHOD'} eq 'GET') || ($ENV{'REQUEST_METHOD'} eq 'HEAD')) {
		if(my $query = $ENV{'QUERY_STRING'}) {
			if((defined($content_type)) && ($content_type =~ /multipart\/form-data/i)) {
				$self->_warn('Multipart/form-data not supported for GET');
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
		if(($self->{max_upload_size} >= 0) && ($content_length > $self->{max_upload_size})) {	# Set maximum posts
			# TODO: Design a way to tell the caller to send HTTP
			# status 413
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
				$self->_warn({
					warning => 'Attempt to upload a file when upload_dir has not been set'
				});
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
				$self->_warn({
					warning => "upload_dir $self->{upload_dir} isn't writeable"
				});
				$self->status(500);
				delete $self->{upload_dir};
				return;
			}
			my $tmpdir = $self->tmpdir();
			if($self->{'upload_dir'} !~ /^\Q$tmpdir\E/) {
				$self->_warn({
					warning => 'upload_dir ' . $self->{'upload_dir'} . " isn't somewhere in the temporary area $tmpdir"
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
			}
		} elsif($content_type =~ /text\/xml/i) {
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

			$FORM{XML} = $buffer;

			$self->{paramref} = \%FORM;

			return \%FORM;
		} elsif($content_type =~ /application\/json/i) {
			my $buffer;
			if($stdin_data) {
				$buffer = $stdin_data;
			} else {
				require JSON::MaybeXS && JSON::MaybeXS->import() unless JSON::MaybeXS->can('parse_json');
				# require JSON::MaybeXS;
				# JSON::MaybeXS->import();

				if(read(STDIN, $buffer, $content_length) != $content_length) {
					$self->_warn({
						warning => 'read failed: something else may have read STDIN'
					});
				}
				$stdin_data = $buffer;
				# JSON::Parse::assert_valid_json($buffer);
				# my $paramref = JSON::Parse::parse_json($buffer);
				my $paramref = decode_json($buffer);
				foreach my $key(keys(%{$paramref})) {
					push @pairs, "$key=" . $paramref->{$key};
				}
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
			warning => 'Use POST, GET or HEAD'
		});
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

		$key =~ s/%00//g;	# Strip NUL byte poison
		$key =~ s/%([a-fA-F\d][a-fA-F\d])/pack("C", hex($1))/eg;
		$key =~ tr/+/ /;
		if(defined($value)) {
			$value =~ s/%00//g;	# Strip NUL byte poison
			$value =~ s/%([a-fA-F\d][a-fA-F\d])/pack("C", hex($1))/eg;
			$value =~ tr/+/ /;
		} else {
			$value = '';
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
							unknown_parameter_handler => 'warn',
						});
					};
					if($@) {
						$self->_info("Block $key = $value: $@");
						$self->status(422);
						next;	# Skip to the next parameter
					}
					$value = $value->{$key};
				}
			}
		}

		# if($self->{expect} && (List::Util::none { $_ eq $key } @{$self->{expect}})) {
			# next;
		# }
		my $orig_value = $value;
		$value = _sanitise_input($value);

		if((!defined($ENV{'REQUEST_METHOD'})) || ($ENV{'REQUEST_METHOD'} eq 'GET')) {
			# From http://www.symantec.com/connect/articles/detection-sql-injection-and-cross-site-scripting-attacks
			# Facebook FBCLID can have "--"
			# if(($value =~ /(\%27)|(\')|(\-\-)|(\%23)|(\#)/ix) ||
			if(($value =~ /(\%27)|(\')|(\%23)|(\#)/ix) ||
			   ($value =~ /((\%3D)|(=))[^\n]*((\%27)|(\')|(\-\-)|(\%3B)|(;))/i) ||
			   ($value =~ /\w*((\%27)|(\'))((\%6F)|o|(\%4F))((\%72)|r|(\%52))/ix) ||
			   ($value =~ /((\%27)|(\'))union/ix) ||
			   ($value =~ /select[[a-z]\s\*]from/ix) ||
			   ($value =~ /\sAND\s1=1/ix) ||
			   ($value =~ /\sOR\s.+\sAND\s/) ||
			   ($value =~ /\/\*\*\/ORDER\/\*\*\/BY\/\*\*/ix) ||
			   ($value =~ /\/AND\/.+\(SELECT\//) ||	# United/**/States)/**/AND/**/(SELECT/**/6734/**/FROM/**/(SELECT(SLEEP(5)))lRNi)/**/AND/**/(8984=8984
			   ($value =~ /exec(\s|\+)+(s|x)p\w+/ix)) {
				$self->status(403);
				if($ENV{'REMOTE_ADDR'}) {
					$self->_warn($ENV{'REMOTE_ADDR'} . ": SQL injection attempt blocked for '$value'");
				} else {
					$self->_warn("SQL injection attempt blocked for '$value'");
				}
				return;
			}
			if(my $agent = $ENV{'HTTP_USER_AGENT'}) {
				if(($agent =~ /SELECT.+AND.+/) || ($agent =~ /ORDER BY /) || ($agent =~ / OR NOT /) || ($agent =~ / AND \d+=\d+/) || ($agent =~ /THEN.+ELSE.+END/) || ($agent =~ /.+AND.+SELECT.+/) || ($agent =~ /\sAND\s.+\sAND\s/)) {
					$self->status(403);
					if($ENV{'REMOTE_ADDR'}) {
						$self->_warn($ENV{'REMOTE_ADDR'} . ": SQL injection attempt blocked for '$agent'");
					} else {
						$self->_warn("SQL injection attempt blocked for '$agent'");
					}
					return 1;
				}
			}
			if(($value =~ /((\%3C)|<)((\%2F)|\/)*[a-z0-9\%]+((\%3E)|>)/ix) ||
			   ($value =~ /((\%3C)|<)[^\n]+((\%3E)|>)/i) ||
			   ($orig_value =~ /((\%3C)|<)((\%2F)|\/)*[a-z0-9\%]+((\%3E)|>)/ix) ||
			   ($orig_value =~ /((\%3C)|<)[^\n]+((\%3E)|>)/i)) {
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

	return \%FORM;
}

=head2 param

Get a single parameter from the query string.
Takes an optional single string parameter which is the argument to return. If
that parameter is not given param() is a wrapper to params() with no arguments.

	use CGI::Info;
	# ...
	my $info = CGI::Info->new();
	my $bar = $info->param('foo');

If the requested parameter isn't in the allowed list, an error message will
be thrown:

	use CGI::Info;
	my $allowed = {
		foo => qr/\d+/
	};
	my $xyzzy = $info->params(allow => $allowed);
	my $bar = $info->param('bar');  # Gives an error message

Returns undef if the requested parameter was not given

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
		return $params->{$field};
	}
}

sub _sanitise_input($) {
	my $arg = shift;

	# Remove hacking attempts and spaces
	$arg =~ s/[\r\n]//g;
	$arg =~ s/\s+$//;
	$arg =~ s/^\s//;

	$arg =~ s/<!--.*-->//g;
	# Allow :
	# $arg =~ s/[;<>\*|`&\$!?#\(\)\[\]\{\}'"\\\r]//g;

	# return $arg;
	# return String::EscapeCage->new(convert_XSS($arg))->escapecstring();
	return convert_XSS($arg);
}

sub _multipart_data {
	my ($self, $args) = @_;

	$self->_trace('Entering _multipart_data');

	my $total_bytes = $$args{length};

	$self->_debug("_multipart_data: total_bytes = $total_bytes");

	if($total_bytes == 0) {
		return;
	}

	unless($stdin_data) {
		while(<STDIN>) {
			chop(my $line = $_);
			$line =~ s/[\r\n]//g;
			$stdin_data .= "$line\n";
		}
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

	foreach my $line(split(/\n/, $stdin_data)) {
		if($line =~ /^--\Q$boundary\E--$/) {
			last;
		}
		if($line =~ /^--\Q$boundary\E$/) {
			if($writing_file) {
				close $fout;
				$writing_file = 0;
			} elsif(defined($key)) {
				push(@pairs, "$key=$value");
				$value = undef;
			}
			$in_header = 1;
		} elsif($in_header) {
			if(length($line) == 0) {
				$in_header = 0;
			} elsif($line =~ /^Content-Disposition: (.+)/i) {
				my $field = $1;
				if($field =~ /name="(.+?)"/) {
					$key = $1;
				}
				if($field =~ /filename="(.+)?"/) {
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
						# $full_path =~ m/^(\/[\w\.]+)$/;
						my $full_path = File::Spec->catfile($self->{upload_dir}, $filename);
						unless(open($fout, '>', $full_path)) {
							$self->_warn("Can't open $full_path");
						}
						$writing_file = 1;
						push(@pairs, "$key=$filename");
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

# Robust filename generation (preventing overwriting)
sub _create_file_name {
	my ($self, $args) = @_;
	my $filename = $$args{filename} . '_' . time;

	my $counter = 0;
	my $rc;

	do {
		$rc = $filename . ($counter ? "_$counter" : '');
		$counter++;
	} until(! -e $rc);	# Check if file exists

	return $rc;
}

# Untaint a filename. Regex from CGI::Untaint::Filenames
sub _untaint_filename {
	my ($self, $args) = @_;

	if($$args{filename} =~ /(^[\w\+_\040\#\(\)\{\}\[\]\/\-\^,\.:;&%@\\~]+\$?$)/) {
		return $1;
	}
	# return undef;
}

=head2 is_mobile

Returns a boolean if the website is being viewed on a mobile
device such as a smartphone.
All tablets are mobile, but not all mobile devices are tablets.

Can be overriden by the IS_MOBILE environment setting

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
		if($agent =~ /.+(Android|iPhone).+/) {
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
				$self->{cache}->set("$remote/$agent", 'mobile', '1 day');
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

	if($ENV{'HTTP_USER_AGENT'} && ($ENV{'HTTP_USER_AGENT'} =~ /.+(iPad|TabletPC).+/)) {
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

=cut

sub as_string
{
	my $self = shift;

	# Retrieve object parameters
	my $params = $self->params() || return '';
	my $args = Params::Get::get_params(undef, @_);
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

	$self->_trace("as_string: returning '$rc'") if($rc);

	return $rc;
}

=head2 protocol

Returns the connection protocol, presumably 'http' or 'https', or undef if
it can't be determined.

=cut

sub protocol {
	my $self = shift;

	if($ENV{'SCRIPT_URI'} && ($ENV{'SCRIPT_URI'} =~ /^(.+):\/\/.+/)) {
		return $1;
	}
	if($ENV{'SERVER_PROTOCOL'} && ($ENV{'SERVER_PROTOCOL'} =~ /^HTTP\//)) {
		return 'http';
	}

	if(my $port = $ENV{'SERVER_PORT'}) {
		if(defined(my $name = getservbyport($port, 'tcp'))) {
			if($name =~ /https?/) {
				return $name;
			} elsif($name eq 'www') {
				# e.g. NetBSD and OpenBSD
				return 'http';
			}
			# Return an error, maybe missing something
		} elsif($port == 80) {
			# e.g. Solaris
			return 'http';
		} elsif($port == 443) {
			return 'https';
		}
	}

	if($ENV{'REMOTE_ADDR'}) {
		$self->_warn("Can't determine the calling protocol");
	}
	return;
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
	return $params->{default} ? $params->{default} : File::Spec->tmpdir();
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
	my $script_name = $0;

	unless(File::Spec->file_name_is_absolute($script_name)) {
		$script_name = File::Spec->rel2abs($script_name);
	}
	if($script_name =~ /.cgi\-bin.*/) {	# kludge for outside CGI environment
		$script_name =~ s/.cgi\-bin.*//;
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

=head2 logdir

Gets and sets the name of a directory that you can use to store logs in.

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

	# See also params()
	if(($agent =~ /SELECT.+AND.+/) || ($agent =~ /ORDER BY /) || ($agent =~ / OR NOT /) || ($agent =~ / AND \d+=\d+/) || ($agent =~ /THEN.+ELSE.+END/) || ($agent =~ /.+AND.+SELECT.+/) || ($agent =~ /\sAND\s.+\sAND\s/)) {
		$self->status(403);
		$self->{is_robot} = 1;
		if($ENV{'REMOTE_ADDR'}) {
			$self->_warn($ENV{'REMOTE_ADDR'} . ": SQL injection attempt blocked for '$agent'");
		} else {
			$self->_warn("SQL injection attempt blocked for '$agent'");
		}
		return 1;
	}
	if($agent =~ /.+bot|axios\/1\.6\.7|bytespider|ClaudeBot|Clickagy.Intelligence.Bot|msnptc|CriteoBot|is_archiver|backstreet|fuzz faster|linkfluence\.com|spider|scoutjet|gingersoftware|heritrix|dodnetdotcom|yandex|nutch|ezooms|plukkie|nova\.6scan\.com|Twitterbot|adscanner|Go-http-client|python-requests|Mediatoolkitbot|NetcraftSurveyAgent|Expanse|serpstatbot|DreamHost SiteMonitor|techiaith.cymru|trendictionbot|ias_crawler|WPsec|Yak\/1\.0|ZoominfoBot/i) {
		$self->{is_robot} = 1;
		return 1;
	}

	# TODO:
	# Download and use list from
	#	https://raw.githubusercontent.com/mitchellkrogza/apache-ultimate-bad-bot-blocker/refs/heads/master/_generator_lists/bad-user-agents.list

	my $key = "$remote/$agent";

	if(my $referrer = $ENV{'HTTP_REFERER'}) {
		# https://agency.ohow.co/google-analytics-implementation-audit/google-analytics-historical-spam-list/
		my @crawler_lists = (
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

			# Mine
			'http://www.seokicks.de/robot.html',
		);
		$referrer =~ s/\\/_/g;
		if(($referrer =~ /\)/) || (List::Util::any { $_ =~ /^$referrer/ } @crawler_lists)) {
			$self->_debug("is_robot: blocked trawler $referrer");

			if($self->{cache}) {
				$self->{cache}->set($key, 'robot', '1 day');
			}
			$self->{is_robot} = 1;
			return 1;
		}
	}

	if(defined($remote) && $self->{cache}) {
		if(my $type = $self->{cache}->get("$remote/$agent")) {
			return $self->{is_robot} = ($type eq 'robot');
		}
	}

	# Don't use HTTP_USER_AGENT to detect more than we really have to since
	# that is easily spoofed
	if($agent =~ /www\.majestic12\.co\.uk|facebookexternal/) {
		# Mark Facebook as a search engine, not a robot
		if($self->{cache}) {
			$self->{cache}->set($key, 'search', '1 day');
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
				$self->{cache}->set($key, 'robot', '1 day');
			}
			$self->{is_robot} = $is_robot;
			return $is_robot;
		}
	}

	if($self->{cache}) {
		$self->{cache}->set($key, 'unknown', '1 day');
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

Can be overriden by the IS_SEARCH_ENGINE environment setting

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

	my $key;

	if($self->{cache}) {
		$key = "$remote/$agent";
		if(defined($remote) && $self->{cache}) {
			if(my $type = $self->{cache}->get("$remote/$agent")) {
				return $self->{is_search} = ($type eq 'search');
			}
		}
	}

	# Don't use HTTP_USER_AGENT to detect more than we really have to since
	# that is easily spoofed
	if($agent =~ /www\.majestic12\.co\.uk|facebookexternal/) {
		# Mark Facebook as a search engine, not a robot
		if($self->{cache}) {
			$self->{cache}->set($key, 'search', '1 day');
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
			$self->{cache}->set($key, 'search', '1 day');
		}
		return $self->{is_search_engine} = $is_search;
	}

	# TODO: DNS lookup, not gethostbyaddr - though that will be slow
	my $hostname = gethostbyaddr(inet_aton($remote), AF_INET) || $remote;

	my @cidr_blocks = ('47.235.0.0/12');	# Alibaba

	if((defined($hostname) && ($hostname =~ /google|msnbot|bingbot|amazonbot|GPTBot/) && ($hostname !~ /^google-proxy/)) ||
	   (Net::CIDR::cidrlookup($remote, @cidr_blocks))) {
		if($self->{cache}) {
			$self->{cache}->set($key, 'search', '1 day');
		}
		$self->{is_search_engine} = 1;
		return 1;
	}

	$self->{is_search_engine} = 0;
	return 0;
}

=head2 browser_type

Returns one of 'web', 'search', 'robot' and 'mobile'.

    # Code to display a different web page for a browser, search engine and
    # smartphone
    use Template;
    use CGI::Info;

    my $info = CGI::Info->new();
    my $dir = $info->rootdir() . '/templates/' . $info->browser_type();

    my $filename = ref($self);
    $filename =~ s/::/\//g;
    $filename = "$dir/$filename.tmpl";

    if((!-f $filename) || (!-r $filename)) {
	die "Can't open $filename";
    }
    my $template = Template->new();
    $template->process($filename, {}) || die $template->error();

=cut

sub browser_type {
	my $self = shift;

	if($self->is_mobile()) {
		return 'mobile';
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
	my $params = Params::Get::get_params('cookie_name', @_);

	# Validate field argument
	if(!defined($params->{'cookie_name'})) {
		$self->_warn('cookie_name argument not given');
		return;
	}

	# Load cookies if not already loaded
	unless($self->{jar}) {
		if(defined $ENV{'HTTP_COOKIE'}) {
			$self->{jar} = { map { split(/=/, $_, 2) } split(/; /, $ENV{'HTTP_COOKIE'}) };
		}
	}

	# Return the cookie value if it exists, otherwise return undef
	return $self->{jar}->{$params->{'cookie_name'}};
}

=head2 cookie

Returns a cookie's value, or undef if no name is given, or the requested
cookie isn't in the jar.
API is the same as "param",
it will replace the "get_cookie" method in the future.

    use CGI::Info;

    my $name = CGI::Info->new()->cookie('name');
    print "Your name is $name\n";

=cut

sub cookie {
	my ($self, $field) = @_;

	# Validate field argument
	if(!defined($field)) {
		$self->_warn('what cookie do you want?');
		return;
	}

	# Load cookies if not already loaded
	unless($self->{jar}) {
		if(defined $ENV{'HTTP_COOKIE'}) {
			$self->{jar} = { map { split(/=/, $_, 2) } split(/; /, $ENV{'HTTP_COOKIE'}) };
		}
	}

	# Return the cookie value if it exists, otherwise return undef
	return $self->{jar}{$field};
}

=head2 status

Sets or returns the status of the object,
200 for OK,
otherwise an HTTP error code

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

=head2 cache

Get/set the internal cache system.

Use this rather than pass the cache argument to C<new()> if you see these error messages,
"(in cleanup) Failed to get MD5_CTX pointer".
It's some obscure problem that I can't work out,
but calling this after C<new()> works.

=cut

sub cache
{
	my $self = shift;
	my $cache = shift;

	if($cache) {
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
sub _log
{
	my ($self, $level, @messages) = @_;

	# FIXME: add caller's function
	# if(($level eq 'warn') || ($level eq 'info')) {
		push @{$self->{'messages'}}, { level => $level, message => join(' ', grep defined, @messages) };
	# }

	if(scalar(@messages) && (my $logger = $self->{'logger'})) {
		$self->{'logger'}->$level(join('', grep defined, @messages));
	}
}

sub _debug {
	my $self = shift;
	$self->_log('debug', @_);
}

sub _info {
	my $self = shift;
	$self->_log('info', @_);
}

sub _notice {
	my $self = shift;
	$self->_log('notice', @_);
}

sub _trace {
	my $self = shift;
	$self->_log('trace', @_);
}

# Emit a warning message somewhere
sub _warn {
	my $self = shift;
	my $params = Params::Get::get_params('warning', @_);

	$self->_log('warn', $params->{'warning'});
	if(!defined($self->{'logger'})) {
		Carp::carp($params->{'warning'});
	}
}

# Ensure all environment variables are sanitized and validated before use.
# Use regular expressions to enforce strict input formats.
sub _get_env
{
	my ($self, $var) = @_;

	return unless defined $ENV{$var};

	# Strict sanitization: allow alphanumeric and limited special characters
	if($ENV{$var} =~ /^[\w\.\-\/:\\]+$/) {
		return $ENV{$var};
	}
	$self->_warn("Invalid value in environment variable: $var");

	return undef;
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

	# Extract the method name from the AUTOLOAD variable
	my ($method) = $AUTOLOAD =~ /::(\w+)$/;

	# Skip if called on destruction
	return if($method eq 'DESTROY');

	Carp::croak(__PACKAGE__, ": Unknown method $method") if(!ref($self));

	# Allow the AUTOLOAD feature to be disabled
	Carp::croak(__PACKAGE__, ": Unknown method $method") if(exists($self->{'auto_load'}) && boolean($self->{'auto_load'})->isFalse());

	# Ensure the method is called on the correct package object or a subclass
	return unless((ref($self) eq __PACKAGE__) || (UNIVERSAL::isa((caller)[0], __PACKAGE__)));

	# Delegate to the param method
	return $self->param($method);
}

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 BUGS

is_tablet() only currently detects the iPad and Windows PCs. Android strings
don't differ between tablets and smartphones.

params() returns a ref which means that calling routines can change the hash
for other routines.
Take a local copy before making amendments to the table if you don't want unexpected
things to happen.

=head1 SEE ALSO

=over 4

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

=head1 LICENCE AND COPYRIGHT

Copyright 2010-2025 Nigel Horne.

Usage is subject to licence terms.

The licence terms of this software are as follows:

=over 4

=item * Personal single user, single computer use: GPL2

=item * All other users (including Commercial, Charity, Educational, Government)
  must apply in writing for a licence for use from Nigel Horne at the
  above e-mail.

=back

=cut

1;
