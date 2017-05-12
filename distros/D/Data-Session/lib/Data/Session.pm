package Data::Session;

use parent 'Data::Session::Base';
no autovivification;
use strict;
use warnings;

use Class::Load ':all'; # For try_load_class() and is_class_loaded().

use File::Spec;  # For catdir.
use File::Slurp; # For read_dir.

use Hash::FieldHash ':all';

use Try::Tiny;

fieldhash my %my_drivers       => 'my_drivers';
fieldhash my %my_id_generators => 'my_id_generators';
fieldhash my %my_serializers   => 'my_serializers';

our $errstr  = '';
our $VERSION = '1.17';

# -----------------------------------------------

sub atime
{
	my($self, $atime) = @_;
	my($data) = $self -> session;

	# This is really only for use by load_session().

	if (defined $atime)
	{
		$$data{_SESSION_ATIME} = $atime;

		$self -> session($data);
		$self -> modified(1);
	}

	return $$data{_SESSION_ATIME};

} # End of atime.

# -----------------------------------------------

sub check_expiry
{
	my($self) = @_;

	if ($self -> etime && ( ($self -> atime + $self -> etime) < time) )
	{
		($self -> verbose) && $self -> log('Expiring id: ' . $self -> id);

		$self -> delete;
		$self -> expired(1);
	}

} # End of check_expiry.

# -----------------------------------------------

sub clear
{
	my($self, $name) = @_;
	my($data) = $self -> session;

	if (! $name)
	{
		$name = [$self -> param];
	}
	elsif (ref($name) ne 'ARRAY')
	{
		$name = [$name];
	}
	else
	{
		$name = [grep{! /^_/} @$name];
	}

	for my $key (@$name)
	{
		delete $$data{$key};
		delete $$data{_SESSION_PTIME}{$key};

		$self -> modified(1);
	}

	$self -> session($data);

	return 1;

} # End of clear.

# -----------------------------------------------

sub cookie
{
	my($self)   = shift;
	my($q)      = $self -> query;
	my(@param)  = ('-name' => $self -> name, '-value' => $self -> id, @_);
	my($cookie) = '';

	if (! $q -> can('cookie') )
	{
	}
	elsif ($self -> expired)
	{
		$cookie = $q -> cookie(@param, -expires => '-1d');
	}
	elsif (my($t) = $self -> expire)
	{
		$cookie = $q -> cookie(@param, -expires => "+${t}s");
	}
	else
	{
		$cookie = $q -> cookie(@param);
	}

	return $cookie;

} # End of cookie.

# -----------------------------------------------

sub ctime
{
	my($self) = @_;
	my($data) = $self -> session;

	return $$data{_SESSION_CTIME};

} # End of ctime.

# -----------------------------------------------

sub delete
{
	my($self)   = @_;
	my($result) = $self -> driver_class -> remove($self -> id);

	$self -> clear;
	$self -> deleted(1);

	return $result;

} # End of delete.

# -----------------------------------------------

sub DESTROY
{
	my($self) = @_;

	$self -> flush;

} # End of DESTROY.

# -----------------------------------------------

sub dump
{
	my($self, $heading) = @_;
	my($data) = $self -> session;

	($heading) && $self -> log($heading);

	for my $key (sort keys %$data)
	{
		if (ref($$data{$key}) eq 'HASH')
		{
			$self -> log("$key: " . join(', ', map{"$_: $$data{$key}{$_}"} sort keys %{$$data{$key} }) );
		}
		else
		{
			$self -> log("$key: $$data{$key}");
		}
	}

} # End of dump.

# -----------------------------------------------

sub etime
{
	my($self) = @_;
	my($data) = $self -> session;

	return $$data{_SESSION_ETIME};

} # End of etime.

# -----------------------------------------------

sub expire
{
	my($self, @arg) = @_;

	if (! @arg)
	{
		return $self -> etime;
	}

	if ($#arg == 0)
	{
		# Set the expiry time of the session.

		my($data) = $self -> session;
		my($time) = $self -> validate_time($arg[0]);

		if ($$data{_SESSION_ETIME} != $time)
		{
			$$data{_SESSION_ETIME} = $time;

			$self -> session($data);
			$self -> modified(1);
		}
	}
	else
	{
		# Set the expiry times of session parameters.

		my($data)     = $self -> session;
		my($modified) = 0;
		my(%arg)      = @arg;

		my($time);

		# Warning: The next line ignores 'each %{@arg}'.

		while (my($key, $value) = each %arg)
		{
			$time = $self -> validate_time($value);

			($time == 0) && next;

			if (! $$data{_SESSION_PTIME}{$key} || ($$data{_SESSION_PTIME}{$key} ne $time) )
			{
				$$data{_SESSION_PTIME}{$key} = $time;

				$modified = 1;
			}
		}

		if ($modified)
		{
			$self -> session($data);
			$self -> modified(1);
		}
	}

	return 1;

} # End of expire.

# -----------------------------------------------

sub flush
{
	my($self) = @_;

	if ($self -> modified && ! $self -> deleted)
	{
		$self -> driver_class -> store
		(
			$self -> id,
			$self -> serializer_class -> freeze($self -> session),
			$self -> etime
		);
	}

	($self -> verbose > 1) && $self -> dump('Flushing. New: ' . $self -> is_new . '. Modified: ' . $self -> modified . '. Deleted: ' . $self -> deleted);

	return 1;

} # End of flush.

# -----------------------------------------------

sub get_my_drivers
{
	my($self)	= @_;
	my($path)	= $self -> _get_pm_path('Driver');

	# Warning: Use sort map{} read_dir, not map{} sort read_dir. But, why?

	my(@driver) = sort map{s/.pm//; $_} read_dir($path);

	($#driver < 0) && die __PACKAGE__ . '. No drivers available';

	($self -> verbose > 1) && $self -> log('Drivers: ' . join(', ', @driver) );

	$self -> my_drivers(\@driver);

} # End of get_my_drivers.

# -----------------------------------------------

sub get_my_id_generators
{
	my($self)	= @_;
	my($path)	= $self -> _get_pm_path('ID');

	# Warning: Use sort map{} read_dir, not map{} sort read_dir. But, why?

	my(@id_generator) = sort map{s/.pm//; $_} read_dir($path);

	($#id_generator < 0) && die __PACKAGE__ . '. No id generators available';

	($self -> verbose > 1) && $self -> log('Id generators: ' . join(', ', @id_generator) );

	$self -> my_id_generators(\@id_generator);

} # End of get_my_id_generators.

# -----------------------------------------------

sub get_my_serializers
{
	my($self)	= @_;
	my($path)	= $self -> _get_pm_path('Serialize');

	# Warning: Use sort map{} read_dir, not map{} sort read_dir. But, why?

	my(@serializer) = sort map{s/.pm//; $_} read_dir($path);

	($#serializer < 0) && die __PACKAGE__ . '. No serializers available';

	($self -> verbose > 1) && $self -> log('Serializers: ' . join(', ', @serializer) );

	$self -> my_serializers(\@serializer);

} # End of get_my_serializers.

# -----------------------------------------------

sub _get_pm_path
{
	my($self, $subdir)	= @_;
	my($path)			= $INC{'Data/Session.pm'};
	$path				=~ s/\.pm$//;

	return File::Spec -> catdir($path, $subdir);
}

# -----------------------------------------------

sub http_header
{
	my($self)   = shift;
	my($cookie) = $self -> cookie;

	my($header);

	if ($cookie)
	{
		$header = $self -> query -> header(-cookie => $cookie, @_);
	}
	else
	{
		$header = $self -> query -> header(@_);
	}

	return $header;

} # End of http_header.

# -----------------------------------------------

sub load_driver
{
	my($self, $arg) = @_;
	my($class)      = join('::', __PACKAGE__, 'Driver', $self -> driver_option);

	try_load_class($class);

	die __PACKAGE__ . ". Unable to load class '$class'" if (! is_class_loaded($class) );

	($self -> verbose > 1) && $self -> log("Loaded driver_option: $class");

	$self -> driver_class($class -> new(%$arg) );

	($self -> verbose > 1) && $self -> log("Initialized driver_class: $class");

} # End of load_driver.

# -----------------------------------------------

sub load_id_generator
{
	my($self, $arg)  = @_;
	my($class)       = join('::', __PACKAGE__, 'ID', $self -> id_option);

	try_load_class($class);

	die __PACKAGE__ . ". Unable to load class '$class'" if (! is_class_loaded($class) );

	($self -> verbose > 1) && $self -> log("Loaded id_option: $class");

	$self -> id_class($class -> new(%$arg) );

	($self -> verbose > 1) && $self -> log("Initialized id_class: $class");

} # End of load_id_generator.

# -----------------------------------------------

sub load_param
{
	my($self, $q, $name) = @_;

	if (! defined $q)
	{
		$q = $self -> load_query_class;
	}

	my($data) = $self -> session;

	if (! $name)
	{
		$name = [sort keys %$data];
	}
	elsif (ref($name) ne 'ARRAY')
	{
		$name = [$name];
	}

	for my $key (grep{! /^_/} @$name)
	{
		$q -> param($key => $$data{$key});
	}

	return $q;

} # End of load_param.

# -----------------------------------------------

sub load_query_class
{
	my($self) = @_;

	if (! $self -> query)
	{
		my($class) = $self -> query_class;

		try_load_class($class);

		die __PACKAGE__ . ". Unable to load class '$class'" if (! is_class_loaded($class) );

		($self -> verbose > 1) && $self -> log('Loaded query_class: ' . $class);

		$self -> query($class -> new);

		($self -> verbose > 1) && $self -> log('Called query_class -> new: ' . $class);
	}

	return $self -> query;

} # End of load_query_class.

# -----------------------------------------------

sub load_serializer
{
	my($self, $arg) = @_;
	my($class)      = join('::', __PACKAGE__, 'Serialize', $self -> serializer_option);

	try_load_class($class);

	die __PACKAGE__ . ". Unable to load class '$class'" if (! is_class_loaded($class) );

	($self -> verbose > 1) && $self -> log("Loaded serializer_option: $class");

	$self -> serializer_class($class -> new(%$arg) );

	($self -> verbose > 1) && $self -> log("Initialized serializer_class: $class");

} # End of load_serializer.

# -----------------------------------------------

sub load_session
{
	my($self) = @_;
	my($id)   = $self -> user_id;

	($self -> verbose > 1) && $self -> log("Loading session for id: $id");

	if ($id)
	{
		my($raw_data) = $self -> driver_class -> retrieve($id);

		($self -> verbose > 1) && $self -> log("Tried to retrieve session for id: $id. Length of raw data: @{[length($raw_data)]}");

		if (! $raw_data)
		{
			$self -> new_session($id);
		}
		else
		{
			# Retrieved an old session, so flag it as accessed, and not-new.

			my($data) = $self -> serializer_class -> thaw($raw_data);

			if ($self -> verbose > 1)
			{
				for my $key (sort keys %{$$data{_SESSION_PTIME} })
				{
					$self -> log("Recovered session parameter expiry time: $key: $$data{_SESSION_PTIME}{$key}");
				}
			}

			$self -> id($id);
			$self -> is_new(0);
			$self -> session($data);

			($self -> verbose > 1) && $self -> dump('Loaded');

			# Check for session expiry.

			$self -> check_expiry;

			($self -> verbose > 1) && $self -> dump('Loaded and checked expiry');

			# Check for session parameter expiry.
			# Stockpile keys to be cleared. We can't call $self -> clear($key) inside the loop,
			# because it updates $$data{_SESSION_PTIME}, which in turns confuses 'each'.

			my(@stack);

			while (my($key, $time) = each %{$$data{_SESSION_PTIME} })
			{
				if ($time && ( ($self -> atime + $time) < time) )
				{
					push @stack, $key;
				}
			}

			$self -> clear($_) for @stack;

			# We can't do this above, just after my($data)..., since it's used just above, as $self -> atime().

			$self -> atime(time);

			($self -> verbose > 1) && $self -> dump('Loaded and checked parameter expiry');
		}
	}
	else
	{
		$self -> new_session(0);
	}

	($self -> verbose > 1) && $self -> log("Loaded session for id: " . $self -> id);

	return 1;

} # End of load_session.

# -----------------------------------------------

sub new
{
	my($class, %arg)  = @_;
	$arg{debug}       ||= 0; # new(...).
	$arg{deleted}     = 0;   # Internal.
	$arg{expired}     = 0;   # Internal.
	$arg{id}          ||= 0; # new(...).
	$arg{modified}    = 0;   # Internal.
	$arg{name}        ||= 'CGISESSID'; # new(...).
	$arg{query}       ||= ''; # new(...).
	$arg{query_class} ||= 'CGI'; # new(...).
	$arg{session}     = {};  # Internal.
	$arg{type}        ||= ''; # new(...).
	$arg{verbose}     ||= 0; # new(...).

	my($self);

	try
	{
		$self  = from_hash(bless({}, $class), \%arg);

		$self -> get_my_drivers;
		$self -> get_my_id_generators;
		$self -> get_my_serializers;
		$self -> parse_options;
		$self -> validate_options;
		$self -> load_driver(\%arg);
		$self -> load_id_generator(\%arg);
		$self -> load_serializer(\%arg);
		$self -> load_session; # Calls user_id() which calls load_query_class() if necessary.
	}
	catch
	{
		$errstr = $_;
		$self   = undef;
	};

	return $self;

} # End of new.

# -----------------------------------------------

sub new_session
{
	my($self, $id) = @_;
	$id            = $id ? $id : $self -> id_class -> generate;
	my($time)      = time;

	$self -> session
	({
		_SESSION_ATIME => $time, # Access time.
		_SESSION_CTIME => $time, # Create time.
		_SESSION_ETIME => 0,     # Session expiry time.
		_SESSION_ID    => $id,   # Session id.
		_SESSION_PTIME => {},    # Parameter expiry times.
	});

	$self -> id($id);
	$self -> is_new(1);

} # End of new_session.

# -----------------------------------------------

sub param
{
	my($self, @arg) = @_;
	my($data) = $self -> session;

	if ($#arg < 0)
	{
		return grep{! /^_/} sort keys %$data;
	}
	elsif ($#arg == 0)
	{
		# If only 1 name is supplied, return the session's data for that name.

		return $$data{$arg[0]};
	}

	# Otherwise, loop over all the supplied data.

	my(%arg) = @arg;

	for my $key (keys %arg)
	{
		next if ($key =~ /^_/);

		# Don't update a value if it's the same as the original value.
		# That way we don't update the last-access-time.
		# We're effectively testing $x == $y, but we're not testing to ensure:
		# o undef == undef
		# o 0 == 0
		# o '' == ''
		# So changing undef to 0 or visa versa, etc, will all be ignored.

		(! $$data{$key} && ! $arg{$key}) && next;

		if ( (! $$data{$key} && $arg{$key}) || ($$data{$key} && ! $arg{$key}) || ($$data{$key} ne $arg{$key}) )
		{
			$$data{$key} = $arg{$key};

			$self -> modified(1);
		}
	}

	$self -> session($data);

	return 1;

} # End of param.

# -----------------------------------------------
# Format expected: new(type => 'driver:File;id:MD5;serialize:DataDumper').

sub parse_options
{
	my($self)    = @_;
	my($options) = $self -> type || '';

	($self -> verbose > 1) && $self -> log("Parsing type '$options'");

	$options     =~ tr/ //d;
	my(%options) = map{split(/:/, $_)} split(/;/, lc $options); # lc!
	my(%default) =
	(
		driver    => 'File',
		id        => 'MD5',
		serialize => 'DataDumper',
	);

	for my $key (keys %options)
	{
		(! $default{$key}) && die __PACKAGE__ . ". Error in type: Unexpected component '$key'";
	}

	my(%driver)       = map{(lc $_ => $_)} @{$self -> my_drivers};
	my(%id_generator) = map{(lc $_ => $_)} @{$self -> my_id_generators};
	my(%serializer)   = map{(lc $_ => $_)} @{$self -> my_serializers};

	# The sort is just to make the warnings ($required) appear in alphabetical order.

	for my $required (sort keys %default)
	{
		# Set default if user does not supply the key:value pair.

		if (! exists $options{$required})
		{
			$options{$required} = $default{$required};

			($self -> verbose) && $self -> log("Warning for type: Defaulting '$required' to '$default{$required}'");
		}

		# Ensure the value is set.

		(! $options{$required}) && die __PACKAGE__ . ". Error in type: Missing value for option '$required'";

		# Ensure the case of the value is correct.

		if ($required eq 'driver')
		{
			if ($driver{lc $options{$required} })
			{
				$options{$required} = $driver{lc $options{$required} };
			}
			else
			{
				die __PACKAGE__ . ". Unknown driver '$options{$required}'";
			}
		}
		elsif ($required eq 'id')
		{
			if ($id_generator{lc $options{$required} })
			{
				$options{$required} = $id_generator{lc $options{$required} };
			}
			else
			{
				die __PACKAGE__ . ". Unknown id generator '$options{$required}'";
			}
		}
		elsif ($required eq 'serialize')
		{
			if ($serializer{lc $options{$required} })
			{
				$options{$required} = $serializer{lc $options{$required} };
			}
			else
			{
				die __PACKAGE__ . ". Unknown serialize '$options{$required}'";
			}
		}
	}

	$self -> driver_option($options{driver});
	$self -> id_option($options{id});
	$self -> serializer_option($options{serialize});
	$self -> type(join(';', map{"$_:$options{$_}"} sort keys %default));

	if ($self -> verbose > 1)
	{
		$self -> log('type:              ' . $self -> type);
		$self -> log('driver_option:     ' . $self -> driver_option);
		$self -> log('id_option:         ' . $self -> id_option);
		$self -> log('serializer_option: ' . $self -> serializer_option);
	}

} # End of parse_options.

# -----------------------------------------------
# Warning: Returns a hashref.

sub ptime
{
	my($self) = @_;
	my($data) = $self -> session;

	return $$data{_SESSION_PTIME};

} # End of ptime.

# -----------------------------------------------

sub save_param
{
	my($self, $q, $name) = @_;

	if (! defined $q)
	{
		$q = $self -> load_query_class;
	}

	my($data) = $self -> session;

	if (! $name)
	{
		$name = [$q -> param];
	}
	elsif (ref($name) ne 'ARRAY')
	{
		$name = [grep{! /^_/} $name];
	}
	else
	{
		$name = [grep{! /^_/} @$name];
	}

	for my $key (@$name)
	{
		$$data{$key} = $q -> param($key);

		$self -> modified(1);
	}

	$self -> session($data);

	return 1;

} # End of save_param.

# -----------------------------------------------

sub traverse
{
	my($self, $sub) = @_;

	return $self -> driver_class -> traverse($sub);

} # End of traverse.

# -----------------------------------------------

sub user_id
{
	my($self) = @_;

	# Sources of id:
	# o User supplied one in $session -> new(id => $id).
	# o User didn't, so we try $self -> query -> cookie and/or $self -> query -> param.

	my($id) = $self -> id;

	if (! $id)
	{
		$self -> load_query_class;

		my($name) = $self -> name;
		my($q)    = $self -> query;

		if ($q -> can('cookie') )
		{
			$id = $q -> cookie($name) || $q -> param($name);

			($self -> verbose > 1) && $self -> log('query can cookie(). id from cookie or param: ' . ($id || '') );
		}
		else
		{
			$id = $q -> param($name);

			($self -> verbose > 1) && $self -> log("query can't cookie(). id from param: " . ($id || '') );
		}

		if (! $id)
		{
			$id = 0;
		}
	}

	return $id;

} # End of user_id.

# -----------------------------------------------

sub validate_options
{
	my($self) = @_;

	if ( ($self -> id_option eq 'Static') && ! $self -> id)
	{
		die __PACKAGE__ . '. When using id:Static, you must provide a (true) id to new(id => ...)';
	}

} # End of validate_options.

# -----------------------------------------------

sub validate_time
{
	my($self, $time) = @_;

	(! $time) && return 0;

	$time = "${time}s" if ($time =~ /\d$/);

	($time !~ /^([-+]?\d+)([smhdwMy])$/) && die __PACKAGE__ . ". Can't parse time: $time";

	my(%scale) =
	(
		s =>        1,
		m =>       60,
		h =>     3600,
		d =>    86400,
		w =>   604800,
		M =>  2592000,
		y => 31536000,
	);

	return $scale{$2} * $1;

} # End of validate_time.

# -----------------------------------------------

1;

=pod

=head1 NAME

Data::Session - Persistent session data management

=head1 Synopsis

1: A self-contained CGI script (scripts/cgi.demo.cgi):

	#!/usr/bin/perl

	use CGI;

	use Data::Session;

	use File::Spec;

	# ----------------------------------------------

	sub generate_html
	{
		my($name, $id, $count) = @_;
		$id        ||= '';
		my($title) = "CGI demo for Data::Session";
		return     <<EOS;
	<html>
	<head><title>$title</title></head>
	<body>
		Number of times this script has been run: $count.<br/>
		Current value of $name: $id.<br/>
		<form id='sample' method='post' name='sample'>
		<button id='submit'>Click to submit</button>
		<input type='hidden' name='$name' id='$name' value='$id' />
		</form>
	</body>
	</html>
	EOS

	} # End of generate_html.

	# ----------------------------------------------

	my($q)        = CGI -> new;
	my($name)     = 'sid'; # CGI form field name.
	my($sid)      = $q -> param($name);
	my($dir_name) = '/tmp';
	my($type)     = 'driver:File;id:MD5;serialize:JSON';
	my($session)  = Data::Session -> new
	(
		directory => $dir_name,
		name      => $name,
		query     => $q,
		type      => $type,
	);
	my($id) = $session -> id;

	# First entry ever?

	my($count);

	if ($sid) # Not $id, which always has a value...
	{
		# No. The CGI form field called sid has a (true) value.
		# So, this is the code for the second and subsequent entries.
		# Count the # of times this CGI script has been run.

		$count = $session -> param('count') + 1;
	}
	else
	{
		# Yes. There is no CGI form field called sid (with a true value).
		# So, this is the code for the first entry ever.
		# Count the # of times this CGI script has been run.

		$count = 0;
	}

	$session -> param(count => $count);

	print $q -> header, generate_html($name, $id, $count);

	# Calling flush() is good practice, rather than hoping 'things just work'.
	# In a persistent environment, this call is mandatory...
	# But you knew that, because you'd read the docs, right?

	$session -> flush;

2: A basic session. See scripts/sqlite.pl:

	# The EXLOCK is for BSD-based systems.
	my($directory)   = File::Temp::newdir('temp.XXXX', CLEANUP => 1, EXLOCK => 0, TMPDIR => 1);
	my($data_source) = 'dbi:SQLite:dbname=' . File::Spec -> catdir($directory, 'sessions.sqlite');
	my($type)        = 'driver:SQLite;id:SHA1;serialize:DataDumper'; # Case-sensitive.
	my($session)     = Data::Session -> new
	(
		data_source => $data_source,
		type        => $type,
	) || die $Data::Session::errstr;

3: Using BerkeleyDB as a cache manager. See scripts/berkeleydb.pl:

	# The EXLOCK is for BSD-based systems.
	my($file_name) = File::Temp -> new(EXLOCK => 0, SUFFIX => '.bdb');
	my($env)       = BerkeleyDB::Env -> new
	(
		Home => File::Spec -> tmpdir,
		Flags => DB_CREATE | DB_INIT_CDB | DB_INIT_MPOOL,
	);
	if (! $env)
	{
		print "BerkeleyDB is not responding. \n";
		exit;
	}
	my($bdb) = BerkeleyDB::Hash -> new(Env => $env, Filename => $file_name, Flags => DB_CREATE);
	if (! $bdb)
	{
		print "BerkeleyDB is not responding. \n";
		exit;
	}
	my($type)    = 'driver:BerkeleyDB;id:SHA1;serialize:DataDumper'; # Case-sensitive.
	my($session) = Data::Session -> new
	(
		cache => $bdb,
		type  => $type,
	) || die $Data::Session::errstr;

4: Using memcached as a cache manager. See scripts/memcached.pl:

	my($memd) = Cache::Memcached -> new
	({
		namespace => 'data.session.id',
		servers   => ['127.0.0.1:11211'],
	});
	my($test) = $memd -> set(time => time);
	if (! $test || ($test != 1) )
	{
		print "memcached is not responding. \n";
		exit;
	}
	$memd -> delete('time');
	my($type)    = 'driver:Memcached;id:SHA1;serialize:DataDumper'; # Case-sensitive.
	my($session) = Data::Session -> new
	(
		cache => $memd,
		type  => $type,
	) || die $Data::Session::errstr;

5: Using a file to hold the ids. See scripts/file.autoincrement.pl:

	# The EXLOCK is for BSD-based systems.
	my($directory) = File::Temp::newdir('temp.XXXX', CLEANUP => 1, EXLOCK => 0, TMPDIR => 1);
	my($file_name) = 'autoinc.session.dat';
	my($id_file)   = File::Spec -> catfile($directory, $file_name);
	my($type)      = 'driver:File;id:AutoIncrement;serialize:DataDumper'; # Case-sensitive.
	my($session)   = Data::Session -> new
	(
		id_base     => 99,
		id_file     => $id_file,
		id_step     => 2,
		type        => $type,
	) || die $Data::Session::errstr;

6: Using a file to hold the ids. See scripts/file.sha1.pl (non-CGI context):

	my($directory) = '/tmp';
	my($file_name) = 'session.%s.dat';
	my($type)      = 'driver:File;id:SHA1;serialize:DataDumper'; # Case-sensitive.

	# Create the session:
	my($session)   = Data::Session -> new
	(
		directory => $directory,
		file_name => $file_name,
		type      => $type,
	) || die $Data::Session::errstr;

	# Time passes...

	# Retrieve the session:
	my($id)      = $session -> id;
	my($session) = Data::Session -> new
	(
		directory => $directory,
		file_name => $file_name,
		id        => $id, # <== Look! You must supply the id for retrieval.
		type      => $type,
	) || die $Data::Session::errstr;

7: As a variation on the above, see scripts/cgi.sha1.pl (CGI context but command line program):

	# As above (scripts/file.sha1.pl), for creating the session. Then...

	# Retrieve the session:
	my($q)       = CGI -> new; # CGI form data provides the id.
	my($session) = Data::Session -> new
	(
		directory => $directory,
		file_name => $file_name,
		query     => $q, # <== Look! You must supply the id for retrieval.
		type      => $type,
	) || die $Data::Session::errstr;

Also, much can be gleaned from t/basic.t and t/Test.pm. See L</Test Code>.

=head1 Description

L<Data::Session> is typically used by a CGI script to preserve state data between runs of the
script. This gives the end user the illusion that the script never exits.

It can also be used to communicate between 2 scripts, as long as they agree beforehand what session
id to use.

See L<Data::Session::CGISession> for an extended discussion of the design changes between
L<Data::Session> and L<CGI::Session>.

L<Data::Session> stores user data internally in a hashref, and the module reserves key names
starting with '_'.

The current list of reserved keys is documented under L</flush()>.

Of course, the module also has a whole set of methods to help manage state.

=head1 Methods

=head2 new()

Calling new() returns a object of type L<Data::Session>, or - if new() fails - it returns undef.
For details see L</Trouble with Errors>.

new() takes a hash of key/value pairs, some of which might mandatory. Further, some combinations
might be mandatory.

The keys are listed here in alphabetical order.

They are lower-case because they are (also) method names, meaning they can be called to set or get
the value at any time.

But a warning: In some cases, setting them after this module has used the previous value, will have
no effect. All such cases should be documented.

Beginners understandably confused by the quantity of options should consult the L</Synopsis> for
example code.

The questions of combinations of options, and which option has priority over other options,
are addressed in the section, L</Combinations of Options>.

=over 4

=item o cache => $cache

Specifies an object of type L<BerkeleyDB> or L<Cache::Memcached> to use for storage.

Only needed if you use 'type' like 'driver:BerkeleyDB ...' or 'driver:Memcached ...'.

See L<Data::Session::Driver::BerkeleyDB> and L<Data::Session::Driver::Memcached>.

Default: '' (the empty string).

=item o data_col_name => $string

Specifies the name of the column holding the session data, in the session table.

This key is optional.

Default: 'a_session'.

=item o data_source => $string

Specifies a value to use as the 1st parameter in the call to L<DBI>'s connect() method.

A typical value would be 'dbi:Pg:dbname=project'.

This key is optional. It is only used if you do not supply a value for the 'dbh' key.

Default: '' (the empty string).

=item o data_source_attrs => $hashref

Specify a hashref of options to use as the last parameter in the call to L<DBI>'s connect() method.

This key is optional. It is only used if you do not supply a value for the 'dbh' key.

Default: {AutoCommit => 1, PrintError => 0, RaiseError => 1}.

=item o dbh => $dbh

Specifies a database handle to use to access the session table.

This key is optional.

However, if not specified, you must specify a value for 'data_source', and perhaps also 'username'
and 'password', so that this module can create a database handle.

If this module does create a database handle, it will also destroy it, whereas if you supply a database
handle, you are responsible for destroying it.

=item o debug => $Boolean

Specifies that debugging should be turned on (1) or off (0) in L<Data::Session::File::Driver> and
L<Data::Session::ID::AutoIncrement>.

When debug is 1, $! is included in error messages, but because this reveals directory names, it is
0 by default.

This key is optional.

Default: 0.

=item o directory => $string

Specifies the directory in which session files are stored, when each session is stored in a separate
file (by using 'driver:File ...' as the first component of the 'type').

This key is optional.

Default: Your temp directory as determined by L<File::Spec>.

See L</Specifying Session Options> for details.

=item o file_name => $string_containing_%s

Specifies the syntax for the names of session files, when each session is stored in a separate file
(by using 'driver:File ...' as the first component of the 'type').

This key is optional.

Default: 'cgisess_%s', where the %s is replaced at run-time by the session id.

The directory in which these files are stored is specified by the 'directory' option above.

See L</Specifying Session Options> for details.

=item o host => $string

Specifies a host, typically for use with a data_source referring to MySQL.

This key is optional.

Default: '' (the empty string).

=item o id => $string

Specifies an id to retrieve from storage.

This key is optional.

Default: 0.

Note: If you do not provide an id here, the module calls L</user_id()> to determine whether or not
an id is available from a cookie or a form field.

This complex topic is discussed in the section L<Specifying an Id>.

=item o id_col_name => $string

Specifies the name of the column holding the session id, in the session table.

This key is optional.

Default: 'id'.

=item o id_base => $integer

Specifies the base from which to start ids when using the '... id:AutoIncrement ...' component in
the 'type'.

Note: The first id returned by L<Data::Session::ID::AutoIncrement> will be id_base + id_step.
So, if id_base is 1000 and id_step is 10, then the lowest id will be 1010.

This key is optional.

Default: 0.

=item o id_file => $file_path_and_name

Specifies the file path and name in which to store the last used id, as calculated from C<id_base +
id_step>, when using the '... id:AutoIncrement ...' component in the 'type'.

This value must contain a path because the 'directory' option above is only used for session files
(when using L<Data::Session::Driver::File>).

This key is optional.

Default: File::Spec -> catdir(File::Spec -> tmpdir, 'data.session.id').

=item o id_step => $integer

Specifies the step size between ids when using the '... id:AutoIncrement ...' component of the
'type'.

This key is optional.

Default: 1.

=item o name => $string

Specifies the name of the cookie or form field which holds the session id.

This key is optional.

Default: 'CGISESSID'.

Usage of 'name' is discussed in the sections L</Specifying an Id> and L</user_id()>.

=item o no_flock => $boolean

Specifies (no_flock => 1) to not use flock() to obtain a lock on a session file before processing
it, or (no_flock => 0) to use flock().

This key is optional.

Default: 0.

This value is used in these cases:

=over 4

=item o type => 'driver:File ...'

=item o type => '... id:AutoIncrement ...'

=back

=item o no_follow => $boolean

Influences the mode to use when calling sysopen() on session files.

'Influences' means the value is bit-wise ored with O_RDWR for reading and with O_WRONLY for writing.

This key is optional.

Default: eval { O_NOFOLLOW } || 0.

This value is used in this case:

=over 4

=item o type => 'driver:File ...'

=back

=item o password => $string

Specifies a value to use as the 3rd parameter in the call to L<DBI>'s connect() method.

This key is optional. It is only used if you do not supply a value for the 'dbh' key.

Default: '' (the empty string).

=item o pg_bytea => $boolean

Specifies that you're using a Postgres-specific column type of 'bytea' to hold the session data,
in the session table.

This key is optional, but see the section, L</Combinations of Options> for how it interacts with
the pg_text key.

Default: 0.

Warning: Columns of type bytea can hold null characters (\x00), whereas columns of type text cannot.

=item o pg_text => $boolean

Specifies that you're using a Postgres-specific column type of 'text' to hold the session data, in
the session table.

This key is optional, but see the section, L</Combinations of Options> for how it interacts with the
pg_bytea key.

Default: 0.

Warning: Columns of type bytea can hold null characters (\x00), whereas columns of type text cannot.

=item o port => $string

Specifies a port, typically for use with a data_source referring to MySQL.

This key is optional.

Default: '' (the empty string).

=item o query => $q

Specifies the query object.

If not specified, the next option - 'query_class' - will be used to create a query object.

Either way, the object will be accessible via the $session -> query() method.

This key is optional.

Default: '' (the empty string).

=item o query_class => $class_name

Specifies the class of query object to create if a value is not provided for the 'query' option.

This key is optional.

Default: 'CGI'.

=item o socket => $string

Specifies a socket, typically for use with a data_source referring to MySQL.

The reason this key is called socket and not mysql_socket is in case other drivers permit a socket
option.

This key is optional.

Default: '' (the empty string).

=item o table_name => $string

Specifies the name of the table holding the session data.

This key is optional.

Default: 'sessions'.

=item o type => $string

Specifies the type of L<Data::Session> object you wish to create.

This key is optional.

Default: 'driver:File;id:MD5;serialize:DataDumper'.

This complex topic is discussed in the section L</Specifying Session Options>.

=item o umask => $octal_number

Specifies the mode to use when calling sysopen() on session files.

This value is used in these cases:

=over 4

=item o type => 'driver:File ...'

=item o type => '... id:AutoIncrement ...'

=back

Default: 0660 (octal).

=item o username => $string

Specifies a value to use as the 2nd parameter in the call to L<DBI>'s connect() method.

This key is optional. It is only used if you do not supply a value for the 'dbh' key.

Default: '' (the empty string).

=item o verbose => $integer

Print to STDERR more or less information.

Typical values are 0, 1 and 2.

This key is optional.

Default: 0, meaings nothing is printed.

See L</dump([$heading])> for what happens when verbose is 2.

=back

=head3 Specifying Session Options

See also L</Case-sensitive Options>.

The default 'type' string is 'driver:File;id:MD5;serialize:DataDumper'. It consists of 3 optional
components separated by semi-colons.

Each of those 3 components consists of 2 fields (a key and a value) separated by a colon.

The keys:

=over 4

=item o driver

This specifies what type of persistent storage you wish to use for session data.

Values for 'driver':

=over 4

=item o BerkeleyDB

Use L<BerkeleyDB> for storage. In this case, you must pass an object of type L<BerkeleyDB>
to new() as the value of the 'cache' option.

See L<Data::Session::Driver::BerkeleyDB>.

=item o File

The default, 'File', says sessions are each stored in a separate file.

The directory for these files is specified with the 'directory' option to new().

If a directory is not specified in that way, L<File::Spec> is used to find your temp directory.

The names of the session files are generated from the 'file_name' option to new().

The default file name (pattern) is 'cgisess_%s', where the %s is replaced by the session id.

See L<Data::Session::Driver::File>.

=item o Memcached

Use C<memcached> for storage. In this case, you must pass an object of type L<Cache::Memcached> to
new() as the value of the 'cache' option.

See L<Data::Session::Driver::Memcached>.

=item o mysql

This says each session is stored in a separate row of a database table using the L<DBD::mysql>
database server.

These rows have a unique primary id equal to the session id.

See L<Data::Session::Driver::mysql>.

=item o ODBC

This says each session is stored in a separate row of a database table using the L<DBD::ODBC>
database connector.

These rows have a unique primary id equal to the session id.

See L<Data::Session::Driver::ODBC>.

=item o Oracle

This says each session is stored in a separate row of a database table using the L<DBD::Oracle>
database server.

These rows have a unique primary id equal to the session id.

See L<Data::Session::Driver::Oracle>.

=item o Pg

This says each session is stored in a separate row of a database table using the L<DBD::Pg> database
server.

These rows have a unique primary id equal to the session id.

See L<Data::Session::Driver::Pg>.

=item o SQLite

This says each session is stored in a separate row of a database table using the SQLite database
server.

These rows have a unique primary id equal to the session id.

The advantage of SQLite is that a client I<and server> are shipped with all recent versions of Perl.

See L<Data::Session::Driver::SQLite>.

=back

=item o id

This specifies what type of id generator you wish to use.

Values for 'id':

=over 4

=item o AutoIncrement

This says ids are generated starting from a value specified with the 'id_base' option to new(),
and the last-used id is stored in the file name given by the 'id_file' option to new().

This file name must include a path, since the 'directory' option to new() is I<not> used here.

When a new id is required, the value in the file is incremented by the value of the 'id_step' option
to new(), with the new value both written back to the file and returned as the new session id.

The default value of id_base is 0, and the default value of id_step is 1. Together, the first id
available as a session id is id_base + id_step = 1.

The sequence starts when the module cannot find the given file, or when its contents are not
numeric.

See L<Data::Session::ID::AutoIncrement>.

=item o MD5

The default, 'MD5', says ids are to be generated by L<Digest::MD5>.

See L<Data::Session::ID::MD5>.

=item o SHA1

This says ids are to be generated by L<Digest::SHA>, using a digest algorithm of 1.

See L<Data::Session::ID::SHA1>.

=item o SHA256

This says ids are to be generated by L<Digest::SHA>, using a digest algorithm of 256.

See L<Data::Session::ID::SHA256>.

=item o SHA512

This says ids are to be generated by L<Digest::SHA>, using a digest algorithm of 512.

See L<Data::Session::ID::SHA512>.

=item o Static

This says that the id passed in to new(), as the value of the 'id' option, will be used as the
session id for every session.

Of course, this id must have a true value. L<Data::Session> dies on all values Perl regards as
false.

See L<Data::Session::ID::Static>.

=item o UUID16

This says ids are to be generated by L<Data::UUID>, to generate a 16 byte long binary UUID.

See L<Data::Session::ID::UUID16>.

=item o UUID34

This says ids are to be generated by L<Data::UUID>, to generate a 34 byte long string UUID.

See L<Data::Session::ID::UUID34>.

=item o UUID36

This says ids are to be generated by L<Data::UUID>, to generate a 36 byte long string UUID.

See L<Data::Session::ID::UUID36>.

=item o UUID64

This says ids are to be generated by L<Data::UUID>, to generate a 24 (sic) byte long, base-64
encoded, UUID.

See L<Data::Session::ID::UUID64>.

=back

See scripts/digest.pl which prints the length of each type of digest.

=item o serialize

The specifies what type of mechanism you wish to use to convert the in-memory session data into a
form appropriate for your chosen storage type.

Values for 'serialize':

=over 4

=item o DataDumper

Use L<Data::Dumper> to freeze/thaw sessions.

See L<Data::Session::Serialize::DataDumper>.

=item o FreezeThaw

Use L<FreezeThaw> to freeze/thaw sessions.

See L<Data::Session::Serialize::FreezeThaw>.

=item o JSON

Use L<JSON> to freeze/thaw sessions.

See L<Data::Session::Serialize::JSON>.

=item o Storable

Use L<Storable> to freeze/thaw sessions.

See L<Data::Session::Serialize::Storable>.

Warning: Storable should be avoided until this problem is fixed:
L<http://rt.cpan.org/Public/Bug/Display.html?id=36087>.

=item o YAML

Use L<YAML::Tiny> to freeze/thaw sessions.

See L<Data::Session::Serialize::YAML>.

=back

=back

=head3 Case-sensitive Options

Just to emphasize: The names of drivers, etc follow the DBD::* (or similar) style of
case-sensitivity.

The following classes for drivers, id generators and serializers, are shipped with this package.

Drivers:

=over 4

=item o L<Data::Session::Driver::BerkeleyDB>

This name comes from L<BerkeleyDB>.

And yes, the module uses L<BerkeleyDB> and not L<DB_File>.

=item o L<Data::Session::Driver::File>

=item o L<Data::Session::Driver::Memcached>

This name comes from L<Cache::Memcached> even though the external program you run is called
memcached.

=item o L<Data::Session::Driver::mysql>

=item o L<Data::Session::Driver::ODBC>

=item o L<Data::Session::Driver::Oracle>

=item o L<Data::Session::Driver::Pg>

=item o L<Data::Session::Driver::SQLite>

=back

ID generators:

=over 4

=item o L<Data::Session::ID::AutoIncrement>

=item o L<Data::Session::ID::MD5>

=item o L<Data::Session::ID::SHA1>

=item o L<Data::Session::ID::SHA256>

=item o L<Data::Session::ID::SHA512>

=item o L<Data::Session::ID::Static>

=item o L<Data::Session::ID::UUID16>

=item o L<Data::Session::ID::UUID34>

=item o L<Data::Session::ID::UUID36>

=item o L<Data::Session::ID::UUID64>

=back

Serializers:

=over 4

=item o L<Data::Session::Serialize::DataDumper>

=item o L<Data::Session::Serialize::FreezeThaw>

=item o L<Data::Session::Serialize::JSON>

=item o L<Data::Session::Serialize::Storable>

Warning: Storable should be avoided until this problem is fixed:
L<http://rt.cpan.org/Public/Bug/Display.html?id=36087>

=item o L<Data::Session::Serialize::YAML>

=back

=head3 Specifying an Id

L</user_id()> is called to determine if an id is available from a cookie or a form field.

There are several cases to consider:

=over 4

=item o You specify an id which exists in storage

You can check this with the call $session -> is_new, which will return 0.

$session -> id will return the old id.

=item o You do not specify an id

The module generates a new session and a new id.

You can check this with the call $session -> is_new, which will return 1.

$session -> id will return the new id.

=item o You specify an id which does not exist in storage

You can check this with the call $session -> is_new, which will return 1.

$session -> id will return the old id.

=back

So, how to tell the difference between the last 2 cases? Like this:

	if ($session -> id == $session -> user_id)
	{
		# New session using user-supplied id.
	}
	else
	{
		# New session with new id.
	}

=head3 Combinations of Options

See also L</Specifying Session Options>, for options-related combinations.

=over 4

=item o dbh

If you don't specify a value for the 'dbh' key, this module must create a database handle in those
cases when you specify a database driver of some sort in the value for 'type'.

To create that handle, we needs a value for 'data_source', and that in turn may require values for
'username' and 'password'.

When using SQLite, just specify a value for 'data_source'. The default values for 'username' and
'password' - empty strings - will work.

=item o file_name and id_file

When using new(type => 'driver:File;id:AutoIncrement;...'), then file_name is ignored and id_file is
used.

If id_file is not supplied, it defaults to File::Spec -> catdir(File::Spec -> tmpdir,
'data.session.id').

When using new(type => 'driver:File;id:<Not AutoIncrement>;...'), then id_file is ignored and
file_name is used.

If file_name is not supplied, it defaults to 'cgisess_%s'. Note the mandatory %s.

=item o pg_bytea and pg_text

If you set 'pg_bytea' to 1, then 'pg_text' will be set to 0.

If you set 'pg_text' to 1, then 'pg_bytea' will be set to 0.

If you set them both to 0 (i.e. the default), then 'pg_bytea' will be set to 1.

If you set them both to 1, 'pg_bytea' will be left as 1 and 'pg_text' will be set to 0.

This choice was made because you really should be using a column type of 'bytea' for a_session
in the sessions table, since the type 'text' does not handle null (\x00) characters.

=back

=head2 atime([$atime])

The [] indicates an optional parameter.

Returns the last access time of the session.

By default, the value comes from calling Perl's time() function, or you may pass in a time,
which is then used to set the last access time of the session.

This latter alternative is used by L</load_session()>.

See also L</ctime()>, L</etime()> and L</ptime()>.

=head2 check_expiry()

Checks that there is an expiry time set for the session, and, if (atime + etime) < time():

=over 4

=item o Deletes the session

See L</delete()> for precisely what this means.

=item o Sets the expired flag

See L</expired()>.

=back

This is used when the session is loaded, when you call L</http_header([@arg])>, and by
scripts/expire.pl.

=head2 clear([$name])

The [] indicates an optional parameter.

Returns 1.

Specifies that you wish to delete parameters stored in the session, i.e. stored by previous calls to
param().

$name is a parameter name or an arrayref of parameter names.

If $name is not specified, it is set to the list of all unreserved keys (parameter names) in the
session.

See L</param([@arg])> for details.

=head2 cookie([@arg])

The [] indicates an optional parameter.

Returns a cookie, or '' (the empty string) if the query object does not have a cookie() method.

Use the @arg parameter to pass any extra parameters to the query object's cookie() method.

Warning: Parameters which are handled by L<Data::Session>, and hence should I<not> be passed in,
are:

=over 4

=item o -expires

=item o -name

=item o -value

=back

See L</http_header([@arg])> and scripts/cookie.pl.

=head2 ctime()

Returns the creation time of the session.

The value comes from calling Perl's time() function when the session was created.

This is not the creation time of the session I<object>, except for new sessions.

See also L</atime()>, L</etime()> and L</ptime()>.

=head2 delete()

Returns the result of calling the driver's remove() method.

Specifies that you want to delete the session. Here's what it does:

=over 4

=item o Immediately deletes the session from storage

=item o Calls clear()

This deletes all non-reserved parameters from the session object, and marks it as modified.

=item o Marks the session object as deleted

=back

The latter step means that when (or if) the session object goes out of scope, it will not be flushed
to storage.

Likewise, if you call flush(), the call will be ignored.

Nevertheless, the session object is still fully functional - it just can't be saved or retrieved.

See also L</deleted()> and L</expire([@arg])>.

=head2 deleted()

Returns a Boolean (0/1) indicating whether or not the session has been deleted.

See also L</delete()> and L</expire([@arg])>.

=head2 dump([$heading])

The [] indicates an optional parameter.

Dumps the session's contents to STDERR, with a prefix of '# '.

The $heading, if any, is written first, on a line by itself, with the same prefix.

This is especially useful for testing, since it fits in with the L<Test::More> method diag().

When verbose is 2, dump is called at these times:

=over 4

=item o When a session is flushed

=item o As soon as a session is loaded

=item o As soon as expiry is checked on a just-loaded session

=item o As soon as parameter expiry is checked on a just-loaded session

=back

=head2 etime()

Returns the expiry time of the session.

This is the same as calling $session -> expiry(). In fact, this just calls $session -> etime.

See also L</atime()>, L</ctime()> and L</ptime()>.

=head2 expire([@arg])

The [] indicates an optional parameter.

Specifies that you wish to set or retrieve the session's expiry time, or set the expiry times of
session parameters.

Integer time values ($time below) are assumed to be seconds. The value may be positive or 0 or
negative.

These expiry times are relative to the session's last access time, not the session's creation time.

In all cases, a time of 0 disables expiry.

This affects users of L<Cache::Memcached>. See below and L<Data::Session::Driver::Memcached>.

When a session expires, it is deleted from storage. See L</delete()> for details.

The test for whether or not a session has expired only takes place when a session is loaded from
storage.

When a session parameter expires, it is deleted from the session object. See L</clear([$name])>
for details.

The test for whether or not a session parameter has expired only takes place when a session is
loaded from storage.

=over 4

=item o $session -> expire()

Use $session -> expire() to return the session's expiry time. This just calls $session -> etime.

The default expiry time is 0, meaning the session will never expire. Likewise, by default, session
parameters never expire.

=item o $session -> expire($time)

Use $session -> expire($time) to set the session's expiry time.

Use these suffixes to change the interpretation of the integer you specify:

	+-----------+---------------+
	|   Suffix  |   Meaning     |
	+-----------+---------------+
	|     s     |   Second      |
	|     m     |   Minute      |
	|     h     |   Hour        |
	|     d     |   Day         |
	|     w     |   Week        |
	|     M     |   Month       |
	|     y     |   Year        |
	+-----------+---------------+

Hence $session -> expire('2h') means expire the session in 2 hours.

expire($time) calls validate_time($time) to perform the conversion from '2h' to seconds,
so L</validate_time($time)> is available to you too.

If setting a time like this, expire($time) returns 1.

Note: The time set here is passed as the 3rd parameter to the storage driver's store() method (for
all types of storage), and from there as the 3rd parameter to the set() method of
L<Cache::Memcached>. Of course, this doesn't happen immediately - it only happens when the session
is saved.

=item o $session -> expire($key_1 => $time_1[, $key_2 => $time_2...])

Use $session -> expire($key_1 => $time_1[, $key_2 => $time_2...]) to set the expiry times of
session parameters.

=back

Special cases:

=over 4

=item o To expire the session immediately, call delete()

=item o To expire a session parameter immediately, call clear($key)

=back

See also L</atime()>, L</ctime()>, L</etime()>, L</delete()> and
L</deleted()>.

=head2 expired()

Returns a Boolean (0/1) indicating whether or not the session has expired.

See L</delete()>.

=head2 flush()

Returns 1.

Specifies that you want the session object immediately written to storage.

If you have previously called delete(), the call to flush() is ignored.

If the object has not been modified, the call to flush() is ignored.

Warning: With persistent environments, you object may never go out of scope that way you think it
does.See L</Trouble with Exiting> for details.

These reserved session parameters are included in what's written to storage:

=over 4

=item o _SESSION_ATIME

The session's last access time.

=item o _SESSION_CTIME

The session's creation time.

=item o _SESSION_ETIME

The session's expiry time.

A time of 0 means there is no expiry time.

This affect users of L<Cache::Memcached>. See L</expire([@arg])> and
L<Data::Session::Driver::Memcached>.

=item o _SESSION_ID

The session's id.

=item o _SESSION_PTIME

A hashref of session parameter expiry times.

=back

=head2 http_header([@arg])

The [] indicate an optional parameter.

Returns a HTTP header. This means it does I<not> print the header. You have to do that, when
appropriate.

Unlike L<CGI::Session>, L<Data::Session> does I<not> force the document type to be 'text/html'.

You must pass in a document type to http_header(), as
C<< $session -> http_header('-type' => 'text/html') >>, or use the query object's default.

Both L<CGI> and L<CGI::Simple> default to 'text/html'.

L<Data::Session> handles the case where the query object does not have a cookie() method, by calling
$session -> cookie() to generate either a cookie, or '' (the empty string).

The @arg parameter, if any, is passed to the query object's header() method, after the cookie
parameter, if any.

=head2 id()

Returns the id of the session.

=head2 is_new()

Returns a Boolean (0/1).

Specifies you want to know if the session object was created from scratch (1) or was retrieved
from storage (0).

=head2 load_param([$q][, $name])

The [] indicate optional parameters.

Returns $q.

Loads (copies) all non-reserved parameters from the session object into the query object.

L</save_param([$q][, $name])> performs the opposite operation.

$q is a query object, and $name is a parameter name or an arrayref of names.

If the query object is not specified, generates one by calling $session -> load_query_class,
and stores it in the internal 'query' attribute.

If you don't provide $q, use undef, don't just omit the parameter.

If $name is specified, only the session parameters named in the arrayref are processed.

If $name is not specified, copies all parameters belonging to the query object.

=head2 load_query_class()

Returns the query object.

This calls $session -> query_class -> new if the session object's query object is not defined.

=head2 load_session()

Returns a session.

Note: This method does not take any parameters, and hence does not function in the same way as
load(...) in L<CGI::Session>.

Algorithm:

=over 4

=item o If user_id() returns a session id, try to load that session

If that succeeds, return the session.

If it fails, generate a new session, and return it.

You can call is_new() to tell the difference between these 2 cases.

=item o If user_id() returns 0, generate a new session, and return it

=back

=head2 modified()

Returns a Boolean (0/1) indicating whether or not the session's parameters have been modified.

However, changing a value from one form of not-defined, e.g. undef, to another form of not-defined,
e.g. 0, is ignored, meaning the modified flag is not set. In such cases, you could set the flag
yourself.

Note: Loading a session from storage changes the session's last access time, which means the session
has been modified.

If you wish to stop the session being written to storage, without deleting it, you can reset the
modified flag with $session -> modified(0).

=head2 param([@arg])

The [] indicates an optional parameter.

Specifies that you wish to retrieve data stored in the session, or you wish to store data in the
session.

Data is stored in the session object as in a hash, via a set of $key => $value relationships.

Use $session -> param($key_1 => $value_1[, $key_2 => $value_2...]) to store data in the session.

If storing data, param() returns 1.

The values stored in the session may be undef.

Note: If the value being stored is the same as the pre-existing value, the value in the session is
not updated, which means the last access time does not change.

Use $session -> param() to return a sorted list of all keys.

That call returns a list of the keys you have previously stored in the session.

Use $session -> param('key') to return the value associated with the given key.

See also L</clear([$name])>.

=head2 ptime()

Returns the hashref of session parameter expiry times.

Keys are parameter names and values are expiry times in seconds.

These expiry times are set by calling L</expire([@arg])>.

See also L</atime()>, L</ctime()> and L</etime()>.

=head2 save_param([$q][, $name])

The [] indicate optional parameters.

Returns 1.

Loads (copies) all non-reserved parameters from the query object into the session object.

L</load_param([$q][, $name])> performs the opposite operation.

$q is a query object, and $name is a parameter name or an arrayref of names.

If the query object is not specified, generates one by calling $session -> load_query_class,
and stores it in the internal 'query' attribute. This means you can retrieve it with
$session -> query.

If you don't provide $q, use undef, don't just omit the parameter.

If $name is specified, only the session parameters named in the arrayref are processed.

If $name is not specified, copies all parameters.

=head2 traverse($sub)

Returns 1.

Specifies that you want the $sub called for each session id found in storage, with one (1) id as
the only parameter in each call.

Note: traverse($sub) does not load the sessions, and hence has no effect on the session's last
access time.

See scripts/expire.pl.

=head2 user_id()

Returns either a session id, or 0.

Algorithm:

=over 4

=item o If $session -> id() returns a true value, return that

E.g. The user supplied one in $session -> new(id => $id).

Return this id.

=item o Try to recover an id from the cookie object or the query object.

If the query object supports the cookie method, call
$self -> query -> cookie and (if that doesn't find an id), $self -> query -> param.

If the query object does not support the cookie method, just call $self -> query -> param.

Return any id found, or 0.

Note: The name of the cookie, and the name of the CGI form field, is passed to new() by the 'name'
option.

=back

=head2 validate_options()

Cross-check a few things.

E.g. When using type => '... id:Static ...', you must supply a (true) id to new(id => ...').

=head2 validate_time($time)

Dies for an invalid time string, or returns the number of seconds corresponding to $time,
which may be positive or negative.

See L</expire([@arg])> for details on the time string format.

=head1 Test Code

t/basic.ini and t/bulk.ini contain DSNs for BerkeleyDB, File, Memcache, MySQL, Pg and SQLite.
Actually, they're the same file, just with different DSNs activated.

So, you can use t/basic.t to run minimal tests (with only File and SQLite activated) like this:

	perl -Ilib t/basic.t

or you can edit t/bulk.ini as desired, and pass it in like this:

	perl -Ilib t/basic.t t/bulk.ini

Simple instructions for installing L<BerkeleyDB> (Oracle and Perl) are in
L<Data::Session::Driver::Berkeley>.

Simple instructions for installing L<Cache::Memcached> and memcached are in
L<Data::Session::Driver::Memcached>.

=head1 FAQ

=head2 Guidelines re Sources of Confusion

This section discusses various issues which confront beginners:

=over 4

=item o 1: Both Data::Session and L<CGI::Snapp> have a I<param()> method

Let's say your L<CGI> script sub-classes L<CGI::Application> or it's successor L<CGI::Snapp>.

Then inside your sub-class's methods, this works:

	$self -> param(a_key => 'a_value');

	Time passes...

	my($value) = $self -> param('a_key');

because those 2 modules each implement a method called I<param()>. Basically, you're storing a value
(via 'param') inside $self.

But when you store an object of type Data::Session using I<param()>, it looks like this:

	$self -> param(session => Data::Session -> new(...) );

Now, Data::Session itself I<also> implements a method called I<param()>. So, to store something in
the session (but not in $self), you must do:

	$self -> param('session') -> param(a_key => 'a_value');

	Time passes...

	my($value) = $self -> param('session') -> param('a_key');

It should be obvious that confusion can arise here because the 2 objects represented by $self and
$self -> param('session') both have I<param()> methods.

=item o 2: How exactly should a L<CGI> script save a session?

The first example in the Synopsis shows a very simple L<CGI> script doing the right thing by
calling I<flush()> just before it exits.

Alternately, if you sub-class L<CGI::Snapp>, the call to I<flush()> is best placed in your
I<teardown()> method, which is where you override L<CGI::Snapp/teardown()>. The point here is that
your I<teardown()> is called automatically at the end of each run mode.

This important matter is also discussed in L</General Questions> below.

=item o 3: Storing array and hashes

Put simply: Don't do that!

This will fail:

	$self -> param('session') -> param(my_hash => %my_hash);

	Time passes...

	my(%my_hash) = $self -> param('session') -> param('my_hash');

Likewise for an array instead of a hash.

But why? Because the part 'param(my_hash => %my_hash)' is basically assigning a list (%my_hash) to
a scalar (my_hash). Hence, only 1 element of the list (the 'first' key in some unknown order) will
be assigned.

So, when you try to restore the hash with 'my(%my_hash) ...', all you'll get back is a scalar, which
will generate the classic error message 'Odd number of elements in hash assignment...'.

The solution is to use arrayrefs and hashrefs:

	$self -> param('session') -> param(my_hash => {%my_hash});

	Time passes...

	my(%my_hash) = %{$self -> param('session') -> param('my_hash')};

Likewise for an array:

	$self -> param('session') -> param(my_ara => [@my_ara]);

	Time passes...

	my(@my_ara) = @{$self -> param('session') -> param('my_ara')};

=back

=head2 General Questions

=over 4

=item o My sessions are not getting written to disk!

This is because you haven't stored anything in them. You're probably thinking sessions are saved
just because they exist.

Actually, sessions are only saved if they have at least 1 parameter set. The session id and
access/etc times are not enough to trigger saving.

Just do something like $session -> param(ok => 1); if you want a session saved just to indicate it
exists. Code like this sets the modified flag on the session, so that flush() actually does the
save.

Also, see L</Trouble with Exiting>, below, to understand why flush() must be called explicitly in
persistent environments.

=item o Why don't the test scripts use L<Test::Database>?

I decided to circumvent it by using L<DBIx::Admin::DSNManager> and adopting the wonders of nested
testing. But, since V 1.11, I've replaced that module with L<Config::Tiny>, to reduce dependencies,
and hence to make it easier to get L<Data::Session> into Debian.

See t/basic.t, and in particular this line: subtest $driver => sub.

=item o Why didn't you use OSSP::uuid as did L<CGI::Session::ID::uuid>?

Because when I tried to build that module (under Debian), ./configure died, saying I had set 2
incompatible options, even though I hadn't set either of them.

=item o What happens when 2 processes write sessions with the same id?

The last-to-write wins, by overwriting what the first wrote.

=item o Params::Validate be adopted to validate parameters?

Not yet.

=back

=head1 Troubleshooting

=head2 Trouble with Errors

When object construction fails, new() sets $Data::Session::errstr and returns undef.
This means you can use this idiom:

	my($session) = Data::Session -> new(...) || process_error($Data::Session::errstr);

However, when methods detect errors they die, so after successful object construction, you can do:

	use Try::Tiny;

	try
	{
		$session -> some_method_which_may_die;
	}
	catch
	{
		process_error($_); # Because $_ holds the error message.
	};

=head2 Trouble with Exiting

If the session object's clean-up code is called, in DESTROY(), the session data is automatically
flushed to storage (except when it's been deleted, or has not been modified).

However, as explained below, there can be problems with your code (i.e. not with L<Data::Session>)
such that this clean-up code is not called, or, if called, it cannot perform as expected.

The general guideline, then, is that you should explicitly call C<flush()> on the session object
before your program exits.

Common traps for beginners:

=over 4

=item o Creating 2 CGI-like objects

If your code creates an object of type L<CGI> or similar, but you don't pass that object into
L<Data::Session> via the 'query' parameter to new(), this module will create one for you,
which can be very confusing.

The solution is to always create such a object yourself, and to always pass that into
L<Data::Session>.

In the case that the user of a CGI script runs your code for the first time, there will be no
session id, either from a cookie or from a form field.

In such a case, L<Data::Session> will do what you expect, which is to generate a session id.

=item o Letting your database handle go out of scope too early

When your script is exiting, and you're trying to save session data to storage via a database
handle, the save will fail if the handle goes out of scope before the session data is flushed to
storage.

So, don't do that.

=item o Assuming your session object goes out of scope when it doesn't

In persistent environments such as L<Plack>, FastCGI and mod_perl, your code exits as expected, but
the session object does not go out of scope in the normal way.

In cases like this, it is mandatory for you to call flush() on the session object before your
code exits, since persistent environments operate in such a way that the session object's clean-up
code does not get called. This means that flush() is not called automatically by DESTROY() as you
would expect, because DESTROY() is not being called.

=item o Creating circular references anywhere in your code

In these cases, Perl's clean-up code may not run to completion, which means the session object may
not have its clean-up code called at all. As above, flush() may not get called.

If you must create circular references, it's vital you debug the exit logic using a module such as
L<Devel::Cycle> before assuming the fault is with L<Data::Session>.

=item o Using signal handlers

Write your code defensively, if you wish to call the session object's flush() method when a signal
might affect program exit logic.

=back

=head2 Trouble with IDs

The module uses code like if (! $self -> id), which means ids must be (Perl) true values, so undef,
0 and '' will not work.

=head2 Trouble with UUID16

While testing with UUID16 as the id generator, I got this message:
... invalid byte sequence for encoding "UTF8" ...

That's because when I create a database (in Postgres) I use "create database d_name owner d_owner
encoding 'UTF8';" and UUID16 simply produces a 16 byte binary value, which is not guaranteed to be
or contain a valid UTF8 character.

This also means you should never try to use 'driver:File;id:UUID16 ...', since the ids generated by
this module would rarely if ever be valid as a part of a file name.

=head2 Trouble with UUID64

While testing with UUID64 as the id generator, I got this message:
...  Session ids cannot contain \ or / ...

That's because I was using a File driver, and UUID's encoded in base 64 can contain /.

So, don't do that.

=head1 Version Numbers

Version numbers < 1.00 represent development versions. From 1.00 up, they are production versions.

=head1 Repository

L<https://github.com/ronsavage/Data-Session.git>

=head1 Support

Log a bug on RT: L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Session>.

The L<CGI::Application> mailing list often discusses issues relating to L<CGI::Session>,
and the author of L<Data::Session> monitors that list, so that is another forum available to you.

See L<http://www.erlbaum.net/mailman/listinfo/cgiapp> for details.

=head1 Thanks

Many thanks are due to all the people who contributed to both L<Apache::Session> and
L<CGI::Session>.

Likewise, many thanks to the implementors of nesting testing. See L<Test::Simple>.

=head1 Author

L<Data::Session> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2010.

Home page: L<http://savage.net.au/index.html>.

=head1 Copyright

Australian copyright (c) 2010, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License, a copy of which is available at:
	http://www.opensource.org/licenses/index.html

=cut
