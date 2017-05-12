package CGI::Snapp::Dispatch;

use strict;
use warnings;

use Carp;

use CGI::PSGI;

use Class::Load ':all';

use HTTP::Exception;

use Log::Handler;

use Moo;

use Try::Tiny;

has logger =>
(
	is       => 'rw',
	default  => sub{return ''},
	required => 0,
);

has return_type =>
(
	is       => 'rw',
	default  => sub{return 0},
	required => 0,
);

our $VERSION = '2.00';

# --------------------------------------------------

sub as_psgi
{
	my($self, @args)   = @_;

	$self -> log(debug => 'as_psgi(...)');

	croak "Parameter \@args to dispatch() must be a hashref or a hash\n" if ( ($#args > 0) && ($#args % 2 != 1) );

	my($options) = ref $args[0] eq 'HASH' ? $args[0] : {@args};
	my($args)    = $self -> _merge_args($options);

	croak "Missing dispatch table, or it's not an arrayref\n" if (! $$args{table} || ref $$args{table} ne 'ARRAY');

	my($output);

	return
		sub
		{
			my($env)         = shift @_;
			my($http_method) = $$env{REQUEST_METHOD};
			my($named_args)  = $self -> _parse_path($http_method, $self -> _clean_path($$env{PATH_INFO}, $args), $$args{table});

			HTTP::Exception -> throw(404, status_message => 'Not Found') if (! $$named_args{app});
			HTTP::Exception -> throw(400, status_message => "Invalid characters in run mode name '$$named_args{rm}'") if ($$named_args{rm} && ($$named_args{rm} !~ m/^([a-zA-Z_][\w\']+)$/) );

			# If _prepare() croaks, error number is 404.
			# If run() croaks, error number is 500,
			# because the error message will not match /^\d+$/.

			try
			{
				my($module, $rm, $args_to_new) = $self -> _prepare($http_method, $args, $named_args);
				$$args_to_new{_psgi}           = 1; # Required.
				$$args_to_new{QUERY}           = CGI::PSGI -> new($env) if (! $$args_to_new{QUERY});
				my($app)                       = $module -> new(%$args_to_new);

				$app -> mode_param(sub {return $rm}) if ($rm);

				$output = $app -> run;
			}
			catch
			{
				my($error)   = $_ =~ /^404/ ? 404 : 500;
				my($message) = $error == 404 ? 'Not Found' : 'Internal Server Error';

				HTTP::Exception -> throw($error, status_message => $message);
			};

			return $output;
		};

} # End of as_psgi.

# --------------------------------------------------

sub _clean_path
{
	my($self, $path_info, $args) = @_;
	$path_info = '' if (! defined $path_info || length $path_info == 0);

	$self -> log(debug => "_clean_path($path_info, ...)");

	$path_info = $$args{default} if (! defined $path_info || ($path_info eq '/') );
	$path_info = ''              if (! defined $path_info || length $path_info == 0);

	# Standardize the format of the path info, to simplify processing in _parse_path().

	$path_info = "/$path_info" if (index($path_info, '/') != 0);
	$path_info = "$path_info/" if (substr($path_info, -1) ne '/');

	$self -> log(debug => "Path info '$path_info'");

	return $path_info;

} # End of _clean_path.

# --------------------------------------------------

sub dispatch
{
	my($self, @args)   = @_;

	$self -> log(debug => 'dispatch(...)');

	croak "Parameter \@args to dispatch() must be a hashref or a hash\n" if ( ($#args > 0) && ($#args % 2 != 1) );

	my($options) = ref $args[0] eq 'HASH' ? $args[0] : {@args};
	my($args)    = $self -> _merge_args($options);

	croak "Missing dispatch table, or it's not an arrayref\n" if (! $$args{table} || ref $$args{table} ne 'ARRAY');

	# Return the args if the caller is testing.

	return $args if ($self -> return_type == 1);

	my($error);
	my($output);

	try
	{
		my($http_method) = $ENV{HTTP_REQUEST_METHOD} || $ENV{REQUEST_METHOD};
		my($named_args)  = $self -> _parse_path($http_method, $self -> _clean_path($ENV{PATH_INFO}, $args), $$args{table});

		croak 404 if (! $$named_args{app});
		croak 400 if ($$named_args{rm} && ($$named_args{rm} !~ m/^([a-zA-Z_][\w\']+)$/) );

		if ($self -> return_type == 2)
		{
			# Return the args if the caller is testing.
			# Warning: You can't just return when within 'try',
			# or your return value is discarded. Hence this 'if'.

			$output = $named_args;
		}
		else
		{
			# If run() croaks, _http_error() uses error number 500,
			# because the error message will not match /^\d+$/.

			my($module, $rm, $args_to_new) = $self -> _prepare($http_method, $args, $named_args);
			my($app) = $module -> new(%$args_to_new);

			$app -> mode_param(sub {return $rm}) if ($rm);

			$output = $app -> run;
		}
	}
	catch
	{
		# Remove any trailing text from error number, placed there by croak.

		($error = $_) =~ s/^(\d+).+/$1/s;
		$error        = 500 if (! $error);
	};

	return $error ? $self -> _http_error($$args{error_document}, $error) : $output;

} # End of dispatch.

# --------------------------------------------------

sub dispatch_args
{
	my($self, $args) = @_;

	return
	{
		args_to_new => {},
		default     => '',
		prefix      => '',
		table       =>
		[
			':app'     => {},
			':app/:rm' => {},
		],
	};

} # End of dispatch_args.

# --------------------------------------------------

sub _http_error
{
	my($self, $error_document, $error_number) = @_;

	$self -> log(debug => "_http_error(..., $error_number)");

	$error_document ||= '';
	$error_number   = 500 if ($error_number !~ /^\d+/);

	$self -> log(debug => "Processing HTTP error $error_number");

	my($output);
	my($url);

	($output, $url) = $self -> _parse_error_document($error_document, $error_number) if ($error_document);

	# Now process either the $output or the $url.

	my(%error_message) =
	(
		400 => 'Bad Request',
		404 => 'Not Found',
		500 => 'Internal Server Error',
	);
	my($message) = "$error_number $error_message{$error_number}";

	if ($url)
	{
		# Fabricate a somewhat malformed header. There'll be no error in the access log,
		# but browers display the $url's document, and the old url in the address bar.

		$output = "HTTP/1.0 $message\nLocation: $url\n\n";
	}
	else
	{
		# Fabricate a HTML document if necessary.

		my($header)                  = '';
		local $ENV{SERVER_ADMIN}     ||= '';
		local $ENV{SERVER_SIGNATURE} ||= '';

		$output = <<EOS if (! $output);
<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML 2.0//EN">
<html>
<head>
	<title>$message</title>
</head>
<body>
	$header
	<h1>$message</h1>
	<p>
		<address>
		$ENV{SERVER_ADMIN}
		</address>
	</p>
	<hr>
	$ENV{SERVER_SIGNATURE}
</body>
</html>
EOS
		$header = "Status: $message\nContent-type: text/" .
			($output =~ /^(?:<html|<!doctype html)/i ? "html\n\n" : "plain\n\n");

		# Work around an IE bug. 'IE bug' is a tautology if I ever saw one...

		$output .= ' ' x (520 - length $output) if (length $output < 520);
		$output = $header . $output;
	}

	return $output;

} # End of _http_error.

# --------------------------------------------------

sub log
{
	my($self, $level, $s) = @_;

	croak "Error: No level defined in call to log()\n" if (! defined $level);

	$self -> logger -> $level($s) if ($self -> logger);

} # End of log.

# --------------------------------------------------

sub _merge_args
{
	my($self, $args) = @_;

	$self -> log(debug => '_merge_args(...)');

	my($extra_args) = $self -> dispatch_args;
	my($final_args) = {};

	# Process all args to dispatch().

	for my $key (keys %$args)
	{
		# Merge args_to_new because it's a hashref.

		if ($key eq 'args_to_new')
		{
			$$final_args{$key} = {};

			# Process all args to this key (args_to_new).

			for my $sub_key (keys %{$$args{$key} })
			{
				# If the sub key points to a hashref, merge data.

				if (ref $$args{$key}{$sub_key} eq 'HASH')
				{
					# But only merge if dispatch_args() returned data. Otherwise, overwrite.

					if (exists $$extra_args{$key}{$sub_key})
					{
						$$final_args{$key}{$sub_key} = {%{$$extra_args{$key}{$sub_key} }, %{$$args{$key}{$sub_key} } };
					}
					else
					{
						$$final_args{$key}{$sub_key} = {%{$$args{$key}{$sub_key} } };
					}
				}
				else
				{
					$$final_args{$key}{$sub_key} = defined $$args{$key}{$sub_key} ? $$args{$key}{$sub_key} : $$extra_args{$key}{$sub_key};
				}
			}
		}
		else
		{
			# Overwrite when not a hashref.

			$$final_args{$key} = $$args{$key};
		}
	}

	# Now process args returned from dispatch_args() but not sent to this method.

	for my $key (keys %$extra_args)
	{
		# If the sub key points to a hashref, merge data.

		if (ref $$extra_args{$key} eq 'HASH')
		{
			# But only merge if $final_args contains data. Otherwise, overwrite.

			if (exists $$final_args{$key})
			{
				# But PARAMS itself is a hashref key.

				if ($$final_args{$key}{PARAMS})
				{
					if (exists $$extra_args{$key}{PARAMS})
					{
						$$final_args{$key}{PARAMS} = {%{$$final_args{$key}{PARAMS} }, %{$$extra_args{$key}{PARAMS} } };
					}
				}
				else
				{
					$$final_args{$key}= {%{$$final_args{$key} }, %{$$extra_args{$key} } };
				}
			}
			else
			{
				$$final_args{$key} = $$extra_args{$key};
			}
		}
		else
		{
			# Overwrite since $$args{$key} does not exist.

			$$final_args{$key} = $$extra_args{$key} if (! exists $$args{$key});
		}
	}

	return $final_args;

}	# End of _merge_args.

# --------------------------------------------------

sub _parse_error_document
{
	my($self, $error_document, $error_number) = @_;

	$self -> log(debug => "_parse_error_document(..., $error_number)");

	# Jam the error number into the document, if the latter contains %s.

	my($s) = sprintf($error_document, $error_number);

	my($output);
	my($url);

	if (index($s, '"') == 0)
	{
		# It's a customised error string.
		# Discard the leading " & use it as the output.

		$output = substr($s, 1);
	}
	elsif (index($s, '<') == 0)
	{
		# It's a local file, which is - hopefully - secure. Read it as the output.
		# If we can't read it, $output will remain undef.

		require File::Spec;

		my($doc_root) = $ENV{DOCUMENT_ROOT};
		$s            = substr($s, 1);
		$s            = File::Spec -> catdir($doc_root, $s) if ($doc_root);

		$self -> log(debug => "Reading file $s");

		if (-f $s && open(INX, '<', $s) )
		{
			local $/ = undef;
			$output  = <INX>;

			close INX;
		}
		else
		{
			carp "[Dispatch] Unable to open error_document file $s";
		}
	}
	else
	{
		# It's neither customised error string nor file name.
		# Assume it's a url. Keep it separate from $output for later.

		$url = $s;
	}

	$self -> log(debug => "Redirecting HTTP error $error_number to $url")    if ($url);
	$self -> log(debug => "Displaying message for HTTP error $error_number") if ($output);

	return ($output, $url);

} # End of _parse_error_document.

# --------------------------------------------------

sub _parse_path
{
	my($self, $http_method, $path_info, $table) = @_;

	$self -> log(debug => "_parse_path($path_info, ...)");

	# Compare each rule in the table with the path_info, and process the 1st match.

	my($request_method_regexp, $rule);

	for (my $i = 0; $i < scalar @$table; $i += 2)
	{
		$rule = $$table[$i];

		next if (! defined $rule);

		$self -> log(debug => "Original rule '$rule'");

		# Firstly, look for a HTTP method name in the rule,
		# as something like ':app/news[post]' => {rm => 'add_news'}.

		$request_method_regexp = qr/\[([^\]]+)\]$/;

		if ($rule =~ /$request_method_regexp/)
		{
			# If the method doesn't match the rule can't possibly match.

			next if (lc $http_method ne lc $1);

			$self -> log(debug => "Matched HTTP method '$http_method'");

			# Remove the method portion from the rule.

			$rule =~ s/$request_method_regexp//;
		}

		# Standardize the format of the rule, to match the standardized path info.

		$rule = "/$rule" if (index($rule, '/') != 0);
		$rule = "$rule/" if (substr($rule, -1) ne '/');

		$self -> log(debug => "Rule is now   '$rule'");

		# Translate the rule into a regular expression, remembering where the named args are.
		# '/:foo' will become '/([^\/]*)'
		# and
		# '/:bar?' will become '/?([^\/]*)?'
		# and then remember which position it matches.

		my(@names);

		$rule =~
		s{
			(^|/)                 # Beginning, or a /.
			(:([^/\?]+)(\?)?)     # Stuff in between.
		}{
			push @names, $3;
			$1 . ($4 ? '?([^/]*)?' : '([^/]*)')
		}gxe;

		# '/*/' will become '/(.*)/$'.
		# The final '/' has been added to the end of both $rule and $path_info already.

		if ($rule =~ m{/\*/$})
		{
			$rule =~ s{/\*/$}{/(.*)/\$};

			push @names, 'dispatch_url_remainder';
		}

		$self -> log(debug => "Rule is now   '$rule'");
		$self -> log(debug => "Names in rule [" . join(', ', @names) . ']');
		$self -> log(debug => "Trying to match path info '$path_info' against rule '$$table[$i]' using regexp '$rule'");

		# If we find a match, then run with it.

		if (my @values = ($path_info =~ m#^$rule$#) )
		{
			$self -> log(debug => 'Matched!');

			my(%named_args)     = %{$$table[++$i]};
			@named_args{@names} = @values if @names;

			return {%named_args};
		}
	}

	# No rule matched the given path info.

	$self -> log(debug => 'Nothing matched');

	return {};

}	# End of _parse_path.

# --------------------------------------------------

sub _prepare
{
	my($self, $http_method, $args, $named_args) = @_;
	$http_method ||= '';

	$self -> log(debug => "_prepare($http_method, ...)");

	my($module, $prefix, $rm, $args_to_new) = delete @{$named_args}{qw(app prefix rm args_to_new)};
	$module = '' if (! defined $module); # Stop uninit warning.
	$rm     = '' if (! defined $rm);

	# If another name for dispatch_url_remainder has been set, move the value to the requested name.

	if ($$named_args{'*'})
	{
		$$named_args{$$named_args{'*'} } = $$named_args{'dispatch_url_remainder'};

		delete $$named_args{'*'};
		delete $$named_args{'dispatch_url_remainder'};
	}

	# Warning: The following statement was copied from CGI::Application::Dispatch,
	# but it does not do what you think, due to the way Perl equivalences hashrefs.
	# The symptom is that up at line 62:
	# $$args_to_new{QUERY} = CGI::PSGI -> new($env) if (! $$args_to_new{QUERY});
	# it has the effect of setting $args{args_to_new}, and not just $args_to_new.
	# That means the 'if (! $$args_to_new{QUERY})' stops a new CGI::PSGI being assigned
	# during each call of the subref, so the initial CGI::PSGI object is preserved,
	# and of course it has no CGI parameters, so no parameters are ever received :-(.

	#$args_to_new ||= $$args{args_to_new};

	if (! $args_to_new)
	{
		my(%new_args) = %{$$args{args_to_new} };
		$args_to_new  = {%new_args};
	}

	@{$$args_to_new{PARAMS} }{keys %$named_args} = values %$named_args;
	$args_to_new   = {} if (! $args_to_new);
	$module        = $self -> translate_module_name($module);
	$prefix        ||= $$args{prefix} || '';
	$module        = $prefix . '::' . $module if ($prefix);
	my($auto_rest) = defined $$named_args{auto_rest} ? $$named_args{auto_rest} : $$args{auto_rest};

	if ($auto_rest)
	{
		my($method_lc) = defined $$named_args{auto_rest_lc} ? $$named_args{auto_rest_lc} : $$args{auto_rest_lc};
		$http_method   = lc $http_method if ($method_lc);
		$rm            = length $rm ? "${rm}_$http_method" : $rm;
	}

	$self -> log(debug => "Trying to load '$module'. Run method is '$rm'");

	try_load_class $module;

	if (is_class_loaded $module)
	{
		$self -> log(debug => "Loaded '$module'");
	}
	else
	{
		croak 404;
	}

	return ($module, $rm, $args_to_new);

} # End of _prepare.

# --------------------------------------------------

sub translate_module_name
{
	my($self, $name) = @_;

	$self -> log(debug => "translate_module_name($name)");

	$name = join('::', map{ucfirst $_} split(/_/, $name) );
	$name = join('',   map{ucfirst $_} split(/-/, $name) );

	return $name;

} # End of translate_module_name.

# --------------------------------------------------

1;

=pod

=head1 NAME

CGI::Snapp::Dispatch - Dispatch requests to CGI::Snapp-based objects

=head1 Synopsis

=head2 CGI Scripts

Here is a minimal CGI instance script. I<Note the call to new()!>

	#!/usr/bin/env perl

	use CGI::Snapp::Dispatch;

	CGI::Snapp::Dispatch -> new -> dispatch;

(The use of new() is discussed in detail under L</PSGI Scripts>, just below.)

But, to override the default dispatch table, you probably want something like this:

MyApp/Dispatch.pm:

	package MyApp::Dispatch;
	parent 'CGI::Snapp::Dispatch';

	sub dispatch_args
	{
		my($self) = @_;

		return
		{
			prefix => 'MyApp',
			table  =>
			[
				''               => {app => 'Initialize', rm => 'start'},
				':app/:rm'       => {},
				'admin/:app/:rm' => {prefix => 'MyApp::Admin'},
			],
		};
	}

And then you can write ...  I<Note the call to new()!>

	#!/usr/bin/env perl

	use MyApp::Dispatch;

	MyApp::Dispatch -> new -> dispatch;

=head2 PSGI Scripts

Here is a PSGI script in production on my development machine. I<Note the call to new()!>

	#!/usr/bin/env perl
	#
	# Run with:
	# starman -l 127.0.0.1:5020 --workers 1 httpd/cgi-bin/local/wines.psgi &
	# or, for more debug output:
	# plackup -l 127.0.0.1:5020 httpd/cgi-bin/local/wines.psgi &

	use strict;
	use warnings;

	use CGI::Snapp::Dispatch;

	use Plack::Builder;

	# ---------------------

	my($app) = CGI::Snapp::Dispatch -> new -> as_psgi
	(
		prefix => 'Local::Wines::Controller', # A sub-class of CGI::Snapp.
		table  =>
		[
		''              => {app => 'Initialize', rm => 'display'},
		':app'          => {rm => 'display'},
		':app/:rm/:id?' => {},
		],
	);

	builder
	{
		enable "ContentLength";
		enable "Static",
		path => qr!^/(assets|favicon|yui)!,
		root => '/dev/shm/html'; # /dev/shm/ is Debian's RAM disk.
		$app;
	};

I<Warning!> The line my($app) = ... contains a call to L</new()>. This is definitely not the same as if you
were using L<CGI::Application::Dispatch> or L<CGI::Application::Dispatch::PSGI>. They look like this:

	my($app) = CGI::Application::Dispatch -> as_psgi

The lack of a call to new() there tells you I've implemented something very similar but different.
You have been warned...

The point of this difference is that new() returns an object, and passing that into L</as_psgi(@args)> as $self
allows the latter method to be much more sophisticated than it would otherwise be. Specifically, it can now share
a lot of code with L</dispatch(@args)>.

Lastly, if you want to use regexps to match the path info, see L<CGI::Snapp::Dispatch::Regexp>.

=head1 Description

This module provides a way to automatically look at the path info - $ENV{PATH_INFO} - of the incoming HTTP request,
and to process that path info like this:

=over 4

=item o Parse off a module name

=item o Parse off a run mode

=item o Create an instance of that module (i.e. load it)

=item o Run that instance

=item o Return the output of that run as the result of requsting that path info (i.e. module and run mode combo)

=back

Thus, it will translate a URI like this:

	/app/index.cgi/module_name/run_mode

into something that is functionally equivalent to this:

	my($app) = Module::Name -> new(...);

	$app -> mode_param(sub {return 'run_mode'});

	return $app -> run;

=head1 Distributions

This module is available as a Unix-style distro (*.tgz).

See L<http://savage.net.au/Perl-modules/html/installing-a-module.html>
for help on unpacking and installing distros.

=head1 Installation

Install L<CGI::Snapp::Dispatch> as you would for any C<Perl> module:

Run:

	cpanm CGI::Snapp::Dispatch

or run:

	sudo cpan CGI::Snapp::Dispatch

or unpack the distro, and then either:

	perl Build.PL
	./Build
	./Build test
	sudo ./Build install

or:

	perl Makefile.PL
	make (or dmake or nmake)
	make test
	make install

=head1 Constructor and Initialization

C<new()> is called as C<< my($app) = CGI::Snapp::Dispatch -> new(k1 => v1, k2 => v2, ...) >>.

It returns a new object of type C<CGI::Snapp::Dispatch>.

Key-value pairs accepted in the parameter list (see corresponding methods for details
[e.g. L</return_type([$string])>]):

=over 4

=item o logger => $aLoggerObject

Specify a logger compatible with L<Log::Handler>.

Note: This logs method calls etc inside CGI::Snapp::Dispatch.

To log within L<CGI::Snapp>, see L</How do I use my own logger object?>.

Default: '' (The empty string).

To clarify: The built-in calls to log() all use a log level of 'debug', so if your logger has 'maxlevel' set
to anything less than 'debug', nothing nothing will get logged.

'maxlevel' and 'minlevel' are discussed in L<Log::Handler#LOG-LEVELS> and L<Log::Handler::Levels>.

=item o return_type => $integer

Possible values for $integer:

=over 4

=item o 0 (zero)

dispatch() returns the output of the run mode.

This is the default.

=item o 1 (one)

dispatch() returns the hashref of args built from combining the output of dispatch_args() and the
args to dispatch().

The requested module is I<not> loaded and run. See t/args.t.

=item o 2 (two)

dispatch() returns the hashref of args build from parsing the path info.

The requested module is I<not> loaded and run. See t/args.t.

=back

Default: 0.

Note: I<return_type> is ignored by L</as_psgi(@args)>.

=back

=head1 Methods

=head2 as_psgi(@args)

Returns a L<PSGI|http://plackperl.org/>-compatible coderef which, when called, runs your sub-class of L<CGI::Snapp>
as a L<PSGI|http://plackperl.org/> app.

This works because the coderef actually calls L<CGI::Snapp/psgi_app($args_to_new)>.

See the next method, L</dispatch(@args)>, for a discussion of @args, which may be a hash or hashref.

Lastly: as_psgi() does not support the I<error_document> option the way dispatch({table => {error_document => ...} })
does. Rather, it throws errors of type L<HTTP::Exception>. Consider handling these errors with
L<Plack::Middleware::ErrorDocument> or similar.

=head2 dispatch(@args)

Returns the output generated by calling a L<CGI::Snapp>-based module.

@args is a hash or hashref of options, which includes the all-important 'table' key, to define a dispatch table.
See L</What is the structure of the dispatch table?> for details.

The unfortunate mismatch between dispatch() taking a hash and dispatch_args() taking a hashref has been copied
from L<CGI::Application::Dispatch>. But, to clean things up, L<CGI::Snapp::Dispatch> allows dispatch() to accept
a hashref. You are encouraged to always use hashrefs, to avoid confusion.

(Key => value) pairs which may appear in the hashref parameter ($args[0]):

=over

=item o args_to_new => $hashref

This is a hashref of arguments that are passed into the constructor (C<new()>) of the application.

If you wish to set parameters in your app which can be retrieved by the $self -> param($key) method, then use:

	my($app)    = CGI::Snapp::Dispatch -> new;
	my($output) = $app -> dispatch(args_to_new => {PARAMS => {key1 => 'value1'} });

This means that inside your app, $self -> param('key1') will return 'value1'.

See t/args.t's test_13(), which calls t/lib/CGI/Snapp/App1.pm's rm2().

See also t/lib/CGI/Snapp/Dispatch/SubClass1.pm's dispatch_args() for how to pass in one or more such values via
your sub-class.

=item o auto_rest => $Boolean

If 1, this tells Dispatch that you are using REST by default and that you care about which HTTP method
is being used. Dispatch will append the HTTP method name (upper case by default) to
the run mode that is determined after finding the appropriate dispatch rule. So a GET request
that translates into C<< MyApp::Module -> foo >> will become C<< MyApp::Module -> foo_GET >>.

This can be overridden on a per-rule basis in a derived class's dispatch table. See also the next option.

Default: 0.

See t/args.t test_27().

=item o auto_rest_lc => $Boolean

If 1, then in combination with I<auto_rest>, this tells Dispatch that you prefer lower cased HTTP method names.
So instead of C<foo_POST> and C<foo_GET> you'll get C<foo_post> and C<foo_get>.

See t/args.t test_28().

=item o default

Specify a value to use for the path info if one is not available.
This could be the case if the default page is selected (e.g.: '/cgi-bin/x.cgi' or perhaps '/cgi-bin/x.cgi/').

=item o error_document

Note: When using L</as_psgi(@args)>, error_document makes no sense, and is ignored.
In that case, use L<Plack::Middleware::ErrorDocument> or similar.

If this value is not provided, and something goes wrong, then Dispatch will return a '500 Internal Server Error',
using an internal HTML page. See t/args.t, test_25().

Otherwise, the value should be one of the following:

=over 4

=item o A customised error string

To use this, the string must start with a single double-quote (") character. This character
character will be trimmed from final output.

=item o A file name

To use this, the string must start with a less-than sign (<) character. This character
character will be trimmed from final output.

$ENV{DOCUMENT_ROOT}, if not empty, will be prepended to this file name.

The file will be read in and used as the error document.

See t/args.t, test_26().

=item o A URL to which the application will be redirected

This happens when the I<error_document> does not start with " or <.

=back

Note: In all 3 cases, the string may contain a '%s', which will be replaced with the error number (by sprintf).

Currently CGI::Snapp::Dispatch uses three HTTP errors:

=over 4

=item o 400 Bad Request

This is output if the run mode is not specified, or it contains an invalid character.

=item o 404 Not Found

This is output if the module name is not specified, or if there was no match with the dispatch table,
or the module could not be loaded by L<Class::Load>.

=item o 500 Internal Server Error

This is output if the application dies.

=back

See t/args.t, test_24().

=item o prefix

This option will set the string to be prepended to the name of the application
module before it is loaded and created.

For instance, consider /app/index.cgi/module_name/run_mode.

This would, by default, load and create a module named 'Module::Name'. But let's say that you
have all of your application specific modules under the 'My' namespace. If you set this option
- C<prefix> - to 'My' then it would instead load the 'My::Module::Name' application module instead.

The algorithm for converting a path info into a module name is documented in L</translate_module_name($name)>.

=item o table

In most cases, simply using Dispatch with the C<default> and C<prefix> is enough
to simplify your application and your URLs, but there are many cases where you want
more power. Enter the dispatch table (a hashref), specified here as the value of the C<table> key.

Since this table can be slightly complicated, a whole section exists on its use. Please see the L</What is the structure of the dispatch table?> section.

Examples are in the dispatch_args() method of both t/lib/CGI/Snapp/Dispatch/SubClass1.pm and
t/lib/CGI/Snapp/Dispatch/SubClass2.pm.

=back

=head2 dispatch_args($args)

Returns a hashref of args to be used by L</dispatch(@args)>.

This hashref is a dispatch table. See L</What is the structure of the dispatch table?> for details.

L</dispatch(@args)> calls this method, passing in the hash/hashref which was passed in to L</dispatch(@args)>.

Default output:

	{
		args_to_new => {},
		default     => '',
		prefix      => '',
		table       =>
		[
			':app'      => {},
			':app/:rm'  => {},
		],
	}

This is the perfect method to override when creating a subclass to provide a richer L</What is the structure of the dispatch table?>.

See CGI::Snapp::Dispatch::SubClass1 and CGI::Snapp::Dispatch::SubClass2, both under t/lib/. These modules are
exercised by t/args.t.

=head2 new()

See L</Constructor and Initialization> for details on the parameters accepted by L</new()>.

Returns an object of type L<CGI::Snapp::Dispatch>.

=head2 translate_module_name($name)

This method is used to control how the module name is translated from
the matching section of the path. See L</How does CGI::Snapp parse the path info?>.

The main reason that this method exists is so that it can be overridden if it doesn't do
exactly what you want.

The following transformations are performed on the input:

=over 4

=item o The text is split on '_'s (underscores)

Next, each word has its first letter capitalized. The words are then joined
back together using '::'.

=item o The text is split on '-'s (hyphens)

Next, each word has its first letter capitalized. The words are then joined
back together without the '-'s.

=back

Examples:

	module_name      => Module::Name
	module-name      => ModuleName
	admin_top-scores => Admin::TopScores

=head1 FAQ

=head2 What is 'path info'?

For a L<CGI> script, it is just $ENV{PATH_INFO}. The value of $ENV{PATH_INFO} is normally set by the web server
from the path info sent by the HTTP client.

A request to /cgi-bin/x.cgi/path/info will set $ENV{PATH_INFO} to /path/info.

For Apache, whether $ENV{PATH_INFO} is set or not depends on the setting of the
L<AcceptPathInfo|http://httpd.apache.org/docs/current/mod/core.html#acceptpathinfo> directive.

For a L<PSGI|http://plackperl.org/> script, it is $$env{PATH_INFO}, within the $env hashref provided by PSGI.

Path info is also discussed in L<CGI::Snapp/mode_param([@new_options])>.

Similar comments apply to the request method (GET, PUT etc) which may be used in rules.

For CGI scripts, request method comes from $ENV{HTTP_REQUEST_METHOD} || $ENV{REQUEST_METHOD}, whereas for PSGI
scripts it is just $$env{REQUEST_METHOD}.

=head2 Is there any sample code?

Yes. See t/args.t and t/lib/*.

=head2 Why did you fork L<CGI::Application::Dispatch>?

To be a companion module for L<CGI::Snapp>.

=head2 What version of L<CGI::Application::Dispatch> did you fork?

V 3.07.

=head2 How does CGI::Snapp::Dispatch differ from CGI::Application::Dispatch?

=head3 There is no module called CGI::Snapp::Dispatch::PSGI

This just means the L<PSGI|http://plackperl.org/>-specific code is incorporated into CGI::Snapp::Dispatch.
See L</as_psgi(@args)>.

=head3 Processing parameters to dispatch() and dispatch_args()

The code which combines parameters to these 2 subs has been written from scratch. Obviously, the intention is that
the new code behave in an identical fashion to the corresponding code in L<CGI::Application::Dispatch>.

Also, the re-write allowed me to support a version of L</dispatch(@args)> which accepts a hashref, not just a hash.
The same flexibility has been added to L</as_psgi(@args)>.

=head3 No special code for Apache, mod_perl or plugins

I suggest that sort of stuff is best put in sub-classes.

=head3 Unsupported features

=over 4

=item o dispatch_path()

Method dispatch_path() is not provided. For L<CGI> scripts, the code in dispatch() accesses $ENV{PATH_INFO} directly,
whereas for L<PSGI|http://plackperl.org/> scripts, as_psgi() accesses the L<PSGI|http://plackperl.org/> environment
hashref $$env{PATH_INFO}.

=back

=head3 Enhanced features

L</new()> can take extra parameters:

=over 4

=item o return_type

Note: I<return_type> is ignored by L</as_psgi(@args)>.

=back

=head3 This module uses Class::Load to try loading your application's module

L<CGI::Application::Dispatch> uses:

	eval "require $module";

whereas CGI::Snapp::Dispatch uses 2 methods from L<Class::Load>:

	try_load_class $module;
	croak 404 if (! is_class_loaded $module);

For L<CGI> scripts, the 404 (and all other error numbers) is handled by sub _http_error(), whereas for
L<PSGI|http://plackperl.org/> scripts, the code throws errors of type L<HTTP::Exception>.

=head3 Reading an error document from a file

L<CGI::Application::Dispatch> always prepends $ENV{DOCUMENT_ROOT} to the file name.
Unfortunately, this means that when $ENV{DOCUMENT_ROOT} is not set, File::Spec prepends a '/' to the file name.
So, an I<error_document> of '<x.html' becomes '/x.html'.

This module only prepends $ENV{DOCUMENT_ROOT} if it is not empty. Hence, with an empty $ENV{DOCUMENT_ROOT},
an I<error_document> of '<x.html' becomes 'x.html'.

See sub _parse_error_document() and t/args.t test_26().

=head3 Handling of exceptions

L<CGI::Application::Dispatch> uses a combination of eval and L<Try::Tiny>, together with L<Exception::Class>.
Likewise, L<CGI::Application::Dispatch::PSGI> uses the same combination, although without L<Exception::Class>.

CGI::Snapp::Dispatch just uses L<Try::Tiny>. This applies both to CGI scripts and PSGI scripts.
For L<CGI> scripts, errors are handled by sub _http_errror(). For L<PSGI|http://plackperl.org/> scripts, the code
throws errors of type L<HTTP::Exception>.

=head2 How does CGI::Snapp parse the path info?

Firstly, the path info is split on '/' chars. Hence /module_name/mode1 gives us ('', 'module_name', 'mode1').

The value 'module_name' is passed to L</translate_module_name($name)>. In this case, the result is 'Module::Name'.

You are free to override L</translate_module_name($name)> to customize it.

After that, the I<prefix> option's value, if any, is added to the front of 'Module::Name'. See L</dispatch_args($args)> for
more about I<prefix>.

FInally, 'mode1' becomes the name of the run mode.

Remember from the docs for L<CGI::Snapp>, that this is the I<name> of the run mode, but is not necessarily the name
of the method which will be run. The code in your sub-class of L<CGI::Snapp> can map run mode names to method
names.

For instance, a statement like:

	$self -> run_modes({rm_name_1 => 'rm_method_1', rm_name_2 => 'rm_method_2'});

in (probably) sub setup(), shows how to separate run mode names from method names.

=head2 What is the structure of the dispatch table?

Sometimes it's easiest to explain with an example, so here you go:

	CGI::Snapp::Dispatch -> new -> dispatch # Note the new()!
	(
		args_to_new =>
		{
			PARAMS => {big => 'small'},
		},
		default => '/app',
		prefix  => 'MyApp',
		table   =>
		[
			''                         => {app => 'Blog', rm => 'recent'},
			'posts/:category'          => {app => 'Blog', rm => 'posts'},
			':app/:rm/:id'             => {app => 'Blog'},
			'date/:year/:month?/:day?' =>
			{
				app         => 'Blog',
				rm          => 'by_date',
				args_to_new => {PARAMS => {small => 'big'} },
			},
		]
	);

Firstly note, that besides passing this structure into L</dispatch(@args)>, you could sub-class L<CGI::Snapp::Dispatch>
and design L</dispatch_args($args)> to return exactly the same structure.

OK. The components, all of which are optional, are:

=over 4

=item o args_to_new => $hashref

This is how you specify a hashref of parameters to be passed to the constructor (new() ) of your sub-class of
L<CGI::Snapp>.

=item o default => $string

This specifies a default for the path info in the case this code is called with an empty $ENV{PATH_INFO}.

=item o prefix => $string

This specifies a namespace to prepend to the class name derived by processing the path info.

E.g. If path info was /module_name, then the above would produce 'MyApp::Module::Name'.

=item o table => $arrayref

This provides a set of rules, which are compared - 1 at a time, in the given order - with the path info, as the code tries to match the
incoming path info to a rule you have provided.

The first match wins.

Each element of the array consists of a I<rule> and an I<argument list>.

Rules can be empty (see '' above), or they may be a combination of '/' chars and tokens. A token can be one of:

=over 4

=item o A literal

Any token which does not start with a colon (:) is taken to be a literal string and must appear exactly as-is
in the path info in order to match. In the rule 'posts/:category', posts is a literal.

=item o A variable

Any token which begins with a colon (:) is a variable token. These are simply wild-card place holders in the rule
that will match anything - in the corresponding position - in the path info that isn't a slash.

These variables can later be referred to in your application (sub-class of L<CGI::Snapp>) by using the
$self -> param($name) mechanism. In the rule 'posts/:category', ':category' is a variable token.

If the path info matched this rule, you could retrieve the value of that token from within your application
like so: my($category) = $self -> param('category');.

There are some variable tokens which are special. These can be used to further customize the dispatching.

=over 4

=item o :app

This is the module name of the application. The value of this token will be sent to L</translate_module_name($name)>
and then prefixed with the prefix if there is one.

=item o :rm

This is the run mode of the application. The value of this token will be the actual name of the run mode used.
As explained just above (L</How does CGI::Snapp parse the path info?>), this is not necessarily the name of the
method within the module which will be run.

=back

=item o An optional variable

Any token which begins with a colon (:) and ends with a question mark (?) is considered optional.
If the rest of the path info matches the rest of the rule, then it doesn't matter whether it contains this token
or not. It's best to only include optional variable tokens at the end of your rule. In the rule
'date/:year/:month?/:day?', ':month?' and ':day?' are optional-variable tokens.

Just as with variable tokens, optional-variable tokens' values can be retrieved by the application,
if they existed in the path info. Try:

	if (defined $self -> param('month') )
	{
		...
	}

Lastly, $self -> param('month') will return undef if ':month?' does not match anything in the path info.

=item o A wildcard

The wildcard token '*' allows for partial matches. The token I<must> appear at the end of the rule.

E.g.: 'posts/list/*'. Given this rule, the 'dispatch_url_remainder' param is set to the remainder of the
path info matched by the *. The name ('dispatch_url_remainder') of the param can be changed by setting '*'
argument in the I<argument list>. This example:

	'posts/list/*' => {'*' => 'post_list_filter'}

specifies that $self -> param('post_list_filter') rather than $self -> param('dispatch_url_remainder') is to be
used in your app, to retrieve the value which was passed in via the path info.

See t/args.t, test_21() and test_22(), and the corresponding sub rm5() in t/lib/CGI/Snapp/App2.pm.

=item o A HTTP method name

You can also dispatch based on HTTP method. This is similar to using I<auto_rest> but offers more fine-grained
control. You include the (case insensitive) method name at the end of the rule and enclose it in square brackets.
Samples:

	':app/news[post]'   => {rm => 'add_news'   },
	':app/news[get]'    => {rm => 'news'       },
	':app/news[delete]' => {rm => 'delete_news'},

The main reason that we don't use regular expressions for dispatch rules is that regular expressions did not provide
for named back references (until recent versions of Perl), in the way variable tokens do.

=back

=back

=head2 How do I use my own logger object?

Study the sample code in L<CGI::Snapp::Demo::Four>, which shows how to supply a L<Config::Plugin::Tiny> *.ini file to configure the logger via the wrapper class
L<CGI::Snapp::Demo::Four::Wrapper>.

Also, see t/logs.t, t/log.a.pl and t/log.b.pl.

See also L<CGI::Snapp/What else do I need to know about logging?> for important info and sample code.

=head2 How do I sub-class CGI::Snapp::Dispatch?

You do this the same way you sub-class L<CGI::Snapp>. See L<this FAQ entry in CGI::Snapp|CGI::Snapp#How-do-I-sub-class-CGI::Snapp->.

=head2 Are there any security implications from using this module?

Yes. Since CGI::Snapp::Dispatch will dynamically choose which modules to use as content generators,
it may give someone the ability to execute specially crafted modules on your system if those modules can be found
in Perl's @INC path. This should only be a problem if you don't use a I<prefix>.

Of course those modules would have to behave like L<CGI::Snapp> based modules, but that still opens up the door
more than most want.

By using the I<prefix> option you are only allowing Dispatch to pick modules from a pre-defined namespace.

=head2 Why is CGI::PSGI required in Build.PL and Makefile.PL when it's sometimes not needed?

It's a tradeoff. Leaving it out of those files is convenient for users who don't run under a PSGI environment,
but it means users who do use PSGI must install L<CGI::PSGI> explicitly. And, worse, it means their code
does not run by default, but only runs after manually installing that module.

So, since L<CGI::PSGI>'s only requirement is L<CGI>, it's simpler to just always require it.

=head1 Troubleshooting

=head2 It doesn't work!

Things to consider:

=over 4

=item o Run the *.cgi script from the command line

shell> perl httpd/cgi-bin/cgi.snapp.one.cgi

If that doesn't work, you're in b-i-g trouble. Keep reading for suggestions as to what to do next.

=item o Did you try using a logger to trace the method calls?

Pass a logger to your sub-class of L<CGI::Snapp> like this:

	my($logger) = Log::Handler -> new;

	$logger -> add
		(
		 screen =>
		 {
			 maxlevel       => 'debug',
			 message_layout => '%m',
			 minlevel       => 'error',
			 newline        => 1, # When running from the command line.
		 }
		);
	CGI::Snapp::Dispatch -> new -> as_psgi({args_to_new => {logger => $logger} }, ...);

In addition, you can trace CGI::Snapp::Dispatch itself with the same (or a different) logger:

	CGI::Snapp::Dispatch -> new(logger => $logger) -> as_psgi({args_to_new => {logger => $logger} }, ...);

The entry to each method in L<CGI::Snapp> and CGI::Snapp::Dispatch is logged using this technique,
although only when maxlevel is 'debug'. Lower levels for maxlevel do not trigger logging.
See the source for details. By 'this technique' I mean there is a statement like this at the entry of each method:

	$self -> log(debug => 'Entered x()');

=item o Are you confused about combining parameters to dispatch() and dispatch_args()?

I suggest you use the I<request_type> option to L</new()> to capture output from the parameter merging code
before trying to run your module. See t/args.t.

=item o Are you confused about patterns in tables which do/don't use ':app' and ':rm'?

The golden rule is:

=over 4

=item o If the rule uses 'app', then it is non-capturing

This means the matching app name from $ENV{PATH_INFO} is I<not> saved, so you must provide a modue name
in the table's rule. E.g.: 'app/:rm' => {app => 'MyModule}, or perhaps use the I<prefix> option to specify
the complete module name.

=item o If the rule uses ':app', then it is capturing

This means the matching app name from $ENV{PATH_INFO} I<is> saved, and it becomes the name of the module.
Of course, I<prefix> might come into play here, too.

=back

=item o Did you forget the leading < (read from file) in the customised error document file name?

=item o Did you forget the leading " (double-quote) in the customised error document string?

=item o Did you forget the embedded %s in the customised error document?

This triggers the use of sprintf to merge the error number into the string.

=item o Are you trying to use this module with an app non based on CGI::Snapp?

Remember that L<CGI::Snapp>'s new() takes a hash, not a hashref.

=item o Did you get the mysterious error 'No such field "priority"'?

You did this:

	as_psgi(args_to_new => $logger, ...)

instead of this:

	as_psgi(args_to_new => {logger => $logger, ...}, ...)

=item o The system Perl 'v' perlbrew

Are you using perlbrew? If so, recall that your web server will use the first line of your L<CGI> script to find a Perl,
and that line probably says something like #!/usr/bin/env perl.

So, perhaps you'd better turn perlbrew off and install L<CGI::Snapp> and this module under the system Perl, before trying again.

=item o Generic advice

L<http://www.perlmonks.org/?node_id=380424>.

=back

=head1 See Also

L<CGI::Snapp> - A almost back-compat fork of CGI::Application.

As of V 1.01, L<CGI::Snapp> now supports L<PSGI|http://plackperl.org/>-style apps.

And see L<CGI::Snapp::Dispatch::Regexp> for another way of matching the path info.

=head1 Machine-Readable Change Log

The file Changes was converted into Changelog.ini by L<Module::Metadata::Changes>.

=head1 Version Numbers

Version numbers < 1.00 represent development versions. From 1.00 up, they are production versions.

=head1 Credits

Please read L<CGI::Application::Dispatch/CONTRIBUTORS>, since this module is a fork of the non-Apache
components of L<CGI::Application::Dispatch>.

=head1 Repository

L<https://github.com/ronsavage/CGI-Snapp-Dispatch>

=head1 Support

Email the author, or log a bug on RT:

L<https://rt.cpan.org/Public/Dist/Display.html?Name=CGI::Snapp::Dispatch>.

=head1 Author

L<CGI::Snapp::Dispatch> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2012.

Home page: L<http://savage.net.au/index.html>.

=head1 Copyright

Australian copyright (c) 2012, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License, a copy of which is available at:
	http://www.opensource.org/licenses/index.html

=cut
