package BGPmon::Fetch2::Client2;
our $VERSION = '1.092';

use 5.006;
use strict;
use warnings;
use IO::Socket;
use IO::Select;
use POSIX qw/strftime/;

require Exporter;
our $AUTOLOAD;
our @ISA = qw(Exporter);
#our %EXPORT_TAGS = ( 'all' => [ qw(connect_bgpmon read_xml_message close_connection is_connected messages_read uptime connection_endtime) ] );
#our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT_OK = qw(connect_bgpmon read_xml_message close_connection is_connected messages_read uptime connection_endtime init_bgpdata get_error_code get_error_message get_error_msg set_timeout);

# connection status
our $msgs_read = 0;
our $start_time = time;
our $end_time = time;
our $connected = 0;

# socket and persistent buffer for storing partial messages
our $sock;
our $sel;
our $read_buffer = "";
our $chunksize = 1024;
our $socket_timeout = 600; # Socket times out after 10 min.
our %socket_buffer = ();

# Variables to store error codes and messages.
my %error_code;
my %error_msg;

# Error messages
use constant NO_ERROR_CODE => 0;
use constant NO_ERROR_MSG => 'No error.';
use constant CONNECT_ERROR_CODE => 201;
use constant CONNECT_ERROR_MSG => 'Could not connect to BGPmon.';
use constant NOT_CONNECTED_CODE => 202;
use constant NOT_CONNECTED_MSG => 'Not connected to a BGPmon instance.';
use constant ALREADY_CONNECTED_CODE => 203;
use constant ALREADY_CONNECTED_MSG => 'Already connected to a BGPmon instance.';
use constant XML_MSG_READ_ERROR_CODE => 204;
use constant XML_MSG_READ_ERROR_MSG => 'Error reading XML message from stream.';
use constant CONNECTION_CLOSED_CODE => 205;
use constant CONNECTION_CLOSED_MSG => 'Connection to BGPmon closed.';
use constant INVALID_NUM_BYTES_ERROR_CODE => 206;
use constant INVALID_NUM_BYTES_ERROR_MSG => 'Attempting to read invalid number of bytes.';
use constant READ_ERROR_CODE => 207;
use constant READ_ERROR_MSG => 'Could not read from file handle. Error in sysread.';
use constant SOCKET_TIMEOUT_CODE => 208;
use constant SOCKET_TIMEOUT_MSG => 'Socket timed out.';
use constant ARGUMENT_ERROR_CODE => 297;
use constant ARGUMENT_ERROR_MSG => 'Invalid number of arguments.';
use constant INVALID_FUNCTION_SPECIFIED_CODE => 298;
use constant INVALID_FUNCTION_SPECIFIED_MSG => 'Invalid function name specified.';
use constant UNKNOWN_ERROR_CODE => 299;
use constant UNKNOWN_ERROR_MSG => 'Unknown error occurred.';

# Initially, all functions are error-free.
my @functions = qw(init_bgpdata connect_bgpmon read_xml_message read_n_bytes close_connection is_connected messages_read uptime connection_endtime);
for my $function (@functions) {
    $error_code{$function} = NO_ERROR_CODE;
    $error_msg{$function} = NO_ERROR_MSG;
}

=head1 NAME

BGPmon::Fetch::Client

The BGPmon Client module, to connect to BGPmon and receive XML messages one at a time.

=cut

=head1 SYNOPSIS

The BGPmon::Client module provides functionality to connect to a bgpmon instance and read one XML message at a time.

    use BGPmon::Fetch::Client;
    my $ret = connect_bgpmon();
    set_timeout($time_out_seconds);
    my $xml_msg = read_xml_message();
    my $ret = is_connected();
    my $num_read = messages_read();
    my $uptime = uptime();
    my $ret = close_connection();
    my $downtime = connection_endtime();
=cut

=head1 EXPORT

init_bgpdata
connect_bgpmon
set_timeout
read_xml_message
close_connection
is_connected
messages_read
uptime
connection_endtime

=cut

=head1 SUBROUTINES/METHODS

=head2 init_bgpdata

Initializes the client module. Takes no arguments.

=cut

sub init_bgpdata {
    return 1;
}

=head2 set_timeout

Sets the socket timeout value in seconds. Takes one argument - the timeout value in seconds.

=cut

sub set_timeout {
    $socket_timeout = shift;
}

=head2 connect_bgpmon

This function connects to the BGPmon server. If the connection succeeds, the function
attempts to read the starting <xml> tag from the BGPmon server. If that succeeds, the
created socket is returned. If not, the function returns undef.

=cut

sub connect_bgpmon {
    my ($server, $port) = @_;
    my $fname = 'connect_bgpmon';

    if ($connected == 1) {
        $error_code{$fname} = ALREADY_CONNECTED_CODE;
        $error_msg{$fname} = ALREADY_CONNECTED_MSG;
        return -1;
    }

    # Connect to the BGPmon instance to receive XML xml_stream
    $sock = new IO::Socket::INET(PeerAddr => $server, PeerPort => $port, Proto => 'tcp');
    if(!defined $sock) {
        $error_code{$fname} = CONNECT_ERROR_CODE;
        $error_msg{$fname} = CONNECT_ERROR_MSG;
        return -2;
    }

    # Create select object, to be used later.
    $sel = new IO::Select->new();
    $sel->add($sock);

    my $data;
    my @ready = $sel->can_read($socket_timeout);
    if (scalar(@ready) > 0) { #We have data on socket.
        $data = read_n_bytes(5);
        if (!defined $data) {
            $error_code{$fname} = XML_MSG_READ_ERROR_CODE;
            $error_msg{$fname} = XML_MSG_READ_ERROR_MSG;
            $sel->remove($sock);
            close($sock);
            return -3;
        }
        if ($data ne "<xml>") {
            $error_code{$fname} = XML_MSG_READ_ERROR_CODE;
            $error_msg{$fname} = XML_MSG_READ_ERROR_MSG;
            $sel->remove($sock);
            close($sock);
            return -4;
        }
        $connected = 1;
        $start_time = time;
        $msgs_read = 0;

        $error_code{$fname} = NO_ERROR_CODE;
        $error_msg{$fname} = NO_ERROR_MSG;
        return 0;
    }

    # Socket timed out.
    $error_code{$fname} = SOCKET_TIMEOUT_CODE;
    $error_msg{$fname} = SOCKET_TIMEOUT_MSG;
    $sel->remove($sock);
    close($sock);
    return -5;
}

=head2 read_xml_message

This function reads one xml message at a time from the BGPmon XML stream.

=cut

sub read_xml_message {
    my $complete_xml_msg = "";
    my $fname = 'read_xml_message';

    # Check if we are connected to a server
    unless ($connected == 1) {
        $error_code{$fname} = NOT_CONNECTED_CODE;
        $error_msg{$fname} = NOT_CONNECTED_MSG;
        return undef;
    }

    my $tempbuf;
    my $bytesread = 0;
    my @ready = $sel->can_read($socket_timeout);

    # If there is a socket with data.
    if (scalar(@ready) > 0) {
        while ($read_buffer !~ /<BGP_MONITOR_MESSAGE.*?BGP_MONITOR_MESSAGE>/) {
            $bytesread = sysread($sock, $tempbuf, $chunksize);
            if (!defined $bytesread) {
                $error_code{$fname} = XML_MSG_READ_ERROR_CODE;
                $error_msg{$fname} = XML_MSG_READ_ERROR_MSG;
                close_connection();
                return undef;
            }
            if ($bytesread == 0) {
                $error_code{$fname} = CONNECTION_CLOSED_CODE;
                $error_msg{$fname} = CONNECTION_CLOSED_MSG;
                close_connection();
                return undef;
            }
            $read_buffer .= $tempbuf;
        }

        # at this point I have a complete message OR my socket closed
        if ($read_buffer =~ /^(<BGP_MONITOR_MESSAGE.*?BGP_MONITOR_MESSAGE>)/) {
            $complete_xml_msg = $1;
            $msgs_read++;
            $read_buffer =~ s/^<BGP_MONITOR_MESSAGE.*?BGP_MONITOR_MESSAGE>//;
        } else {
            $error_code{$fname} = UNKNOWN_ERROR_CODE;
            $error_msg{$fname} = UNKNOWN_ERROR_MSG;
        }
        return $complete_xml_msg;
    }
    # Timeout.
    $error_code{$fname} = SOCKET_TIMEOUT_CODE;
    $error_msg{$fname} = SOCKET_TIMEOUT_MSG;
    return undef;
}

=head2 close_connection

Function to close open files and sockets.

=cut

sub close_connection {
    $connected = 0;
    $end_time = time;
    if ($sock) {
        $sel->remove($sock);
        $sock->close();
    }
}

=head2 is_connected

Function to report whether currently connected to BGPmon.

=cut

sub is_connected {
    return $connected;
}

=head2 messages_read

Get number of messages read.

=cut

sub messages_read {
    return $msgs_read;
}

=head2 uptime

Returns number of seconds the connection has been up.
If the connection is down, return 0.

=cut

sub uptime {
    if ($connected) {
        return time() - $start_time;
    }
    return 0;

}

=head2 connection_endtime

Returns the time the connection ended .
If the connection is up, return 0.

=cut

sub connection_endtime {
    if ($connected) {
        return 0;
    }
    return $end_time;

}

=head2 read_n_bytes

This function reads exactly n bytes from a connection.
returns undef on any error or connection close

=cut

sub read_n_bytes {
    my ($bytesneeded) = shift;
    my $fname = 'read_n_bytes';
    if ($bytesneeded < 0) {
        $error_code{$fname} = INVALID_NUM_BYTES_ERROR_CODE;
        $error_msg{$fname} = INVALID_NUM_BYTES_ERROR_MSG;
        return undef;
    }
    my $data = "";
    my $buf = "";
    my $bytesread = 0;
    while($bytesneeded > 0) {
        $bytesread = sysread($sock, $buf, $bytesneeded);
        if (!defined $bytesread) {
            $error_code{$fname} = READ_ERROR_CODE;
            $error_msg{$fname} = READ_ERROR_MSG . ": $!";
            return undef;
        }
        if ($bytesread == 0) {
            $error_code{$fname} = CONNECTION_CLOSED_CODE;
            $error_msg{$fname} = CONNECTION_CLOSED_MSG;
            return undef;
        }
        $data .= $buf;
        $bytesneeded = $bytesneeded - $bytesread;
    }
    return $data;
}

=head2 get_error_code

Get the error code for a given function
Input : the name of the function whose error code we should report
Output: the function's error code
        or ARGUMENT_ERROR if the user did not supply a function
        or INVALID_FUNCTION_SPECIFIED if the user provided an invalid function
Usage:  my $err_code = get_error_code("connect_archive");

=cut
sub get_error_code {
    my $function = shift;
    unless (defined $function) {
        return ARGUMENT_ERROR_CODE;
    }

    return $error_code{$function} if (defined $error_code{$function});
    return INVALID_FUNCTION_SPECIFIED_CODE;
}

=head2 get_error_message {

Get the error message of a given function
Input : the name of the function whose error message we should report
Output: the function's error message
        or ARGUMENT_ERROR if the user did not supply a function
        or INVALID_FUNCTION_SPECIFIED if the user provided an invalid function
Usage:  my $err_msg = get_error_message("read_xml_message");

=cut
sub get_error_message {
    my $function = shift;
    unless (defined $function) {
        return ARGUMENT_ERROR_MSG;
    }

    return $error_msg{$function} if (defined $error_msg{$function});
    return INVALID_FUNCTION_SPECIFIED_MSG;
}

=head2 get_error_msg

Shorthand call for get_error_message

=cut

sub get_error_msg{
    my $fname = shift;
    return get_error_message($fname);
}

=head1 AUTHOR

Kaustubh Gadkari, C<< <kaustubh at cs.colostate.edu> >>

=head1 BUGS

Please report any bugs or feature requests to C<bgpmon at netsec.colostate.edu>, or through
the web interface at L<http://bgpmon.netsec.colostate.edu>.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc BGPmon::Client

=cut

=head1 LICENSE AND COPYRIGHT
Copyright (c) 2012 Colorado State University

    Permission is hereby granted, free of charge, to any person
    obtaining a copy of this software and associated documentation
    files (the "Software"), to deal in the Software without
    restriction, including without limitation the rights to use,
    copy, modify, merge, publish, distribute, sublicense, and/or
    sell copies of the Software, and to permit persons to whom
    the Software is furnished to do so, subject to the following
    conditions:

    The above copyright notice and this permission notice shall be
    included in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
    EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
    OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
    NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
    HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
    WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
    FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
    OTHER DEALINGS IN THE SOFTWARE.\


  File: Client.pm
  Authors: Kaustubh Gadkari, Dan Massey, Cathie Olschanowsky
  Date: May 21, 2012

=cut
1; # End of BGPmon::Client
