package BGPmon::Fetch2;
our $VERSION = '1.092';

use 5.006;
use strict;
use warnings;
use BGPmon::Fetch::Client2;
use BGPmon::Fetch::File;
use BGPmon::Fetch::Archive;

require Exporter;
our $AUTOLOAD;
our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw(connect_bgpdata read_xml_message close_connection is_connected messages_read uptime connection_endtime get_error_code get_error_message get_error_msg) ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

# Flag to determine type of data source we're connecting to
# 0 for live data, 1 for online archive, 2 for local file
our $use_offline_data = -1;

#error code/message
my %error_code;
my %error_msg;

#Error codes and messages
use constant NO_ERROR_CODE => 0;
use constant NO_ERROR_MSG => 'No Error. Life is good.';
use constant ARGUMENT_ERROR_CODE => 101;
use constant ARGUMENT_ERROR_MSG => 'Invalid number of arguments';
use constant UNCONNECTED_CODE => 102;
use constant UNCONNECTED_MSG => 'Not connected to a data source';
use constant INVALID_FUNCTION_SPECIFIED_CODE => 103;
use constant INVALID_FUNCTION_SPECIFIED_MSG => 'Invalid function name given';

my @function_names = ('init_bgpdata', 'connect_bgpdata', 'read_xml_message',
'close_connection', 'is_connected','uptime','connection_endtime');

for my $function_name (@function_names) {
    $error_code{$function_name} = NO_ERROR_CODE;
    $error_msg{$function_name} = NO_ERROR_MSG;
}

=head1 NAME

BGPmon::Fetch.pm

The BGPmon Fetch module, to connect to a live BGPmon stream,
an online archive of XFB data, or a single XML file.  The interface then
supports "streaming" of XML messages from the given data source.

=head1 SYNOPSIS

The BGPmon::Fetch module provides functionality to connect to one of the
following data sources:
    1) a live BGPmon instance
    2) an archive of XFB data
    3) an individual XML file
The user is then able to read XML messages in sequence from the appropriate
data source and get information about the currently-running connection.

    use BGPmon::Fetch;
    my $ret = init_bgpdata();
    my $ret = connect_bgpdata();
    my $xml_msg = read_xml_message();
    if ( !defined($xml_msg) ){
        print get_error_code() . ": " . get_error_msg();
    }
    my $ret = is_connected();
    my $num_read = messages_read();
    my $uptime = uptime();
    my $ret = close_connection();
    my $downtime = connection_endtime();

=head1 EXPORT

init_bgpdata
connect_bgpdata
read_xml_message
close_connection
is_connected
messages_read
uptime
connection_endtime
get_error_code
get_error_message
get_error_msg

=cut

=head1 SUBROUTINES/METHODS

=head2 init_bgpdata

Initialize parameters for any/all of the Fetch submodules.
File and Archive take the same three optional parameters:

    scratch_dir - a filesystem location to put a scratch directory in
        (default is /tmp)

    ignore_incomplete_data - a flag to turn off checking for possible gaps
        in the data "stream" (default is to check)

    ignore_data_errors - a flag to turn off checking for any other errors
        in the data. Using this flag requires setting ignore_incomplete_data.
        (default is to check)

Client also accepts the same scratch directory argument described above,
but will ignore the data-integrity flags, as a live stream is, well, live.

Usage:      my $ret = init_bgpdata('scratch_dir' => '/tmp',
                                    'ignore_incomplete_data' => 1,
                                    'ignore_data_errors' => 0);
            my $ret = init_bgpdata();
            my $ret = init_bgpdata('scratch_dir' => "~/");

=cut

sub init_bgpdata{
    my @args = @_;
    BGPmon::Fetch::File::init_bgpdata(@args);
    BGPmon::Fetch::Archive::init_bgpdata(@args);
    BGPmon::Fetch::Client::init_bgpdata(@args);

    return 0;
}

=head2 connect_bgpdata

This is a function which connects to the appropriate data source.
If a live data source is specified, the function opens a TCP connection to the
source. If an archived data source is specified, the function processes data
files from the given URL.  If a local file is specified, it will read data
from the file.

Input:  One of the following sets of arguments:
        [server_address, listening port]    -> this will connect to live data
        [URL,start time, end time]          -> this will connect to an archive
        [filename]                          -> this will connect to a file

Output: 1 on failure

=cut

sub connect_bgpdata {
    my $fname = 'connect_bgpdata';
    if (scalar(@_) == 2) { # Live data stream.
        my ($server, $port) = @_;
        $use_offline_data = 0;

        if( BGPmon::Fetch2::Client2::connect_bgpmon($server,$port) ){
            $error_code{$fname} = BGPmon::Fetch2::Client2::get_error_code('connect_bgpmon');
            $error_msg{$fname} = BGPmon::Fetch2::Client2::get_error_message('connect_bgpmon');
            return 1;
        }
    } elsif (scalar(@_) == 3) { # Archived data.
        my ($url, $start, $end) = @_;
        $use_offline_data = 1;

        if( BGPmon::Fetch::Archive::connect_archive($url, $start, $end) ){
            $error_code{$fname} = BGPmon::Fetch::Archive::get_error_code('connect_archive');
            $error_msg{$fname} = BGPmon::Fetch::Archive::get_error_message('connect_archive');
            return 1;
        }
    } elsif (scalar(@_) == 1){
        my $filename = shift;
        $use_offline_data = 2;

        if( BGPmon::Fetch::File::connect_file($filename) ){
            $error_code{$fname} = BGPmon::Fetch::File::get_error_code('connect_file');
            $error_msg{$fname} = BGPmon::Fetch::File::get_error_message('connect_file');
            return 1;
        }
    } else {
        $error_code{$fname} = ARGUMENT_ERROR_CODE;
        $error_msg{$fname} = ARGUMENT_ERROR_MSG;
        return 1;
    }
}

=head2 read_xml_message

This function reads and returns the next XML message from the currently
connected data source, or undef if there is an error OR there are no
more messages available (in File or Archive).

Usage:  my $msg = read_xml_message();

=cut

sub read_xml_message {
    my $fname = 'read_xml_message';
    if ($use_offline_data == 0) {
        my $msg = BGPmon::Fetch2::Client2::read_xml_message();
        if( !defined($msg) ){
            $error_code{$fname} = BGPmon::Fetch2::Client2::get_error_code('read_xml_message');
            $error_msg{$fname} = BGPmon::Fetch2::Client2::get_error_message('read_xml_message');
            return undef;
        }
        $error_code{$fname} = NO_ERROR_CODE;
        $error_msg{$fname} = NO_ERROR_MSG;
        return $msg;
    } elsif ($use_offline_data == 1) {
        my $msg = BGPmon::Fetch::Archive::read_xml_message();
        if( !defined($msg) ){
            $error_code{$fname} = BGPmon::Fetch::Archive::get_error_code('read_xml_message');
            $error_msg{$fname} = BGPmon::Fetch::Archive::get_error_message('read_xml_message');
            return undef;
        }
        else {
            $error_code{$fname} = NO_ERROR_CODE;
            $error_msg{$fname} = NO_ERROR_MSG;
            return $msg;
        }
    } elsif ($use_offline_data == 2) {
        my $msg = BGPmon::Fetch::File::read_xml_message();
        if( !defined($msg) ){
            $error_code{$fname} = BGPmon::Fetch::File::get_error_code('read_xml_message');
            $error_msg{$fname} = BGPmon::Fetch::File::get_error_message('read_xml_message');
            return undef;
        }
        else {
            $error_code{$fname} = NO_ERROR_CODE;
            $error_msg{$fname} = NO_ERROR_MSG;
            return $msg;
        }
    } else {
        $error_code{$fname} = UNCONNECTED_CODE;
        $error_msg{$fname} = UNCONNECTED_MSG;
        return undef;
    }
}

=head2 close_connection

This subroutine closes an active connection.  For File and Archive, this will
delete the scratch directory and close any open files.  For a live stream,
the TCP connection will be terminated.  The function returns 0 on success,
1 on failure

Usage: close_connection();

=cut

sub close_connection {
    my $fname = 'close_connection';
    if ($use_offline_data == 0) {
        if( BGPmon::Fetch::Client::close_connection() ){
            $error_code{$fname} = BGPmon::Fetch::Client::get_error_code("$fname");
            $error_msg{$fname} = BGPmon::Fetch::Client::get_error_message("$fname");
            return 1;
        }
    } elsif ($use_offline_data == 1) {
        if( BGPmon::Fetch::Archive::close_connection() ){
            $error_code{$fname} = BGPmon::Fetch::Archive::get_error_code("$fname");
            $error_msg{$fname} = BGPmon::Fetch::Archive::get_error_message("$fname");
            return 1;
        }
    } elsif ($use_offline_data == 2) {
        if( BGPmon::Fetch::File::close_connection() ){
            $error_code{$fname} = BGPmon::Fetch::File::get_error_code("$fname");
            $error_msg{$fname} = BGPmon::Fetch::File::get_error_message("$fname");
            return 1;
        }
    } else {
        $error_code{$fname} = UNCONNECTED_CODE;
        $error_msg{$fname} = UNCONNECTED_MSG;
        return undef;
    }
    return 0;
}

=head2 is_connected

Subroutine that simply returns whether or not there is a currently-active
connection.  If no connection has been initialized, returns undef.

Usage:  if( is_connected ) { #Do stuff }

=cut

sub is_connected {
    my $fname = 'is_connected';
    if ($use_offline_data == 0) {
        return BGPmon::Fetch2::Client2::is_connected();
    } elsif ($use_offline_data == 1) {
        return BGPmon::Fetch::Archive::is_connected();
    } elsif ($use_offline_data == 2) {
        return BGPmon::Fetch::File::is_connected();
    } else {
        $error_code{$fname} = UNCONNECTED_CODE;
        $error_msg{$fname} = UNCONNECTED_MSG;
        return undef;
    }
}

=head2 messages_read

Returns the number of messages read from the data source.  This also includes
any additional metadata messages that may be in the stream or within files.

Usage:  my $num_msgs = messages_read();

=cut

sub messages_read {
    my $fname = 'messages_read';
    if ($use_offline_data == 0) {
        return BGPmon::Fetch::Client::messages_read();
    } elsif ($use_offline_data == 1) {
        return BGPmon::Fetch::Archive::messages_read();
    } elsif ($use_offline_data == 2) {
        return BGPmon::Fetch::File::messages_read();
    } else {
        $error_code{$fname} = UNCONNECTED_CODE;
        $error_msg{$fname} = UNCONNECTED_MSG;
        return undef;
    }
}


=head2 uptime

Returns number of seconds the connection has been up.
If the connection is down or there has never been a connection, return 0.

Usage:  my $up = uptime();

=cut

sub uptime {
    my $fname = 'uptime';
    if ($use_offline_data == 0) {
        return BGPmon::Fetch::Client::uptime();
    } elsif ($use_offline_data == 1) {
        return BGPmon::Fetch::Archive::uptime();
    } elsif ($use_offline_data == 2) {
        return BGPmon::Fetch::File::uptime();
    } else {
        $error_code{$fname} = UNCONNECTED_CODE;
        $error_msg{$fname} = UNCONNECTED_MSG;
        return 0;
    }
}

=head2 connection_endtime

Returns the time the connection ended.
If the connection is up, return 0.
If there has been no connection, returns -1.

Usage:  my $e_time = connection_endtime();

=cut

sub connection_endtime {
    my $fname = 'connection_endtime';
    if ($use_offline_data == 0) {
        return BGPmon::Fetch::Client::connection_endtime();
    } elsif ($use_offline_data == 1) {
        return BGPmon::Fetch::Archive::connection_endtime();
    } elsif ($use_offline_data == 2) {
        return BGPmon::Fetch::File::connection_endtime();
    } else {
        $error_code{$fname} = UNCONNECTED_CODE;
        $error_msg{$fname} = UNCONNECTED_MSG;
        return -1;
    }
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

    # check we got a function name
    if (!defined($function)) {
        return ARGUMENT_ERROR_CODE;
    }

    return $error_code{$function} if defined($error_code{$function});
    return INVALID_FUNCTION_SPECIFIED_CODE;
}

=head2 get_error_message

Get the error message of a given function
Input : the name of the function whose error message we should report
Output: the function's error message
        or ARGUMENT_ERROR if the user did not supply a function
        or INVALID_FUNCTION_SPECIFIED if the user provided an invalid function
Usage:  my $err_msg = get_error_message("read_xml_message");

=cut

sub get_error_message {
    my $function = shift;

    # check we got a function name
    if (!defined($function)) {
        return ARGUMENT_ERROR_MSG;
    }

    return $error_msg{$function} if defined($error_msg{$function});
    return INVALID_FUNCTION_SPECIFIED_MSG."$function";
}

=head2 get_error_msg

Shorthand call for get_error_message

=cut

sub get_error_msg{
    my $fname = shift;
    return get_error_message($fname);
}

=head1 ERROR CODES AND MESSAGES

The following error codes and messages are defined for the Fetch module.
Additional error codes and messages are defined within Client, File,
and Archive, and can be inspected by running perldoc on each of them.

File uses Error codes 300-399
Archive uses Error codes 400-499
Client uses Error codes 500-599

    0:      No Error
            'No Error. Life is good.'

    101:    Too many or too few arguments were passed to connect_bgpdata or
                get_error_[code/message/msg]
            'Invalid number of arguments'

    102:    There is no connection (via connect_bgpdata) to a data source.
            'Not connected to a data source'

    103:    An invalid function name was passed to get_error_[code/message/msg]
            'Invalid function name specified'

=head1 AUTHOR

Kaustubh Gadkari, C<< <kaustubh at cs.colostate.edu> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bgpmon at netsec.colostate.edu>, or through
the web interface at L<http://bgpmon.netsec.colostate.edu>.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc BGPmon::Fetch

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

    File: Fetch.pm

    Authors: Kaustubh Gadkari, Dan Massey, Cathie Olschanowsky, Jason Bartlett
    Date: May 21, 2012

=cut

1; # End of BGPmon::Fetch

