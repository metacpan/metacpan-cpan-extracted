
package RayApp;

use strict;
use warnings;
use 5.008001;

$RayApp::VERSION = '2.004';

# print STDERR "RayApp version [$RayApp::VERSION]\n";

use URI::file ();
use XML::LibXML ();
use RayApp::UserAgent ();

# The constructor
sub new {
	my $class = shift;
	my $base = URI::file->cwd;
	my %options;
	my $ua_options = delete $options{ua_options};
	my $ua = new RayApp::UserAgent(
		defined($ua_options) ? %$ua_options : ()
	);
	my $self = bless {
		%options,
		base => $base,
		ua => $ua,
		}, $class;
	return $self;
}
# Errstr is either a class or instance method
sub errstr {
	my $self = shift;
	my $errstr;
	if (@_) {
		if (defined $_[0]) {
			$errstr = join ' ', @_;
			chomp $errstr;
		}
		if (ref $self) {
			$self->{errstr} = $errstr;
		} else {
			$RayApp::errstr = $errstr;
		}
	}
	if (ref $self) {
		return $self->{errstr};
	} else {
		return $RayApp::errstr;
	}
}
sub clear_errstr {
	shift->errstr(undef);
	1;
}

sub base {
	shift->{base};
}

# Loading content by URI
sub load_uri {
	my ($self, $uri, %options) = @_;
	$self->clear_errstr;

	# rewrite the URI to the absolute one
	$uri = URI->new_abs($uri, $self->{base});

	# print STDERR "Loading $uri in pid $$\n";

	# reuse cached file
	my $cached = $self->{uris}{$uri};
	if (defined $cached
		and defined $cached->mtime
		and $uri =~ m!^file:(//)?(/.*)$!) {
		my $filename = $2;

		my $cached_mtime = $cached->mtime;
		my $current_mtime = (stat $filename)[9];
		if ($cached_mtime == $current_mtime) {
			# print STDERR " + Reusing $uri [$cached_mtime] [$current_mtime]\n";
			return $cached;
		}

		# print STDERR " - Will have to reload $uri\n";
	}

	require RayApp::Source;
	my $data = new RayApp::Source(
		%options,
		rayapp => $self,
		uri => $uri,
	) or return;
	$self->{uris}{ $data->uri } = $data;
	return $data;
}

# Loading content by string
sub load_string {
	my ($self, $string, %options) = @_;
	$self->clear_errstr;

	require RayApp::String;
	my $data = new RayApp::String(
		%options,
		rayapp => $self,
		content => $string,
	) or return;
	$self->{uris}{ $data->uri } = $data;
	return $data;
}

# Loading URI expected to be XML
sub load_xml {
	my ($self, $uri, %options) = @_;

	require RayApp::XML;
	my $xml = new RayApp::XML(
		%options,
		rayapp => $self,
		uri => $uri,
	) or return;
	$self->{xmls}{ $xml->uri } = $xml;
	return $xml;
}

# Loading string expected to be XML
sub load_xml_string {
	my ($self, $string, %options) = @_;

	require RayApp::XML;
	my $xml = new RayApp::XML(
		%options,
		rayapp => $self,
		content => $string,
	) or return;
	$self->{xmls}{ $xml->uri } = $xml;
	return $xml;
}

# Loading URI expected to be DSD
sub load_dsd {
	my ($self, $uri) = (shift, shift);

	my $xml = $self->load_xml($uri, @_) or return;
        if ($xml->{is_dsd}) {
		return $xml;
	}

	$xml->parse_as_dsd() or return;
	$xml;
}

# Loading string expected to be DSD
sub load_dsd_string {
	my ($self, $string) = ( shift, shift );

	my $xml = $self->load_xml_string($string, @_) or return;
        if ($xml->{is_dsd}) {
		return $xml;
	}

	$xml->parse_as_dsd() or return;
	$xml;
}

# Using user agent
sub ua { shift->{ua}; }

# Using XML::LibXML parser
sub xml_parser {
	my $self = shift;
	if (not defined $self->{xml_parser}) {
		$self->{xml_parser} = new XML::LibXML;
		if (not defined $self->{xml_parser}) {
			$self->errstr("Error loading the XML::LibXML parser");
			return;
		}
		$self->{xml_parser}->line_numbers(1);
		# $self->{xml_parser}->keep_blanks(0);
	}
	$self->{xml_parser};
}

sub execute_application_cgi {
	my ($self, $application, @params) = @_;
	$self->{errstr} = undef;
	if (ref $application) {
		$application = $application->application_name;
	}       
	my $ret = eval {
		if (not defined $application) {
			die "Application name was not defined\n";
		}
		require $application;
		return &handler(@params);
	};
	if ($@) {
		print STDERR $@;
		my $errstr = $@;
		$errstr =~ s/\n$//;
		$self->{errstr} = $errstr;
		return 500;
	}
	return $ret;
}

sub execute_application_handler {
	my ($self, $application, @params) = @_;
	$self->{errstr} = undef;
	if (ref $application) {
		$application = $application->application_name;
	}       
	my $ret = eval {
		if (not defined $application) {
			die "Application name was not defined\n";
		}
		local *FILE;
		open FILE, $application or die "Error reading `$application': $!\n";
		local $/ = undef;
		my $content = <FILE>;
		close FILE or die "Error reading `$application' during close: $!\n";
		if (${^TAINT}) {
			$content =~ /^(.*)$/s and $content = $1;
		}
		my $max_num = $self->{max_handler_num};
		if (not defined $max_num) {
			$max_num = 0;
		}
		$self->{max_handler_num} = ++$max_num;
		my $appname = $application;
		utf8::decode($appname);
		{
		no warnings 'redefine';
		eval qq!#line 1 "$appname"\npackage RayApp::Root::pkg$max_num; ! 
			. $content
			or die "Compiling `$application' did not return true value\n";
		}
		my $handler = 'RayApp::Root::pkg' . $max_num . '::handler';
		$self->{handlers}{$application} = {
			handler => $handler,
		};
		no strict;
		return &{ $handler }(@params);
	};
	if ($@) {
		$self->errstr($@);
		return 500;
	}
	return $ret;
}

sub execute_application_handler_reuse {
	my ($self, $application, @params) = @_;
	$self->{errstr} = undef;
	if (ref $application) {
		$application = $application->application_name;
	}       
	my $ret = eval {
		if (not defined $application) {
			die "Application name was not defined\n";
		}
		my $handler;
		my $mtime = (stat $application)[9];
		if (defined $self->{handlers}{$application}
			and defined $self->{handlers}{$application}{mtime}
			and $self->{handlers}{$application}{mtime} == $mtime) {
			# print STDERR "Not loading\n";
			$handler = $self->{handlers}{$application}{handler};
		} else {        
			$handler = $application;
			$handler =~ s!([^a-zA-Z0-9])! ($1 eq '/') ? '::' : sprintf("_%02x", ord $1) !ge;
			my $package = 'RayApp::Root::pkn' . $handler;
			$handler = $package . '::handler';
			### print STDERR "Loading\n";

			local *FILE;
			open FILE, $application or die "Error reading `$application': $!\n";
			local $/ = undef;
			my $content = <FILE>;
			close FILE or die "Error reading `$application' during close: $!\n";
			if (${^TAINT}) {
				$content =~ /^(.*)$/s and $content = $1;
			}
			my $max_num = $self->{max_handler_num};
			if (not defined $max_num) {
				$max_num = 0;
			}
			## $content =~ s/(.*)/$1/s;
			$max_num++;
			{
			no warnings 'redefine';
			my $appname = $application;
			utf8::decode($appname);
			eval qq!package $package;\n#line 1 "$appname"\n!
				. $content
				or die "Compiling `$application' did not return true value\n";
			}
			$self->{handlers}{$application} = {
				handler => $handler,
				mtime => $mtime,
			};
		}
		no strict;
		return &{ $handler }(@params);
	};
	if ($@) {
		print STDERR $@;
		my $errstr = $@;
		$errstr =~ s/\n$//;
		$self->{errstr} = $errstr;
		return 500;
	}
	return $ret;
}

1;


=head1 NAME

RayApp - Framework for data-centric Web applications

=head1 SYNOPSIS

	use RayApp;
	my $rayapp = new RayApp;
	my $dsd = $rayapp->load_dsd('structure.dsd');
	print $dsd->serialize_data( $data );

=head1 INTRODUCTION

The B<RayApp> provides a framework for data-centric Web applications.
Instead of writing Perl code that prints HTML, or a code that calls
functions that print HTML, or embedding the code inside of HTML
markup, the Web applications only process and return Perl data.
No markup handling is done in the code of individual applications,
thus application code can focus on the business logic. This reduces
the presentation noise in individual applications, increases
maintainability and speeds development.

The data returned by the application is then serialized to XML and
can be postprocessed by XSLT to desired output format, which may be
HTML, XHTML, WML or anything else. In order to provide all parties
involved (analysts, application programmers, Web designers, ...) with
a common specification of the data format, data structure description
(DSD) file is a mandatory part of the applications. The DSD describes
what parameters the application expects and what data it will return,
therefore, what XML will come out of that data. The data returned
by the application in a form of hash by the Perl code is fitted into
the data structure, creating XML file with agreed-on elements.

This way, application programmers know what data is expected from
their applications and Web designers know what XMLs the
prostprocessing stage will be dealing with, in advance. In addition,
application code can be tested separately from the presentation part,
and tests for both application and presentation part can be written
independently, in parallel. Of course, this also works if you are the
sole person on the project, playing the above mentioned roles.

The system will never produce unexpected data output, since the data
output is based on DSD which is known.

=head1 CONFIGURATION

Most of the use of RayApp is expected in the Web context. This
section summarizes configuration steps needed for the Apache HTTP
server. This version of RayApp works with Apache 2.0
and mod_perl 2.0.

Assume you have a Web application that should reside on URL

	http://server/sub/app.html

The application consists of three files:

	/opt/www/app.dsd
	/opt/www/app.pl
	/opt/www/app.xsl

Yes, instead of sticking application code and presentation into one
file, we separate them completely.

Whenever a request for /sub/app.html comes, the DSD
/opt/www/app.dsd is loaded, app.pl (or app.mpl) executed and its
output serialized to HTML using app.xsl. For syntax of app.dsd, see
B<RayApp::DSD>. In the app.pl script, there has to be at least one
function, called B<handler>, and this function should return Perl hash
with data matching the DSD. The whole content of the .pl is evaluated
in a B<package> context in a B<Apache::Registry> manner, so two
B<handler> methods from different applications do not clash. In
app.xsl, there should be an XSLT stylesheet.

If you issue a request for /sub/app.xml, the presentation
postprocessing is skipped and you get the XML output -- ideal for
debugging.

If the app.html file exists in the filesystem, it "overrides" any
attempts to is generate dynamic content, and the file is returned.
Likewise, if there is a app.xml file in the filesystem and there is
a request for app.xml, the XML file is returned. If there is app.xml
but no app.html and a request for app.html comes, the app.xml is
serialized using app.xsl. So B<RayApp> can be used not only for fully
dynamic sites, but also as a XSLT processor.

You will need to configure Apache for B<RayApp> to do its job. It
can operate both in the mod_perl and in pure CGI way.

=head2 Pure mod_perl approach

If you have a mod_perl 2 support in your Apache 2 and want to use
it to run you B<RayApp>-based applications, the following setup
will give you the correct result:

	Alias /sub /opt/www
	<LocationMatch ^/sub/(.+\.(html|xml))?$/>
		SetHandler perl-script
		PerlResponseHandler RayApp::mod_perl
	</LocationMatch>

The Alias directive ensures that the DSD and Perl code will be
correctly found in the /opt/www/ directory, for requests coming to
/sub/ Location.

Instead of perl-script, you can also use C<SetHandler modperl>.

=head2 CGI approach

In the B<RayApp> distribution, there is a script
B<rayapp_cgi_wrapper>. Assuming it was installed in the B</usr/bin>
directory, the configuration is

	ScriptAliasMatch ^/sub/(.+(\.(html|xml))?)?$ /usr/bin/rayapp_cgi_wrapper/$1
	<Location /sub>
		SetEnv RAYAPP_DIRECTORY /opt/www
	</Location>

With the B<ScriptAliasMatch> directive in effect, the request will
be processed by B<usr/bin/rayapp_cgi_wrapper>, and the
C<SetEnv RAYAPP_DIRECTORY> tells B<RayApp> where on the filesystem
should it find the necessary files of the application (the same
as B<Alias> with mod_perl setup).
Here we partly simulate the work that Apache would have done for us
in the static files case.

Both B<LocationMatch> in mod_perl case and B<Location> in CGI case can
of course contain additional configuration options for Apache,
like B<Order> / B<Allow>, and configuration of B<RayApp>, described
in the next section.

=head2 More detailed setup

For mod_perl, the configuration is done using B<PerlSetVar> and the
variable name in in mixed capitals. For CGI, enviroment variables are
used, set using B<SetEnv> and the variable name is in all capitals,
words separated by underscores. For example, for mod_perl the directive
would be

	PerlSetVar RayAppDirectoryIndex index.html

and for CGI, it would read

	SetEnv RAYAPP_DIRECTORY_INDEX index.html

Supported options:

=over 4

=item RayAppDirectoryIndex / RAYAPP_DIRECTORY_INDEX

Similar to Apache's B<DirectoryIndex> directive, this will be used
for requests ending with a slash, or generaly requests resulting
into requests for directories. As B<RayApp>'s output is dynamically
generated, pure B<DirectoryIndex> cannot be used.

If not set, nothing will be served for directory requests.

=item RayAppInputModule / RAYAPP_INPUT_MODULE

As already noted, B<RayApp> runs the B<handler> function found
in the application file (app.pl). Often applications share the same
context -- all of them want to be passed an open B<$dbh> database
handler (instead of doing their own DBI->connect), all of them want to
be passed the request object to query the input parameters.

The option B<RayAppInputModule> specifies a module name which will
be loaded and from which a B<handler> function will be called for
every request. The function should return a list of values that
will be passed in as parameters to the application B<handler>.

The first parameter passed to this input module B<handler> is the
B<RayApp::DSD> object, for mod_perl the second argument is the request
(B<Apache2::RequestRec>) object. An example of an input module might
be

	package Application::Input;

	use RayApp::Request ();
	use DBI ();
	sub handler {
		my ($dsd, $r) = @_;
		if (defined $dsd) {
			$dsd->validate_parameters($q)
				or die $dsd->errstr;
		}
		my $dbh = DBI->connect('dbi:Oracle:prod',
			'scott', 'tiger',
			{ RaiseError => 1, AutoCommit => 0 });
		my $q = new RayApp::Request($r);
		return ($dbh, $q);
	}
	1;

Here we first validate parameters against DSD (you can optionally
die or just log an error, depending on how strict you want to be),
we connect to the database, so that the applications get connection
to their database backend, and we use B<RayApp::Request> to get
uniform (for mod_perl and CGI) query object. The values B<$dbh> and
B<$q> are returned and will be passed as argument to the application
B<handler>.

=item RayAppStyleParamModule / RAYAPP_STYLE_PARAM_MODULE

There are often additional data except the core data of the
application that you might like to process in your XSLT
stylesheets -- id of the authenticated user, the full and
relative URLs of the currently running application, some sticky
preferences of the user. They are more related to the presentation
than to the business logic of the application, so you do not want to
have them in your DSD and have all your applications generate them and
return them.

The option B<RayAppStyleParamModule> specifies a module name from
which a B<handler> function will be called for every request that goes
to the postprocessing stage. It will be passed the DSD object and the
same arguments as the application B<handler> (those returned by
B<RayAppInputModule>) and it should return a list of key => value
pairs that will be passed to the stylesheet.

A simple style parameter module might look like this:

	package Application::Style_params;
	sub handler {
		my ($dsd, $dbh, $q) = @_;
		return (
			my_full_url => $q->url( -full => 1 ),
			my_relative_url => $q->url( -relative => 1 ),
			dbuser => $dbh->{'Username'},
                );
	}
	1;

and in the XSLT you will get to them for example via

	<xsl:value-of select="$my_relative_url"/>

=item RayAppStyleStaticParams / RAYAPP_STYLE_STATIC_PARAMS

When a static .xml file is processed into HTML, the XSL
transformation is run, even if there was no application invocation
in the process. Normally, the B<handler> of module specified by
B<RayAppInputModule> would not be run in this case. If you want the
module to be run even in this case (thus generating input argument for
the B<RayAppStyleParamModule> module), set this option to true.

=head2 The applications

Having the Web server set up, you can write your first application
in B<RayApp> manner. For start, a simplistic application which only
returns two values will be enough.

First the DSD file, /opt/www/app.dsd:

	<?xml version="1.0"?>
	<root>
		<_param name="name"/>
		<name/>
		<time/>
	</root>

The application will accept one parameter, B<name> and will return
hash with two values, B<name> and B<time>. The code in
/opt/www/app.mpl can be

	sub handler {
		my ($dbh, $q) = @_;
		return {
			name => scalar($q->param('name')),
			time => time,
		};
	}
	1;

Note that the B<$dbh> and B<$q> values are generated by the module
specified by B<RayAppInputModule>.

The application returns a hash with two elements. A request for

	http://server/sub/app.xml?name=Peter

should return

	<?xml version="1.0"?>
	<root>
		<name>Peter</name>
		<time>1075057209</time>
	</root>

Adding the /opt/www/app.xsl file with XSLT templates should be
easy now.

=head1 SEE ALSO

RayApp::DSD(3), RayApp::Request(3)

=head1 AUTHOR

Copyright (c) Jan Pazdziora 2001--2006

=head1 VERSION

This documentation is believed to describe accurately B<RayApp>
version 2.004.

