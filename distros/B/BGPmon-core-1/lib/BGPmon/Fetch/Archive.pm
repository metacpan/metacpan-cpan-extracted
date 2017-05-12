package BGPmon::Fetch::Archive;
our $VERSION = '1.092';

use 5.006;
use strict;
use warnings;
use POSIX qw/strftime/;
use File::Path qw/mkpath rmtree/;
use BGPmon::Translator::XFB2PerlHash;
use BGPmon::Fetch::File;
use WWW::Curl::Easy;

BEGIN{
require Exporter;
    our $AUTOLOAD;
    our @ISA = qw(Exporter);
    our %EXPORT_TAGS = ( 'all' => [ qw(init_bgpdata connect_archive read_xml_message close_connection is_connected messages_read files_read uptime connection_endtime connection_duration get_error_code get_error_message get_error_msg) ] );
    our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
}

# connection status
my $msgs_read = 0;
my $files_read = 0;
my $connection_start;
my $connection_stop;
my $connected = 0;

#state variables to maintain state between calls to read_xml_message
my $upd_url;        #Root URL to retrieve update files from
my $begin_time;     #interval start time
my $end_time;       #interval end time
my $year;           #year/month used for URL construction
my $month;
my $append;         #variable to detect /UPDATES/ directories below the normal depth
my @index_page;     #list of HTML download links
my $scratch_dir = "/tmp/";
my $ignore_data_errors = 0;
my $ignore_incomplete_data = 0;

#Error codes and messages
my %error_code;
my %error_msg;
my @function_names = ('init_bgpdata', 'connect_archive', 'read_xml_message',
'close_connection', 'is_connected','uptime','connection_endtime',
'connection_duration');

use constant NO_ERROR_CODE => 0;
use constant NO_ERROR_MSG => 'No Error';
use constant UNDEFINED_ARGUMENT_CODE => 401;
use constant UNDEFINED_ARGUMENT_MSG => 'Undefined Argument(s)';
use constant UNCONNECTED_CODE => 402;
use constant UNCONNECTED_MSG => 'Not connected to an archive';
use constant ALREADY_CONNECTED_CODE => 403;
use constant ALREADY_CONNECTED_MSG => 'Already connected to an archive';
use constant NO_INDEX_PAGE_CODE => 404;
use constant NO_INDEX_PAGE_MSG => 'Unable to find an index page';
use constant SYSCALL_FAIL_CODE => 405;
use constant SYSCALL_FAIL_MSG => 'System call failed';
use constant INVALID_ARGUMENT_CODE => 406;
use constant INVALID_ARGUMENT_MSG => 'Invalid value given for argument';
use constant INIT_FAIL_CODE => 407;
use constant INIT_FAIL_MSG => 'Failed to initialize connection to archive';
use constant FILE_OPERATION_FAIL_CODE => 408;
use constant FILE_OPERATION_FAIL_MSG => 'File operation failed';
use constant DOWNLOAD_FAIL_CODE => 409;
use constant DOWNLOAD_FAIL_MSG => 'Failed to download file';
use constant INVALID_MESSAGE_CODE => 410;
use constant INVALID_MESSAGE_MSG => 'Invalid message read';
use constant INVALID_FUNCTION_SPECIFIED_CODE => 411;
use constant INVALID_FUNCTION_SPECIFIED_MSG => 'Invalid function specified';
use constant IGNORE_ERROR_CODE => 412;
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

BGPmon::Fetch::Archive

The BGPmon::Fetch::Archive module, to connect to an online archive of
BGP files, download XML files and read XML messages one at a time.

=head1 SYNOPSIS

The BGPmon::Fetch::Archive module provides functionality to connect
to an BGP archive and read one XML message at a time.

    use BGPmon::Fetch::Archive;
    my $ret = init_bgpdata('scratch_dir' => '/tmp/',
'ignore_incomplete_data' => 1, 'ignore_data_errors' => 0);
    my $ret = connect_archive('archive.netsec.colostate.edu/collectors/bgpdata-netsec/',
1234567890,2345678901);
    my $xml_msg = read_xml_message();
    my $ret = is_connected();
    my $num_read = messages_read();
    my $num_files = files_read();
    my $uptime = uptime();
    my $ret = close_connection();
    my $downtime = connection_endtime();
    my $duration = connection_duration();

=head1 EXPORT

init_bgpdata
connect_archive
read_xml_message
close_connection
is_connected
messages_read
files_read
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
archive connection.
Input:      The location to create a scratch directory in (default is /tmp)
            Whether to ignore potentially incomplete data (default is to check)
            Whether to ignore all data errors   (must also specify ignore
                incomplete data flag as well) (default is to check)
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
            $scratch_dir .= "/BGP.Archive.$$";
            $scratch_dir =~ s/\/\//\//;
            mkpath $scratch_dir;
            1;
        } or do {
            $error_code{$fname} = SYSCALL_FAIL_CODE;
            $error_msg{$fname} = SYSCALL_FAIL_MSG.": $@";
            return 0;
        };
        return 1;
    }
    else{
        eval{
            $new_dir .= "/BGP.Archive.$$";
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

    #Initialize the scratch directory and ignore-error flags for the
    #underlying File module
    if( !BGPmon::Fetch::File::init_bgpdata(%args) ){
        $error_code{$fname} = BGPmon::Fetch::File::get_error_code('init_bgpdata');
        $error_msg{$fname} = BGPmon::Fetch::File::get_error_msg('init_bgpdata');
        return 0;
    }

    #Reset some module state variables, including error codes
    $msgs_read = 0;
    $files_read = 0;
    for my $function_name (@function_names) {
        $error_code{$function_name} = NO_ERROR_CODE;
        $error_msg{$function_name} = NO_ERROR_MSG;
    }
    $connection_stop = undef;
    return 1;
}

=head2 connect_archive

Connects to an online archive.

Input:      archive URL page for some collector
                (i.e. "archive.netsec.colostate.edu/bgpdata-netsec/")
            start/end (UNIX timestamps corresponding to the data interval
            the user wants)

Output:     0 on success, 1 on failure

Usage:      my $ret = connect_archive(
                'archive.netsec.colostate.edu/collectors/bgpdata-netsec',
                1234567890,
                2345678901);

=cut

sub connect_archive {

    #Store arguments in state variables
    my ($url, $begin, $end) = @_;
    my $fname = "connect_archive";

    #Check for correct number of variables
    if( scalar(@_) < 3 ){
        $error_code{$fname} = UNDEFINED_ARGUMENT_CODE;
        $error_msg{$fname} = UNDEFINED_ARGUMENT_MSG;
        return 1;
    }

    #Check to make sure we aren't already connected to an archive
    if(is_connected()){
        $error_code{$fname} = ALREADY_CONNECTED_CODE;
        $error_msg{$fname} = ALREADY_CONNECTED_MSG;
        return 1;
    }

    #check to make sure start and end time are proper UNIX timestamps
    #and that the start time <= end time and the URL has no garbage characters
    if($begin =~ m/\D/ || $end =~ m/\D/ || $begin<0 || $end<0 ||
$begin > $end || $url =~ m/[^[:graph:]]/){
        $error_code{$fname} = INVALID_ARGUMENT_CODE;
        $error_msg{$fname} = INVALID_ARGUMENT_MSG;
        return 1;
    }

    #Set year/month variables with the start time
    my @c_time = gmtime($begin);
    $year = scalar strftime("%Y",@c_time);
    $month = scalar strftime("%m",@c_time);

    #Create the scratch directory if it has not already been created
    #and set the ignore-error flags to off
    if( $scratch_dir !~ m/BGP.Archive/ ){
        if(!init_bgpdata('ignore_incomplete_data'=>0,'ignore_data_errors'=>0)){
            $error_code{$fname} = INIT_FAIL_CODE;
            $error_msg{$fname} = INIT_FAIL_MSG;
            close_connection();
            return 1;
        }
    }

    $upd_url = $url;
    $begin_time = $begin;
    $end_time = $end;

    set_append();

    #Fetch the first update file (which will in turn get the first index file)
    if( !defined(get_next_update_file()) ){
        $error_code{$fname} = INIT_FAIL_CODE;
        $error_msg{$fname} = INIT_FAIL_MSG;
        close_connection();
        return 1;
    }

    $connected = 1;
    $connection_start = time;

    $error_code{$fname} = NO_ERROR_CODE;
    $error_msg{$fname} = NO_ERROR_MSG;

    return 0;
}

=head2 read_xml_message

Reads the next XML message from the data source that is in the interval.

Input:  None, but assumes connect_archive has been called

Output: The next XML message from the archive "stream" or undef

Usage:  my $msg = read_xml_message();

=cut

sub read_xml_message {
    my $fname = "read_xml_message";

    if( !is_connected() ){
        $error_code{$fname} = UNCONNECTED_CODE;
        $error_msg{$fname} = UNCONNECTED_MSG;
        return undef;
    }

    while( 1 ){
        #Try to get the next message
        my $msg = get_next_message();
        if( !defined($msg) ){
            $error_code{$fname} = INVALID_MESSAGE_CODE;
            $error_msg{$fname} = INVALID_MESSAGE_MSG;
            return undef;
        }
        my $msg_hashref = BGPmon::Translator::XFB2PerlHash::translate_msg($msg);
        if( !keys %$msg_hashref ){
            $error_code{$fname} = INVALID_MESSAGE_CODE;
            $error_msg{$fname} = INVALID_MESSAGE_MSG;
            return undef;
        }
        #Non BGP messages can have all sorts of weird timestamps, so we'll
        #just return any message that isn't a normal BGP_MESSAGE and let
        #the calling script deal with them.
        if(!defined BGPmon::Translator::XFB2PerlHash::get_content("/BGP_MESSAGE") ){
            $error_code{$fname} = NO_ERROR_CODE;
            $error_msg{$fname} = NO_ERROR_MSG;
            return $msg;
        }
        #If there is a message, evaluate its timestamp
        my $msg_time = BGPmon::Translator::XFB2PerlHash::get_content("/BGP_MESSAGE/TIME/timestamp");
        if( !defined($msg_time) ){
            $error_code{$fname} = INVALID_MESSAGE_CODE;
            $error_msg{$fname} = INVALID_MESSAGE_MSG;
            return $msg;
        }
        #if the message is too early, get the next one
        if( $msg_time < $begin_time ){
            next;
        }
        #If the message time >= start time but <= end_time, return it
        elsif( $msg_time <= $end_time ){
            $msgs_read++;
            $error_code{$fname} = NO_ERROR_CODE;
            $error_msg{$fname} = NO_ERROR_MSG;
            return $msg;
        }
        #Otherwise the message is past the interval and we quit
        else{
            close_connection();
            return undef;
        }
    }

    return undef;
}

=head2 close_connection

Function to close and delete any files and reset the module's state variables

Usage:  close_connection();

=cut

sub close_connection {
    my $fname = "close_connection";
    if( !is_connected() ){
        $error_code{$fname} = UNCONNECTED_CODE;
        $error_msg{$fname} = UNCONNECTED_MSG;
        return 1;
    }
    eval{
        my $errs;
        rmtree($scratch_dir,{keep_root => 1, safe => 1, error => \$errs});
        1;
    } or do {
        $error_code{$fname} = SYSCALL_FAIL_CODE;
        $error_msg{$fname} = SYSCALL_FAIL_MSG.": $@";
    };
    $connection_stop = time;
    BGPmon::Fetch::File::close_connection();
    ($upd_url,$year,$month,$begin_time,$end_time,@index_page) = undef;
    $connected = 0;
    $error_code{$fname} = NO_ERROR_CODE;
    $error_msg{$fname} = NO_ERROR_MSG;
    return 0;
}

=head2 is_connected

Function to report whether currently connected to an archive.

=cut

sub is_connected {
    return $connected;
}

=head2 messages_read

Get number of messages read.

Usage:  my $num_msgs = messages_read();

=cut

sub messages_read {
    return $msgs_read;
}

=head2 files_read

Get the number of files read.

Usage:  my $num_files = files_read();

=cut
sub files_read{
    return $files_read;
}

=head2 uptime

Returns number of seconds the connection has been up.
If the connection is down, return 0.

Usage:  my $time = uptime();

=cut

sub uptime {
    if ($connected) {
        return time() - $begin_time;
    }
    return 0;

}

=head2 connection_endtime

Returns the time the connection ended .
If the connection is up, return 0.

Usage:  my $time = connection_endtime();

=cut

sub connection_endtime {
    if ($connected) {
        return 0;
    }
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

Get the error code for a given function

Input : the name of the function whose error code we should report

Output: the function's error code
        or UNDEFINED_ARGUMENT if the user did not supply a function
        or INVALID_FUNCTION_SPECIFIED if the user provided an invalid function

Usage:  my $err_code = get_error_code("connect_archive");

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

Get the error message of a given function

Input : the name of the function whose error message we should report

Output: the function's error message
        or UNDEFINED_ARGUMENT if the user did not supply a function
        or INVALID_FUNCTION_SPECIFIED if the user provided an invalid function

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

################################# END EXPORTED FUNCTIONS ######################
###################### BEGIN UNEXPORTED FUNCTIONS #############################

#get_next_message
#This function retrieves the next message from the currently-open file
#or fetches the next available update file and then returns the first
#message from that file.
#Input:      None
#Output:     The next XML message in the archive "stream" or
#            undef if there are no more messages available.

sub get_next_message{
    my $fname = "get_next_message";
    #First see if there's an open update file going already
    if( !BGPmon::Fetch::File::is_connected() ){
        $error_code{$fname} = UNCONNECTED_CODE;
        $error_msg{$fname} = UNCONNECTED_MSG;
        return undef;
    }

    #Get the next message from the open XML file, or the next update file
    #if no message is found.
    my $msg = BGPmon::Fetch::File::read_xml_message();
    while( !defined($msg) ){
        #If there is no open update file, try to get the next one
        my $ret = get_next_update_file();
        if( !defined($ret) ){
            $error_code{$fname} = BGPmon::Fetch::File::get_error_code
("read_xml_message");
            $error_msg{$fname} = BGPmon::Fetch::File::get_error_message
("read_xml_message");
            return undef;
        }
        $msg = BGPmon::Fetch::File::read_xml_message();
    }
    return $msg;
}

# get_next_update_file
#
#Iterates through a list of files and downloads and opens the next one
#Input:      None
#Output:     0 on success, undef on failure
#            Also, the module-level filehandle upd_fh is open on success

sub get_next_update_file{
    my $fname = "get_next_update_file";
    my $next_url = "";

    if( is_connected() && BGPmon::Fetch::File::is_connected() ){
        $error_code{$fname} = FILE_OPERATION_FAIL_CODE;
        $error_msg{$fname} = FILE_OPERATION_FAIL_MSG;
        return undef;
    }

    #If there is no index page loaded for an otherwise connected archive,
    #then return an error
    if( !@index_page && is_connected() ){
        $error_code{$fname} = NO_INDEX_PAGE_CODE;
        $error_msg{$fname} = NO_INDEX_PAGE_MSG;
        return undef;
    }

    #Grab the URL of the next file to download
    $next_url = shift @index_page;
    if( !defined($next_url) || $next_url eq "" ){
        #If the current index page is exhausted, increment the month/year
        #and download the next index page
        advanceIndex() if is_connected();
        @index_page = get_next_index();
        if( !@index_page ){
            $error_code{$fname} = DOWNLOAD_FAIL_CODE;
            $error_msg{$fname} = DOWNLOAD_FAIL_MSG;
            return undef;
        }
        $next_url = shift @index_page;
    }

    #Extract the filename from the next URL to download
    my @url_split = split("/",$next_url);
    my $upd_fn = $url_split[-1];
    my $ret = download_URL($next_url,"$scratch_dir/".$upd_fn);
    if( !defined($ret) ){
        $error_code{$fname} = DOWNLOAD_FAIL_CODE;
        $error_msg{$fname} = DOWNLOAD_FAIL_MSG." $upd_fn";
        return undef;
    }

    if( BGPmon::Fetch::File::connect_file("$scratch_dir/".$upd_fn) ){
        $error_code{$fname} = FILE_OPERATION_FAIL_CODE;
        $error_msg{$fname} = FILE_OPERATION_FAIL_MSG;
        return undef;
    }
    $files_read++;

    return 0;
}

#advanceIndex
#A helper function to advance the month
#and possibly year module state variables.
#Input:      None
#Output:     None (returns 0)

sub advanceIndex{
    $month = sprintf("%02u",($month + 1) % 13);
    $month = "01" if $month == 0;
    $year = sprintf("%04u",$year + 1) if $month == 1;
    return 0;
}

#get_next_index

#Fetches an index HTML page and returns the contents as an array
#Input:         None
#Output: An array with the lines of the HTML, or undef on failure

sub get_next_index{
    my $fname = "get_next_index";
    my $index_url = "";
    my @html_index = undef;
    my $index_fh = undef;
    my $index_fn = "$scratch_dir/index.html";

    if(!defined($upd_url)||!defined($month)||
!defined($year)||!defined($append)){
        $error_code{$fname} = UNDEFINED_ARGUMENT_CODE;
        $error_msg{$fname} = UNDEFINED_ARGUMENT_MSG;
        return;
    }

    #Construct the current index URL from the current month and year
    $index_url = "$upd_url/$year.$month/$append";

    my $ret = download_URL($index_url,$index_fn);
    if( !defined($ret) ){
        $error_code{$fname} = DOWNLOAD_FAIL_CODE;
        $error_msg{$fname} = DOWNLOAD_FAIL_MSG;
        return;
    }

    #Open the saved index HTML file and load it into an array
    unless( open($index_fh,"<","$index_fn") ){
        $error_code{$fname} = FILE_OPERATION_FAIL_CODE;
        $error_msg{$fname} = FILE_OPERATION_FAIL_MSG.": $@";
        return;
    }

    while(<$index_fh>){
        my $line = $_;
        chomp($line);

        my $file_url = $index_url . get_filename_from_line($line);
        if( $file_url ne $index_url ){
            push(@html_index,$file_url);
        }
    }

    if( !@html_index ){
        $error_code{$fname} = NO_INDEX_PAGE_CODE;
        $error_msg{$fname} = NO_INDEX_PAGE_MSG;
        return;
    }

    close($index_fh);
    eval{
        unlink($index_fn);
        1;
    } or do {
        $error_code{$fname} = SYSCALL_FAIL_CODE;
        $error_msg{$fname} = SYSCALL_FAIL_MSG;
    };
    #This shift removes a leading undef at the beginning of the array.
    shift @html_index;
    return @html_index;
}

# get_filename_from_line

#This helper function extracts an update filename from a line of HTML.
#Input:      A single line of HTML code
#Output:     The filename extracted from the line (of the form
#                updates.YYYYMMDD.HHMM.*.xml.[compression type] )
#                or the empty string if none is found.

sub get_filename_from_line{
    my $line = shift;
    my $fname = "get_filename_from_line";
    if( !defined($line) ){
        $error_code{$fname} = UNDEFINED_ARGUMENT_CODE;
        $error_msg{$fname} = UNDEFINED_ARGUMENT_MSG;
        return undef;
    }

    #Filenames look like this: updates.YYYYMMDD.HHMM.*.xml
    #Filenames may also have an up-to-4-character extension for compressed
    if($line =~
m/(\"updates\.[0-9][0-9][0-9][0-9][0-1][0-9][0-3][0-9]\.[0-2][0-9][0-5][0-9].*\.xml(\.\w{0,4})?\")/){
        my $filename = $1;
        #Hack off the double-quotes on either side of the filename
        $filename =~ s/\"//g;
        return $filename;
    }
    return "";
}


#set_append

#This function tests different variants of the final possible subdirectory
#under an archive page.
#Input:      None
#Output:     0

sub set_append{
    my $fname = "set_append";
    my $url = $upd_url."/$year.$month/";
    my $output = "$scratch_dir/index-test.html";

    if(download_URL($url."UPDATES/",$output) == 0 && validateIndex($output) ){
        $append = "UPDATES/";
    }
    elsif(download_URL($url."updates/",$output)==0 && validateIndex($output) ){
        $append = "updates/";
    }
    elsif(download_URL($url,$output) == 0 && validateIndex($output) ){
        $append = "";
    }
    else {
        $append = undef;
    }
    eval{
        unlink($output);
        1;
    } or do {
        $error_code{$fname} = SYSCALL_FAIL_CODE;
        $error_msg{$fname} = SYSCALL_FAIL_MSG.": $@";
    };
    return 0;
}

# validateIndex
#A helper function to scan an HTML page to determine whether the page is
#a valid index page or something else.  It looks for the key phrase
#"Index of" with the current year.month subdirectory.
#Input:      The filename to check
#Output:     1 if the file matches the search, 0 otherwise

sub validateIndex{
    my $index_fn = shift;
    my $fname = "validateIndex";
    if( !defined($index_fn) ){
        $error_code{$fname} = UNDEFINED_ARGUMENT_CODE;
        $error_msg{$fname} = UNDEFINED_ARGUMENT_MSG;
        return 0;
    }
    my $index_fh;
    unless( open($index_fh,"<",$index_fn) ){
        $error_code{$fname} = FILE_OPERATION_FAIL_CODE;
        $error_msg{$fname} = FILE_OPERATION_FAIL_MSG;
        return 0;
    }

    while(<$index_fh>){
        my $line = $_;
        if( $line =~ m/Index of .*\/$year.$month\// ){
            close($index_fh);
            return 1;
        }
    }
    close($index_fh);
    return 0;
}

# download_URL
#
#Downloads a target file and saves it to a user-specified file
#This function is primarily a wrapper around several functions of
# the WWW::Curl module.
#Input:        a target URL, either an HTML index or another file
#              an output file name
#Output:       0 on success, undef on failure

sub download_URL{
    my $fname = "download_URL";
    #Initialize a libcurl object so we can do cool stuff
    #with curl like error handling.
    my $curl = WWW::Curl::Easy->new;
    my $dl_fh = undef;

    #Get argument(s) and check that they exist
    my $target_url = shift;
    my $output = shift;

    #If the target is not defined, obviously that is a problem
    if(!defined($target_url) || !defined($output) ){
        $error_code{$fname} = UNDEFINED_ARGUMENT_CODE;
        $error_msg{$fname} = UNDEFINED_ARGUMENT_MSG;
        return undef;
    }
    else{
        #Open a local filehandle for the output file
        unless(open($dl_fh,">","$output") ){
            $error_code{$fname} = FILE_OPERATION_FAIL_CODE;
            $error_msg{$fname} = FILE_OPERATION_FAIL_MSG.": $@";
            return undef;
        }
        #If the URL exists, set curl's download target and output file
        #and also tell curl to suppress it's progress meter
        $curl->setopt(CURLOPT_URL,"$target_url");
        $curl->setopt(CURLOPT_WRITEDATA,$dl_fh);
        $curl->setopt(CURLOPT_NOPROGRESS,1);
    }

    #Call curl to download the specified file into the given output file
    my $ret = $curl->perform;
    #If curl fails, log the reason why
    if($ret){
        $error_code{$fname} = DOWNLOAD_FAIL_CODE;
        $error_msg{$fname} = DOWNLOAD_FAIL_MSG.$curl->strerror($ret)." "
.$curl->errbuf;
        close $dl_fh;
        return undef;
    }

    #Close the open filehandle
    close $dl_fh;
    return 0;
}

########################### END UNEXPORTED FUNCTIONS ##########################

=head1 ERROR CODES AND MESSAGES
The following error codes and messages are defined:

    0:  No Error
        'No Error'

    401:    A subroutine was missing an expected argument
            'Undefined Argument(s)'

    402:    There is no active connection to an archive
            'Not connected to an archive'

    403:    There is a currently-active connection to an archive
            'Already connected to an archive'

    404:    The module was unable to find an HTML index page
                or any download links on the index page
            'Unable to find an index page'

    405:    A system call failed
            'System call failed'

    406:    An invalid value was passed to a subroutine as an argument
            'Invalid value given for argument'

    407:    The connection could not be initialized, either by a failure
                to set the scratch directory, ignore-error flags, or
                the first update file could not be loaded.
            'Failed to initialize connection to archive'

    408:    A filesystem 'open' command failed
            'File operation failed'

    409:    There was a failure trying to download a file
            'Failed to download file'

    410:    An invalid XML message was read, or the end of the archive was read
            'Invalid message read'

    411:    An invalid function name was passed to get_error_[code/message/msg]
            'Invalid function specified'

    412:    User tried to ignore all data errors, but was checking for
                incomplete data
            'Cannot have ignore_incomplete_data off with ignore_data_errors on'

=head1 AUTHOR

Jason Bartlett, C<< <bartletj at cs.colostate.edu> >>

=head1 BUGS

Please report any bugs or feature requests to C<bgpmon at netsec.colostate.edu>
, or through the web interface at L<http://bgpmon.netsec.colostate.edu>.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc BGPmon::Fetch::Archive

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

    File: Archive.pm

    Authors: Jason Bartlett, Kaustubh Gadkari, Dan Massey, Cathie Olschanowsky
    Date: 13 Jul 2012

=cut

1; # End of BGPmon::Fetch::Archive
