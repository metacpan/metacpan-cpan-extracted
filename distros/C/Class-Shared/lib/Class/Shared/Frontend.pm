package Class::Shared::Frontend;

use strict;
use warnings;

use Carp ();
use Fcntl qw(:flock O_RDWR O_CREAT);
use File::Spec ();
use Scalar::Util ();
use Socket qw(AF_UNIX SOCK_STREAM pack_sockaddr_un);

use Class::Shared ();
use Class::Shared::Protocol ();

our $VERSION = '0.001.0';

# Seconds to wait for a backend to start up and answer.
our $DEFAULT_TIMEOUT = 10;

# How long shared_shutdown waits, in seconds, for the socket to disappear.
our $SHUTDOWN_WAIT = 5;

# The descriptors a freshly forked backend closes.  Everything from 3 up belongs
# to the client that forked it, and a daemon must not keep a client's sockets or
# locks open.
our $FIRST_INHERITED_FD = 3;
our $LAST_INHERITED_FD  = 1023;

our $AUTOLOAD;

my %KNOWN_OPTION = map { $_ => 1 } qw(
	class ctor socket dir host port token token_file autostart timeout log
	tls_cert tls_key tls_ca tls_fingerprint
);

# One frontend stands for one object.  The object itself lives in the backend,
# together with every other object of the same class; the class is loaded there
# once, however many objects and processes there are.
sub new {
	my $class = shift;

	my $target;
	# An undef first argument is "no class name": it is taken as the target so
	# that the check below reports it, instead of warning on the lookup.
	if (@_ && !ref $_[0] && (!defined $_[0] || !exists $KNOWN_OPTION{$_[0]})) {
		$target = shift @_;
	}

	my %opt;
	if (@_ == 1 && ref($_[0]) eq 'HASH') {
		%opt = %{ $_[0] };
	} elsif (@_) {
		die "Class::Shared::Frontend->new: expected key/value options\n" if @_ % 2;
		%opt = @_;
	}

	$target = delete $opt{class} if defined $opt{class};

	for my $key (sort keys %opt) {
		die "Class::Shared::Frontend->new: unknown option '$key'\n"
			unless exists $KNOWN_OPTION{$key};
	}

	die "Class::Shared::Frontend->new: no class name given\n"
		unless defined $target && length $target;

	Class::Shared::validate_class($target);

	if (defined $opt{ctor} && ref($opt{ctor}) ne 'ARRAY') {
		die "Class::Shared::Frontend->new: ctor must be an array ref\n";
	}

	my $transport = (defined $opt{host} || defined $opt{port}) ? 'tcp' : 'unix';

	# A unix socket is mode 0600 in a directory only its owner can write to, so
	# the kernel has already decided who may connect: a token would add 32 bytes
	# to every frame and buy nothing.
	die "Class::Shared::Frontend->new: a unix socket needs no token: "
		. "$Class::Shared::UNIX_TRUST_REASON\n"
		if $transport eq 'unix'
			&& (defined $opt{token} || defined $opt{token_file});

	die "Class::Shared::Frontend->new: a unix socket needs no TLS: "
		. "$Class::Shared::UNIX_TRUST_REASON\n"
		if $transport eq 'unix'
			&& grep { defined $opt{$_} && length $opt{$_} }
				qw(tls_cert tls_key tls_ca tls_fingerprint);

	# Two sources of one secret: picking one would hide a mistake in the other.
	die "Class::Shared::Frontend->new: give token or token_file, not both\n"
		if defined $opt{token} && defined $opt{token_file};

	my $token = defined $opt{token_file}
		? Class::Shared::read_secret($opt{token_file})
		: $opt{token};

	if ($transport eq 'tcp') {
		die "Class::Shared::Frontend->new: a TCP backend needs both host and port\n"
			unless defined $opt{host} && defined $opt{port};

		# A port is a whole number in the range the network stack accepts.
		# Checked before anything is read or connected, so a typo is reported
		# as a typo rather than as a failure to reach the backend.
		if ($opt{port} !~ /\A[0-9]+\z/ || $opt{port} < 1 || $opt{port} > 65535) {
			die "Class::Shared::Frontend->new: port must be a whole number from 1 to 65535\n";
		}
		die "Class::Shared::Frontend->new: use either socket or host/port, not both\n"
			if defined $opt{socket};

		# Verification is not optional, and neither is proving who we are:
		# tls_cert/tls_key are the certificate the backend will accept from
		# this client, and tls_ca or tls_fingerprint says how to be sure the
		# backend is the one we meant.
		die "Class::Shared::Frontend->new: a TCP backend needs tls_cert and tls_key: "
			. "the backend will not accept a client it cannot verify\n"
			if grep { !defined $opt{$_} || !length $opt{$_} } qw(tls_cert tls_key);

		die "Class::Shared::Frontend->new: a TCP backend needs tls_ca or "
			. "tls_fingerprint: without one it cannot verify the backend\n"
			unless (defined $opt{tls_ca} && length $opt{tls_ca})
				|| (defined $opt{tls_fingerprint} && length $opt{tls_fingerprint});

		die "Class::Shared::Frontend->new: give tls_ca or tls_fingerprint, "
			. "not both: a CA and a pin are alternatives\n"
			if (defined $opt{tls_ca} && length $opt{tls_ca})
				&& (defined $opt{tls_fingerprint} && length $opt{tls_fingerprint});
	}

	my $socket_path = $transport eq 'unix'
		? (defined $opt{socket} && length $opt{socket}
			? Class::Shared::check_socket_path($opt{socket})
			: Class::Shared::socket_path($opt{dir}))
		: undef;

	my $self = bless {
		class       => $target,
		transport   => $transport,
		socket_path => $socket_path,
		host        => $opt{host},
		port        => $opt{port},
		token       => $token,
		tls_cert    => $opt{tls_cert},
		tls_key     => $opt{tls_key},
		tls_ca      => $opt{tls_ca},
		tls_fingerprint => (defined $opt{tls_fingerprint} && length $opt{tls_fingerprint})
			? Class::Shared::normalise_fingerprint($opt{tls_fingerprint})
			: undef,
		ctor        => $opt{ctor} || [],
		autostart   => exists $opt{autostart} ? $opt{autostart} : 1,
		timeout     => defined $opt{timeout} ? $opt{timeout} : $DEFAULT_TIMEOUT,
		# Only a unix backend is ever started from here, so only it has a log.
		log         => defined $opt{log} && length $opt{log} ? $opt{log}
			: $transport eq 'unix' ? "$socket_path.log" : undef,
		sock        => undef,
		pid         => undef,
		id          => undef,
		last_error  => undef,
	}, $class;

	$self->_connect;

	return $self;
}

# ---------------------------------------------------------------- accessors

sub shared_class { $_[0]->{class} }

# The unix socket in use, or undef when talking to a TCP backend.
sub shared_socket_path { $_[0]->{socket_path} }

# A socket path or host:port, whichever this frontend talks to.
sub shared_address {
	my $self = shift;
	return $self->{transport} eq 'tcp'
		? $self->{host} . ':' . $self->{port}
		: $self->{socket_path};
}

# Process id of the backend, and the id of this object inside it.
sub shared_pid { $_[0]->{pid} }
sub shared_id  { $_[0]->{id} }

sub shared_connected { defined $_[0]->{sock} ? 1 : 0 }

sub shared_last_error { $_[0]->{last_error} }

# Explicit dispatch, for method names that clash with the accessors above
# (or with new()).
sub shared_call {
	my $self = shift;
	my $method = shift;

	die "Class::Shared::Frontend->shared_call: no method name given\n"
		unless defined $method && length $method;

	return $self->_invoke_as_called($method, \@_);
}

sub shared_status {
	my $self = shift;

	return $self->_request({ op => 'ping' });
}

# Close the connection.  The object goes with it: the backend destroys
# everything a connection created when that connection goes away, which is
# also what happens if this process dies without closing anything.
sub shared_close {
	my $self = shift;

	return 0 unless $self->{sock};

	# The state is cleared whether or not the close worked: the connection is
	# unusable either way, and a caller must not be left holding half of one.
	# It is cleared first: a failed close carps, and Carp calls can() on the
	# objects in the call stack, which would otherwise send a request down the
	# handle that is being closed.
	my $sock = $self->{sock};
	$self->{sock} = undef;
	$self->{id} = undef;
	$self->{pid} = undef;
	$self->_close($sock, 'the connection to the backend');

	return 1;
}

sub DESTROY {
	my $self = shift;
	$self->shared_close if $self->{sock};
	return;
}

# Ask the backend to stop.  That destroys every object it holds, including
# other clients' objects, so it is an administrative operation, not something
# a normal client does.
sub shared_shutdown {
	# Evals below must not leave their errors in the caller's $@.
	local $@;
	my $self = shift;

	return 0 unless $self->{sock};

	my $response = eval { $self->_request({ op => 'shutdown' }) };
	my $error = $@;

	$self->shared_close;

	if ($self->{transport} eq 'unix') {
		my $deadline = time + $SHUTDOWN_WAIT;
		while (-e $self->{socket_path} && time < $deadline) {
			Class::Shared::poll_pause();
		}
	}

	die $error if $error;

	return $response->{ok} ? 1 : 0;
}

# ------------------------------------------------------------- dispatching

sub AUTOLOAD {
	my $self = shift;

	my $method = $AUTOLOAD;
	$method =~ s/\A.*:://;

	return if $method eq 'DESTROY';

	die "Class::Shared::Frontend: '$method' called on something that is not a Class::Shared::Frontend object\n"
		unless ref $self;

	return $self->_invoke_as_called($method, \@_);
}

# can() and isa() are inherited from UNIVERSAL, which would answer for the
# frontend rather than for the class it stands in for, so both are overridden.
sub can {
	# Evals below must not leave their errors in the caller's $@.
	local $@;
	my ($self, $method) = @_;

	return UNIVERSAL::can($self, $method) unless ref $self;
	return undef unless defined $method;

	# The frontend's own methods are answered locally and honestly.
	my $local = UNIVERSAL::can('Class::Shared::Frontend', $method);
	return $local if $local;

	my $response = eval {
		$self->_request({
			op     => 'call',
			method => 'can',
			args   => [$method],
			want   => 'scalar',
		});
	};

	return undef unless $response && $response->{ok};
	return undef unless ref($response->{result}) eq 'ARRAY' && $response->{result}[0];

	# Answer the way can() normally does: with something callable.
	return sub {
		shift if @_ && ref($_[0])
			&& Scalar::Util::refaddr($_[0]) == Scalar::Util::refaddr($self);

		return $self->_invoke_as_called($method, \@_);
	};
}

sub isa {
	# Evals below must not leave their errors in the caller's $@.
	local $@;
	my ($self, $class) = @_;

	return UNIVERSAL::isa($self, $class) unless ref $self;

	# UNIVERSAL::isa warns about an undefined class; no class is not a parent.
	return 0 unless defined $class;

	return 1 if $class eq 'Class::Shared::Frontend' or $class eq 'UNIVERSAL';

	my $response = eval {
		$self->_request({
			op     => 'call',
			method => 'isa',
			args   => [$class],
			want   => 'scalar',
		});
	};

	return 0 unless $response && $response->{ok};

	return ref($response->{result}) eq 'ARRAY' && $response->{result}[0] ? 1 : 0;
}

# Purpose:       Run $method in the backend in the context this routine's own
#                caller used, so list, scalar and void calls behave as if the
#                target object were local.  Three entry points need exactly this.
# Entry:         $self is a connected frontend; $args is an array ref.
# Exit status:   the call's results, shaped by the caller's context; dies as
#                _invoke does.
# Side effects:  one round trip to the backend.  Called as the last expression
#                of its caller (return $self->_invoke_as_called(...)) so that
#                wantarray here is the caller's context.
sub _invoke_as_called {
	my ($self, $method, $args) = @_;

	my $want = wantarray;
	my $context = $want ? 'list' : defined($want) ? 'scalar' : 'void';

	my $result = $self->_invoke($method, $args, $context);

	return @{$result} if $context eq 'list';
	return if $context eq 'void';
	return $result->[0];
}

sub _invoke {
	my ($self, $method, $args, $context) = @_;

	my $response = $self->_request({
		op     => 'call',
		method => $method,
		args   => $args,
		want   => $context,
	});

	if (!$response->{ok}) {
		my $error = $response->{error};
		$error = "Class::Shared: the backend for '$self->{class}' rejected '$method'"
			unless defined $error && length $error;

		# Thrown again with its original text (see the POD): without a final
		# new line die would add this file and line to it.
		$error .= "\n" unless $error =~ /\n\z/;
		die $error;
	}

	my $result = $response->{result};
	return [] unless ref($result) eq 'ARRAY';

	return $result;
}

# --------------------------------------------------------------- transport

sub _connect {
	my $self = shift;

	my $sock = $self->_greet;

	if (!$sock) {
		my $reason = $self->{last_error} || 'no backend';

		die "Class::Shared: cannot reach a backend at "
			. $self->shared_address . ": $reason\n"
			unless $self->{autostart} && $self->{transport} eq 'unix';

		$sock = $self->_spawn_backend;

		die "Class::Shared: could not start a backend: "
			. ($self->{last_error} || 'timed out')
			. ' (socket ' . $self->shared_address . ", log $self->{log})\n"
			unless $sock;
	}

	$self->{sock} = $sock;

	$self->_create_object;

	return $self;
}

sub _open {
	my $self = shift;

	if ($self->{transport} eq 'tcp') {
		# Loaded only here, so a client of a unix socket still runs none of
		# this.  Verification is mandatory: a certificate that does not chain
		# to tls_ca and name this backend, or whose digest is not the pinned
		# one, is not a connection.
		require IO::Socket::SSL;

		my $sock = IO::Socket::SSL->new(
			PeerAddr => $self->{host},
			PeerPort => $self->{port},
			Proto    => 'tcp',
			Timeout  => $self->{timeout},
			Class::Shared::client_tls_options(
				cert        => $self->{tls_cert},
				key         => $self->{tls_key},
				ca          => $self->{tls_ca},
				fingerprint => $self->{tls_fingerprint},
			),
		);

		if (!$sock) {
			my $why = IO::Socket::SSL::errstr();
			$why = "$!" unless defined $why && length $why;
			$self->{last_error} = "cannot connect to " . $self->shared_address
				. " over TLS: $why";
		}

		return $sock;
	}

	my $path = $self->{socket_path};

	# TODO: Data Flow Anomaly - DD: redefined unread by each later failure, and cleared unread by _greet on success
	$self->{last_error} = "no socket at $path";
	return undef unless -S $path;

	# Whatever comes back over this socket is thawed, so it must be ours: a
	# directory another user can write to, or a socket another user made, would
	# let that user answer every call and read every argument.
	my ($safe, $why) = Class::Shared::_check_endpoint($path);
	if (!$safe) {
		$self->{last_error} = "will not connect to $path: $why";
		return undef;
	}

	# The built-in socket and connect, not IO::Socket::UNIX: that module brings
	# IO::Socket, IO::Socket::INET and IO::Handle with it, about 1.2 MB and 16
	# ms in every process that talks to the backend, for a handle that is only
	# ever given to sysread, syswrite and close.
	my $sock;
	if (!socket($sock, AF_UNIX, SOCK_STREAM, 0)
		|| !connect($sock, pack_sockaddr_un($path))) {
		$self->{last_error} = "cannot connect to $path: $!";
		return undef;
	}

	return $sock;
}

sub _greet {
	my $self = shift;

	my $sock = $self->_open;
	return undef unless $sock;

	my ($response, $error) = $self->_roundtrip($sock, {
		op    => 'hello',
		proto => $Class::Shared::PROTOCOL_VERSION,
		class => $self->{class},
		pid   => $$,
	}, $self->{timeout});

	if (!defined $response) {
		$self->_close($sock, 'a failed handshake');

		$self->{last_error} = 'handshake failed: ' . $self->_first_exchange_failed($error);
		return undef;
	}

	if (!$response->{ok}) {
		$self->_close($sock, 'a refused handshake');
		die 'Class::Shared: ' . ($response->{error} || 'the backend refused the handshake') . "\n";
	}

	$self->{pid} = $response->{pid};
	$self->{last_error} = undef;

	return $sock;
}

# Say what a failed first exchange most likely means.  Over TLS a backend that
# will not accept this client's certificate drops the connection during the
# handshake, before it can answer: from here that is a stream closing at once,
# and calling it "connection closed by peer" hides the one thing that would fix
# it.  A backend that accepted the certificate but not the token does answer,
# with a frame this side cannot read, so that case keeps the token wording.
sub _first_exchange_failed {
	my ($self, $error) = @_;

	$error = 'no reason was given' unless defined $error;

	if ($self->{transport} eq 'tcp' && defined $error
		&& $error =~ /closed by peer|read failed|write failed/)
	{
		my $hint = "the backend refused this client's certificate: check that "
			. 'tls_cert and tls_key are a certificate it accepts, and that tls_ca '
			. 'holds the CA it trusts for clients';

		return "$hint (detail: $error)";
	}

	# A silent backend is more likely busy with another client's method than
	# in need of a token, and saying so is what lets the person decide to wait.
	return "$error (the backend may be busy running another client's method; "
		. 'try again, or raise timeout)' if $error =~ /timed out/;

	return $error if defined $self->{token};

	return "$error (this backend may require a token)";
}

sub _create_object {
	my $self = shift;

	my $response = $self->_request({ op => 'new', args => $self->{ctor} }, $self->{timeout});

	if (!$response->{ok}) {
		my $error = $response->{error} || 'the backend gave no reason';
		$error =~ s/\s+\z//;
		$self->shared_close;
		die "Class::Shared: could not construct $self->{class}: $error\n";
	}

	$self->{id} = $response->{id};

	return $self;
}

sub _request {
	my ($self, $message, $wait) = @_;

	$message->{id} = $self->{id} if ($message->{op} || '') eq 'call';

	die "Class::Shared: this frontend has no connection to a backend for '$self->{class}'; "
		. "its object is gone\n" unless $self->{sock};

	my ($response, $error) = $self->_roundtrip($self->{sock}, $message, $wait);

	if (!defined $response) {
		$error = 'no reason was given' unless defined $error && length $error;
		$self->shared_close;
		$self->{last_error} = $error;
		die "Class::Shared: lost the backend for '$self->{class}': $error\n";
	}

	return $response;
}

sub _roundtrip {
	my ($self, $sock, $message, $wait) = @_;

	# With a token every frame is signed, and the backend checks the digest
	# before it thaws: this is what stops the request bytes from being code.
	my ($bytes, $encode_error) = Class::Shared::Protocol::encode_frame($message, $self->{token});
	if (!defined $bytes) {
		return (undef, $encode_error);
	}

	my ($ok, $write_error) = Class::Shared::Protocol::write_all($sock, $bytes);
	return (undef, $write_error) unless $ok;

	my ($response, $read_error)
		= Class::Shared::Protocol::read_frame($sock, $wait, $self->{token});
	return (undef, $read_error) unless defined $response;

	if (ref($response) ne 'HASH') {
		return (undef, 'malformed response from the backend');
	}

	return ($response);
}

# ------------------------------------------------------------ spawning

# Purpose:       close a handle and say so if it fails, because a failed close
#                can mean data was lost or a lock was not released.
# Entry:         $fh is an open handle; $what names it for the message.
# Exit status:   1 on success, 0 on failure.
# Side effects:  closes $fh; carps on failure.
sub _close {
	my ($self, $fh, $what) = @_;

	return 1 if close($fh);

	Carp::carp("Class::Shared::Frontend: cannot close $what: $!");

	return 0;
}

sub _spawn_backend {
	# Evals below must not leave their errors in the caller's $@.
	local $@;
	my $self = shift;

	my $path = $self->{socket_path};
	my $dir  = Class::Shared::dir_of($path);

	my ($dir_ok, $dir_error) = Class::Shared::ensure_dir($dir);
	if (!$dir_ok) {
		$self->{last_error} = $dir_error;
		return undef;
	}

	my $lock_path = $path . '.spawn';
	my $lock;
	if (!sysopen($lock, $lock_path, O_RDWR | O_CREAT, 0600)) {
		$self->{last_error} = "cannot open $lock_path: $!";
		return undef;
	}
	if (!flock($lock, LOCK_EX)) {
		$self->{last_error} = "cannot lock $lock_path: $!";
		$self->_close($lock, $lock_path);
		return undef;
	}

	# Somebody else may have started it while we waited for the lock.
	if (my $sock = eval { $self->_greet }) {
		$self->_close($lock, $lock_path);
		return $sock;
	}
	$self->_refused($lock, $lock_path, $@);

	# We hold the lock, so a socket that will not answer is a leftover.
	# Only a socket is removed as a leftover: a path that names anything else
	# is not ours to delete, whatever the caller meant by it.
	my $state = $self->_remove_stale($path);
	if (!$state) {
		$self->_close($lock, $lock_path);
		return undef;
	}

	# A backend that is running but slow to answer is waited for, not replaced.
	if ($state ne 'running' && !$self->_fork_backend($lock)) {
		$self->_close($lock, $lock_path);
		return undef;
	}

	my $deadline = time + $self->{timeout};
	my $sock;

	while (time <= $deadline) {
		my $greeted = eval { $self->_greet };
		if (my $handshake_error = $@) {
			$self->_refused($lock, $lock_path, $handshake_error);
			$handshake_error =~ s/\s+\z//;
			$self->{last_error} = $handshake_error;
		}
		if ($greeted) {
			$sock = $greeted;
			last;
		}

		# A backend that is stopping removes its socket before it releases its
		# lock.  Once the lock is free nobody is coming back to answer, so one
		# has to be started after all.
		if ($state eq 'running') {
			$state = $self->_remove_stale($path);
			last unless $state;
			if ($state ne 'running' && !$self->_fork_backend($lock)) {
				last;
			}
		}
		Class::Shared::poll_pause();
	}

	$self->_close($lock, $lock_path);

	$self->{last_error} = "a backend is running at $path but did not answer: "
		. ($self->{last_error} // 'no reason was given')
		if !$sock && ($state // '') eq 'running';

	return $sock;
}

# Purpose:       start one backend in the background.
# Entry:         the spawn lock is held on $lock.
# Exit status:   1 once it has been started (not once it is ready), 0 with
#                last_error set if it could not be.
# Side effects:  forks, and waits for the intermediate child.
sub _fork_backend {
	my ($self, $lock) = @_;

	my $pid = fork;
	if (!defined $pid) {
		$self->{last_error} = "fork failed: $!";
		return 0;
	}

	if ($pid == 0) {
		$self->_exec_backend($lock);
		# not reached
	}

	# The first child only forks the daemon and exits; waiting for it stops it
	# being left as a zombie.  Its status says nothing about the backend, which
	# is judged by whether it answers, and waitpid fails harmlessly when
	# SIGCHLD is ignored.
	waitpid($pid, 0);

	return 1;
}

# Purpose:       remove the socket a dead backend left, and only that.
# Entry:         $path is the socket path; the spawn lock is held.
# Exit status:   'running' if a backend owns the path, 'clear' if nothing is in
#                the way of a new one, undef (with last_error set) otherwise.
# Side effects:  may unlink $path.
# Why:           silence is not death: a backend busy with a long method does
#                not answer.  A running backend holds a lock on PATH.owner, so
#                the lock tells the two apart.  It is held while unlinking, so a
#                backend starting at this moment waits and keeps its new socket.
sub _remove_stale {
	my ($self, $path) = @_;

	my $owner_path = "$path.owner";
	my $owner;
	if (!sysopen($owner, $owner_path, O_RDWR | O_CREAT, 0600)) {
		$self->{last_error} = "cannot open $owner_path: $!";
		return undef;
	}

	my $state = 'running';
	if (flock($owner, LOCK_SH | LOCK_NB)) {
		$state = 'clear';
		if (-e $path && !-S $path) {
			$self->{last_error} = "$path exists and is not a socket; refusing to remove it";
			$state = undef;
		} elsif (-e $path && !unlink($path)) {
			$self->{last_error} = "cannot remove the stale socket $path: $!";
			$state = undef;
		}
	}
	$self->_close($owner, $owner_path);

	return $state;
}

# Purpose:       pass on a refusal that a running backend gave to the handshake.
# Entry:         $error is what _greet died with ('' if it did not die).
# Exit status:   returns if there is nothing to pass on; otherwise dies.
# Side effects:  releases the start lock first.
# Why:           a backend that answers "cannot load CLASS" is alive and has
#                given its final answer.  Retrying until the timeout wastes
#                the time, and replacing its socket would be wrong.
sub _refused {
	my ($self, $lock, $lock_path, $error) = @_;

	return unless defined $error && $error =~ /\AClass::Shared: /;

	$self->_close($lock, $lock_path);
	die $error;
}

# Runs in the freshly forked child; never returns.  There is nobody to report
# a failure to here: the streams are not redirected yet, and the parent only
# sees whether a backend answers.  So every step that must work is checked, and
# a failure ends the child with status 127, after which the parent reports that
# no backend started and points at the log.
sub _exec_backend {
	my ($self, $lock) = @_;

	require POSIX;

	if ($lock) {
		close($lock) or POSIX::_exit(127);
	}

	POSIX::setsid() or POSIX::_exit(127);

	# Double fork so the daemon is reaped by init, not by the client.
	my $pid = fork;
	POSIX::_exit(0) if !defined $pid || $pid > 0;

	# Most of these numbers are not open descriptors, so POSIX::close failing
	# with EBADF is the expected answer and is not an error.
	for my $fd ($FIRST_INHERITED_FD .. $LAST_INHERITED_FD) {
		POSIX::close($fd);
	}

	my ($detached) = Class::Shared::detach_standard_streams($self->{log});
	POSIX::_exit(127) unless $detached;

	my @inc = grep { defined($_) && !ref($_) && length($_) } @INC;

	# Under -T perl will not exec with a tainted argument or a PATH it cannot
	# vouch for, and it counts the name of the perl itself ($^X) as tainted.
	# All are untainted here, at the one place they are used, and only under -T
	# so that nothing changes for anyone else.  The names are only refused if
	# they hold a NUL, which would end them early.  PATH keeps the entries that
	# are absolute directories no one but the owner can write to, and perl
	# insists on that: it refuses to exec at all while PATH names a directory
	# others can write to (a CI runner's PATH usually does), because a program
	# put there would be run in place of the one meant.  A relative or empty
	# entry would make the child look in the current directory.
	my ($perl, $socket, $log) = ($^X, $self->{socket_path}, $self->{log});
	if (${^TAINT}) {
		($perl)   = $perl   =~ /\A([^\0]+)\z/ or POSIX::_exit(127);
		($socket) = $socket =~ /\A([^\0]+)\z/ or POSIX::_exit(127);
		($log)    = $log    =~ /\A([^\0]+)\z/ or POSIX::_exit(127);

		# The capture untaints each entry; the filetests need no untainting.
		my @safe = grep { -d $_ && !((stat _)[2] & 0022) }
			map { m{\A(/[^\0]*)\z} ? $1 : () } split /:/, ($ENV{PATH} // '');
		$ENV{PATH} = @safe ? join(':', @safe) : '/usr/bin:/bin';
		delete @ENV{qw(IFS CDPATH ENV BASH_ENV)};
	}

	no warnings 'exec';    # exec() does not return when it works
	exec(
		$perl,
		(map { ('-I', $_) } @inc),
		'-MClass::Shared::Backend',
		'-e',
		'Class::Shared::Backend->new(socket => $ARGV[0], log => $ARGV[1])->run()',
		$socket,
		$log,
	);

	POSIX::_exit(127);
}

1;

__END__

=encoding utf8

=head1 NAME

Class::Shared::Frontend - a stand-in for one object that lives in a backend

=head1 SYNOPSIS

Each example is a different real-world pattern.

    use Class::Shared::Frontend;

    # 1. Share one class between many processes.  The object is built in the
    #    shared backend, and this process runs none of the class's code.
    my $simple = Class::Shared::Frontend->new('Class::Simple');

    $simple->foo('hello');
    print $simple->foo(), "\n";                 # prints "hello"

    # 2. The same, giving the class's constructor arguments.
    #    It is Class::Simple->new(verbose => 1).
    my $verbose = Class::Shared::Frontend->new('Class::Simple',
        ctor => [verbose => 1],
    );

    # 3. A backend on another machine, reached over TLS with a client
    #    certificate, and checked against a CA.
    my $remote = Class::Shared::Frontend->new('Class::Simple',
        host       => 'classhost.example.com',
        port       => 7000,
        tls_ca     => '/etc/class-shared/server-ca.pem',
        tls_cert   => '/etc/class-shared/client.pem',
        tls_key    => '/etc/class-shared/client-key.pem',
        token_file => '/etc/class-shared/token',
        ctor       => [verbose => 1],
    );

    # 4. Trust exactly one certificate by its fingerprint instead of a CA.
    my $pinned = Class::Shared::Frontend->new('Class::Simple',
        host            => '192.0.2.10',
        port            => 7000,
        tls_fingerprint => 'AB:CD:EF:...:12',
        tls_cert        => 'client.pem',
        tls_key         => 'client-key.pem',
        token_file      => '/etc/class-shared/token',
    );

    # 5. Do not start a backend; fail if there is none.  Catch the error.
    my $maybe = eval {
        Class::Shared::Frontend->new('Class::Simple', autostart => 0)
    };
    warn "no backend running: $@" unless $maybe;

    # 6. Ask about the connection, and call a method whose name clashes with a
    #    frontend method.
    print "backend pid: ", $simple->shared_pid, "\n";
    my $status = $simple->shared_status;
    print "objects held: $status->{objects}\n";

    # Same as $simple->foo('hello'), but also works when the target's method
    # has the same name as one of the frontend's own methods.
    my $same = $simple->shared_call('foo', 'hello');

    # 7. Let go of the object early (it is also released when $simple goes away).
    $simple->shared_close;

=head1 DESCRIPTION

Each frontend stands for one object.  Constructing it asks a
L<Class::Shared::Backend> to run the target's C<new> with the arguments in
C<ctor>, and the backend returns an id.  Every method call is then forwarded
over the socket, applied to that object, and the result comes back.

The backend holds many such objects, all belonging to the one copy of the class
it loaded.  So a hundred client processes with ten objects each still cost one
copy of F<Class/Simple.pm>, while keeping a hundred processes' worth of
independent objects.

The object lives as long as the connection.  When the frontend is destroyed, or
the process exits or dies, the socket closes and the backend destroys everything
that connection created; the target's C<DESTROY> runs there, once.

A frontend never loads the target class.  If no backend is listening on a unix
socket, one is started automatically (C<autostart =E<gt> 0> forbids that, and a
TCP backend is never started for you).

In this page, I<target> means the real class that is being shared (for example
C<Class::Simple>), and I<backend> means the process that holds the real objects.
A I<socket> is a connection point two programs use to talk; a I<unix socket> is
a file for programs on the same machine.  See L<Class::Shared/Words used in this documentation>
for the rest.

=head1 OPTIONS

    my $frontend = Class::Shared::Frontend->new('Class::Simple', %options);

The class name may be the first argument or C<class =E<gt> 'Class::Simple'>.

=over 4

=item ctor

Array reference of arguments for the target's C<new>, passed as a list in the
order given: C<ctor =E<gt> [verbose =E<gt> 1]> is
C<< Class::Simple->new(verbose =E<gt> 1) >>, and
C<ctor =E<gt> [{verbose =E<gt> 1}]> is
C<< Class::Simple->new({verbose =E<gt> 1}) >>.  Defaults to none, which is
C<< Class::Simple->new() >>.

They are used once, when the frontend connects and the backend constructs the
object, and they are serialised to get there, so they must be plain data: a
code reference, or anything else Storable cannot freeze, is reported when the
frontend is constructed rather than silently dropped.  A constructor that dies
makes C<new> die with C<Class::Shared: could not construct Class::Simple: > and
the error the backend reported.

=item dir

Directory for the unix socket.  Defaults to L<Class::Shared/default_dir>.

=item socket

An explicit unix socket path, overriding C<dir> and the derived name.  It must be
at most 100 characters; a longer path makes C<new> die, because the operating
system would otherwise cut it short without saying so.

=item host, port

Talk to a TCP backend on another machine, over TLS.  Both are required together,
and neither may be combined with C<socket>.  Autostarting does not apply.
C<tls_cert> and C<tls_key> are required with them, and so is one of C<tls_ca> or
C<tls_fingerprint>.

=item tls_ca, tls_fingerprint

How the backend is verified.  One of the two is required for TCP and there is no
way to switch verification off: a backend that does not verify is not a backend.

C<tls_ca> is a PEM file of the CA that signed the backend's certificate, and the
certificate must also name C<host>.  C<tls_fingerprint> is the SHA-256 digest of
that one certificate, as C<openssl x509 -in server.pem -noout -fingerprint
-sha256> prints it (colons and all, with or without a C<sha256$> prefix); a
pinned backend is accepted for its digest alone, whatever it is called and
whoever signed it, so a self-signed certificate and an address that does not
match its name are both fine.

Give one or the other, not both: a CA and a pin are alternatives.

=item tls_cert, tls_key

The certificate and private key this client presents.  The backend verifies
clients, so a connection without one is refused during the handshake and this
frontend gets no object; the error says the backend refused the certificate and
names these options.

=item token, token_file

The shared secret, needed only for a TCP backend, which will not start without
one and refuses a frame it cannot authenticate; a frontend whose token is wrong
is refused at the handshake and gets no object.  It is a second check on top of
TLS, not a replacement for it.  A unix socket takes none -- its mode 0600 file
already decides who may connect -- and C<new> dies if one is given.  Prefer
C<token_file>; a secret passed as C<token> is visible to anything that can read
this process's memory or command line.  Give one or the other: C<new> dies if
both are given.

=item autostart

True by default.  When false, a missing unix backend is an error.

=item timeout

Seconds to wait for a backend that is being started, for a TCP connect, and for
the backend's answer to the first two requests (the handshake and the request
for an object).  The backend serves one request at a time, so a backend that is
busy running another client's method answers late; when it takes longer than
this, C<new> dies with the reason instead of waiting without end.  Default 10.
It does not limit how long a later method call may take.

=item log

Where a backend started by this frontend should write.  Defaults to the socket
path with C<.log> appended.

=back

=head1 METHODS

The schemas in each B<API SPECIFICATION> follow the conventions of
L<Params::Validate::Strict> (for input) and L<Return::Set> (for output).  They
describe the method for people and for tools.  The code does not call those
modules, and this distribution does not depend on them.

=head2 new

    my $frontend = Class::Shared::Frontend->new('Class::Simple', %options);
    my $frontend = Class::Shared::Frontend->new('Class::Simple', \%options);
    my $frontend = Class::Shared::Frontend->new(class => 'Class::Simple', %options);

Connects to a backend (starting one for a unix socket if there is none and
C<autostart> is true), and asks it to build one object.  Returns the frontend.
Every option is described in L</OPTIONS>.

The class name may be the first argument or the C<class> option.  The options
may be a list of pairs or one hash reference.

B<Side effects:> opens a connection.  It may fork and start a backend process.
It may create the socket directory (mode 0700) and a lock file, and it may
write the backend's log.

B<Dies> (with the reason) if an option is unknown or wrong, if no backend can be
reached or started, if the handshake is refused, or if the target's C<new>
dies.  No object is returned in these cases.

It also refuses to connect to a unix socket that is not the user's own: one
whose directory is owned by someone else or can be written to by group or
others, or that is not a socket or is owned by someone else.  Such a socket
could answer every call with whatever it liked, and would be told every
argument.  The reason begins "will not connect to".  The same rule applies to
C<class-shared status> and C<class-shared stop>.

=head3 API SPECIFICATION

=head4 Input

    {
        class           => { type => 'string', position => 0, optional => 0,
                             matches => qr/\A[A-Za-z_][A-Za-z0-9_]*(?:::[A-Za-z_][A-Za-z0-9_]*)*\z/ },
        ctor            => { type => 'arrayref', optional => 1 },
        dir             => { type => 'string',   optional => 1, min => 1 },
        socket          => { type => 'string',   optional => 1, min => 1, max => 100 },
        host            => { type => 'string',   optional => 1, min => 1 },
        port            => { type => 'integer',  optional => 1, min => 1, max => 65535 },
        token           => { type => 'string',   optional => 1, matches => qr/\A[\x20-\x7E]+\z/ },
        token_file      => { type => 'string',   optional => 1, min => 1 },
        autostart       => { type => 'boolean',  optional => 1 },
        timeout         => { type => 'number',   optional => 1, min => 0 },
        log             => { type => 'string',   optional => 1, min => 1 },
        tls_cert        => { type => 'string',   optional => 1, min => 1 },
        tls_key         => { type => 'string',   optional => 1, min => 1 },
        tls_ca          => { type => 'string',   optional => 1, min => 1 },
        tls_fingerprint => { type => 'string',   optional => 1 },
    }

=head4 Domains

    The options are checked before a connection is made, so every partition
    below is refused without contacting a backend.

    partition                        representative              result
    -------------------------------------------------------------------------
    unknown option                    bogus => 1                  dies
    odd number of arguments           "odd"                       dies
    no class                          ()                          dies
    invalid class name                2Bad, Foo::, M + U+00FC     dies
    ctor not an array reference       ctor => "x"                 dies
    unix socket with a token          token => "s"                dies
    unix socket with TLS              tls_ca => "ca.pem"          dies
    token and token file together     token, token_file           dies
    host without port                 host => "h"                 dies
    port without host                 port => 1                   dies
    socket with host and port         socket, host, port          dies
    TCP without certificate or key    host, port                  dies
    TCP with both a CA and a pin      tls_ca, tls_fingerprint     dies

    Port boundary values, with a host present: 1 and 65535 are accepted and
    validation passes to the next option; 0, 65536, -1, "", "80x", " 80" and
    "80.0" die.  A port is a whole number, so "0080" is accepted as 80.  A
    missing host or port is reported before the port is range checked.  The
    class name follows L<Class::Shared/validate_class>, and ctor must be an
    array reference.

    A valid unix frontend needs only a class name; a valid TCP frontend needs
    host, port, tls_cert, tls_key and exactly one of tls_ca and
    tls_fingerprint.  Those partitions connect, so they are covered by
    F<t/02-frontend.t>; the refusals above are covered by F<t/domain.t>.

=head4 Output

    { type => 'object', isa => 'Class::Shared::Frontend' }

=head2 AUTOLOAD (any method of the target)

    my $answer  = $frontend->any_method(@args);
    my @answers = $frontend->any_method(@args);
               $frontend->any_method(@args);

Any method name that the frontend does not define itself is sent to the
backend, applied to this frontend's object, and the result is returned.  The
calling context is kept: in list context all the values come back, in scalar
context the scalar comes back, and in void context nothing does.

An exception thrown by the target is thrown again here with its original text.

B<Side effects:> one round trip to the backend, and whatever the target method
does there.  The call waits for as long as the method takes; there is no time
limit.

B<Dies> if the target dies, if the target has no such method, if the object has
been released, or if the connection is lost.

A method name is a plain name: letters, digits and underscores, not starting
with a digit.  A name with a package in it (C<Other::function>, C<SUPER::new>)
is refused by the backend, because it would call that function with the object
as its first argument instead of a method of the object's class.

=head3 API SPECIFICATION

=head4 Input

    {
        method => { type => 'string', description => 'the name you called' },
        args   => { type => 'arrayref', description => 'plain data only (Storable can freeze it)' },
    }

=head4 Output

    {
        type        => 'any',
        description => 'whatever the target method returns, in the context you called it in',
    }

=head2 shared_call

    my @result = $frontend->shared_call('method_name', @args);

Calls a method of the target by name.  Use it when the target's method has the
same name as one of the frontend's own methods (C<shared_pid>, C<can>, C<isa>,
and so on), because a direct call would reach the frontend's version instead.
It keeps the calling context.

The backend refuses C<new>, C<DESTROY> and C<AUTOLOAD>.

B<Side effects:> as for any forwarded method.

B<Dies> if the method name is missing or empty, and in the same cases as a
forwarded method.

=head3 API SPECIFICATION

=head4 Input

    {
        method => { type => 'string', position => 0, optional => 0, min => 1 },
        args   => { type => 'arrayref', position => 1, optional => 1 },
    }

=head4 Output

    { type => 'any' }

=head2 shared_class

    my $class = $frontend->shared_class;

The name of the target class, such as C<Class::Simple>.  Never fails.

=head3 API SPECIFICATION

=head4 Input

    { }

=head4 Output

    { type => 'string', min => 1 }

=head2 shared_address

    my $where = $frontend->shared_address;

The place this frontend connects to: the socket path for a unix backend, or
C<host:port> for a TCP backend.

=head3 API SPECIFICATION

=head4 Input

    { }

=head4 Output

    { type => 'string', min => 1 }

=head2 shared_socket_path

    my $path = $frontend->shared_socket_path;

The unix socket path, or undef when the backend is on TCP.

=head3 API SPECIFICATION

=head4 Input

    { }

=head4 Output

    { type => 'string', optional => 1, description => 'undef for a TCP backend' }

=head2 shared_pid

    my $pid = $frontend->shared_pid;

The process id of the backend.  It is undef after the connection is closed.

=head3 API SPECIFICATION

=head4 Input

    { }

=head4 Output

    { type => 'integer', optional => 1, min => 1 }

=head2 shared_id

    my $id = $frontend->shared_id;

This object's number inside the backend.  It is undef after the connection is
closed.  The number is only meaningful to that backend.

=head3 API SPECIFICATION

=head4 Input

    { }

=head4 Output

    { type => 'integer', optional => 1, min => 1 }

=head2 shared_connected

    if ($frontend->shared_connected) { ... }

Returns 1 while the connection is open and 0 after it has been closed or lost.
It does not test the connection; it only reports what this frontend last
knew.  A backend that has died is noticed on the next call.

=head3 API SPECIFICATION

=head4 Input

    { }

=head4 Output

    { type => 'integer', memberof => [0, 1] }

=head2 shared_last_error

    my $why = $frontend->shared_last_error;

Why the last connection attempt, or the last lost connection, failed.  Undef if
there has been no problem.  A message is kept until something replaces it.

=head3 API SPECIFICATION

=head4 Input

    { }

=head4 Output

    { type => 'string', optional => 1 }

=head2 shared_status

    my $status = $frontend->shared_status;
    print "$status->{objects} objects, up $status->{uptime} seconds\n";

Asks the backend how it is, and returns its answer as a hash reference.  The
keys are:

=over 4

=item C<ok>

1 when the backend answered.

=item C<classes>

An array reference: the names of the classes the backend has loaded, sorted.

=item C<objects>

How many objects it holds now, for all clients.

=item C<constructed>

How many objects it has built since it started.

=item C<clients>

How many connections it has now.

=item C<calls>

How many method calls it has run.

=item C<queued>, C<max_queued_total>

The bytes waiting to be written to all clients, and the ceiling for that.

=item C<pid>, C<version>, C<proto>

The backend's process id, the version of the distribution, and the protocol
version.

=item C<address>

Where it is listening.

=item C<started>, C<uptime>

When it started (seconds since the epoch) and how long it has run (seconds).

=back

B<Side effects:> one round trip.

B<Dies> if the connection is closed or lost.

=head3 API SPECIFICATION

=head4 Input

    { }

=head4 Output

    {
        type   => 'hashref',
        schema => {
            ok               => { type => 'integer', memberof => [1] },
            classes          => { type => 'arrayref' },
            objects          => { type => 'integer', min => 0 },
            constructed      => { type => 'integer', min => 0 },
            clients          => { type => 'integer', min => 0 },
            calls            => { type => 'integer', min => 0 },
            queued           => { type => 'integer', min => 0 },
            max_queued_total => { type => 'integer', min => 0 },
            pid              => { type => 'integer', min => 1 },
            version          => { type => 'string' },
            proto            => { type => 'integer', min => 1 },
            address          => { type => 'string' },
            started          => { type => 'integer', min => 0 },
            uptime           => { type => 'integer', min => 0 },
        },
    }

=head2 shared_close

    $frontend->shared_close;

Closes the connection and gives up the object.  The backend then destroys the
object, and the target's C<DESTROY> runs there.  Any later call on this frontend
dies.  It is safe to call twice.

This also happens by itself when the frontend goes out of scope or the program
ends.

Returns 1 if it closed an open connection, and 0 if there was none.

B<Side effects:> closes the socket.  If the close itself fails, a warning is
given with C<carp>; the frontend is still unusable afterwards.

=head3 API SPECIFICATION

=head4 Input

    { }

=head4 Output

    { type => 'integer', memberof => [0, 1] }

=head2 shared_shutdown

    $frontend->shared_shutdown;

Asks the whole backend to stop.  This destroys every object it holds, B<including
other clients' objects>, so it is for administration and for tests, not for
normal use.  The frontend is closed.  For a unix backend it then waits (up to 5
seconds) for the socket file to go away.

Returns 1 if the backend said it would stop, 0 otherwise (including when there
was no connection).

B<Side effects:> stops the backend process.

B<Dies> if the request cannot be completed, after closing the frontend.

=head3 API SPECIFICATION

=head4 Input

    { }

=head4 Output

    { type => 'integer', memberof => [0, 1] }

=head2 can

    my $code = $frontend->can('method_name');
    $code->($frontend, @args) if $code;

Says whether the target has a method of that name.  For the frontend's own
methods (such as C<shared_call>) it answers by itself.  For other names it asks
the backend.  If the answer is yes, it returns a code reference you can call;
the reference sends the call to the backend.  If the answer is no, or the
backend cannot be asked, it returns undef.

Called on the class name instead of an object (C<< Class::Shared::Frontend->can(...) >>)
it behaves as Perl's usual C<can>.

=head3 API SPECIFICATION

=head4 Input

    { method => { type => 'string', position => 0, optional => 0, min => 1 } }

=head4 Output

    { type => 'coderef', optional => 1, description => 'undef when the method does not exist' }

=head2 isa

    if ($frontend->isa('Class::Base')) { ... }

Says whether the target is, or inherits from, the named class.  It is always true
for C<Class::Shared::Frontend> and C<UNIVERSAL>.  Other names are put to the
backend.  It returns 1 or 0.

=head3 API SPECIFICATION

=head4 Input

    { class => { type => 'string', position => 0, optional => 0, min => 1 } }

=head4 Output

    { type => 'integer', memberof => [0, 1] }

=head2 DESTROY

Called by Perl when the frontend goes away.  It closes the connection, so the
backend destroys the object.  You do not call it yourself.

=head1 ERRORS

A call dies if the target dies, if the method does not exist, if the object has
been released, or if the connection is lost.  A lost connection is never
silently replaced by a new object, because that would throw away the state the
caller thought it had.

The messages you are most likely to see, and what to do:

=over 4

=item C<Class::Shared::Frontend-E<gt>new: unknown option 'NAME'>

You spelled an option wrong.  Check L</OPTIONS>.

=item C<Class::Shared::Frontend-E<gt>new: a unix socket needs no token ...> (or C<no TLS>)

You gave C<token>, C<token_file> or a C<tls_*> option without C<host> and
C<port>.  Remove them: a unix socket does not use them.

=item C<Class::Shared::Frontend-E<gt>new: give token or token_file, not both>

Both options name the same secret.  Remove one of them.

=item C<Class::Shared::Frontend-E<gt>new: port must be a whole number from 1 to 65535>

The C<port> given with C<host> is not a number in that range.  Correct it.

=item C<Class::Shared: cannot reach a backend at ADDRESS: REASON>

Nothing is listening and a backend was not started, because C<autostart> is off
or the backend is on TCP.  Start the backend with C<class-shared start>.

=item C<Class::Shared: could not start a backend: REASON (socket PATH, log PATH)>

The automatic start failed.  Read the log file named in the message.

When C<REASON> begins C<a backend is running at PATH but did not answer>, nothing
was started or removed: the backend is there, usually busy running another
client's method.  Try again, or raise C<timeout>.

=item C<Class::Shared: cannot load CLASS: ERROR>

The backend could not find or compile the class.  The text after the colon is
Perl's own message, for example C<Can't locate Class/Simple.pm in @INC>.  Check
the spelling, and check that the backend can see the directory that holds the
class (see L</COMMON PITFALLS>).

=item C<Class::Shared: could not construct CLASS: ERROR>

The class loaded, but the target's C<new> died.  The text after the colon is the
target's own message.

=item C<Class::Shared: lost the backend for 'CLASS': REASON>

The connection broke, or a request could not be sent.  The frontend is closed.
Make a new one.

=item C<Class::Shared: this frontend has no connection to a backend ...; its object is gone>

You called a method after C<shared_close>, or after the connection was lost.

=item C<Class::Shared: socket path 'PATH' is N characters, more than the 100 allowed ...>

The C<socket> (or the default directory) makes a path that is too long.  Use a
shorter one.

=back

=head1 ENCODING

=over 4

=item Arguments, constructor arguments, results and error text: full Unicode.

They are sent with L<Storable>, which keeps strings unchanged.  Accented
letters, Chinese, Arabic and emoji all arrive intact, and so does the difference
between a byte string and a character string.  This was checked with
C<"caf\x{e9}">, C<"\x{1F600}"> and Japanese text, including in an exception
message and in C<ctor>.  Decode input before sending it, and encode it when you
print it.

=item Class names: ASCII only.

Letters A to Z, digits and underscores, with C<::> between the words.

=item Method names: use ASCII.

=item C<token> and the file named by C<token_file>: ASCII only.

A token with an accented letter is different as a string and as the bytes of a
file, and a character above code point 255 cannot be used at all.  The two
ends would disagree and the connection would be refused.

=item C<dir>, C<socket>, C<log> and the C<tls_*> files: ASCII is safest.

They are given to the operating system as they are.  The 100 character limit on
a socket path counts characters, not bytes.

=item C<tls_fingerprint>: hexadecimal digits, with optional colons.

=back

=head1 COMMON PITFALLS

=over 4

=item C<new> is the frontend's, not the target's.

To pass arguments to the target's constructor, use C<ctor>.  You cannot call the
target's C<new> through the frontend; the backend refuses.

=item C<ctor> is used once.

It is read when the object is built.  Changing the array afterwards does
nothing.  Every element must be plain data.

=item Only plain data can be an argument or a return value.

Strings, numbers, C<undef>, and array and hash references of those.  A code
reference, a file handle or a tied object cannot be sent.  If you try, the call
fails with "lost the backend ... cannot serialise message", B<and the frontend is
closed>, so the object is gone.  A method that returns an object also cannot be
used: the object stays in the backend.

=item Method names that clash with the frontend's own.

C<new>, C<can>, C<isa>, C<DESTROY> and every name that starts with C<shared_>
belong to the frontend.  Reach the target's method of that name with
C<shared_call>.

=item C<timeout> does not limit a method call.

It limits starting a backend, making a TCP connection, and waiting for the
answers to the handshake and to the request for an object.  A later call waits
for as long as the target takes, and for ever if the backend hangs.

=item Do not use one frontend from two processes.

After a C<fork>, the parent and the child hold the same connection, and if both
use it their requests and replies can be mixed up.  Make a new frontend in the
child.  The same goes for threads.

=item A lost connection means a lost object.

The frontend does not reconnect, because a new object would have none of the old
state.  Make a new frontend and set it up again.

=item The backend sees the C<@INC> of the process that started it.

A backend started automatically searches for classes in the directories that
C<@INC> held when it was started.  A later client that has added a directory
(C<use lib>) will get "cannot load ... Can't locate ..." if the target class
lives only there.  Start the backend yourself with the right C<-I>, or make sure
the first client has the full C<@INC>.

=item The class's package variables are shared.

All clients of one class share its package variables and any class data, because
the class is loaded once.  Keep state in the object.

=item A slow method delays every client.

The backend does one thing at a time.

=item A list is not a count.

C<my $n = $frontend-E<gt>items> calls the method in scalar context, exactly as
Perl would.  A method that returns a list gives its last value there.

=item C<undef> in list context is one value.

A method that returns C<undef> in list context gives a list with one element.

=item C<shared_shutdown> is not C<shared_close>.

C<shared_close> gives up your object.  C<shared_shutdown> stops the backend for
everybody.

=item A unix socket takes no token and no TLS.

Giving one is an error, on purpose, so that it never looks like extra
protection.

=back

=head1 SEE ALSO

L<Class::Shared>, L<Class::Shared::Backend>, L<Class::Shared::Protocol>,
L<class-shared>.

=head1 AUTHOR

Nigel Horne

=head1 FORMAL SPECIFICATION

This section describes what each method does in the Z notation, a way of
writing exactly what a program promises using sets and logic.  You do not need
it to use the module.  Read the plain text above first.

Z uses mathematical symbols, so this is the only part of the file that is not
plain ASCII.  A short key:

    x? input      x! output      x' the value of x after the operation
    =>  implies   /\  and        \/  or        ~  not
    ⊥  undef (no value)          ⊕  update a function    ↦  maps to

=head2 State

    ┌─ Frontend ──────────────────────────────────────────────
    │ class     : CLASSNAME
    │ conn      : {open, closed}
    │ id        : ℕ₁ ∪ {⊥}          the object's number in the backend
    │ pid       : ℕ₁ ∪ {⊥}          the backend's process id
    │ last_error: STRING ∪ {⊥}
    ├─────────────────────────────────────────────────────────
    │ conn = open ⇔ id ≠ ⊥ ∧ pid ≠ ⊥        (an open frontend always has an object)
    │ conn = closed ⇒ id = ⊥ ∧ pid = ⊥
    └─────────────────────────────────────────────────────────

The backend is described in L<Class::Shared::Backend/FORMAL SPECIFICATION>.  Here
B<objects> is the backend's partial function from ids to objects.

=head2 new

    ┌─ New ───────────────────────────────────────────────────
    │ ΔFrontend ; opts? : OPTIONS ; objects, objects' : ℕ₁ ⇸ OBJECT
    ├─────────────────────────────────────────────────────────
    │ opts? valid ∧ backend reachable (or started, if unix and autostart) ∧ target new succeeds
    │     ⇒ conn' = open ∧ id' ∉ dom objects ∧ objects' = objects ⊕ {id' ↦ o}
    │ any other case ⇒ new dies, and no Frontend exists
    └─────────────────────────────────────────────────────────

=head2 AUTOLOAD (forwarded methods) and shared_call

    ┌─ Forward ───────────────────────────────────────────────
    │ ΞFrontend ∨ ΔFrontend ; m? : STRING ; args? : seq DATA ; ctx? : {list, scalar, void}
    │ out! : RESULT[seq DATA]
    ├─────────────────────────────────────────────────────────
    │ conn = open ∧ args? serialisable ∧ target method m? exists
    │     ∧ the call returns r in context ctx?
    │     ⇒ out! = value(shape(ctx?, r)) ∧ conn' = open        shape: list->r, scalar->⟨r(0)⟩, void->⟨⟩
    │ conn = open ∧ the target method dies with e ⇒ out! = dies(e) ∧ conn' = open
    │ conn = open ∧ args? not serialisable ⇒ out! = dies(e) ∧ conn' = closed ∧ id' = ⊥
    │ connection breaks ⇒ out! = dies(e) ∧ conn' = closed ∧ id' = ⊥
    │ conn = closed ⇒ out! = dies("no connection ... its object is gone")
    └─────────────────────────────────────────────────────────

=head2 shared_close

    ┌─ SharedClose ───────────────────────────────────────────
    │ ΔFrontend ; objects, objects' : ℕ₁ ⇸ OBJECT ; out! : {0, 1}
    ├─────────────────────────────────────────────────────────
    │ conn = open ⇒ conn' = closed ∧ id' = ⊥ ∧ pid' = ⊥ ∧ out! = 1
    │               ∧ objects' = {id} ⩤ objects              the backend destroys it
    │ conn = closed ⇒ ΞFrontend ∧ out! = 0
    └─────────────────────────────────────────────────────────

=head2 shared_shutdown

    ┌─ SharedShutdown ────────────────────────────────────────
    │ ΔFrontend ; out! : {0, 1}
    ├─────────────────────────────────────────────────────────
    │ conn = closed ⇒ ΞFrontend ∧ out! = 0
    │ conn = open ∧ backend accepts ⇒ conn' = closed ∧ out! = 1 ∧ the backend stops
    │                                 ∧ objects' = ∅          every client's object
    │ conn = open ∧ request fails ⇒ conn' = closed ∧ it dies
    └─────────────────────────────────────────────────────────

=head2 shared_status

    ┌─ SharedStatus ──────────────────────────────────────────
    │ ΞFrontend ; out! : RESULT[STATUS]
    ├─────────────────────────────────────────────────────────
    │ conn = open ⇒ out! = value(s) ∧ s.objects = #objects ∧ s.classes = loaded classes
    │ conn = closed ∨ connection breaks ⇒ out! = dies(e)
    └─────────────────────────────────────────────────────────

=head2 can

    ┌─ Can ───────────────────────────────────────────────────
    │ ΞFrontend ; m? : STRING ; out! : CODE ∪ {⊥}
    ├─────────────────────────────────────────────────────────
    │ m? ∈ methods(Class::Shared::Frontend)    ⇒ out! ≠ ⊥          answered here
    │ conn = open ∧ m? ∈ methods(class)        ⇒ out! ≠ ⊥          the code ref forwards the call
    │ otherwise (including a broken connection) ⇒ out! = ⊥
    └─────────────────────────────────────────────────────────

=head2 isa

    ┌─ Isa ───────────────────────────────────────────────────
    │ ΞFrontend ; c? : STRING ; out! : {0, 1}
    ├─────────────────────────────────────────────────────────
    │ c? ∈ {"Class::Shared::Frontend", "UNIVERSAL"} ⇒ out! = 1
    │ conn = open ∧ class isa c?                    ⇒ out! = 1
    │ otherwise                                      ⇒ out! = 0
    └─────────────────────────────────────────────────────────

=head2 Accessors

    ┌─ Accessors ─────────────────────────────────────────────
    │ ΞFrontend
    ├─────────────────────────────────────────────────────────
    │ shared_class! = class          shared_id! = id           shared_pid! = pid
    │ shared_connected! = 1 if conn = open, else 0
    │ shared_last_error! = last_error
    └─────────────────────────────────────────────────────────

=head1 STATE DIAGRAM

A frontend is made by C<new>.  C<new> either returns a frontend that is already
BOUND, or it dies.  So the first diagram is what happens inside C<new>, and the
second is the life of the frontend you get back.

Inside C<new>:

              +------------+  backend answers  +------------+  object built  +-------+
    new() --> | CONNECTING | ----------------> | HANDSHAKEN | -------------> | BOUND |--> new() returns
              +------------+                   +------------+                +-------+
                 |                                  ^    |
      nothing    |                                  |    | refused, or the
      answers    v        a backend answers         |    | target's new() dies
              +-----------+ ------------------------+    |
              | SPAWNING  |                               |
              +-----------+                               |
                    |                                     |
                    | no answer in time, or the           |
                    | fork or the directory fails         |
                    v                                     v
              +-------------------------------------------+
              | FAILED: new() dies, no object is returned |
              +-------------------------------------------+

After C<new> returns:

              +-- forwarded call, shared_call, shared_status, can, isa,
              |   or an accessor: no change.  (A target exception also
              v   leaves the state as it is.)
          +---------+   shared_close, shared_shutdown, DESTROY,    +--------+
          |  BOUND  | -------------------------------------------> | CLOSED |
          +---------+   connection lost, or an argument can't be   +--------+
                        sent (the frontend closes itself)             |   ^
                                                                      +---+
                                           any call on a closed frontend dies

=over 4

=item CONNECTING to HANDSHAKEN

Trigger: C<new>; the backend answers the C<hello> message.  Action: the
frontend stores the backend's pid.

=item CONNECTING to SPAWNING

Trigger: nothing answers, the transport is a unix socket and C<autostart> is
true.  Action: take a lock file, make sure the directory is safe, remove a
leftover socket, fork a backend and wait.  A socket is leftover only if no
backend holds the lock on the file named by the socket path plus C<.owner>.  A
backend that holds it but does not answer is waited for, and nothing of its is
removed.

=item SPAWNING to HANDSHAKEN

Trigger: the new backend answers the C<hello> message.  Action: the lock is
released and the frontend stores the backend's pid.

=item SPAWNING to FAILED

Trigger: the directory is unsafe, the fork fails, or no backend answers within
C<timeout> seconds.  Action: C<new> dies with C<could not start a backend>.

=item HANDSHAKEN to BOUND

Trigger: the backend builds the object.  Action: the frontend stores the object
id.  C<new> returns.

=item HANDSHAKEN to FAILED

Trigger: the handshake is refused, or the target's C<new> dies.  Action: the
connection is closed and C<new> dies.

=item BOUND to BOUND

Trigger: a forwarded call, C<shared_call>, C<shared_status>, C<can>, C<isa> or an
accessor.  Action: a round trip, or a local answer.  An exception thrown by the
target does not change the state.

=item BOUND to CLOSED, by error

Trigger: the connection breaks, or an argument cannot be serialised.  Action:
the frontend closes itself, records C<last_error> and the call dies.

=item BOUND to CLOSED, on purpose

Trigger: C<shared_close>, C<shared_shutdown> or C<DESTROY>.  Action: the socket
is closed and the backend destroys the object (or, for C<shared_shutdown>, stops
and destroys every object).

=back

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License, version 2, as published by the
Free Software Foundation.

This module is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.  See the F<LICENSE> file for the full text.

=cut
