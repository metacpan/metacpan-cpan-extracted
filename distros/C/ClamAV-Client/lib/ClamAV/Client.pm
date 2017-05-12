#
# ClamAV::Client class,
# a client class for the ClamAV clamd virus scanner daemon.
#
# (C) 2004-2005 Julian Mehnle <julian@mehnle.net>
# $Id: Client.pm,v 1.6 2005/01/21 22:50:14 julian Exp $
#
##############################################################################

=head1 NAME

ClamAV::Client - A client class for the ClamAV C<clamd> virus scanner daemon

=cut

package ClamAV::Client;

=head1 VERSION

0.11

=cut

our $VERSION = '0.11';

=head1 SYNOPSIS

=head2 Creating a scanner client

    use ClamAV::Client;

    # Try using socket options from clamd.conf, or use default socket:
    my $scanner = ClamAV::Client->new();

    # Use a local Unix domain socket:
    my $scanner = ClamAV::Client->new(
        socket_name     => '/var/run/clamav/clamd.ctl'
    );
    
    # Use a TCP socket:
    my $scanner = ClamAV::Client->new(
        socket_host     => '127.0.0.1',
        socket_port     => 3310
    );
    
    die("ClamAV daemon not alive")
        if not defined($scanner) or not $scanner->ping();

=head2 Daemon maintenance

    my $version = $scanner->version;
                            # Retrieve the ClamAV version string.
    
    $scanner->reload();     # Reload the malware pattern database.
    
    $scanner->quit();       # Terminates the ClamAV daemon.
    $scanner->shutdown();   # Likewise.

=head2 Path scanning (lazy)

    # Scan a single file or a whole directory structure,
    # and stop at the first infected file:
    my ($path, $result) = $scanner->scan_path($path);
    my ($path, $result) = $scanner->scan_path(
        $path, ClamAV::Client::SCAN_MODE_NORMAL );
    my ($path, $result) = $scanner->scan_path(
        $path, ClamAV::Client::SCAN_MODE_RAW );

=head2 Path scanning (complete)

    # Scan a single file or a whole directory structure,
    # and scan all files without stopping at the first infected one:
    my %results = $scanner->scan_path_complete($path);
    while (my ($path, $result) = each %results) { ... }

=head2 Other scanning methods

    # Scan a stream, i.e. read from an I/O handle:
    my $result = $scanner->scan_stream($handle);
    
    # Scan a scalar value:
    my $result = $scanner->scan_scalar(\$value);

=cut

use warnings;
use strict;

use Error qw(:try);

use Carp;
use IO::Socket;

use ClamAV::Config;

use constant TRUE   => (0 == 0);
use constant FALSE  => not TRUE;

use constant SOCKET_TYPE_AUTO       => 0;
use constant SOCKET_TYPE_UNIX       => 1;
use constant SOCKET_TYPE_TCP        => 2;

use constant DEFAULT_SOCKET_NAME    => '/var/run/clamav/clamd.ctl';
use constant DEFAULT_SOCKET_HOST    => '127.0.0.1';
use constant DEFAULT_SOCKET_PORT    => 3310;

use constant SCAN_MODE_NORMAL       => FALSE;
use constant SCAN_MODE_RAW          => TRUE;

use constant STREAM_BLOCK_SIZE      => 4096;

# Interface:
##############################################################################

=head1 DESCRIPTION

B<ClamAV::Client> is a class acting as a client for a ClamAV C<clamd> virus
scanner daemon.  The daemon may run locally or on a remote system as
B<ClamAV::Client> can use both Unix domain sockets and TCP/IP sockets.  The
full functionality of the C<clamd> client/server protocol is supported.

=cut

sub new;

sub ping;
sub version;
sub reload;
sub quit;

sub scan_path;
sub scan_path_complete;
sub scan_stream;
sub scan_scalar;

# Implementation:
##############################################################################

=head2 Constructor

The following constructor is provided:

=over

=item B<new(%options)>: RETURNS ClamAV::Client

Creates a new C<ClamAV::Client> object.  If I<no> socket options are specified,
first the socket options from the local C<clamd.conf> configuration file are
tried, then the Unix domain socket C</var/run/clamav/clamd.ctl> is tried, then
finally the TCP/IP socket at C<127.0.0.1> on port C<3310> is tried.  If either
Unix domain or TCP/IP socket options are explicitly specified, only these are
used.

C<%options> is a list of key/value pairs representing any of the following
options:

=over

=item B<socket_name>

A scalar containing the absolute name of the local Unix domain socket.
Defaults to B<'/var/run/clamav/clamd.ctl'>.

=item B<socket_host>

A scalar containing the name or IP address of the TCP/IP socket.  Defaults to
B<'127.0.0.1'>.

=item B<socket_port>

A scalar containing the port number of the TCP/IP socket.  Defaults to B<3310>.

=back

=cut

sub new {
    my ($class, %options) = @_;
    
    if ($options{socket_name}) {
        # Caller explicitly specified local Unix domain socket.
        $options{socket_type} = SOCKET_TYPE_UNIX;
        $options{socket_host} ||= DEFAULT_SOCKET_HOST;
    }
    elsif ($options{socket_host} or $options{socket_port}) {
        # Caller explicitly specified TCP socket.
        $options{socket_type} = SOCKET_TYPE_TCP;
        $options{socket_host} ||= DEFAULT_SOCKET_HOST;
        $options{socket_port} ||= DEFAULT_SOCKET_PORT;
    }
    else {
        # Caller hasn't specified anything.
        
        # Try reading local clamd config file:
        try {
            ClamAV::Config->clamd_config;
        }
        catch ClamAV::Config::Error with {
            # Ignore access problems to clamd configuration file.
        };
        
        # Try local Unix domain socket first...:
        $options{socket_name} = ClamAV::Config->clamd_option('LocalSocket')
            or
        # ...otherwise try TCP socket:
        $options{socket_host} = ClamAV::Config->clamd_option('TCPAddr'),
        $options{socket_port} = ClamAV::Config->clamd_option('TCPSocket');
        
        if ($options{socket_name}) {
            # Local clamd config file has specified local Unix domain socket.
            $options{socket_type} = SOCKET_TYPE_UNIX;
            $options{socket_host} ||= DEFAULT_SOCKET_HOST;
        }
        elsif ($options{socket_host} or $options{socket_port}) {
            # Local clamd config file has speficied TCP socket.
            $options{socket_type} = SOCKET_TYPE_TCP;
            $options{socket_host} ||= DEFAULT_SOCKET_HOST;
            $options{socket_port} ||= DEFAULT_SOCKET_PORT;
        }
        else {
            # Neither caller nor clamd config file have specified anything, set
            # socket auto detection mode.
            $options{socket_type} = SOCKET_TYPE_AUTO;
            $options{socket_host} = DEFAULT_SOCKET_HOST;
            $options{socket_name} = DEFAULT_SOCKET_NAME;
            $options{socket_port} = DEFAULT_SOCKET_PORT;
        }
    }
    
    my $self = {
        socket_type     => $options{socket_type},
        socket_name     => $options{socket_name},
        socket_host     => $options{socket_host},
        socket_port     => $options{socket_port}
    };
    bless($self, $class);
    return $self;
}

=back

=head2 Instance methods

The following instance methods are provided:

=head3 Daemon maintenance

=over

=item B<ping>: RETURNS SCALAR; THROWS ClamAV::Client::Error

Returns B<true> ('PONG') if the ClamAV daemon is alive.  Throws a
ClamAV::Client::Error exception otherwise.

=cut

sub ping {
    my ($self) = @_;
    return $self->_simple_command("PING");
}

=item B<version>: RETURNS SCALAR; THROWS ClamAV::Client::Error

Returns the version string of the ClamAV daemon.

=cut

sub version {
    my ($self) = @_;
    return $self->_simple_command("VERSION");
}

=item B<reload>: RETURNS SCALAR; THROWS ClamAV::Client::Error

Instructs the ClamAV daemon to reload its malware database.  Returns B<true> if
the reloading succeeds, or throws a ClamAV::Client::Error exception otherwise.

=cut

sub reload {
    my ($self) = @_;
    return $self->_simple_command("RELOAD");
}

=item B<quit>: RETURNS SCALAR; THROWS ClamAV::Client::Error

=item B<shutdown>: RETURNS SCALAR; THROWS ClamAV::Client::Error

Terminates the ClamAV daemon.  Returns B<true> if the termination succeeds,
or throws a ClamAV::Client::Error exception otherwise.

=cut

sub quit {
    # Caution, this terminates the ClamAV daemon!
    my ($self) = @_;
    return $self->_simple_command("QUIT");
}

*shutdown = *shutdown = \&quit;

=item B<scan_path($path)>: RETURNS SCALAR, SCALAR; THROWS ClamAV::Client::Error

=item B<scan_path($path, $scan_mode)>: RETURNS SCALAR, SCALAR; THROWS
ClamAV::Client::Error

Scans a single file or a whole directory structure, and stops at the first
infected file found.  The specified path must be absolute.  A scan mode may be
specified: a mode of B<ClamAV::Client::SCAN_MODE_NORMAL> (which is the default)
causes a normal scan (C<SCAN>) with archive support enabled, a mode of
B<ClamAV::Client::SCAN_MODE_RAW> causes a raw scan with archive support
disabled.

If an infected file is found, returns a list consisting of the path of the file
and the name of the malware signature that matched the file.  Otherwise,
returns the originally specified path and B<undef>.

=cut

sub scan_path {
    my ($self, $path, $scan_mode_raw) = @_;
    
    my $command = ($scan_mode_raw ? 'RAWSCAN' : 'SCAN');
    my $response = $self->_simple_command("$command $path");
    return $self->_parse_scan_response($response);
}

=item B<scan_path_complete($path)>: RETURNS HASH; THROWS ClamAV::Client::Error

Scans a single file or a whole directory structure I<completely>, not stopping
at the first infected file found.  The specified path must be absolute.  Only
the normal, non-raw mode is supported for complete scans by ClamAV.

Returns a hash with a list of infected files found, with the file paths as
the keys and the matched malware signature names as the values.

=cut

sub scan_path_complete {
    my ($self, $path, $scan_mode_raw) = @_;

    if ($scan_mode_raw) {
        throw ClamAV::Client::Error("Raw mode not supported for path complete (CONTSCAN) scanning");
    }
    
    my $socket = $self->_socket;
    $socket->print("CONTSCAN $path\n");
    
    my %results;
    while (my $response = $socket->getline()) {
        my ($file_name, $result) = $self->_parse_scan_response($response);
        $results{$file_name} = $result;
    }
    
    $socket->close();
    
    %results = ()
        if values(%results) == 1 and not defined((values(%results))[0]);
    
    return %results;
}

=item B<scan_stream($handle)>: RETURNS SCALAR; THROWS ClamAV::Client::Error

Scans a stream, that is, reads from an I/O handle.  If the stream is found to
be infected, returns the name of the matching malware signature, B<undef>
otherwise.

=cut

sub scan_stream {
    my ($self, $handle, $scan_mode_raw) = @_;
    
    if ($scan_mode_raw) {
        throw ClamAV::Client::Error("Raw mode not supported for stream (STREAM) scanning");
    }
    
    my $socket = $self->_socket;
    $socket->print("STREAM\n");
    my $port_spec = $socket->getline();
    if (not $port_spec =~ /^PORT (\d+)$/i) {
        throw ClamAV::Client::Error("Invalid server response to STREAM command: \"$port_spec\"");
    }
    
    my $port = $1;
    
    require IO::Socket::INET;
    my $stream_socket = IO::Socket::INET->new(
        Proto       => 'tcp',
        PeerHost    => $self->{socket_host},
        PeerPort    => $port
    );
    
    # If we didn't manage to gain a connection, throw exception:
    if (not defined($stream_socket)) {
        throw ClamAV::Client::Error(
            "Could not establish TCP socket connection on port $port for STREAM scan"
        );
    }
    
    $stream_socket->autoflush(TRUE);
    my $block;
    $stream_socket->print($block)
        while $handle->read($block, STREAM_BLOCK_SIZE);
    $stream_socket->close();
    
    my $response = $self->{'socket'}->getline();

    $socket->close();
    
    my (undef, $result) = $self->_parse_scan_response($response);
    return $result;
}

=item B<scan_scalar(\$value)>: RETURNS SCALAR; THROWS ClamAV::Client::Error

Scans the value referenced by the given scalarref.  If the value is found to be
infected, returns the name of the matching malware signature, B<undef>
otherwise.

=cut

sub scan_scalar {
    my ($self, $scalar_ref, $scan_mode_raw) = @_;
    
    open(my $handle, '<', $scalar_ref);
    return $self->scan_stream($handle, $scan_mode_raw);
}

=back

=cut

sub _socket {
    my ($self) = @_;
    
    # Try to reuse cached socket connection:
    my $socket = $self->{'socket'};
    
    while (not defined($socket) or not $socket->opened) {
        # (Re-)establish socket connection.
        
        # Try to connect through Unix domain socket:
        if (
            $self->{socket_type} == SOCKET_TYPE_UNIX or
            $self->{socket_type} == SOCKET_TYPE_AUTO
        ) {
            require IO::Socket::UNIX;
            $socket = IO::Socket::UNIX->new(
                Peer    => $self->{socket_name}
            );
            last if defined($socket);
        }
        
        # Try to connect through TCP socket:
        if (
            $self->{socket_type} == SOCKET_TYPE_TCP  or
            $self->{socket_type} == SOCKET_TYPE_AUTO
        ) {
            require IO::Socket::INET;
            $socket = IO::Socket::INET->new(
                Proto       => 'tcp',
                PeerHost    => $self->{socket_host},
                PeerPort    => $self->{socket_port}
            );
            last if defined($socket);
        }
        
        # We haven't managed to gain a connection, throw exception:
        throw ClamAV::Client::Error(
            "Could not establish socket connection, tried UNIX domain and TCP sockets"
        );
    }
    
    $socket->autoflush(TRUE);
    return $self->{'socket'} = $socket;
}

sub _simple_command {
    my ($self, $command) = @_;
    
    my $socket = $self->_socket;
    $socket->print("$command\n");
    chomp(my $response = $socket->getline());
    $socket->close();
    return $response;
}

sub _parse_scan_response {
    my ($self, $response) = @_;
    chomp($response);
    if (not $response =~ /^(.*): (?:OK|(.*) FOUND)$/i) {
        throw ClamAV::Client::Error("Invalid server response to scan command: \"$response\"");
    }
    return ($1, $2);  # (<file-name>, <virus-name> | undef)
}

=head1 SEE ALSO

The L<clamd> and L<clamav> man-pages.

=head1 AVAILABILITY and SUPPORT

The latest version of ClamAV::Client is available on CPAN and at
L<http://www.mehnle.net/software/clamav-client>.

Support is usually (but not guaranteed to be) given by the author, Julian
Mehnle <julian@mehnle.net>.

=head1 AUTHOR and LICENSE

ClamAV::Client is Copyright (C) 2004-2005 Julian Mehnle <julian@mehnle.net>.

ClamAV::Client is free software.  You may use, modify, and distribute it under
the same terms as Perl itself, i.e. under the GNU GPL or the Artistic License.

=cut

package ClamAV::Client::Error;
use base qw(Error::Simple);

package ClamAV::Client;

TRUE;

# vim:tw=79
