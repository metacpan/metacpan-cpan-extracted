package Class::Shared::Backend;

use strict;
use warnings;

use Carp ();
use Fcntl qw(:flock F_SETFD FD_CLOEXEC O_RDWR O_WRONLY O_CREAT O_EXCL);
use File::Spec ();
use IO::Socket::INET;
use IO::Socket::UNIX;
use Scalar::Util ();
use Socket qw(SOCK_STREAM);
use Storable ();
use Time::HiRes ();

use Log::Abstraction ();
use Object::Configure ();
use Params::Get ();
use Params::Validate::Strict ();

use Class::Shared ();
use Class::Shared::Protocol ();

# version->declare here alone: this is VERSION_FROM, and with it MakeMaker
# writes 0.001.0 into META; a plain dotted string becomes v0.001.0 there.
use version; our $VERSION = version->declare('0.001.0');

our $DEFAULT_MAX_CLIENTS = 128;
our $DEFAULT_MAX_OBJECTS = 4096;

# How long a new backend waits, in seconds, for a lock that a backend which is
# shutting down still holds.
our $DEFAULT_START_TIMEOUT = 2;

# The accept queue of the listening socket.
our $LISTEN_BACKLOG = 64;

# The most one read takes from a client.  A larger frame arrives over several
# turns of the loop and waits in that client's buffer.
our $READ_CHUNK = 65536;

# While a TLS handshake is pending the loop wakes this often, in seconds, to
# expire the ones that have run out of time.
our $HANDSHAKE_POLL = 0.25;

# How long a connection may spend on its TLS handshake.  The handshake is done
# a little at a time from the select loop, so a peer that connects and then
# says nothing costs one connection slot for this long, not the whole backend.
our $HANDSHAKE_TIMEOUT = 5;

# How much may be waiting to be written to one client before it is dropped.
# Replies are queued per connection and written from the loop as the socket
# takes them, so this is what stops a client that asks for an answer and then
# stops reading from holding that reply, and the memory for it, indefinitely.
# The default is one maximum-size frame, so no reply the protocol allows is
# refused for being large.
our $MAX_QUEUED = $Class::Shared::Protocol::MAX_FRAME + 4096;

# max_queued bounds how much one client may have waiting; this bounds how long
# it may have it there.  A stalled queue that the socket will not take is a
# client that has stopped reading, and holding its memory for ever is what the
# bound alone allows.  The clock is fractional, so a slow reader that keeps
# taking bytes is not dropped early by the second hand.
our $WRITE_TIMEOUT = 30;

# A request that has only partly arrived is held in memory until the rest
# does.  max_queued_total bounds replies; these two bound requests.  Without
# them every client could send nearly a whole maximum-size frame, stop, and
# leave the backend holding max_clients times that for as long as it liked.
our $MAX_BUFFERED_TOTAL = 4 * ($Class::Shared::Protocol::MAX_FRAME + 4096);
our $READ_TIMEOUT = 30;

# A request no longer than this is thawed straight away.  Each level of nesting
# takes at least one byte, and this many levels fit easily on any C stack; a
# longer request is first tried in a child process.
our $THAW_UNCHECKED = 4096;

# The most seconds that trial may take.
our $THAW_TRIAL_TIMEOUT = 30;

# The log is copied to LOG.1 and emptied when it passes this many bytes, so the
# two together are bounded however much a client makes the backend say.
our $MAX_LOG_SIZE = 10 * 1024 * 1024;

# How long a greeted client may send nothing at all.  0, the default, is for
# ever: a client that holds an object and uses it rarely is the normal case.
our $IDLE_TIMEOUT = 0;

# How long, in seconds, the listener is left alone after accept() failed for
# want of file descriptors or memory.
our $ACCEPT_PAUSE = 0.1;

# How long one call to a target (a method, or its constructor) may run, in
# seconds.  The backend runs one request at a time, so a call that does not
# return holds every client; this is what ends it.  0 means no limit.
our $CALL_TIMEOUT = 60;

# What a connection is told when it asks for an object before naming a class.
our $NO_CLASS_ERROR = 'this connection named no class in its handshake';

# What each option to new() may be.  The checks here are the ones that do not
# depend on another option; the rules that do ("a TCP listener needs a token")
# stay in new(), where they can explain themselves.  An empty token or TLS file
# name is allowed on purpose, so that those rules, not a type error, are what the
# caller reads.  A token is limited to printable ASCII because it is turned into
# an HMAC key as bytes (see "ENCODING" in the POD).
my %OPTION_SCHEMA = (
	socket            => { type => 'string',  optional => 1, min => 1 },
	dir               => { type => 'string',  optional => 1, min => 1 },
	host              => { type => 'string',  optional => 1, min => 1 },
	port              => { type => 'integer', optional => 1, min => 1, max => 65535 },
	tls_cert          => { type => 'string',  optional => 1 },
	tls_key           => { type => 'string',  optional => 1 },
	tls_ca            => { type => 'string',  optional => 1 },
	token             => { type => 'string',  optional => 1, matches => qr/\A[\x20-\x7E]*\z/ },
	log               => { type => 'string',  optional => 1, min => 1 },
	daemonize         => { type => 'boolean', optional => 1 },
	max_clients       => { type => 'integer', optional => 1, min => 1 },
	max_objects       => { type => 'integer', optional => 1, min => 1 },
	max_queued        => { type => 'integer', optional => 1, min => 1 },
	max_queued_total  => { type => 'integer', optional => 1, min => 1 },
	write_timeout     => { type => 'number',  optional => 1, min => 0 },
	handshake_timeout => { type => 'number',  optional => 1, min => 0 },
	start_timeout     => { type => 'number',  optional => 1, min => 0 },
	call_timeout      => { type => 'number',  optional => 1, min => 0 },
	read_timeout      => { type => 'number',  optional => 1, min => 0 },
	max_buffered_total => { type => 'integer', optional => 1, min => 1 },
	idle_timeout      => { type => 'number',  optional => 1, min => 0 },
	max_log_size      => { type => 'integer', optional => 1, min => 0 },

	# Not options of the backend: they say where to look for site settings.
	config_file       => { type => 'string',   optional => 1, min => 1 },
	config_dirs       => { type => 'arrayref', optional => 1 },
);

# The two entries above that only locate settings, and so are never kept.
my %LOCATES_SETTINGS = (config_file => 1, config_dirs => 1);

# The options that are the backend's own.  Worked out once, because the schema
# does not change: Premise 1: %OPTION_SCHEMA is fixed when the module loads.
# Premise 2: what is a backend option depends only on the schema.  Conclusion:
# there is no reason to filter it again on every call to new().
my @BACKEND_OPTIONS = grep { !$LOCATES_SETTINGS{$_} } sort keys %OPTION_SCHEMA;

# A listener's TLS identity is these three files together.
my @TLS_FILES = qw(tls_cert tls_key tls_ca);

# Every refusal from new() starts with this, so a caller can rely on it
# (bin/class-shared removes it before showing the message to a person).
my $REFUSAL_PREFIX = __PACKAGE__ . '->new: ';

# The backend loads each class a client names, once, and holds many objects
# made from them: one per frontend.  Clients talk to it over a unix socket or
# TCP.
sub new {
	my $class = shift;

	# new(%options) and new(\%options) are both fine, and so is new().
	my %opt = %{ _options($class, Params::Get::get_params(undef, \@_)) };

	my ($host, $port, $socket) = @opt{qw(host port socket)};

	# Premise 1: _options leaves no undef value in %opt, so "defined" means "was
	# given".  Premise 2: an empty token or TLS file name is let through the
	# schema on purpose, so "given" is not "set": a value is set when it is not
	# empty.  Conclusion: each of the three facts below is worked out once, and
	# every rule after this reads it, where the rules used to repeat the test.
	my $tcp       = defined $host || defined $port;
	my $has_token = length($opt{token} // '') ? 1 : 0;
	my $tls_set   = grep { length($opt{$_} // '') } @TLS_FILES;

	my $control;

	if ($tcp) {
		_refuse('a TCP listener needs both host and port')
			unless defined $host && defined $port;

		_refuse('use either socket or host/port, not both')
			if defined $socket;

		# A TCP port is reachable by anybody who can route to it, and thawing
		# is running code, so refuse to be the listener that would deserialise
		# whatever a stranger sends.
		_refuse('a TCP listener needs a token: without one it would thaw whatever arrives')
			unless $has_token;

		# TLS is not a wrapper here but the listener itself: this certificate
		# proves who the backend is, tls_ca decides which client certificates
		# are welcome, and a client without one is never accepted.  All three
		# are needed, so the number that are set must be the number there are.
		_refuse('a TCP listener needs tls_cert, tls_key and tls_ca: '
			. 'without them the traffic would be readable to anyone who can route to it')
			unless $tls_set == @TLS_FILES;

		# Premise: a TCP listener has no socket (refused above).  Its lock, pid
		# file and log still live in the directory a socket would have used.
		$control = Class::Shared::socket_path($opt{dir});
	} else {
		# Premise: the guards above did not run, so there is no host or port.
		# Conclusion: the socket is either the one given or the default one, and
		# it is also the control path, so it is worked out once, here.
		$socket = defined $socket
			? Class::Shared::check_socket_path($socket)
			: Class::Shared::socket_path($opt{dir});
		$control = $socket;

		# The socket is mode 0600 in a directory only its owner can write to,
		# so the kernel has already decided who may connect: a digest on every
		# frame would buy nothing here and cost 32 bytes on each message.
		_refuse("a unix socket needs no token: $Class::Shared::UNIX_TRUST_REASON")
			if $has_token;

		_refuse("a unix socket needs no TLS: $Class::Shared::UNIX_TRUST_REASON")
			if $tls_set;
	}

	# What is used when an option is not given.  Read here, each time, and not
	# once when the module loads, because these are package variables that a
	# program may set before it calls new().  Premise 1 makes "not given" the
	# same as "not in %opt", so one merge replaces a test for each option; and
	# because the schema never allows a zero here, the merge cannot differ from
	# the "x || default" it replaces, except for a log that is called "0", which
	# "||" wrongly treated as not given.
	my %set = (
		max_clients       => $DEFAULT_MAX_CLIENTS,
		max_objects       => $DEFAULT_MAX_OBJECTS,
		max_queued        => $MAX_QUEUED,
		write_timeout     => $WRITE_TIMEOUT,
		handshake_timeout => $HANDSHAKE_TIMEOUT,
		start_timeout     => $DEFAULT_START_TIMEOUT,
		call_timeout      => $CALL_TIMEOUT,
		read_timeout      => $READ_TIMEOUT,
		max_buffered_total => $MAX_BUFFERED_TOTAL,
		idle_timeout      => $IDLE_TIMEOUT,
		max_log_size      => $MAX_LOG_SIZE,
		daemonize         => 0,
		log               => $control . '.log',
		%opt,
	);

	# Four times one client's bound by default: enough that a few clients may
	# each be holding a maximum-size reply, small enough that a few hundred
	# cannot each be holding one.
	$set{max_queued_total} //= $set{max_queued} * 4;

	my $self = bless {
		classes       => {},
		socket        => $socket,
		host          => $host,
		port          => $port,
		# An empty token is none: kept, it would sign frames with an empty key.
		token         => $has_token ? $opt{token} : undef,
		tls_cert      => $opt{tls_cert},
		tls_key       => $opt{tls_key},
		tls_ca        => $opt{tls_ca},
		dir_hint      => $opt{dir},
		control       => $control,
		log           => $set{log},

		# The schema says a boolean is 0 or 1 once it has been checked, so
		# nothing here has to turn "true" into 1.
		daemonize         => $set{daemonize},
		max_clients       => $set{max_clients},
		max_objects       => $set{max_objects},
		max_queued        => $set{max_queued},
		max_queued_total  => $set{max_queued_total},
		write_timeout     => $set{write_timeout},
		handshake_timeout => $set{handshake_timeout},
		start_timeout     => $set{start_timeout},
		call_timeout      => $set{call_timeout},
		read_timeout      => $set{read_timeout},
		max_buffered_total => $set{max_buffered_total},
		idle_timeout      => $set{idle_timeout},
		max_log_size      => $set{max_log_size},
		objects       => {},
		clients       => {},
		queued        => 0,
		next_id       => 1,
		next_serial   => 1,
		calls         => 0,
		constructed   => 0,
		started       => time,
		stop          => 0,
		cleaned       => 0,
		logger        => undef,
		logger_pid    => undef,
		listener      => undef,
		lock          => undef,
		owns_socket   => 0,
		owner_pid     => undef,
		address       => undef,
	}, $class;

	return $self;
}

# Purpose:       refuse the arguments of new() in this module's usual form.
# Entry:         $why is the reason, without the prefix or a line break.
# Exit status:   none: it dies.
# Side effects:  none.
sub _refuse {
	my ($why) = @_;

	die $REFUSAL_PREFIX . $why . "\n";
}

# Purpose:       work out the options for one backend from three places, in
#                this order of importance: what the caller passed, then the
#                environment (Class__Shared__Backend__NAME), then a config file
#                (class-shared-backend.yml).  The caller always wins, so a
#                stray variable in the environment cannot override a token or a
#                certificate that the program chose.
# Entry:         $class is the class being built; $given is a hash reference
#                of the caller's arguments, or undef if there were none.
# Exit status:   a hash reference of valid options (only those that were set);
#                dies with "Class::Shared::Backend->new: ..." if an argument
#                or a configured value is unknown or has the wrong type.
# Side effects:  reads config files and the environment.
sub _options {
	my ($class, $given) = @_;

	# What the caller passed is checked first, so that a misspelt name is
	# reported as theirs, and not lost among the site settings.
	my $explicit = _validate($given || {}, 'an argument');

	# undef means "not given", which is how bin/class-shared passes an option
	# it has nothing for; it must not hide a site setting.
	delete @{$explicit}{ grep { !defined $explicit->{$_} } keys %{$explicit} };

	# Object::Configure gives the caller's values the LOWEST priority and adds
	# keys of its own (a logger, the config path).  So it is given only the
	# place to look, and only the options this class knows are taken back.
	# The backend writes its own log, so no logger is wanted from it.  The two
	# locators are taken out of $explicit as they are passed on, so what is left
	# in it is exactly what is kept.
	my %locate = map { $_ => delete $explicit->{$_} }
		grep { exists $explicit->{$_} } keys %LOCATES_SETTINGS;

	my $configured = Object::Configure::configure($class, { logger => 'NULL', %locate });

	my %site = map { $_ => $configured->{$_} }
		grep { defined $configured->{$_} } @BACKEND_OPTIONS;

	# Values from a file or the environment arrive as text, so they are checked
	# (and turned into numbers) in the same way as the caller's.  Premise: every
	# entry in the schema is optional.  Premise: nothing was configured.
	# Conclusion: there is nothing to check and nothing to turn into a number,
	# so the checker is not called for an empty set.
	my $site = %site ? _validate(\%site, 'a configured value') : {};

	return { %{$site}, %{$explicit} };
}

# Purpose:       check one set of options against %OPTION_SCHEMA.
# Entry:         $input is a hash reference; $source says where it came from, for
#                the message ("an argument", "a configured value").
# Exit status:   the validated hash reference (numbers and booleans coerced);
#                dies with a message in this module's usual form if not.
# Side effects:  none.
sub _validate {
	# Evals below must not leave their errors in the caller's $@.
	local $@;
	my ($input, $source) = @_;

	my $valid = eval {
		Params::Validate::Strict::validate_strict(
			schema => \%OPTION_SCHEMA,
			input  => $input,
		);
	};

	if (!$valid) {
		# The validator names its own source line and ours; neither helps a
		# person, who needs to know which option and what was wrong with it.
		my $why = $@ || 'invalid options';
		$why =~ s/\AParams::Validate::Strict line \d+: validate_strict: //;
		$why =~ s/ at \S+ line \d+\.?\s*\z//;
		$why =~ s/\s+\z//;

		die "Class::Shared::Backend->new: $source is not valid: $why\n";
	}

	return $valid;
}

sub run {
	my $self = shift;

	# A backend object is one life.  After a normal stop the socket, pid file
	# and lock have already been given back, so running again would bind a new
	# socket that the finished cleanup would never remove.
	die "this backend has already run and stopped\n" if $self->{cleaned};

	$self->_daemonize if $self->{daemonize};

	my $started = eval { $self->_setup; 1 };
	if (!$started) {
		my $error = $@ || 'unknown error';
		$self->_log("fatal: $error", 'error');

		# Give back whatever was taken before the failure, so that another
		# start can succeed while this object is still alive.
		$self->_cleanup;
		@{$self}{qw(cleaned owns_socket)} = (0, 0);

		die $error unless $self->{daemonize};
		exit 1;
	}

	$self->_log("serving on $self->{address} (pid $$"
		. ($self->{token} ? ', token required' : '')
		. (defined $self->{host} ? ', TLS with client certificates' : '') . ')');

	$self->_loop;
	$self->_cleanup;

	$self->_log('stopped');

	return 0;
}

# Remove the socket only if this object bound it.  A backend that failed to
# start because another one is already serving never owned the path, and
# unlinking it here would leave the live backend running but unreachable.
sub DESTROY {
	my $self = shift;
	return if $self->{cleaned};

	# A target that forks leaves a copy of this object in the child, and the
	# socket is not the child's to remove.
	return if defined $self->{owner_pid} && $self->{owner_pid} != $$;

	$self->{cleaned} = 1;

	# A destructor must not disturb the $@ or $! of the code that was running
	# when the object went out of scope.
	local ($@, $!);

	if ($self->{owns_socket} && -e $self->{socket}) {
		unlink($self->{socket})
			or Carp::carp("Class::Shared::Backend: cannot remove $self->{socket}: $!");
	}

	return;
}

# The class is the client's choice, so it is loaded when a client asks for it
# rather than at startup: require brings the file in, and import is called
# because a module with exports is normally used with use, not require.  Each
# class is loaded once however many clients want it.
sub _load_class {
	my ($self, $class) = @_;

	return 1 if $self->{classes}{$class};

	my $file = $class;
	$file =~ s{::}{/}g;
	$file .= '.pm';

	eval { require $file; 1 }
		or return (0, "cannot load $class: " . ($@ || 'unknown error'));

	if ($class->can('import')) {
		eval { $class->import; 1 }
			or return (0, "cannot import $class: " . ($@ || 'unknown error'));
	}

	$self->{classes}{$class} = 1;

	return (1);
}

sub _setup {
	my $self = shift;

	# The lock, the pid file and the default log live beside the control path,
	# so that is the only directory this backend needs.
	my $dir = Class::Shared::dir_of($self->{control});

	my ($dir_ok, $dir_error) = Class::Shared::ensure_dir($dir);
	die "$dir_error\n" unless $dir_ok;

	my $lock_path = $self->{control} . '.owner';
	my $lock;
	sysopen($lock, $lock_path, O_RDWR | O_CREAT, 0600)
		or die "cannot open $lock_path: $!\n";

	# A backend that is shutting down still holds the lock for a moment, so
	# give it a short while before deciding that somebody else is serving.
	my $deadline = time + $self->{start_timeout};
	while (1) {
		last if flock($lock, LOCK_EX | LOCK_NB);
		if (time >= $deadline) {
			die "another backend is already serving ($lock_path is locked)\n";
		}
		Class::Shared::poll_pause();
	}
	$self->{lock} = $lock;

	if (defined $self->{socket}) {
		$self->_setup_unix;
	} else {
		$self->_setup_tcp;
	}

	# A listener that leaked into a method's exec'd child would keep the socket
	# open after this backend had gone.
	fcntl($self->{listener}, F_SETFD, FD_CLOEXEC)
		or die "cannot mark the listener close-on-exec: $!\n";

	# The pid file is a convenience for administrators, so failing to write it
	# is logged and not fatal.
	my $pid_path = $self->{control} . '.pid';
	my $pid_fh;
	open($pid_fh, '>', $pid_path)
		&& print({$pid_fh} "$$\n")
		&& close($pid_fh)
		or $self->_log("cannot write $pid_path: $!", 'error');

	return 1;
}

sub _setup_unix {
	my $self = shift;

	if (-e $self->{socket}) {
		# Only a socket is removed as a leftover: a path that names anything
		# else is not ours to delete, however it came to be given as one.
		die "$self->{socket} exists and is not a socket; refusing to remove it\n"
			unless -S $self->{socket};

		my $probe = IO::Socket::UNIX->new(Type => SOCK_STREAM, Peer => $self->{socket});
		if ($probe) {
			$self->_close($probe, 'the probe connection');
			die "a backend is already listening on $self->{socket}\n";
		}
		unlink $self->{socket}
			or die "cannot remove the stale socket $self->{socket}: $!\n";
	}

	# Bind with no permission for anyone else, so that there is no moment
	# between bind and the chmod below when the socket is open to the group.
	my $old_umask = umask 0177;
	my $listener = IO::Socket::UNIX->new(
		Type     => SOCK_STREAM,
		Local    => $self->{socket},
		Listen   => $LISTEN_BACKLOG,
		Blocking => 1,
	);
	my $bind_error = $!;
	umask $old_umask;

	die "cannot listen on $self->{socket}: $bind_error\n" unless $listener;

	# Recorded before anything else can fail, so that the failure cleans it up.
	$self->{listener} = $listener;
	$self->{address} = $self->{socket};
	$self->{owns_socket} = 1;
	$self->{owner_pid} = $$;

	chmod 0600, $self->{socket}
		or die "cannot set permissions on $self->{socket}: $!\n";

	return 1;
}

sub _setup_tcp {
	my $self = shift;

	die "Class::Shared::Backend: no TCP address configured\n"
		unless defined $self->{host} && defined $self->{port};

	# Loaded only for a TCP listener: a unix socket never pays for TLS, just
	# as it never paid for the digest.
	require IO::Socket::SSL;

	# One context for every connection: the certificates are read and checked
	# once, and each accepted socket starts its handshake against it.
	# The context croaks for a file it cannot use, and only returns false
	# for some other faults, so both are turned into the one message.
	my $context = eval {
		IO::Socket::SSL::SSL_Context->new(
			SSL_server      => 1,
			SSL_version     => $Class::Shared::TLS_VERSIONS,
			SSL_cert_file   => $self->{tls_cert},
			SSL_key_file    => $self->{tls_key},
			SSL_ca_file     => $self->{tls_ca},
			SSL_verify_mode => IO::Socket::SSL::SSL_VERIFY_PEER()
				| IO::Socket::SSL::SSL_VERIFY_FAIL_IF_NO_PEER_CERT(),
		);
	};

	if (!$context) {
		my $why = $@;
		$why =~ s/ at \S+ line \d+\.?\s*\z//;
		$why =~ s/\s+\z//;
		$why = IO::Socket::SSL::errstr() || "$!" || 'unknown error' unless length $why;

		die "cannot set up TLS for $self->{host}:$self->{port}: $why\n";
	}

	$self->{tls_context} = $context;

	# The listener is plain TCP.  The handshake belongs to the connection, where
	# it can be carried a little at a time as that connection becomes ready; in
	# accept() it would stall every client already being served for as long as
	# the newest one stayed silent.
	my $listener = IO::Socket::INET->new(
		LocalAddr => $self->{host},
		LocalPort => $self->{port},
		Proto     => 'tcp',
		Listen    => $LISTEN_BACKLOG,
		ReuseAddr => 1,
	) or die "cannot listen on $self->{host}:$self->{port}: $!\n";

	$self->{listener} = $listener;
	$self->{address} = $self->{host} . ':' . $self->{port};

	return 1;
}

sub _loop {
	my $self = shift;

	local $SIG{TERM} = sub { $self->{stop} = 1 };
	local $SIG{INT}  = sub { $self->{stop} = 1 };
	local $SIG{HUP}  = 'IGNORE';
	local $SIG{PIPE} = 'IGNORE';

	while (!$self->{stop}) {
		my $rin = '';
		my $win = '';
		my $handshaking = 0;
		my $write_deadline;

		vec($rin, fileno($self->{listener}), 1) = 1;

		for my $client (values %{$self->{clients}}) {
			my $fd = fileno($client->{fh});
			next unless defined $fd;

			vec($rin, $fd, 1) = 1;

			if ($client->{handshaking}) {
				$handshaking = 1;

				# A handshake can want to write as well (TLS 1.3 tickets, a
				# full send buffer), so wait for that only when it asked.
				vec($win, $fd, 1) = 1 if $client->{want_write};
			} elsif (length $client->{outbuf}) {
				# A queued reply is waiting for the socket to take it, and has a
				# deadline if it has made no progress yet.
				vec($win, $fd, 1) = 1;

				if (defined $client->{stalled_since}) {
					my $deadline = $client->{stalled_since} + $self->{write_timeout};
					$write_deadline = $deadline
						if !defined $write_deadline || $deadline < $write_deadline;
				}
			}
		}

		# With a handshake in progress, or a queued reply on a deadline, wake up
		# now and then: a peer that never speaks, or one that never reads, would
		# otherwise keep select asleep past the deadline it is on.
		my $timeout = $handshaking ? $HANDSHAKE_POLL : undef;
		my $read_deadline;
		for my $client (values %{$self->{clients}}) {
			my ($deadline) = $self->_read_deadline($client);
			next unless defined $deadline;
			$read_deadline = $deadline
				if !defined $read_deadline || $deadline < $read_deadline;
		}
		if (defined $read_deadline) {
			my $wait = $read_deadline - Time::HiRes::time();
			$wait = 0 if $wait < 0;
			$timeout = $wait if !defined $timeout || $wait < $timeout;
		}
		if (defined $write_deadline) {
			my $wait = $write_deadline - Time::HiRes::time();
			$wait = 0 if $wait < 0;
			$timeout = $wait if !defined $timeout || $wait < $timeout;
		}

		# After accept() ran out of descriptors the waiting connection keeps the
		# listener readable, so watching it would spin the processor.  It is left
		# out of the select for a short while instead.
		if (defined $self->{accept_after}) {
			my $wait = $self->{accept_after} - Time::HiRes::time();
			if ($wait > 0) {
				vec($rin, fileno($self->{listener}), 1) = 0;
				$timeout = $wait if !defined $timeout || $wait < $timeout;
			} else {
				delete $self->{accept_after};
			}
		}

		my $ready = select(my $rout = $rin, my $wout = $win, undef, $timeout);

		$self->_expire_handshakes if $handshaking;
		$self->_expire_writes if defined $write_deadline;
		$self->_expire_reads(defined $ready && $ready > 0 ? $rout : '')
			if defined $read_deadline;

		next if !defined $ready || $ready <= 0;

		if (vec($rout, fileno($self->{listener}), 1)) {
			$self->_accept;
		}

		for my $key (keys %{$self->{clients}}) {
			my $client = $self->{clients}{$key};
			next unless $client;

			my $fd = fileno($client->{fh});
			next unless defined $fd;

			my $readable = vec($rout, $fd, 1);
			my $writable = vec($wout, $fd, 1);

			if ($client->{handshaking}) {
				next unless $readable || ($client->{want_write} && $writable);
				$self->_continue_tls($client);
			} else {
				next unless $readable || $writable;

				$self->_serve_client($client) if $readable;
				$self->_flush($client) if $writable && !$client->{closed};
			}

			last if $self->{stop};
		}
	}

	return 1;
}

# Drop connections whose handshake has run out of time, so a peer that opens a
# socket and then says nothing frees its slot again.
sub _expire_handshakes {
	my $self = shift;

	my $now = time;

	for my $client (values %{$self->{clients}}) {
		next unless $client->{handshaking};
		next if $client->{deadline} > $now;

		$self->_drop_client($client, 'TLS handshake timed out');
	}

	return 1;
}

# Purpose:       keep count of what a client has half sent, and bound the total.
# Entry:         $client has just been read from; $completed is how many whole
#                frames that read finished.
# Exit status:   1.
# Side effects:  releases an emptied buffer; while the half-sent frames of all
#                clients add up to more than max_buffered_total, drops the
#                client whose frame has been arriving the longest.
# Why:           the oldest is the one to go because a client that is hoarding
#                memory has an old frame, and an honest large request a new one.
sub _account_inbound {
	my ($self, $client, $completed) = @_;

	if (!length $client->{buffer}) {
		# Emptying a string keeps its memory, and a frame can be 64 MiB.
		undef $client->{buffer};
		$client->{buffer} = '';
		delete @{$client}{qw(partial_started partial_progress)};
		return 1;
	}

	my $now = Time::HiRes::time();
	delete $client->{partial_started} if $completed;
	$client->{partial_started} //= $now;
	$client->{partial_progress} = $now;

	my @partial = grep { length($_->{buffer} // '') } values %{$self->{clients}};
	my $total = 0;
	$total += length $_->{buffer} for @partial;

	for my $oldest (sort { ($a->{partial_started} // $now) <=> ($b->{partial_started} // $now) } @partial) {
		last if $total <= $self->{max_buffered_total};

		my $held = length $oldest->{buffer};
		$total -= $held;
		$self->_drop_client($oldest, "half-received requests add up to more than the "
			. "$self->{max_buffered_total} bytes the backend may hold; this one held $held");
	}

	return 1;
}

# Purpose:       say by when a client must send something, and why.
# Entry:         $client is a client record.
# Exit status:   (time, reason for dropping it), or () for no limit.
# Side effects:  none.
sub _read_deadline {
	my ($self, $client) = @_;

	# A TLS handshake has its own deadline.
	return () if $client->{handshaking};

	my @partial = defined $client->{partial_progress}
		? ($client->{partial_progress} + $self->{read_timeout},
			'a request of which ' . length($client->{buffer})
			. " bytes had arrived made no progress for $self->{read_timeout} second(s)")
		: ();

	# Until a hello is accepted its deadline stands whatever else arrives, or
	# a hello that never ends would keep its place for ever.
	if (!$client->{greeted} && defined $client->{greet_by}) {
		return @partial if @partial && $partial[0] < $client->{greet_by};
		return ($client->{greet_by}, $self->_no_hello_reason);
	}

	return @partial if @partial;

	# A reply still being written is write_timeout's business.
	return ($client->{last_request} + $self->{idle_timeout},
		"sent nothing for $self->{idle_timeout} second(s)")
		if $self->{idle_timeout} && defined $client->{last_request}
			&& !length $client->{outbuf};

	return ();
}

sub _no_hello_reason {
	my $self = shift;

	return "no accepted hello within $self->{handshake_timeout} second(s)";
}

# Drop connections that have not sent what they should have in time.  One that
# has bytes waiting to be read ($readable) is left alone: the backend may only
# just have come back from a long call, and those bytes are its progress.
sub _expire_reads {
	my ($self, $readable) = @_;

	my $now = Time::HiRes::time();

	for my $client (values %{$self->{clients}}) {
		next if $client->{closed};
		my ($deadline, $reason) = $self->_read_deadline($client);
		next unless defined $deadline;
		next if $deadline > $now;
		next if length $readable && vec($readable, fileno($client->{fh}), 1);

		$self->_drop_client($client, $reason);
	}

	return 1;
}

# Purpose:       keep the log from filling the disk.
# Entry:         max_log_size is a number of bytes, 0 for no limit.
# Exit status:   1.
# Side effects:  copies a log over the limit to LOG.1 (replacing it) and
#                empties the log.
# Why:           copied and emptied, not renamed: standard output and error of
#                the backend, which the target writes to, hold the file open, and
#                after a rename they would go on filling a file nobody can see.
#                A log that is a symbolic link or a device is left to whoever
#                made it so.
sub _trim_log {
	my $self = shift;

	my $limit = $self->{max_log_size};
	return 1 unless $limit && defined $self->{log};

	my $path = File::Spec->rel2abs($self->{log});
	return 1 unless lstat($path) && -f _ && -s _ > $limit;

	local ($!, $@);

	# From here on only this handle is read and emptied.  The name may come to
	# mean another file at any moment, so check that what was opened is what the
	# name meant: a plain file, not a link to one.
	open(my $log, '+<', $path) or return 1;
	my @opened = stat($log);
	my @named = lstat($path);
	return 1 unless @named && -f _ && $named[0] == $opened[0] && $named[1] == $opened[1];

	my $old = "$path.1";

	# Made anew, owner only, so that nothing already there is written through.
	unlink($old);
	if (sysopen(my $to, $old, O_WRONLY | O_CREAT | O_EXCL, 0600)) {
		while (sysread($log, my $chunk, $READ_CHUNK)) {
			last unless syswrite($to, $chunk);
		}
		close($to);
	}

	# Emptied even if the copy failed: bounding the disk is the point.
	truncate($log, 0);
	close($log);

	return 1;
}

# Drop connections whose queued reply the socket has stopped taking, so a
# client that has stopped reading cannot sit on the memory it was allowed.
sub _expire_writes {
	my $self = shift;

	my $now = Time::HiRes::time();

	for my $client (values %{$self->{clients}}) {
		next if $client->{closed};
		next unless length $client->{outbuf};
		next unless defined $client->{stalled_since};
		next if $client->{stalled_since} + $self->{write_timeout} > $now;

		$self->_drop_client($client, 'a queued reply of ' . length($client->{outbuf})
			. ' bytes made no progress for ' . $self->{write_timeout} . ' second(s)');
	}

	return 1;
}

sub _accept {
	my $self = shift;

	my $fh = $self->{listener}->accept;
	if (!$fh) {
		if ($!{EMFILE} || $!{ENFILE} || $!{ENOBUFS} || $!{ENOMEM}) {
			# Logged once for each shortage, not once for each attempt.
			$self->_log("cannot accept a connection: $!", 'warn')
				unless $self->{accept_failing}++;
			$self->{accept_after} = Time::HiRes::time() + $ACCEPT_PAUSE;
		}
		return;
	}
	delete $self->{accept_failing};

	if (keys %{$self->{clients}} >= $self->{max_clients}) {
		# A unix client can be told, signed like every other frame.  A TCP
		# client has not handshaken yet, so there is no session to sign one
		# for: it is closed, and the frontend reports a failed connection.
		if (!defined $self->{host}) {
			my ($bytes) = Class::Shared::Protocol::encode_frame(
				_failure('busy', "backend is serving too many clients ($self->{max_clients})"),
				$self->{token},
			);
			Class::Shared::Protocol::write_all($fh, $bytes) if defined $bytes;
		}

		$self->_close($fh, 'a refused connection');
		return;
	}

	# A unix client that stops reading must not hold the loop either, so every
	# accepted socket is non-blocking from here on, TLS or not.  Neither step
	# can be skipped: a blocking socket stalls everybody, and one that leaks
	# into an exec'd child outlives its connection.
	if (!(fcntl($fh, F_SETFD, FD_CLOEXEC) && defined $fh->blocking(0))) {
		$self->_log("refused a connection: cannot prepare its socket: $!", 'warn');
		$self->_close($fh, 'a refused connection');
		return;
	}

	my $client = {
		fh      => $fh,
		buffer  => '',
		outbuf  => '',
		greeted => 0,
		serial  => $self->{next_serial}++,
		objects => {},
		closed  => 0,
		greet_by => Time::HiRes::time() + $self->{handshake_timeout},
	};

	if (defined $self->{host}) {
		my $ssl = $self->_start_tls($fh);

		if (!$ssl) {
			$self->_log('refused a TLS connection: '
				. (IO::Socket::SSL::errstr() || 'cannot start a handshake'), 'warn');
			$self->_close($fh, 'a refused connection');
			return;
		}

		# TODO: Data Flow Anomaly - DD: for TLS, fh was defined with the plain socket and is redefined unread
		$client->{fh}          = $ssl;
		$client->{handshaking} = 1;
		$client->{want_write}  = 0;
		$client->{deadline}    = time + $self->{handshake_timeout};
	}

	$self->{clients}{ fileno($client->{fh}) } = $client;

	return 1;
}

# Give an accepted socket its TLS layer but do not perform the handshake here:
# accept_SSL() is called from the select loop as the socket becomes ready, so a
# silent peer holds one pending handshake instead of the whole backend.
sub _start_tls {
	my ($self, $fh) = @_;

	# _accept has already made it non-blocking; start_SSL keeps that.
	return IO::Socket::SSL->start_SSL(
		$fh,
		SSL_server         => 1,
		SSL_startHandshake => 0,
		SSL_reuse_ctx      => $self->{tls_context},
	);
}

# One step of a pending handshake.  Returns nothing; the client either becomes
# an ordinary connection, waits for the next readiness, or is dropped.
sub _continue_tls {
	my ($self, $client) = @_;

	my $fh = $client->{fh};

	if ($fh->accept_SSL) {
		$client->{handshaking} = 0;
		$client->{want_write}  = 0;
		delete $client->{deadline};
		# The time to say hello starts once there is a channel to say it on.
		$client->{greet_by} = Time::HiRes::time() + $self->{handshake_timeout};

		# The socket stays non-blocking: a frame, or the TLS record carrying
		# it, that arrives in pieces waits in this client's buffer while the
		# loop serves everybody else.
		return 1;
	}

	# A failed handshake reblesses the socket back to the plain class it was
	# upgraded from, so the handle can no longer answer TLS questions.  Ask
	# the TLS layer for the last error instead.
	my $error = do { no warnings 'once'; $IO::Socket::SSL::SSL_ERROR };

	if (defined $error && $error == IO::Socket::SSL::SSL_WANT_READ()) {
		$client->{want_write} = 0;
		return 1;
	}

	if (defined $error && $error == IO::Socket::SSL::SSL_WANT_WRITE()) {
		$client->{want_write} = 1;
		return 1;
	}

	$self->_log('refused a TLS connection: '
		. (IO::Socket::SSL::errstr() || 'handshake failed'), 'warn');
	$self->_drop_client($client, 'TLS handshake failed');

	return;
}

# True when a failed read or write means "not yet", not "gone": a non-blocking
# socket with nothing to give (or no room to take), or a TLS layer waiting for
# the other direction.  The errno it looks at is the one the call that just
# failed produced, never one left over from before it: the caller clears $!.
sub _would_block {
	my ($self, $fh, $direction) = @_;

	$direction = 'read' unless defined $direction;

	return 1 if $!{EAGAIN} || $!{EWOULDBLOCK};

	my $want = "want_$direction";
	return 1 if $fh->can($want) && $fh->$want;

	# A write can be waiting on a TLS layer that has to read something first.
	return 1 if $direction eq 'write' && $fh->can('want_read') && $fh->want_read;

	return 0;
}

sub _serve_client {
	my ($self, $client) = @_;

	# errno outlives a call, and a TLS read can fail for its own reasons
	# without touching it, so clear it and let only this sysread supply the
	# EAGAIN that means "not yet".  Otherwise a genuine TLS error could be
	# mistaken for half a frame and the client would be kept rather than
	# dropped.
	$! = 0;

	my $read = sysread($client->{fh}, my $chunk, $READ_CHUNK);

	if (!defined $read) {
		# Half a frame is not a fault: keep what has arrived and come back
		# when the rest does.  The buffer is per client, so a slow sender
		# only ever delays itself.
		return 1 if $self->_would_block($client->{fh});

		$self->_drop_client($client, 'read error: ' . ($! || 'unknown error'));
		return;
	}

	if ($read == 0) {
		$self->_drop_client($client, 'client disconnected');
		return;
	}

	$client->{buffer} .= $chunk;
	my $completed = 0;

	while (1) {
		# With a token, take_frame checks the frame's digest before it
		# thaws anything, so an unauthenticated peer never gets as far as
		# Storable.
		my ($status, $message, $protocol_error)
			= Class::Shared::Protocol::take_frame(\$client->{buffer}, $self->{token},
				sub { $self->_survives_thaw($_[0]) });

		if ($status == 0) {
			last;
		}

		$completed++ if $status > 0;

		if ($status < 0) {
			$self->_send($client, _failure('protocol', $protocol_error));
			$self->_drop_client($client, $protocol_error);
			last;
		}

		my $response = eval { $self->_dispatch($client, $message) };
		if ($@) {
			my $internal = $@;
			$internal =~ s/\s+\z//;
			$self->_log("internal error while handling a request: $internal", 'error');
			$response = _failure('internal', $internal);
		}

		$self->_send($client, $response) if defined $response;

		last if $client->{closed};
		last if $self->{stop};
	}

	# _expire_reads spares a connection with bytes waiting, so one that never
	# stops sending is held to its hello deadline here, once they are read.
	$self->_drop_client($client, $self->_no_hello_reason)
		if !$client->{closed} && !$client->{greeted}
			&& defined $client->{greet_by}
			&& $client->{greet_by} <= Time::HiRes::time();

	$client->{last_request} = Time::HiRes::time() if $completed;
	$self->_account_inbound($client, $completed) unless $client->{closed};
	$self->_trim_log;

	return 1;
}

# Purpose:       say whether a request can be thawed without killing us.
# Entry:         $body is an authenticated Storable image.
# Exit status:   1 if it is safe to thaw here, 0 if not.
# Side effects:  for a body over $THAW_UNCHECKED bytes, forks and waits.
# Why:           Storable::thaw calls itself for each level of nesting and has
#                no limit it can be relied on to apply, so a few hundred
#                kilobytes of nested arrays overflow the C stack.  That is a
#                segmentation fault, which eval cannot catch, and every shared
#                object would be lost with the process.  A child with the same
#                stack finds out first.  An ordinary failure to thaw is not its
#                business: only the child dying is.
sub _survives_thaw {
	my ($self, $body) = @_;

	return 1 if length($body) <= $THAW_UNCHECKED;

	require POSIX;
	local ($!, $?, $@);
	local $SIG{CHLD} = 'DEFAULT';

	my $pid = fork;
	if (!defined $pid) {
		$self->_log("refused a request: cannot fork to check it: $!", 'warn');
		return 0;
	}

	if (!$pid) {
		local $SIG{ALRM} = 'DEFAULT';
		local $SIG{SEGV} = 'DEFAULT';
		alarm $THAW_TRIAL_TIMEOUT;

		# A hostile request must not be able to fill the disk with core
		# files, each as large as the backend.
		if (open(my $filter, '>', '/proc/self/coredump_filter')) {
			print {$filter} '0';
			close($filter);
		}
		chdir('/');

		# Held until the exit, so that no DESTROY runs in this copy.
		my $held = eval { Storable::thaw($body) };
		POSIX::_exit(0);
	}

	1 while waitpid($pid, 0) == -1 && $!{EINTR};

	return $? == 0 ? 1 : 0;
}

# The connection owns its objects: when it goes, they go, and the target's
# DESTROY runs here rather than being lost with a dead client.
sub _drop_client {
	my ($self, $client, $reason) = @_;

	return 1 if $client->{closed};

	$self->_log('dropped a client: ' . (defined $reason && length $reason ? $reason : 'no reason given'), 'warn');

	# Whatever was waiting to be written goes with the connection: there is
	# nobody left to read it.
	$self->{queued} -= length $client->{outbuf};
	$self->{queued} = 0 if $self->{queued} < 0;

	$client->{closed} = 1;
	$client->{outbuf} = '';
	$client->{stalled_since} = undef;
	undef $client->{buffer};
	$client->{buffer} = '';
	delete @{$client}{qw(partial_started partial_progress)};

	my $owned = $client->{objects} || {};
	for my $id (keys %{$owned}) {
		delete $self->{objects}{$id};
	}
	%{$owned} = ();

	my $fd = fileno($client->{fh});
	$self->_close($client->{fh}, 'a client connection');
	delete $self->{clients}{$fd} if defined $fd;

	return 1;
}

sub _send {
	my ($self, $client, $message) = @_;

	return if $client->{closed};

	my ($bytes, $encode_error) = Class::Shared::Protocol::encode_frame($message, $self->{token});

	if (!defined $bytes) {
		my $error = $encode_error;
		($bytes) = Class::Shared::Protocol::encode_frame(
			_failure('protocol', $error),
			$self->{token},
		);

		# Neither the reply nor the frame saying it could not be sent can be
		# encoded, so this client will never hear anything: say so here.
		if (!defined $bytes) {
			$self->_log("cannot encode a reply: " . ($encode_error || 'unknown error'), 'error');
			return;
		}
	}

	# Measure the queues before any of this reply goes out, so the limits are on
	# what the backend is holding and not on how much of it the kernel happened
	# to take.
	my $length = length $bytes;
	my $queued = length($client->{outbuf}) + $length;

	if ($queued > $self->{max_queued}) {
		$self->_drop_client($client, "a reply of $length bytes leaves $queued "
			. "waiting to be written, more than the $self->{max_queued} a client may hold");
		return;
	}

	# One client's bound is not the process's: a few hundred clients that each
	# stay under max_queued would still add up to more memory than there is.
	if ($self->{queued} + $length > $self->{max_queued_total}) {
		$self->_drop_client($client, "a reply of $length bytes would leave "
			. ($self->{queued} + $length) . ' queued across all clients, more than '
			. "the $self->{max_queued_total} the backend may hold");
		return;
	}

	# The stall clock belongs to the queue, and it starts with it: this is the
	# only place a queue begins.  _flush restarts it on every write that takes
	# bytes out and clears it when the queue empties; nothing else sets it, so a
	# waiting reply can only get older, never fresher.  A reply added to a queue
	# that is already waiting does not get a new deadline.
	$client->{stalled_since} = Time::HiRes::time()
		unless length $client->{outbuf};

	$client->{outbuf} .= $bytes;
	$self->{queued} += $length;

	$self->_flush($client);

	return;
}

# Write as much of a client's queue as the socket will take right now.  What is
# left waits for the loop, which asks for writability again rather than
# sitting here until the client reads.
sub _flush {
	my ($self, $client) = @_;

	return if $client->{closed} || !length $client->{outbuf};

	# errno outlives a call, and a TLS write can fail without touching it.
	$! = 0;

	my $written = syswrite($client->{fh}, $client->{outbuf});

	if (!defined $written) {
		if ($self->_would_block($client->{fh}, 'write')) {
			# Nothing went out, so the deadline does not move: a socket that keeps
			# taking nothing stays on the clock of its last progress instead of
			# being handed a fresh one every time the loop tries it again.
			return;
		}

		$self->_drop_client($client, 'write error: ' . ($! || 'unknown error'));
		return;
	}

	# A socket that takes nothing and reports no error would keep the fd in the
	# writable set for ever, spinning the loop on a queue that never shrinks.
	if ($written == 0) {
		$self->_drop_client($client, 'write error: peer closed the connection');
		return;
	}

	substr($client->{outbuf}, 0, $written, '');
	$self->{queued} -= $written;

	# Progress, so the clock starts again -- or stops, if there is nothing left
	# to wait for.  _send started it when it made the queue; _expire_writes only
	# reads it; those two lines and this one are the whole of the rule.
	$client->{stalled_since} = length $client->{outbuf} ? Time::HiRes::time() : undef;

	# As for requests: an emptied queue should not keep a large reply's memory.
	if (!length $client->{outbuf}) {
		undef $client->{outbuf};
		$client->{outbuf} = '';
	}

	# Anything still queued puts the fd back in the loop's writable set.
	return;
}

# ------------------------------------------------------------- request ops

# Purpose:       build the reply that says a request failed, so every refusal
#                has the same shape and a client can rely on ok, kind and error.
# Entry:         $kind is the machine-readable category (protocol, busy, die,
#                forbidden, ...); $error is the text for a person.
# Exit status:   a hash reference { ok => 0, kind => $kind, error => $error }.
# Side effects:  none.
sub _failure {
	my ($kind, $error) = @_;

	return { ok => 0, kind => $kind, error => $error };
}

sub _dispatch {
	my ($self, $client, $message) = @_;

	if (ref($message) ne 'HASH') {
		return _failure('protocol', 'request is not a hash reference');
	}

	my $op = defined $message->{op} ? $message->{op} : '';

	if ($op eq 'hello') {
		return $self->_op_hello($client, $message);
	}

	if (!$client->{greeted}) {
		return _failure('protocol', 'handshake required');
	}

	return $self->_op_new($client, $message) if $op eq 'new';
	return $self->_op_call($client, $message) if $op eq 'call';
	return $self->_op_ping                  if $op eq 'ping';
	return $self->_op_shutdown              if $op eq 'shutdown';

	return _failure('protocol', "unknown operation '$op'");
}

sub _op_hello {
	my ($self, $client, $message) = @_;

	# One hello per connection.  A second would change the class of a
	# connection that may already hold objects, leaving them of a class the
	# connection no longer names.
	return _failure('protocol', 'hello has already been accepted on this connection')
		if $client->{greeted};

	# Compared as text, not as a number.  As a number, "2x" or " 2" would pass
	# as 2 (and "x" would warn), and a reference would be compared by its
	# address.  The version is written the one way, so only that way is
	# accepted.
	my $proto = defined $message->{proto} && !ref $message->{proto} ? $message->{proto} : 0;

	if ($proto ne $Class::Shared::PROTOCOL_VERSION) {
		return _failure('protocol',
			"protocol version mismatch: client speaks $proto, this backend speaks "
			. $Class::Shared::PROTOCOL_VERSION);
	}

	# A client may name the class it wants here, and then this connection is
	# for objects of that class.  A client that names none is welcome too: that
	# is how the admin commands ask a backend how it is without asking for
	# anything to be loaded.
	my $wanted = $message->{class};

	if (defined $wanted && length $wanted) {
		my $valid = eval { Class::Shared::validate_class($wanted); 1 };
		if (!$valid) {
			my $error = $@ || 'bad class name';
			$error =~ s/\s+\z//;
			return _failure('protocol', $error);
		}

		my ($loaded, $load_error) = $self->_load_class($wanted);
		return _failure('unknown_class', $load_error)
			unless $loaded;

		$client->{class} = $wanted;
	}

	$client->{greeted} = 1;

	return {
		ok      => 1,
		class   => $client->{class},
		pid     => $$,
		proto   => $Class::Shared::PROTOCOL_VERSION,
		version => $Class::Shared::VERSION,
	};
}

sub _op_new {
	my ($self, $client, $message) = @_;

	my $class = $client->{class};
	return _failure('protocol', $NO_CLASS_ERROR) unless defined $class;

	my $args = $message->{args};
	$args = [] unless defined $args;

	return _failure('protocol', 'new: args must be an array reference')
		unless ref($args) eq 'ARRAY';

	my $held = keys %{$self->{objects}};
	if ($held >= $self->{max_objects}) {
		return _failure('busy', "this backend already holds $held objects, its limit");
	}

	my $object;
	my ($built, $error, $timed_out) = $self->_limited(sub { $object = $class->new(@{$args}) });
	return $self->_timed_out("$class->new") if $timed_out;
	return _failure('die', $error) unless $built;

	return _failure('protocol', "$class->new did not return an object") unless ref($object);

	my $id = $self->{next_id}++;

	$self->{objects}{$id} = {
		object => $object,
		owner  => $client->{serial},
	};
	$client->{objects}{$id} = 1;
	$self->{constructed}++;

	return { ok => 1, id => $id, class => $class };
}

sub _op_call {
	my ($self, $client, $message) = @_;

	my $class = $client->{class};
	return _failure('protocol', $NO_CLASS_ERROR) unless defined $class;

	my $id = $message->{id};
	return _failure('protocol', 'call: no object id')
		unless defined $id && $id =~ /\A\d+\z/a;	# /a: ASCII digits only, as object ids are

	my $entry = $self->{objects}{$id};
	return _failure('unknown_object',
		"no object #$id here; it may have been released or its client has gone")
		unless $entry;

	return _failure('forbidden', "object #$id belongs to another connection")
		unless $entry->{owner} == $client->{serial};

	my $object = $entry->{object};

	my $method = $message->{method};
	return _failure('protocol', 'call: no method name')
		unless defined $method && length $method;

	my $args = $message->{args};
	$args = [] unless defined $args;
	return _failure('protocol', 'call: args must be an array reference')
		unless ref($args) eq 'ARRAY';

	my $want = $message->{want};
	$want = 'scalar' unless defined $want;
	return _failure('protocol', "call: unknown calling context '$want'")
		unless $want =~ /\A(?:list|scalar|void)\z/;

	# A method is a plain name.  A qualified one ("Other::Package::function")
	# would be looked up in that package, so a client could call any function
	# of any loaded module with the object as its first argument, and that
	# includes ones that write files.  can and isa are plain names too.
	return _failure('forbidden', "call: '$method' is not a plain method name")
		unless $method =~ /\A[A-Za-z_][A-Za-z0-9_]*\z/;

	if ($method eq 'new' or $method eq 'DESTROY' or $method eq 'AUTOLOAD') {
		return _failure('forbidden', "cannot call $method() through Class::Shared");
	}

	# can() and isa() are answered locally as booleans: the code reference
	# that can() normally returns cannot cross the wire.
	if ($method eq 'can' or $method eq 'isa') {
		my $name = $args->[0];

		# No name is not a class or method the object has; passing undef on
		# would only make perl warn about it.
		return { ok => 1, result => [0] } unless defined $name;

		my $answer = eval { $object->$method($name) ? 1 : 0 };
		return _failure('die', "$@") if $@;
		return { ok => 1, result => [$answer] };
	}

	# Asked of the object: a factory's new() may return another class.
	my $target = Scalar::Util::blessed($object) ? $object : $class;
	if (!$target->can($method) && !$target->can('AUTOLOAD')) {
		return _failure('unknown_method', "$class has no method '$method'");
	}

	my @result;
	my ($ok, $call_error, $call_timed_out) = $self->_limited(sub {
		if ($want eq 'list') {
			@result = $object->$method(@{$args});
		} elsif ($want eq 'void') {
			$object->$method(@{$args});
			@result = ();
		} else {
			my $scalar = $object->$method(@{$args});
			@result = ($scalar);
		}
	});

	return $self->_timed_out($method) if $call_timed_out;
	return _failure('die', $call_error) unless $ok;

	$self->{calls}++;

	return { ok => 1, result => [@result] };
}

# Purpose:       run one call to a target, stopping it if it takes too long.
# Entry:         $code is a code reference; call_timeout is a number of
#                seconds, 0 for no limit.
# Exit status:   ($ok, $error, $timed_out): $ok is true if $code returned;
#                $error is what it died with; $timed_out is true if the limit
#                ended it.
# Side effects:  uses SIGALRM and the process's one alarm timer for the
#                length of the call, and leaves it off afterwards.
# Why:           the backend serves one request at a time, so a call that does
#                not return holds every client.  Perl handles a signal between
#                two operations, so a call that is inside one long operation
#                (a system call, a regular expression, an XS function) is
#                stopped when that operation ends, not before.
sub _limited {
	my ($self, $code) = @_;

	my $limit = $self->{call_timeout};
	my $timed_out = 0;
	my ($ok, $error);

	{
		local $@;
		local $SIG{ALRM} = sub { $timed_out = 1; die "call timed out\n" };

		Time::HiRes::alarm($limit) if $limit;

		# The timer is switched off inside the eval as well, so that it cannot
		# fire in the gap between the call returning and the line after it.
		$ok = eval { $code->(); Time::HiRes::alarm(0) if $limit; 1 };
		$error = "$@";

		Time::HiRes::alarm(0) if $limit;
	}

	# A target that caught the timeout and carried on has still overrun it.
	$ok = 0 if $timed_out;

	return ($ok ? 1 : 0, $error, $timed_out);
}

# Purpose:       the reply, and the log line, for a call that was stopped.
# Entry:         $what names the call (a method, or CLASS->new).
# Exit status:   a failure reply of kind 'timeout'.
# Side effects:  logs one line.
sub _timed_out {
	my ($self, $what) = @_;

	my $message = "$what took longer than call_timeout ($self->{call_timeout} seconds) and was stopped";
	$self->_log($message);

	return _failure('timeout', $message);
}

sub _op_ping {
	my $self = shift;

	return {
		ok          => 1,
		classes     => [sort keys %{$self->{classes}}],
		queued      => $self->{queued},
		max_queued_total => $self->{max_queued_total},
		pid         => $$,
		proto       => $Class::Shared::PROTOCOL_VERSION,
		version     => $Class::Shared::VERSION,
		address     => $self->{address},
		calls       => $self->{calls},
		objects     => scalar(keys %{$self->{objects}}),
		constructed => $self->{constructed},
		clients     => scalar(keys %{$self->{clients}}),
		started     => $self->{started},
		uptime      => time - $self->{started},
	};
}

sub _op_shutdown {
	my $self = shift;

	$self->_log('shutdown requested');
	$self->{stop} = 1;

	return { ok => 1, message => 'shutting down' };
}

# ---------------------------------------------------------------- plumbing

sub _cleanup {
	my $self = shift;

	return if $self->{cleaned};
	$self->{cleaned} = 1;

	if ($self->{listener}) {
		$self->_close($self->{listener}, 'the listener');
		$self->{listener} = undef;
	}

	$self->_unlink($self->{socket}) if $self->{owns_socket};

	for my $client (values %{$self->{clients}}) {
		# A reply that was queued when the backend stopped, such as the one
		# that asked it to stop, gets one last chance to go out.
		$self->_flush($client) unless $client->{closed};
		$self->_close($client->{fh}, 'a client connection') unless $client->{closed};
	}

	# Every object the backend still holds is destroyed here, once, in the
	# process that created them.
	%{$self->{objects}} = ();
	%{$self->{clients}} = ();

	# Without the lock the pid file belongs to some other backend.
	if ($self->{lock}) {
		$self->_unlink($self->{control} . '.pid');
		flock($self->{lock}, LOCK_UN)
			or $self->_log("cannot release the lock: $!", 'error');
		$self->_close($self->{lock}, 'the lock file');
		$self->{lock} = undef;
	}

	return 1;
}

sub _daemonize {
	my $self = shift;

	my $pid = fork;
	die "cannot fork: $!\n" unless defined $pid;

	if ($pid) {
		# The intermediate child's status is not ours to report: the real
		# backend reports through the log.  waitpid only stops it being left
		# as a zombie, and fails harmlessly if SIGCHLD is ignored.
		waitpid($pid, 0);
		exit 0;
	}

	require POSIX;
	POSIX::setsid()
		or die "cannot start a new session: $!\n";

	my $second = fork;
	POSIX::_exit(0) if !defined $second || $second > 0;

	umask 077;

	my ($detached, $detach_error) = Class::Shared::detach_standard_streams($self->{log});
	die "$detach_error\n" unless $detached;

	# The logger names this process in every line, and this is a new one.
	$self->{logger} = undef;

	return 1;
}

# Purpose:       close a handle and log it if the close fails, so that a failure
#                is seen once, in the log, instead of being lost.
# Entry:         $fh is an open handle; $what names it in the message.
# Exit status:   1 on success, 0 on failure.
# Side effects:  closes $fh; may write to the log.
sub _close {
	my ($self, $fh, $what) = @_;

	return 1 if close($fh);

	$self->_log("cannot close $what: " . ($! || 'unknown error'), 'error');

	return 0;
}

# Purpose:       remove a file this backend made.  A file that is already gone
#                is what was wanted, so only a real failure is logged.
# Entry:         $path names the file.
# Exit status:   1 if the file is gone afterwards, 0 if it could not be removed.
# Side effects:  unlinks $path; may write to the log.
sub _unlink {
	my ($self, $path) = @_;

	return 1 if unlink($path) || $!{ENOENT};

	$self->_log("cannot remove $path: $!", 'error');

	return 0;
}

# Purpose:       write one line to the backend's log, through Log::Abstraction.
# Entry:         $message is the text; $level is a Log::Abstraction level name
#                ('info' if left out; 'warn' and 'error' for trouble).
# Exit status:   1 if the line was handed to the logger, 0 if there is no logger
#                (the log could not be set up).
# Side effects:  makes the logger on first use, and again in a new process;
#                appends to the log file.  A failure to log is not reported
#                anywhere, because the log is where reports go.
sub _log {
	my ($self, $message, $level) = @_;

	$level = 'info' unless defined $level;

	$self->_trim_log;

	# Some of what is logged is text a client chose (the reason a call died, a
	# name it asked for).  An escape character in it would act on the terminal
	# of whoever reads the log, so each run of control characters becomes one
	# space.  A new line and a tab are kept: the logger indents the line after
	# a new line, so it cannot pass for an entry of its own.
	$message =~ s/[\x00-\x08\x0B-\x1F\x7F]+/ /g if defined $message;

	# One logger per process.  The line starts with the pid so that the
	# processes that share a log (the one that spawned the backend, and the
	# backend) can be told apart, and the pid is part of the format, so a
	# logger inherited across fork() would name the wrong process.
	if (!defined $self->{logger} || $self->{logger_pid} != $$) {
		# Premise 1: new() always sets log, to the default if it was not given,
		# so there is nothing to fall back on here.  Premise 2: Log::Abstraction
		# takes a logger that is false in Perl to mean "no logger", and "0" is a
		# valid file name that is false.  Premise 3: an absolute path is never
		# false.  Conclusion: the path is made absolute, which names the same
		# file as before (a relative path was always opened from the directory
		# in force at the time) and cannot be mistaken for "no logger".
		my $path = File::Spec->rel2abs($self->{log});

		$self->{logger} = eval {
			Log::Abstraction->new(
				logger => $path,
				level  => 'info',
				format => "[$$] %timestamp% %message%",
			);
		};
		$self->{logger_pid} = $$;
	}

	return 0 unless defined $self->{logger};

	# Log::Abstraction keeps a message to one entry by putting a tab after
	# each line break, so nothing in a message can pass for a new log line.
	return eval { $self->{logger}->$level($message); 1 } ? 1 : 0;
}

1;

__END__

=encoding utf8

=head1 NAME

Class::Shared::Backend - load a class once and serve objects made from it

=head1 SYNOPSIS

Each example is a different real-world pattern.  Most people never write this
code: a frontend starts a backend for you, and C<class-shared start> starts one
from the shell.

    use Class::Shared::Backend;

    # 1. In the foreground, on the default unix socket.  run() does not return
    #    until the backend is told to stop (Ctrl-C, SIGTERM or "class-shared stop").
    Class::Shared::Backend->new()->run;

    # 2. An explicit unix socket path (at most 100 characters).
    Class::Shared::Backend->new(
        socket => '/run/user/1000/class-shared/class-shared.sock',
    )->run;

    # 3. In the background.  The process that calls run() EXITS (status 0) once
    #    the background copy has been started, so run() never returns there.
    Class::Shared::Backend->new(daemonize => 1, log => '/tmp/cs.log')->run;

    # 4. Serve other machines, over TLS with client certificates and a token.
    my $secret = 'the secret its clients were given too';
    Class::Shared::Backend->new(
        host     => '0.0.0.0',
        port     => 7000,
        tls_cert => '/etc/class-shared/server.pem',
        tls_key  => '/etc/class-shared/server-key.pem',
        tls_ca   => '/etc/class-shared/clients-ca.pem',
        token    => $secret,
    )->run;

    # 5. Limit what the backend will hold.
    Class::Shared::Backend->new(
        max_clients => 20,
        max_objects => 200,
    )->run;

    # 6. Take site settings from a file or the environment, with no change to
    #    the program.  See "CONFIGURATION".
    #      export Class__Shared__Backend__max_clients=50
    Class::Shared::Backend->new(config_file => '/etc/class-shared/backend.yml')->run;

=head1 DESCRIPTION

A client names the class it wants in its first message, the handshake, and the
backend loads that module then -- C<require> for the file, C<import> for its
exports -- once per class however many clients ask for it.  Each object lives
until the connection that asked for it goes away.

    one backend  --  Class::Simple (code, loaded when first asked for)
                 |--  Class::Other  (code, loaded when first asked for)
                 `--  object #1 (client A), object #2 (client B), ...

It answers one request at a time in a select loop, because all the objects share
one interpreter.

There is no class option: which classes are loaded is decided by the clients,
not by the command line.

=head1 OPTIONS

Every option may also be given as a site default; see L</CONFIGURATION>.  An
option you pass with the value C<undef> counts as not given.  A name that is not
listed here makes C<new> die.

=over 4

=item socket

Unix socket path.  Defaults to L<Class::Shared/socket_path>.  Use this or
C<host>/C<port>, not both.  It must be at most 100 characters; a longer path
makes C<new> die, because the operating system would otherwise cut it short
without saying so.

=item dir

The directory for the default socket, when C<socket> is not given.  Defaults to
L<Class::Shared/default_dir>.  The lock file, the pid file and the log are kept
next to the socket.

=item host, port

Listen on TCP instead of a unix socket, over TLS.  C<host> may be C<127.0.0.1>
for local use or an address of this machine to accept remote clients.  A TCP
listener needs C<tls_cert>, C<tls_key>, C<tls_ca> and a C<token>; see
L</TLS>.

=item tls_cert, tls_key

The certificate and private key this listener presents to clients.  The
certificate has to name the address clients use, because they check the name as
well as the chain.

=item tls_ca

PEM file of the CA, or CAs, that clients' certificates must chain to.  Client
certificates are mandatory: a client that presents none, or one signed by
another CA, is dropped during the handshake.

=item token

The shared secret for a TCP listener, which refuses to start without one and
refuses to accept a frame it cannot authenticate.  It is kept even though the
connection is already TLS: the token checks each frame, the certificate checks
the connection, and neither replaces the other.  A unix socket takes no token:
its mode 0600 file already decides who may connect, so its frames carry no
digest at all.  See L</SECURITY>.

=item log

Log file.  Defaults to the control path with C<.log> appended, when you give
none.  Every client the backend drops is written there with the reason it was
dropped.  A relative name is taken from the directory the backend is in when it
first writes.  See L</LOG>.

=item daemonize

Fork into the background, detach from the terminal and send output to the log.
Off by default, so a failure to load the class or bind the socket is reported
by C<die> to whoever started it.

=item max_clients

How many connections to accept before refusing more, including connections
still handshaking.  Default 128.  A unix client over the limit is sent a signed
C<busy> reply; a TCP client has no TLS session yet to sign one for, so it is
closed and its frontend reports a failed connection.

=item max_objects

How many objects to hold before refusing to construct more.  Default 4096.

=item max_queued

How many bytes may be waiting to be written to one client before it is dropped.
Default one maximum-size frame (64 MiB) plus a little, so no reply the protocol
allows is refused for being large.  Lower it to cap what a client that asks and
does not read can hold; a reply larger than the setting is then dropped rather
than queued.  The bound is per client, so all of them together may hold
C<max_clients> times this, which is more than any machine has; C<max_queued_total>
is what stops that from being reachable.  A queued reply is also dropped if the
socket takes none of it for C<write_timeout> seconds, so this bounds what one
client may have waiting, not how long it may wait.

=item max_queued_total

How many bytes may be waiting to be written to all clients together before the
reply that would pass it is refused.  Default four times C<max_queued>: enough
that a few clients may each be holding a maximum-size reply, small enough that
a few hundred cannot each be holding one.  A reply that would pass it is not
queued and its client is dropped, with a log line giving the total, and its
objects go with it; the alternative is a backend whose memory depends on how
many clients decide to stop reading at once.

=item write_timeout

Seconds a queued reply may go without the socket taking any of it before the
connection is dropped.  Default 30.  C<max_queued> bounds how much one client
may have waiting; without this, a client that has stopped reading could leave a
reply there for ever within that allowance.  Progress is what counts, so a slow
client that keeps taking bytes is not dropped, however long the whole reply
takes; one that takes nothing at all loses its connection, its queued reply and
its objects.

=item max_buffered_total

The most bytes of half-received requests the backend holds, over all clients.
Default four times the largest frame (about 256 MiB).  A request that has only
partly arrived is kept until the rest does; when these add up to more than this,
the connection whose request has been arriving the longest is dropped, and its
objects with it, until they fit.  Set it no lower than the largest request you
expect.

=item read_timeout

Seconds a half-received request may go without another byte arriving before the
connection is dropped.  Default 30.  A client that is idle between requests is
not affected, however long it waits.

=item start_timeout

Seconds to wait for another backend that is shutting down to release its lock.
Default 2.

=item handshake_timeout

Seconds a TCP connection may spend on its TLS handshake before it is dropped
and its slot freed, and then seconds any new connection may take to send a
hello that is accepted.  Default 5.  So a connection that says nothing cannot
hold one of the C<max_clients> places.

=item idle_timeout

Seconds a client that has said hello may send nothing before it is dropped, and
its objects with it.  Default 0, which means for ever, because a program that
uses its object rarely is normal.  Set it if programs you do not trust to leave
can connect: without it they can occupy all C<max_clients> places.

=item max_log_size

When the log grows past this many bytes it is copied to F<LOG.1>, replacing any
earlier one, and emptied.  Default 10485760 (10 MiB); 0 means never.  A log that
is a symbolic link or not a plain file is left alone.  The size is looked at
when the backend logs a line or has served a request.

=item call_timeout

Seconds one call to a target (a method, or the target's C<new>) may run before
the backend stops it and answers with the C<timeout> kind.  Default 60.  0 means
no limit.  The backend serves one request at a time, so a call that never
returns would hold every client; this bound is what ends it.  The call is
stopped with an exception raised at the next point where Perl can run it, which
is between two operations: a call that is inside one long operation (a system
call, a long regular expression, an XS function) is stopped when that operation
ends.  The target's object is not repaired or removed: it may have been left half
changed, and a later call on it sees it so.  A target that sets its own
C<alarm> or C<$SIG{ALRM}>, or that catches the exception and carries on, defeats
the limit; the call is still reported as timed out when it returns.

=item config_file

The path of a configuration file to read site settings from.  It is not an
option of the backend itself and is not kept.  See L</CONFIGURATION>.

=item config_dirs

An array reference of directories to search for the configuration file when
C<config_file> is a bare file name.  Not kept either.

=back

=head1 METHODS

The schemas in each B<API SPECIFICATION> follow the conventions of
L<Params::Validate::Strict> (for input) and L<Return::Set> (for output).  They
describe the method for people and for tools.  The code does not call those
modules, and this distribution does not depend on them.

=head2 new

    my $backend = Class::Shared::Backend->new(%options);

Checks the options and returns a backend that is ready to run.  It does not
open a socket, take a lock or start anything: that happens in L</run>.  Every
option is described in L</OPTIONS>.  You may pass the options as a list of pairs
or as one hash reference.

The options come from three places.  What you pass always wins.  What you do not
pass is taken from the environment, and then from a configuration file, as
L</CONFIGURATION> describes.  Whatever the source, each value is checked the same
way.

Choose one transport.  With neither C<host> nor C<port> you get a unix socket
(C<socket>, or the default path).  With C<host> and C<port> you get TCP over
TLS, which also needs C<tls_cert>, C<tls_key>, C<tls_ca> and C<token>.  A unix
socket refuses a token and TLS files, because its permissions already decide
who may connect.

B<Side effects:> reads the environment and, if there is one, a configuration
file.  It builds the object and nothing else.

B<Dies> if an option name is not known or a value has the wrong type or is out
of range (for example a C<port> that is not a whole number from 1 to 65535).
The message says whether the bad value was an argument or a configured value,
and names the option.  It also dies if the options are inconsistent: only one of C<host> and C<port>;
C<socket> together with C<host>/C<port>; a TCP listener without a token or
without all three TLS files; a unix socket with a token or TLS files; or an
over-long socket path.  (A perl without unix sockets is reported by C<run>, or
by C<new> when it has to work out the default socket path.)

=head3 DECISION TABLE

The rules are checked in this order, and the first one that applies is the one
you read.  A value that is empty counts as not set, so C<token =E<gt> ''> is
no token, and an empty TLS file name is a missing one.

    host or port given?   rule                                     refused with
    -------------------   --------------------------------------   ----------------------------
    one of them only      a TCP listener needs both                needs both host and port
    both, and a socket    use host/port or a socket, not both      either socket or host/port
    both, no token        a TCP listener needs a token             needs a token
    both, TLS files < 3   a TCP listener needs all three           needs tls_cert, tls_key ...
    both, all of it       accepted as a TCP listener
    neither, path too     the socket must fit in an address        more than the N allowed
      long
    neither, a token      a unix socket needs no token             a unix socket needs no token
    neither, a TLS file   a unix socket needs no TLS               a unix socket needs no TLS
    neither               accepted as a unix listener

Three plain-English steps show why the table is complete.  A listener is TCP if
it has a host or a port, and unix if it has neither, so every input is in exactly
one half.  In the TCP half a token and all three TLS files are required and a
socket is not allowed, so each missing or extra thing has one rule that
refuses it.  In the unix half a token and every TLS file are forbidden, so
each extra thing has one rule that refuses it.

An option that you do not give gets its default.  An option that you do give
keeps its value even when that value is false, so C<write_timeout =E<gt> 0> is a
timeout of 0 and not the default, and C<log =E<gt> '0'> is a log file called
C<0>.  The defaults are read when you call C<new>, so a program may set a package
variable such as C<$Class::Shared::Backend::WRITE_TIMEOUT> before it does.

=head3 API SPECIFICATION

=head4 Input

    {
        socket            => { type => 'string',  optional => 1, min => 1, max => 100 },
        dir               => { type => 'string',  optional => 1, min => 1 },
        host              => { type => 'string',  optional => 1, min => 1 },
        port              => { type => 'integer', optional => 1, min => 1, max => 65535 },
        tls_cert          => { type => 'string',  optional => 1, min => 1 },
        tls_key           => { type => 'string',  optional => 1, min => 1 },
        tls_ca            => { type => 'string',  optional => 1, min => 1 },
        token             => { type => 'string',  optional => 1, matches => qr/\A[\x20-\x7E]*\z/ },
        log               => { type => 'string',  optional => 1, min => 1 },
        daemonize         => { type => 'boolean', optional => 1 },
        max_clients       => { type => 'integer', optional => 1, min => 1 },
        max_objects       => { type => 'integer', optional => 1, min => 1 },
        max_queued        => { type => 'integer', optional => 1, min => 1 },
        max_queued_total  => { type => 'integer', optional => 1, min => 1 },
        write_timeout     => { type => 'number',  optional => 1, min => 0 },
        handshake_timeout => { type => 'number',  optional => 1, min => 0 },
        start_timeout     => { type => 'number',  optional => 1, min => 0 },
        call_timeout      => { type => 'number',  optional => 1, min => 0 },
        read_timeout      => { type => 'number',  optional => 1, min => 0 },
        max_buffered_total => { type => 'integer', optional => 1, min => 1 },
        idle_timeout      => { type => 'number',  optional => 1, min => 0 },
        max_log_size      => { type => 'integer', optional => 1, min => 0 },
        config_file       => { type => 'string',   optional => 1, min => 1 },
        config_dirs       => { type => 'arrayref', optional => 1 },
    }

=head4 Output

    { type => 'object', isa => 'Class::Shared::Backend' }

=head2 run

    my $status = $backend->run;

Starts serving.  In order, it

=over 4

=item 1.

goes into the background, if C<daemonize> is true (see below);

=item 2.

makes sure the socket directory exists and is safe;

=item 3.

takes the lock that makes the backend a singleton (waiting up to
C<start_timeout> seconds for a backend that is shutting down);

=item 4.

opens the listening socket (removing a leftover one that nobody answers on) and
writes the pid file;

=item 5.

serves clients until it is told to stop; and

=item 6.

closes everything, destroys every object, removes the socket and pid file, and
releases the lock.

=back

It stops when it receives C<SIGTERM> or C<SIGINT>, or when a client sends the
C<shutdown> request (for example C<class-shared stop>).  C<SIGHUP> and
C<SIGPIPE> are ignored.

Returns 0 after a normal stop.  A backend object is one life: calling C<run>
again after it has stopped dies with C<this backend has already run and
stopped>.  Make a new object to serve again.

B<Background mode.> When C<daemonize> is true, C<run> forks twice.  The process
that called it B<exits with status 0> as soon as the first fork has finished, so
C<run> does not return there.  Only the background copy goes on.  The calling
process does not wait for the background copy to be ready, so the socket may not
exist yet when it exits.  If starting fails in the background copy, the reason is
written to the log and the copy exits with status 1.

B<Side effects:> creates the socket directory, a lock file (C<.owner>), a pid
file (C<.pid>) and a log file (C<.log>) next to the socket; opens the listening
socket; loads each class a client asks for; writes to the log.  The socket and
the pid file are removed at a normal stop.  The lock file and the log are left
in place.

B<Dies> (when not in the background) with the reason if it cannot start: another
backend is serving, the directory is unsafe, this perl has no unix sockets, the
socket cannot be bound, or TLS cannot be set up.  The same reason is written to
the log first.

=head3 API SPECIFICATION

=head4 Input

    { }

=head4 Output

    { type => 'integer', memberof => [0] }

=head2 DESTROY

Called by Perl when the backend object goes away.  It removes the socket file,
but only if this object created it.  A backend that failed to start because
another one was already serving never owned the socket, so it leaves the other
backend's socket alone.  You do not call it yourself.

=head1 LOG

The backend writes its log with L<Log::Abstraction>.  Each message is one line:

    [4242] 2026-11-25 10:44:55 serving on /run/user/1000/class-shared/class-shared.sock (pid 4242)

That is the process id of the process that wrote it, the local date and time, and
the message.  The pid is there because the process that starts a backend and the
backend itself can write to the same file.  A line is written as soon as the
event happens, so you can follow the log with C<tail -f>.

A message that has more than one line has a tab put at the start of each line
after the first, so that nothing in a message can look like the start of a new
entry.  Percent signs in a message are written as they are.

Normal events (starting, stopping, a shutdown request) are logged at C<info>.
Clients that are dropped or refused are logged at C<warn>.  Failures of the
backend itself (a file that cannot be removed, a reply that cannot be encoded,
an internal error) are logged at C<error>.  All three are always written: there
is no option to turn them down.

If the log cannot be opened or written (for example its directory does not
exist), the backend carries on without it.  The log is the place where failures
are reported, so there is nowhere else to report this one.

=head1 CONFIGURATION

A backend can take its options from outside the program, so that whoever runs
it can change them without editing code.  This is done with
L<Object::Configure>.  The same option can come from three places.  The first
one that has a value wins:

=over 4

=item 1.

what you passed to C<new>;

=item 2.

an environment variable named C<Class__Shared__Backend__OPTION>, for example
C<Class__Shared__Backend__max_clients=50>;

=item 3.

a configuration file, but only if the program that makes the backend names one
with C<config_file>.  Nothing is searched for.  See L</Where the settings can
come from>.

=back

This is the opposite of L<Object::Configure>'s own default, in which the program's
values have the lowest priority.  It is reversed here on purpose.  The backend
holds a secret (C<token>) and the names of the certificates it trusts, and a
stray variable in the environment must not be able to replace what the program
chose.  A value you do not pass is the place where a site default is welcome.

The file is named after the class, in lower case, with C<::> turned into C<->:
F<class-shared-backend.yml>.  JSON works too (F<class-shared-backend.json>); the
kind of file is taken from its name.  You give C<config_file> either as a full
path, or as a bare file name together with C<config_dirs>, a list of
directories to look in.  No directory is searched unless you ask: a file in
F<~/.conf>, for example, is B<not> read.  A C<config_file> that has a C<..>
in it is refused.  Inside, the settings sit under a key that has C<__> where
the class name has C<::>:

    ---
    Class__Shared__Backend:
        max_clients: 50
        max_objects: 1000
        log: /var/log/class-shared.log

Only the options listed in L</OPTIONS> are taken from the file or the
environment.  Other keys are ignored, because the same file may hold settings for
other classes.  Each value is checked as strictly as an argument would be, and a
bad one is reported as "a configured value is not valid".  The rules between
options still apply: a C<token> in the environment is refused for a unix socket,
just as one passed in code is.

A file called F<universal.yml> in the same directory is read as well, and its
C<UNIVERSAL:> section applies to this backend and to every other class that uses
L<Object::Configure>.  Keep the backend's file in a directory of its own so that
no such file is picked up by accident.

Treat these places as you would treat the program.  A token or a certificate
path set in a file or in the environment can be read by anybody who can read
that file or that process's environment.  Keep the file mode 0600 and prefer
C<--token-file> in L<class-shared> to putting a secret in a variable.

A backend that a frontend starts for you inherits the environment of that
frontend, so these variables apply to it too.

=head1 RUNNING AS A SERVICE

You do not have to do any of this.  The first frontend that cannot find a
backend starts one for you.  Run the backend as a service when you want it to be
running before the first request, to be started again if it stops, or to run
with settings that you choose in one place.

Examples marked (tested) were run, on systemd 257 with Perl 5.40.  Those marked
(not run) were written from the manual of that system and have not been run, so
try them before you rely on them.

=head2 Decide where it lives

A unix socket is mode 0600 in a directory that only its owner can write to.  This
has three results.

=over 4

=item *

Only the user who runs the backend can connect to it.  Sites that run as
different users cannot share one unix socket backend.  Run them as one user, run
one backend for each user, or use TCP with TLS (see L</TLS>).

=item *

Every client must look in the same directory as the backend.  The directory is
the first of these that is set: C<--dir> or C<dir>, the C<CLASS_SHARED_DIR>
environment variable, F<$XDG_RUNTIME_DIR/class-shared>, F</run/user/UID/class-shared>,
and last the system temporary directory.  The most common fault is a backend that
was started with C<--dir> while the clients use the default.  Run
C<class-shared path> in the same environment as a client to see where it will
look.

=item *

The backend makes these files next to the socket: the socket itself, a lock file
(C<.owner>), a pid file (C<.pid>) and the log (C<.log>).  If you use
C<RuntimeDirectory> with systemd, all of them are deleted when the service stops.
See L</Where the log goes>.

=back

=head2 Where the settings can come from

There are three places, and not all of them work with the C<class-shared>
command.

=over 4

=item Command line options

C<--dir>, C<--socket>, C<--log>, C<--listen>, the TLS options and
C<--token-file>.  Nothing else, so there is no option for C<max_clients>.

=item Environment variables

Any option, as C<Class__Shared__Backend__NAME>.  This works with the
C<class-shared> command (tested): with C<Class__Shared__Backend__max_clients=1>
set, a second client was refused.  A service manager can set them for you.

=item A configuration file

Any option, but only when the program that makes the backend passes
C<config_file>.  The C<class-shared> command has no option for that, and a
C<Class__Shared__Backend__config_file> variable is ignored (tested).  To use a
file you need a launcher, which is three lines of Perl.

=back

A value in the environment beats one in a file, and a value on the command line
or in code beats both.

=head2 A configuration file and a launcher (tested)

The file, F</etc/class-shared/class-shared-backend.yml>:

    ---
    Class__Shared__Backend:
        dir: /run/class-shared
        log: /var/log/class-shared/backend.log
        max_clients: 50
        max_objects: 1000

The launcher, F</usr/local/bin/class-shared-backend>:

    #!/usr/bin/perl
    use strict;
    use warnings;
    use Class::Shared::Backend;

    Class::Shared::Backend->new(
        config_file => '/etc/class-shared/class-shared-backend.yml',
    )->run;

Run it from a service manager like any other program.  With this file it used
the directory and log the file named, enforced C<max_clients>, and stopped
cleanly on C<SIGTERM> (tested).  The file is read once, when the backend starts,
so a change needs a restart.  Do not set C<daemonize> in a file that a service
manager runs: the manager would lose track of the process.

=head2 systemd, for one user (tested)

This is the usual choice for a web site that runs as an ordinary user.  Save it
as F<~/.config/systemd/user/class-shared.service>:

    [Unit]
    Description=Class::Shared backend

    [Service]
    Type=simple
    StateDirectory=class-shared
    EnvironmentFile=-%h/.config/class-shared/backend.env
    ExecStart=/usr/local/bin/class-shared start --foreground --log %S/class-shared/backend.log
    Restart=on-failure
    RestartSec=2

    [Install]
    WantedBy=default.target

Then:

    systemctl --user daemon-reload
    systemctl --user enable --now class-shared
    systemctl --user status class-shared
    class-shared status

To start it at boot and not when you log in, run C<loginctl enable-linger
$USER> once.

The settings go in F<~/.config/class-shared/backend.env>, one C<NAME=value> a
line.  The C<-> after C<EnvironmentFile=> means that the file may be missing:

    Class__Shared__Backend__max_clients=50
    Class__Shared__Backend__max_objects=1000
    TZ=UTC

C<--foreground> keeps the backend in the process that systemd started.  Without
it the command goes into the background and systemd thinks the service has
ended.  The socket is in the default directory, F</run/user/UID/class-shared>,
because systemd sets C<XDG_RUNTIME_DIR> for a user service, so clients need no
setting.

What was checked: the service starts and reports C<active>; the environment file
is applied; after C<kill -9> the service came back after the delay set by C<RestartSec>
and a client could reach it, because a backend removes a socket that nobody
answers on; and C<systemctl --user stop> ends it cleanly and removes the socket.  Stop
needs no C<ExecStop>: the backend stops on C<SIGTERM>.

Two things to know.  First, systemd does not read your shell's startup files.  Its
C<PATH> is short, and C<PERL5LIB> and perlbrew are not set.  Give C<ExecStart> the
full path of the script.  If you use perlbrew or a local library, name the C<perl>
that installed it as well, as in C<ExecStart=/home/you/perl5/perlbrew/perls/perl-5.40.0/bin/perl
/home/you/perl5/perlbrew/perls/perl-5.40.0/bin/class-shared start --foreground>,
or add C<Environment=PERL5LIB=/home/you/perl5/lib/perl5> for your classes.  Second, C<Restart=on-failure> does not
restart a backend that C<class-shared stop> ended, because that is a normal exit.
Use C<Restart=always> if you want it back even then.

=head2 systemd, a system service (not run)

Use this when the backend should start with the machine, for the user that the web
server runs as.  Save it as F</etc/systemd/system/class-shared.service>:

    [Unit]
    Description=Class::Shared backend
    After=network.target

    [Service]
    Type=simple
    User=www-data
    Group=www-data
    RuntimeDirectory=class-shared
    RuntimeDirectoryMode=0700
    LogsDirectory=class-shared
    EnvironmentFile=-/etc/class-shared/backend.env
    Environment=CLASS_SHARED_DIR=/run/class-shared
    ExecStart=/usr/local/bin/class-shared start --foreground --dir /run/class-shared --log /var/log/class-shared/backend.log
    Restart=on-failure
    RestartSec=2

    [Install]
    WantedBy=multi-user.target

Then C<systemctl daemon-reload> and C<systemctl enable --now class-shared>.
C<RuntimeDirectoryMode=0700> matters: the backend refuses a directory that other
users can write to.  The clients must run as the same user and must be told the
directory, with C<CLASS_SHARED_DIR=/run/class-shared> in their environment or
C<dir =E<gt> '/run/class-shared'> in their code.

To use a configuration file, replace C<ExecStart> with the launcher from the
section above.

=head2 macOS, launchd (not run)

Save this as F<~/Library/LaunchAgents/org.cpan.class-shared.plist>.  macOS has no
C<XDG_RUNTIME_DIR>, and the temporary directory that a launchd job sees may not
be the one that your shell sees, so give the directory explicitly here B<and> to
every client:

    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
      "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
      <key>Label</key><string>org.cpan.class-shared</string>
      <key>ProgramArguments</key>
      <array>
        <string>/usr/local/bin/class-shared</string>
        <string>start</string>
        <string>--foreground</string>
      </array>
      <key>EnvironmentVariables</key>
      <dict>
        <key>CLASS_SHARED_DIR</key><string>/Users/you/Library/Caches/class-shared</string>
      </dict>
      <key>RunAtLoad</key><true/>
      <key>KeepAlive</key>
      <dict><key>SuccessfulExit</key><false/></dict>
    </dict>
    </plist>

Load it with C<launchctl load ~/Library/LaunchAgents/org.cpan.class-shared.plist>.
C<SuccessfulExit> false means "restart it only if it failed", like systemd's
C<on-failure>.  With a plain C<KeepAlive> set to true, launchd would start the
backend again after C<class-shared stop>.

=head2 FreeBSD, rc.d (not run)

Save this as F</usr/local/etc/rc.d/class_shared> and make it executable.  It uses
the command's own background mode and its C<stop> command, so no
C<daemon(8)> is needed:

    #!/bin/sh
    # PROVIDE: class_shared
    # REQUIRE: LOGIN
    # KEYWORD: shutdown

    . /etc/rc.subr

    name="class_shared"
    rcvar="class_shared_enable"
    start_cmd="class_shared_start"
    stop_cmd="class_shared_stop"
    status_cmd="class_shared_status"

    : ${class_shared_user:="www"}
    : ${class_shared_dir:="/var/run/class-shared"}

    class_shared_start() {
        su -m "${class_shared_user}" -c \
            "/usr/local/bin/class-shared start --dir ${class_shared_dir}"
    }
    class_shared_stop() {
        su -m "${class_shared_user}" -c \
            "/usr/local/bin/class-shared stop --dir ${class_shared_dir}"
    }
    class_shared_status() {
        su -m "${class_shared_user}" -c \
            "/usr/local/bin/class-shared status --dir ${class_shared_dir}"
    }

    load_rc_config $name
    run_rc_command "$1"

Enable it with C<sysrc class_shared_enable=YES>.  Create the directory first, owned
by that user and mode 0700.  The command in the background mode returns before the
backend is ready (see L</run>), so a script that needs it at once
should run C<class-shared status> in a short loop.  OpenBSD's F<rc.d> works in the
same way, with C<rc_start> and C<rc_stop> running the same two commands.

=head2 runit and s6 (not run)

These want a program that stays in the foreground, which is what C<--foreground>
is.  A runit F<run> file:

    #!/bin/sh
    exec 2>&1
    exec chpst -u www /usr/local/bin/class-shared start --foreground \
        --dir /var/run/class-shared --log /var/log/class-shared/backend.log

For s6, use C<s6-setuidgid www> in place of C<chpst -u www>.

=head2 Containers (not run)

Run one backend in a container, in the foreground, and share the socket directory
with the containers that have the clients:

    docker run -d --name class-shared --user 33:33 \
        -v class-shared-run:/run/class-shared \
        myimage class-shared start --foreground --dir /run/class-shared

Every client container mounts the same volume at the same place and runs with the
same user id (33 here), because the socket is mode 0600.

=head2 Without a service manager

The command starts the backend in the background, and C<stop> ends it:

    class-shared start
    class-shared status
    class-shared stop

To start it when the machine does, put C<@reboot /usr/local/bin/class-shared
start> in your crontab.  Nothing starts it again if it stops, which is the
difference from the examples above.

=head2 Windows

Not supported.  A backend needs unix sockets and owner-only directories (see
L</SECURITY>).

=head2 Where the log goes

The backend writes its log to a file (see L</LOG>), also in the foreground.  It
does not write it to the journal or to standard output, so C<journalctl> shows
only what the service manager says (tested).  Use C<--log> to put the file
somewhere that lasts.  The default, next to the socket, is wrong for a service
that has a C<RuntimeDirectory>: systemd deletes the directory when the service
stops, and the log with it (seen in testing).  C<StateDirectory> and
C<LogsDirectory> are kept (tested for C<StateDirectory>).

=head2 The backend has its own environment

A service does not get your shell's environment, and a backend started by a
frontend gets the frontend's.  Anything that a class reads from the environment
must be set for the backend.  The one that shows up first is C<TZ>: C<Date::Manip>
complains and refuses to work without a time zone, so a class that uses it needs
C<TZ=UTC> (or your zone) in the unit or the environment file.  A class that reads
the request's own variables, such as C<REMOTE_ADDR>, gets the backend's, not the
client's.  Pass those values as arguments instead.

Objects live in memory.  When the backend restarts, the objects that it held are
gone.

=head1 SINGLETON

Two guards keep it to one backend per directory:

=over 4

=item *

An exclusive C<flock> on a control file in the socket directory, held for the
life of the process.  A second backend there exits with an explanation,
whatever transport it was asked to use.

=item *

A unix socket in the way is probed: if something answers, the backend is already
running; if not, the socket is a leftover and is removed.  A TCP port that is in
use fails to bind.

=back

=head1 OBJECT LIFETIME

An object belongs to the connection that created it.  When that connection
closes -- because the frontend was destroyed, the client exited, or the client
process died -- the backend destroys the object.  A client cannot call, or even
see, another client's object: ids are checked against the connection that owns
them.

=head1 PROTOCOL

Every request and reply is a hash reference in a length-prefixed L<Storable>
frame; see L<Class::Shared::Protocol>.  Clients must start with C<hello>.

=over 4

=item hello

C<{ op =E<gt> 'hello', proto =E<gt> 2, class =E<gt> 'Class::Simple' }>.  C<proto>
must be the backend's own protocol version.  C<class> is optional: a client that
names none can still use C<ping> and C<shutdown>, which is how C<class-shared
status> works.  A name is checked (see L</ENCODING>) and the class is loaded, once
for the whole backend.  The reply carries the backend's pid and version.

=item new

C<{ op =E<gt> 'new', args =E<gt> [...] }>.  Constructs a new object with those
arguments and replies with its C<id>.  A constructor that dies is reported and
no object is created.

=item call

C<{ op =E<gt> 'call', id =E<gt> $id, method =E<gt> 'name', args =E<gt> [...],
want =E<gt> 'list' | 'scalar' | 'void' }>.  Replies with C<result =E<gt> [ ...
]>, or C<ok =E<gt> 0> with the text of the exception.  C<new>, C<DESTROY> and
C<AUTOLOAD> may not be called, and the id must belong to this connection.

=item ping

C<{ op =E<gt> 'ping' }>.  Counters and identity, for C<class-shared status>:
objects, calls, clients, classes, uptime, C<queued> (the bytes waiting to be
written to all clients together) and C<max_queued_total>, the ceiling those
bytes are held against, so the one number can be read as a fraction of the
other.

=item shutdown

C<{ op =E<gt> 'shutdown' }>.  Replies first, then destroys every object and
exits.

=back

A reply that says C<ok =E<gt> 0> also has a C<kind>, which tells a program what
went wrong, and an C<error>, which tells a person.  The kinds are:

=over 4

=item protocol

The request was malformed, came out of order, or spoke another protocol version.

=item unknown_class

The class could not be loaded.

=item busy

The backend is full: too many clients or too many objects.

=item die

The target's C<new> or method died; C<error> is its message.

=item unknown_object

No such object (it may have been released).

=item timeout

The call ran for longer than C<call_timeout> and was stopped; C<error> says which
call.  The object is still there.

=item unknown_method

The target class has no such method.

=item forbidden

The object belongs to another connection, or the method may not be called.

=item internal

The backend itself failed while handling the request.

=back

=head1 SECURITY

A unix socket is created mode 0600 in a directory only the owner can write to.
That is the whole of its authentication, so it takes neither a token nor TLS,
and its frames carry no digest.

The class is the client's choice.  The handshake loads whatever module is named,
so anybody who can connect can make the backend C<require> any module it can
find, running that module's load-time code.  That is the same power they would
have running perl themselves as the backend's user, which is what a unix
socket's owner-only permissions and a TCP listener's certificate and token are
there to confine: keep them to people you would let run code here.

A TCP listener is a TLS endpoint with client certificates: it needs
C<tls_cert>/C<tls_key> to prove which backend it is, and C<tls_ca> to decide
which clients are welcome.  Verification of the client is mandatory
(C<SSL_VERIFY_FAIL_IF_NO_PEER_CERT>), so a client that presents no certificate,
or one signed by another CA, is dropped inside C<accept> and never becomes a
connection with a buffer or an object.  The rejection is logged; there is
nobody to send an explanation to, because they have not been authenticated.

It also needs a C<token>.  With one, every frame carries an HMAC-SHA-256 of its
body, keyed with the token, and the digest is verified before L<Storable::thaw>
is given any of the frame.  That order is what makes the token a guard rather
than a comment: C<thaw> runs code of the sender's choosing, so a peer without
the secret is stopped before deserialisation, not after it.  A wrong or missing
digest ends that connection.  The refusal is signed like any other frame, so a
peer that does not hold the secret cannot read it either.

So the two checks answer different questions.  TLS says which machine is
calling and keeps what it sends private; the token says whether the frame in
front of us was built by somebody who knows the secret.  A stolen certificate is
not a stolen secret, and a leaked secret does not let anybody read the traffic.

A unix socket needs no token, and takes none: it is created mode 0600 in a
directory only the owner can write to, so the kernel has already decided who
may connect and its frames carry no digest.

=head1 TLS

TCP is TLS; there is no unencrypted TCP mode.  C<new> refuses a C<host>/C<port>
listener without C<tls_cert>, C<tls_key> and C<tls_ca>, the same way it refuses
one without a token, so a port cannot be opened in the clear by forgetting an
argument.

The certificate has to name the address clients connect to: a frontend given a
C<tls_ca> checks the name as well as the chain, so an address- or hostname-based
certificate for C<classhost.example.com> is the one to issue for a backend
reached at that name.  A frontend given a C<tls_fingerprint> instead pins this
exact certificate by digest, in which case the name and the signer (a private
CA, or none at all) do not have to satisfy anybody.

The commands that produce the four files, with the C<subjectAltName> the
certificate needs and a working frontend to match, are in
L<Class::Shared/TRANSPORT SECURITY>; F<t/certs/make-certs.sh> in the
distribution generates the same set, with a second CA and impostor
certificates, for the tests.

Frame reads are non-blocking too.  A connection that stops halfway through a
frame, or halfway through the TLS record carrying it, keeps what has arrived in
its own buffer; the loop goes on serving everyone else and resumes that
connection when the rest arrives.

Replies are queued per connection and written as the socket takes them, so a
client that asks for an answer and then stops reading holds its own reply, not
the loop.  What it may hold is bounded by C<max_queued>: once more than that is
waiting to be written to it, the client is dropped, since the alternative is
holding the backend's memory for as long as it chooses to stay connected.  For
the same reason a queued reply that makes no progress for C<write_timeout>
seconds is dropped too: the bound caps how much a client may hold, the timeout
caps how long it may hold it.  C<max_queued_total> caps what all of them
together may hold, so the memory a few hundred clients that all stop reading
can pin is a number, not the product of two other numbers.

The handshake is not done in C<accept>.  An accepted socket starts its TLS
layer without a handshake and then finishes it, a little at a time, from the
select loop as that socket becomes readable or writable.  A peer that connects
and then says nothing therefore costs one pending handshake for at most
C<handshake_timeout> seconds (five by default), after which it is dropped and
its slot freed, while every client already connected keeps being served in the
meantime.  Doing the handshake in C<accept> would let
anyone who can reach the port freeze the backend for the length of the timeout,
and the loop is single-threaded, so that would be every client.

Data nested many thousands of levels deep cannot be read by L<Storable> without
crashing the process.  The backend therefore first reads any request over 4096
bytes in a child process, and refuses the request, and drops its connection, if
the child dies.  This costs one C<fork> for each large request, and a class with
a C<STORABLE_thaw> hook sees that hook run in the child as well.

=head1 ENCODING

=over 4

=item Arguments, results and error text: full Unicode.

Everything a client sends or receives is a L<Storable> image, which keeps
strings exactly as they are.  Accented letters, any alphabet and emoji pass
through the backend unchanged.  The backend does not look inside them.

=item Class names: ASCII only.

A class name is checked in the handshake.  Only the letters A to Z, digits and
underscores, with C<::> between words, are accepted.

=item The token: ASCII only.

The digest is worked out by L<Digest::SHA> on bytes.  A character above code
point 255 stops it from working, and a character from 128 to 255 gives a
different answer as a Perl string than as the bytes of a file.  So C<new> accepts
only printable ASCII (space to C<~>) in a token and refuses anything else.

=item Paths: ASCII is safest.

C<socket>, C<dir>, C<log> and the C<tls_*> files go to the operating system as
they are.  The 100 character limit on a socket path counts characters.

=item The log: not one encoding.

The log has no encoding layer.  A message with only characters up to code point
255 is written as one byte per character (so C<caf\x{e9}> is the Latin-1 byte,
not UTF-8).  A message with a higher character, such as an emoji, is written as
UTF-8, and Perl prints a C<Wide character> warning.  Most log lines are the
backend's own English text; other text can only come from an error in your own
class (for example C<internal error while handling a request: ...>).  Read the
log as bytes, and expect that a line may be in either form.

=back

=head1 COMMON PITFALLS

=over 4

=item With C<daemonize>, C<run> does not return in your program.

The process that calls it exits with status 0 once the background copy is
started.  Put nothing after the call that you need to run.  Also, the process
exits before the background copy is ready, so the socket may not exist at that
moment.

=item Without C<daemonize>, C<run> does not return until the backend stops.

It runs the server loop for as long as the backend lives.

=item Which classes are loaded is decided by the clients.

There is no C<class> option.  The class must be findable in the C<@INC> that the
backend was started with, so start it with the right C<-I> or C<PERL5LIB>.

=item A misspelt option is an error.

C<new> dies on a name it does not know, as C<Class::Shared::Frontend> does.
This includes C<class>, which was never an option: the clients choose the class.

=item Environment variables and files can change what you did not pass.

If your program leaves C<max_clients> out, C<Class__Shared__Backend__max_clients>
in the environment sets it.  To be sure of a value, pass it.  A bad value in the
environment stops the backend from starting, and the message says it came from
configuration.

=item The configuration file is looked up once per process.

L<Object::Configure> remembers where it found the file for a class.  Changing
C<config_file> later in the same process may not be noticed.

=item Log::Abstraction is not told where to log by your configuration.

C<Object::Configure> would also accept a C<logger> setting, but the backend
ignores it and always logs to C<log>, so that the file the clients and the CLI
are told about is the file that is used.

=item Loading the configuration modules costs a little start-up time.

Roughly 0.1 seconds, which matters only if you start a backend very often.

=item The backend keeps the environment it was started with.

Its C<%ENV> and its current directory are those of whoever started it.  A client
cannot change them.

=item One request at a time.

A slow method makes every other client wait, whatever class they use.

=item A TCP listener needs four things.

C<tls_cert>, C<tls_key>, C<tls_ca> and a C<token>.  A unix socket accepts none of
them, on purpose.

=item Only one backend per directory.

A second backend in the same directory exits with "another backend is already
serving".  That failure does not touch the first backend's socket.

=item A killed backend leaves files behind.

After C<kill -9> the socket file and the pid file stay.  The next backend starts
normally: it finds that nothing answers on the socket and removes it.  The lock
file (C<.owner>) and the log are never removed.

=item Old log lines are thrown away.

It keeps only one earlier copy: see C<max_log_size>.  To keep more, give C<log>
a symbolic link to a file that something else rotates.

=item The limits drop clients, not requests.

A client that goes over C<max_queued>, C<max_queued_total> or C<write_timeout>
loses its connection and, with it, its objects.

=item C<max_clients> counts connections that are still shaking hands.

A client over the limit is told "busy" on a unix socket.  On TCP it is simply
closed, because the TLS handshake has not happened.

=item The class's package variables are shared.

All objects of a class live in one process, so all clients see the same package
variables.  Keep state in the object.

=back

=head1 SEE ALSO

L<Class::Shared>, L<Class::Shared::Frontend>, L<Class::Shared::Protocol>,
L<class-shared>, L<Log::Abstraction>, L<Object::Configure>, L<Params::Get>,
L<Params::Validate::Strict>.

=head1 AUTHOR

Nigel Horne

=head1 FORMAL SPECIFICATION

This section describes what the backend does in the Z notation, a way of
writing exactly what a program promises using sets and logic.  You do not need
it to use the module.  Read the plain text above first.

Z uses mathematical symbols, so this is the only part of the file that is not
plain ASCII.  A short key:

    x? input      x! output      x' the value of x after the operation
    =>  implies   /\  and        \/  or        ~  not
    ⊥  undef      ⊕  update a function      ⩤  remove from a function (domain subtraction)
    ↦  maps to    ⇸  partial function       #  size of a set

=head2 State

    ┌─ Backend ───────────────────────────────────────────────
    │ classes     : ℙ CLASSNAME               loaded, each once
    │ clients     : FD ⇸ CLIENT               open connections
    │ objects     : ℕ₁ ⇸ (OBJECT × SERIAL)    object id to its object and owner
    │ queued      : ℕ                         bytes waiting to be written, all clients
    │ stop        : 𝔹
    │ owns_socket : 𝔹
    ├─────────────────────────────────────────────────────────
    │ #clients ≤ max_clients ∧ #objects ≤ max_objects
    │ queued = Σ { #c.outbuf | c ∈ ran clients } ∧ queued ≤ max_queued_total
    │ ∀ c ∈ ran clients • ∀ id ∈ c.objects • id ∈ dom objects ∧ owner(objects id) = c.serial
    │ ∀ id ∈ dom objects • ∃ c ∈ ran clients • owner(objects id) = c.serial
    │                                  an object never outlives its connection
    └─────────────────────────────────────────────────────────

and each CLIENT has C<class> (a class name or ⊥), C<greeted> (𝔹), C<serial>,
C<objects> (the ids it made), C<buffer> and C<outbuf> (bytes), and C<closed>.

=head2 new

    ┌─ New ───────────────────────────────────────────────────
    │ args?, env, file : NAME ⇸ VALUE ; out! : RESULT[Backend]
    │ opts == (file ⊕ env) ⊕ args?            the caller's arguments win, then env, then file
    ├─────────────────────────────────────────────────────────
    │ dom args? ⊄ OPTIONS ∨ ¬ valid(args?)    ⇒ ∃ m • out! = dies(m)
    │ ¬ valid(opts ∖ dom args?)               ⇒ ∃ m • out! = dies(m)   a configured value
    │ otherwise, with opts as below:
    │ host? = ⊥ ∧ port? = ⊥ ∧ no token ∧ no tls_*  ∧ #socket ≤ 100  ⇒ out! = value(b) ∧ b is idle
    │ host? ≠ ⊥ ∧ port? ≠ ⊥ ∧ socket? = ⊥ ∧ token ≠ ⊥ ∧ tls_cert, tls_key, tls_ca ≠ ⊥
    │                                                    ⇒ out! = value(b) ∧ b is idle
    │ any other combination ⇒ ∃ m • out! = dies(m)
    └─────────────────────────────────────────────────────────

where an option whose value is ⊥ counts as absent from C<args?>, and C<valid>
means every named option exists and its value has the right type and range.

=head2 run

    ┌─ Run ───────────────────────────────────────────────────
    │ ΔBackend ; out! : RESULT[{0}]
    ├─────────────────────────────────────────────────────────
    │ setup succeeds ⇒ owns_socket' = (transport = unix)
    │                  ∧ (the loop runs until stop = true)
    │                  ∧ at the end: clients' = ∅ ∧ objects' = ∅ ∧ owns_socket' = false ∧ out! = value(0)
    │ setup fails ∧ ¬ daemonize ⇒ out! = dies(e) ∧ owns_socket' = false
    │ setup fails ∧ daemonize   ⇒ the background process exits 1
    │ daemonize ⇒ the calling process exits 0 and out! is never seen
    └─────────────────────────────────────────────────────────

=head2 hello

    ┌─ Hello ─────────────────────────────────────────────────
    │ ΔBackend ; c : CLIENT ; proto? : ℕ ; class? : STRING⊥ ; out! : REPLY
    ├─────────────────────────────────────────────────────────
    │ proto? ≠ PROTOCOL_VERSION ⇒ out! = failure(protocol) ∧ ΞBackend
    │ class? ∉ CLASSNAME ∧ class? ≠ ⊥ ⇒ out! = failure(protocol)
    │ class? ∈ CLASSNAME ∧ load fails ⇒ out! = failure(unknown_class)
    │ otherwise ⇒ c.greeted' = true ∧ c.class' = class?
    │             ∧ classes' = classes ∪ {class? | class? ≠ ⊥} ∧ out!.ok = true
    └─────────────────────────────────────────────────────────

=head2 new (the request)

    ┌─ NewObject ─────────────────────────────────────────────
    │ ΔBackend ; c : CLIENT ; args? : seq DATA ; out! : REPLY
    ├─────────────────────────────────────────────────────────
    │ ¬ c.greeted ⇒ failure(protocol)            c.class = ⊥ ⇒ failure(protocol)
    │ #objects ≥ max_objects ⇒ failure(busy)
    │ c.class->new(args?) dies ⇒ failure(die)
    │ c.class->new(args?) = o ∧ o is a reference
    │     ⇒ ∃ id ∉ dom objects • objects' = objects ⊕ {id ↦ (o, c.serial)}
    │           ∧ c.objects' = c.objects ∪ {id} ∧ out! = (ok, id)
    └─────────────────────────────────────────────────────────

=head2 call

    ┌─ Call ──────────────────────────────────────────────────
    │ ΔBackend ; c : CLIENT ; id?, m? : ... ; args? : seq DATA ; want? : {list, scalar, void}
    ├─────────────────────────────────────────────────────────
    │ id? ∉ dom objects ⇒ failure(unknown_object)
    │ id? ∈ dom objects ∧ owner(objects id?) ≠ c.serial ⇒ failure(forbidden)
    │ m? ∈ {"new", "DESTROY", "AUTOLOAD"} ⇒ failure(forbidden)
    │ the class has no method m? ⇒ failure(unknown_method)
    │ the method dies with e ⇒ failure(die)               objects' = objects
    │ the method returns r ⇒ out! = (ok, shape(want?, r))   calls' = calls + 1
    └─────────────────────────────────────────────────────────

=head2 ping and shutdown

    ┌─ Ping ──────────────────────────────────────────────────
    │ ΞBackend ; c.greeted = true ; out! = (ok, counters of the state above)
    └─────────────────────────────────────────────────────────

    ┌─ Shutdown ──────────────────────────────────────────────
    │ ΔBackend ; c.greeted = true
    ├─────────────────────────────────────────────────────────
    │ stop' = true ∧ out! = (ok, "shutting down")     the reply is sent first
    └─────────────────────────────────────────────────────────

=head2 drop a client

    ┌─ Drop ──────────────────────────────────────────────────
    │ ΔBackend ; c : CLIENT ; reason? : STRING
    ├─────────────────────────────────────────────────────────
    │ c ∈ ran clients
    │ objects' = c.objects ⩤ objects                      its objects are destroyed
    │ clients' = clients \ {c's descriptor}               the connection is closed
    │ queued' = queued - #c.outbuf                        its queued reply is discarded
    │ a log line records reason?
    └─────────────────────────────────────────────────────────

=head1 STATE DIAGRAM

First, the life of the backend process.  Then, the life of one client
connection inside it.

=head2 The backend

    +------+  run()  +----------+  lock taken, socket bound  +---------+
    | IDLE | ------> | STARTING | -------------------------> | SERVING | <-+
    +------+         +----------+                            +---------+   | requests keep
                          |                                       |      --+ it SERVING
             something    |                       SIGTERM, SIGINT |
             fails        v                       or "shutdown"   v
                     +----------+                            +----------+
                     |  FAILED  |                            | STOPPING |
                     +----------+                            +----------+
                                                                   |
                                                    cleanup done   v
                                                              +---------+
                                                              | STOPPED |
                                                              +---------+

=over 4

=item IDLE to STARTING

Trigger: C<run>.  Action: if C<daemonize>, fork twice (the caller exits 0); then
check the directory, take the lock, and open the socket.

=item STARTING to SERVING

Trigger: the socket is open.  Action: the pid file is written and C<serving on
...> is logged.  A unix backend now owns its socket.

=item STARTING to FAILED

Trigger: another backend holds the lock or the socket, the directory is unsafe,
TLS cannot be set up, or the bind fails.  Action: the reason is logged.  The
foreground C<run> dies; a background copy exits with status 1.  The other
backend's socket is not touched.

=item SERVING to SERVING

Trigger: a client connects, sends a request, or goes away.  Action: see the
client diagram below.

=item SERVING to STOPPING

Trigger: C<SIGTERM>, C<SIGINT> or a C<shutdown> request.  Action: the loop ends.

=item STOPPING to STOPPED

Trigger: cleanup finishes.  Action: queued replies get one last try to be sent,
all connections are closed, every object is destroyed (so each C<DESTROY> runs,
here), the socket and pid file are removed, the lock is released, C<stopped> is
logged and C<run> returns 0.

=back

=head2 One client connection

    +----------+  TCP: start TLS   +-------------+
    | ACCEPTED | ----------------> | HANDSHAKING |
    +----------+                   +-------------+
         |                           |         |
         | unix: no TLS              | done    | fails, or takes longer
         |                           |         | than handshake_timeout
         v                           v         |
    +----------------+ <-------------+         |
    | AWAITING HELLO | <-+  a failed hello      |
    +----------------+ --+  changes nothing     |
         | good hello                           |
         v                                      |
    +---------+  new, call, ping:               |
    | GREETED | <-+  stays GREETED              |
    +---------+ --+  (new adds an object)       |
         |                                      |
         | error, end of file, bad frame,       |
         | or over a limit                      |
         v                                      v
    +----------------------------------------------+
    |  DROPPED: objects destroyed, socket closed,  |
    |  reason logged                               |
    +----------------------------------------------+

=over 4

=item ACCEPTED to HANDSHAKING

Trigger: a TCP client connects (and the backend is not full).  Action: start TLS
without waiting.  The handshake finishes a little at a time from the loop.

=item ACCEPTED to AWAITING HELLO

Trigger: a unix client connects.  Action: none; its socket is already trusted by
its file permissions.

=item ACCEPTED to DROPPED

Trigger: the backend already has C<max_clients> connections.  Action: a unix
client gets a signed C<busy> reply first; a TCP client is just closed.

=item HANDSHAKING to AWAITING HELLO

Trigger: the TLS handshake finishes.  Action: none.

=item HANDSHAKING to DROPPED

Trigger: the handshake fails (for example no client certificate, or one signed
by another CA) or takes longer than C<handshake_timeout>.  Action: logged and
closed; no object was ever made.

=item AWAITING HELLO to GREETED

Trigger: a C<hello> with the right protocol version and a valid, loadable class
(or no class).  Action: the class is loaded once (if new) and the connection is
marked greeted.  A further C<hello> on a greeted connection is refused with a
C<protocol> failure and changes nothing.

=item GREETED to GREETED

Trigger: C<new>, C<call>, C<ping>.  Action: C<new> adds an object owned by this
connection.  C<call> runs a method.  An exception from the target is sent back
as a reply and does not change the state.

=item any state to DROPPED

Trigger: end of file, a read or write error, a frame that is too large or fails
its digest, a reply that would pass C<max_queued> or C<max_queued_total>, a
queued reply that makes no progress for C<write_timeout> seconds.  Action: the connection's objects are destroyed, its queued data is
discarded, the socket is closed, and the reason is logged.  (When the backend
itself stops, it closes every connection during its cleanup; that is not logged
as a drop.)

=back

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License, version 2, as published by the
Free Software Foundation.

This module is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.  See the F<LICENSE> file for the full text.

=cut
