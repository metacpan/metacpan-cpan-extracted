package CGI::Snapp;

use strict;
use warnings;

use Carp;

use Class::ISA;

use Log::Handler;

use Moo;

use Try::Tiny;

has _current_run_mode =>
(
	is       => 'rw',
	default  => sub{return ''},
	required => 0,
);

has _error_mode =>
(
	is       => 'rw',
	default  => sub{return ''},
	required => 0,
);

has _headers =>
(
	is       => 'rw',
	default  => sub{return {} },
	required => 0,
);

has _header_type =>
(
	is       => 'rw',
	default  => sub{return 'header'},
	required => 0,
);

has logger =>
(
	is       => 'rw',
	default  => sub{return ''},
	required => 0,
);

has _object_callbacks =>
(
	is       => 'rw',
	default  => sub{return {} },
	required => 0,
);

has PARAMS =>
(
	is       => 'rw',
	default  => sub{return {} },
	required => 0,
);

has _params =>
(
	is       => 'rw',
	default  => sub{return {} },
	required => 0,
);

has _prerun_mode_lock =>
(
	is       => 'rw',
	default  => sub{return 1},
	required => 0,
);

has _psgi =>
(
	is       => 'rw',
	default  => sub{return 0},
	required => 0,
);

has QUERY =>
(
	is       => 'rw',
	default  => sub{return ''},
	required => 0,
);

has _query =>
(
	is       => 'rw',
	default  => sub{return ''},
	required => 0,
);

has _run_mode_source =>
(
	is       => 'rw',
	default  => sub{return 'rm'}, # I.e. the CGI form field of that name.
	required => 0,,
);

has _run_modes =>
(
	is       => 'rw',
	default  => sub{return {} },
	required => 0,
);

has send_output =>
(
	is       => 'rw',
	default  => sub{return 1},
	required => 0,
);

has _start_mode =>
(
	is       => 'rw',
	default  => sub{return 'start'},
	required => 0,
);

my(%class_callbacks) =
(
	error          => {},
	forward_prerun => {},
	init           => {'CGI::Snapp' => ['cgiapp_init']},
	prerun         => {'CGI::Snapp' => ['cgiapp_prerun']},
	postrun        => {'CGI::Snapp' => ['cgiapp_postrun']},
	teardown       => {'CGI::Snapp' => ['teardown']},
);

my($myself);

our $VERSION = '2.01';

# --------------------------------------------------

sub add_callback
{
	my($self, $hook, $option) = @_;

	croak "Error: Can't use undef as a hook name\n" if (! defined $hook);

	$hook = lc $hook;

	$self -> log(debug => "add_callback($hook, ...)");

	croak "Error: Unknown hook name '$hook'\n" if (! $class_callbacks{$hook});

	if (ref $self)
	{
		# it's an object-level callback.

		my($object_callback)     = $self -> _object_callbacks;
		$$object_callback{$hook} = [] if (! $$object_callback{$hook});

		push @{$$object_callback{$hook} }, $option;

		$self -> _object_callbacks($object_callback);
	}
	else
	{
		# It's a class-level callback.

		push @{$class_callbacks{$hook}{$self} }, $option;
	}

} # End of add_callback.

# --------------------------------------------------

sub add_header
{
	my($self, @headers) = @_;

	$self -> log(debug => 'add_header(...)');

	my($old) = $self -> _headers;

	if (@headers)
	{
		my(%new) = ref $headers[0] eq 'HASH' ? %{$headers[0]}
		: ref $headers[0] eq 'ARRAY'         ? @{$headers[0]}
		: scalar(@headers) % 2 == 0          ? @headers
		: croak "Error: Odd number of parameters passed to add_header()\n";

		my($value);

		for my $key (keys %new)
		{
			$value = $$old{$key};

			if (ref $new{$key} eq 'ARRAY')
			{
				if (ref $value eq 'ARRAY')
				{
					$new{$key} = [@$value, @{$new{$key} }];
				}
				else
				{
					$new{$key} = [$value, @{$new{$key} }] if (defined $value);
				}
			}
			else
			{
				if (ref $value eq 'ARRAY')
				{
					$new{$key} = [@$value, $new{$key}];
				}
				else
				{
					$new{$key} = [$value, $new{$key}] if (defined $value);
				}
			}
		}

		$old = {%$old, %new};

		$self -> _headers($old);
	}

	return %$old;

} # End of add_header.

# --------------------------------------------------

sub BUILD
{
	my($self, $args)	= @_;
	$myself				= $self;

	$self -> _params($$args{PARAMS})	if ($$args{PARAMS} && (ref $$args{PARAMS} eq 'HASH') );
	$self -> _query($$args{QUERY})		if ($$args{QUERY});
	$self -> send_output(0)				if ($ENV{CGI_SNAPP_RETURN_ONLY});
	$self -> _run_modes({$self -> _start_mode => 'dump_html'});
	$self -> call_hook('init', %$args);
	$self -> setup;

}	# End of BUILD.

# --------------------------------------------------

sub call_hook
{
	my($self, $hook, @args) = @_;

	croak "Error: Can't use undef as a hook name\n" if (! defined $hook);

	$hook = lc $hook;

	$self -> log(debug => "call_hook($hook, ...)");

	my($count) = {class => 0, object => 0};

	my(%seen);

	# Call object-level hooks.

	for my $callback (@{${$self -> _object_callbacks}{$hook} })
	{
		next if ($seen{$callback});

		try
		{
			$self -> $callback(@args);
		}
		catch
		{
			croak "Error executing object-level callback for hook '$hook': $@\n" if ($@);
		};

		$$count{object}++;

		$seen{$callback} = 1;
	}

	# Call class-level hooks.

	for my $class (Class::ISA::self_and_super_path(ref $self || $self) )
	{
		next if (! exists $class_callbacks{$hook}{$class});

		for my $callback (@{$class_callbacks{$hook}{$class} })
		{
			next if ($seen{$callback});

			try
			{
				$self -> $callback(@args);
			}
			catch
			{
				croak "Error executing class-level callback for class '$class', hook '$hook': $@\n" if ($@);
			};

			$$count{class}++;

			$seen{$callback} = 1;
		}
	}

	return $count;

} # End of call_hook.

# --------------------------------------------------

sub cgiapp_get_query
{
	my($self) = @_;

	$self -> log(debug => 'cgiapp_get_query()');

	if (! $self -> _query)
	{
		require CGI;

		$self -> _query(CGI -> new);
	}

	return $self -> _query;

} # End of cgiapp_get_query.

# --------------------------------------------------

sub cgiapp_init
{
	my($self) = @_;

	$self -> log(debug => 'cgiapp_init()');

} # End of cgiapp_init.

# --------------------------------------------------

sub cgiapp_prerun
{
	my($self) = @_;

	$self -> log(debug => 'cgiapp_prerun()');

} # End of cgiapp_prerun.

# --------------------------------------------------

sub cgiapp_postrun
{
	my($self) = @_;

	$self -> log(debug => 'cgiapp_postrun()');

} # End of cgiapp_postrun.

# --------------------------------------------------

sub delete
{
	my($self, $key) = @_;

	$self -> log(debug => 'delete()');

	my($result);

	if (defined $key)
	{
		my($param) = $self -> _params;
		$result    = delete $$param{$key};

		$self -> _params($param);
	}

	return $result;

} # End of delete.

# --------------------------------------------------

sub delete_header
{
	my($self, @keys) = @_;

	$self -> log(debug => 'delete_header()');

	my($old) = $self -> _headers;

	delete $$old{$_} for (@keys);

	$self -> _headers($old);

	return %$old;

} # End of delete_header.

# --------------------------------------------------

sub _determine_cgi_header
{
	my($self) = @_;

	$self -> log(debug => '_determine_cgi_header()');

	my($q)    = $self -> query;
	my($type) = $self -> header_type;

	return
		$type eq 'header'
		? $q -> header($self -> header_props)
		: $type eq 'redirect'
		? $q -> redirect($self -> header_props)
		: '';

} # End of _determine_cgi_header.

# --------------------------------------------------

sub _determine_output
{
	my($self) = @_;

	$self -> log(debug => '_determine_output()');

	my($run_mode) = $self -> _determine_run_mode;

	$self -> _prerun_mode_lock(0);
	$self -> call_hook('prerun', $run_mode);
	$self -> _prerun_mode_lock(1);

	my($output) = $self -> _generate_output;
	$output     = $$output if (ref $output eq 'SCALAR');

	$self -> call_hook('postrun', \$output);

	return $output;

} # End of _determine_output.

# --------------------------------------------------

sub _determine_psgi_header
{
	my($self) = @_;

	$self -> log(debug => '_determine_psgi_header()');

	my($q)    = $self -> query;
	my($type) = $self -> header_type;

	return
		$type eq 'header'
		? $q -> psgi_header($self -> header_props)
		: $type eq 'redirect'
		? $q -> psgi_redirect($self -> header_props)
		: (200, []);

} # End of _determine_psgi_header.

# --------------------------------------------------

sub _determine_run_mode
{
	my($self)        = @_;
	my($mode_source) = $self -> _run_mode_source;

	my($run_mode);

	if (ref $mode_source eq 'CODE')
	{
		$run_mode = $mode_source -> ($self);
	}
	elsif (ref $mode_source eq 'HASH')
	{
		$run_mode = $$mode_source{run_mode};
	}
	else
	{
		$self -> cgiapp_get_query if (! $self -> query);

		$run_mode = $self -> query -> param($mode_source);
	}

	$run_mode = $self -> start_mode if (! defined $run_mode);

	$self -> _current_run_mode($run_mode);
	$self -> log(debug => "_determine_run_mode() => $run_mode");

	return $run_mode;

} # End of _determine_run_mode.

# --------------------------------------------------

sub dump
{
	my($self) = @_;

	$self -> log(debug => 'dump()');

	my($q)      = $self -> query;
	my($output) = 'Run mode: ' . ($self -> _current_run_mode || ''). "\n" .
		"Query parameters:\n" . $q -> Dump . "\nQuery environment:\n";

	for my $key (sort keys %ENV)
	{
		$output .= $q -> escapeHTML($key) . ' => ' . $q -> escapeHTML($ENV{$key}) . "\n";
	}

	return $output;

} # End of dump.

# --------------------------------------------------

sub dump_html
{
	my($self) = @_;

	$self -> log(debug => 'dump_html()');

	my($q)      = $self -> query;
	my($output) = '<p>Run mode: ' . ($self -> _current_run_mode || ''). "</p>\n" .
		"<p>Query parameters:</p>\n" . $q -> Dump . "\n<p>Query environment:</p>\n" .
		"<ol>\n";

	for my $key (sort keys %ENV)
	{
		$output .= '<li>' . $q -> escapeHTML($key) . ' => ' . $q -> escapeHTML($ENV{$key}) . "</li>\n";
	}

	$output .= "</ol>\n";

	return $output;

} # End of dump_html.

# --------------------------------------------------

sub error_mode
{
	my($self, $method_name) = @_;
	$method_name            ||= '';

	$self -> log(debug => "error_mode($method_name)");
	$self -> _error_mode($method_name) if ($method_name);

	return $self -> _error_mode;

} # End of error_mode.

# --------------------------------------------------

sub forward
{
	my($self, $run_mode, @args) = @_;
	$run_mode = defined $run_mode ? $run_mode : '';

	$self -> log(debug => "forward($run_mode, ...)");
	$self -> _current_run_mode($run_mode);
	$self -> call_hook('forward_prerun');

	return $self -> _generate_output(@args);

} # End of forward.

# --------------------------------------------------

sub _generate_output
{
	my($self, @args) = @_;

	$self -> log(debug => '_generate_output()');

	my($is_autoload) = 0;
	my($run_mode)    = $self -> _current_run_mode;
	my(%run_modes)   = $self -> run_modes;

	my($method_name);

	if (exists $run_modes{$run_mode})
	{
		$method_name = $run_modes{$run_mode};
	}
	else
	{
		croak "Error: No such run mode: '$run_mode'\n" if (! exists $run_modes{'AUTOLOAD'});

		$method_name = $run_modes{'AUTOLOAD'};
		$is_autoload = 1;
	}

	my($output);

	try
	{
		$output = $is_autoload ? $self -> $method_name($run_mode, @args) : $self -> $method_name(@args);
	}
	catch
	{
		my($error) = $_;

		$self -> call_hook('error', $error);

		if ($method_name = $self -> error_mode)
		{
			try
			{
				$output = $self -> $method_name($error);
			}
			catch
			{
				croak "Error executing the error mode method '$method_name': $_\n";
			};
		}
		else
		{
			croak "Error executing run mode '$run_mode': $error\n";
		}
	};

	return defined($output) ? $output : '';

} # End of _generate_output.

# --------------------------------------------------

sub get_callbacks
{
	my($self, $type, $hook) = @_;
	$type ||= '';
	$hook ||= '';

	$self -> log(debug => "get_callbacks($type, $hook)");

	croak "Error: \$type parameter to get_callbacks() must be 'class' or 'object'\n" if ($type !~ /^(?:class|object)$/);
	croak "Error: \$hook parameter to get_callbacks() must be a string\n"            if (length($hook) == 0);

	return $type eq 'class' ? $class_callbacks{$hook} : ${$self -> _object_callbacks}{$hook};

} # End of get_callbacks.

# --------------------------------------------------

sub get_current_runmode
{
	my($self) = @_;

	$self -> log(debug => 'get_current_runmode()');

	return $self -> _current_run_mode;

} # End of get_current_runmode.

# --------------------------------------------------

sub header_add
{
	my($self, @headers) = @_;

	$self -> log(debug => 'header_add(...)');

	my(%new) = ref $headers[0] eq 'HASH' ? %{$headers[0]}
	: ref $headers[0] eq 'ARRAY'         ? @{$headers[0]}
	: scalar(@headers) % 2 == 0          ? @headers
	: croak "Error: Odd number of parameters passed to header_add()\n";

	my($old) = $self -> _headers;

	if (scalar keys %new)
	{
		my($value);

		for my $key (grep{ref $new{$_} eq 'ARRAY'} keys %new)
		{
			$value = $$old{$key};

			next if (! defined $value);

			$value     = [$value] if (ref $value ne 'ARRAY');
			$new{$key} = [@$value, @{$new{$key} }];
		}

		$old = {%$old, %new};

		$self -> _headers($old);
	}

	return %$old;

} # End of header_add.

# --------------------------------------------------

sub header_props
{
	my($self, @headers) = @_;

	$self -> log(debug => 'header_props(...)');

	if (@headers)
	{
		my(%new) = ref $headers[0] eq 'HASH' ? %{$headers[0]}
		: ref $headers[0] eq 'ARRAY'         ? @{$headers[0]}
		: scalar(@headers) % 2 == 0          ? @headers
		: croak "Error: Odd number of parameters passed to header_props()\n";

		$self -> _headers({%new});
	}

	return %{$self -> _headers};

} # End of header_props.

# --------------------------------------------------

sub header_type
{
	my($self, $option) = @_;
	$option            ||= '';

	$self -> log(debug => "header_type($option)");

	if ($option)
	{
		my(%valid) = (header => 1, none => 1, redirect => 1);

		croak "Error: Invalid header type '$option'. Must be one of: " . join(', ', sort keys %valid) . "\n" if (! $valid{$option});

		$self -> _header_type($option);
	}

	return $self -> _header_type;

} # End of header_type.

# --------------------------------------------------

sub log
{
	my($self, $level, $s) = @_;
	$level ||= 'info';
	$s     ||= '';

	# We can't use $self here because add_callback can be called as a class method,
	# and logging inside add_callback would then call here without initializing $self
	# to be an instance. It would just be the string name of the class calling add_callback.

	$myself -> logger -> log($level => $s) if ($myself && $myself -> logger);

} # End of log.

# --------------------------------------------------

sub mode_param
{
	my($self, @new_options) = @_;

	$self -> log(debug => 'mode_param(...)');

	my($mode_source);

	if (@new_options)
	{
		my($ref) = ref $new_options[0];

		if ( ($#new_options == 0) && ($ref !~ /(?:ARRAY|HASH)/) )
		{
			$mode_source = $new_options[0];
		}
		else
		{
			my(%new_options) = $ref eq 'HASH'  ? %{$new_options[0]}
			: $ref eq 'ARRAY'                  ? @{$new_options[0]}
			: scalar(@new_options) % 2 == 0    ? @new_options
			: croak "Error: Odd number of parameters passed to mode_param()\n";

			# We need defined in case someone uses a run mode of 0.

			$mode_source   = defined($new_options{param}) ? $new_options{param} : '';
			my($index)     = $new_options{path_info};
			my($path_info) = $self -> query -> path_info;

			if ($index && $path_info)
			{
				$index       -= 1 if ($index > 0);
				$path_info   =~ s!^/!!;
				$path_info   = (split m|/|, $path_info)[$index] || '';
				$mode_source = length $index ? {run_mode => $path_info} : $mode_source;
			}
		}

		$self -> _run_mode_source($mode_source);
	}
	else
	{
		$mode_source = $self -> _run_mode_source;
	}

	return $mode_source;

} # End of mode_param.

# --------------------------------------------------

sub new_hook
{
	my($self, $hook) = @_;

	croak "Error: Can't use undef as a hook name\n" if (! defined $hook);

	$hook = lc $hook;

	$self -> log(debug => "new_hook($hook)");

	$class_callbacks{$hook} ||= {};

	return 1;

}	# End of new_hook.

# --------------------------------------------------

sub param
{
	my($self, @params) = @_;

	$self -> log(debug => 'param(...)');

	my(%old) = %{$self -> _params};

	my($returnz);
	my($value);

	if (@params)
	{
		my(%new);

		if (ref $params[0] eq 'HASH')
		{
			%new = %{$params[0]};
		}
		elsif (ref $params[0] eq 'ARRAY')
		{
			%new = @{$params[0]};
		}
		elsif (scalar @params % 2 == 0)
		{
			%new   = @params;
			$value = $params[1] if ($#params == 1);
		}
		elsif ($#params == 0)
		{
			$value = $old{$params[0]};
		}
		else
		{
			croak "Error: Odd number of parameters passed to param()\n";
		}

		$returnz = 'scalar';
		%old     = (%old, %new);

		$self -> _params({%old});
	}
	else
	{
		$returnz = 'array';
	}

	return $returnz eq 'scalar' ? $value : keys %{$self -> _params};

}	# End of param.

# --------------------------------------------------

sub prerun_mode
{
	my($self, $run_mode) = @_;
	$run_mode            = defined($run_mode) ? $run_mode : '';

	$self -> log(debug => "prerun_mode($run_mode)");

	croak "Error: prerun_mode() can only be called from within cgiapp_prerun()\n" if ($self -> _prerun_mode_lock);

	$self -> _current_run_mode($run_mode);

	return $run_mode;

} # End of prerun_mode.

# --------------------------------------------------

sub psgi_app
{
	my($self, %arg) = @_;

	$self -> log(debug => 'psgi_app(...)');

	return
		sub
		{
			my($env) = @_;

			if (! $arg{QUERY})
			{
				require CGI::PSGI;

				$arg{QUERY} = CGI::PSGI -> new($env);
			}

			$arg{_psgi} = 1; # Required.
			my($class)  = $self;
			$class      =~ s/=HASH\(.+\)//;

			return $class -> new(%arg) -> run;
		};

} # End of psgi_app.

# --------------------------------------------------

sub query
{
	my($self, $q) = @_;
	$q            ||= '';

	$self -> log(debug => "_query($q)");
	$self -> _query($q)       if ($q);
	$self -> cgiapp_get_query if (! $self -> _query);

	return $self -> _query;

} # End of _query.

# --------------------------------------------------

sub redirect
{
	my($self, $url, $status) = @_;
	$url    ||= '';
	$status ||= 0;

	$self -> log(debug => "redirect($url, ...)");

	# If we're in the prerun phase, generate a no-op via a dummy sub.

	if ($self -> _prerun_mode_lock == 0)
	{
		$self -> run_modes(dummy_redirect => sub{});
		$self -> prerun_mode('dummy_redirect');
	}

	if ($status)
	{
		$self -> header_add(-location => $url, -status => $status);
	}
	else
	{
		$self -> header_add(-location => $url);
	}

	$self -> header_type('redirect');

} # End of redirect.

# --------------------------------------------------

sub run
{
	my($self) = @_;

	$self -> log(debug => 'run()');

	my($output) = $self -> _determine_output;

	if ($self -> _psgi)
	{
		my($status, $header) = $self -> _determine_psgi_header;

		utf8::downgrade($_, 0) for @$header;

		$self -> call_hook('teardown');

		return [$status, $header, [$output] ];
	}
	else
	{
		my($header) = $self -> _determine_cgi_header;

		utf8::downgrade($header, 0);

		$output = $header . $output;

		print $output if ($self -> send_output);

		$self -> call_hook('teardown');

		return $output;
	}

} # End of run.

# --------------------------------------------------

sub run_modes
{
	my($self, @new_modes) = @_;

	$self -> log(debug => 'run_modes(...)');

	my($old_modes) = $self -> _run_modes;

	if (@new_modes)
	{
		$old_modes     = ref $new_modes[0] eq 'HASH' ? {%$old_modes, %{$new_modes[0]} }
		: ref $new_modes[0] eq 'ARRAY'               ? {%$old_modes, map{($_ => $_)} @{$new_modes[0]} }
		: scalar(@new_modes) % 2 == 0                ? {%$old_modes, @new_modes}
		: croak "Error: Odd number of parameters passed to run_modes()\n";

		$self -> _run_modes($old_modes);
	}

	return %$old_modes;

} # End of run_modes.

# --------------------------------------------------

sub setup
{
	my($self) = @_;

	$self -> log(debug => 'setup()');

} # End of setup.

# --------------------------------------------------

sub start_mode
{
	my($self, $run_mode) = @_;

	if ($run_mode)
	{
		$self -> _start_mode($run_mode = defined $run_mode ? $run_mode : '');
	}
	else
	{
		$run_mode = $self -> _start_mode;
	}

	$self -> log(debug => "start_mode($run_mode)");

	return $self -> _start_mode;

} # End of start_mode.

# --------------------------------------------------

sub teardown
{
	my($self) = @_;

	$self -> log(debug => 'teardown()');

} # End of teardown.

# --------------------------------------------------

1;

=pod

=head1 NAME

CGI::Snapp - An almost back-compat fork of CGI::Application

=head1 Synopsis

In general, use as you would L<CGI::Application>, except for the differences discussed in L</How does CGI::Snapp differ from CGI::Application?>.

But be warned, load_tmp() and tmp_path() in particular are not supported, because they're too tied to the L<HTML::Template> way of doing things, and I prefer L<Text::Xslate>.

=head1 Description

A fork of L<CGI::Application> (later L<CGI::Application::Dispatch> etc) in order to understand how they work in sufficient detail that I can put L<CGI::Snapp> etc into
production - I<in my own code> - as replacements for those modules.

You are I<strongly> encouraged to peruse L</How does CGI::Snapp differ from CGI::Application?> for details of the differences between L<CGI::Application> and L<CGI::Snapp>.

=head1 The Flow of Control

This is a short article on which methods get called in which order. Steve Comrie has written a version for L<CGI::Application>:
L<Order of Operations|http://cgi-app.org/index.cgi?OrderOfOperations>.

=head2 An Overview

If you have trouble following this explanation, consider working thru the tests (t/*.pl called by t/test.t) shipped with this distro.

Now, under normal circumstances, your CGI script receives CGI form data and accesses it via an object of type L<CGI> or similar.

Let's say you have a CGI form field called 'rm', and when the user submits the form, that field has the value 'start'.

Then in the terminology of this module, and its predecessor, 'start' is called a run mode.

(In fact, 'rm' is the default name of the CGI form field this module uses to find the name of the run mode. And, when that CGI form field's name does not exist, or is empty, the
default run mode is 'start'.)

Then L<CGI::Snapp> uses 'start' to find which method to run to handle that run mode. The default run mode 'start' runs a method called L</dump_htm()>' implemented in L<CGI::Snapp>.

How does it use 'start' to find the name of the method? By examining a dispatch table (a hash), which is explained under
L</run_modes([$option])>. 'start' is the key, and (in the simplest case) the value is the name of a method.

Your run mode methods must all I<return> a string or stringref of HTML to be sent to the HTTP client. You code must never write to STDOUT - that's the classic mistake most beginners make.

You can of course override the defaults just mentioned:

=over 4

=item o The default CGI form field name 'rm'

Method L</mode_param([@new_options])> allows you to change that CGI form field name from 'rm' to another string, amongst other options.

=item o The default run mode 'start'

Method L</start_mode([$run_mode])> allows you to change that run mode 'start' to another string.

=item o The default association between 'start' and 'dump_html()'

Method L</run_modes([$option])> allows you to associate any run mode name with any method name.

=back

=head2 The Simple View

So, a basic L<CGI> script is something like:

	#!/usr/bin/env perl

	use KillerApp;
	KillerApp -> new -> run;

Here's what happens as L<CGI::Snapp> runs firstly 'new()' and then 'run()':

=over 4

=item o The call to new():

This calls some initialization code, which you never override (so we ignore it), and then calls, in this order:

=over 4

=item o 1: cgiapp_init(@args)

Here, @args is the array of options passed in to L</new()>.

=item o 2: setup()

=back

These 2 methods give you scope to set up anything you want before your run mode method is activated, by sub-classing L<CGI::Snapp> and re-implementing either or both of these methods.

For instance, if we have this inheritance structure: CGI::Snapp --> parent of --> GlobalApp --> parent of --> SpecificApp, then one or both of these methods could be
implemented in GlobalApp and/or in SpecificApp. This would allow yet other descendents of GlobalApp (in parallel with SpecificApp) to share GlobalApp's code, and at the same time
implement their own run methods.

After calling L</new()>, a call to L</cgiapp_get_runmode()> will return undef, since determination of the run mode only takes place during the call to L</run()>.

=item o The call to run():

This in turn calls:

=over 4

=item o 3: mode_param([@new_options])

=back

So now we know how you want run modes to be determined. See L</mode_param([@new_options])> for how to control this mechanism.

Then it calls internal code to get the name of the run mode, using - by default - the L<CGI> form field parameter whose name defaults to 'rm'.

Finally, methods are called in this order:

=over 4

=item o 4: cgiapp_prerun($run_mode)

During this call (and at no other time), you can call L</prerun_mode([$string])> to change the name of the run mode which is about to be executed.

=item o 5: your_run_mode_method()

This is found via the dispatch table described at length under L</run_modes([$option])>

The name of the run mode is the key used to find this method name in the dispatch table (which is just a hash).

Your run mode method must return a string, or a scalarref to a string, containing the HTML to be output to the HTTP client (normally a browser of course).

See note 1 (just below) on what parameters are passed to the method.

See note 2 (just below) on what happens if the key is not present in the dispatch table.

See note 3 (just below) on what happens if the run mode method fails to run.

=item o 6: cgiapp_postrun(\$html)

A scalarref of the generated HTML is passed in to cgiapp_postrun(), which can overwrite that HTML if desired.

Now, the HTTP headers are generated, and both those headers and the HTML are sent to the HTTP client. You can stop the transmission with L</send_output([$Boolean])>.

utf8::downgrade() is used to turn off any stray UTF-8 bits on the headers.

=item o 7: teardown()

Here's where you clean up, by disconnecting from the database, or whatever.

=back

=back

=head3 Note 1: Parameters passed to your run mode method

Normally, the only parameter passed is $self, which is an object of type L<CGI::Snapp> or a sub-class.

However, if the method was invoked via the AUTOLOAD mechanism (note 2), the next parameter is the run mode.

Lastly, if the method was invoked via L<CGI::Snapp::Plugin::Forward>'s forward(@args), then those parameters you pass to forward() will be passed to the run mode method (after $self).

=head3 Note 2: When the run mode is not a key in the dispatch table, this algorithm is invoked

=over 4

=item o The AUTOLOAD run mode

The code checks if you have defined a run mode named 'AUTOLOAD'. If so, it's value in the dispatch table is used as the method name.

=item o Fallback

If no run mode called 'AUTOLOAD' is found, the code calls L<Carp>'s croak($message).

=back

=head3 Note 3: When the run mode method fails to run, this algorithm is invoked

=over 4

=item o The error hook

The method, if any, attached to the 'error' hook is called. The error message generated from the run mode method's failure is passed as the parameter, for you to utilize when deciding what
action to take.

Hooks are discussed under L</A More Complex View> just below.

=item o The error_mode method

Next, L<error_mode([$method_name])> is called. If it returns a defined value, that value is used as the name of a method to call.

=item o Fallback

Finally, if L<error_mode([$method_name])> does not return a method name, or calling that method also fails, the code calls L<Carp>'s croak($message).

=back

Aren't you glad that was the I<simple> view?

=head2 A More Complex View

L<CGI::Snapp> and before it L<CGI::Application> are designed in such a way that some of those methods are actually I<callbacks> aka I<hooks>, and their names are looked up via hook names.

See the Wikipedia article L<Hooking|http://en.wikipedia.org/wiki/Hooking> for a long explanation of hooks.

It works like this: A hook name is a key in a hash, and the corresponding value is a package name, which in turn points to an arrayref of method names. So, for a given hook name and
package, we can execute a series of named methods, where those names are listed in that arrayref.

The hooked methods are not expected to return anything.

Here's the default set of hooks aka (default) dispatch table. It's just a hash with fancy values per key:

	my(%class_callback) =
	(
	error          => {},
	forward_prerun => {},
	init           => {'CGI::Snapp' => ['cgiapp_init']},
	prerun         => {'CGI::Snapp' => ['cgiapp_prerun']},
	postrun        => {'CGI::Snapp' => ['cgiapp_postrun']},
	teardown       => {'CGI::Snapp' => ['teardown']},
	);

An explanation:

=over 4

=item o Yes, there are class-level callbacks and object-level callbacks

See L</add_callback($hook, $option)> for details.

=item o The error hook

By default, there is no method attached to the 'error' hook. See L</error_mode([$method_name])> for details.

=item o The init hook

Instead of calling cgiapp_init() directly at the start of the run as alleged above, we call all those methods named as belonging to the 'init' hook, of which - here - there is just the
default one, CGI::Snapp::cgiapp_init().

=item o The prerun hook

Likewise.

=item o The postrun hook

Likewise.

=item o The teardown hook

Likewise, instead of calling teardown() directly at the finish of the run, we call all those methods named as belonging to the 'teardown' hook, starting with (the default) CGI::Snapp::teardown().

=back

Now, when I say 'all those methods', that's because you can add your own hooked methods, to enhance this process. What happens is that your hooks are pushed onto the stack of hooked methods
attached to a given hook name, and run in turn at the appropriate time.

Further, besides extending the stack of methods attached to a pre-existing hook name, you can create new hook names, and attach any number of methods to each.

The pre-defined hooks are called 'error', 'init', 'prerun', 'postrun' and 'teardown', so there is no need to call L</new_hook($hook)> for those.

This matter is discussed in depth under the entry for L</add_callback($hook, $option)>. Also, see L</new_hook($hook)> and L</call_hook($hook, @args)> for how hooks are named and invoked.

Sample code is in t/callback.pl, in the distro.

=head1 Distributions

This module is available as a Unix-style distro (*.tgz).

See L<http://savage.net.au/Perl-modules/html/installing-a-module.html>
for help on unpacking and installing distros.

=head1 Installation

Install L<CGI::Snapp> as you would for any C<Perl> module:

Run:

	cpanm CGI::Snapp

or run:

	sudo cpan CGI::Snapp

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

C<new()> is called as C<< my($app) = CGI::Snapp -> new(k1 => v1, k2 => v2, ...) >>.

It returns a new object of type C<CGI::Snapp>.

Key-value pairs accepted in the parameter list (see corresponding methods for details
[e.g. L</send_output([$Boolean])>]):

=over 4

=item o logger => $aLoggerObject

Specify a logger compatible with L<Log::Handler>.

Default: '' (The empty string).

To clarify: The built-in calls to log() all use a log level of 'debug', so if your logger has 'maxlevel' set
to anything less than 'debug', nothing will get logged.

'maxlevel' and 'minlevel' are discussed in L<Log::Handler#LOG-LEVELS> and L<Log::Handler::Levels>.

Also, see L</How do I use my own logger object?> and L</Troubleshooting>.

=item o PARAMS => $hashref

Provides a set of ($key => $value) pairs as initial data available to your sub-class of L<CGI::Snapp> via the L</param([@params])> method.

Default: {}.

=item o send_output => $Boolean

Controls whether or not the HTML output is sent (printed) to the HTTP client.

This corresponds to L<CGI::Application>'s use of $ENV{CGI_APP_RETURN_ONLY}. But check the spelling in the next line.

Default: 1 (meaning yes, send). However, if $ENV{CGI_SNAPP_RETURN_ONLY} has a Perlish true value, the default is 0.

Using 0 means you have to get the output from the return value of the L</run()> method.

=item o QUERY => $q

Provides L</new()> with a pre-created L<CGI>-compatible object.

Default: ''.

However, a new L<CGI> object is created at run-time if needed. See L</query([$q])>.

=back

=head1 Methods

=head2 add_callback($hook, $option)

Adds another method to the stack of methods associated with $hook.

$hook is the name of a hook. $hook is forced to be lower-case.

Returns nothing.

That name is either pre-defined (see L</new_hook($hook)>) or one of your own, which you've previously set up with L</new_hook($hook)>.

Sample code:

	# Class-level callbacks.
	$class_name -> add_callback('init', \&method_1);
	KillerApp   -> add_callback('init', 'method_2');

	# Object-level callbacks.
	$app = CGI::Snapp -> new;
	$app -> add_callback('init', \&method_3);

Notes:

=over 4

=item o Callback lifetimes

Class-level callbacks outlive the life of the $app object (of type L<CGI::Snapp> or your sub-class), by surviving for the duration of the Perl process, which, in a persistent
environment like L<Starman>, L<Plack>, etc, can be long enough to serve many HTTP client requests.

Object-level callbacks, however, go out of scope at the same time the $app object itself does.

=item o The class hierarchy

Callbacks can be registered by an object, or any of its parent classes, all the way up the hierarchy to L<CGI::Snapp>.

=item o Callback name resolution

Callback names are checked, and only the first with a given name is called. The type of callback, class or object, is ignored in this test, as it is in L<CGI::Application>.
This also means, that if there are 2 callbacks with the same name, in different classes, then still only the first is called.

Consider:

	In Class A: $self -> add_callback('teardown', 'teardown_sub');
	In Class B: $self -> add_callback('teardown', 'teardown_sub');

Here, because the names are the same, only one (1) teardown_sub() will be called. Which one called depends on the order in which those calls to add_callback() take place.

	In Class A: $self -> add_callback('teardown', \&teardown_sub);
	In Class B: $self -> add_callback('teardown', \&teardown_sub);

This time, both teardown_sub()s are called, because what's passed to add_callback() are 2 subrefs, which are memory addresses, and can't be the same for 2 different subs.

=item o Pre-defined hooks

Only the pre-defined hooks are called by L<CGI::Snapp>. So, if you use your own name in calling new_hook($name), you are also responsible for triggering the calls to that hook.

The pre-defined hooks are called 'error', 'init', 'prerun', 'postrun' and 'teardown', and there is no need to call L</new_hook($hook)> for those.

=item o Class-level callbacks

These belong to the class of the object calling L</add_callback($hook, $option)>.

=item o Multiple callbacks for a given hook

If multiple I<class>-level callbacks are added for the same hook by different classes, they will be executed in reverse-class-hierarchy order.
That it, the callback for the most derived class is executed first. This is the way normal class-hierarchy overrides work - nothing unexpected here.

If multiple I<class>-level callbacks are added for the same hook by the same class, they will be executed in the order added, since they are pushed onto a stack (as are object-level
callbacks).

If multiple I<object>-level callbacks are added for the same hook, they are run in the order they are registered, i.e. in the order of calls to L</add_callback($hook, $option)>.

=item o The 'init' hook

Since the 'init' hook is triggered during the call to L</new()>, even before L</setup()> is called, there is no opportunity for normal end-user code (your sub-class of L<CGI::Snapp>) to attach
a callback to this hook.

The way around this is to write a class which is I<not> a sub-class of L<CGI::Snapp>, and whose import() method is triggered when you 'use' this class in your sub-class of L<CGI::Snapp>.

There is a group of examples on how to do this. Start with t/hook.test.a.pl, which 'use's t/lib/CGI/Snapp/HookTestA.pm, which in turn 'use's t/lib/CGI/Snapp/Plugin/HookTest1.pm.

Alternately, examine the source code of L<CGI::Snapp::Plugin::Forward> for another way to do things, although it uses 'forward_prerun' rather than 'init'.

=back

To summarize, you are I<strongly> advised to examine t/hook.test.pl and all the modules it uses to gain a deeper understanding of this complex issue. In particular, the order of 'use'
statements in your sub-class of L<CGI::Snapp> will determine the order in which class-level callbacks are triggered.

=head2 add_header(@headers)

Adds headers to the list which will be sent to the HTTP client.

Returns all headers as a hash.

See also L</delete_header(@keys)>, L</header_add(@headers)>, L</header_props([@headers])>, L</header_type([$option])> and L</How does add_header() differ from header_add()?>.

=head2 call_hook($hook, @args)

Call the named hook. $hook is forced to be lower-case.

Returns a hashref of the number of callbacks actually called, where the keys are 'class' and 'object', and the values are integer counts.

@args takes various values, depending on the name of the callback:

=over 4

=item o init

Here, @args is the hash of options passed in to L</new()>.

Defaults to calling CGI::Snapp::cgiapp_init(@args).

=item o prerun

@args is the name of the run mode.

Defaults to calling CGI::Snapp::cgiapp_prerun($run_mode).

=item o postrun

@args is a scalarref, where the scalar is the output generated by the run mode method. This scalar does not yet have the HTTP headers attatched (if any).

Defaults to calling CGI::Snapp::cgiapp_postrun(\$html).

=item o teardown

@args is not used in this case.

Defauts to calling CGI::Snapp::teardown().

=back

If you call an unregistered hook, the call is just ignored.

See L</new_hook($hook)> and L</add_hook($hook, @args)> if you wish to register a new type of hook.

=head2 cgiapp_get_query()

Returns the query object.

This method only creates an object of type L<CGI> when a query object is needed.

Alternately, you can pass your own query object to the L</query([$q])> method.

You can override this method in your sub-class, if you wish to provide a L<CGI>-compatible object, such as a L<CGI::Simple> object, or similar. If not using L<CGI>, note:

=over 4

=item o The object must have a param() method

Normally, your object just needs to have a L</param([@params])> method, for it to be 'similar enough' to a L<CGI> object.

=item o The object may need a header() method

This is called if L</header_type([$option])> returns 'header'.

=item o The object may need a redirect() method

This is called if L</header_type([$option])> returns 'redirect'.

=item o If you use the 'path_info' option in the call to L</mode_param([@new_options])>

In this case the path_info() method will be called on your object.

=item o If you call L</dump_html()>, which is the default run mode method for the default run mode 'start'

Lastly, if you don't override the 'start' run mode, the L</dump_html()> method (of L<CGI::Snapp>) is called, which in turn calls the Dump() and escapeHTML() methods of your object.

=back

=head2 cgiapp_init()

Does nothing. You implement it in a sub-class, if desired.

Defaults to returning nothing.

=head2 cgiapp_prerun()

Does nothing. You implement it in a sub-class, if desired.

Defaults to returning nothing.

=head2 cgiapp_postrun()

Does nothing. You implement it in a sub-class, if desired.

Defaults to returning nothing.

=head2 delete($key)

Deletes a (key => value) pair from the hash of private storage managed by L</param([@params])>, so a later call to param($key) will return undef.

Returns the value deleted, or undef if $key is absent.

=head2 delete_header(@keys)

Deletes headers from the list which will be sent to the HTTP client.

@keys are the names of the headers you wish to delete.

Returns the remaining headers as a hash.

See also L</add_header(@headers)>, L</header_add(@headers)>, L</header_props([@headers])>, L</header_type([$option])> and L</How does add_header() differ from header_add()?>.

=head2 dump()

Returns the same string as does L</dump_html()>, but without any HTML.

=head2 dump_html()

Returns a nicely-formatted block of HTML, i.e. a set of paragraphs, containing:

=over 4

=item o The run mode

=item o The query parameters

This is derived from the query object's Dump() method.

=item o The environment

This is derived from %ENV.

=back

See L</cgiapp_get_query()> for how to influence the type of query object used.

=head2 error_mode([$method_name])

Sets and gets the name of the error mode method.

Note: This is a method name, not a run mode as is returned from L</start_mode([$run_mode])>.

Here, the [] indicate an optional parameter.

Default: ''.

Returns the current error mode method name.

=head2 forward($run_mode[, @args])

Switches from the current run mode to the given $run_mode, passing the optional @args to the new mode's method.

For this to work, you must have previously called $self -> run_modes($run_mode => 'some_method'), so the code
knows which method it must call.

Just before the method associated with $run_mode is invoked, the current run mode is set to $run_mode, and any
methods attached to the hook 'forward_prerun' are called.

Calling this hook gives you the opportunity of making any preparations you wish before the new run mode is entered.

Finally, $run_mode's method is called, using @args as its arguments.

Returns the output of the $run_mode's method.

See t/forward.t and t/lib/CGI/Snapp/ForwardTest.pm for sample code.

If you wish to interrupt the current request, and redirect to an external url, then the
L</redirect($url[, $status])> method is probably what you want.

=head2 get_current_runmode()

Returns the name of the current run mode.

=head2 header_add(@headers)

Adds I<and sometimes deletes> headers from the list which will be sent to the HTTP client.
This strange behaviour is copied directly from L<CGI::Application>.

Returns the remaining headers as a hash.

Deprecated.

See also L</add_header(@headers)>, L</delete_header(@keys)>, L</header_props([@headers])>, L</header_type([$option])> and L</How does add_header() differ from header_add()?>.

=head2 get_callbacks($type, $hook)

Gets callback information associated with the given $type (class/object) and $hook.

$type is 'class' for class-level callbacks, and 'object' for object-level callbacks.

Values for $type:

=over 4

=item o 'class'

get_callbacks('class', $hook) returns a I<hashref>.

The keys of this hashref are the class names which have registered callbacks for $hook.

The values of this hashref are arrayrefs of method names or references.

=item o 'object'

get_callbacks('object', $hook) returns an I<arrayref>.

The values of this arrayref are arrayrefs of method names or references.

=back

See t/defaults.pl for sample code.

=head2 header_props([@headers])

Sets the headers to be sent to the HTTP client. These headers are expected to be a hash of L<CGI>-compatible HTTP header properties.
These properties will be ignored (sic) or passed directly to the header() or redirect() method of the L</query([$q])> object, depending on the value returned by L</header([$option])>.

Returns all headers as a hash.

See also L</add_header(@headers)>, L</delete_header(@keys)>, L</header_add([@headers])>, L</header_type([$option])> and L</How does add_header() differ from header_add()?>.

=head2 header_type([$option])

Sets and gets the type of HTTP headers to output.

Here, the [] indicate an optional parameter.

Returns the current header type.

Possible values for $option:

=over 4

=item o 'header'

The default. Uses the hash returned by L</header_props([@headers])> to generate a set of HTTP headers to send to the HTTP client.

=item o 'none'

Don't output any headers. See also the L</send_output([$Boolean)]> method.

In this case the HTTP status is set to 200.

=item o 'redirect'

Generates a redirection header to send to the HTTP client.

=back

=head2 log($level, $string)

If a logger object exists, then this calls the log() method of that object, passing it $level and $string.

Returns nothing.

So, the body of this method consists of this 1 line:

	$self -> logger -> log($level => $string) if ($self && $self -> logger);

Up until V 1.03, this used to call $self -> logger -> $level($s), but the change was made to allow
simpler loggers, meaning they did not have to implement all the methods covered by $level().
See CHANGES for details. For more on log levels, see L<Log::Handler::Levels>.

=head2 logger([$logger_object])

Sets and gets the logger object (of type L<Log::Handler>.

Here, the [] indicate an optional parameter.

'logger' is a parameter to L</new()>. See L</Constructor and Initialization> for details.

Also, see L</How do I use my own logger object?>.

=head2 mode_param([@new_options])

Sets and gets the option which defines how to determine the run mode.

Returns the current setting.

Here, the [] indicate an optional parameter.

There are various values which @new_options can take:

=over 4

=item o Not specified

Just returns the current setting.

=item o A string

The value of that string ($new_options[0]) is the name of the CGI form field, and the value of this form field will be the name of the run mode.

So, mode_param('rm') means the CGI form field called 'rm' contains the name of the run mode. This is the default.

=item o A subref

If $new_options[0] is a reference to a callback (method), call that method when appropriate to determine the run mode.

See t/run.modes.pl's test_7() for an example of this. It uses t/lib/CGI/Snapp/RunModes.pm.

=item o 2 * N parameters, specified as a arrayref, hashref or array

Here, 2 * N means there must be an even number of parameters, or the code calls L<Carp>'s croak($message).

The array is expected to be of the form: (path_info => $integer[, param => $string]).

Use (path_info => $integer) to set the run mode from the value of $ENV{PATH_INFO}, which in turn is set by the web server from the path info sent by the HTTP client.
(path_info => 0) means $ENV{PATH_INFO} is ignored. The $integer is explained in full just below.

If the optional (param => $string) part is supplied, then $string will be name of the CGI form field to use if there is no $ENV{PATH_INFO}.

=back

The usage of (path_info => $integer):

Let's say $ENV{PATH_INFO} is 'a/b/c/d/e'. Then here's how to use $integer to select various components of that path info:

=over 4

=item o (path_info => 1): 'a' will be the run mode.

=item o (path_info => 2): 'b' will be the run mode. And so on...

=item o (path_info => -1): 'e' will be the run mode.

=item o (path_info => -2): 'd' will be the run mode. And so on...

=back

Summary:

In all cases, the name of the run mode determined - during a call to L</run()> - by your chosen mechanism I<must> be a key in the dispatch table (hash) returned by the
L</run_modes([$option])> method, since that hash is used to find the name of the method to call to process the given run mode. If it's not a key, the code calls L<Carp>'s
croak($message).

=head2 new()

See L</Constructor and Initialization> for details on the parameters accepted by L</new()>.

Returns an object of type L<CGI::Snapp>.

=head2 new_hook($hook)

Reserves a slot in the dispatch table for the named hook. $hook is forced to be lower-case.

Returns 1, since that's what L<CGI::Application> does, for some reason.

The pre-defined slots are called 'error', 'init', 'prerun', 'postrun' and 'teardown', so there is no need to call new_hook() for those.

For help populating this slot, see L</add_callback($hook, $option)>.

=head2 param([@params])

Sets and gets application-specific ($key => $value) pairs.

I.e. implements a hash of private storage for your app, which can be initialized via new(PARAMS => {...}) or by calls to param(...).

Here, the [] indicate an optional parameter.

Use this to store special values, and retrieve them later.

Thus, you can at any stage do this:

	$app -> param($key => $value);
	...
	my($value) = $app -> param($key);

Or, in your CGI script, start with:

	#!/usr/bin/env perl
	use KillerApp;
	my($config_file) = '/web/server/private/config/dir/config.ini';
	KillerApp -> new(PARAMS => {config_file => $config_file}) -> run;

where your config file looks like:

	[template_stuff]
	template_path = /web/server/private/template/dir/web.page.tx
	[other_stuff]
	...

Then, in the L</cgiapp_init()> method, or the L</setup()> method, in your sub-class of L<CGI::Snapp> (L<Config::Tiny>'s read() returns a hashref):

	use Config::Plugin::Tiny; # Uses Config::Tiny.
	...
	$self -> param(config => config_tiny($self -> param('config_file') ) );
	...
	my($template_path) = ${$self -> param('config')}{template_stuff}{template_path};

In this way a set of 4-line CGI scripts with different config file names can run the same code.

Possible values for @params:

=over 4

=item o Not specified

Returns an array of the names of the parameters previously set.

	my(@names) = $self -> param;

=item o 1 parameter

Returns the value of the named parameter, or undef if it has not had a value set.

	my($value) = $self -> param($name);

=item o 2 * N parameters, specified as a arrayref, hashref or array

Sets the N (key => value) pairs, for later retrieval.

Here, 2 * N means there must be an even number of parameters, or the code calls L<Carp>'s croak($message).

Further, if N == 1, returns the value supplied.

	my($value) = $self -> param(key_1 => 'value_1'); # Returns 'value_1'.

	$self -> param(key_1 => 'value_1', key_2 => 'value_2', ...); # Returns undef.

=back

=head2 prerun_mode($string)

Set the name of the run mode which is about to be executed.

Returns the current run mode.

prerun_mode($string) can only be called from with your L</cgiapp_prerun()> method.

Despite that restriction, L</cgiapp_prerun()> can use any information whatsoever to determine a run mode.

For example, it could get parameters from the query object, and use those, perhaps together with config data, to get yet more data from a database.

=head2 psgi_app($args_to_new)

Returns a L<PSGI|http://plackperl.org/>-compatible coderef which, when called, runs your sub-class of L<CGI::Snapp>
as a L<PSGI|http://plackperl.org/> app.

$args_to_new is a hashref of arguments that are passed into the constructor (L</new()>) of your application.

You can supply you own query object, with psgi_app({QUERY => Some::Object -> new}). But really there's no point.
Just let the code create the default query object, which will be of type L<CGI::PSGI>.

L<CGI::Application> also provides sub run_as_psgi(), but we have no need of that.

Note: This method, psgi_app(), is very similar to L<CGI::Snapp::Dispatch/as_psgi(@args)>, but the latter contains
this line (amongst other logic):

	$app -> mode_param(sub {return $rm}) if ($rm);

where the current method does not. This means L<CGI::Snapp::Dispatch> can determine the run mode from the path info
sent from the web client, whereas if you use psgi_app(), your sub-class of L<CGI::Snapp> must contain all the logic
required to determine the run mode.

=head2 query([$q])

Sets and gets the L<CGI>-compatible object used to retrieve the CGI form field names and values. This object also needs to be able to generate HTTP headers. See L</header_props([@headers])>.

Here, the [] indicate an optional parameter.

Alternately, you can pass in such an object via the 'QUERY' parameter to L</new()>.

=head2 redirect($url[, $status])

Interrupts the current request, and redirects to the given (external) $url, optionally setting the HTTP status to $status.

Here, the [] indicate an optional parameter.

The redirect happens even if you are inside a method attached to the 'prerun' hook when you call redirect().

Specifically, this method does these 3 things:

=over 4

=item o Sets the HTTP header 'location' to the given $url

=item o Sets the HTTP 'status' (if provided) to $status

=item o Sets the L<CGI::Snapp> header type to 'redirect'

=back

See t/redirect.t and t/lib/CGI/Snapp/RedirectTest.pm for sample code.

If you just want to display the results of another run mode within the same application, then the
L</forward($run_mode[, @args])> method is probably what you want.

=head2 run()

Returns the output generated by the run mode method.

See L</send_output([$Boolean])> for controlling whether or not this output is also sent to the HTTP client.

You must call the L</run()> method before anything useful can possibly happen. Here is a typical L<CGI> script:

	#!/usr/bin/env perl

	use KillerApp;
	KillerApp -> new -> run;

See L</The Flow of Control> for details of the many things which happen during the call to run().

=head2 run_modes([$option])

Sets and gets the dispatch table, which is just a hash mapping run mode names to method names.

Returns the dispatch table as a hash.

Here, the [] indicate an optional parameter.

When you call L</run()> the code firstly determines the run mode, and then calls run_modes() to get the dispatch table,
and then calls a method by getting the method name from the value in this dispatch table corresponding to that run mode.

The parameter list passed to your run mode method is discussed in L</The Simple View>.

There are 3 values which $option can take:

=over 4

=item o An arrayref

This is an abbreviated way of specifying the dispatch table. The arrayref's elements are strings, each of which specifies a run mode and a method I<of the same name>. Hence:

	$app -> run_modes([qw/one two/]);

defines 2 run modes, 'one' and 'two', and these are automatically mapped (by L<CGI::Snapp>) to 2 methods called 'one' and 'two', respectively.

It's very simple, and is, at least at first, probably all you'll need. It just requires you to implement the methods 'one' and 'two' in your sub-class of L<CGI::Snapp>.

=item o A hashref

Use this to specify both the run modes and their corresponding method names. Thus, something like:

	$app -> run_modes({one => 'sub_1', two => sub {}, three => \&sub_3});

says you'll implement 3 methods: The first is a method called 'sub_1', the second is an anonymous sub, and the 3rd is the named subref.

=item o A hash

If $option is neither an arrayref nor a hashref, it is assumed to be an array (i.e. a hash!) and treated as though it were a hashref.

=back

Here's how the dispatch table is initialized:

=over 4

=item o After calling new()

Since the default start mode is 'start', the dispatch table defaults to (start => 'dump_html'), where the L</dump_html()> method is implemented in L<CGI::Snapp>.
Of course, you can override that in your sub-class.

=item o After calling new() and start_mode('first')

This time the dispatch table will still be (start => 'dump_html'), from calling L</new()>, but now if the code cannot determine a run mode from the L<CGI> parameters, it will
default to 'first', I<which is not in the dispatch table>. So, the code calls L<Carp>'s croak($message).

That means that if you call L</start_mode($run_mode)>, it only makes sense if you also call L</run_modes([$option])> where $option is {$run_mode => 'some sub name'}.

=back

Lastly, note that calling L</run_modes([$option])> does I<not> remove the default (start => 'dump_html') entry from the dispatch table. The code just ignores it. It affects test code, though.
See sub test_4 in t/run.modes.pl for instance.

=head2 send_output([$Boolean])

Sets and gets the flag which determines whether or not the HTML output generated by your code is actually sent to the HTTP client.

Here, the [] indicate an optional parameter.

The default is 1, meaning yes, send the output to the HTTP client.

During your call to L</new()>, this code is executed:

	$self -> send_output(0) if ($ENV{CGI_SNAPP_RETURN_ONLY});

which means backward-compatible behaviour is supported for those people wishing to stick with L<CGI::Application>'s (negative logic) mechanism to turn off transmission.

And yes, any value which Perl regards as true will suffice for both this method and the value of that environment variable, not just the value 1.

The tests which ship with this mode, for example, almost always turn this flag off to stop output appearing which would confuse the test harness.
The one time in testing when the flag is not reset is when I'm testing the default value of this flag.

'send_output' is a parameter to L</new()>. See L</Constructor and Initialization> for details.

=head2 setup()

Does nothing. You implement it in a sub-class, if desired.

Defaults to returning nothing.

=head2 start_mode([$run_mode])

Sets and gets the name of the run mode to start from.

Returns the current start mode.

Here, the [] indicate an optional parameter.

Default: 'start'.

You're always going to need a start mode, because when your user first sends a request, to, say:

	http://my.web.site/cgi-bin/script.cgi

there is no L<CGI> form data submitted with that request.

So, your code (script.cgi, which uses a sub-class of L<CGI::Snapp>), must determine and execute a run mode (a method) without the user having indicated which run mode to use.

That is, your code must default to something, and the default is a run mode called 'start', which defaults to calling a method called L</dump_html()> (within L<CGI::Snapp>).

In other words, in the very simplest case, you don't have to change the name of the initial run mode ('start'), you just have to implement a suitable method, and then call L</run_modes([$option])> to tell
L<CGI::Snapp> the name of your method.

=head2 teardown()

Does nothing. You implement it in a sub-class, if desired.

Defaults to returning nothing.

Typically, teardown() is where you put the code which saves session state, closes logs, disconnects from databases, etc.

You may find it is mandatory for you to override teardown() in your sub-class, especially in persistent environments.

In particular, you are I<strongly> encouraged to read L<the Data::Session FAQ|https://metacpan.org/module/Data::Session#FAQ> and
L<the Data::Session Troubleshooting guidelines|https://metacpan.org/module/Data::Session#Troubleshooting> before writing your own teardown() method.

=head1 FAQ

=head2 Do I need to output a header when using Ajax?

Yes. At least, when I use jQuery I must do this in a run mode:

	$self -> add_header(Status => 200, 'Content-Type' => 'text/html; charset=utf-8');

	return $self -> param('view') -> search -> display($name, $row);

Here, display() returns a HTML table wrapped in 2 divs in the jQuery style, which becomes the return value
of the run mode.

The quoted code is in L<App::Office::Contacts::Controller::Exporter::Search>'s display (the run mode), and the
display() method being called above is in L<App::Office::Contacts::View::Search>, but it will be the same no
matter which Perl app you're running.

=head2 Does CGI::Snapp V 1.01 support PSGI?

Yes. See L</psgi_app()> and L<CGI::Snapp::Dispatch>.

=head2 Is there any sample code?

Yes. See t/*.pl and all the modules in t/lib/*.

See also L<CGI::Snapp::Dispatch> and its t/psi.args.t.

=head2 Why did you fork CGI::Application?

In order to study the code. I want to understand how L<CGI::Application>, L<CGI::Application::Dispatch> and L<CGI::Application::Dispatch::PSGI> work in sufficient detail that I
can put my forks of those modules into production - I<in my own code>.

Also - obviously - it allows me to implement what I think are code cleanups. And lastly, it allows me to indulge myself in a user-friendly release strategy.

Clearly, those are the same reasons which motivated me to fork L<CGI::Session> into L<Data::Session>.

As a byproduct of forking, rewriting the documentation has also allowed me to cut about 20,000 bytes from the source file Snapp.pm compared to Application.pm.

=head2 What version is the fork of CGI::Application based on?

CGI::Snapp V 1.00 is based on CGI::Application V 4.31. CGI::Snapp V 1.01 is based on CGI::Application V 4.50.

=head2 How does CGI::Snapp differ from CGI::Application?

My usage of the latter's features was always minimalistic, so - at least initially - I will only support a basic set of L<CGI::Application>'s features.

These are the major differences:

=head3 Clean up 'run_mode' 'v' runmode

Except for method calls where 'runmode' is unfortunately used, e.g L</get_current_runmode()>, 'run_mode' and 'run mode' have been adopted as the norm.

=head3 Always call croak and not a combination of croak and die

Also, every message passed to croak matches /^Error/ and ends with "\n".

=head3 No global variables (except for the inescapable dispatch table of class-level callbacks)

This means things like $$self{__CURRENT_RUNMODE} and $$self{__PRERUN_MODE_LOCKED} etc are only be available via method calls.

Here is a list of the global variables in L<CGI::Application>, and the corresponding methods in L<CGI::Snapp>, in alphabetical order:

=over 4

=item o __CALLBACK_CLASSES => %callback_classes

=item o __CURRENT_RUNMODE => L</get_current_runmode()>

=item o __CURRENT_TMPL_EXTENSION => Not implemented

=item o __ERROR_MODE => L</error_mode([$method_name])>

=item o __HEADER_PROPS => L</header_props([@headers])>

=item o __HEADER_TYPE => L</header_type([$option])>

=item o __HTML_TMPL_CLASS => Not implemented

=item o __INSTALLED_CALLBACKS => L</installed_callbacks()>

=item o __IS_PSGI => _psgi()

=item o __MODE_PARAM => L</mode_param([@new_options])>

=item o __PARAMS => L</param([@params])>

=item o __PRERUN_MODE => L</prerun_mode($string)>

=item o __PRERUN_MODE_LOCKED => _prerun_mode_lock([$Boolean])

=item o __QUERY_OBJ => L</query([$q])>

=item o __RUN_MODES => L</run_modes([$option])>

=item o __START_MODE => L</start_mode([$run_mode])>

=item o __TMPL_PATH => Not implemented

=back

The leading '_' on some CGI::Snapp method names means all such methods are for the exclusive use of the author of this module.

=head3 New methods

=over 4

=item o L</add_header(@headers)>

=item o L</get_callbacks($type, $hook)>

=item o L</log($level, $string)>

=item o L</logger($logger_object)>

=item o L</send_output([$Boolean])>

=back

=head3 Deprecated methods

=over 4

=item o L</header_add(@headers)>

See L</How does add_header() differ from header_add()?>.

=back

=head3 Unsupported methods

=over 4

=item o html_tmpl_class()

=item o load_tmpl()

=item o run_as_psgi()

=item o tmpl_path()

=back

See below for details.

=head3 Enchanced features

=over 4

=item o Use of utf8::downgrade() to turn off utf8 bit on headers

=item o Use of Try::Tiny rather than eval

Ideally, this won't be detectable, and hence won't matter.

=item o call_hook(...) returns a hashref - keys are 'class' and 'object' - of counts of hooks actually called

=item o delete_header(A list)

See L</delete_header(@keys)> for how to delete any number of HTTP headers.

=item o Calling the error_mode() method

This call is protected by Try::Tiny.

=item o Calling mode_param([...])

mode_param() can be called with an arrayref, as in $self -> mode_param([qw/path_info -2/]). See t/run.modes.pl for details.

=item o Calling param([...])

param() can be called with an arrayref, as in $self -> param([qw/six 6 seven 7/]). See t/params.pl for details.

=back

=head3 No special code for Apache, mod_perl or plugins

I suggest that sort of stuff is best put in sub-classes.

For the record, I don't use Apache or mod_perl. For web servers I use L<Engine X|http://wiki.nginx.org/Main>, L<mini_httpd|http://www.acme.com/software/mini_httpd/>, L<Starman> and (for development) L<Plack>.
As it happens, I don't use any plugins (for L<CGI::Application>) either.

So, it's not that I refuse to support them, it's just that I won't put any special code in place unless asked to do so. And then, only if it fits into my philosophy
of where this code is headed. And that includes potential re-writes of L<CGI::Application::Dispatch>, L<CGI::Application::Dispatch::PSGI> and L<CGI::Application::Server>.

=head3 Upper-case parameters to L</new()>

Yes, I know SHOUTING parameter names is ugly, but I<some> back-compat feautures must be supported, right?. Hence L</new()> accepts PARAMS and QUERY.

=head3 Template Mangement

L<CGI::Snapp> contains no special processing for L<HTML::Template>, or indeed any templating system. Rationale:

There is no support because I see L<CGI::Application>'s usage as a manifestation of an (understandable) design fault. If anything, TMPL_PATH should have been CONFIG_PATH.

That is, one of the methods in your sub-class - cgiapp_init(), cgiapp_prerun() or setup(), or a hook - should load a config file, and in that file is the place to put a template path,
along with all those other things typically needed: Paths to CSS and Javascript libraries, database connexion parameters, etc.

Then, each different sub-class can load a different config file, if necessary, and hence use a different set of templates. Likewise, testing and production versions of config files
can be deployed, and so on.

For example, first read in a hashref of config options (see L<Config::Plugin::Tiny>), and then set up a rendering engine:

	use Config::Plugin::Tiny; # For config_tiny().
	use Text::Xslate;
	...
	$self -> param
	(
		config => config_tiny('/some/dir/some.file.ini');
	);
	$self -> param
	(
		renderer => Text::Xslate -> new
		(
		input_layer => '',
		path        => ${$self -> param('config')}{template_path},
		)
	);

Then, later, use the renderer like this (in a View component of the MVC style):

	my($output) =
	{
		div     => 'order_message_div',
		content => $self -> param('renderer') -> render('note.tx', $param),
	};

	return JSON::XS -> new -> utf8 -> encode($output);

=head2 How does add_header() differ from header_add()?

Firstly, a note about the name of header_add(). It really should have been called add_header() in the first place, just like add_callback().
After 70 years of programming, programmers should have learned that I<the verb always and everywhere comes first> in function/method/sub names.
I do understand the choice of header_add(): It's by analogy with header_props() and header_type(). I used to argue like that myself :-(.

OK, here's how they differ. Consider this code.

	$app -> header_add(a => 1,  b => [2], c => 3,    d => [4])  or call add_header(same params)
	$app -> header_add(a => 11, b => 22,  c => [33], d => [44]) or call add_header(same params)

Output:

	(a => 11,      b => 22,      c => [3, 33], d => [4, 44]) - header_add() - CGI::Snapp and CGI::Application
	(a => [1, 11], b => [2, 22], c => [3, 33], d => [4, 44]) - add_header() - CGI::Snapp

You can see, for both modules, L</header_add(@headers)> I<deletes> a pre-exising header when the incoming header's value is a scalar.
L<CGI::Snapp>'s L</header_add(@headers)> emulates L<CGI::Application>'s weird L</header_add(@headers)> logic here.

But, if you want to add headers without violating the L<Principle of Least Surprise|http://en.wikipedia.org/wiki/Principle_of_least_surprise>, use L</add_header(@headers)>.
Also, L</delete_header(@keys)> is the counterpart of L</add_header(@headers)>.

For this reason, L</header_add(@headers)> is deprecated.

=head2 I'm confused because you called your tests t/*.pl

Well, not really. t/test.t is I<the> test script. It runs all t/*.pl helper scripts. Run it thusly: shell> prove -Ilib -v t/

You can run any single test helper script - e.g. t/defaults.pl - like this: shell> prove -Ilib -v t/defaults.pl

=head2 Do you expect authors of plugins for CGI::App to re-write their code?

Nope. But they are free to do so...

=head2 Are you going to release any plugins?

Yes. Check out L</See Also>.

=head2 How do I sub-class CGI::Snapp?

There is an example in t/subclass.pl, which uses t/lib/CGI/Snapp/SubClass.pm. The latter is:

	package CGI::Snapp::SubClass;

	use parent 'CGI::Snapp';
	use strict;
	use warnings;

	use Moo;

	has => verbose
	(
		is       => 'rw',
		default  => sub{return 0},
		required => 0,
	);

	our $VERSION = '1.08';

	# --------------------------------------------------

	1;

The steps are:

=over 4

=item o Create the file

Just copy t/lib/CGI/Snapp/SubClass.pm to get started.

=item o Declare the accessors

fieldhash my %verbose => 'verbose';

is how it's done. This means you can now have all these features available:

=over 4

=item o Use verbose when calling new()

	CGI::Snapp::SubClass -> new(verbose => 1);

=item o Use verbose() as a getter

	my($verbosity) = $self -> verbose;

=item o Use verbose($Boolean) as a setter

	$self -> verbose(1);

=back

=back

See t/subclass.pl for how it works in practice.

=head2 How do I use my own logger object?

Study the sample code in L<CGI::Snapp::Demo::Four>, which shows how to supply a L<Config::Plugin::Tiny> *.ini file to configure the logger via the wrapper class
L<CGI::Snapp::Demo::Four::Wrapper>.

Also, see any test script, e.g. t/basic.pl.

=head2 What else do I need to know about logging?

The effect of logging varies depending on the stage at which it is activated.

And, your logger must be compatible with L<Log::Handler>.

If you call your sub-class of CGI::Snapp as My::App -> new(logger => $logging), then logging is turned on at the
earliest possible time. This means calls within L</new()>, to L</call_hook($hook, @args)> (which calls cgiapp_init() )
and L</setup()>, are logged. And since you have probably overridden setup(), you can do this in your setup():

	$self -> log($level => $message); # Log anything...

Alternately, you could override L</cgiapp_init()> or L</cgiapp_prerun()>, and create your own logger object
within one of those.

Then you just do $self -> logger($my_logger), after which logging is immediately activated. But obviously that
means the calls to call_hook() and setup() (in new() ) will not produce any log output, because by now they have
already been run.

Nevertheless, after this point (e.g. in cgiapp_init() ), since a logger is now set up, logging will produce output.

Remember the prefix 'Local::Wines::Controller' mentioned in L<CGI::Snapp::Dispatch/PSGI Scripts>?

Here's what it's cgiapp_prerun() looks like:

	sub cgiapp_prerun
	{
		my($self) = @_;

		# Can't call, since logger not yet set up.
		# Well, could, but it's pointless...

		#$self -> log(debug => 'cgiapp_prerun()');

		$self -> param(config => Local::Config -> new(module_name => 'Local::Wines') -> get_config);
		$self -> set_connector; # The dreaded DBIx::Connector.
		$self -> logger(Local::Logger -> new(config => $self -> param('config') ) );

		# Log the CGI form parameters.

		my($q) = $self -> query;

		$self -> log(info  => '');
		$self -> log(info  => $q -> url(-full => 1, -path => 1) );
		$self -> log(info  => "Param: $_: " . $q -> param($_) ) for $q -> param;

		# Other controllers add their own run modes.

		$self -> run_modes([qw/display/]);
		$self -> log(debug => 'tmpl_path: ' . ${$self -> param('config')}{template_path});

		# Set up the database, the templater and the viewer.
		# We pass the templater into the viewer so all views share it.

		# A newer design has the controller created in the db class.

		$self -> param
			(
			 db => Local::Wines::Database -> new
			 (
			  dbh    => $self -> param('connector') -> dbh,
			  logger => $self -> logger,
			  query  => $q,
			 )
			);

		$self -> param
			(
			 templater => Text::Xslate -> new
			 (
			  input_layer => '',
			  path        => ${$self -> param('config')}{template_path},
			 )
			);

		$self -> param
			(
			 view => Local::Wines::View -> new
			 (
			  db        => $self -> param('db'),
			  logger    => $self -> logger,
			  templater => $self -> param('templater'),
			 )
			);

		# Output this here so we know how far we got.

		$self -> log(info  => 'Session id: ' . $self -> param('db') -> session -> id);

	} # End of cgiapp_prerun.

=head2 So, should I upgrade from CGI::Application to CGI::Snapp?

Well, that's up to you. Of course, if your code is not broken, don't fix it. But, as I said above, L<CGI::Snapp> will be going in to production in my work.

The biggest problem for you will almost certainly be lack of support for load_tmp() and tmpl_path().

Still, you're welcome to sub-class L<CGI::Snapp> and fix that...

=head1 Troubleshooting

=head2 It doesn't work!

Hmmm. Things to consider:

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
	CGI::Snapp -> new(logger => $logger, ...) -> run;

Then, in your methods, just use:

	$self -> log(debug => 'A string');

The entry to each method in CGI::Snapp and L<CGI::Snapp::Dispatch> is logged using this technique,
although only when maxlevel is 'debug'. Lower levels for maxlevel do not trigger logging.
See the source for details.

=item o The system Perl 'v' perlbrew

Are you using perlbrew? If so, recall that your web server will use the first line of your L<CGI> script to find a Perl,
and that line probably says something like #!/usr/bin/env perl.

So, perhaps you'd better turn perlbrew off and install L<CGI::Snapp> and this module under the system Perl, before trying again.

=item o Generic advice

L<http://www.perlmonks.org/?node_id=380424>.

=back

=head1 See Also

L<CGI::Application>

The following are all part of this set of distros:

L<CGI::Snapp> - A almost back-compat fork of CGI::Application

L<CGI::Snapp::Dispatch> and L<CGI::Snapp::Dispatch::Regexp> - Dispatch requests to CGI::Snapp-based objects

L<CGI::Snapp::Demo::One> - A template-free demo of CGI::Snapp using just 1 run mode

L<CGI::Snapp::Demo::Two> - A template-free demo of CGI::Snapp using N run modes

L<CGI::Snapp::Demo::Three> - A template-free demo of CGI::Snapp using the forward() method

L<CGI::Snapp::Demo::Four> - A template-free demo of CGI::Snapp using Log::Handler::Plugin::DBI

L<CGI::Snapp::Demo::Four::Wrapper> - A wrapper around CGI::Snapp::Demo::Four, to simplify using Log::Handler::Plugin::DBI

L<Config::Plugin::Tiny> - A plugin which uses Config::Tiny

L<Config::Plugin::TinyManifold> - A plugin which uses Config::Tiny with 1 of N sections

L<Data::Session> - Persistent session data management

L<Log::Handler::Plugin::DBI> - A plugin for Log::Handler using Log::Hander::Output::DBI

L<Log::Handler::Plugin::DBI::CreateTable> - A helper for Log::Hander::Output::DBI to create your 'log' table

=head1 Machine-Readable Change Log

The file Changes was converted into Changelog.ini by L<Module::Metadata::Changes>.

=head1 Version Numbers

Version numbers < 1.00 represent development versions. From 1.00 up, they are production versions.

=head1 Credits

Please read L<CGI::Application/CREDITS> and L<CGI::Application::Dispatch/CONTRIBUTORS>, since a great deal of work has gone into both of those modules.

=head1 Repository

L<https://github.com/ronsavage/CGI-Snapp>

=head1 Support

Email the author, or log a bug on RT:

L<https://rt.cpan.org/Public/Dist/Display.html?Name=CGI::Snapp>.

=head1 Author

L<CGI::Snapp> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2012.

Home page: L<http://savage.net.au/index.html>.

=head1 Copyright

Australian copyright (c) 2012, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License, a copy of which is available at:
	http://www.opensource.org/licenses/index.html

=cut
