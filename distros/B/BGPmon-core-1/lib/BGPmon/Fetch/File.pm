package BGPmon::Fetch::File;
our $VERSION = '1.092';

use 5.006;
use strict;
use warnings;
use POSIX qw/strftime/;
use IO::Uncompress::AnyUncompress qw(anyuncompress $AnyUncompressError);
use File::Path qw/mkpath rmtree/;
use XML::LibXML::Reader;

BEGIN{
require Exporter;
    our $AUTOLOAD;
    our @ISA = qw(Exporter);
    our %EXPORT_TAGS = ( 'all' => [ qw(init_bgpdata connect_file read_xml_message close_connection is_connected messages_read uptime connection_endtime connection_duration get_error_code get_error_message get_error_msg) ] );
    our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
}

# connection status
my $msgs_read = 0;
my $connection_start;
my $connection_stop;
my $connected = 0;
my $saw_start = 0;      #saw_start and saw_end track <ARCHIVER> tags
my $saw_end = 0;

#Set these to 1 to skip errors and/or incomplete data errors
my $ignore_data_errors = 0;
my $ignore_incomplete_data = 0;

#state variables to maintain state between calls to read_xml_message
my $upd_fh;         #filehandle for update files
my $upd_filename;   #Filename
my $xml_reader;     #variable to use as the XML reader

#scratch directory and default filename
my $scratch_dir = "/tmp/";
my $output_file = "extract_bgp.$$";

#Error codes and messages
my %error_code;
my %error_msg;
my @function_names = ('init_bgpdata', 'connect_file',  'read_xml_message', 'close_connection', 'is_connected', 'uptime', 'connection_endtime', 'connection_duration');

use constant NO_ERROR_CODE => 0;
use constant NO_ERROR_MSG => 'No Error';
use constant UNDEFINED_ARGUMENT_CODE => 301;
use constant UNDEFINED_ARGUMENT_MSG => 'Undefined Argument(s)';
use constant UNCONNECTED_CODE => 302;
use constant UNCONNECTED_MSG => 'Not connected to a file';
use constant ALREADY_CONNECTED_CODE => 303;
use constant ALREADY_CONNECTED_MSG => 'Already connected to a file';
use constant NO_SUCH_FILE_CODE => 304;
use constant NO_SUCH_FILE_MSG => 'Specified file/directory does not exist';
use constant SYSCALL_FAIL_CODE => 305;
use constant SYSCALL_FAIL_MSG => 'System call failed';
use constant DECOMPRESS_FAIL_CODE => 306;
use constant DECOMPRESS_FAIL_MSG => 'Failed to decompress file';
use constant OPEN_FAIL_CODE => 307;
use constant OPEN_FAIL_MSG => 'Failed to open file';
use constant PARSER_INIT_FAIL_CODE => 308;
use constant PARSER_INIT_FAIL_MSG => 'Failed to initialize XML Reader';
use constant PARSER_FATAL_ERROR_CODE => 309;
use constant PARSER_FATAL_ERROR_MSG => 'XML Parser Error';
use constant FILE_FORMAT_ERROR_CODE => 310;
use constant FILE_FORMAT_ERROR_MSG => 'File must begin with <xml> tag';
use constant INVALID_FUNCTION_SPECIFIED_CODE => 311;
use constant INVALID_FUNCTION_SPECIFIED_MSG => 'Invalid function specified';
use constant INIT_FAIL_CODE => 312;
use constant INIT_FAIL_MSG => 'Failed to initialize file connection';
use constant INCOMPLETE_DATA_CODE => 313;
use constant INCOMPLETE_DATA_MSG => 'File is missing expected ARCHIVER messages';
use constant DATA_GAP_CODE => 314;
use constant DATA_GAP_MSG => 'File may be missing data';
use constant IGNORE_ERROR_CODE => 315;
use constant IGNORE_ERROR_MSG => 'Cannot have ignore_incomplete_data off with ignore_data_errors on';

for my $function_name (@function_names) {
    $error_code{$function_name} = NO_ERROR_CODE;
    $error_msg{$function_name} = NO_ERROR_MSG;
}

END{
    my $errs;
    rmtree($scratch_dir,{keep_root => 1, safe => 1, error => \$errs});
}

=head1 NAME

BGPmon::Fetch::File

The BGPmon::Fetch::File module, to connect to a local XML file and read
XML messages one at a time.


=head1 SYNOPSIS

The BGPmon::Fetch::File module provides functionality to connect
to an XML file and read message at a time.

    use BGPmon::Fetch::File;
    my $ret = init_bgpdata('scratch_dir'=>'path/to/temp/dir',
'ignore_incomplete_data' => 0, 'ignore_data_errors' => 0);
    my $ret = connect_file('path/to/file');
    my $xml_msg = read_xml_message();
    my $ret = is_connected();
    my $num_read = messages_read();
    my $uptime = uptime();
    my $ret = close_connection();
    my $downtime = connection_endtime();
    my $duration = connection_duration();

=head1 EXPORT

init_bgpdata
connect_file
read_xml_message
close_connection
is_connected
messages_read
uptime
connection_endtime
connection_duration
get_error_code
get_error_message
get_error_msg

=cut

=head1 SUBROUTINES/METHODS

=head2 init_bgpdata

Initializes the scratch directory and error-checking flags for the next
file connection.

Input:      The location to create a scratch directory in (default is /tmp)
            Whether to ignore potentially incomplete data (default is off)
            Whether to ignore all data errors   (must also specify ignore
                incomplete data flag as well) (default is off)

Output:     0 if initialization fails
            1 if initialization succeeds

Usage:      my $ret = init_bgpdata('scratch_dir' => '/tmp',
                'ignore_incomplete_data' => 1, 'ignore_data_errors' => 0);

=cut

sub init_bgpdata{
    my %args = @_;
    my $fname = "init_bgpdata";

    #Extract the specified scratch directory if specified, otherwise
    #use the default directory (/tmp).
    my $new_dir = $args{'scratch_dir'};
    if( !defined($new_dir) ){
        eval{
            $scratch_dir .= "/BGP.File.$$";
            $scratch_dir =~ s/\/\//\//;
            mkpath $scratch_dir;
            1;
        } or do {
            $error_code{$fname} = SYSCALL_FAIL_CODE;
            $error_msg{$fname} = SYSCALL_FAIL_MSG.": $@";
            return 0;
        };
    }
    else{
        eval{
            $new_dir .= "/BGP.File.$$";
            $new_dir =~ s/\/\//\//;
            mkpath $new_dir;
            $scratch_dir = $new_dir;
            1;
        } or do {
            $error_code{$fname} = SYSCALL_FAIL_CODE;
            $error_msg{$fname} = SYSCALL_FAIL_MSG.": $@";
            return 0;
        };
    }

    #Get whether or not the user wants to ignore incomplete data or all data errors
    #It is an error to ignore all data errors but not incomplete data
    $ignore_incomplete_data = $args{'ignore_incomplete_data'} if defined $args{'ignore_incomplete_data'};
    $ignore_data_errors = $args{'ignore_data_errors'} if defined $args{'ignore_data_errors'};

    if( $ignore_data_errors && !$ignore_incomplete_data ){
        $error_code{$fname} = IGNORE_ERROR_CODE;
        $error_msg{$fname} = IGNORE_ERROR_MSG;
        return 0;
    }
    #Reset some module state variables, including error codes
    $saw_start = 0;
    $saw_end = 0;
    for my $function_name (@function_names) {
        $error_code{$function_name} = NO_ERROR_CODE;
        $error_msg{$function_name} = NO_ERROR_MSG;
    }
    $connection_stop = undef;
    return 1;
}

=head2 connect_file

This function connects to a local file.

Input:      the filename to read XML from

Output:     0 on success, 1 on failure

Usage:      my $ret = connect_file("path/to/file");

=cut

sub connect_file {

    #Store arguments in state variables
    my $filename = shift;

    my $fname = "connect_file";

    #Check for correct number of variables
    if( !defined($filename) ){
        $error_code{$fname} = UNDEFINED_ARGUMENT_CODE;
        $error_msg{$fname} = UNDEFINED_ARGUMENT_MSG;
        return 1;
    }

    #We cannot connect to a file while already connected to one
    if(is_connected()){
        $error_code{$fname} = ALREADY_CONNECTED_CODE;
        $error_msg{$fname} = ALREADY_CONNECTED_MSG;
        return 1;
    }

    #The file must exist before we can connect to it
    if(!file_check($filename) ){
        $error_code{$fname} = NO_SUCH_FILE_CODE;
        $error_msg{$fname} = NO_SUCH_FILE_MSG;
        return 1;
    }
    #Create the scratch directory if it has not already been created
    #This call will create the default scratch directory, and will NOT
    #ignore any data errors
    if( $scratch_dir !~ m/BGP.File/ ){
        if(!init_bgpdata('ignore_incomplete_data' => 0, 'ignore_data_errors' => 0)){
            $error_code{$fname} = INIT_FAIL_CODE;
            $error_msg{$fname} = INIT_FAIL_MSG;
            close_connection();
            return 1;
        }
    }
    #decompress_file never fails to return
    my $ret = decompress_file($filename);
    $filename = $ret if defined $ret;

    #Now open the now-uncompressed file
    unless( open($upd_fh, "<", "$scratch_dir/$filename") ){
        $error_code{$fname} = OPEN_FAIL_CODE;
        $error_msg{$fname} = OPEN_FAIL_MSG.": $@";
        return 1;
    }

    #Instantiate the XML parser
    unless($xml_reader = XML::LibXML::Reader->new(IO => $upd_fh, recover => 1)){
        $error_code{$fname} = PARSER_INIT_FAIL_CODE;
        $error_msg{$fname} = PARSER_INIT_FAIL_MSG;
        close($upd_fh);
        return 1;
    }

    #We require all files to start with an <xml> tag, and fail if it is not present.
    eval{
        unless( $xml_reader->read() == 1 && $xml_reader->localName() eq "xml"){
            $error_code{$fname} = FILE_FORMAT_ERROR_CODE;
            $error_msg{$fname} = FILE_FORMAT_ERROR_MSG;
            close($upd_fh);
            return 1;
        }
        1;
    } or do{
        $error_code{$fname} = PARSER_FATAL_ERROR_CODE;
        $error_msg{$fname} = PARSER_FATAL_ERROR_MSG.": $@";
        close($upd_fh);
        return 1;
    };

    #Now that we have successfully connected, set some remaining state variables
    #for this connection
    $msgs_read = 0;
    $upd_filename = "$scratch_dir/$filename";
    $connected = 1;
    $connection_start = time;

    $error_code{$fname} = NO_ERROR_CODE;
    $error_msg{$fname} = NO_ERROR_MSG;
    return 0;
}

=head2 read_xml_message

This function reads one XML message at a time from an open file connection.

Input:  None, but assumes connect_file has been called

Output: The next available XML message from the file, or undef if the
        messages are exhausted or some other failure is encountered

Usage:  my $next_msg = read_xml_message();

=cut

sub read_xml_message {
    my $fname = "read_xml_message";

    #There must be an open file connection to read from
    if( !is_connected() ){
        $error_code{$fname} = UNCONNECTED_CODE;
        $error_msg{$fname} = UNCONNECTED_MSG;
        return undef;
    }

    #The file that we're supposed to be connected to had better still be there
    if( !file_check($upd_filename) ){
        $error_code{$fname} = NO_SUCH_FILE_CODE;
        $error_msg{$fname} = NO_SUCH_FILE_MSG;
        close_connection();
        return undef;
    }
    my $complete_xml_msg = "";

    #For archive files, the root node (depth 0) is the <xml> tag
    #Therefore we want every XML message right under that (at depth 1)
    #These are mostly <BGP_MESSAGE>s, but could be anything
    while( $xml_reader->depth() != 1 || $xml_reader->nodeType() == XML_READER_TYPE_SIGNIFICANT_WHITESPACE){
        #First try to read the next node in the XML stream
        #If the XML parser itself fails, close the connection and return
        eval{
            #If read() returns 0, then we are at the end of the file
            #and we need to check for any data error.  However, the XML parser
            #can fail too, so this eval will catch both cases which we need
            #to differentiate in the do block.
            return undef if !$xml_reader->read();
            1;
        } or do {
            #This case catches any XML parser error.
            if($?){
                $error_code{$fname} = PARSER_FATAL_ERROR_CODE;
                $error_msg{$fname} = PARSER_FATAL_ERROR_MSG.": $@";
            }
            #Since the only other way to get into this block is for the file
            #to be done, this checks to make sure the file ended with an
            #ARCHIVER/CLOSED message (if we're looking for such things).
            elsif( $ignore_incomplete_data || $saw_end == 1 ){
                $error_code{$fname} = NO_ERROR_CODE;
                $error_msg{$fname} = NO_ERROR_MSG;
            }
            #If the ARCHIVER/CLOSED message was not there or there were
            #more than 1, there is an error.
            else{
                $error_code{$fname} = INCOMPLETE_DATA_CODE;
                $error_msg{$fname} = INCOMPLETE_DATA_MSG;
            }
            #All 3 cases terminate this connection.
            close_connection();
            return undef;
        };
    }
    eval{
        $complete_xml_msg .= $xml_reader->readOuterXml();
        #There are a couple of error cases to check w.r.t. ARCHIVER messages.
        #We must start off with an ARCHIVER/OPENED message
        #Any additional ARCHIVER/OPENED messages indicate missing data
        #We must see an ARCHIVER/END message
        if( !$ignore_data_errors && $xml_reader->localName() eq "ARCHIVER" &&
$xml_reader->nextElement("EVENT") == 1 ){
            #This block examines any ARCHIVER messages we encounter.
            #If the current message is an ARCHIVER/OPENED and we have not seen
            #any messages yet, then it is expected and we can set the flag
            #to indicate it.
            if($xml_reader->readInnerXml() eq "OPENED" && $msgs_read == 0){
                $saw_start = 1;
                $error_code{$fname} = NO_ERROR_CODE;
                $error_msg{$fname} = NO_ERROR_MSG;
            }
            #If the current message is an ARCHIVER/CLOSED message, then we
            #increment the count of such messages we've seen.  This will be
            #used later in error-detection.
            elsif( $xml_reader->readInnerXml() eq "CLOSED" ){
                $saw_end++;
            }
            #This case implies that the current message is an ARCHIVER/OPENED
            #message, but we've already seen one, so this is an error
            else{ return undef;}
            #Read to the beginning of the next XML message
            $xml_reader->read() while( $xml_reader->depth() != 1 ||
$xml_reader->nodeType() == XML_READER_TYPE_SIGNIFICANT_WHITESPACE );
        }
        1;
    #This block handles the error cases that can arise from the previous
    #block.  This can happen in two ways: either we've seen a duplicate
    #ARCHIVER/OPENED message or the XML parser itself failed.
    } or do {
        if( $msgs_read != 0 ){
            $error_code{$fname} = DATA_GAP_CODE;
            $error_msg{$fname} = DATA_GAP_MSG;
            #We only want to throw this error if we care about
            #incomplete data.
            if( !$ignore_incomplete_data ){
                close_connection();
                return undef;
            }
        }
        else{
            $error_code{$fname} = PARSER_FATAL_ERROR_CODE;
            $error_msg{$fname} = PARSER_FATAL_ERROR_MSG.": $@";
            close_connection();
            return undef;
        }
    };
    if( !defined($complete_xml_msg) ){
        $error_code{$fname} = FILE_FORMAT_ERROR_CODE;
        $error_msg{$fname} = FILE_FORMAT_ERROR_MSG.": $@";
        close_connection();
        return undef;
    }
    $xml_reader->next();
    #If we are checking data errors, then the first message MUST
    #be an ARCHIVER/OPENED message, otherwise throw the error and quit.
    if( $msgs_read == 0 && !$saw_start && !$ignore_data_errors){
        $error_code{$fname} = INCOMPLETE_DATA_CODE;
        $error_msg{$fname} = INCOMPLETE_DATA_MSG;
        close_connection();
        return undef;
    }
    $msgs_read++;
    $error_code{$fname} = NO_ERROR_CODE;
    $error_msg{$fname} = NO_ERROR_MSG;
    return $complete_xml_msg;
}


=head2 close_connection

Function to close and delete any files and reset the module's state variables

Usage:  close_connection();

=cut

sub close_connection {
    my $fname = "close_connection";
    #Can't close a connection that isn't there...
    if( !is_connected() ){
        $error_code{$fname} = UNCONNECTED_CODE;
        $error_msg{$fname} = UNCONNECTED_MSG;
        return 1;
    }
    #Close the XML reader
    $xml_reader->close();
    #Close the open file handle
    close($upd_fh) if defined(fileno $upd_fh);
    #Track the end of this connection
    $connection_stop = time;
    #Now try to delete the scratch directory; set an error if it fails
    #but do not return an error if the system call fails
    eval{
        my $errs;
        rmtree($scratch_dir,{keep_root => 1, safe => 1, error => \$errs});
        1;
    } or do {
        $error_code{$fname} = SYSCALL_FAIL_CODE;
        $error_msg{$fname} = SYSCALL_FAIL_MSG.": $@";
    };
    ($upd_fh,$upd_filename) = undef;
    $error_code{$fname} = NO_ERROR_CODE;
    $error_msg{$fname} = NO_ERROR_MSG;
    $connected = 0;
}

=head2 is_connected

Function to report whether currently connected to an archive.

=cut

sub is_connected {
    return $connected;
}

=head2 messages_read

Get number of messages read.

Usage:  my $msgs_read = messages_read();

=cut

sub messages_read {
    return $msgs_read;
}

=head2 uptime

Returns number of seconds the connection has been up.
If the connection is down, return 0.

Usage:  my $uptime = uptime();

=cut

sub uptime {
    if ($connected) {
        return time() - $connection_start;
    }
    return 0;

}

=head2 connection_endtime

Returns the time the connection ended .
If the connection is up, return 0.

Usage:  my $endtime = connection_endtime();

=cut

sub connection_endtime {
    my $fname = "connection_endtime";
    if ($connected) {
        $error_code{$fname} = ALREADY_CONNECTED_CODE;
        $error_msg{$fname} = ALREADY_CONNECTED_MSG;
        return 0;
    }
    $error_code{$fname} = NO_ERROR_CODE;
    $error_msg{$fname} = NO_ERROR_MSG;
    return $connection_stop;

}

=head2 connection_duration

Returns the total time the last connection was up for.
If the connection is up, returns 0.
NOTE: If a connection is currently established, call uptime().

Usage:  my $dur = connection_duration();

=cut
sub connection_duration{
    my $fname = "connection_duration";
    if( $connected) {
        $error_code{$fname} = ALREADY_CONNECTED_CODE;
        $error_msg{$fname} = ALREADY_CONNECTED_MSG;
        return 0;
    }
    $error_code{$fname} = NO_ERROR_CODE;
    $error_msg{$fname} = NO_ERROR_MSG;
    return $connection_stop - $connection_start;
}

=head2 get_error_code

Get the error code

Input : the name of the function whose error code we should report

Output: the function's error code
        or UNDEFINED_ARGUMENT if the user did not supply a function
        or INVALID_FUNCTION_SPECIFIED if the user provided an invalid function name

Usage:  my $err_code = get_error_code("connect_file");
=cut

sub get_error_code {
    my $function = shift;

    # check we got a function name
    if (!defined($function)) {
        return UNDEFINED_ARGUMENT_CODE;
    }

    return $error_code{$function} if defined($error_code{$function});
    return INVALID_FUNCTION_SPECIFIED_CODE;
}

=head2 get_error_message

Get the error message

Input : the name of the function whose error message we should report

Output: the function's error message
        or UNDEFINED_ARGUMENT if the user did not supply a function
        or INVALID_FUNCTION_SPECIFIED if the user provided an invalid function name

Usage:  my $err_msg = get_error_message("read_xml_message");
=cut

sub get_error_message {
    my $function = shift;

    # check we got a function name
    if (!defined($function)) {
        return UNDEFINED_ARGUMENT_MSG;
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


########################## END EXPORTED FUNCTIONS #############################
########################## BEGIN UNEXPORTED FUNCTIONS #########################

# file_check

#This function checks whether or not the currently-open file exists
#Input:  A filename to check
#Output: 1 if the file exists, 0 otherwise

sub file_check{
    my $file = shift;
    my $fname = "file_check";
    if( !defined($file) ){
        $error_code{$fname} = UNDEFINED_ARGUMENT_CODE;
        $error_msg{$fname} = UNDEFINED_ARGUMENT_MSG;
        return 0;
    }
    if( -e $file ){
        return 1;
    }
    else{
        $error_code{$fname} = NO_SUCH_FILE_CODE;
        $error_msg{$fname} = NO_SUCH_FILE_MSG;
        return 0;
    }
}

# decompress_file

#This function decompresses a file using Perl's IO::Uncompress library.
#Currently supports gzip, bzip2, RFC 1950/1951, zip,lzop,lzf,lzma,xz
#Input:      The filename to uncompress
#Returns:    undef on failure, the name of the uncompressed file on success

sub decompress_file{
    my $file = shift;
    my $fname = "decompress_file";
    if( !defined($file) ){
        $error_code{$fname} = UNDEFINED_ARGUMENT_CODE;
        $error_msg{$fname} = UNDEFINED_ARGUMENT_MSG;
        return undef;
    }
    if( is_connected() ){
        $error_code{$fname} = ALREADY_CONNECTED_CODE;
        $error_msg{$fname} = ALREADY_CONNECTED_MSG;
        return undef;
    }
    if( !file_check($file) || !file_check($scratch_dir) ){
        $error_code{$fname} = NO_SUCH_FILE_CODE;
        $error_msg{$fname} = NO_SUCH_FILE_MSG;
        return undef;
    }
    unless( anyuncompress $file => "$scratch_dir/$output_file" ){
        $error_code{$fname} = DECOMPRESS_FAIL_CODE;
        $error_msg{$fname} = DECOMPRESS_FAIL_MSG.": $@";
        return undef;
    }

    return $output_file;
}

########################## END UNEXPORTED #####################################

=head1 ERROR CODES AND MESSAGES

The following error codes and messages are defined:

    0:  No Error
        'No Error'

    301:    An argument to a function was undefined
            'Undefined Argument(s)'

    302:    There is no active connection to a file
            'Not connected to a file'

    303:    There is a currently-active connection to a file
            'Already connected to a file'

    304:    The filename or directory given does not exist
            'Specified file/directory does not exist'

    305:    A system call failed
            'System call failed'

    306:    Decompressing the file failed
            'Failed to decompress file'

    307:    The file was not opened successfully
            'Failed to open file'

    308:    Initializing the XML Reader failed
            'Failed to initialize XML Reader'

    309:    The XML Reader encountered a fatal error
            'XML Parser Error'

    310:    The XML file passed in did not begin with an <xml> tag
            'File must begin with <xml> tag'

    311:    An invalid function name was passed to get_error_[code/message/msg]
            'Invalid function specified'

    312:    There was an error initializing one or more of the options to init_bgpdata
            'Failed to initialize file connection'

    313:    At least one of the beginning ARCHIVER/OPENING or ARCHIVER/CLOSE
                messages were missing from the file
                NOTE: Setting the ignore_data_errors flag will suppress this
            'File is missing expected ARCHIVER messages'

    314:    An additional ARCHIVER/OPENING message was encountered during file
                processing. This indicates a likely gap in the data.
                NOTE: Setting the ignore_incomplete_data flag will suppress this
            'File may be missing data'

    315:    User tried to ignore all data errors, but was checking for incomplete data
            'Cannot have ignore_incomplete_data off with ignore_data_errors on'

=head1 AUTHOR

Jason Bartlett, C<< <bartletj at cs.colostate.edu> >>

=head1 BUGS

Please report any bugs or feature requests to C<bgpmon at netsec.colostate.edu>, or through
the web interface at L<http://bgpmon.netsec.colostate.edu>.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc BGPmon::Fetch::File

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

    File: File.pm

    Authors: Jason Bartlett, Kaustubh Gadkari, Dan Massey, Cathie Olschanowsky
    Date: 13 Jul 2012

=cut

1; # End of BGPmon::Fetch::File
