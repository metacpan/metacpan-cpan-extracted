package BGPmon::Log;
our $VERSION = '1.092';

use 5.006;
use strict;
use warnings;
use Carp;
use Sys::Syslog;   # for writing to syslog
use POSIX;         # for date/time parsing with strftime
use Sys::Hostname; # to get the hostname

require Exporter;
our %EXPORT_TAGS = ( "all" => [ qw(log_init log_close
                                   log_emerg log_emergency log_alert
                                   log_fatal log_crit log_critical
                                   log_err log_error
                                   log_warn log_warning log_notice log_info
                                   log_debug debug get_error_code
                                   get_error_message get_error_msg) ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @ISA = qw(Exporter);

# ----- The Different Logging levels and their matching functions ---
use constant LOG_EMERG => 0;       # log_emerg
use constant LOG_EMERGENCY => 0;   # log_emergency
use constant LOG_ALERT => 1;       # log_alert
use constant LOG_FATAL => 2;       # log_fatal
use constant LOG_CRIT => 2;        # log_crit
use constant LOG_CRITICAL => 2;    # log_critical
use constant LOG_ERR => 3;         # log_err
use constant LOG_ERROR => 3;       # log_error
use constant LOG_WARNING => 4;     # log_warning
use constant LOG_WARN => 4;        # log_warn
use constant LOG_NOTICE => 5;      # log_notice
use constant LOG_INFO => 6;        # log_info
use constant LOG_DEBUG => 7;       # log_debug

# ----- The Different Logging facilities ---
# we simply repeat the syslog module settings
use constant LOG_KERN => Sys::Syslog::LOG_KERN;
use constant LOG_USER => Sys::Syslog::LOG_USER;
use constant LOG_MAIL => Sys::Syslog::LOG_MAIL;
use constant LOG_DAEMON => Sys::Syslog::LOG_DAEMON;
use constant LOG_SECURITY => Sys::Syslog::LOG_SECURITY;
use constant LOG_SYSLOG => Sys::Syslog::LOG_SYSLOG;
use constant LOG_LPR => Sys::Syslog::LOG_LPR;
use constant LOG_NEWS => Sys::Syslog::LOG_NEWS;
use constant LOG_UUCP => Sys::Syslog::LOG_UUCP;
use constant LOG_AUTH => Sys::Syslog::LOG_AUTH;
use constant LOG_AUTHPRIV => Sys::Syslog::LOG_AUTHPRIV;
use constant LOG_FTP => Sys::Syslog::LOG_FTP;
use constant LOG_NTP => Sys::Syslog::LOG_NTP;
use constant LOG_AUDIT => Sys::Syslog::LOG_AUDIT;
use constant LOG_CONSOLE => Sys::Syslog::LOG_CONSOLE;
use constant LOG_INSTALL => Sys::Syslog::LOG_INSTALL;
use constant LOG_LAUNCHD => Sys::Syslog::LOG_LAUNCHD;
use constant LOG_LFMT => Sys::Syslog::LOG_LFMT;
use constant LOG_NETINFO => Sys::Syslog::LOG_NETINFO;
use constant LOG_RAS => Sys::Syslog::LOG_RAS;
use constant LOG_REMOTEAUTH => Sys::Syslog::LOG_REMOTEAUTH;
use constant LOG_CRON => Sys::Syslog::LOG_CRON;
use constant LOG_LOCAL0 => Sys::Syslog::LOG_LOCAL0;
use constant LOG_LOCAL1 => Sys::Syslog::LOG_LOCAL1;
use constant LOG_LOCAL2 => Sys::Syslog::LOG_LOCAL2;
use constant LOG_LOCAL3 => Sys::Syslog::LOG_LOCAL3;
use constant LOG_LOCAL4 => Sys::Syslog::LOG_LOCAL4;
use constant LOG_LOCAL5 => Sys::Syslog::LOG_LOCAL5;
use constant LOG_LOCAL6 => Sys::Syslog::LOG_LOCAL6;
use constant LOG_LOCAL7 => Sys::Syslog::LOG_LOCAL7;

# ----- The default log settings ---
use constant DEFAULT_LOG_LEVEL => LOG_WARNING;
use constant DEFAULT_LOG_FACILITY => LOG_LOCAL1;
use constant DEFAULT_USE_SYSLOG => 0;
use constant DEFAULT_USE_GMT => 1;
use constant MAX_STRING_LEN => 256;

# --- constants used to indicate error codes and messages---
use constant NO_ERROR_CODE => 0;
use constant NO_ERROR_MSG =>
    'No Error';
use constant NO_FUNCTION_SPECIFIED_CODE => 1;
use constant NO_FUNCTION_SPECIFIED_MSG =>
    'Error reporting function called without specifying the function.';
use constant INVALID_FUNCTION_SPECIFIED_CODE => 2;
use constant INVALID_FUNCTION_SPECIFIED_MSG =>
    'Error reporting function called with invalid function name';
use constant LOG_INIT_NO_HOSTNAME_CODE => 3;
use constant LOG_INIT_NO_HOSTNAME_MSG =>
    'Unable to get the hostname';
use constant LOG_INIT_PROG_SIZE_CODE => 4;
use constant LOG_INIT_PROG_SIZE_MSG =>
    'Program name exceeds maximum length of '.MAX_STRING_LEN;
use constant LOG_INIT_PROG_PRINTABLE_CODE => 5;
use constant LOG_INIT_PROG_PRINTABLE_MSG =>
    'Program name contains non-printable characters';
use constant LOG_INIT_LEVEL_NOT_NUM_CODE => 6;
use constant LOG_INIT_LEVEL_NOT_NUM_MSG =>
    'Log level must be a postive integer';
use constant LOG_INIT_LEVEL_RANGE_CODE => 7;
use constant LOG_INIT_LEVEL_RANGE_MSG =>
    'Log level must be between '.LOG_EMERG.' and '.LOG_DEBUG;
use constant LOG_INIT_FACILITY_NOT_NUM_CODE => 8;
use constant LOG_INIT_FACILITY_NOT_NUM_MSG =>
    'Log facility must be a postive integer';
use constant LOG_INIT_FILE_SIZE_CODE => 9;
use constant LOG_INIT_FILE_SIZE_MSG =>
    'Log file exceeds maximum length of '.MAX_STRING_LEN;
use constant LOG_INIT_FILE_PRINTABLE_CODE => 10;
use constant LOG_INIT_FILE_PRINTABLE_MSG =>
    'Log file contains non-printable characters';
use constant LOG_INIT_SYSLOG_NOT_NUM_CODE => 11;
use constant LOG_INIT_SYSLOG_NOT_NUM_MSG =>
    'use_syslog must be 0 or 1';
use constant LOG_INIT_SYSLOG_RANGE_CODE => 12;
use constant LOG_INIT_SYSLOG_RANGE_MSG =>
    'use_syslog must be 0 or 1';
use constant LOG_INIT_GMT_NOT_NUM_CODE => 13;
use constant LOG_INIT_GMT_NOT_NUM_MSG =>
    'use_syslog must be 0 or 1';
use constant LOG_INIT_GMT_RANGE_CODE => 14;
use constant LOG_INIT_GMT_RANGE_MSG =>
    'use_gmt must be 0 or 1';
use constant LOG_INIT_GMT_SYSLOG_CODE => 15;
use constant LOG_INIT_GMT_SYSLOG_MSG =>
    'use_gmt not allowed when use_syslog = 1';
use constant LOG_INIT_SYSLOG_AND_FILE_CODE => 16;
use constant LOG_INIT_SYSLOG_AND_FILE_MSG =>
   'Unable to both use_syslog and write to a file';
use constant LOG_INIT_SYSLOG_OPEN_CODE => 17;
use constant LOG_INIT_SYSLOG_OPEN_MSG =>
   'Unable to open syslog';
use constant LOG_INIT_FILE_OPEN_CODE => 18;
use constant LOG_INIT_FILE_OPEN_MSG =>
   'Unable to open log file';
use constant LOG_NOT_INITIALIZED_CODE => 19;
use constant LOG_NOT_INITIALIZED_MSG =>
   'Logging not initialized.   Use init_log() prior to calling log_*("msg")';
use constant LOG_UNKNOWN_FUNCTION_CODE => 20;
use constant LOG_UNKNOWN_FUNCTION_MSG =>
   'No such log function';
use constant LOG_MISSING_MSG_CODE => 21;
use constant LOG_MISSING_MSG_MSG =>
   'Log function called with no log message';
use constant LOG_MSG_SIZE_CODE => 22;
use constant LOG_MSG_SIZE_MSG =>
    'Log message exceeds maximum length of '.MAX_STRING_LEN;
use constant LOG_MSG_PRINTABLE_CODE => 23;
use constant LOG_MSG_PRINTABLE_MSG =>
    'Message contains non-printable characters';
use constant LOG_WRITE_FAILED_CODE => 24;
use constant LOG_WRITE_FAILED_MSG =>
   'Unable to write log messsage';

# --- error code/message ---
my %error_code;
my %error_msg;
# init the error codes for all functions
my @function_names = ("log_init", "log_close",
                      "log_emerg", "log_emergency", "log_alert",
                      "log_fatal", "log_crit", "log_critical", "log_err",
                      "log_error", "log_warn", "log_warning", "log_notice",
                      "log_info", "log_debug", "debug");
for my $function_name (@function_names) {
    $error_code{$function_name} = NO_ERROR_CODE;
    $error_msg{$function_name} = NO_ERROR_MSG;
}

# ----- The Different Logging levels and their matching functions ---
our %function_level;               # maps function names to levels
our %function_description;         # maps function names to descriptions
$function_level{"log_emerg"} = LOG_EMERG;
$function_description{"log_emerg"} = "[LOG_EMERG]";
$function_level{"log_emergency"} = LOG_EMERGENCY;
$function_description{"log_emergency"} = "[LOG_EMERGENCY]";
$function_level{"log_alert"} = LOG_ALERT;
$function_description{"log_alert"} = "[LOG_ALERT]";
$function_level{"log_fatal"} = LOG_FATAL;
$function_description{"log_fatal"} = "[LOG_FATAL]";
$function_level{"log_crit"} = LOG_CRIT;
$function_description{"log_crit"} = "[LOG_CRIT]";
$function_level{"log_critical"} = LOG_CRITICAL;
$function_description{"log_critical"} = "[LOG_CRITICAL]";
$function_level{"log_err"} = LOG_ERR;
$function_description{"log_err"} = "[LOG_ERR]";
$function_level{"log_error"} = LOG_ERR;
$function_description{"log_error"} = "[LOG_ERROR]";
$function_level{"log_warning"} = LOG_WARNING;
$function_description{"log_warning"} = "[LOG_WARNING]";
$function_level{"log_warn"} = LOG_WARN;
$function_description{"log_warn"} = "[LOG_WARN]";
$function_level{"log_notice"} = LOG_NOTICE;
$function_description{"log_notice"} = "[LOG_NOTICE]";
$function_level{"log_info"} = LOG_INFO;
$function_description{"log_info"} = "[LOG_INFO]";
$function_level{"log_debug"} = LOG_INFO;
$function_description{"log_debug"} = "[LOG_DEBUG]";
$function_level{"debug"} = LOG_INFO;
$function_description{"debug"} = "[DEBUG]";

# ---   User configurable log settings --
my $prog_name = $0;
my $log_level = DEFAULT_LOG_LEVEL;
my $log_facility = DEFAULT_LOG_FACILITY;
my $log_file;
my $use_syslog = DEFAULT_USE_SYSLOG;
my $use_gmt = DEFAULT_USE_GMT;

# ---   internal state of the log module --
my $pid = $$;
my $hostname = "not initialized";
my $log_initialized = 0;
my $use_stderr = 0;
my $log_fh;

=head1 NAME

BGPmon::Log - BGPmon Logging

This module implements logging for BGPmon clients. The module can log messages
to syslog, STDERR,  or a user specified log file.   It allows the user to
specify a log level and write log messages using different log levels.

=cut

=head1 SYNOPSIS

After initializing the log,  the user can log messages at different log levels.

use BGPmon::Log qw (debug
                    log_debug
                    log_info
                    log_notice
                    log_warn log_warning
                    log_err  log_error
                    log_fatal log_crit log_critical
                    log_alert
                    log_emerg log_emergency
                   );

my %log_param = ( prog_name => "my name",
                  log_level => BGPmon::Log::LOG_DEBUG(),
                  log_facility => BGPmon::Log::LOG_LOCAL0(),
                  log_file => "./mylog",
                  use_syslog => 0,
                  use_gmt => 0,
                );

if (BGPmon::Log::log_init(%log_param) ) {
    my $code = BGPmon::Log::get_error_code("log_init");
    my $msg = BGPmon::Log::get_error_message("log_init");
    print STDERR "Error initializing log: $code - $msg\n";
    exit 1;
}

debug("Log a message with level BGPmon::Log::LOG_DEBUG");

log_debug("Also log a message with level BGPmon::Log::LOG_DEBUG");

log_info("Log a message, level BGPmon::Log::LOG_INFO");

log_notice("Log a message, level BGPmon::Log::LOG_NOTICE");

log_warn("Log a message, level BGPmon::Log::LOG_WARN");

log_warning("Log a message, level BGPmon::Log::LOG_WARNING");

log_err("Log a message, level BGPmon::Log::LOG_ERR");

log_error("Log a message, level BGPmon::Log::LOG_ERROR");

log_fatal("Log a message, level BGPmon::Log::LOG_FATAL");

log_crit("Log a message, level BGPmon::Log::LOG_CRIT");

log_critical("Log a message, level BGPmon::Log::LOG_CRITICAL");

log_alert("Log a message, level BGPmon::Log::LOG_ALERT");

log_emergency("Log a message, level BGPmon::Log::LOG_EMERGENCY");

log_emerg("Log a message, level BGPmon::Log::LOG_EMERG");

BGPmon::Log::log_close();

=head1 EXPORT

log_init
log_close
log_emerg
log_emergency
log_alert
log_fatal
log_crit
log_critical
log_err
log_error
log_warn
log_warning
log_notice
log_info
log_debug
debug
get_errror_code
get_error_message
get_error_msg

=head1 SUBROUTINES/METHODS

=head2 log_init

Initialize the logging facility.   This function must be called prior to using
any log_* functions.

Input : The log settings
       1. prog_name - The program name
       2. log_level - the log level
       3. log_facility - the log facility
       4. log_file -  the file where log messages will be written
       5. use_syslog - flag indicating whether to use syslog, 1 = use syslog,
       5. use_gmt - flag indicating whether to GMT for time or use local time,
             1 = use GMT,  use_gmt can only be set when use_syslog = 0
Output: returns 0 on success,  1 on error and setserror_message and error_code

If use_syslog=1,  all log messages are written to syslog.
  if the user sets both use_syslog=1 and provides a log_file,  the log_file
  is ignored.

If use_syslog != 1,  log messages are written to the log_file,  if provided
  if no log file is provided to init,  all messages are written to STDERR

=cut
sub log_init {
    my %args = @_;

    # set function name for error reporting
    my $function_name = $function_names[0];

    # reset configurable values to their defaults
    $prog_name = $0;
    $log_level = DEFAULT_LOG_LEVEL;
    $log_facility = DEFAULT_LOG_FACILITY;
    $use_syslog = DEFAULT_USE_SYSLOG;
    $use_gmt = DEFAULT_USE_GMT;
    # reset the internal log variables
    $log_initialized = 0;
    $pid = $$;
    $hostname = Sys::Hostname::hostname;
    if (!defined($hostname)) {
        $error_code{$function_name} = LOG_INIT_NO_HOSTNAME_CODE;
        $error_msg{$function_name} = LOG_INIT_NO_HOSTNAME_MSG;
        return 1;
    }
    $log_file = undef;
    $use_stderr = 0;
    $log_fh = undef;

    # parse the init arguements and over-ride any defaults
    if (defined($args{prog_name})) {
        if ($args{prog_name} =~ /^[[:print:]]*$/) {
            if (length($args{prog_name}) > MAX_STRING_LEN ) {
                $error_code{$function_name} = LOG_INIT_PROG_SIZE_CODE;
                $error_msg{$function_name} = LOG_INIT_PROG_SIZE_MSG;
                return 1;
            }
            $prog_name = $args{prog_name};
        } else {
            # prog_name contains non-printable characters
            $error_code{$function_name} = LOG_INIT_PROG_PRINTABLE_CODE;
            $error_msg{$function_name} = LOG_INIT_PROG_PRINTABLE_MSG;
            return 1;
        }
    }
    if (defined($args{log_level})) {
        # make sure it is a number
        if ($args{log_level} =~ /\D/) {
            # not a number or out of range
            $error_code{$function_name} = LOG_INIT_LEVEL_NOT_NUM_CODE;
            $error_msg{$function_name} = LOG_INIT_LEVEL_NOT_NUM_MSG;
            return 1;
        }
        # make sure it is in range
        if ($args{log_level} < LOG_EMERG || $args{log_level} > LOG_DEBUG) {
            $error_code{$function_name} = LOG_INIT_LEVEL_RANGE_CODE;
            $error_msg{$function_name} = LOG_INIT_LEVEL_RANGE_MSG;
            return 1;
        }
        $log_level = $args{log_level};
    }
    if (defined($args{log_facility})) {
        # make sure it is a number
        if ($args{log_facility} =~ /\D/) {
            # not a number or out of range
            $error_code{$function_name} = LOG_INIT_FACILITY_NOT_NUM_CODE;
            $error_msg{$function_name} = LOG_INIT_FACILITY_NOT_NUM_MSG;
            return 1;
        }
        $log_facility = $args{log_facility};
    }
    if (defined($args{log_file})) {
        if ($args{log_file} =~ /^[[:print:]]*$/) {
            if (length($args{log_file}) > MAX_STRING_LEN ) {
                $error_code{$function_name} = LOG_INIT_FILE_SIZE_CODE;
                $error_msg{$function_name} = LOG_INIT_FILE_SIZE_MSG;
                return 1;
            }
            $log_file = $args{log_file};
        } else {
            # prog_name contains non-printable characters
            $error_code{$function_name} = LOG_INIT_FILE_PRINTABLE_CODE;
            $error_msg{$function_name} = LOG_INIT_FILE_PRINTABLE_MSG;
            return 1;
        }
    }
    if (defined($args{use_syslog})) {
        # make sure it is a number
        if ($args{use_syslog} =~ /\D/) {
            # not a number or out of range
            $error_code{$function_name} = LOG_INIT_SYSLOG_NOT_NUM_CODE;
            $error_msg{$function_name} = LOG_INIT_SYSLOG_NOT_NUM_MSG;
            return 1;
        }
        # make sure it is in range
        if ($args{use_syslog} != 0 && $args{use_syslog} != 1) {
            $error_code{$function_name} = LOG_INIT_SYSLOG_RANGE_CODE;
            $error_msg{$function_name} = LOG_INIT_SYSLOG_RANGE_MSG;
            return 1;
        }
        $use_syslog = $args{use_syslog};
    }
    if (defined($args{use_gmt})) {
        # make sure it is a number
        if ($args{use_gmt} =~ /\D/) {
            # not a number or out of range
            $error_code{$function_name} = LOG_INIT_GMT_NOT_NUM_CODE;
            $error_msg{$function_name} = LOG_INIT_GMT_NOT_NUM_MSG;
            return 1;
        }
        # make sure it is in range
        if ($args{use_gmt} != 0 && $args{use_gmt} != 1) {
            $error_code{$function_name} = LOG_INIT_GMT_RANGE_CODE;
            $error_msg{$function_name} = LOG_INIT_GMT_RANGE_MSG;
            return 1;
        }
        if ($use_syslog == 1) {
            $error_code{$function_name} = LOG_INIT_GMT_SYSLOG_CODE;
            $error_msg{$function_name} = LOG_INIT_GMT_SYSLOG_MSG;
            return 1;
        }
        $use_gmt = $args{use_gmt};
    }

    # error if the specified both use_syslog and log to a file
    if (($use_syslog == 1) && (defined($log_file)) ) {
        $error_code{$function_name} = LOG_INIT_SYSLOG_AND_FILE_CODE;
        $error_msg{$function_name} = LOG_INIT_SYSLOG_AND_FILE_MSG;
        return 1;
    }

    # open syslog if use_syslog set
    if ($use_syslog == 1) {
        if (! Sys::Syslog::openlog($prog_name, "ndelay,pid", $log_facility)) {
            $error_code{$function_name} = LOG_INIT_SYSLOG_OPEN_CODE;
            $error_msg{$function_name} = LOG_INIT_SYSLOG_OPEN_MSG;
            return 1;
        }
        $log_initialized = 1;
        $error_code{$function_name} = NO_ERROR_CODE;
        $error_msg{$function_name} = NO_ERROR_MSG;
        return 0;
    }

    # open file if file was provided
    if (defined($log_file)) {
        if (! open($log_fh, ">>$log_file") ) {
            $error_code{$function_name} = LOG_INIT_FILE_OPEN_CODE;
            $error_msg{$function_name} = LOG_INIT_FILE_OPEN_MSG;
            return 1;
        }
        $log_initialized = 1;
        $error_code{$function_name} = NO_ERROR_CODE;
        $error_msg{$function_name} = NO_ERROR_MSG;
        return 0;
    }

    # no use_syslog and no log file so write to STDERR
    $log_initialized = 1;
    $use_stderr = 1;
    $log_fh = *STDERR;
    $error_code{$function_name} = NO_ERROR_CODE;
    $error_msg{$function_name} = NO_ERROR_MSG;
    return 0;
}

=head2 log_close

Closes the logfile so no further log messages can be written
You must call log_init again to re-enable logging.

Typically called at the end of program to cleanly close the log file
or cleanly close the connection to syslog.

Input: None
Output: None
=cut
sub log_close {

    # set function name for error reporting
    my $function_name = $function_names[1];

    # if already closed,  just return
    if ($log_initialized) {

        # set initialized back to 0
        $log_initialized = 0;

        # close the  log
        if ($use_syslog) {
            closelog();
        } elsif (!$use_stderr) {
            close($log_fh);
        }
    }

    $error_code{$function_names[7]} = NO_ERROR_CODE;
    $error_msg{$function_names[7]} = NO_ERROR_MSG;
    return 0;
}

=head2 log_emerg

Logs an emergency message.  Log levels LOG_EMERG

Input: Message to be printed.
Output: returns 0 on success,  1 on error and sets error_message and error_code
=cut
# implemented using AUTOLOADER

=head2 log_emergency

Logs an emergency message.  Log levels LOG_EMERGENCY

This function is identical to log_emerg
=cut
# implemented using AUTOLOADER

=head2 log_alert

Logs an alert message.  Log levels LOG_ALERT

Input: Message to be printed.
Output: returns 0 on success,  1 on error and sets error_message and error_code
=cut
# implemented using AUTOLOADER

=head2 log_fatal
Logs a fatal error message.  Log levels LOG_CRIT

Input: Message to be printed.
Output: returns 0 on success,  1 on error and sets error_message and error_code
=cut
# implemented using AUTOLOADER

=head2 log_crit
Logs a critical error message.  Log levels LOG_CRIT

This function is identical to log_fatal
=cut
# implemented using AUTOLOADER

=head2 log_critical

Logs a critical error message.  Log levels LOG_CRIT

This function is identical to log_fatal
=cut
# implemented using AUTOLOADER

=head2 log_err

Logs an error message.  Log level LOG_ERR.
Input: Message to be printed.
Output: returns 0 on success,  1 on error and sets error_message and error_code
=cut
# implemented using AUTOLOADER

=head2 log_error

Logs an error message.  Log level LOG_ERR.

This function is identical to log_fatal
=cut
# implemented using AUTOLOADER

=head2 log_warn

Logs a warning message.  Log level LOG_WARN
This function is identical to log_fatal
Input: Message to be printed.
Output: returns 0 on success,  1 on error and sets error_message and error_code
=cut
# implemented using AUTOLOADER

=head2 log_warning

Logs a warning message.  Log level LOG_WARNING

This function is identical to log_warn
=cut
# implemented using AUTOLOADER

=head2 log_notice

Logs a notice message.  Log level LOG_NOTICE
Input: Message to be printed.
Output: returns 0 on success,  1 on error and sets error_message and error_code
=cut
# implemented using AUTOLOADER

=head2 log_info

Logs a informational message.  Log level LOG_INFO
Input: Message to be printed.
Output: returns 0 on success,  1 on error and sets error_message and error_code
=cut
# implemented using AUTOLOADER

=head2 log_debug

Logs a debug message.  Log level LOG_DEBUG
Input: Message to be printed.
Output: returns 0 on success,  1 on error and sets error_message and error_code
=cut
# implemented using AUTOLOADER

=head2 debug

Logs a debug message.  Log level LOG_DEBUG

This function is identical to log_debug
=cut
# implemented using AUTOLOADER

=head2 get_error_code

Get the error code
Input : the name of the function whose error code we should report
Output: the function's error code
        or NO_FUNCTION_SPECIFIED if the user did not supply a function
        or INVALID_FUNCTION_SPECIFIED if the user provided an invalid function
=cut
sub get_error_code {
    my $function = shift;

    # check we got a function name
    if (!defined($function)) {
        return NO_FUNCTION_SPECIFIED_CODE;
    }

    # check this is one of our exported function names
    if (!defined($error_code{$function}) ) {
        return INVALID_FUNCTION_SPECIFIED_CODE;
    }

    my $code = $error_code{$function};
    return $code;
}

=head2 get_error_message

Get the error message
Input : the name of the function whose error message we should report
Output: the function's error message
        or NO_FUNCTION_SPECIFIED if the user did not supply a function
        or INVALID_FUNCTION_SPECIFIED if the user provided an invalid function
=cut
sub get_error_message {
    my $function = shift;

    # check we got a function name
    if (!defined($function)) {
        return NO_FUNCTION_SPECIFIED_MSG;
    }

    # check this is one of our exported function names
    if (!defined($error_msg{$function}) ) {
        return INVALID_FUNCTION_SPECIFIED_MSG;
    }

    my $msg = $error_msg{$function};
    return $msg;
}

=head2 get_error_msg

Get the error message

This function is identical to get_error_message
=cut
sub get_error_msg {
    my $msg = shift;
    return get_error_message($msg);
}

###  ------------------   These functions are not exported -------------

# this function handles all log_* functions using AUTOLOAD
#Input (from AUTOLOADER): the function name that was called
#Input (from caller): Message to be printed.
#Output: returns 0 on success,  1 on error
#        and sets error_message and error_code for function_name
sub AUTOLOAD {
    our $AUTOLOAD;
    my  $msg = shift;

    # get the function name
    my $sub = $AUTOLOAD;
    (my $function_name = $sub) =~ s/.*:://;

    # check we got a function name
    if (!defined($function_name)) {
        # no function name so no error code/msg to set
        return 1;
    }

    # check that logging was initialized
    if ($log_initialized == 0) {
        $error_code{$function_name} = LOG_NOT_INITIALIZED_CODE;
        $error_msg{$function_name} = LOG_NOT_INITIALIZED_MSG;
        return 1;
    }

    # check that we have a message
    if (!defined($msg)) {
        $error_code{$function_name} = LOG_MISSING_MSG_CODE;
        $error_msg{$function_name} = LOG_MISSING_MSG_MSG;
        return 1;
    }

    # check the message is printable and has valid length
    if ($msg =~ /^[[:print:]]*$/) {
        if (length($msg) > MAX_STRING_LEN ) {
            $error_code{$function_name} = LOG_MSG_SIZE_CODE;
            $error_msg{$function_name} = LOG_MSG_SIZE_MSG;
            return 1;
        }
    } else {
        # prog_name contains non-printable characters
        $error_code{$function_name} = LOG_MSG_PRINTABLE_CODE;
        $error_msg{$function_name} = LOG_MSG_PRINTABLE_MSG;
        return 1;
    }

    # calculate the log_level and description from the function
    if ( (!defined($function_level{$function_name})) ||
         (!defined($function_description{$function_name})) ) {
        $error_code{$function_name} = LOG_UNKNOWN_FUNCTION_CODE;
        $error_msg{$function_name} = LOG_UNKNOWN_FUNCTION_MSG;
        return 1;
    }

    # check our log_level
    if ($function_level{$function_name} > $log_level){
        $error_code{$function_name} = NO_ERROR_CODE;
        $error_msg{$function_name} = NO_ERROR_MSG;
        return 0;
    }

    # if using syslog
    if ($use_syslog == 1) {
        syslog($function_level{$function_name}, $msg);
        $error_code{$function_name} = NO_ERROR_CODE;
        $error_msg{$function_name} = NO_ERROR_MSG;
        return 0;
    }

    # create a timestamp for this message
    my $header;
    if ($use_gmt) {
        $header = strftime ("%Y-%m-%d %H:%M:%S GMT", gmtime());
    } else {
        $header = strftime ("%Y-%m-%d %H:%M:%S %Z", localtime());
    }
    # add the hostname,  program name, and pid
    $header = $header." $hostname $prog_name\[$pid\]:";
    # add the function description
    $header = $header." $function_description{$function_name}";
    # combine the header and message
    $msg = $header." ".$msg."\n";
    # write the message to the file (note log_fh may be STDERR)
    my $bytes_written = syswrite($log_fh, $msg);
    if (!defined($bytes_written) || $bytes_written == 0
         || $bytes_written != length($msg) ) {
        $error_code{$function_name} = LOG_WRITE_FAILED_CODE;
        $error_msg{$function_name} = LOG_WRITE_FAILED_MSG;
        return 1;
    }

    # set the error code to success and return
    $error_code{$function_name} = NO_ERROR_CODE;
    $error_msg{$function_name} = NO_ERROR_MSG;
    return 0;
}

=head2 RETURN VALUES AND ERROR CODES

All functions return 0 on success and 1 on error.
In the event of an error,   an error code and error
message can be obtained using
  $code = get_error_code("function_name");
  $msg = get_error_msg("function_name");

The following error codes are defined:

 0 - No Error:
     'No Error'

 1 - No Function Specified in get_error_code/get_error_msg
    'Error reporting function called without specifying the function.'

 2 - Invalid Funtion in get_error_code/get_error_msg
    'Error reporting function called with invalid function name'

 3 - Failed To Obtain Hostname in log_init
    'Unable to get the hostname'

 4 - Program Name Exceeds Max Length in log_init
    'Program name exceeds maximum length of MAX_STRING_LEN'

 5 - Program Name Contains Non-Printable Characters in log_init
    'Program name contains non-printable characters'

 6 - Log Level Is Not A Number in log_init
    'Log level must be a postive integer'

 7 - Log Level Is Out of Range in log_init
    'Log level must be between LOG_EMERG and LOG_DEBUG'

 8 - Log Facility Is Not A Number in log_init
    'Log facility must be a postive integer'

 9 - Log File Name Exceeds Max Length in log_init
    'Log file exceeds maximum length of MAX_STRING_LEN'

 10 - Log File Name Contains Non-Printable Characters in log_init
    'Log file contains non-printable characters'

 11 - Use_syslog Is Not A Number in log_init
    'use_syslog must be 0 or 1'

 12 - Use_syslog Is Not 0 or 1 in log_init
    'use_syslog must be 0 or 1'

 13 - Use_gmt Is Not A Number in log_init
    'use_gmt must be 0 or 1'

 14 - Use_gmt Is Not 0 or 1 in log_init
    'use_gmt must be 0 or 1'

 15 - Use_gmt Set When Use_syslog = 1 in log_init
    'use_gmt not allowed when use_syslog = 1'

 16 - Specified Both Syslog and Log File in log_init
   'Unable to both use_syslog and write to file ';

 17 - Unable To Open Syslog in log_init
   'Unable To open syslog';

 18 - Unable To Open Log File in log_init
   'Unable to open log file';

 19 - Log Function Called Before Log Initialized
   'Logging not initialized.   Use init_log() prior to calling log_*("msg")';

 20 -No Such Log Function Exists
   'No such log function ';

 21 - No Message to Log
   'Log function called with no log message';

 22 - Log Message Exceeds Maximum Length
    'Log message exceeds maximum length of '.MAX_STRING_LEN;

 23 - Log Message Contains Non-Printable Characters
    'Message name contains non-printable characters'

 24 - Failed to Write Log Message
   'Unable to write log messsage ';

=head1 AUTHOR

Dan Massey, C<< <massey at cs.colostate.edu> >>

=head1 BUGS

Please report any bugs or feature requests to C<< <bgpmon@netsec.colostate.edu> >>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc BGPmon::Log
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

    File: Log.pm

    Authors: Kaustubh Gadkari, Dan Massey, Cathie Olschanowsky
    Date: May 21, 2012

    Updated documentation and error reporting:  Dan Massey
    Date: July 9, 2012
=cut
1;
