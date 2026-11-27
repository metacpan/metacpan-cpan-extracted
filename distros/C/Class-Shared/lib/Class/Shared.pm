package Class::Shared;

use strict;
use warnings;

use File::Basename ();
use File::Spec ();

# version->declare here alone: this is VERSION_FROM, and with it MakeMaker
# writes 0.001.0 into META; a plain dotted string becomes v0.001.0 there.
use version; our $VERSION = version->declare('0.001.0');

# Bumped whenever the wire protocol changes in an incompatible way.  2 added
# the HMAC-SHA-256 digest every frame carries when a token is in use.
our $PROTOCOL_VERSION = 2;

# Longest unix(7) path we are prepared to generate.  The kernel limit is
# 107 characters plus the terminator; leaving headroom keeps us portable.
our $MAX_SOCKET_PATH = 100;

# How often the loops that wait for a socket or a lock look again, in seconds.
# One value, so every wait in the distribution polls at the same rate.
our $POLL_INTERVAL = 0.02;

# Why a unix socket takes neither a token nor TLS.  It is quoted by the backend,
# the frontend and the command line, so they cannot word it differently.
our $UNIX_TRUST_REASON = 'its mode 0600 file already decides who may connect';

# The protocol versions a TLS connection may use, in IO::Socket::SSL's own
# notation: TLS 1.2 and later.  SSL 2 and 3 and TLS 1.0 and 1.1 are broken or
# deprecated (RFC 8996), and left to its defaults the library would still
# offer them to a peer that asked.  Used by both ends so that they agree.
our $TLS_VERSIONS = 'SSLv23:!SSLv3:!SSLv2:!TLSv1:!TLSv1_1';

# Parts of a class name are joined by "::".  The characters of a part never
# include ":", so a part can only end where "::" or the end begins, and there
# is only one way to match any name.
#
# The name is checked in two flat steps, not by one pattern that repeats a
# group once per part: perl 5.26 stops a repeated group at 32766 repeats
# ("Complex regular subexpression recursion limit"), so a long but valid
# name would die there.  Step one matches only the allowed characters, and its
# capture is what is returned, so it is untainted.  Step two checks each part.
# The classes are written out, not \w, so that no non-ASCII letter is accepted.
my $CLASS_CHARS_RE = qr/ \A ( [A-Za-z0-9_:]++ ) \z /x;
my $CLASS_PART_RE  = qr/ \A [A-Za-z_] [A-Za-z0-9_]*+ \z /x;

=head1 NAME

Class::Shared - Keep one instance of a class and let other processes call it

=head1 SYNOPSIS

The usual way to use this distribution is through L<Class::Shared::Frontend>.
Each example below is a different real-world pattern.

    # 1. The simplest case: share one class between many processes.
    use Class::Shared::Frontend;

    my $simple = Class::Shared::Frontend->new('Class::Simple');

    $simple->foo('hello');          # runs in the shared backend
    print $simple->foo(), "\n";     # prints "hello"

    # 2. Give the class its constructor arguments.  They are used once, when
    #    the object is made, and must be plain data (no code references).
    my $logger = Class::Shared::Frontend->new('My::Logger',
        ctor => [ level => 'debug', file => '/var/log/app.log' ],
    );

    my @all = $logger->lines();     # list context is kept
    my $n   = $logger->lines();     # scalar context is kept too

    # 3. Use a backend on another machine, over TLS with client certificates.
    my $remote = Class::Shared::Frontend->new('Class::Simple',
        host       => 'classhost.example.com',
        port       => 7000,
        tls_ca     => 'ca.pem',
        tls_cert   => 'client.pem',
        tls_key    => 'client-key.pem',
        token_file => '/etc/class-shared/token',
    );

    # 4. Look after the backend yourself, from the shell.
    #      class-shared start        # start it in the background
    #      class-shared status       # ask what it is doing
    #      class-shared stop         # ask it to stop

    # 5. Use the helper functions to write your own client.
    use Class::Shared ();

    my $dir = Class::Shared::default_dir();
    my ($ok, $why) = Class::Shared::ensure_dir($dir);
    die "cannot use $dir: $why" unless $ok;

    my $socket = Class::Shared::socket_path($dir);

=head1 DESCRIPTION

Perl has no equivalent of a shared library for classes: every process loads
its own copy of F<Class/Simple.pm>, runs its own constructors and keeps its
own state.  For a large class used by many short lived processes that is a lot
of memory and a lot of start up time.

Class::Shared moves the code into one process and lets the others keep a small
proxy: a L<Class::Shared::Frontend> standing in for one object, held by a
L<Class::Shared::Backend> that loaded the class once and does the work.

    client process            singleton backend process
    --------------            -------------------------
    Frontend (object #1)  --socket-->  Class::Shared::Backend
    Frontend (object #2)  --socket-->  |-- Class::Simple (code, loaded once)
    Frontend (object #3)  --socket-->  |-- object #1
                                       |-- object #2
                                       `-- object #3

So there is one copy of the class in the system and as many objects as there are
frontends: C<< Class::Shared::Frontend->new('Class::Simple', ...) >> is one call
to C<< Class::Simple->new(...) >>, in the backend.

The arguments for that constructor go in C<ctor>, as an array reference:
C<ctor =E<gt> [verbose =E<gt> 1]> is
C<< Class::Simple->new(verbose =E<gt> 1) >>.  They are used once, when the
frontend connects and asks the backend for the object, and they travel over the
socket, so they must be plain data -- a code reference cannot be sent.  If the
constructor dies, the frontend's C<new> dies too, naming the class and the error
the backend reported.

L<Class::Shared::Frontend> lists every option this constructor takes.

The frontend never loads the target class, so it stays cheap.  An object lives
as long as the connection that made it; when the frontend goes, the backend
destroys the object, so its C<DESTROY> runs once, in the backend.

One backend serves every class its clients ask for.  A client names the class it
wants in its first message, the handshake, and the backend loads that module
then, once per class, however many clients ask for it.  The backend may be on
this machine (a unix socket, see C<Class::Shared::default_dir>) or on another
one (TCP).

Class::Shared is for Unix-like systems: unix sockets, POSIX directory
permissions and C<fork> are what make a backend reachable, private and
startable.  See L</PLATFORMS>.

This page documents the helper functions that the frontend, the backend and the
command line program share.  Start with L<Class::Shared::Frontend> if you only
want to use a shared class.

=head2 Words used in this documentation

=over 4

=item backend

The one process that loads the class and holds the real objects.

=item frontend

The small stand-in object in your own process.  It forwards each method call to
the backend and gives you back the answer.

=item unix socket

A special file that two programs on the same machine use to talk to each other.
Its file permissions decide who may connect.

=item TCP

The way programs on different machines talk to each other over a network.  Here
it is always protected by TLS.

=item TLS

Encryption for a network connection.  Each side also shows a certificate to
prove who it is.

=item certificate, CA

A certificate is a small file that says "this key belongs to this name".  A CA
(certificate authority) is the organisation, or your own private key pair, that
signs certificates so others can trust them.

=item fingerprint

A short code (SHA-256) that identifies exactly one certificate.  A client can
trust one certificate by its fingerprint instead of trusting a CA.

=item token

A shared secret, kept in a file, that both sides of a TCP connection know.  It
proves that each message came from somebody who has the secret.

=item frame

One message on the wire: a length, then the data.  See
L<Class::Shared::Protocol>.

=item handshake

The first message a client sends.  It names the class the client wants.

=item context

Perl's idea of what the caller wants back from a call: a list, one value, or
nothing (void).  Class::Shared keeps the context you used.

=back

=head1 FUNCTIONS

None is exported.  They are used by the frontend and the backend, and may be
useful when writing your own client.  Call each one with its full name, for
example C<Class::Shared::validate_class($name)>.

A function either returns its answer or, when it cannot, dies with a message
that begins C<Class::Shared:> and ends with a new line.  The one exception is
C<ensure_dir>, which returns a pair so that the reason can be shown to the user.

The schemas in each B<API SPECIFICATION> follow the conventions of
L<Params::Validate::Strict> (for input) and L<Return::Set> (for output).  They
describe the function for people and for tools.  The code does not call those
two modules, and this distribution does not depend on them.

=head2 validate_class

    my $class = Class::Shared::validate_class($class);

Checks that C<$class> looks like a Perl package name, and returns it unchanged.
Use it before you pass a name to C<require> or build a file name from it.

A valid name is one or more words joined by C<::>.  Each word starts with an
English letter or an underscore and then has letters, digits or underscores.
So C<Class::Simple> and C<My_Class2> are valid, and C<2Bad>, C<Foo::> and
C<Foo-Bar> are not.

B<Side effects:> none.

B<Dies> with C<Class::Shared: no class name given> if C<$class> is undef or
empty, and with C<Class::Shared: 'NAME' is not a valid class name> otherwise.
The domains and boundaries these two messages divide are listed under
B<API SPECIFICATION> below, and F<t/domain.t> tests every one of them.

=head3 API SPECIFICATION

=head4 Input

    {
        class => {
            type     => 'string',
            position => 0,
            optional => 0,
            min      => 1,
            matches  => qr/\A[A-Za-z_][A-Za-z0-9_]*(?:::[A-Za-z_][A-Za-z0-9_]*)*\z/,
        },
    }

=head4 Domains

    valid    one or more ASCII words, each starting with a letter or "_" and
             continuing with letters, digits or "_", joined by "::"
    invalid  undef, the empty string, a leading digit in any word, an empty
             word, any other separator, any non-ASCII character

    partition                representative           result
    -------------------------------------------------------------
    one word                 Foo                      accepted
    several words            Foo::Bar::Baz            accepted
    digits and underscores   My_Class2, A::_2         accepted
    length 1                 A, _                     accepted
    empty string             ""                       dies: no class name
    leading digit            2Foo                     dies
    empty word               Foo::, ::Foo, A:::B      dies
    hyphen, space or dot     Foo-Bar, Foo Bar         dies
    non-ASCII letter         "M" + U+00FC + "ller"    dies
    emoji, RTL override      U+1F600, U+202E          dies

    Boundary values: length 0 dies, length 1 is the smallest accepted.  There
    is no maximum: a 40,000 character name is accepted, because the check does
    not repeat a group (perl 5.26 stops a repeated group at 32,766 repeats).
    Only the pattern in this specification can match, so the answer is
    untainted and safe to use as a module name.

=head4 Output

    { type => 'string', matches => qr/\A[A-Za-z_][A-Za-z0-9_]*(?:::[A-Za-z_][A-Za-z0-9_]*)*\z/ }

=cut

sub validate_class {
	my $class = $_[0];

	die "Class::Shared: no class name given\n"
		unless defined $class && length $class;

	# The captured copy is returned, not the argument: it is the only text that
	# has been matched against the pattern, so under taint mode (-T) it is
	# untainted by the check that proves it safe.
	my ($valid) = $class =~ $CLASS_CHARS_RE
		or die "Class::Shared: '$class' is not a valid class name\n";

	# -1 keeps a trailing empty part, so "A::" and "A:::B" are refused.
	foreach my $part (split /::/, $valid, -1) {
		$part =~ $CLASS_PART_RE
			or die "Class::Shared: '$class' is not a valid class name\n";
	}

	return $valid;
}

=head2 read_secret

    my $secret = Class::Shared::read_secret('/etc/class-shared/token');

Reads a shared secret (a token) from a file and returns it.  The whole file is
read as bytes.  White space at the end, including the final new line, is
removed.  White space at the start, and any inside the secret, is kept.

Never put a secret on a command line, where other users can see it.  Give its
file name instead and let this function read it.

B<Side effects:> opens, reads and closes the file.

B<Dies> if no file name is given, if the file cannot be read, if it is larger
than 65536 bytes (which also refuses an endless file such as F</dev/zero>), or
if the secret is empty after the end of it has been trimmed.

=head3 API SPECIFICATION

=head4 Input

    {
        path => { type => 'string', position => 0, optional => 0, min => 1 },
    }

=head4 Domains

    valid    a path to a readable file whose content, after trailing white
             space is removed, is 1 to 65536 bytes
    invalid  undef, the empty path, an unreadable path, a directory, a file
             larger than 65536 bytes, and a file that is empty after trimming

    partition            representative        result
    -----------------------------------------------------------
    1 byte               "a"                   accepted
    trailing white space "secret \r\n"         trimmed
    leading white space  "  secret"            kept
    white space only     "\n\t "               dies: is empty
    0 bytes              ""                    dies: is empty
    65536 bytes          "a" x 65536           accepted
    65537 bytes          "a" x 65537           dies: too large

    Boundary values: 0 bytes dies, 1 byte is the smallest accepted, 65536
    bytes is the largest accepted, 65537 dies.  The size is counted in bytes,
    so the limit is the same for a UTF-8 or a binary secret.  The content is
    returned as bytes, unchanged and not decoded, so an embedded NUL and a
    multibyte character cost exactly what they occupy in the file.

=head4 Output

    { type => 'string', min => 1 }

=cut

# A shared secret for a backend listening on a network socket.  Never pass
# secrets on a command line: give a file and let the caller read it.
# The most read_secret accepts, in bytes.  A token is a line of text.
our $MAX_SECRET = 65536;

sub read_secret {
	my $path = $_[0];

	die "Class::Shared: no token file given\n" unless defined $path && length $path;

	open(my $fh, '<', $path) or die "Class::Shared: cannot read $path: $!\n";

	# One byte more than is allowed is asked for, and no more: a "file" such as
	# /dev/zero never ends, and reading it whole would use all the memory.
	my $secret = '';
	while (length($secret) <= $MAX_SECRET) {
		my $got = read($fh, $secret, $MAX_SECRET + 1 - length($secret), length($secret));

		# Some systems (macOS) let a directory be opened and only fail here.
		die "Class::Shared: cannot read $path: $!\n" unless defined $got;
		last unless $got;
	}

	close($fh) or die "Class::Shared: cannot read $path: $!\n";

	die "Class::Shared: $path is too large to be a secret (more than $MAX_SECRET bytes)\n"
		if length($secret) > $MAX_SECRET;

	$secret =~ s/\s+\z//;

	die "Class::Shared: $path is empty\n" unless length $secret;

	return $secret;
}

# A SHA-256 fingerprint of a certificate, in the shape IO::Socket::SSL wants
# for SSL_fingerprint.  Accepts the colon-separated form openssl prints, with
# or without a "sha256$" prefix, so a pin can be pasted straight from
# "openssl x509 -fingerprint -sha256".
my $FINGERPRINT_RE = qr{
	\A
	(?: sha256 \$ )?
	( (?:[0-9A-Fa-f]{2}:){31}[0-9A-Fa-f]{2} | [0-9A-Fa-f]{64} )
	\z
}x;

sub normalise_fingerprint {
	my $value = $_[0];

	die "Class::Shared: no TLS fingerprint given\n"
		unless defined $value && length $value;

	my ($hex) = $value =~ $FINGERPRINT_RE
		or die "Class::Shared: '$value' is not a SHA-256 certificate fingerprint: "
			. "give 64 hexadecimal digits, optionally colon-separated\n";

	$hex =~ s/://g;

	return 'sha256$' . lc $hex;
}

# The TLS options a client hands to IO::Socket::SSL->new, in one place so the
# frontend and the command line cannot drift apart about what verification
# means.  IO::Socket::SSL is loaded here rather than at the top of this module:
# a unix socket never needs any of it.
sub client_tls_options {
	my (%opt) = @_;

	require IO::Socket::SSL;

	my %tls = (
		SSL_version     => $TLS_VERSIONS,
		SSL_cert_file   => $opt{cert},
		SSL_key_file    => $opt{key},
		SSL_verify_mode => IO::Socket::SSL::SSL_VERIFY_PEER(),
	);

	if (defined $opt{fingerprint}) {
		# A pin names one exact certificate, so it stands in for both the CA
		# and the name, and SSL_force_fingerprint makes the digest the only
		# thing that can accept the peer.
		$tls{SSL_fingerprint}       = $opt{fingerprint};
		$tls{SSL_force_fingerprint} = 1;
		$tls{SSL_verifycn_scheme}   = 'none';
	} else {
		$tls{SSL_ca_file} = $opt{ca};
	}

	return %tls;
}

sub dir_of {
	my ($path) = @_;
	my $dir = File::Basename::dirname($path);
	return length $dir ? $dir : '/';
}

# Sleep for one polling interval.  Used by every loop that waits for something
# on the file system, so none of them spins and all of them wake at the same
# rate.  select is the portable sub-second sleep that needs no extra module.
sub poll_pause {
	select(undef, undef, undef, $POLL_INTERVAL);

	return;
}

# Point STDIN at the null device and STDOUT and STDERR at the log, so a
# background process holds no terminal and its diagnostics land somewhere.  If
# the log cannot be opened they go to the null device instead: a backend that
# cannot log should still run.  Returns (1, undef), or (0, $why) if a stream
# could not be reopened; the caller decides whether that is fatal, because
# this is used both by the backend and by the forked child that becomes one.
sub detach_standard_streams {
	my ($log) = @_;

	my $null = File::Spec->devnull;

	open(STDIN, '<', $null) or return (0, "cannot reopen STDIN on $null: $!");

	if (open(my $log_fh, '>>', $log)) {
		open(STDOUT, '>&', $log_fh) or return (0, "cannot send STDOUT to $log: $!");
		open(STDERR, '>&', $log_fh) or return (0, "cannot send STDERR to $log: $!");
		close($log_fh) or return (0, "cannot close $log: $!");
	} else {
		open(STDOUT, '>', $null) or return (0, "cannot send STDOUT to $null: $!");
		open(STDERR, '>&', \*STDOUT) or return (0, "cannot send STDERR to $null: $!");
	}

	return (1, undef);
}

# Where per-user sockets live.  Kept short because the path ends up in a
# sockaddr_un, and per-user because the socket is a trust boundary.
sub default_dir {
	my (%opt) = @_;

	my $dir;

	if (defined $opt{dir} && length $opt{dir}) {
		$dir = $opt{dir};
	} elsif (defined $ENV{CLASS_SHARED_DIR} && length $ENV{CLASS_SHARED_DIR}) {
		$dir = $ENV{CLASS_SHARED_DIR};
	} elsif (defined $ENV{XDG_RUNTIME_DIR} && length $ENV{XDG_RUNTIME_DIR} && -d $ENV{XDG_RUNTIME_DIR}) {
		$dir = File::Spec->catdir($ENV{XDG_RUNTIME_DIR}, 'class-shared');
	} elsif (-d "/run/user/$>") {
		$dir = File::Spec->catdir("/run/user/$>", 'class-shared');
	} else {
		$dir = File::Spec->catdir(File::Spec->tmpdir, "class-shared-$>");
	}

	# The directory may come from the environment or the caller, both of which
	# are tainted under -T, and perl refuses to mkdir or open a file in a
	# tainted path.  A name is not dangerous because of what it says, only
	# because of what it is used for, and everything made here is checked by
	# ensure_dir (ours, and closed to others) before anything is trusted in it.
	# The one thing that is refused outright is a NUL byte, which would end
	# the name early in the system call and so name a different place.
	my ($clean) = $dir =~ /\A([^\0]+)\z/
		or die "Class::Shared: a directory name may not contain a NUL byte\n";

	return $clean;
}

# Whether this perl can make a unix domain socket, which is what a backend is
# reached through and what a frontend starts one over.  Probed rather than
# assumed from $^O: a Cygwin perl is not MSWin32 and has them, and a platform
# without them is refused whatever it calls itself.  The answer cannot change
# during a run, so it is asked for once.
our $UNIX_SOCKETS;

sub _has_unix_sockets {
	return $UNIX_SOCKETS if defined $UNIX_SOCKETS;

	$UNIX_SOCKETS = eval {
		# Both have to work.  A Windows perl 5.26 emulates socketpair, so it
		# succeeds, but cannot name a unix socket, and pack_sockaddr_un dies.
		# IO::Socket::UNIX is not required here: it would cost every client
		# process about 1.2 MB, and the backend and the command load it
		# themselves when they need it.
		require Socket;

		Socket::pack_sockaddr_un('probe');

		socketpair(my $reader, my $writer, Socket::AF_UNIX(), Socket::SOCK_STREAM(), 0)
			? 1
			: 0;
	} ? 1 : 0;

	return $UNIX_SOCKETS;
}

# Nothing here can work without unix domain sockets, so say that where it is
# tried rather than blaming the directory the caller passed: on a platform
# without them there is no directory that would have helped.  Whether they
# exist can be given as an argument, so the refusal is exercised by the suite
# on machines that have them.
sub _require_unix_sockets {
	my ($what, $has_unix_sockets) = @_;

	$has_unix_sockets = _has_unix_sockets() unless defined $has_unix_sockets;

	return if $has_unix_sockets;

	die "Class::Shared: $what is not available here: this perl has no unix "
		. "domain sockets, so a backend could neither be reached nor started.  "
		. "This distribution is Unix-only (see PLATFORMS)\n";
}

# Create $dir if needed and make sure nobody else can drop a socket in it.
# Returns (1, undef), or (0, $why_not), as the POD documents.
sub ensure_dir {
	my ($dir) = @_;

	die "Class::Shared: no directory given\n" unless defined $dir && length $dir;

	_require_unix_sockets('a backend directory');

	if (!-d $dir) {
		# Losing a race to make it is not a failure; what the winner made is
		# checked below like any directory that was already there.
		if (!mkdir($dir, 0700)) {
			my $why = "$!";
			return (0, "cannot create $dir: $why") unless -d $dir;
		}
	}

	return _check_dir($dir);
}

# Purpose:       say whether $dir is somewhere only this user can put a socket.
# Entry:         $dir is a directory name; nothing is created.
# Exit status:   (1, undef) when it is ours and not writable by group or
#                others, otherwise (0, $why_not).
# Side effects:  none.
sub _check_dir {
	my ($dir) = @_;

	my @stat = stat($dir);
	return (0, "cannot stat $dir: $!") unless @stat;

	return (0, "$dir is owned by uid $stat[4], not by uid $>")
		if $stat[4] != $>;

	return (0, "$dir is writable by group or others; refusing to use it")
		if $stat[2] & 0022;

	return (1, undef);
}

# Purpose:       decide whether to talk to the socket at $path.  What comes back
#                over it is thawed by Storable, so a socket made by another user
#                must never be trusted: it could answer with whatever it likes,
#                and would be told every argument the client sends.
# Entry:         $path names a socket that is known to exist.
# Exit status:   (1, undef) when its directory is safe (see _check_dir) and the
#                socket is a socket owned by this user, otherwise (0, $why_not).
# Side effects:  none.
# Why both:      a safe directory means nobody else could have put the socket
#                there; the owner check catches a socket that was already there.
sub _check_endpoint {
	my ($path) = @_;

	my ($safe, $why) = _check_dir(dir_of($path));
	return (0, $why) unless $safe;

	my @stat = stat($path);
	return (0, "cannot stat $path: $!") unless @stat;

	return (0, "$path is not a socket") unless -S _;

	return (0, "$path is owned by uid $stat[4], not by uid $>")
		if $stat[4] != $>;

	return (1, undef);
}

# One socket for every class.  The backend behind it is told which class a
# client wants when that client connects, so the path names no class and one
# backend can serve as many as are asked for.
sub socket_path {
	my ($dir) = @_;

	_require_unix_sockets('a unix socket');

	$dir = default_dir(dir => $dir);

	return check_socket_path(File::Spec->catfile($dir, 'class-shared.sock'));
}

# A path that will not fit in a sockaddr_un is silently truncated by the
# operating system, so a client and a backend could end up on different
# sockets.  Refuse it instead.  Applies to a path given explicitly as well as
# one socket_path built.
sub check_socket_path {
	my ($path) = @_;

	die "Class::Shared: no socket path given\n" unless defined $path && length $path;

	if (length($path) > $MAX_SOCKET_PATH) {
		die sprintf("Class::Shared: socket path '%s' is %d characters, more than the %d allowed; "
			. "set CLASS_SHARED_DIR or pass dir => to a shorter directory\n",
			$path, length($path), $MAX_SOCKET_PATH);
	}

	return $path;
}

1;

__END__

=head2 normalise_fingerprint

    my $pin = Class::Shared::normalise_fingerprint(
        'AB:CD:...:EF'    # 32 pairs of hex digits, as openssl prints them
    );

Turns the SHA-256 fingerprint of a certificate into the one form the TLS layer
wants: C<sha256$> followed by 64 lower case hexadecimal digits.

It accepts 64 hex digits, or 32 pairs of hex digits separated by colons, with or
without a leading C<sha256$>.  Upper or lower case digits are fine.  The prefix
itself must be lower case.  To get a fingerprint from a certificate file, run
C<openssl x509 -in server.pem -noout -fingerprint -sha256> and copy the part
after the equals sign.

B<Side effects:> none.

B<Dies> if no value is given, or if the value is not a SHA-256 fingerprint.

=head3 API SPECIFICATION

=head4 Input

    {
        value => {
            type     => 'string',
            position => 0,
            optional => 0,
            matches  => qr/\A(?:sha256\$)?(?:(?:[0-9A-Fa-f]{2}:){31}[0-9A-Fa-f]{2}|[0-9A-Fa-f]{64})\z/,
        },
    }

=head4 Domains

    valid    exactly 64 hexadecimal digits, or 32 pairs of two hexadecimal
             digits separated by ":", with or without a lower case "sha256$"
             prefix
    invalid  any other length, any other separator, an upper case prefix, and
             any character that is not a hexadecimal digit

    partition             representative         result
    ----------------------------------------------------------
    64 digits             0102...1f20             accepted
    32 colon-separated    01:02:...:1f:20          accepted
    sha256$ prefix        sha256$0102...           accepted
    upper case digits     0102...1F20             accepted, lower cased
    upper case prefix     SHA256$0102...           dies
    63 or 65 digits       one short, one long      dies
    31 or 33 pairs        one short, one long      dies
    spaces or hyphens     01 02 03..., 01-02-03    dies
    non-ASCII character   U+00FC, U+1F600, U+202E  dies

    Boundary values: the plain form is valid at exactly 64 characters (63 and
    65 die); the colon form is valid at exactly 95 (94 and 96 die).  The
    prefix is removed and every digit is lower cased; all invalid values are
    echoed in the message byte for byte, without being decoded.

=head4 Output

    { type => 'string', matches => qr/\Asha256\$[0-9a-f]{64}\z/ }

=head2 client_tls_options

    my %tls = Class::Shared::client_tls_options(
        cert => 'client.pem',
        key  => 'client-key.pem',
        ca   => 'ca.pem',
    );
    my $socket = IO::Socket::SSL->new(PeerAddr => $host, PeerPort => $port, %tls);

Returns the options a TLS client needs, as a flat list of key and value pairs
that you can pass straight to C<< IO::Socket::SSL->new >>.  It exists so that
the frontend and the command line program cannot disagree about what "verify the
backend" means.

Give C<cert> and C<key> (the certificate this client shows), and then either
C<ca> or C<fingerprint>.  With C<ca>, the backend's certificate must be signed
by that CA and must name the host you connect to.  With C<fingerprint> (the
output of L</normalise_fingerprint>), exactly one certificate is trusted, and
its name and its signer do not matter.  Verification is always on.

This function does not check that the files exist, and does not check that you
gave only one of C<ca> and C<fingerprint>.  The caller does that.

B<Side effects:> loads L<IO::Socket::SSL>.  Nothing else loads it.

B<Dies> if L<IO::Socket::SSL> is not installed.

=head3 API SPECIFICATION

=head4 Input

    {
        cert        => { type => 'string', optional => 0 },
        key         => { type => 'string', optional => 0 },
        ca          => { type => 'string', optional => 1 },
        fingerprint => { type => 'string', optional => 1,
                         matches => qr/\Asha256\$[0-9a-f]{64}\z/ },
    }

=head4 Domains

    valid    cert and key, then either ca or fingerprint (or neither, which
             the caller is expected to have refused already)
    invalid  nothing is refused here: this function checks neither that the
             files exist nor that ca and fingerprint are not both given

    partition            representative                  result
    ---------------------------------------------------------------
    ca given             ca => "ca.pem"                  SSL_ca_file
    fingerprint given    sha256$ + 64 lower hex digits   pin, no CA
    both given           ca and fingerprint              the pin wins
    neither given        cert and key only               SSL_ca_file undef
    multibyte path       /etc/U+00FC/client.pem          passed through

    Output boundaries: the flat list has five pairs with a CA and seven with a
    pin, so ten and fourteen elements.  SSL_verify_mode is "verify the peer"
    in every partition, and SSL_version is the same for both ends.

=head4 Output

    {
        type   => 'arrayref',
        min    => 10,
        max    => 14,
        description => 'a flat list of option name and value pairs: SSL_version, SSL_cert_file, SSL_key_file, SSL_verify_mode, and either SSL_ca_file or (SSL_fingerprint, SSL_force_fingerprint, SSL_verifycn_scheme)',
    }

=head2 dir_of

    my $dir = Class::Shared::dir_of('/run/user/1000/class-shared/x.sock');
    # '/run/user/1000/class-shared'

Returns the directory part of a path, so that the answer can always be used.  A
path with no directory part, such as C<x.sock>, gives C<.> (the current
directory).  A file directly in the top directory, such as C</x.sock>, gives C</>.

B<Side effects:> none.

=head3 API SPECIFICATION

=head4 Input

    { path => { type => 'string', position => 0, optional => 0 } }

=head4 Domains

    partition            representative    result
    -------------------------------------------------
    bare file name       x.sock            .
    file in the root     /x.sock           /
    nested file          /a/b/c            /a/b
    trailing slash       a/b/              a
    doubled separator    a//b              a
    empty path           ""                .

    The answer is never empty, so it can always be used: a path with no
    directory part gives ".".  There is no length boundary.  A multibyte
    directory part is returned unchanged, with no encoding or decoding.

=head4 Output

    { type => 'string', min => 1 }

=head2 default_dir

    my $dir = Class::Shared::default_dir();
    my $dir = Class::Shared::default_dir(dir => '/tmp/mine');

Returns the directory that holds this user's sockets.  The first of these that
applies wins:

=over 4

=item 1.

the C<dir> you pass;

=item 2.

the environment variable C<CLASS_SHARED_DIR>;

=item 3.

C<$ENV{XDG_RUNTIME_DIR}/class-shared>, if C<XDG_RUNTIME_DIR> names a directory
that exists;

=item 4.

F</run/user/UID/class-shared>, if F</run/user/UID> exists (UID is the effective
user id);

=item 5.

a per-user directory under the system temporary directory.

=back

The path is kept short on purpose, because it ends up inside a socket address,
which has a small size limit.  It is per user because the socket is a trust
boundary.

B<Side effects:> reads the environment and checks whether directories exist.  It
does not create anything; use L</ensure_dir> for that.

B<Dies> if the directory name contains a NUL byte, which would end the name
early in a system call and so name a different place.  Under taint mode
(C<-T>) the name is untainted here, because everything made in it is checked by
L</ensure_dir> before it is trusted.

=head3 API SPECIFICATION

=head4 Input

    { dir => { type => 'string', optional => 1, min => 1 } }

=head4 Domains

    The first partition that applies wins, so they are ordered:

    rank  partition                             result
    -----------------------------------------------------------------
    1     dir given and not empty               the dir, unchanged
    2     CLASS_SHARED_DIR set and not empty    that value
    3     XDG_RUNTIME_DIR names a directory     that directory/class-shared
    4     /run/user/UID exists                  that directory/class-shared
    5     none of the above                     tmpdir/class-shared-UID

    invalid: a name containing a NUL byte dies at any rank, because a system
    call would end the name there and so name a different place.  The empty
    string is not invalid: it means "not given" and falls through to the next
    rank.  A multibyte name is returned unchanged, not encoded.  Nothing is
    created, so a rank may name a directory that does not exist yet.

=head4 Output

    { type => 'string', min => 1 }

=head2 ensure_dir

    my ($ok, $why) = Class::Shared::ensure_dir($dir);
    die "cannot use $dir: $why" unless $ok;

Makes sure C<$dir> exists and that nobody else can put a socket in it.  It
returns C<(1, undef)> on success or C<(0, $why_not)> when the directory is not
safe.  It is refused if

=over 4

=item *

it cannot be created or inspected;

=item *

it belongs to a different user (anybody who owns the directory could pretend to
be the backend); or

=item *

group or other users can write to it.

=back

If the directory is missing it is created with mode 0700.  Only the last part of
the path is created: the parent directory must already exist.

B<Side effects:> may create one directory.

B<Dies> (and does not return a pair) if no directory is given, or on a perl
without unix sockets.

=head3 API SPECIFICATION

=head4 Input

    { dir => { type => 'string', position => 0, optional => 0, min => 1 } }

=head4 Domains

    valid    a path whose last part exists, or can be created, as a directory
             owned by this user with neither the group write bit (0020) nor
             the other write bit (0002) set
    invalid  undef, the empty path, a path whose parent is missing, a path
             that is not a directory, a directory owned by another user, and
             a directory with either write bit set

    partition              representative    result
    -----------------------------------------------------
    does not exist         tmp/fresh         (1, undef), mode 0700
    exists, mode 0700      tmp/private       (1, undef)
    exists, mode 0755      tmp/open          (1, undef)
    exists, mode 0777      tmp/writable      (0, reason)
    exists, mode 0770      group writable    (0, reason)
    exists, mode 0702      other writable    (0, reason)
    parent missing         tmp/absent/child  (0, "cannot create ...")
    a plain file           tmp/file          (0, "cannot create ...")
    empty or undef         ""                dies

    Boundary values: the boundary is the write mask 0022, not a single mode:
    0700 is the most private mode created and 0777 the most open refused, but
    0755 is accepted because others may read and search, not write.  Only the
    last part of the path is created, so a missing parent is a refusal, not a
    recursive mkdir.  A multibyte name is created as given.

=head4 Output

    {
        type   => 'arrayref',
        min    => 2,
        max    => 2,
        schema => [
            { type => 'boolean', description => '1 when the directory is safe to use' },
            { type => 'string',  optional => 1, description => 'undef on success, otherwise the reason' },
        ],
    }

=head2 socket_path

    my $path = Class::Shared::socket_path();
    my $path = Class::Shared::socket_path('/tmp/mine');

Returns the path of the backend socket inside C<$dir>, or inside the default
directory (see L</default_dir>) if none is given.  The file name is always
C<class-shared.sock>.  There is one socket for every class, because the client
chooses the class and not the listener.

B<Side effects:> none.  The directory and the socket are not created.

B<Dies> on a perl without unix sockets, or if the result is longer than 100
characters (see L</check_socket_path>).

=head3 API SPECIFICATION

=head4 Input

    { dir => { type => 'string', position => 0, optional => 1, min => 1 } }

=head4 Domains

    valid    no argument, or a directory name, such that the socket path is
             1 to 100 characters
    invalid  a directory name that makes the path longer than 100 characters,
             which dies with the message documented under L</check_socket_path>

    partition                     representative      result
    ------------------------------------------------------------------
    default directory             ()                  .../class-shared.sock
    a directory                   /tmp                /tmp/class-shared.sock
    path exactly 100 characters   dir of 82 chars     accepted
    path 101 characters           dir of 83 chars     dies

    The file name is always "class-shared.sock", so the boundary is reached
    through the directory: with a 17 character file name the largest usable
    directory is 82 characters.  Nothing is created and nothing is checked for
    existence.

=head4 Output

    { type => 'string', min => 1, max => 100 }

=head2 check_socket_path

    my $path = Class::Shared::check_socket_path($path);

Returns C<$path> if it is short enough to be a socket address, and dies if it
is not, or if no path is given at all.  The limit is 100 characters, which is
less than the operating system's limit so that the code stays portable.  Without this check the system would cut
a long path short without saying so, and a client and a backend could end up
using two different sockets.

The frontend, the backend and F<class-shared> all use it for a C<socket> that
you give yourself, as well as for the path that C<socket_path> builds.

B<Side effects:> none.

B<Dies> with C<Class::Shared: no socket path given> if C<$path> is undef or
empty, and with C<Class::Shared: socket path 'PATH' is N characters, more than
the 100 allowed; set CLASS_SHARED_DIR or pass dir =E<gt> to a shorter
directory> if it is too long.

=head3 API SPECIFICATION

=head4 Input

    { path => { type => 'string', position => 0, optional => 0, min => 1 } }

=head4 Domains

    valid    a non-empty path of 1 to 100 characters
    invalid  undef, the empty path, and any path longer than 100 characters

    partition          representative   result
    -------------------------------------------------
    length 1           /                accepted
    length 99          ...              accepted
    length 100         ...              accepted, the maximum
    length 101         ...              dies
    length 0 or undef  ""               dies

    Boundary values: 100 is accepted and 101 dies; 0 and undef die.  The limit
    is 100 characters and is below the operating system's.  A multibyte path is
    counted in characters and returned unchanged.  This function does not check
    that a socket can use its characters: see L</ENCODING>.

=head4 Output

    { type => 'string', min => 1, max => 100 }

=head2 poll_pause

    Class::Shared::poll_pause();

Sleeps for one polling interval (C<$Class::Shared::POLL_INTERVAL>, 0.02
seconds).  Every loop that waits for a socket or a lock uses it, so that none of
them spins the processor and all of them wake at the same rate.

B<Side effects:> sleeps.  It returns nothing.

=head3 API SPECIFICATION

=head4 Input

    { }

=head4 Domains

    Takes no input, so it has one partition.  The output is the empty list
    (undef in scalar context).  The only observable effect is a sleep of
    C<$Class::Shared::POLL_INTERVAL> seconds, 0.02, which is the same for
    every loop that waits for a socket or a lock.

=head4 Output

    { type => 'undef' }

=head2 detach_standard_streams

    my ($ok, $why) = Class::Shared::detach_standard_streams('/path/to/log');

Used when a backend goes into the background.  It reopens standard input on the
null device (F</dev/null>) and standard output and standard error on the log
file, so that the process holds no terminal and its messages land in a file.  If
the log file cannot be opened, they go to the null device instead, because a
backend that cannot write a log should still run.

It returns C<(1, undef)>, or C<(0, $why)> if a stream could not be reopened.  The
caller decides whether that matters: the backend treats it as fatal.

B<Side effects:> replaces STDIN, STDOUT and STDERR of the current process.  Do
not call it in a program that still needs them.

=head3 API SPECIFICATION

=head4 Input

    { log => { type => 'string', position => 0, optional => 0, min => 1 } }

=head4 Domains

    valid    any log path: one that can be opened for appending, and one that
             cannot (the streams then go to the null device and the call still
             succeeds, because a backend that cannot log should still run)
    invalid  none by value: an unopenable path is a documented fallback, not
             an error

    partition            representative        result
    ---------------------------------------------------------
    writable log         /tmp/backend.log      (1, undef), file created
    log in a missing dir /absent/backend.log    (1, undef), null device

    The refusal path, C<(0, $why)>, exists for a failure to reopen a stream
    after the log was opened, such as a descriptor limit; it cannot be
    provoked by the value of the path alone.  The call replaces STDIN, STDOUT
    and STDERR of the current process, so a test makes it in a child.

=head4 Output

    {
        type   => 'arrayref',
        min    => 2,
        max    => 2,
        schema => [
            { type => 'boolean' },
            { type => 'string', optional => 1 },
        ],
    }

=head1 PACKAGE VARIABLES

These can be changed with C<local> in a test or a special program.  Most users
never need to.

=over 4

=item C<$Class::Shared::VERSION>

The version of the distribution.

=item C<$Class::Shared::PROTOCOL_VERSION>

The version of the wire protocol, now 2.  A backend refuses a client that speaks
a different one.  It is raised whenever the protocol changes in a way old
clients cannot understand.

=item C<$Class::Shared::MAX_SOCKET_PATH>

The longest socket path this module will make or accept: 100 characters.

=item C<$Class::Shared::POLL_INTERVAL>

How long, in seconds, the waiting loops sleep between looks: 0.02.

=item C<$Class::Shared::UNIX_TRUST_REASON>

The sentence explaining why a unix socket needs no token and no TLS.  The
backend, the frontend and the command line all quote it, so they use the same
words.

=back

=head1 ENCODING

Class::Shared moves text between processes, so it matters which parts accept
more than plain English letters.

=over 4

=item Arguments, results and error text: full Unicode.

The arguments you pass to a method, the C<ctor> list, the values a method
returns and the text of an exception all travel through L<Storable>, which
keeps Perl strings exactly as they are.  Accented letters, Chinese, Japanese,
Arabic and emoji all arrive unchanged, with their "UTF-8 flag" kept.  This was
checked with a round trip of C<"caf\x{e9}">, C<"\x{1F600}"> and a Japanese word.

Bytes and characters are kept apart.  A byte string comes back as a byte string
and a character string as a character string.  So decode your input (for
example with L<Encode>) before you send it, and encode it when you print it.

=item Class names: ASCII only.

A class name may contain only the letters A to Z (either case), digits and
underscores, joined by C<::>.  A class with non-ASCII letters in its name is
refused by L</validate_class>, even though Perl itself would allow it.

=item Method names: ASCII is safe.

A method name is passed on as given.  Use ASCII names; a name that does not
exist is reported as "has no method".

=item Secrets (token, token file): ASCII only.

Use only ASCII characters in a token.  The token file is read as bytes, but a
C<token> you give in your program is a Perl string.  The word C<caf\x{e9}> has
different bytes in the two forms and so gives a different digest, and a
character above code point 255 stops the digest from being calculated at all.
Both sides would then fail to agree, and the connection is refused.

=item File and directory names: ASCII is safest.

Paths (C<dir>, C<socket>, C<log>, certificate files) are handed to the operating
system as they are.  Non-ASCII names work if every program uses the same bytes,
but they are not tested here.  The 100 character limit on a socket path counts
characters.  Perl gives a socket one byte for each character up to code point
255, so an accepted path is not cut short.  A path with a higher character in a
character string cannot be used as a socket: connecting or binding dies with
C<Wide character>.  Encode such a name to bytes first; each byte then counts
towards the limit.

=item Fingerprints: hexadecimal digits only.

See L</normalise_fingerprint>.

=item The backend log: be careful.

The log file has no encoding layer.  Text that has only characters up to code
point 255 (such as C<caf\x{e9}>) is written as one byte per character, which is
not UTF-8.  Text with a higher character (such as an emoji) is written as UTF-8
and Perl prints a C<Wide character> warning.  A log that contains both is mixed.
Log lines are mostly the backend's own English messages; the main way for other
text to appear is an error from your own class.

=back

=head1 COMMON PITFALLS

=over 4

=item Class variables are shared by every client.

Each frontend has its own object, but all objects of a class live in one
process, so a package variable (C<our $COUNT>) or other class data is shared by
all clients.  A change made by one client is seen by all the others.  Keep state
in the object, not in the package.

=item The backend is one process: it does one thing at a time.

A slow method makes every other client wait, whatever class they use.

=item The backend's environment is not yours.

Setting C<$ENV{FOO}>, calling C<chdir>, or opening a file in your own process
changes nothing in the backend.  Pass what a method needs as arguments.

=item Only plain data can cross.

Strings, numbers, C<undef>, array references and hash references can be sent.
Code references, file handles and tied or inside-out objects cannot.  An
argument that cannot be sent makes the call fail.  In this version the failure
is reported as "lost the backend" and it also closes the connection, so the
object is gone.  Check your arguments before the call.

=item Context is kept, so list rules still apply.

A method that returns C<(1, 2, 3)> gives the last value, 3, in scalar context.
That is normal Perl, and it is the same through a frontend.

=item C<undef> is a value.

C<undef> is sent and returned faithfully.  A method that returns C<undef> in list
context gives a list of one element, not an empty list.

=item C<ensure_dir> returns a pair; the other functions die.

Test C<$ok>, the first value of the pair.  The pair as a whole is never an empty
list, so testing the list itself tells you nothing.

=item C<ensure_dir> makes only one directory.

If the parent does not exist, it fails with "No such file or directory".  Create
the parent first.

=item An over-long socket path is refused.

Keep C<dir> or C<socket> short (100 characters at most).

=item A token file's trailing white space is removed.

A secret whose last character is meant to be a space or a new line cannot be
stored in a token file.  Use ordinary printable characters.

=item A unix socket takes no token and no TLS.

Passing one is an error, on purpose, so that it never looks like extra
protection.

=back

=head1 TRANSPORT SECURITY

Authentication belongs to the transport, and the two transports are
deliberately different.

A unix socket is created mode 0600 in a directory only its owner can write to,
so the kernel has already decided who may connect: there is no token and no TLS,
and no frame carries a digest.  The backend, the frontend and L<class-shared>
refuse both for a unix socket rather than let either look like a defence.

TCP is the opposite case.  A port is reachable by anybody who can route to it,
and treating a frame means running what the sender put in it, so a TCP listener
is a TLS listener: it needs a certificate and its key to prove which backend it
is, and a CA to check client certificates against, and it will not start without
all three.  Clients must present a certificate that CA signed, and must verify
the backend's certificate against the CA that signed it -- name included -- or
against a pinned SHA-256 fingerprint of that one certificate, which stands in
for both the CA and the name.  A client whose certificate the backend cannot
verify is dropped during the handshake and never receives a frame.

TLS answers who is on the other end and makes the bytes unreadable.  The token is
kept on top of it, as a second and independent check: with a token every frame
in both directions carries an HMAC-SHA-256 of its body, and the digest is
verified before L<Storable::thaw> sees the body.  So a client that has a
certificate but not the shared secret still cannot make the backend
deserialise, and so run, bytes of its choosing.  The digest authenticates one
frame; TLS authenticates the connection and encrypts it.  Both, because either
one alone has been enough to lose a system.

See L<Class::Shared::Backend/SECURITY> for the backend's side of it and
L<Class::Shared::Protocol> for the framing.

=head2 Making the certificates

A TCP listener needs four files: a CA, the listener's certificate and key, and
a certificate for every client.  OpenSSL makes them in three steps.  The CA's
key signs certificates and is not needed on the machines that use them.

    # 1. A CA of your own.
    openssl req -x509 -newkey rsa:2048 -nodes -days 3650 \
        -keyout ca-key.pem -out ca.pem -subj '/CN=Class::Shared CA' \
        -addext 'basicConstraints=critical,CA:TRUE' \
        -addext 'keyUsage=critical,keyCertSign,cRLSign'

The listener's certificate has to name the address clients connect to, in
C<subjectAltName>: a C<DNS:> entry for a hostname, an C<IP:> entry for an
address, or both.

    # 2. The listener's certificate.  Put your own addresses in server.ext.
    printf 'subjectAltName = DNS:classhost.example.com, IP:127.0.0.1\n' > server.ext
    printf 'extendedKeyUsage = serverAuth\n' >> server.ext
    openssl req -new -newkey rsa:2048 -nodes -subj '/CN=classhost.example.com' \
        -keyout server-key.pem -out server.csr
    openssl x509 -req -in server.csr -CA ca.pem -CAkey ca-key.pem \
        -CAcreateserial -days 3650 -out server.pem -extfile server.ext

Each client needs a certificate of its own.  The backend cannot tell one from
another beyond this, so give each client, or each pair of them, their own.

    # 3. A client certificate.
    printf 'extendedKeyUsage = clientAuth\n' > client.ext
    openssl req -new -newkey rsa:2048 -nodes -subj '/CN=class-shared client' \
        -keyout client-key.pem -out client.csr
    openssl x509 -req -in client.csr -CA ca.pem -CAkey ca-key.pem \
        -CAcreateserial -days 3650 -out client.pem -extfile client.ext

The listener is given three of the files:

    class-shared start --listen tcp:0.0.0.0:7000 \
        --token-file /etc/class-shared/token \
        --tls-cert server.pem --tls-key server-key.pem --tls-ca ca.pem

and every client the other three:

    my $simple = Class::Shared::Frontend->new('Class::Simple',
        host       => 'classhost.example.com',
        port       => 7000,
        tls_ca     => 'ca.pem',
        tls_cert   => 'client.pem',
        tls_key    => 'client-key.pem',
        token_file => '/etc/class-shared/token',
    );

A frontend that pins the listener's certificate instead of trusting the CA skips
C<tls_ca> and passes C<tls_fingerprint> the digest that
C<openssl x509 -in server.pem -noout -fingerprint -sha256> prints.  That works
with a self-signed certificate too, and then the CA is only needed for the
clients.  F<t/certs/make-certs.sh> in the distribution generates this set, plus
a second CA and impostor certificates, for the tests.

=head1 LIMITATIONS

=over 4

=item *

A unix socket is not encrypted: file permissions decide who may connect, and
anything that can read the socket can read the traffic on it.  TCP is always
TLS, and has no unencrypted mode.

=item *

One backend per directory answers one call at a time, so a slow method delays
every client of that backend, whatever class they are using.

=item *

Each frontend is one connection: many objects in one process means many file
descriptors in both processes.

=item *

Arguments and return values travel through L<Storable>; filehandles, code
references and tied or inside-out objects do not.

=item *

An object cannot outlive its connection, so it cannot be handed to another
process; it lives exactly as long as the frontend that made it.

=item *

The backend is a separate process, so nothing about your process reaches it
unless you send it.  Setting C<$ENV{FOO}> in a frontend does not set it in the
backend, and a method that reads C<%ENV> (or C<chdir>, or a global, or a file
handle) sees the backend's environment, not yours: its C<%ENV> is the one the
backend was started with, and every client shares those values.  Pass such
state as arguments if it matters, or set the environment when you start the
backend.

=item *

A client may call a method only by its plain name.  A package-qualified name
such as C<Other::Package::function> is refused, and so are C<new>, C<DESTROY>
and C<AUTOLOAD>.  This is not a sandbox: a client that has passed the
transport's authentication can already make the backend load any module and
call the methods of what it constructs, so the backend is only as safe as the
clients allowed to reach it.

=back

=head1 PLATFORMS

Unix-like systems only.  A backend needs three things this distribution cannot
do without:

=over 4

=item *

unix domain sockets, which is how a frontend reaches a backend on this machine
and starts one when there is none;

=item *

POSIX directory permissions, which are the whole of a unix socket's
authentication: the socket is mode 0600 inside a directory only its owner can
write to, so the kernel decides who may connect;

=item *

a real C<fork>, which is how a frontend starts a backend in the background.

=back

A perl without unix domain sockets can run none of it, so that is the question
the check asks, rather than a list of operating systems: a Cygwin perl has the
sockets and works.  Windows has had the sockets since Windows 10, but an
MSWin32 perl still cannot run a backend: its C<stat> reports the same mode bits
for every directory, so none there can be shown to be owner-only and
C<Class::Shared::ensure_dir> refuses them all.

The refusal names what is missing: C<Class::Shared::ensure_dir> and
C<Class::Shared::socket_path> die with that explanation on a perl without the
sockets, and C<Class::Shared::ensure_dir> refuses the directories it cannot
show to be owner-only.

It installs there anyway, and F<Makefile.PL> says so as it runs.  Refusing to
install would take away L<Class::Shared::Protocol>, which is pure Perl and can
talk to a backend from a machine that cannot run one, and would leave such a
platform with nothing to report but a failed install.

The wire protocol, L<Class::Shared::Protocol>, is pure Perl and loads on any
platform, so it can be used to talk to a backend from a machine that cannot run
one.

=head1 SEE ALSO

=over 4

=item * L<Test Dashboard|https://nigelhorne.github.io/Class-Shared/coverage/>

=back

L<Class::Shared::Frontend>, L<Class::Shared::Backend>,
L<Class::Shared::Protocol>, L<class-shared>.

=head1 HACKING

F<README.md> is generated from the POD in this file and must never be edited
by hand.  After changing the POD, run C<make readme>, which calls
F<maint/regen-readme>; it converts the POD with L<Pod::Github>'s
C<pod2github>, the converter whose C<##> headings, fenced Perl blocks and
MetaCPAN links are the style the committed front page uses.  C<pod2markdown>
does not reproduce it.

L<Pod::Github> is a development requirement, so C<cpanm --installdeps
--with-develop .> installs everything needed to regenerate the front page.

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=encoding utf8

=head1 FORMAL SPECIFICATION

This section describes what each function does in the Z notation, a way of
writing exactly what a program promises using sets and logic.  You do not need
it to use the module.  Read the plain text above first.

Z uses mathematical symbols, so this is the only part of the file that is not
plain ASCII.  A short key:

    x? input        x! output        x' the value of x after the operation
    =>  implies     /\  and          \/  or          ~  not
    |->  maps to    <->  relation    +->  partial function (each input at most one answer)
    seq  a sequence (an ordered list)    # the length of a sequence

In the Z text below the symbols are the usual Unicode ones.

=head2 Basic types

    [CHAR]                                  all characters
    STRING   == seq CHAR
    STRING⊥  == STRING ∪ {⊥}                a string, or undef
    PATH     == STRING
    MAXPATH  == 100
    RESULT[X] ::= value⟨⟨X⟩⟩ | dies⟨⟨STRING⟩⟩    a function returns X, or dies with a message
    IDENT    == the strings that start with a letter or _ and continue with letters, digits or _
    CLASSNAME == { c : STRING | ∃ parts : seq₁ IDENT • c = join(⟨"::"⟩, parts) }
    HEX64    == the strings of exactly 64 hexadecimal digits
    FP       == { f : STRING | f ∈ HEX64 ∨ f is 32 pairs of hex digits separated by ":" }

=head2 validate_class

    ┌─ ValidateClass ─────────────────────────────────────────
    │ class? : STRING⊥
    │ out!   : RESULT[STRING]
    ├─────────────────────────────────────────────────────────
    │ class? ∈ CLASSNAME ⇒ out! = value(class?)
    │ class? ∉ CLASSNAME ⇒ ∃ m : STRING • out! = dies(m)
    └─────────────────────────────────────────────────────────

=head2 read_secret

    ┌─ ReadSecret ────────────────────────────────────────────
    │ path?  : STRING⊥
    │ files  : PATH ⇸ STRING                  the file system, as bytes
    │ out!   : RESULT[STRING]
    ├─────────────────────────────────────────────────────────
    │ path? ∈ dom files ∧ trim(files(path?)) ≠ ⟨⟩
    │     ⇒ out! = value(trim(files(path?)))
    │ path? ∉ dom files ∨ trim(files(path?)) = ⟨⟩ ∨ path? = ⊥
    │     ⇒ ∃ m : STRING • out! = dies(m)
    │ files' = files                          nothing is changed
    └─────────────────────────────────────────────────────────

where C<trim> removes white space from the end only.

=head2 normalise_fingerprint

    ┌─ NormaliseFingerprint ──────────────────────────────────
    │ value? : STRING⊥
    │ out!   : RESULT[STRING]
    ├─────────────────────────────────────────────────────────
    │ value? = ⟨"sha256$"⟩ ⌢ f ∨ value? = f, for some f ∈ FP
    │     ⇒ out! = value(⟨"sha256$"⟩ ⌢ lower(strip_colons(f)))
    │ otherwise ⇒ ∃ m : STRING • out! = dies(m)
    └─────────────────────────────────────────────────────────

=head2 client_tls_options

    ┌─ ClientTlsOptions ──────────────────────────────────────
    │ cert?, key? : STRING
    │ ca?, fingerprint? : STRING⊥
    │ out! : RESULT[seq (STRING × VALUE)]
    ├─────────────────────────────────────────────────────────
    │ fingerprint? ≠ ⊥ ⇒ out! = value(base ⌢ pin)
    │ fingerprint? = ⊥ ⇒ out! = value(base ⌢ ⟨("SSL_ca_file", ca?)⟩)
    │ SSL_verify_mode ∈ base is always "verify the peer"
    └─────────────────────────────────────────────────────────

=head2 dir_of

    ┌─ DirOf ─────────────────────────────────────────────────
    │ path? : STRING
    │ dir!  : STRING
    ├─────────────────────────────────────────────────────────
    │ dir! = dirname(path?)       ("." when path? has no directory part)
    │ dir! ≠ ⟨⟩
    └─────────────────────────────────────────────────────────

=head2 default_dir

    ┌─ DefaultDir ────────────────────────────────────────────
    │ dir? : STRING⊥ ; env : STRING ⇸ STRING ; isdir : ℙ PATH ; euid : ℕ
    │ dir! : STRING
    ├─────────────────────────────────────────────────────────
    │ dir? ≠ ⊥ ∧ dir? ≠ ⟨⟩ ⇒ dir! = dir?
    │ else "CLASS_SHARED_DIR" ∈ dom env ∧ env(..) ≠ ⟨⟩ ⇒ dir! = env("CLASS_SHARED_DIR")
    │ else env("XDG_RUNTIME_DIR") ∈ isdir ⇒ dir! = env("XDG_RUNTIME_DIR") / "class-shared"
    │ else "/run/user/" ⌢ euid ∈ isdir ⇒ dir! = that / "class-shared"
    │ else dir! = tmpdir / ("class-shared-" ⌢ euid)
    │ isdir' = isdir                          nothing is created
    └─────────────────────────────────────────────────────────

=head2 ensure_dir

    ┌─ EnsureDir ─────────────────────────────────────────────
    │ dir?  : STRING⊥
    │ fs    : PATH ⇸ (owner : ℕ × mode : ℕ)   the directories that exist
    │ euid  : ℕ
    │ out!  : RESULT[𝔹 × STRING⊥]
    ├─────────────────────────────────────────────────────────
    │ dir? = ⊥ ∨ dir? = ⟨⟩ ∨ ¬ UnixSockets ⇒ ∃ m • out! = dies(m)
    │ dir? ∉ dom fs ∧ parent(dir?) ∈ dom fs ⇒ fs' = fs ⊕ {dir? ↦ (euid, 8#700)}
    │ dir? ∈ dom fs' ∧ owner(fs'(dir?)) = euid ∧ mode(fs'(dir?)) ∧ 8#022 = 0
    │     ⇒ out! = value(true, ⊥)
    │ otherwise (and no dying) ⇒ ∃ why : STRING • out! = value(false, why)
    └─────────────────────────────────────────────────────────

=head2 socket_path

    ┌─ SocketPath ────────────────────────────────────────────
    │ dir? : STRING⊥
    │ out! : RESULT[PATH]
    ├─────────────────────────────────────────────────────────
    │ ¬ UnixSockets ⇒ ∃ m • out! = dies(m)
    │ let p = default_dir(dir?) / "class-shared.sock" in
    │     UnixSockets ∧ #p ≤ MAXPATH ⇒ out! = value(p)
    │     UnixSockets ∧ #p > MAXPATH ⇒ ∃ m • out! = dies(m)
    └─────────────────────────────────────────────────────────

=head2 check_socket_path

    ┌─ CheckSocketPath ───────────────────────────────────────
    │ path? : STRING⊥
    │ out!  : RESULT[PATH]
    ├─────────────────────────────────────────────────────────
    │ path? ≠ ⊥ ∧ 0 < #path? ≤ MAXPATH ⇒ out! = value(path?)
    │ path? = ⊥ ∨ #path? = 0           ⇒ ∃ m • out! = dies(m)
    │ path? ≠ ⊥ ∧ #path? > MAXPATH     ⇒ ∃ m • out! = dies(m)
    └─────────────────────────────────────────────────────────

=head2 poll_pause

    ┌─ PollPause ─────────────────────────────────────────────
    │ clock, clock' : ℝ
    ├─────────────────────────────────────────────────────────
    │ clock' ≥ clock + POLL_INTERVAL          it returns nothing
    └─────────────────────────────────────────────────────────

=head2 detach_standard_streams

    ┌─ DetachStandardStreams ─────────────────────────────────
    │ log? : PATH ; stdin, stdout, stderr : STREAM ; writable : ℙ PATH
    │ out! : 𝔹 × STRING⊥
    ├─────────────────────────────────────────────────────────
    │ stdin' = null
    │ log? ∈ writable ⇒ stdout' = stderr' = file(log?) ∧ out! = (true, ⊥)
    │ log? ∉ writable ⇒ stdout' = stderr' = null      ∧ out! = (true, ⊥)
    │ any reopen fails ⇒ ∃ why • out! = (false, why)
    └─────────────────────────────────────────────────────────

=head2 The unix socket probe (internal)

    ┌─ UnixSocketProbe ───────────────────────────────────────
    │ cache, cache' : {unknown, yes, no}
    ├─────────────────────────────────────────────────────────
    │ cache = unknown ⇒ cache' ∈ {yes, no}    asked once, by naming a socket and
    │                                         trying socketpair; both must work
    │ cache ≠ unknown ⇒ cache' = cache        the answer never changes in a run
    └─────────────────────────────────────────────────────────

=head1 STATE DIAGRAM

The functions in this file keep almost no state.  The one piece they do keep is
the answer to "can this perl make a unix socket?", which is worked out once,
the first time it is needed, and then never changes.

                  both tries work
    +---------+ -------------------------> +---------+ <---+
    | UNKNOWN |                            | UNIX_OK |     | every later call
    +---------+ ---+                       +---------+ ----+ (no change)
                   |  try fails
                   |                       +---------+ <---+
                   +---------------------> | NO_UNIX |     | every later call
                                           +---------+ ----+ (calls die)

A directory, as seen by L</ensure_dir>, moves through these states.  The
function does not remember them; they describe what it finds and what it does.

    +---------+   mkdir 0700 works    +---------+
    | MISSING | --------------------> | PRESENT |   (it existed, or was just made)
    +---------+                       +---------+
         |                              |      |
         | mkdir fails                  |      | I own it, and group and
         | (parent missing, no          |      | other cannot write to it
         |  permission, ...)            |      v
         |                              |   +------+
         |                              |   | SAFE |   returns (1, undef)
         |                              |   +------+
         |                              | someone else owns it, or
         |                              | group or other can write to it
         v                              v
      +------------------------------------+
      | REFUSED   returns (0, $why)        |
      +------------------------------------+

=over 4

=item UNKNOWN to UNIX_OK or NO_UNIX

Trigger: the first call to C<socket_path> or C<ensure_dir> (or the check in
F<Makefile.PL>).  Action: try to name a unix socket (C<pack_sockaddr_un>) and to
make a pair of connected ones (C<socketpair>).  The
answer is stored in C<$Class::Shared::UNIX_SOCKETS> and is never asked again.

=item UNIX_OK, no change

Trigger: any later call.  Action: none; C<socket_path> and C<ensure_dir> work as
described above.

=item NO_UNIX, no change

Trigger: any later call to C<socket_path> or C<ensure_dir>.  Action: the call
dies with a message saying that this perl has no unix sockets.

=item MISSING to PRESENT

Trigger: C<ensure_dir> on a directory that does not exist but whose parent does.
Action: C<mkdir> with mode 0700.

=item MISSING to REFUSED

Trigger: the C<mkdir> fails, for example because the parent does not exist.
Action: return C<(0, $reason)>.

=item PRESENT to SAFE

Trigger: C<ensure_dir> finds that this user owns the directory and that group
and other users cannot write to it.  Action: return C<(1, undef)>.

=item PRESENT to REFUSED

Trigger: C<ensure_dir> finds a different owner, or that group or other users can
write to it.  Action: return C<(0, $reason)>.

=back

=head1 LICENCE AND COPYRIGHT

Copyright 2026 Nigel Horne.

Class::Shared is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License, version 2, as published by the
Free Software Foundation.

Class::Shared is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the F<LICENSE> file for the full text.

If you use it, please let me know.

=cut

1;
