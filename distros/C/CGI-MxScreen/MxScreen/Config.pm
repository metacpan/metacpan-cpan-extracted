# -*- Mode: perl -*-
#
# $Id: Config.pm,v 0.1 2001/04/22 17:57:03 ram Exp $
#
#  Copyright (c) 1998-2001, Raphael Manfredi
#  Copyright (c) 2000-2001, Christophe Dehaudt
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#
# HISTORY
# $Log: Config.pm,v $
# Revision 0.1  2001/04/22 17:57:03  ram
# Baseline for first Alpha release.
#
# $EndLog$
#

use strict;

#
# CGI::MxScreen run-time configuration, factorized.
#

package CGI::MxScreen::Config;

use Log::Agent;
use Carp::Datum;
require CGI;

use FindBin qw($Bin);
BEGIN {$Bin = $1 if $Bin =~ /^(\S+)$/;}	# untaint

#
# import
#
# Compile-time processing hook.
#
# The $config parameter may be either a "filename.pl" (naming scheme which
# properly intuits it has to be a syntactically correct perl file which can
# be safely required) or a HASH reference.
#
# It it's a file, it is required in the dynamic CGI::MxScreen::cf namepace.
#
# If it's a HASH reference, each key sets a configuration variable.
# Furthermore, if the special FILE key is set, its value is taken as
# a file to be required before setting. This allows one to refine a common
# configuration for specific purposes.
#
# NB: Any '-' in front of the keys is stripped.  This enables the use of
# Perl's automatic quoting of -words.
#
# Therefore, the following are strictly equivalent:
#
#	use CGI::MxScreen::Config "./filename.pl";
#	use CGI::MxScreen::Config ({ -FILE => "./filename.pl" });
#
sub import {
	DFEATURE my $f_;
	my ($module, $config) = @_;
	$CGI::MxScreen::cf::bindir = $Bin;
	set_defaults();
	if (ref $config eq 'HASH') {
		my $file = $config->{'-FILE'} || $config->{'FILE'};
		load_file($file) if $file;			# File guaranteed to load before
		load_hash($config);					# any hash configuration is made
	} else {
		load_file($config);
	}
	configure();							# Runtime configuration
	return DVOID;
}

#
# load_file
#
# Load specified file
#
sub load_file {
	DFEATURE my $f_;
	my ($file) = @_;
	$file = "$Bin/$file" unless $file =~ m|^/|;
	logdie "can't read config file $file: $!" unless -r $file;
	$CGI::MxScreen::cf::config = $file;
	eval {
		local $SIG{__DIE__};
		local $SIG{__WARN__};
		package CGI::MxScreen::cf;
		require $CGI::MxScreen::cf::config;	# Keep trace of which one it was
	};
	logdie "can't load config file $file: $@" if chop $@;
	$CGI::MxScreen::cf::_configured = 0;	# Signals: don't set defaults
	return DVOID;
}

#
# load_hash
#
# Load all keys as CGI::MxScreen::cf scalar variables.
# Leading '-' in keys are stripped and FILE is skipped.
#
sub load_hash {
	DFEATURE my $f_;
	my ($h) = @_;
	while (my ($var, $value) = each %$h) {
		$var =~ s/^-//;
		next if $var eq 'FILE';
		no strict 'refs';
		${"CGI::MxScreen::cf::$var"} = $value;
	}
	$CGI::MxScreen::cf::_configured = 0;	# Signals: don't set defaults
	return DVOID;
}

#
# set_defaults
#
# Set configuration defaults.
#
sub set_defaults {
	DFEATURE my $f_;
	{
		package CGI::MxScreen::cf;
		no strict 'vars';

		$fatals_to_browser = 1;
		$disable_upload = 1;
		$view_source = 1;
		$mx_check_vars = 1;
		$mx_buffer_stdout = 1;
	}
	return DVOID;
}

#
# is_configured
#
# Returns true when configuration was performed.
#
sub is_configured {
	DFEATURE my $f_;
	return DVAL
		defined $CGI::MxScreen::cf::_configured &&
		$CGI::MxScreen::cf::_configured;
}

#
# configure
#
# Perform runtime configuration.
# This routine is called by import(), i.e. is ususally run during compilation
# of the main script.
#
sub configure {
	DFEATURE my $f_;

	#
	# If they did not perform any customization already and called us
	# directly, set some defaults.
	#

	if (defined $CGI::MxScreen::cf::_configured) {
		return DVOID if $CGI::MxScreen::cf::_configured;
	} else {
		set_defaults();
	}

	#
	# "chdir" is the first thing we process
	#
	if (length $CGI::MxScreen::cf::chdir) {
		my $dir = $CGI::MxScreen::cf::chdir;
		logdie "invalid chdir directory $dir: $!" unless -d $dir;
		$dir = $1 if $dir =~ /^(.*)$/;		# untaint
		chdir($dir) || logdie "cannot chdir to '$dir': $!";
	}

	#
	# "path" -- recall we should be running in taint mode
	#

	$ENV{PATH} = $CGI::MxScreen::cf::path if defined $CGI::MxScreen::cf::path;

	#
	# "libpath" is handled via a manual "use lib" import.
	#

	if (length $CGI::MxScreen::cf::libpath) {
		my @libs = split(/:/, $CGI::MxScreen::cf::libpath);
		require lib;
		lib->import(@libs);
	}

	#
	# Log::Agent -- Application level dispatch
	#

	require Log::Agent::Driver::File;

	#
	# "logdir" and "logfile" (may use %s for $me)
	#

	my $me;
	($me = $0) =~ s|.*/(.*)|$1|;
	$me = $1 if $me =~ /^(.*)$/;			# untaint

	my ($logfile, $logchannels);
	my $logdir = $CGI::MxScreen::cf::logdir || ".";

	logdie "invalid logging directory $logdir: $!" unless -d $logdir;
	$logdir = $1 if $logdir =~ /^(.*)$/;	# untaint

	if (defined $CGI::MxScreen::cf::logfile) {
		my $fmt = $CGI::MxScreen::cf::logfile;
		$fmt = $1 if $fmt =~ /^(.*)$/;		# untaint
		$logfile = $fmt eq "" ? "$me.log" : sprintf($fmt, $me);
		$logfile = "$logdir/$logfile" unless $logfile =~ m|^/|;
	}

	#
	# "logchannels" (may use %s for $me)
	#

	if (ref $CGI::MxScreen::cf::logchannels) {
		my $channels = $CGI::MxScreen::cf::logchannels;
		$channels = {
			'error'		=> "%s.err",
			'output'	=> "%s.out",
			'debug'		=> "%s.dbg",
		} unless scalar keys %$channels;
		foreach my $chan (keys %$channels) {
			my $file = sprintf($channels->{$chan}, $me);
			$file = "$logdir/$file" unless $file =~ m|^/|;
			$channels->{$chan} = $file;
		}
		$logchannels = $channels;
	}

	#
	# "log_maxsize" and "log_maxtime"
	#

	my $rotate;

	if (
		defined $CGI::MxScreen::cf::log_maxsize ||
		defined $CGI::MxScreen::cf::log_maxtime
	) {
		require Log::Agent::Rotate;
		my $keep = 7;
		$keep = $CGI::MxScreen::cf::log_backlog
			if defined $CGI::MxScreen::cf::log_backlog &&
			$CGI::MxScreen::cf::log_backlog >= 0;

		$rotate = Log::Agent::Rotate->make(
			-backlog		=> $keep,
			-unzipped		=> $keep,	# don't gzip, could cause some delay
			-is_alone		=> 0,
			-max_size		=> $CGI::MxScreen::cf::log_maxsize,
			-max_time		=> $CGI::MxScreen::cf::log_maxtime,
			-single_host	=> $CGI::MxScreen::cf::log_single_host,
		);
	}

	#
	# Create driver
	#

	my $driver;

	if (defined $logfile || defined $logchannels) {
		my @dest = defined $logchannels ?
			(-channels	=> $logchannels) :
			(-file		=> $logfile);
		$driver = Log::Agent::Driver::File->make(
			-prefix		=> $me,
			-stampfmt	=> $CGI::MxScreen::cf::logstamp || "own",
			-showpid	=> 1,
			-duperr		=> 1,
			-rotate		=> $rotate,
			@dest,
		);
	} else {
		# Logs will go to the server, force the "date" format
		$driver = Log::Agent::Driver::File->make(
			-prefix     => $me,
			-stampfmt   => "date",
			-showpid    => 1,
			-file       => '>&STDERR',
			-magic_open => 1,
		);
	}

	#
	# "loglevel" and "logdebug"
	#
	logconfig(-prefix => $me, -driver => $driver,
		-trace => $CGI::MxScreen::cf::loglevel || 0,
		-debug => $CGI::MxScreen::cf::logdebug || 0,
	);

	#
	# CGI::MxScreen logging
	#

	if (defined $CGI::MxScreen::cf::mx_logfile) {
		require Log::Agent::Logger;
		require Log::Agent::Channel::File;

		my $fmt = $CGI::MxScreen::cf::mx_logfile;
		$fmt = $1 if $fmt =~ /^(.*)$/;		# untaint
		my $file = $fmt eq "" ? "$me.log" : sprintf($fmt, $me);
		$file = "$logdir/$file" unless $file =~ m|^/|;

		my $channel = Log::Agent::Channel::File->make(
			-prefix		=> $me,
			-stampfmt	=> "own",
			-filename	=> $file,
			-rotate		=> $rotate,
		);

		$CGI::MxScreen::Config::LOG = Log::Agent::Logger->make(
			-channel	=> $channel,
			-max_prio	=> $CGI::MxScreen::cf::mx_loglevel || "debug",
		);
	}

	#
	# CGI::MxScreen session handling
	#

	if (defined $CGI::MxScreen::cf::mx_serializer) {
		my $ary = $CGI::MxScreen::cf::mx_serializer;
		if (ref $ary eq 'ARRAY') {
			my ($type, @args) = @$ary;
			$type =~ s/^\+/CGI::MxScreen::Serializer::/;
			eval "require $type";
			if (chop $@) {
				logerr "can't load $type: $@";
			} else {
				my $s = $CGI::MxScreen::Config::SERIALIZER = $type->make(@args);
				logwarn "mx_serializer defined an unexpected type $s"
					unless $s->isa("CGI::MxScreen::Serializer");
			}
		} else {
			logerr "ignoring mx_serializer: not an arrray ref!";
		}
	}

	unless (ref $CGI::MxScreen::Config::SERIALIZER) {
		require CGI::MxScreen::Serializer::Storable;
		$CGI::MxScreen::Config::SERIALIZER =
			CGI::MxScreen::Serializer::Storable->make();
	}

	if (defined $CGI::MxScreen::cf::mx_medium) {
		my $ary = $CGI::MxScreen::cf::mx_medium;
		if (ref $ary eq 'ARRAY') {
			my ($type, @args) = @$ary;
			$type =~ s/^\+/CGI::MxScreen::Session::Medium::/;
			eval "require $type";
			if (chop $@) {
				logerr "can't load $type: $@";
			} else {
				my $s = $CGI::MxScreen::Config::MEDIUM = $type->make(@args);
				logwarn "mx_medium defined an unexpected type $s"
					unless $s->isa("CGI::MxScreen::Session::Medium");
			}
		} else {
			logerr "ignoring mx_medium: not an arrray ref!";
		}
	}

	unless (ref $CGI::MxScreen::Config::MEDIUM) {
		require CGI::MxScreen::Session::Medium::Browser;
		$CGI::MxScreen::Config::MEDIUM =
			CGI::MxScreen::Session::Medium::Browser->make(
				-key	=> "that's my unsecure _key_"
			);
	}

	#
	# Carp::Datum configuration
	#

	Carp::Datum->import($CGI::MxScreen::cf::datum_on ? "on" : "off");
	if (defined $CGI::MxScreen::cf::datum_config) {
		my $datum_config = $CGI::MxScreen::cf::datum_config;
		$datum_config = "$Bin/$datum_config" unless $datum_config =~ m|^/|;
		DLOAD_CONFIG(-file => $datum_config) if -f $datum_config;
	}

	#
	# "disable_upload" and "post_max"
	#

	$CGI::DISABLE_UPLOADS = 1
		if $CGI::MxScreen::cf::disable_upload;
	$CGI::POST_MAX = $CGI::MxScreen::cf::post_max || 1024 * 1024;

	#
	# "fatals_to_browser" and "fatal_message"
	#

	if ($CGI::MxScreen::cf::fatals_to_browser) {
		require CGI::Carp;
		CGI::Carp->import('fatalsToBrowser');
		CGI::Carp::set_message($CGI::MxScreen::cf::fatal_message)
			if $CGI::MxScreen::cf::fatal_message;
	}

	#
	# "cgi_carpout"
	#

	if (-t STDIN && -t STDOUT) {		# Debug mode anyway!
		require CGI::Carp;
		CGI::Carp::carpout(\*STDOUT);
	} elsif ($CGI::MxScreen::cf::cgi_carpout && defined $logfile) {
		local *FH;
		if (open(FH, ">> $logfile")) {
			select((select(FH), $| = 1)[0]);
			CGI::Carp::carpout(\*FH);
		} else {
			CGI::Carp::carp("can't append to $logfile: $!");
		}
	}

	#
	# "view_source" -- produce <VIEW SOURCE>-able HTML
	#

	$\ = "\n" unless
		defined($CGI::MxScreen::cf::view_source) &&
		!$CGI::MxScreen::cf::view_source;

	$CGI::MxScreen::cf::_configured = 1;		# Mark as "configured"

	return DVOID;
}

1;	# for require

=head1 NAME

CGI::MxScreen::Config - configuration for CGI::MxScreen

=head1 SYNOPSIS

 use CGI::MxScreen::Config "./filename.pl";
 use CGI::MxScreen::Config ({ -FILE => "./filename.pl" });

 use CGI::MxScreen::Config ({
     -FILE              => "./filename.pl",  # Common init
     -disable_upload    => 0,                # Supersede common init
     -fatals_to_browser => 0,
     -loglevel          => "debug",
 });

=head1 DESCRIPTION

The CGI::MxScreen::Config module is meant to provide compile-time
configuration for the CGI::MxScreen framework.

Configuration parameters may be set in a Perl file (which is loaded via
C<require>, so it must end-up being syntactically correct and return a
true value).  Inclusion happens in the C<CGI::MxScreen::cf> namespace, and
therefore you must not use any C<package> declaration in that file.

Configuration parameters may also be specified as keys within a hash ref
object, and may be prefixed by a C<-> character to benefit from Perl's
auto-quoting.  That character is not part of the variable however, and
case matters.

Note that you cannot say:

    use CGI::MxScreen::Config { -loglevel => "notice" };    # WRONG

because it is synctactically incorrect.  You must enclose the hash ref
within parenthesis, as in:

    use CGI::MxScreen::Config ({ -loglevel => "notice" });  # RIGHT

The reason we take a hash ref as first argument and not a list of values
is to leave room for further extensions.

The special C<-FILE> key points to a filename which is loaded B<before>
processing the remaining keys.  Therefore, it is possible to override
some variables on a per-script basis, yet share customized settings.

The CGI::MxScreen module uses C<Log::Agent> for logging, with the File driver.
Some options like C<logfile> and C<loglevel> may be used to customize its
behaviour.  By default, logging will be redirected to STDERR.

There's currently no option to choose another logging driver like Syslog,
but this can be added easily if there's some demand.

=head1 INTERFACE

The following configuration variables are available, in alphabetical
order:

=over

=item bindir

A preset variable, indicating the location of the CGI script.

=item cgi_carpout

When set to true and C<logfile> is also defined, arrange for C<CGI::Carp>
to redirect errors to that logfile.

=item chdir

If set, attempt to chdir() to the specified directory very early during
C<CGI::MxScreen::Config> processing.

=item config

A read-only variable, set to the filename that was used to load configuration
from, if any.

=item datum_config

When set to a non-null string, refers to the configuration file to
load for C<Carp::Datum> dynamic configuration.  See L<Carp::Datum::Cfg> for
details.

=item datum_on

When true, activates C<Carp::Datum>.  Note that the C<datum_config> variable
is used to load the configuration even when this variable is set to false.

=item disable_upload

Sets C<$CGI::DISABLE_UPLOADS> to true if set.

=item fatal_message

The fatal message to be used by C<CGI::Carp> when C<fatals_to_browser> is set.
See L<CGI::Carp> for details.

=item fatals_to_browser

When set to true, tells C<CGI::Carp> to redirect fatal errors to the browser.
This is useful during the debugging phase.  It is true by default.

=item libdir

A set of directories to be added to @INC via C<"use lib">, in the order given.
The format is the same as the one used by the PERL5LIB variable.

=item logchannels

The hash ref to give to C<Log::Agent::Driver::File> via C<-channels>.
Values are printf patterns where "%s" stands for the script's basename.
This variable supersedes any setting in C<logfile>.

When an empty logchannels hash ref is given, it is interpreted as if the
following was given instead:

  {
      'error'     => "%s.err",
      'output'    => "%s.out",
      'debug'     => "%s.dbg",
  }

where "%s" stands for "$me", the basename of the script.

See L<Log::Agent::Driver::File> for more information.

=item logdebug

Sets the value of the C<-debug> flag for logconfig().  See L<Log::Agent>
for allowed values.

=item logdir

This variable is used to anchor logfiles to some directory when C<logfile>
does not specify a full path.  If unset, it defaults to ".".  Note that
when C<chdir> is used, "." is the directory where we chdir-ed to.

=item logfile

The path of the file where logging should go.  Leaving all C<logdir>,
C<logfile> and C<logchannels> empty will cause logging to go to STDERR,
which should end-up in the server's error log.

If left empty but C<logdir> was set, the value of "$me.log" is assummed,
where "$me" stands for the script's basename.  You may use "%s" in the
name to stand for "$me" (an sprintf() is called, so any % you wish to
be part of the logfile name should be written as %%).

=item loglevel

Specify the loglevel for tracing (DTRACE) when the debug mode of
C<Carp::Datum> is turned off.
Possible values are: 
emergency, alert, critical, error, warning, notice, info, debug

See L<Log::Agent> for further details.

=item logstamp

The C<Log::Agent> timestamping format to use.  Defaults to "own" when a
logfile is used, and is forced to "date" when logs are redirected to the server
logs.

=item log_backlog

The amount of backlog you wish to keep after logfile rotation.  Backlog
is never compressed, because it is currently performed synchronously
by C<Log::Agent::Rotate> and that could cause huge delays when C<log_maxsize>
is big, impacting your script response time.

Defaults to 7.

=item log_maxsize

The maximum size in bytes for the logfile.  See L<Log::Agent::Rotate>.

=item log_maxtime

The maximum time a logfile can be kept open before being rotated.
See L<Log::Agent::Rotate> for the allowed syntax.

=item log_single_host

By default, C<CGI::MxScreen> assumes nothing upon how logfiles can be accessed.
When you know they are only accessed from ONE machine, you can set this
variable to I<true>, and it will speed up locking done via C<LockFile::Simple>
during log rotations.

=item mx_buffer_stdout

When true, all regular output to STDOUT is saved away, and the context will
be emitted before any other form output (when saved within the form).  This
has a slight overhead cost since we have to copy things, but has two nice
advantages: in case of fatal errors, the regular output is not mixed with
the CGI::Carp output; and the widgets appear on their browser when the
context is already emitted, meaning that even if they press a submit button
before they have got the whole form, we'll be able to process it sanely.

Default is I<true>.

=item mx_check_vars

Boolean flag, telling whether C<CGI::MxScreen> should trap any access
to unknown keys within the screen global context (accessed through
C<$screen-E<gt>vars>) and make them fatal errors.

Default is I<true>.

=item mx_logfile

The C<CGI::MxScreen> application logfile, where the module logs what is
happening.

=item mx_loglevel

The C<CGI::MxScreen> application loglevel.  Syslog priorities are used,
and the specified level is the maximum priority logged.

Here is the list of the various things logged, and their level:

    Level   What
    ------  -------------------------------------------
    emerg   
    alert   Internal errors
    crit    Display errors
    err     Callback failures
    warn    Current state, session info
    notice  Button pressed, state changes
    info    User-agent (1st time), global time spent
    debug   Detailed statistics

=item mx_medium

Defines the medium used to save the application context.  It takes an
ARRAY ref defining the medium type (must inherit from
C<CGI::MxScreen::Session::Medium>) followed by the creation routine arguments.

The first array item (the medium type) is a string which can be shortened:
the "CGI::MxScreen::Session::Medium::" leading part may be replaced by '+',
which will be automatically replaced.

If not specified, it defaults to:

  [
      "+Browser",
      -key => "an unsecure key -- not this one",
  ]

meaning the session contexts will be saved within the browser.  This
is for convenience only, but when releasing for production, you should never
rely on this default and specify a sensible encryption key, to prevent
eavesdropping and tampering on the context.

See L<CGI::MxScreen::Session::Medium> for the list of available media.

=item mx_serializer

Defines the serializer to use to create a frozen context image.
It takes an ARRAY ref defining the medium type (must inherit from
C<CGI::MxScreen::Serializer>) followed by the creation routine arguments.

The first array item (the serializer type) is a string which can be shortened:
the "CGI::MxScreen::Serializer::" leading part may be replaced by '+',
which will be automatically replaced.

If not specified, this defaults to:

  ["+Storable"]

An alternative when using the browser to store sessions (see C<mx_medium>)
is to use:

  [
      "+Storable",
      -shared     => 0,
      -compress   => 1,
  ]

to create a more compact representation, and reduce network traffic at the
cost of more CPU time spent on the server.

See L<CGI::MxScreen::Serializer> for the list of supported serializers.

=item path

If set, its value is used to set the PATH environment variable.  Remember
that CGI scripts should always be run with taint checks enabled, and that
explicitely setting the PATH is necessary to be able to run commands
via system().

=item post_max

The value of this variable is used to set C<$CGI::POST_MAX>.  It defaults
to 1 Mbyte when not set.

=item view_source

By default, the $\ variable is set to "\n" so that all print statements
end-up being on their own line.  This tends to produce view-able source code.
Setting this to 0 avoids touching $\.  You may of course add your own "\n"
to each print statement, but this is not recommended.

=head1 EXAMPLE

Here is a configuration file example:

    $disable_upload = 1;
    $post_max = 10 * 1024;
    
    $fatals_to_browser = 1;
    
    $datum_config = "debug.cf";
    $datum_on = 1;
    
    $logdir = "/home/ram/public_html/log";
    $logfile = "%s.log";
    $logstamp = "own";
    $loglevel = "warn";
    $logdebug = 0;
    $logchannels = {} if $datum_on;  # take defaults, supersedes $logfile
    
    $cgi_carpout = 1;
    $view_source = 1;
    
    $path = "/bin:/usr/bin:/home/ram/bin/scripts:/home/ram/bin/i386";
    $chdir = "/home/ram/public_html/scripts";
    $libpath = "$bindir/lib:/usr/local/cgilib";

	$mx_logfile = "mx.log";
	$mx_loglevel = "info";
	$mx_medium = ["+Browser", -key => "shush! it's a secret" ];
	$mx_serializer = ["+Storable", -compress => 1];
    
    1;

=head1 AUTHOR

Raphael Manfredi F<E<lt>Raphael_Manfredi@pobox.comE<gt>>

=head1 SEE ALSO

CGI::Carp(3), CGI::MxScreen(3),
CGI::MxScreen::Serializer(3), CGI::MxScreen::Session::Medium(3),
Log::Agent(3).

=cut

