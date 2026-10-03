package App::Syslogd;

use strict;
use warnings;
use autodie qw(:all);

# Encapsulation of the _helpers.  Sub::Private's enforce mode must be
# chosen before the module is loaded, otherwise private subs are removed
# from the stash and $self->_x() breaks.
#
# Both modules declare a CHECK block.  When this module is loaded at run
# time (require, a plugin loader), CHECK has already happened, so Perl
# warns "Too late to run CHECK block" while compiling them; the warning is
# about their internals, so it is filtered here and nothing else is.
# The helpers are protected at the bottom of this file; see there for why.
BEGIN {
	# TODO: Data Flow Anomaly - this global is defined here and never restored, so every
	# package loaded later in the same process that uses Sub::Private also gets enforce
	# mode instead of the default namespace mode.  It cannot be localised: Sub::Private
	# reads it when it wraps the subs, at CHECK time.  Needs a per-package mode in
	# Sub::Private (e.g. "use Sub::Private { mode => 'enforce' }").
	$Sub::Private::config{mode} = 'enforce';
	local $SIG{__WARN__} = sub { warn(@_) unless($_[0] =~ /\AToo late to run CHECK block /) };
	require Sub::Private;
	require Sub::Protected;
}

use Carp qw(carp croak);
use Config;
use Fcntl qw(O_RDWR O_APPEND O_CREAT SEEK_SET SEEK_END);
use IO::Handle;
use IO::Socket::IP ();	# (): IO::Socket would export all of Socket's constants as methods
use Object::Configure;
use overload ();
use Params::Get;
use Params::Validate::Strict;
use Readonly;
use Socket qw(getnameinfo NI_NAMEREQD NI_NUMERICHOST NIx_NOSERV);
use Text::CSV;

use App::Syslogd::Cache;
use App::Syslogd::I18N;

our $VERSION = '0.002.0';

# Every tunable lives here, so it can be overridden from new() and so
# nothing in the code below is a magic number
Readonly our %DEFAULTS => (
	port => 514,			# RFC 5426 well-known port
	address => '0.0.0.0',		# IPv4 wildcard, as the original script used
	file => '/var/log/syslog/syslog.csv',	# The directory must exist; see INSTALLATION
	resolve => 1,			# Log host names rather than addresses
	dns_ttl => 300,			# Seconds to remember a reverse lookup
	dns_cache_bytes => 262_144,	# Upper bound on the reverse-lookup cache
);

# Scalar constants use Readonly::Scalar: "Readonly my $x" makes a tied
# scalar, and every read then costs a tied FETCH (about 45 times slower).
# Several of these are read for every datagram.

# Largest possible UDP payload, so datagrams are never silently truncated
# (RFC 5426 section 3.2 asks receivers to accept at least 2048 octets)
Readonly::Scalar my $RECV_BUFFER => 65_535;

# One-character datagrams are keep-alives or noise, never a log line
Readonly::Scalar my $MIN_MESSAGE_LENGTH => 2;

# PRI = facility * 8 + severity; RFC 5424 section 6.2.1 caps it at 191
Readonly::Scalar my $SEVERITIES_PER_FACILITY => 8;
Readonly::Scalar my $MAX_PRI => 191;

# RFC 3164 section 4.3.3: a message without a valid PRI is user.notice
Readonly::Scalar my $DEFAULT_PRI => 13;

# The log holds other hosts' messages, so only its owner may read it
Readonly::Scalar my $LOG_MODE => 0600;	## no critic (ProhibitLeadingZeros): a file mode is octal

# O_NOFOLLOW is not defined everywhere: on Windows, Fcntl exports the name
# but calling it dies ("Your vendor has not defined Fcntl macro").  Where it
# is missing, 0 leaves the open flags unchanged.  Windows symbolic links
# need administrator rights to create, so the attack it prevents is rare
# there; see LIMITATIONS.
Readonly::Scalar my $O_NOFOLLOW => eval { Fcntl::O_NOFOLLOW() } // 0;

# O_NONBLOCK makes opening a FIFO fail at once (ENXIO) instead of waiting
# for a reader.  Without it anyone able to create a FIFO where the log
# goes (a shared directory such as /tmp) could make the server hang for
# ever at start-up.  It has
# no effect on the regular files we accept.  Not defined on Windows.
Readonly::Scalar my $O_NONBLOCK => eval { Fcntl::O_NONBLOCK() } // 0;

# chmod() on a filehandle needs fchmod(), which Windows Perl does not have
# ("The fchmod function is unimplemented").  Windows does not use Unix
# permission bits anyway, so there is nothing to tighten; see LIMITATIONS.
# chmod() by name is not a substitute: the name may no longer be the file
# we checked.
Readonly::Scalar my $HAVE_FCHMOD => $Config{d_fchmod} ? 1 : 0;

# Column headings written to a brand-new log file.  VWF::Data::syslog_log
# reads these as its column names, so do not change them lightly.
Readonly my @CSV_HEADER => qw(Host facility severity msg);

# What Object::Configure adds that is kept on the object, besides settings
Readonly my @CONFIGURE_EXTRAS => qw(logger config_path);

# Strings that reach the C library (bind, open, the locale) must not hold
# a NUL: C stops reading there, so "127.0.0.1\0.evil" would bind to
# 127.0.0.1 while the object (and every message) named something else.
Readonly::Scalar my $NO_NUL => qr/\A[^\x00]+\z/;

# Parameter schema shared by new() and the API SPECIFICATION in the POD
Readonly my %NEW_SCHEMA => (
	port => { type => 'integer', min => 0, max => 65_535, optional => 1 },
	address => { type => 'string', min => 1, matches => $NO_NUL, optional => 1 },
	file => { type => 'string', min => 1, matches => $NO_NUL, optional => 1 },
	resolve => { type => 'boolean', optional => 1 },
	dns_ttl => { type => 'integer', min => 0, optional => 1 },
	dns_cache_bytes => { type => 'integer', min => 1, optional => 1 },
	language => { type => 'string', min => 1, matches => $NO_NUL, optional => 1 },
	cache => { type => 'object', can => ['compute'], optional => 1 },
	socket => { type => 'object', can => ['recv'], optional => 1 },
);

=head1 NAME

App::Syslogd - A small UDP syslog receiver that writes a CSV file

=head1 VERSION

Version 0.002.0

=head1 SYNOPSIS

=head2 1. Run a syslog server

This is what the program F<etc/syslogd> does.  It listens for messages
until it receives SIGTERM or SIGINT (Ctrl-C).

	use App::Syslogd;

	my $server = App::Syslogd->new(
		port => 5514,				# 514 needs root
		file => '/var/log/syslogd/remote.csv',
	);
	$server->open_socket()->reopen_log();	# fail now, not later
	print $server->i18n('listening', {
		address => $server->address(),
		port => $server->port(),
	}), "\n";
	$server->run();				# waits here until stopped
	print $server->i18n('shutdown', { count => $server->count() }), "\n";

=head2 2. Decode one message, without a network or a file

C<parse_message()> uses no state, so you can call it on the class.

	use App::Syslogd;

	my $record = App::Syslogd->parse_message('<34>su: authentication failure');
	print "facility $record->{facility}, severity $record->{severity}\n";
	# facility 4, severity 2

=head2 3. Record messages that your own code received

Use this when your program already has a socket loop, for example an event
loop that watches many sockets.

	use App::Syslogd;
	use IO::Socket::IP;

	my $recorder = App::Syslogd->new(file => '/var/log/remote.csv', resolve => 0);
	$recorder->reopen_log();

	my $socket = IO::Socket::IP->new(LocalPort => 5514, Proto => 'udp')
		or die "Cannot listen: $IO::Socket::errstr";
	while(my $peer = $socket->recv(my $datagram, 65535)) {
		$recorder->process($datagram, $peer);
	}

=head2 4. Use a socket that someone else opened, for a fixed time

Pass the socket to C<new()>, for example one received from systemd socket
activation, or one opened before giving up root.  C<stop()> ends C<run()>.

	my $server = App::Syslogd->new(socket => $already_bound_socket, file => $file);

	local $SIG{ALRM} = sub { $server->stop() };
	alarm(3600);		# stop after one hour
	$server->run();

=head2 5. Change how the sender is written in the log

C<_peer_name()> is protected: a subclass may replace it.

	package My::Syslogd;
	use parent 'App::Syslogd';
	use Socket ();

	# Write "name [address]" instead of just the name
	sub _peer_name {
		my ($self, $peer) = @_;
		my $name = $self->SUPER::_peer_name($peer);
		my (undef, $address) = Socket::getnameinfo($peer, Socket::NI_NUMERICHOST());
		return "$name [$address]";
	}

=head1 DESCRIPTION

This distribution has two parts: the module App::Syslogd, and the program
F<etc/syslogd> that wraps it.  Installing from CPAN installs only the
module.  The program is not installed by C<make install>; copy it by hand
(see L</INSTALLATION>).

=head2 What syslog is

Many machines (servers, routers, printers, firewalls) can send their log
messages over the network with the I<syslog> protocol.  Each message is one
UDP packet, called a I<datagram>.  A message usually starts with a number in
angle brackets, the I<PRI> (priority), for example C<< <34> >>.  The PRI
holds two smaller numbers:

=over 4

=item * B<facility> = PRI divided by 8, rounded down (0 to 23).  It says which
part of the system sent the message, for example 4 means "security".

=item * B<severity> = the remainder of PRI divided by 8 (0 to 7).  It says how
serious the message is: 0 is "emergency" and 7 is "debug".

=back

So C<< <34> >> means facility 4 (34 / 8 = 4) and severity 2 (34 - 32 = 2).

=head2 What this module does

It waits for syslog datagrams and adds one line to a CSV file for each one.
The first line of a new file names the columns:

	"Host","facility","severity","msg"
	"router.example.com","4","2","su: authentication failure"

=over 4

=item * B<Host> is the name of the machine that sent the message.  The name
is found with the normal system lookup (F</etc/hosts>, then DNS) and
remembered for a few minutes.  If no name is found, or if you turn names
off, the IP address is written instead.  IPv4 and IPv6 both work.  Whoever
controls an address controls its reverse-DNS name, so control characters in
a name are written as C<\xNN>, as in the message.

=item * B<facility> and B<severity> come from the PRI.  If the PRI is missing
or not valid, the message is still kept: it is recorded as facility 1,
severity 5 ("user.notice"), and the whole datagram becomes the message.
RFC 3164 section 4.3.3 asks for this.  A valid PRI is a number from 0 to 191
with no extra leading zeros.

=item * B<msg> is the rest of the datagram.  Line endings at the end are
removed.  Other control characters, including a newline in the middle, are
written as C<\xNN> (for example C<\x0A>).  So every message is exactly one
line, and nobody can create a fake extra line by sending a newline.

=back

=head2 Other behaviour

=over 4

=item * Signal B<SIGHUP> closes and reopens the log file.  Log rotation tools
such as logrotate use this: they rename the file, then send SIGHUP, and the
server starts a new file.

=item * Signals B<SIGTERM> and B<SIGINT> stop the server cleanly.

=item * The log file is created so that only its owner can read it (mode
0600).  The server will not write through a symbolic link or a hard link, or
into a file that another user owns.  An existing file that is not empty
must start with the column-names line, so the server only ever adds to its
own logs: even as root, a wrong setting cannot make it append to (or change
the permissions of) some other file, such as F</etc/passwd>.  This protects
against attacks that trick a root process into overwriting a file.  (Windows
is weaker here: see L</LIMITATIONS>.)

=item * Datagrams up to 65535 bytes (the largest UDP size) are read
completely.  Datagrams shorter than 2 characters are ignored.

=back

=head1 COMMAND LINE

The program F<etc/syslogd> is a small wrapper around this module:

	/usr/local/etc/syslogd [--port 514] [--address 0.0.0.0] [--file /var/log/syslog/syslog.csv]
		[--no-resolve] [--language en]

=over 4

=item C<--port> - the UDP port to listen on.  The default is 514, the
standard syslog port.  Ports below 1024 need root.

=item C<--address> - the local address to listen on.  The default
C<0.0.0.0> means "every IPv4 address of this machine".  Use C<::> for IPv6.

=item C<--file> - the CSV log file.  The default is
F</var/log/syslog/syslog.csv>.  The directory must exist and be writable by
the user that runs the server (see L</INSTALLATION>).  On Debian, Ubuntu and
their derivatives F</var/log/syslog> is the system log file, so give
C<--file> there (see L</LIMITATIONS>).

=item C<--no-resolve> - write IP addresses instead of host names.  This is
faster on a busy server.

=item C<--language> - the language of the program's own messages, for example
C<en>.  By default it comes from the environment (C<LANG> and similar).

=back

Send B<SIGHUP> to reopen the log file.  Send B<SIGTERM>, or press Ctrl-C, to
stop.

=head2 Log rotation

Rotate the log by renaming it and then sending SIGHUP, so that the server
starts a new file.  See L</SAMPLE CONFIGURATION> for logrotate and
newsyslog settings.

=head1 INSTALLATION

Install the module from CPAN:

	cpanm App::Syslogd

or from a git checkout:

	perl Makefile.PL && make && make test && sudo make install

Then copy the program by hand, and create the directory for the default
log file (the server does not create directories):

	sudo cp etc/syslogd /usr/local/etc/
	sudo mkdir -m 700 /var/log/syslog

Make that directory belong to the user that runs the server, if it is not
root.  On Debian and Ubuntu F</var/log/syslog> is already a file; use
another directory and C<--file> there.

C<make install> does not install the program on purpose.  It would put it in
a F<bin> directory, and a program called F<syslogd> there could hide the
system's own F</usr/sbin/syslogd>.

To use a git checkout without installing the module, copy the module next to
the program:

	sudo cp -r lib/App /usr/local/lib/

The program looks for modules in F<../lib> relative to itself (that is
F</usr/local/lib> after installation, or F<lib/> in a git checkout), and also
in Perl's normal module directories.

=head1 SAMPLE CONFIGURATION

These samples run the server as its own user, C<syslogd>, writing to
F</var/log/syslog/remote.csv>.  Adjust the names and paths to suit.

Three things shape them:

=over 4

=item * The server only writes to a log file that it owns (see
L</DESCRIPTION>), so the file must live in a directory the C<syslogd> user
can write to.

=item * The server does not put itself in the background and writes no
process-id file: run it under a service manager that keeps it in the
foreground (systemd), or through F<daemon(8)> (FreeBSD).

=item * The service is called C<app-syslogd> (C<app_syslogd> on FreeBSD)
so that it does not clash with the operating system's own syslog daemon.

=back

Create the user first, for example:

	# Linux
	useradd --system --no-create-home --shell /usr/sbin/nologin syslogd

	# FreeBSD
	pw useradd syslogd -d /nonexistent -s /usr/sbin/nologin -c "App::Syslogd"
	mkdir -p /var/log/syslog && chown syslogd /var/log/syslog && chmod 700 /var/log/syslog

=head2 systemd (Linux)

Save as F</etc/systemd/system/app-syslogd.service>, then run
C<systemctl daemon-reload> and C<systemctl enable --now app-syslogd>.

	[Unit]
	Description=App::Syslogd UDP syslog receiver
	Documentation=https://metacpan.org/pod/App::Syslogd
	After=network-online.target
	Wants=network-online.target

	[Service]
	Type=simple
	User=syslogd
	Group=syslogd
	# Port 514 is below 1024: grant just that right, not root
	AmbientCapabilities=CAP_NET_BIND_SERVICE
	CapabilityBoundingSet=CAP_NET_BIND_SERVICE
	# Creates /var/log/syslog, owned by the user above
	LogsDirectory=syslog
	LogsDirectoryMode=0700
	ExecStart=/usr/local/etc/syslogd --port 514 --file /var/log/syslog/remote.csv
	# SIGHUP reopens the log after rotation
	ExecReload=/bin/kill -HUP $MAINPID
	Restart=on-failure
	RestartSec=5
	# Hardening: the server needs nothing more
	NoNewPrivileges=yes
	ProtectSystem=strict
	ProtectHome=yes
	PrivateTmp=yes
	PrivateDevices=yes
	RestrictAddressFamilies=AF_INET AF_INET6 AF_UNIX

	[Install]
	WantedBy=multi-user.target

SIGTERM (C<systemctl stop>) stops the server cleanly with exit status 0.
The server's start-up and shutdown lines go to the journal
(C<journalctl -u app-syslogd>).

=head2 rc.d and service (FreeBSD)

Save as F</usr/local/etc/rc.d/app_syslogd> (mode 0555), then add
C<app_syslogd_enable="YES"> to F</etc/rc.conf> and run
C<service app_syslogd start>.

	#!/bin/sh

	# PROVIDE: app_syslogd
	# REQUIRE: NETWORKING
	# KEYWORD: shutdown

	. /etc/rc.subr

	name="app_syslogd"
	rcvar="app_syslogd_enable"

	load_rc_config $name

	: ${app_syslogd_enable:="NO"}
	: ${app_syslogd_user:="root"}
	: ${app_syslogd_options:="--port 514 --file /var/log/syslog/remote.csv"}

	pidfile="/var/run/${name}.pid"

	# daemon(8) puts the server in the background and writes the pid
	# file (-p: the server's own pid, so SIGHUP reaches it)
	command="/usr/sbin/daemon"
	command_args="-f -p ${pidfile} -u ${app_syslogd_user} /usr/local/etc/syslogd ${app_syslogd_options}"

	# The running process is "perl /usr/local/etc/syslogd ..."
	procname="/usr/local/etc/syslogd"
	command_interpreter="/usr/local/bin/perl"

	# service app_syslogd reload: reopen the log
	extra_commands="reload"
	sig_reload="HUP"

	run_rc_command "$1"

The options go in C<app_syslogd_options>, not C<app_syslogd_flags>:
F<rc.subr> would put C<_flags> before C<command_args>, that is, give them to
F<daemon(8)>.  Binding port 514 needs root on FreeBSD, so the sample runs as
root; to run as C<syslogd>, use a port above 1023 (or
L<mac_portacl(4)>) and set C<app_syslogd_user="syslogd">.  The log file
must belong to whichever user runs the server.

=head2 logrotate (Linux)

Save as F</etc/logrotate.d/app-syslogd>.

	/var/log/syslog/remote.csv {
		weekly
		rotate 8
		compress
		delaycompress
		missingok
		# The directory belongs to syslogd, so rotate as that user
		su syslogd syslogd
		# Never copytruncate: see below
		create 0600 syslogd syslogd
		postrotate
			systemctl reload app-syslogd.service
		endscript
	}

Do not use C<copytruncate>.  It empties the log in place without telling
the server, which then carries on writing rows to a file with no column
names; at the next reopen the server would refuse that file, because it no
longer starts with the header line.  C<create> (or no C<create>: the server
makes the file itself on SIGHUP) is what the server expects.

=head2 newsyslog (FreeBSD)

Add to F</etc/newsyslog.conf> (or a file in F</usr/local/etc/newsyslog.conf.d/>):

	# logfilename                    owner:group  mode count size when  flags pid_file                  sig
	/var/log/syslog/remote.csv      root:wheel   600  8     *    @T00  JC    /var/run/app_syslogd.pid  1

Creates the new, empty file; signal 1 (SIGHUP) makes the server
reopen it.  Use the owner that runs the server.

=head2 Monit and M/Monit

Add to F</etc/monit/monitrc> (Linux) or F</usr/local/etc/monitrc>
(FreeBSD).  M/Monit collects the results when F<monitrc> names it with
C<set mmonit>.

	# Report to M/Monit (optional)
	set mmonit https://monit:monit@mmonit.example.com:8443/collector

	# Linux, with the systemd unit above
	check process app-syslogd matching "/usr/local/etc/syslogd"
		start program = "/bin/systemctl start app-syslogd"
		stop program  = "/bin/systemctl stop app-syslogd"
		if 5 restarts within 5 cycles then alert

	# FreeBSD, with the rc.d script above, use instead:
	#	check process app_syslogd with pidfile /var/run/app_syslogd.pid
	#		start program = "/usr/sbin/service app_syslogd start"
	#		stop program  = "/usr/sbin/service app_syslogd stop"

	# The log must stay private and be written to
	check file app-syslogd-log with path /var/log/syslog/remote.csv
		if failed permission 600 then alert
		if failed uid "syslogd" then alert
		if timestamp > 1 hour then alert

Monit's UDP port test is not used: syslog never answers, so a port test
cannot show that messages are being recorded.  The timestamp check does:
change C<1 hour> to suit how often your hosts send messages.

=head1 DEPENDENCIES

Perl 5.14 or later, and these modules: L<autodie> (which needs
L<IPC::System::Simple>), L<IO::Socket::IP>, L<Locale::Maketext>,
L<Object::Configure>, L<Params::Get>, L<Params::Validate::Strict>,
L<Readonly>, L<Socket>,
L<Sub::Private>, L<Sub::Protected> and L<Text::CSV>.  F<Makefile.PL> lists
the minimum versions.

=head1 FILES

=over 4

=item F<etc/syslogd> - the command-line program.  Install it as
F</usr/local/etc/syslogd>.

=item F<lib/App/Syslogd.pm> - this module.

=item F<lib/App/Syslogd/I18N.pm> and F<lib/App/Syslogd/I18N/en.pm> - the
messages that people see, and their English text.

=item F<lib/App/Syslogd/Cache.pm> - the built-in cache for host names.

=item F<t/> - the tests.  Run them with C<prove -l t/>.

=item F<www/> - a web page that shows the log.  It is only in the git
repository, not in the CPAN distribution.

=back

=head1 ENCODING

The module works with B<bytes>, not with decoded text.  It never decodes or
encodes anything itself.

=over 4

=item * B<Datagrams> (C<parse_message()>, C<process()>, and everything that
C<run()> receives) can contain any bytes.  UTF-8 text, other non-ASCII text
and emoji are written to the file exactly as they arrived.  Invalid UTF-8 is
also written unchanged.  Only bytes 0x00 to 0x1F and 0x7F are changed (to
C<\xNN>).  Bytes 0x80 to 0x9F are not changed, so a UTF-8 character is never
broken.

=item * If you call C<parse_message()> or C<process()> yourself with a Perl
I<character> string (text that came from C<decode()>, or that contains a
character above 255, such as an emoji written as C<"\x{1F600}">), first
encode it to bytes, for example with C<Encode::encode('UTF-8', $text)>.
Otherwise Perl prints a "Wide character" warning when the line is written.

=item * B<The file name> (C<file>) is passed to the operating system as
bytes.  A name with non-ASCII characters must be given as encoded bytes
(normally UTF-8 on Unix).

=item * B<Host names> come from the system resolver.  An international domain
name normally arrives in its ASCII form (C<xn--...>).

=item * B<The language tag> (C<language>) must be ASCII, for example C<en-gb>.

=item * B<Messages from i18n()> are Perl strings.  The English messages are
ASCII, but a value you pass in (for example a file name) is copied into the
message as it is.  If you print a message that contains wide characters,
set an output layer first: C<binmode(STDOUT, ':encoding(UTF-8)')>.

=back

=head1 COMMON PITFALLS

=over 4

=item * B<undef means "use the default".>  C<< new(file => undef) >> gives the
default file, not an empty file name.  This is useful when you pass options
straight from L<Getopt::Long>, but it means you cannot use C<undef> to switch
something off.  To turn off host names, use C<< resolve => 0 >>.

=item * B<The environment wins over your arguments.>  An
C<App__Syslogd__port> environment variable, or a configuration file, changes
the port even when you pass C<port> to C<new()>.  This is how
L<Object::Configure> works.  Check the environment when a setting seems to
be ignored.

=item * B<The options are merged one level deep only.>  Each option you give
replaces the default with the same name; nothing is merged inside a value.
Objects you pass (C<cache>, C<socket>) are shared, not copied: two servers
given the same C<cache> object share their host name answers.

=item * B<True and false.>  C<resolve> accepts 1, 0, and the words C<true>,
C<false>, C<yes>, C<no>, C<on> and C<off>.  Any other value, such as 2, is an
error.

=item * B<Order of calls.>  C<process()> needs an open log, so call
C<reopen_log()> first.  C<run()> opens the socket and the log by itself if
you have not.

=item * B<Signals are handled only inside run().>  Before C<run()> starts and
after it returns, SIGHUP has its normal effect, which is to end the program.
C<run()> puts back your own signal handlers when it returns.

=item * B<stop() before run() does nothing.>  C<run()> sets the "running"
flag when it starts, so an earlier C<stop()> is forgotten.

=item * B<run() closes everything when it returns.>  If you call C<run()>
again, it opens a new socket.  With C<< port => 0 >>, the new socket can get
a different port number.

=item * B<A failed reopen stops run().>  If SIGHUP arrives and the log file
cannot be opened (for example, the directory was removed), C<run()> dies
with the error.  The socket stays open and the log stays closed.

=item * B<An existing log file is made private.>  C<reopen_log()> changes the
file's permissions to 0600 without asking (except on Windows; see
L</LIMITATIONS>).

=item * B<Do not rotate with copytruncate.>  Emptying the log in place
leaves the server writing rows with no column names, and the next reopen
then refuses the file.  Rename and send SIGHUP instead (see
L</SAMPLE CONFIGURATION>).

=item * B<Only an empty file or one of its own logs is accepted.>  A file
with content must start with the line C<"Host","facility","severity","msg">
(with a Unix or Windows line end), or C<reopen_log()> refuses it and leaves
it untouched.  Logs from older versions start with that line too.  To reuse
a file that does not, empty it or remove it first.

=item * B<A short datagram is ignored silently.>  After removing line endings
at the end, a datagram must have at least 2 characters.  C<parse_message()>
then returns C<undef>, and C<process()> writes nothing and does not count it.

=item * B<A missing sender is not an error.>  C<process($datagram, undef)>
writes the message with an empty Host column.

=item * B<port() and address() change meaning.>  Before C<open_socket()> they
return what you asked for.  After it they return what the system actually
gave, so C<< port => 0 >> becomes a real port number.

=item * B<Backslashes are not escaped.>  A message that really contains the
four characters C<\x0A> looks the same in the file as an escaped newline.

=back

=head1 METHODS

Every method except C<parse_message()> and C<i18n()> needs an object made by
C<new()>; those two also work on the class.  Methods that have nothing
useful to return give back the object, so you can chain calls:

	App::Syslogd->new(port => 5514)->open_socket()->reopen_log()->run();

No method changes the caller's C<$_>, C<$!> or C<$@>, or an C<alarm()>
that is counting down.  (A method that dies sets C<$@>, as C<die> always
does.)

The mathematical description of each method is in
L</FORMAL SPECIFICATION>, and the life cycle of an object is in
L</STATE DIAGRAM>, both at the end of this document.

=head2 new

Purpose: make a new server object.  It does not open the network or the
file yet, so you can create and inspect it without any special permissions.

Args: all optional, given as a list of pairs or as one hash reference.  An
option given as C<undef> uses its default.

Every option can also be set outside the program, through
L<Object::Configure>: in a configuration file (for example
F<~/.conf/app-syslogd.yml>), or in an environment variable named
C<App__Syslogd__> followed by the option, such as
C<App__Syslogd__port=5514>.  B<Those settings win over the arguments given
to new()>.  They are checked in exactly the same way as arguments.

=over 4

=item * C<port> - the UDP port number, 0 to 65535.  Default 514.  0 means
"let the system choose a free port"; call C<port()> after C<open_socket()>
to find out which one.

=item * C<address> - the local address to listen on.  Default C<0.0.0.0> (all
IPv4 addresses).  Use C<::> for IPv6.

=item * C<file> - the CSV log file.  Default F</var/log/syslog/syslog.csv>;
its directory must already exist.

=item * C<resolve> - true (the default) to write host names, false to write
IP addresses.

=item * C<dns_ttl> - how many seconds to remember a host name.  Default 300.

=item * C<dns_cache_bytes> - the most memory, in bytes, used to remember host
names.  Default 262144.  An estimate: see L<App::Syslogd::Cache/new>.  It
does not apply to a C<cache> you supply.

=item * C<language> - the language of messages, such as C<en>.  Default: from
the environment.

=item * C<cache> - your own cache for host names, instead of the built-in
L<App::Syslogd::Cache>.  Any object with a L<CHI>-style C<compute()> method,
for example a L<CHI> cache shared between several servers.

=item * C<socket> - a socket that is already open, instead of opening one.
Any object with a C<recv()> method.

=back

Returns: the new object.  Besides the options, it holds the C<logger> (a
L<Log::Abstraction> object) and C<config_path> that L<Object::Configure>
provides.

Side Effects: reads configuration files and environment variables (see
above).  Does not open the network or the log.  Dies if an option is
unknown, or if an option has a wrong value, wherever the value came from.

Usage:

	my $server = App::Syslogd->new({ port => 514, resolve => 0 });

=head3 EXAMPLE

	# Listen on a port that does not need root, and write addresses only
	my $server = App::Syslogd->new(port => 5514, resolve => 0);

	# Options from Getopt::Long: options not given stay undef = default
	my %opts;
	GetOptions(\%opts, 'port=i', 'file=s');
	my $server2 = App::Syslogd->new(\%opts);

=head3 API SPECIFICATION

=head4 INPUT

	{
		port => { type => 'integer', min => 0, max => 65535, optional => 1 },
		address => { type => 'string', min => 1, optional => 1 },
		file => { type => 'string', min => 1, optional => 1 },
		resolve => { type => 'boolean', optional => 1 },
		dns_ttl => { type => 'integer', min => 0, optional => 1 },
		dns_cache_bytes => { type => 'integer', min => 1, optional => 1 },
		language => { type => 'string', min => 1, optional => 1 },
		cache => { type => 'object', can => ['compute'], optional => 1 },
		socket => { type => 'object', can => ['recv'], optional => 1 },
	}

Domains (equivalence partitions and boundaries; t/domain.t tests each):

	+-----------------+--------------------------------+-----------------------+-------------------------------+
	| Option          | Valid partitions               | Boundaries            | Invalid partitions            |
	+-----------------+--------------------------------+-----------------------+-------------------------------+
	| port            | 0 (the kernel chooses);        | -1 no, 0 yes,         | fractions (514.5), hex        |
	|                 | 1-1023 (needs root);           | 65535 yes, 65536 no   | (0x10), "1_000", text, "",    |
	|                 | 1024-65535.  A numeric string  |                       | non-ASCII digits, references  |
	|                 | is read as its number: " 514 ",|                       |                               |
	|                 | "+514", "0514", "5e2", "5.0"   |                       |                               |
	| address         | IPv4 or IPv6 literal, or a     | 1 character is        | "" (new()); an address this   |
	|                 | host name: any non-empty       | accepted by new()     | machine does not have (fails  |
	|                 | string here                    |                       | in open_socket())             |
	| file            | any non-empty string of bytes; | 1 byte; the system's  | ""; references.  A name over  |
	|                 | non-ASCII names as encoded     | name limit (usually   | the system limit, or an       |
	|                 | (UTF-8) bytes                  | 255 bytes)            | existing file with content    |
	|                 |                                |                       | that does not start with the  |
	|                 |                                |                       | header, fails in reopen_log() |
	| resolve         | true: 1 true TRUE yes on;      | -                     | any other spelling: "", 2,    |
	|                 | false: 0 false FALSE no off    |                       | "Yes", "On", " 1", "t"        |
	| dns_ttl         | whole seconds, 0 or more (0:   | -1 no, 0 yes; no      | fractions, text, references   |
	|                 | names are not reused)          | upper limit           |                               |
	| dns_cache_bytes | whole bytes, 1 or more         | 0 no, 1 yes; no upper | fractions, text, references   |
	|                 |                                | limit                 |                               |
	| language        | any non-empty tag; tags with   | 1 character is        | "" (refused); unknown or      |
	|                 | no lexicon (fr, x, i-klingon)  | accepted              | malformed tags are not an     |
	|                 | fall back to English           |                       | error: they give English      |
	| cache, socket   | an object with compute() /     | -                     | plain hashes, code, globs, an |
	|                 | recv()                         |                       | object without the method     |
	+-----------------+--------------------------------+-----------------------+-------------------------------+

C<address>, C<file> and C<language> must not contain a NUL byte (refused:
"must match pattern"): the C library would stop reading at the NUL, so the
server would bind or write somewhere other than the value it reports.

An undef value is in no partition: it means "use the default".  Options
are checked one by one, so the error names the first invalid option even
when the others are at their limits.

=head4 OUTPUT

	{ type => 'object', isa => 'App::Syslogd' }

=head3 MESSAGES

	+------------------------------------+--------------------------+-----------------------------+
	| Message (dies)                     | Meaning                  | What to do                  |
	+------------------------------------+--------------------------+-----------------------------+
	| validate_strict: Unknown parameter | An option name is wrong  | Check the spelling against  |
	|   'x'                              |                          |   the list above            |
	| validate_strict: Parameter 'port'  | A value is the wrong     | Use a whole number from 0   |
	|   (x) must be an integer           |   type                   |   to 65535                  |
	| validate_strict: Parameter 'port'  | A number is out of range | Use a value inside the      |
	|   (x) must be no more than 65535   |                          |   range shown above         |
	| validate_strict: Parameter 'X'     | A number is below its    | Use a value inside the      |
	|   (x) must be at least 0, or must  |   minimum (port, dns_ttl |   range in the Domains      |
	|   be a positive number             |   at 0; dns_cache_bytes  |   table                     |
	|                                    |   at 1)                  |                             |
	| validate_strict: Parameter         | Not a true/false value   | Use 1, 0, true, false, yes, |
	|   'resolve' (x) must be a boolean  |                          |   no, on, off, TRUE, FALSE  |
	| validate_strict: Parameter 'X'     | address, file or language| Remove the NUL byte         |
	|   (x) must match pattern ...       |   contains a NUL byte    |                             |
	+------------------------------------+--------------------------+-----------------------------+

=head3 PSEUDOCODE

	check the options against the schema (die if one is wrong)
	remove options whose value is undef
	start from the defaults, then copy the options over them
	set the message counter to 0
	choose the message language
	if no cache was given, make an in-memory cache
	make the CSV writer
	return the object

=cut

sub new
{
	my $class = shift;

	# Keep the caller's $! and $@: system calls and modules used below
	# (Params::Validate::Strict, sockets, files) change them.  A
	# croak still reaches the caller: since Perl 5.14 die sets $@ after
	# locals are restored.
	local ($!, $@);

	# Check the caller's own arguments first, so that a misspelt option
	# is reported as such.  Accept a hash, a hashref or nothing at all.
	my $params = Params::Validate::Strict::validate_strict({
		schema => \%NEW_SCHEMA,
		input => Params::Get::get_params(undef, \@_) || {},
	});

	# Object::Configure merges in configuration files and App__Syslogd__*
	# environment variables (which win over the arguments) and adds a
	# logger.  Settings from there are validated too: they used to go in
	# unchecked, so App__Syslogd__port=70000 was accepted.  Only the
	# settings this module uses are checked and kept, plus the logger and
	# config_path that Object::Configure provides; sections meant for other
	# classes are dropped.
	my $configured = Object::Configure::configure($class, { %{$params} });
	my $args = Params::Validate::Strict::validate_strict({
		schema => \%NEW_SCHEMA,
		input => { map { $_ => $configured->{$_} } grep { exists($NEW_SCHEMA{$_}) } keys %{$configured} },
	});
	foreach my $key (@CONFIGURE_EXTRAS) {
		$args->{$key} = $configured->{$key} if(defined($configured->{$key}));
	}

	# An undef value means "use the default": without this,
	# new(file => undef) replaced the default with undef and failed later,
	# far from the mistake
	delete @{$args}{grep { !defined($args->{$_}) } keys %{$args}};

	# Caller's values win over defaults (a one-level merge: nothing nested)
	my $self = bless { %DEFAULTS, %{$args}, count => 0 }, $class;

	# One handle per object: two servers in one process may speak
	# different languages
	$self->{lh} = App::Syslogd::I18N->handle($self->{language});

	# Reverse DNS is synchronous; without a cache one slow resolver would
	# stall the receive loop for every packet from that host.  The built-in
	# cache answers a hit with one hash lookup (a CHI Memory cache took
	# about 17 microseconds, a third of the time per datagram); a CHI
	# object can still be passed in as "cache".
	$self->{cache} ||= App::Syslogd::Cache->new(max_bytes => $self->{dns_cache_bytes});

	# binary => 1 permits non-ASCII bytes; always_quote matches the
	# header row style the original script wrote
	$self->{csv} = Text::CSV->new({ binary => 1, eol => "\n", always_quote => 1 });

	return $self;
}

=head2 open_socket

Purpose: start listening for UDP datagrams on the configured address and
port.  If the port is below 1024, do this before your program gives up root.

Args: none.

Returns: the object, so you can chain another call.

Side Effects: opens a UDP socket.  Does nothing if a socket is already open,
including one given to C<new()>.

Usage:

	$server->open_socket();

=head3 EXAMPLE

	# Let the system choose a free port, then ask which one it chose
	my $server = App::Syslogd->new(port => 0)->open_socket();
	print 'Listening on port ', $server->port(), "\n";

=head3 API SPECIFICATION

=head4 INPUT

	{}

=head4 OUTPUT

	{ type => 'object', isa => 'App::Syslogd' }

=head3 MESSAGES

	+---------------------------------+---------------------------+------------------------------+
	| Message (dies)                  | Meaning                   | What to do                   |
	+---------------------------------+---------------------------+------------------------------+
	| Could not create a UDP socket   | The system refused: the   | Run as root for ports below  |
	|   on ADDR port N: ERROR         |   port is in use, needs   |   1024, stop the other       |
	|                                 |   root, or the address is |   syslog server, or correct  |
	|                                 |   wrong                   |   the address                |
	+---------------------------------+---------------------------+------------------------------+

=cut

sub open_socket
{
	my $self = shift;

	# Keep the caller's $! and $@ (see new()).  $IO::Socket::errstr is a
	# global too: start it empty, or a constructor that fails without
	# setting it would report an older, unrelated socket error.
	local ($!, $@);
	local $IO::Socket::errstr = '';

	# IO::Socket::IP handles both families; IO::Socket::INET is IPv4-only
	$self->{socket} ||= IO::Socket::IP->new(
		LocalHost => $self->{address},
		LocalPort => $self->{port},
		Proto => 'udp',
	) || croak($self->i18n('socket_failed', {
		address => $self->{address},
		port => $self->{port},
		error => $IO::Socket::errstr || "$!",
	}));

	return $self;
}

=head2 port

Purpose: tell you the UDP port number.

Args: none.

Returns: a whole number from 0 to 65535.  Before C<open_socket()> it is the
port you asked for.  After it, it is the port really in use, so
C<< port => 0 >> becomes the number the system chose.  If the socket was
given to C<new()> and has no C<sockport()> method (a simple test double, for
example), it is the port you asked for.

Side Effects: none.

Usage:

	my $port = $server->port();

=head3 EXAMPLE

	print App::Syslogd->new()->port(), "\n";	# 514

=head3 API SPECIFICATION

=head4 INPUT

	{}

=head4 OUTPUT

	{ type => 'integer', min => 0, max => 65535 }

Domain: 0 to 65535.  0 only before open_socket() with C<< port => 0 >>;
after open_socket(), 1 to 65535.

=head3 MESSAGES

None.

=cut

sub port
{
	my $self = shift;

	# An injected test socket may not know its port, so ask only real ones
	my $socket = $self->{socket};

	return ($socket && $socket->can('sockport')) ? $socket->sockport() : $self->{port};
}

=head2 address

Purpose: tell you the local address the server listens on.

Args: none.

Returns: a string, such as C<0.0.0.0> or C<::1>.  Before C<open_socket()> it
is the address you asked for.  After it, it is the address the system reports.
If the socket was given to C<new()> and has no C<sockhost()> method, it is
the address you asked for.

Side Effects: none.

Usage:

	my $address = $server->address();

=head3 EXAMPLE

	print App::Syslogd->new(address => '::')->address(), "\n";	# ::

=head3 API SPECIFICATION

=head4 INPUT

	{}

=head4 OUTPUT

	{ type => 'string', min => 1 }

=head3 MESSAGES

None.

=cut

sub address
{
	my $self = shift;

	# Mirrors port(): injected test sockets need not know their address
	my $socket = $self->{socket};

	return ($socket && $socket->can("sockhost")) ? $socket->sockhost() : $self->{address};
}

=head2 count

Purpose: tell you how many datagrams have been written to the log.

Args: none.

Returns: a whole number, 0 or more.  Ignored datagrams (shorter than 2
characters) are not counted.  A datagram that could not be written because
the disk was full is counted.

Side Effects: none.

Usage:

	print $server->count(), " messages\n";

=head3 EXAMPLE

	$server->reopen_log()->process('<13>hello', $peer);
	print $server->count(), "\n";	# 1

=head3 API SPECIFICATION

=head4 INPUT

	{}

=head4 OUTPUT

	{ type => 'integer', min => 0 }

Domain: 0 or more; it only ever grows, by one for each datagram that was
not too short.

=head3 MESSAGES

None.

=cut

sub count
{
	my $self = shift;

	return $self->{count};
}

=head2 reopen_log

Purpose: open the CSV log file, closing it first if it is already open.  Use
it once at the start.  C<run()> also calls it when SIGHUP arrives, so that
after a log rotation tool renames the file, a new file is started.

Args: none.

Returns: the object, so you can chain another call.

Side Effects:

=over 4

=item * Closes the log file if it is open.

=item * Creates the file if it does not exist, readable only by its owner.

=item * Writes the column names if the file is empty.

=item * Refuses (and does not change) a file with content that does not
start with the column names: only the server's own logs are reused.

=item * Changes an existing file's permissions to 0600 (not on Windows),
after the checks above.

=item * Dies, leaving no log open, if the file cannot be used safely.

=back

Usage:

	$server->reopen_log();

=head3 EXAMPLE

	# Open the log before starting, so that a problem is reported at once
	my $server = App::Syslogd->new(file => '/var/log/remote.csv');
	eval { $server->reopen_log(); 1 } or die "Cannot start: $@";

=head3 API SPECIFICATION

=head4 INPUT

	{}

=head4 OUTPUT

	{ type => 'object', isa => 'App::Syslogd' }

=head3 MESSAGES

	+-------------------------------+--------------------------------+-------------------------------+
	| Message (dies)                | Meaning                        | What to do                    |
	+-------------------------------+--------------------------------+-------------------------------+
	| Could not open log file F:    | The system could not open the  | Create the directory, or fix  |
	|   ERROR                       |   file.  ERROR is the system's |   its permissions.  Remove a  |
	|                               |   reason.  A symbolic link, a  |   symbolic link or FIFO; give |
	|                               |   directory or a FIFO (named   |   a file name, not a          |
	|                               |   pipe) also gives this        |   directory                   |
	| Refusing to log to F: it must | F is a hard link or another    | Remove F and let the server   |
	|   be a regular file, owned by |   user's file                  |   create it again             |
	|   this user, with exactly one |                                |                               |
	|   link                        |                                |                               |
	| Refusing to log to F: it is   | F has content but is not one   | Check the file setting; empty |
	|   not empty and does not      |   of the server's logs (it     |   or remove F if it really is |
	|   start with the syslog       |   does not start with the      |   meant to be the log         |
	|   header line                 |   column names)                |                               |
	| Could not write to log file   | The column names could not be  | Free some disk space          |
	|   F: ERROR                    |   written to a new file        |                               |
	+-------------------------------+--------------------------------+-------------------------------+

=cut

sub reopen_log
{
	my $self = shift;

	# Keep the caller's $! and $@ (see new())
	local ($!, $@);

	# Closing first means a failed reopen leaves no stale handle that
	# would silently keep writing to the rotated file
	$self->_close_log();
	$self->{fh} = $self->_open_log();

	return $self;
}

=head2 parse_message

Purpose: split one datagram into its facility, severity and message text.
It uses no state and writes nothing, so you can call it on the class and use
it on its own.

Args: one datagram, as a string of bytes.

Returns: C<undef> if the datagram is too short to be a message (fewer than 2
characters after removing line endings at the end).  Otherwise a hash
reference with these keys:

=over 4

=item * C<facility> - 0 to 23.

=item * C<severity> - 0 to 7.

=item * C<message> - the text after the PRI, with control characters
written as C<\xNN>.

=item * C<valid> - 1 if the datagram had a valid PRI.  0 if not; then facility
is 1, severity is 5, and C<message> is the whole datagram.

=back

Side Effects: none.

Usage:

	my $record = App::Syslogd->parse_message($datagram);

=head3 EXAMPLE

	my $r = App::Syslogd->parse_message("<34>su: 'su root' failed\n");
	# { facility => 4, severity => 2, message => "su: 'su root' failed", valid => 1 }

	$r = App::Syslogd->parse_message("no pri\there");
	# { facility => 1, severity => 5, message => 'no pri\x09here', valid => 0 }

	$r = App::Syslogd->parse_message("x\n");
	# undef: too short

=head3 API SPECIFICATION

=head4 INPUT

	{
		datagram => { type => 'string', optional => 1, position => 0 },
	}

Domains of the datagram (C<message> is the part after the PRI):

	+-----------------+-----------------------------------+----------------------------------+
	| Partition       | Examples                          | Result                           |
	+-----------------+-----------------------------------+----------------------------------+
	| too short       | undef, "", "x", "x\n" (fewer than | undef                            |
	|                 | 2 characters after removing       |                                  |
	|                 | trailing CR, LF and NUL)          |                                  |
	| valid PRI       | "<0>" to "<191>", no extra        | facility = PRI div 8 (0-23),     |
	|                 | leading zeros                     | severity = PRI mod 8 (0-7),      |
	|                 |                                   | valid 1                          |
	| invalid PRI     | "<192>", "<013>", "<1000>", "<>", | facility 1, severity 5, the      |
	|                 | no PRI at all                     | whole text, valid 0              |
	| control bytes   | 0x00-0x1F and 0x7F                | written as \xNN                  |
	| other bytes     | UTF-8 (umlauts, emoji, combining  | unchanged, same length           |
	|                 | "Zalgo" marks, the RTL override   |                                  |
	|                 | U+202E), invalid UTF-8, C1 bytes  |                                  |
	| references      | [], {}, code, globs               | dies: A datagram must be a       |
	|                 |                                   | string ...                       |
	+-----------------+-----------------------------------+----------------------------------+

Boundaries: length 1 gives undef and 2 gives a record; PRI 191 is valid and
192 is not; PRI 7/8, 15/16, ... are the edges between facilities.  The
largest UDP datagram (65535 bytes) is accepted whole.

=head4 OUTPUT

	{
		type => 'hashref',
		optional => 1,
		schema => {
			facility => { type => 'integer', min => 0, max => 23 },
			severity => { type => 'integer', min => 0, max => 7 },
			message => { type => 'string', matches => qr/\A[^\x00-\x1F\x7F]*\z/ },
			valid => { type => 'boolean' },
		},
	}

=head3 MESSAGES

	+------------------------------------+------------------------------+-----------------------------+
	| Message (dies)                     | Meaning                      | What to do                  |
	+------------------------------------+------------------------------+-----------------------------+
	| A datagram must be a string (the   | A reference was passed; it   | Pass the received bytes     |
	|   type given was TYPE)             |   would have been recorded   |                             |
	|                                    |   as "ARRAY(0x...)"          |                             |
	+------------------------------------+------------------------------+-----------------------------+

A malformed string is recorded, never rejected.  An object that turns
itself into a string (overloads C<"">) is accepted as that string.

=head3 PSEUDOCODE

	treat undef as an empty string
	remove CR, LF and NUL characters from the end
	if fewer than 2 characters remain: return undef
	if the text is "<" NUMBER ">" REST, where NUMBER is 0 to 191
	   written without extra leading zeros:
		valid = 1
	else:
		NUMBER = 13, REST = the whole text, valid = 0
	return {
		facility => NUMBER divided by 8, rounded down,
		severity => remainder of NUMBER divided by 8,
		message  => REST with control characters written as \xNN,
		valid    => valid,
	}

=cut

sub parse_message
{
	my ($self, $datagram) = @_;

	# A reference would be logged as "ARRAY(0x...)"; only a string (or an
	# object that turns itself into one) is a datagram
	if(ref($datagram) && !overload::Method($datagram, q{""})) {
		croak(($self // __PACKAGE__)->i18n('not_a_datagram', { type => ref($datagram) }));
	}

	# Senders disagree about terminators: "\n", "\r\n" and "\0" are all seen
	(my $text = $datagram // '') =~ s/[\r\n\0]+\z//;

	return undef if(length($text) < $MIN_MESSAGE_LENGTH);	## no critic (ProhibitExplicitReturnUndef): documented, also in list context

	# The PRI and the body, as RFC 5424 6.2.1 writes them.  Linear on
	# any input: anchored at the start, the digits capped at three, and
	# the body taken in one greedy step to the end.
	my @match = $text =~ m{
		\A
		<				# a PRI starts with "<"
		(				# capture 1: the PRI number
			0			#   "0" on its own (no other leading zero)
			| [1-9] [0-9]{0,2}	#   or 1 to 3 digits; <= 191 is checked below
		)
		>				# and ends with ">"
		(.*)				# capture 2: the body, newlines included (/s)
		\z
	}xs;
	my $valid = (@match && ($match[0] <= $MAX_PRI)) ? 1 : 0;

	# RFC 3164 4.3.3: keep the whole datagram rather than discarding it.
	# Each value is assigned once, from the right source.
	my ($pri, $body) = $valid ? @match : ($DEFAULT_PRI, $text);

	return {
		facility => int($pri / $SEVERITIES_PER_FACILITY),
		severity => $pri % $SEVERITIES_PER_FACILITY,
		message => _escape_controls($body),
		valid => $valid,
	};
}

=head2 process

Purpose: write one received datagram to the log.

Args:

=over 4

=item 1. The datagram, as a string of bytes.

=item 2. The sender's address, in the packed form that C<recv()> returns.
C<undef>, or anything that is not a packed address (such as a reference),
gives an empty Host column.

=back

Returns: the object, so you can chain another call.

Side Effects:

=over 4

=item * May look up the sender's host name (the answer is remembered).  If
the cache fails (dies) or gives no answer, the IP address is written: a cache
problem never stops the logging.

=item * Adds one line to the log and adds 1 to C<count()>, unless the
datagram is too short, in which case nothing happens.

=item * If the line cannot be written (for example, the disk is full), it
warns and continues.  That message is lost, but the server keeps working.
If only part of the line fitted, the part is removed again, so the file
never holds a half line and the next message starts on a line of its own.

=back

Usage:

	my $peer = $socket->recv(my $datagram, 65535);
	$server->process($datagram, $peer);

=head3 EXAMPLE

	use Socket qw(pack_sockaddr_in inet_aton);

	my $peer = pack_sockaddr_in(514, inet_aton('192.0.2.1'));
	$server->reopen_log()->process('<13>hello', $peer);
	# The file now ends with: "192.0.2.1","1","5","hello"

=head3 API SPECIFICATION

=head4 INPUT

	{
		datagram => { type => 'string', optional => 1, position => 0 },
		peer => { type => 'string', optional => 1, position => 1 },
	}

Domains of the sender: a packed IPv4 or IPv6 address gives that address
(or its name); undef, "", short or garbage strings and references give an
empty Host.  The datagram has the domains listed under L</parse_message>.

=head4 OUTPUT

	{ type => 'object', isa => 'App::Syslogd' }

=head3 MESSAGES

	+-----------------------------------+------------------------------+-------------------------------+
	| Message                           | Meaning                      | What to do                    |
	+-----------------------------------+------------------------------+-------------------------------+
	| process() was called before       | No log file is open (dies)   | Call reopen_log() first       |
	|   reopen_log() succeeded          |                              |                               |
	| A datagram must be a string (the  | The datagram was a reference | Pass the received bytes       |
	|   type given was TYPE)            |   (dies)                     |                               |
	| Could not write to log file F:    | The line was not written,    | Free disk space; this message |
	|   ERROR                           |   e.g. disk full, or the CSV |   is lost, later ones are not |
	|                                   |   writer refused (warning)   |                               |
	+-----------------------------------+------------------------------+-------------------------------+

=cut

sub process
{
	my ($self, $datagram, $peer) = @_;

	# Keep the caller's $! and $@ (see new())
	local ($!, $@);

	croak($self->i18n('no_log_open')) unless($self->{fh});

	# Too-short datagrams are dropped quietly, as the original script did
	if(my $record = $self->parse_message($datagram)) {
		# Escaped like the message: a reverse-DNS (PTR) name is chosen by
		# whoever controls the sender's address and may hold newlines or
		# terminal escape sequences.  Done here rather than in
		# _peer_name(), so that a subclass's override is covered too.
		my $host = _escape_controls($self->_peer_name($peer));
		$self->_write_row([$host, @{$record}{qw(facility severity message)}]);
		$self->{count}++;
	}

	return $self;
}

=head2 run

Purpose: the main loop.  Wait for datagrams and write each one to the log,
until told to stop.

Args: none.

Returns: the object, after SIGTERM, SIGINT or C<stop()>.

Side Effects:

=over 4

=item * Calls C<open_socket()> and C<reopen_log()> first if they have not been
called.  The socket comes first, so if it cannot be opened, C<run()> dies
before the log file is touched.  Starting is all or nothing: if the log
cannot be opened, a socket that C<run()> opened itself is closed again
before C<run()> dies (a socket you opened, or gave to C<new()>, is left
open).

Why the loop never checks for a socket: C<open_socket()> either gives a
socket or dies (premise 1); the loop only starts after it (premise 2); so
inside the loop the socket always exists (conclusion).

=item * While it runs: SIGHUP reopens the log, and SIGTERM or SIGINT stop the
loop.  Your own handlers for these three signals are put back when it
returns.

=item * When it returns, the socket and the log file are closed.

=back

Usage:

	$server->run();

=head3 EXAMPLE

	my $server = App::Syslogd->new(port => 5514, file => '/var/log/remote.csv');
	$server->run();		# Ctrl-C to stop
	print $server->i18n('shutdown', { count => $server->count() }), "\n";
	# Syslog server shutting down after recording 42 messages

=head3 API SPECIFICATION

=head4 INPUT

	{}

=head4 OUTPUT

	{ type => 'object', isa => 'App::Syslogd' }

=head3 MESSAGES

	+---------------------------------+--------------------------------+------------------------------+
	| Message                         | Meaning                        | What to do                   |
	+---------------------------------+--------------------------------+------------------------------+
	| Error receiving a datagram:     | Reading from the network       | Usually nothing: the loop    |
	|   ERROR                         |   failed (warning).  Not given |   continues.  If it repeats, |
	|                                 |   when a signal interrupts the |   check the network          |
	|                                 |   wait                         |                              |
	| Any message of open_socket() or | Starting, or reopening the     | See those methods            |
	|   reopen_log()                  |   log after SIGHUP, failed     |                              |
	|                                 |   (dies)                       |                              |
	+---------------------------------+--------------------------------+------------------------------+

=head3 PSEUDOCODE

	open_socket()		(does nothing if a socket is already open)
	if no log is open: reopen_log()
	for the duration of run():
		SIGHUP          -> set "reopen requested"
		SIGTERM, SIGINT -> clear "running"
	set "running"
	while "running":
		if "reopen requested": clear it, then reopen_log()
		wait for a datagram
		if a datagram arrived: process() it
		(a signal ends the wait early, so the flags are seen at once;
		 any other read error is a warning, and the loop continues)
	close the socket and the log
	put back the caller's signal handlers
	return the object

=cut

sub run
{
	my $self = shift;

	# Keep the caller's $! and $@ (see new())
	local ($!, $@);

	# One loop per object.  A second run() from inside the first (from a
	# subclass or a signal handler, say) used to shut the socket and the log
	# when it returned, and the first loop then died on the missing socket.
	croak($self->i18n('already_running')) if($self->{running});

	# Premise: open_socket() does nothing when a socket is already open.
	# Conclusion: it can be called unconditionally.  reopen_log() is not
	# like that (it always reopens), so its guard stays.
	#
	# Starting is all or nothing: if the log cannot be opened, a socket
	# that run() itself opened is closed again, so a failed start does not
	# leave the port taken.  A socket the caller opened stays theirs.
	my $socket_was_open = $self->{socket} ? 1 : 0;
	$self->open_socket();
	if(!$self->{fh}) {
		eval { $self->reopen_log(); 1 } or do {
			my $error = $@;
			if(!$socket_was_open && (my $socket = delete $self->{socket})) {
				eval { $socket->close() };	# the open error matters more
			}
			die $error;
		};
	}

	# Handlers only set flags: Perl's deferred signals make that safe, and
	# the real work then happens at a known point in the loop below
	local $SIG{HUP} = sub { $self->{reopen_requested} = 1 };
	local $SIG{TERM} = local $SIG{INT} = sub { $self->{running} = 0 };

	# local, so the flag is cleared however run() ends: normally, or by
	# dying when a reopen after SIGHUP fails
	local $self->{running} = 1;

	# Also local: a SIGHUP that arrives with the stop signal must not be
	# left set, or the next run() would reopen the log for no reason
	local $self->{reopen_requested} = 0;
	while($self->{running}) {
		# Perl does not use SA_RESTART, so a signal interrupts recv()
		# and we get here promptly to act on it
		if($self->{reopen_requested}) {
			$self->{reopen_requested} = 0;
			$self->reopen_log();
		}

		my $peer = $self->_receive(\my $datagram);
		$self->process($datagram, $peer) if($peer);
	}

	$self->_shutdown();

	return $self;
}

=head2 stop

Purpose: ask C<run()> to finish.  C<run()> returns after the datagram it is
handling, or at once if it is waiting.

Args: none.

Returns: the object.

Side Effects: clears the "running" flag.  Calling it before C<run()> has no
effect, because C<run()> sets the flag when it starts.

Usage:

	$server->stop();

=head3 EXAMPLE

	# Run for one minute
	local $SIG{ALRM} = sub { $server->stop() };
	alarm(60);
	$server->run();

=head3 API SPECIFICATION

=head4 INPUT

	{}

=head4 OUTPUT

	{ type => 'object', isa => 'App::Syslogd' }

=head3 MESSAGES

None.

=cut

sub stop
{
	my $self = shift;

	$self->{running} = 0;

	return $self;
}

=head2 i18n

Purpose: make a message for people to read, in the server's language.  All
of this module's own messages are made with it, so they can be translated.

Args:

=over 4

=item 1. The message key, for example C<listening>.  The keys are in the
table below.

=item 2. Optional: a hash reference of values to put into the message, for
example C<< { port => 514 } >>.  A missing value becomes an empty string.

=back

It also works on the class (C<< App::Syslogd->i18n(...) >>); the language then
comes from the environment.

Returns: the message as a string.  An unknown key does not die: you get the
key and its values back, such as C<no_such_key (a=1)>.

Side Effects: none.

Usage:

	print $server->i18n('listening', { address => '0.0.0.0', port => 514 }), "\n";

=head3 EXAMPLE

	print App::Syslogd->i18n('shutdown', { count => 1 }), "\n";
	# Syslog server shutting down after recording 1 message
	print App::Syslogd->i18n('shutdown', { count => 3 }), "\n";
	# Syslog server shutting down after recording 3 messages

=head3 API SPECIFICATION

=head4 INPUT

	{
		key => { type => 'string', min => 1, position => 0 },
		args => { type => 'hashref', optional => 1, position => 1 },
	}

Domains: C<key> is one of the keys in the table below (an unknown key gives
the key back; undef, "" or a reference dies).  C<args> is a hash reference
or undef; anything else dies, including C<""> and C<0>.  Values may be any text, including
non-ASCII characters, which appear unchanged.  For C<count>, 1 gives the
singular and every other number (0, 2, -1, 1.5) the plural; text that is
not a number counts as 0.

=head4 OUTPUT

	{ type => 'string' }

=head3 MESSAGES

The keys, the values each one uses, and the English text:

	+---------------+------------------------+--------------------------------------------------+
	| Key           | Values                 | English text                                     |
	+---------------+------------------------+--------------------------------------------------+
	| usage         | program                | Usage: PROGRAM [--port <port_number>] ...        |
	| listening     | address, port          | Syslog server listening on ADDRESS UDP port PORT |
	| shutdown      | count                  | Syslog server shutting down after recording      |
	|               |                        |   COUNT message(s)                               |
	| socket_failed | address, port, error   | Could not create a UDP socket on ADDRESS port    |
	|               |                        |   PORT: ERROR                                    |
	| open_failed   | file, error            | Could not open log file FILE: ERROR              |
	| unsafe_file   | file                   | Refusing to log to FILE: it must be a regular    |
	|               |                        |   file, owned by this user, with exactly one     |
	|               |                        |   link                                           |
	| write_failed  | file, error            | Could not write to log file FILE: ERROR          |
	| recv_failed   | error                  | Error receiving a datagram: ERROR                |
	| no_log_open   | (none)                 | process() was called before reopen_log()         |
	|               |                        |   succeeded                                      |
	| not_a_datagram| type                   | A datagram must be a string (the type given was  |
	|               |                        |   TYPE)                                          |
	| missing_key   | (none)                 | A message key is needed                          |
	| bad_values    | type                   | Message values must be a hash reference (the     |
	|               |                        |   type given was TYPE)                           |
	| no_progress   | (none)                 | the system accepted no data (the ERROR part of   |
	|               |                        |   write_failed when a write makes no progress)   |
	| not_cgi       | (none)                 | This program is a server, not a CGI program: it  |
	|               |                        |   will not run from a web server                 |
	| not_a_log     | file                   | Refusing to log to FILE: it is not empty and     |
	|               |                        |   does not start with the syslog header line     |
	| already_running | (none)               | run() is already running                         |
	+---------------+------------------------+--------------------------------------------------+

=cut

sub i18n
{
	my ($self, $key, $args) = @_;

	# Class-method calls have no object and so no stored handle
	my $lh = ref($self) ? $self->{lh} : App::Syslogd::I18N->handle();

	return $lh->text($key, $args);
}

# ---------------------------------------------------------------------------
# Private and protected helpers
# ---------------------------------------------------------------------------

# _receive
# Purpose:	wait for one datagram.
# Entry:	$self->{socket} set; $buffer_ref a scalar ref to fill.
#		Premise 1: _receive is only called from run()'s loop.
#		Premise 2: run() calls open_socket() before the loop, and
#		open_socket() dies if it cannot give a socket.  Conclusion:
#		the socket always exists here, so it is not checked again.
# Exit:		the sender's sockaddr, or undef if interrupted or on error.
# Side Effects:	carps on errors other than EINTR.
sub _receive
{
	my ($self, $buffer_ref) = @_;

	my $peer = $self->{socket}->recv(${$buffer_ref}, $RECV_BUFFER);

	# EINTR is how a signal wakes us; it is expected, not an error
	if(!defined($peer) && !$!{EINTR}) {
		carp($self->i18n('recv_failed', { error => "$!" }));
	}

	return $peer;
}

# _open_log
# Purpose:	open $self->{file} for appending, safely.
# Entry:	$self->{file} set.
# Exit:		an open filehandle (written with syswrite, unbuffered);
#		croaks on failure.
# Side Effects:	may create the file (mode 0600) and write the header row;
#		chmods an existing file to 0600.
sub _open_log
{
	my $self = shift;
	my $file = $self->{file};

	# The eval below must not touch the caller's $@
	local $@;

	# O_NOFOLLOW: if the log is in a shared directory (/tmp), anyone could plant a
	# symlink to /etc/shadow before root starts us.  O_APPEND: rows from
	# one write() are never interleaved with another writer's, and always
	# go to the end.  O_RDWR (not O_WRONLY) so the first line can be read
	# to check the file is one of our logs.
	my $fh;
	{
		no autodie qw(sysopen);
		sysopen($fh, $file, O_RDWR | O_APPEND | O_CREAT | $O_NOFOLLOW | $O_NONBLOCK, $LOG_MODE)
			or croak($self->i18n('open_failed', { file => $file, error => "$!" }));
	}

	# O_NOFOLLOW cannot catch a hard link or a file someone else pre-created
	# for us to fill with their reading material, so check after opening
	# Safe means all three: a regular file, owned by us, one link.  By De
	# Morgan, "not all three" is "any one of them fails".
	my @st = stat($fh);
	unless(-f _ && ($st[4] == $>) && ($st[3] == 1)) {
		_discard($fh);
		croak($self->i18n('unsafe_file', { file => $file }));
	}

	# A file that already has content must be one of our logs: it must
	# start with the header line.  Without this a mistaken setting (as
	# root, every root-owned file is "ours") would append to, and chmod,
	# any file at all, /etc/passwd included.  Checked before the chmod, so
	# a file that is not ours to change is never changed.
	unless(-z _ || $self->_starts_with_header($fh)) {
		_discard($fh);
		croak($self->i18n('not_a_log', { file => $file }));
	}

	# Tighten an existing file too: previous versions created it 0644
	chmod($LOG_MODE, $fh) if($HAVE_FCHMOD);
	binmode($fh);

	# Header only on an empty file, so a reopened file is not given a
	# second header row half way down.  If that fails the handle is
	# closed here, not left for the garbage collector.
	if(-z $fh) {
		eval { $self->_write_header($fh); 1 } or do {
			my $error = $@;
			_discard($fh);
			die $error;
		};
	}

	return $fh;
}

# _starts_with_header
# Purpose:	is this file one of our logs?
# Entry:	$fh open for reading on a non-empty file.
# Exit:		1 if the first line is the header row (ending in "\n", or
#		"\r\n" for a file once written on Windows), else 0.
# Side Effects:	moves the read position; writes are unaffected, because
#		O_APPEND always writes at the end.
sub _starts_with_header
{
	my ($self, $fh) = @_;

	no autodie qw(sysseek sysread);

	# The header exactly as _write_header writes it, without its newline
	my ($line) = $self->_csv_line([@CSV_HEADER]);
	(my $header = $line // '') =~ s/\n\z//;

	# Read the header and up to two line-end bytes; a failed seek or read
	# leaves $start empty, which does not match
	my $start = '';
	sysread($fh, $start, length($header) + 2) if(defined(sysseek($fh, 0, SEEK_SET)));

	return (length($header) && $start =~ /\A\Q$header\E\r?\n/) ? 1 : 0;
}

# _discard
# Purpose:	close a handle that is being abandoned because of an error.
# Entry:	$fh an open handle.
# Exit:		nothing useful.
# Side Effects:	closes $fh, ignoring a failure: the caller is already
#		reporting a more useful error, and under autodie a failed
#		close() would replace it.
sub _discard
{
	my $fh = shift;

	no autodie qw(close);
	close($fh);

	return;
}

# _write_header
# Purpose:	put the column headings at the top of a new log.
# Entry:	$fh open on an empty file.
# Exit:		$self.
# Side Effects:	writes one line; croaks if it cannot, since a log that
#		cannot take its first line will not take any others.
sub _write_header
{
	my ($self, $fh) = @_;

	my ($line, $error) = $self->_csv_line([@CSV_HEADER]);
	$error //= $self->_append_line($fh, $line);
	croak($self->i18n('write_failed', { file => $self->{file}, error => $error })) if(defined($error));

	return $self;
}

# _append_line
# Purpose:	add one complete line to the end of the log, or nothing.
# Entry:	$fh open for appending; $line ends with a newline.
# Exit:		undef on success, or the system's error text.
# Side Effects:	writes to the file.  If only part of the line could be
#		written (e.g. the disk filled up mid-line), the part is cut off
#		again, so the next line does not join a half-written one.
# syswrite rather than print: print leaves a failed line in Perl's
# buffer, where it makes the next close() fail (fatal under autodie) and
# makes Perl add an "unable to close filehandle properly" warning.
sub _append_line
{
	my ($self, $fh, $line) = @_;

	no autodie qw(sysseek syswrite truncate);

	# syswrite may write less than asked; keep going until done or error
	my $done = 0;
	while($done < length($line)) {
		my $written = syswrite($fh, $line, length($line) - $done, $done);
		last unless($written);
		$done += $written;
	}
	return undef if($done == length($line));	## no critic (ProhibitExplicitReturnUndef): undef means success

	# Remember the error before truncate can change $!.  A write that
	# returned 0 made no progress but set no error, so $! would be stale.
	my $error = $! ? "$!" : $self->i18n('no_progress');

	# Remove a partial line.  The line started $done bytes before the
	# current end (O_APPEND wrote it there).  Finding that out only now,
	# not before every write, saves a seek on every successful line.
	if($done) {
		my $end = sysseek($fh, 0, SEEK_END);
		truncate($fh, $end - $done) if(defined($end));
	}

	return $error;
}

# _close_log
# Purpose:	close the log if it is open.
# Entry:	none.
# Exit:		$self; $self->{fh} is undef.
# Side Effects:	closes a filehandle.
sub _close_log
{
	my $self = shift;

	if(my $fh = delete $self->{fh}) {
		close($fh);
	}

	return $self;
}

# _shutdown
# Purpose:	release the socket and the log when run() finishes.
# Entry:	none.
# Exit:		$self.
# Side Effects:	closes the socket and log; open_socket() and reopen_log() are
#		needed before another run().
sub _shutdown
{
	my $self = shift;

	# Close the log even if closing the socket dies, then pass that
	# error on: otherwise a broken socket would leave the log open too.
	# The eval must not touch the caller's $@.
	local $@;
	my $socket = delete $self->{socket};
	my $ok = eval { $socket->close() if($socket); 1 };
	my $error = $@;
	$self->_close_log();
	die $error unless($ok);

	return $self;
}

# _write_row
# Purpose:	append one CSV row to the log.
# Entry:	$self->{fh} open; $row an arrayref of fields.
# Exit:		$self.
# Side Effects:	writes to the log; carps (does not croak) if that fails, so
#		that a transiently full disk does not stop the daemon.
sub _write_row
{
	my ($self, $row) = @_;

	my ($line, $error) = $self->_csv_line($row);
	$error //= $self->_append_line($self->{fh}, $line);
	carp($self->i18n('write_failed', { file => $self->{file}, error => $error })) if(defined($error));

	return $self;
}

# _csv_line
# Purpose:	turn fields into one CSV line (shared by the header and rows).
# Entry:	$fields an arrayref.
# Exit:		($line) on success, or (undef, $error) if Text::CSV refuses,
#		so that a refused row is reported, not silently written as
#		nothing (or as the previous row, which string() would repeat).
# Side Effects:	none.
# combine() then our own write, rather than Text::CSV's print(): the XS
# print emits a spurious "uninitialized" warning when write() fails.
sub _csv_line
{
	my ($self, $fields) = @_;
	my $csv = $self->{csv};

	# Premise: Text::CSV defines string() whenever combine() succeeds.
	# Conclusion: combine()'s result alone decides; string() needs no
	# separate check.
	return (undef, '' . ($csv->error_diag() || 'Text::CSV could not build the line'))
		unless($csv->combine(@{$fields}));

	return ($csv->string());
}

# _peer_name
# Purpose:	turn the sender's sockaddr into the string to log.
# Entry:	$peer a packed sockaddr (IPv4 or IPv6).
# Exit:		the host name if resolution is on and succeeds, else the
#		numeric address.
# Side Effects:	may do a (cached) reverse DNS lookup.
# Protected rather than private so that a subclass can, say, log
# "name (address)" or use an asynchronous resolver.
sub _peer_name
{
	my ($self, $peer) = @_;

	# Only a packed address can be decoded: getnameinfo dies on undef or a
	# reference ("addr is not a string"), so those are treated like an
	# undecodable address and logged as an empty host
	return '' if(!defined($peer) || ref($peer));

	# getnameinfo copes with both families, unlike inet_ntoa
	my (undef, $address) = getnameinfo($peer, NI_NUMERICHOST, NIx_NOSERV);
	$address //= '';

	return $address unless($self->{resolve} && length($address));

	# getnameinfo consults /etc/hosts before DNS (via nsswitch.conf), so
	# there is no need to read /etc/hosts ourselves.  A cache that fails
	# (a remote cache timing out, say) or answers nothing must not stop
	# the logging: fall back to the address.
	local $@;
	my $name = eval {
		$self->{cache}->compute($address, $self->{dns_ttl}, sub {
			my ($error, $found) = getnameinfo($peer, NI_NAMEREQD, NIx_NOSERV);
			return $error ? $address : $found;
		});
	};

	return (defined($name) && length($name)) ? $name : $address;
}

# _escape_controls
# Purpose:	make a message safe to store as one CSV line.
# Entry:	a string.
# Exit:		the string with every C0 control and DEL written as \xNN.
# Side Effects:	none.
# A plain function, not a method, because it uses no state.
sub _escape_controls
{
	my $text = shift;

	$text =~ s/([\x00-\x1F\x7F])/sprintf('\\x%02X', ord($1))/ge;

	return $text;
}

# Protect the helpers now that they are all defined.  This uses the
# declarative form, not :Private/:Protected attributes, because attributes
# are only applied in a CHECK block, which never runs when this module is
# loaded with require at run time: the helpers were then left callable by
# anyone.
#
# Loaded normally (use), import() queues the subs for CHECK.  Loaded at run
# time, import() should wrap them at once, but Sub::Private 0.05 and
# Sub::Protected 0.02 only learn that CHECK has passed from their own CHECK
# block; if they too were first loaded at run time, the queue is never
# processed.  So, at run time, anything import() did not wrap is wrapped
# here with the same routine their CHECK block uses.  Comparing code refs
# first means nothing is ever wrapped twice (a double wrapper would lock
# this package out of its own helpers).
{
	Readonly my %PROTECTION => (
		'Sub::Private' => [qw(
			_receive _open_log _write_header _append_line _close_log
			_shutdown _write_row _csv_line _escape_controls _discard
			_starts_with_header
		)],
		# Protected, not private: a subclass may override it (see SYNOPSIS)
		'Sub::Protected' => [qw(_peer_name)],
	);
	no strict 'refs';	## no critic (ProhibitNoStrict): reads and replaces subs by name
	foreach my $module (sort keys %PROTECTION) {
		my @names = @{$PROTECTION{$module}};
		my %before = map { $_ => \&{__PACKAGE__ . "::$_"} } @names;
		$module->import(@names);
		next if(${^GLOBAL_PHASE} ne 'RUN');
		my $wrap = $module->can('_process_one') or next;
		# Their own helpers are protected too; the documented BYPASS
		# switches lift that for this call only
		local $Sub::Private::BYPASS = 1;
		local $Sub::Protected::BYPASS = 1;
		foreach my $name (grep { \&{__PACKAGE__ . "::$_"} == $before{$_} } @names) {
			$wrap->(__PACKAGE__, $name);
		}
	}
}

=head1 SECURITY

This module is not a CGI program: it reads no HTTP request, no
C<QUERY_STRING>, C<PATH_INFO>, cookies or other C<HTTP_*> variables, and
never reads standard input.  It writes CSV, not HTML.  Its untrusted
inputs, and what protects against each, are:

	+----------------------+--------------------------+----------------------------------------+
	| Input                | Controlled by            | Protection                             |
	+----------------------+--------------------------+----------------------------------------+
	| UDP datagrams        | anyone who can reach the | stored as data only; control           |
	|                      | port                     | characters written as \xNN (no forged  |
	|                      |                          | lines, no terminal escapes); never     |
	|                      |                          | reflected into warnings or errors      |
	| reverse-DNS names    | whoever owns the         | escaped like messages                  |
	|                      | sender's address         |                                        |
	| App__Syslogd__*      | whoever starts the       | validated like arguments; tainted      |
	| variables, config    | server                   | values are refused under perl -T       |
	| files                |                          | (never untainted)                      |
	| LANG, LANGUAGE, LC_* | whoever starts the       | a tag can only select a lexicon        |
	|                      | server                   | package; unknown tags give English     |
	+----------------------+--------------------------+----------------------------------------+

It never runs another program (no C<system>, C<exec>, backticks or piped
C<open>), so shell metacharacters in any input are only ever text.  File
names are passed to the system directly, never to a shell.  An existing
file is only reused if it is empty or already one of the server's logs, so
even as root a mistaken or hostile C<file> setting cannot make the server
append to, or change the permissions of, a file such as F</etc/passwd>.
Markup such as
C<< <script> >> in a message is stored unchanged: a program that shows the
log in a web page (for example the viewer in F<www/>) must HTML-encode it.

=head1 LIMITATIONS

=over 4

=item * B<The default directory is a file on Debian and Ubuntu.>  The
default log is F</var/log/syslog/syslog.csv>, but on Debian, Ubuntu and
their derivatives F</var/log/syslog> is rsyslog's own log file, so the
server cannot start with the default there ("Not a directory").  Give
C<file> (or C<--file>), for example F</var/log/syslog/syslog.csv> as in
L</SAMPLE CONFIGURATION>.

=item * B<The default directory must already exist.>  The server does not
create directories: create F</var/log/syslog> (see L</INSTALLATION>), or the
server stops with "Could not open log file ...: No such file or directory".
Versions before 0.002.0 logged to F</tmp/syslog.log> by default.

=item * B<The web viewer cannot read the log.>  The file is readable only by
its owner (usually root), but the web pages in F<www/> run as the web
server's user.  You must choose between privacy and the viewer, for example
by using a shared group and changing C<$LOG_MODE> in the source.

=item * B<It does not give up root.>  Port 514 needs root (or the
CAP_NET_BIND_SERVICE capability), and the server keeps root while it runs.
Better: use a port above 1023 with a firewall redirect, or let systemd open
the socket and pass it with C<< new(socket => ...) >>.

=item * B<No time of arrival.>  A line holds only what the sender put in the
message.  Adding a column would break existing files and the web viewer, so
it needs a migration and has not been done.

=item * B<Host name lookups block.>  Answers are remembered, but the first
message from a host with a slow DNS server makes the loop wait, and the
system may drop datagrams that arrive during the wait.  Use C<--no-resolve>
on a busy server.

=item * B<UDP only.>  There is no TCP (RFC 6587) or TLS (RFC 5425).  So
delivery is not guaranteed, and anyone who can reach the port can write to
the log.

=item * B<Only the PRI is decoded.>  Time stamps and host names inside RFC 3164
messages, and RFC 5424 structured data, stay in the C<msg> column.

=item * B<Spreadsheet formulas.>  A message that starts with C<=>, C<+>, C<->
or C<@> may run as a formula if you open the file in a spreadsheet.  The
data is kept unchanged on purpose; take care when you open it.

=item * B<Backslashes are not escaped>, so the text C<\x0A> and an escaped
newline look the same (see L</COMMON PITFALLS>).

=item * B<Windows is less protected.>  The module works on Windows, but:

=over 4

=item * Windows has no C<O_NOFOLLOW>, so the server cannot refuse a symbolic
link as the log file.  (Creating a symbolic link on Windows normally needs
administrator rights, which makes this attack rare.)

=item * Mode 0600 does not make the file private: Windows uses access control
lists, which this module does not change.  An existing file's permissions
are not changed either, because Windows Perl cannot change the permissions
of an open file.  Put the log in a folder that only the right users can
read.

=item * There is no C<kill -HUP> from outside the process, so log rotation by
signal is not available.  Stop and restart the server instead.

=item * A signal such as Ctrl-C may not interrupt the wait for a datagram, so
the server may stop only after the next datagram arrives.

=back

=item * B<Do not send the logger's output to this server.>  L<Object::Configure>
gives each object a logger, and a shared configuration file may point it
at syslog.  This module does not log through it today, but if it ever
does, a logger that sends to the same syslog server would feed its own
input back to itself.

=back

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=encoding utf8

=head1 FORMAL SPECIFICATION

This section describes each method exactly, in the Z notation.  You do not
need it to use the module; the descriptions in L</METHODS> say the same
things in words.

=head2 State

	[ADDRESS, PATH, LANGTAG, SOCKADDR, BYTE, NAME, VALUE]
	PORT == 0 .. 65535
	HEADER == ⟨"Host", "facility", "severity", "msg"⟩
	RECORD == ⟨facility : 0 .. 23, severity : 0 .. 7,
	           message : seq BYTE, valid : 𝔹⟩

	Server
	  port : PORT ; address : ADDRESS ; file : PATH
	  resolve : 𝔹 ; language : LANGTAG
	  count : ℕ
	  bound, logging, running, hup : 𝔹
	  contents : PATH ⇸ seq (seq BYTE)
	  ─────────
	  running ⇒ bound ∧ logging

	ΞServer ≙ [ ΔServer | θServer' = θServer ]

=head2 new

	New
	  Server'
	  args? : NAME ⇸ VALUE
	  configured? : NAME ⇸ VALUE	-- files and environment
	  ─────────
	  let a == ((args? ⊕ configured?) ▷ (VALUE \ {⊥})) ∩ (dom NEW_SCHEMA × VALUE) •
	    dom args? ⊆ dom NEW_SCHEMA ∧
	    conforms(a, NEW_SCHEMA) ∧
	    θServer' = (DEFAULTS ⊕ a) ⊕ {count ↦ 0} ∧
	    bound' = (socket ∈ dom a) ∧ ¬logging' ∧ ¬running' ∧ ¬hup'

	NewFail
	  ΞServer
	  args? : NAME ⇸ VALUE
	  error! : STRING
	  ─────────
	  dom args? ⊈ dom NEW_SCHEMA ∨ ¬ conforms(args?, NEW_SCHEMA) ∨
	  ¬ conforms((args? ⊕ configured?) ∩ (dom NEW_SCHEMA × VALUE), NEW_SCHEMA)

=head2 open_socket

	OpenSocketOk
	  ΔServer
	  ─────────
	  bound' ∧ logging' = logging ∧ count' = count
	  (port = 0 ∧ ¬bound ⇒ port' ∈ 1 .. 65535)
	  (port ≠ 0 ∨ bound ⇒ port' = port)

	OpenSocketFail
	  ΞServer
	  error! : STRING
	  ─────────
	  ¬bound ∧ ¬ canBind(address, port)

	OpenSocket ≙ OpenSocketOk ∨ OpenSocketFail

=head2 port

	Port
	  ΞServer
	  p! : PORT
	  ─────────
	  p! = port

=head2 address

	Address
	  ΞServer
	  a! : ADDRESS
	  ─────────
	  a! = address

=head2 count

	Count
	  ΞServer
	  n! : ℕ
	  ─────────
	  n! = count

=head2 reopen_log

	ReopenLogOk
	  ΔServer
	  ─────────
	  logging' ∧ bound' = bound ∧ count' = count
	  isRegular(file) ∧ ¬ isSymlink(file)
	  owner(file) = euid ∧ links(file) = 1 ∧ mode'(file) = 0600
	  contents(file) = ⟨⟩ ∨ csv(HEADER) ⊑ contents(file)
	  contents(file) = ⟨⟩ ⇒ contents'(file) = ⟨csv(HEADER)⟩
	  contents(file) ≠ ⟨⟩ ⇒ contents'(file) = contents(file)

	ReopenLogFail
	  ΔServer
	  error! : STRING
	  ─────────
	  ¬logging' ∧ bound' = bound ∧ count' = count
	  contents'(file) = contents(file) ∧ mode'(file) = mode(file)

	ReopenLog ≙ ReopenLogOk ∨ ReopenLogFail

=head2 parse_message

	ParseMessage
	  d? : seq BYTE
	  r! : RECORD ∪ {⊥}
	  ─────────
	  let t == stripTrailing({CR, LF, NUL}, d?) •
	  #t < 2 ⇒ r! = ⊥
	  #t ≥ 2 ∧ (∃ p : 0 .. 191 ; b : seq BYTE •
	           t = ⟨'<'⟩ ⁀ canonical(p) ⁀ ⟨'>'⟩ ⁀ b) ⇒
	    r! = ⟨facility ↦ p div 8, severity ↦ p mod 8,
	          message ↦ escape(b), valid ↦ true⟩
	  otherwise ⇒
	    r! = ⟨facility ↦ 1, severity ↦ 5,
	          message ↦ escape(t), valid ↦ false⟩

	escape : seq BYTE → seq BYTE
	∀ c : BYTE • escape(⟨c⟩) =
	  if c ∈ 0 .. 31 ∪ {127} then "\x" ⁀ hex2(c) else ⟨c⟩
	∀ s, u : seq BYTE • escape(s ⁀ u) = escape(s) ⁀ escape(u)

=head2 process

	ProcessOk
	  ΔServer
	  d? : seq BYTE ; peer? : SOCKADDR ∪ {⊥}
	  ─────────
	  logging ∧ bound' = bound ∧ logging'
	  ParseMessage(d?) = ⊥ ⇒ count' = count ∧ contents' = contents
	  ParseMessage(d?) = r ≠ ⊥ ⇒
	    count' = count + 1 ∧
	    (writable(file) ⇒
	      contents'(file) = contents(file) ⁀ ⟨csv(host(peer?), r)⟩) ∧
	    (¬ writable(file) ⇒ contents' = contents)

	host(⊥) = ""
	resolve ⇒ host(p) = reverseName(p) if found, else numeric(p)
	¬resolve ⇒ host(p) = numeric(p)

	ProcessFail
	  ΞServer
	  error! : STRING
	  ─────────
	  ¬logging

	Process ≙ ProcessOk ∨ ProcessFail

=head2 run

	Start ≙ (¬bound ∧ OpenSocket ∨ bound ∧ ΞServer) ⨾
	        (¬logging ∧ ReopenLog ∨ logging ∧ ΞServer)

	Loop ≙ μ L •
	    (¬running ∧ Shutdown)
	  □ (running ∧ hup ∧ [ ΔServer | ¬hup' ] ⨾ ReopenLog ⨾ L)
	  □ (running ∧ ¬hup ∧ Receive ⨾ Process ⨾ L)

	Shutdown
	  ΔServer
	  ─────────
	  ¬bound' ∧ ¬logging' ∧ ¬running' ∧ count' = count

	Run ≙ Start ⨾ [ ΔServer | running' ] ⨾ Loop

	SIGHUP received during Run      ⇒ hup' = true
	SIGTERM or SIGINT during Run    ⇒ running' = false

=head2 stop

	Stop
	  ΔServer
	  ─────────
	  ¬running' ∧ bound' = bound ∧ logging' = logging ∧ count' = count

=head2 i18n

	I18n
	  key? : KEY ; args? : NAME ⇸ VALUE ; out! : STRING
	  ─────────
	  key? ∈ dom ARGUMENT_ORDER ⇒
	    out! = render(lexicon(language, key?),
	                  ⟨args?(n) | n ∈ ARGUMENT_ORDER(key?)⟩)
	  key? ∉ dom ARGUMENT_ORDER ⇒ key? ⊑ out!

=head2 Security invariants

	Commands ≙ { system, exec, readpipe, pipe-open }
	Datagram, Line : seq BYTE

	NoExecution
	  ∀ op : operations(App::Syslogd) • calls(op) ∩ Commands = ∅

	LineIntegrity
	  ∀ d? : Datagram ; peer? : SOCKADDR •
	    #{ l : lines(record(d?, peer?)) } = 1 ∧
	    ran record(d?, peer?) ∩ ({0 .. 31} ∪ {127} \ {LF}) = ∅

	NoReflection
	  ∀ d? : Datagram ; m : warnings ∪ errors •
	    #d? > 2 ⇒ ¬ (stripPRI(d?) ⊑ m)

	NoNul
	  ∀ o : {address, file, language} • 0 ∉ ran args?(o)

=head1 STATE DIAGRAM

An object is always in one of six states.  The boxes are the states; the
arrows are the method calls or events that move it from one state to another.
The text in square brackets is what happens during the move.

	                      new()
	                        |   [check options; nothing opened]
	                        |
	                        |       new(socket => S) starts in BOUND instead
	                        v
	          +---------------------------+
	          |           IDLE            |<--------------------------------+
	          |  no socket, no log file   |                                 |
	          +---------------------------+                                 |
	              |                   |                                     |
	 open_socket()|                   |reopen_log()                         |
	 [bind UDP    |                   |[open or create file (0600),         |
	  socket]     |                   | write header if empty]              |
	              v                   v                                     |
	      +---------------+   +---------------+                             |
	      |     BOUND     |   |    LOGGING    |<-- process()                |
	      | socket open,  |   | log open,     |    [write row, count + 1]   |
	      | no log file   |   | no socket     |                             |
	      +---------------+   +---------------+                             |
	              |                   |                                     |
	  reopen_log()|                   |open_socket()                        |
	              |    +---------+    |                                     |
	              +--->|  READY  |<---+                                     |
	                   | socket  |<-- process()   [write row, count + 1]    |
	                   | and log |<-- reopen_log() [close, reopen file]     |
	                   +---------+                                          |
	                        |                                               |
	                        | run()   [also allowed from IDLE, BOUND or     |
	                        |          LOGGING: opens what is missing;      |
	                        v          installs HUP/TERM/INT handlers]      |
	                   +---------+                                          |
	   datagram ------>|         |   [process(): write row, count + 1]      |
	   SIGHUP -------->| RUNNING |   [reopen_log() at top of loop]          |
	   read error ---->|         |   [warning; keep going]                  |
	                   +---------+                                          |
	                        |                                               |
	                        | SIGTERM, SIGINT or stop()                     |
	                        v         [clear "running" flag]                |
	                   +----------+                                         |
	                   | STOPPING |   the current wait or datagram ends     |
	                   +----------+                                         |
	                        |                                               |
	                        | loop sees the flag                            |
	                        | [close socket and log; restore caller's       |
	                        |  signal handlers; run() returns]              |
	                        +-----------------------------------------------+

=head2 Transition table

	+----------+-------------------------------+----------+------------------------------------+
	| From     | Trigger                       | To       | Action / side effect               |
	+----------+-------------------------------+----------+------------------------------------+
	| (none)   | new()                         | IDLE     | options checked and stored         |
	| (none)   | new(socket => S)              | BOUND    | S used as the socket               |
	| IDLE     | open_socket()                 | BOUND    | UDP socket bound                   |
	| IDLE     | reopen_log()                  | LOGGING  | file opened or created, header     |
	| BOUND    | reopen_log()                  | READY    | file opened or created, header     |
	| LOGGING  | open_socket()                 | READY    | UDP socket bound                   |
	| BOUND    | open_socket()                 | BOUND    | nothing (already bound)            |
	| READY    | open_socket()                 | READY    | nothing (already bound)            |
	| LOGGING  | reopen_log()                  | LOGGING  | file closed and opened again       |
	| READY    | reopen_log()                  | READY    | file closed and opened again       |
	| LOGGING  | process()                     | LOGGING  | one row written, count + 1         |
	| READY    | process()                     | READY    | one row written, count + 1         |
	| IDLE,    | run()                         | RUNNING  | open what is missing, install      |
	| BOUND,   |                               |          |   signal handlers, set "running"   |
	| LOGGING, |                               |          |                                    |
	| READY    |                               |          |                                    |
	| RUNNING  | datagram arrives              | RUNNING  | process(): row written, count + 1  |
	| RUNNING  | SIGHUP                        | RUNNING  | log closed and opened again        |
	| RUNNING  | read error (not a signal)     | RUNNING  | warning "Error receiving ..."      |
	| RUNNING  | a write fails (e.g. disk      | RUNNING  | warning "Could not write ...";     |
	|          |   full)                       |          |   that datagram is lost            |
	| RUNNING  | SIGTERM, SIGINT or stop()     | STOPPING | "running" flag cleared             |
	| STOPPING | the wait or datagram ends     | IDLE     | socket and log closed, handlers    |
	|          |                               |          |   restored, run() returns          |
	+----------+-------------------------------+----------+------------------------------------+

Failures (the method dies and the object changes as shown):

	+----------+-------------------------------+----------+------------------------------------+
	| From     | Trigger                       | To       | Action / side effect               |
	+----------+-------------------------------+----------+------------------------------------+
	| IDLE,    | open_socket() fails           | (same)   | dies "Could not create a UDP       |
	| LOGGING  |                               |          |   socket ..."                      |
	| IDLE,    | reopen_log() fails            | (same)   | dies "Could not open log file ..." |
	| BOUND    |                               |          |   or "Refusing to log ..."         |
	| LOGGING, | reopen_log() fails            | IDLE or  | log closed, then dies "Could not   |
	| READY    |                               | BOUND    |   open log file ..." or            |
	|          |                               |          |   "Refusing to log ..."            |
	| IDLE,    | process()                     | (same)   | dies "process() was called before  |
	| BOUND    |                               |          |   reopen_log() succeeded"          |
	| RUNNING  | SIGHUP, and the reopen fails  | BOUND    | log closed, handlers restored,     |
	|          |                               |          |   run() dies with the error        |
	| IDLE     | run(), and the log cannot be  | IDLE     | the socket run() opened is closed  |
	|          |   opened                      |          |   again; run() dies with the error |
	| BOUND    | run(), and the log cannot be  | BOUND    | the caller's socket is left open;  |
	|          |   opened                      |          |   run() dies with the error        |
	| IDLE,    | run(), and the socket cannot  | (same)   | dies "Could not create a UDP       |
	| LOGGING  |   be opened                   |          |   socket ..."                      |
	| RUNNING  | recv() dies (a broken socket) | READY    | handlers restored; run() dies with |
	|          |                               |          |   the error; socket and log stay   |
	|          |                               |          |   open                             |
	| RUNNING  | run() again (from inside the  | RUNNING  | dies "run() is already running";   |
	|          |   loop)                       |          |   the running loop carries on      |
	| STOPPING | closing the socket dies       | IDLE     | the log is closed anyway; run()    |
	|          |                               |          |   dies with the error              |
	| (none)   | new() with an invalid option  | (none)   | dies "validate_strict: ..."; no    |
	|          |                               |          |   object is made                   |
	+----------+-------------------------------+----------+------------------------------------+

C<port()>, C<address()>, C<count()>, C<parse_message()> and C<i18n()> never
change the state.  C<stop()> outside C<run()> changes nothing that matters,
because C<run()> sets the "running" flag again when it starts.

=head1 LICENSE AND COPYRIGHT

Copyright 2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.

=cut

1;
