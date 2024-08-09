package CGI::Info;

# TODO: remove the expect argument

use warnings;
use strict;
use Carp;
use File::Spec;
use Socket;	# For AF_INET
use 5.008;
use Log::Any qw($log);
# use Cwd;
# use JSON::Parse;
use List::MoreUtils;	# Can go when expect goes
# use Sub::Private;
use Sys::Path;

use namespace::clean;

sub _sanitise_input($);

=head1 NAME

CGI::Info - Information about the CGI environment

=head1 VERSION

Version 0.82

=cut

our $VERSION = '0.82';

=head1 SYNOPSIS

All too often Perl programs have information such as the script's name
hard-coded into their source.
Generally speaking, hard-coding is bad style since it can make programs
difficult to read and it reduces readability and portability.
CGI::Info attempts to remove that.

Furthermore, to aid script debugging, CGI::Info attempts to do sensible
things when you're not running the program in a CGI environment.

    use CGI::Info;
    my $info = CGI::Info->new();
    # ...

=head1 SUBROUTINES/METHODS

=head2 new

Creates a CGI::Info object.

It takes four optional arguments allow, logger, expect and upload_dir,
which are documented in the params() method.

Takes an optional parameter syslog, to log messages to
L<Sys::Syslog>.
It can be a boolean to enable/disable logging to syslog, or a reference
to a hash to be given to Sys::Syslog::setlogsock.

Takes optional parameter logger, an object which is used for warnings

Takes optional parameter cache, an object which is used to cache IP lookups.
This cache object is an object that understands get() and set() messages,
such as a L<CHI> object.

Takes optional parameter max_upload, which is the maximum file size you can upload
(-1 for no limit), the default is 512MB.

=cut

our $stdin_data;	# Class variable storing STDIN in case the class
			# is instantiated more than once

sub new
{
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my %args = (ref($_[0]) eq 'HASH') ? %{$_[0]} : @_;

	if($args{expect} && (ref($args{expect}) ne 'ARRAY')) {
		warn __PACKAGE__, ': expect must be a reference to an array';
		return;
	}

	if(!defined($class)) {
		# Using CGI::Info->new(), not CGI::Info::new()
		# carp(__PACKAGE__, ' use ->new() not ::new() to instantiate');
		# return;

		# FIXME: this only works when no arguments are given
		$class = __PACKAGE__;
	} elsif(ref($class)) {
		# clone the given object
		return bless { %{$class}, %args }, ref($class);
	}

	my %defaults = (
		max_upload_size => 512 * 1024,
		allow => undef,
		expect => undef,
		upload_dir => undef
	);

	return bless { %defaults, %args }, $class;
}

=head2 script_name

Returns the name of the CGI script.
This is useful for POSTing, thus avoiding putting hardcoded paths into forms

	use CGI::Info;

	my $info = CGI::Info->new();
	my $script_name = $info->script_name();
	# ...
	print "<form method=\"POST\" action=$script_name name=\"my_form\">\n";

=cut

sub script_name {
	my $self = shift;

	unless($self->{script_name}) {
		$self->_find_paths();
	}
	return $self->{script_name};
}

sub _find_paths {
	my $self = shift;

	require File::Basename;
	File::Basename->import();

	if($ENV{'SCRIPT_NAME'}) {
		$self->{script_name} = File::Basename::basename($ENV{'SCRIPT_NAME'});
	} else {
		$self->{script_name} = File::Basename::basename($0);
	}
	$self->{script_name} = $self->_untaint_filename({
		filename => $self->{script_name}
	});

	if($ENV{'SCRIPT_FILENAME'}) {
		$self->{script_path} = $ENV{'SCRIPT_FILENAME'};
	} elsif($ENV{'SCRIPT_NAME'} && $ENV{'DOCUMENT_ROOT'}) {
		my $script_name = $ENV{'SCRIPT_NAME'};
		if($script_name =~ /^\/(.+)/) {
			# It's usually the case, e.g. /cgi-bin/foo.pl
			$script_name = $1;
		}
		$self->{script_path} = File::Spec->catfile($ENV{'DOCUMENT_ROOT' }, $script_name);
	} elsif($ENV{'SCRIPT_NAME'} && !$ENV{'DOCUMENT_ROOT'}) {
		if(File::Spec->file_name_is_absolute($ENV{'SCRIPT_NAME'}) && (-r $ENV{'SCRIPT_NAME'})) {
			# Called from a command line with a full path
			$self->{script_path} = $ENV{'SCRIPT_NAME'};
		} else {
			require Cwd;
			Cwd->import;

			my $script_name = $ENV{'SCRIPT_NAME'};
			if($script_name =~ /^\/(.+)/) {
				# It's usually the case, e.g. /cgi-bin/foo.pl
				$script_name = $1;
			}

			$self->{script_path} = File::Spec->catfile(Cwd::abs_path(), $script_name);
		}
	} elsif(File::Spec->file_name_is_absolute($0)) {
		# Called from a command line with a full path
		$self->{script_path} = $0;
	} else {
		$self->{script_path} = File::Spec->rel2abs($0);
	}

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

sub script_dir {
	my $self = shift;

	if(!ref($self)) {
		$self = __PACKAGE__->new();
	}

	unless($self->{script_path}) {
		$self->_find_paths();
	}

	# Don't use File::Spec->splitpath() since that can leave the trailing slash
	if($^O eq 'MSWin32') {
		if($self->{script_path} =~ /(.+)\\.+?$/) {
			return $1;
		}
	} else {
		if($self->{script_path} =~ /(.+)\/.+?$/) {
			return $1;
		}
	}
	return $self->{script_path};
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

sub _find_site_details {
	my $self = shift;

	if($self->{logger}) {
		$self->{logger}->trace('Entering _find_site_details');
	}
	if($self->{site} && $self->{cgi_site}) {
		return;
	}

	require URI::Heuristic;
	URI::Heuristic->import;

	if($ENV{'HTTP_HOST'}) {
		$self->{cgi_site} = URI::Heuristic::uf_uristr($ENV{'HTTP_HOST'});
		# Remove trailing dots from the name.  They are legal in URLs
		# and some sites link using them to avoid spoofing (nice)
		if($self->{cgi_site} =~ /(.*)\.+$/) {
			$self->{cgi_site} = $1;
		}
	} elsif($ENV{'SERVER_NAME'}) {
		$self->{cgi_site} = URI::Heuristic::uf_uristr($ENV{'SERVER_NAME'});
		if(defined($self->protocol()) && ($self->protocol() ne 'http')) {
			$self->{cgi_site} =~ s/^http//;
			$self->{cgi_site} = $self->protocol() . $self->{cgi_site};
		}
	} else {
		require Sys::Hostname;
		Sys::Hostname->import;

		if($self->{logger}) {
			$self->{logger}->debug('Falling back to using hostname');
		}

		$self->{cgi_site} = Sys::Hostname::hostname();
	}

	unless($self->{site}) {
		$self->{site} = $self->{cgi_site};
	}
	if($self->{site} =~ /^https?:\/\/(.+)/) {
		$self->{site} = $1;
	}
	unless($self->{cgi_site} =~ /^https?:\/\//) {
		my $protocol = $self->protocol();

		unless($protocol) {
			$protocol = 'http';
		}
		$self->{cgi_site} = "$protocol://" . $self->{cgi_site};
	}
	unless($self->{site} && $self->{cgi_site}) {
		$self->_warn('Could not determine site name');
	}
	if($self->{logger}) {
		$self->{logger}->trace('Leaving _find_site_details');
	}
}

=head2 domain_name

Domain_name is the name of the controlling domain for this website.
Usually it will be similar to host_name, but will lack the http:// prefix.

=cut

sub domain_name {
	my $self = shift;

	if($self->{domain}) {
		return $self->{domain};
	}
	$self->_find_site_details();

	if($self->{site}) {
		$self->{domain} = $self->{site};
		if($self->{domain} =~ /^www\.(.+)/) {
			$self->{domain} = $1;
		}
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

Takes four optional parameters: allow, expect, logger and upload_dir.
The parameters are passed in a hash, or a reference to a hash.
The latter is more efficient since it puts less on the stack.

Allow is a reference to a hash list of CGI parameters that you will allow.
The value for each entry is a regular expression of permitted values for
the key.
A undef value means that any value will be allowed.
Arguments not in the list are silently ignored.
This is useful to help to block attacks on your site.

Expect is a reference to a list of arguments that you expect to see and pass on.
Arguments not in the list are silently ignored.
This is useful to help to block attacks on your site.
Its use is deprecated, use allow instead.
Expect will be removed in a later version.

Upload_dir is a string containing a directory where files being uploaded are to
be stored.

Takes optional parameter logger, an object which is used for warnings and
traces.
This logger object is an object that understands warn() and trace() messages,
such as a L<Log::Log4perl> or L<Log::Any> object.

The allow, expect, logger and upload_dir arguments can also be passed to the
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
		bar => undef,
		xyzzy => qr/^[\w\s-]+$/,	# must be alphanumeric
						# to prevent XSS, and non-empty
						# as a sanity check
	};
	my $paramsref = $info->params(allow => $allowed);
	# or
	my @expected = ('foo', 'bar');
	my $paramsref = $info->params({
		expect => \@expected,
		upload_dir = $info->tmpdir()
	});
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

=cut

sub params {
	my $self = shift;

	my $params = $self->_get_params(undef, @_);

	if((defined($self->{paramref})) && ((!defined($params->{'allow'})) || defined($self->{allow}) && ($params->{'allow'} eq $self->{allow}))) {
		return $self->{paramref};
	}

	if(defined($params->{allow})) {
		$self->{allow} = $params->{allow};
	}
	if(defined($params->{expect})) {
		if(ref($params->{expect}) eq 'ARRAY') {
			$self->{expect} = $params->{expect};
		} else {
			$self->_warn('expect must be a reference to an array');
		}
	}
	if(defined($params->{upload_dir})) {
		$self->{upload_dir} = $params->{upload_dir};
	}
	if(defined($params->{logger})) {
		$self->{logger} = $params->{logger};
	}
	if($self->{logger}) {
		$self->{logger}->trace('Entering params');
	}

	my @pairs;
	my $content_type = $ENV{'CONTENT_TYPE'};
	my %FORM;

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
		} elsif(!$self->{args_read}) {
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
		if(!defined($ENV{'CONTENT_LENGTH'})) {
			$self->{status} = 411;
			return;
		}
		my $content_length = $ENV{'CONTENT_LENGTH'};
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
			if(!File::Spec->file_name_is_absolute($self->{upload_dir})) {
				$self->_warn({
					warning => "upload_dir $self->{upload_dir} isn't a full pathname"
				});
				delete $self->{upload_dir};
				return;
			}
			if(!-d $self->{upload_dir}) {
				$self->_warn({
					warning => "upload_dir $self->{upload_dir} isn't a directory"
				});
				delete $self->{upload_dir};
				return;
			}
			if(!-w $self->{upload_dir}) {
				delete $self->{paramref};
				$self->_warn({
					warning => "upload_dir $self->{upload_dir} isn't writeable"
				});
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
				require JSON::MaybeXS;
				JSON::MaybeXS->import();

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
				if($self->{logger}) {
					$self->{logger}->info("discard $key");
				}
				next;
			}

			# Do we allow any value, or must it be validated?
			if(defined($self->{allow}->{$key})) {
				if($value !~ $self->{allow}->{$key}) {
					if($self->{logger}) {
						$self->{logger}->info("block $key = $value");
					}
					next;
				}
			}
		}

		if($self->{expect} && (List::MoreUtils::none { $_ eq $key } @{$self->{expect}})) {
			next;
		}
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
			   ($value =~ /\/\*\*\/ORDER\/\*\*\/BY\/\*\*/ix) ||
			   ($value =~ /exec(\s|\+)+(s|x)p\w+/ix)) {
				if($self->{logger}) {
					if($ENV{'REMOTE_ADDR'}) {
						$self->{logger}->warn($ENV{'REMOTE_ADDR'}, ": SQL injection attempt blocked for '$value'");
					} else {
						$self->{logger}->warn("SQL injection attempt blocked for '$value'");
					}
				}
				$self->status(403);
				return;
			}
			if(($value =~ /((\%3C)|<)((\%2F)|\/)*[a-z0-9\%]+((\%3E)|>)/ix) ||
			   ($value =~ /((\%3C)|<)[^\n]+((\%3E)|>)/i)) {
				if($self->{logger}) {
					$self->{logger}->warn("XSS injection attempt blocked for '$value'");
				}
				$self->status(403);
				return;
			}
			if($value eq '../') {
				if($self->{logger}) {
					$self->{logger}->warn("Blocked directory traversal attack for $key");
				}
				$self->status(403);
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

	if($self->{logger}) {
		while(my ($key,$value) = each %FORM) {
			$self->{logger}->debug("$key=$value");
			$log->debug("$key=$value");
		}
	}

	$self->{paramref} = \%FORM;

	return \%FORM;
}

=head2 param

Get a single parameter.
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

	if(defined($self->params())) {
		return $self->params()->{$field};
	}
	return;
}

# Emit a warning message somewhere
sub _warn {
	my $self = shift;

	my $params = $self->_get_params('warning', @_);

	my $warning = $params->{'warning'};

	return unless($warning);
	if($self eq __PACKAGE__) {
		# Called from class method
		carp($warning);
		return;
	}
	# return if($self eq __PACKAGE__);  # Called from class method

	if($self->{syslog}) {
		require Sys::Syslog;

		Sys::Syslog->import();
		if(ref($self->{syslog} eq 'HASH')) {
			Sys::Syslog::setlogsock($self->{syslog});
		}
		openlog($self->script_name(), 'cons,pid', 'user');
		syslog('warning', $warning);
		closelog();
	}

	if($self->{logger}) {
		$self->{logger}->warn($warning);
	} elsif(!defined($self->{syslog})) {
		Carp::carp($warning);
	}
}

# Helper routine to parse the arguments given to a function,
#	allowing the caller to call the function in anyway that they want
#	e.g. foo('bar'), foo(arg => 'bar'), foo({ arg => 'bar' }) all mean the same
#	when called _get_params('arg', @_);
sub _get_params
{
	my $self = shift;
	my $default = shift;

	if(ref($_[0]) eq 'HASH') {
		# %rc = %{$_[0]};
		return $_[0];
	}

	my %rc;

	if(scalar(@_) % 2 == 0) {
		%rc = @_;
	} elsif(scalar(@_) == 1) {
		if(defined($default)) {
			$rc{$default} = shift;
		} else {
			my @c = caller(1);
			my $func = $c[3];	# calling function name
			Carp::croak('Usage: ', __PACKAGE__, "->$func()");
		}
	} elsif((scalar(@_) == 0) && defined($default)) {
		my @c = caller(1);
		my $func = $c[3];	# calling function name
		Carp::croak('Usage: ', __PACKAGE__, "->$func($default => " . '$val)');
	}

	return \%rc;
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

	if($self->{logger}) {
		$self->{logger}->trace('Entering _multipart_data');
	}
	my $total_bytes = $$args{length};

	if($self->{logger}) {
		$self->{logger}->trace("_multipart_data: total_bytes = $total_bytes");
	}
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

	return @pairs;
}

sub _create_file_name {
	my ($self, $args) = @_;

	return $$args{filename} . '_' . time;
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
device such as a smart-phone.
All tablets are mobile, but not all mobile devices are tablets.

=cut

sub is_mobile {
	my $self = shift;

	if(defined($self->{is_mobile})) {
		return $self->{is_mobile};
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
		if ($agent =~ m/(android|bb\d+|meego).+mobile|avantgo|bada\/|blackberry|blazer|compal|elaine|fennec|hiptop|iemobile|ip(hone|od)|iris|kindle|lge |maemo|midp|mmp|mobile.+firefox|netfront|opera m(ob|in)i|palm( os)?|phone|p(ixi|re)\/|plucker|pocket|psp|series(4|6)0|symbian|treo|up\.(browser|link)|vodafone|wap|windows ce|xda|xiino/i || substr($ENV{'HTTP_USER_AGENT'}, 0, 4) =~ m/1207|6310|6590|3gso|4thp|50[1-6]i|770s|802s|a wa|abac|ac(er|oo|s\-)|ai(ko|rn)|al(av|ca|co)|amoi|an(ex|ny|yw)|aptu|ar(ch|go)|as(te|us)|attw|au(di|\-m|r |s )|avan|be(ck|ll|nq)|bi(lb|rd)|bl(ac|az)|br(e|v)w|bumb|bw\-(n|u)|c55\/|capi|ccwa|cdm\-|cell|chtm|cldc|cmd\-|co(mp|nd)|craw|da(it|ll|ng)|dbte|dc\-s|devi|dica|dmob|do(c|p)o|ds(12|\-d)|el(49|ai)|em(l2|ul)|er(ic|k0)|esl8|ez([4-7]0|os|wa|ze)|fetc|fly(\-|_)|g1 u|g560|gene|gf\-5|g\-mo|go(\.w|od)|gr(ad|un)|haie|hcit|hd\-(m|p|t)|hei\-|hi(pt|ta)|hp( i|ip)|hs\-c|ht(c(\-| |_|a|g|p|s|t)|tp)|hu(aw|tc)|i\-(20|go|ma)|i230|iac( |\-|\/)|ibro|idea|ig01|ikom|im1k|inno|ipaq|iris|ja(t|v)a|jbro|jemu|jigs|kddi|keji|kgt( |\/)|klon|kpt |kwc\-|kyo(c|k)|le(no|xi)|lg( g|\/(k|l|u)|50|54|\-[a-w])|libw|lynx|m1\-w|m3ga|m50\/|ma(te|ui|xo)|mc(01|21|ca)|m\-cr|me(rc|ri)|mi(o8|oa|ts)|mmef|mo(01|02|bi|de|do|t(\-| |o|v)|zz)|mt(50|p1|v )|mwbp|mywa|n10[0-2]|n20[2-3]|n30(0|2)|n50(0|2|5)|n7(0(0|1)|10)|ne((c|m)\-|on|tf|wf|wg|wt)|nok(6|i)|nzph|o2im|op(ti|wv)|oran|owg1|p800|pan(a|d|t)|pdxg|pg(13|\-([1-8]|c))|phil|pire|pl(ay|uc)|pn\-2|po(ck|rt|se)|prox|psio|pt\-g|qa\-a|qc(07|12|21|32|60|\-[2-7]|i\-)|qtek|r380|r600|raks|rim9|ro(ve|zo)|s55\/|sa(ge|ma|mm|ms|ny|va)|sc(01|h\-|oo|p\-)|sdk\/|se(c(\-|0|1)|47|mc|nd|ri)|sgh\-|shar|sie(\-|m)|sk\-0|sl(45|id)|sm(al|ar|b3|it|t5)|so(ft|ny)|sp(01|h\-|v\-|v )|sy(01|mb)|t2(18|50)|t6(00|10|18)|ta(gt|lk)|tcl\-|tdg\-|tel(i|m)|tim\-|t\-mo|to(pl|sh)|ts(70|m\-|m3|m5)|tx\-9|up(\.b|g1|si)|utst|v400|v750|veri|vi(rg|te)|vk(40|5[0-3]|\-v)|vm40|voda|vulc|vx(52|53|60|61|70|80|81|83|85|98)|w3c(\-| )|webc|whit|wi(g |nc|nw)|wmlb|wonu|x700|yas\-|your|zeto|zte\-/i) {
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
			my $is_mobile = (defined($device) && ($device =~ /blackberry|webos|iphone|ipod|ipad|android/i));
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

Returns the parameters as a string, which is useful for debugging or
generating keys for a cache.

=cut

sub as_string {
	my $self = shift;

	unless($self->params()) {
		return '';
	}

	my %f = %{$self->params()};

	my $rc;

	foreach (sort keys %f) {
		my $value = $f{$_};
		$value =~ s/\\/\\\\/g;
		$value =~ s/(;|=)/\\$1/g;
		if(defined($rc)) {
			$rc .= ";$_=$value";
		} else {
			$rc = "$_=$value";
		}
	}
	if($rc && $self->{logger}) {
		$self->{logger}->debug("is_string: returning '$rc'");
	}

	return defined($rc) ? $rc : '';
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

	my $port = $ENV{'SERVER_PORT'};
	if(defined($port)) {
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
	my $params = $self->_get_params(undef, @_);

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

	if(defined($dir)) {
		# No sanity testing is done
		return $self->{logdir} = $dir;
	}

	foreach my $rc($self->{logdir}, $ENV{'LOGDIR'}, Sys::Path->logdir(), $self->tmpdir()) {
		if(defined($rc) && length($rc) && (-d $rc) && (-w $rc)) {
			$dir = $rc;
			last;
		}
	}
	carp("Can't determine logdir") if((!defined($dir)) || (length($dir) == 0));
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

	if(($agent =~ /SELECT.+AND.+/) || ($agent =~ /ORDER BY /) || ($agent =~ / OR NOT /) || ($agent =~ / AND \d+=\d+/) || ($agent =~ /THEN.+ELSE.+END/) || ($agent =~ /.+AND.+SELECT.+/) || ($agent =~ /\sAND\s.+\sAND\s/)) {
		$self->status(403);
		$self->{is_robot} = 1;
		if($self->{logger}) {
			if($ENV{'REMOTE_ADDR'}) {
				$self->{logger}->warn($ENV{'REMOTE_ADDR'}, ": SQL injection attempt blocked for '$agent'");
			} else {
				$self->{logger}->warn("SQL injection attempt blocked for '$agent'");
			}
		}
		return 1;
	}
	if($agent =~ /.+bot|axios\/1\.6\.7|bytespider|ClaudeBot|msnptc|is_archiver|backstreet|spider|scoutjet|gingersoftware|heritrix|dodnetdotcom|yandex|nutch|ezooms|plukkie|nova\.6scan\.com|Twitterbot|adscanner|python-requests|Mediatoolkitbot|NetcraftSurveyAgent|Expanse|serpstatbot|DreamHost SiteMonitor|techiaith.cymru|trendictionbot|ias_crawler|Yak\/1\.0|ZoominfoBot/i) {
		$self->{is_robot} = 1;
		return 1;
	}

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
		if(($referrer =~ /\)/) || (List::MoreUtils::any { $_ =~ /^$referrer/ } @crawler_lists)) {
			if($self->{logger}) {
				$self->{logger}->debug("is_robot: blocked trawler $referrer");
			}
			if($self->{cache}) {
				$self->{cache}->set($key, 'robot', '1 day');
			}
			$self->{is_robot} = 1;
			return 1;
		}
	}

	if($self->{cache}) {
		if(defined($remote) && $self->{cache}) {
			if(my $type = $self->{cache}->get("$remote/$agent")) {
				return $self->{is_robot} = ($type eq 'robot');
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
		if(defined($is_robot) && $self->{logger}) {
			$self->{logger}->debug("HTTP::BrowserDetect '$ENV{HTTP_USER_AGENT}' returns $is_robot");
		}
		$is_robot = (defined($is_robot) && ($is_robot)) ? 1 : 0;
		if($self->{logger}) {
			$self->{logger}->debug("is_robot: $is_robot");
		}

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

    use CGI::Info;

    if(CGI::Info->new()->is_search_engine()) {
	# display generic information about yourself
    } else {
	# allow the user to pick and choose something to display
    }

=cut

sub is_search_engine {
	my $self = shift;

	if(defined($self->{is_search_engine})) {
		return $self->{is_search_engine};
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
		if((!$is_search) && $agent =~ /SeznamBot\//) {
			$is_search = 1;
		}
		if($is_search && $self->{cache}) {
			$self->{cache}->set($key, 'search', '1 day');
		}
		return $self->{is_search_engine} = $is_search;
	}

	# TODO: DNS lookup, not gethostbyaddr - though that will be slow
	my $hostname = gethostbyaddr(inet_aton($remote), AF_INET) || $remote;

	if(defined($hostname) && ($hostname =~ /google|msnbot|bingbot|amazonbot|GPTBot/) && ($hostname !~ /^google-proxy/)) {
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
	my $params = $self->_get_params('cookie_name', @_);

	if(!defined($params->{'cookie_name'})) {
		$self->_warn('cookie_name argument not given');
		return;
	}

	unless($self->{jar}) {
		unless(defined($ENV{'HTTP_COOKIE'})) {
			return;
		}
		my @cookies = split(/; /, $ENV{'HTTP_COOKIE'});

		foreach my $cookie(@cookies) {
			my ($name, $value) = split(/=/, $cookie);
			$self->{jar}->{$name} = $value;
		}
	}

	if(exists($self->{jar}->{$params->{'cookie_name'}})) {
		return $self->{jar}->{$params->{'cookie_name'}};
	}
	return;	# Return undef
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

	if(!defined($field)) {
		$self->_warn('what cookie do you want?');
		return;
	}

	unless($self->{jar}) {
		unless(defined($ENV{'HTTP_COOKIE'})) {
			return;
		}
		my @cookies = split(/; /, $ENV{'HTTP_COOKIE'});

		foreach my $cookie(@cookies) {
			my ($name, $value) = split(/=/, $cookie);
			$self->{jar}->{$name} = $value;
		}
	}

	if(exists($self->{jar}->{$field})) {
		return $self->{jar}->{$field};
	}
	return;	# Return undef
}

=head2 status

Sets or returns the status of the object,
200 for OK,
otherwise an HTTP error code

=cut

sub status {
	my $self = shift;

	if(my $status = shift) {
		$self->{status} = $status;
	} elsif(!defined($self->{status})) {
		if(defined(my $method = $ENV{'REQUEST_METHOD'})) {
			if(($method eq 'OPTIONS') || ($method eq 'DELETE')) {
				return 405;
			} elsif(($method eq 'POST') && !defined($ENV{'CONTENT_LENGTH'})) {
				return 411;
			}
		}
		return 200;
	}

	return $self->{status} || 200;
}

=head2 set_logger

Sometimes you don't know what the logger is until you've instantiated the class.
This function fixes the catch22 situation.

=cut

sub set_logger {
	my $self = shift;
	my $params = $self->_get_params('logger', @_);

	$self->{logger} = $params->{'logger'};

	return $self;
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

sub AUTOLOAD {
	our $AUTOLOAD;
	my $param = $AUTOLOAD;

	$param =~ s/.*:://;

	return if($param eq 'DESTROY');

	my $self = shift;

	return if(ref($self) ne __PACKAGE__);

	return $self->param($param);
}

=head1 AUTHOR

Nigel Horne, C<< <njh at bandsman.co.uk> >>

=head1 BUGS

is_tablet() only currently detects the iPad and Windows PCs. Android strings
don't differ between tablets and smart-phones.

Please report any bugs or feature requests to C<bug-cgi-info at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CGI-Info>.
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

params() returns a ref which means that calling routines can change the hash
for other routines.
Take a local copy before making amendments to the table if you don't want unexpected
things to happen.

=head1 SEE ALSO

L<HTTP::BrowserDetect>,
L<https://github.com/mitchellkrogza/apache-ultimate-bad-bot-blocker>

=head1 SUPPORT

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

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2024 Nigel Horne.

This program is released under the following licence: GPL2

=cut

1;
