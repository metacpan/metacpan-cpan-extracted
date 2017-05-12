use strict;
no strict "refs";
use warnings;
#use Test::More tests => 99;
#use Test::More tests => 97;
#use Test::More skip_all => "Only for development purposes";
use Test::More;

# check the dependencies
BEGIN {
    use_ok( 'Carp' );
    use_ok( 'Sys::Syslog' );
    use_ok( 'POSIX' );
    use_ok( 'Sys::Hostname' ); 
    use_ok( 'BGPmon::Log' ); 
}
use POSIX;
use Sys::Hostname; 
use BGPmon::Log;

#---------------------   First Check For Correct Operation ---------------------
# temporary file to use for testing
my $log_file = "/tmp/BGPmon_Log_log_testing";
my $ret = unlink($log_file);
ok($ret == 1 || $ret == 0, "Removing any old copies of $log_file");


# try initializing the log for writing to $log_file
my %init_params = ( prog_name => "BGPmon::Log - Testing",
                    log_level => BGPmon::Log::LOG_DEBUG,
                    log_facility => BGPmon::Log::LOG_LOCAL0,
                    log_file => $log_file, 
                    use_syslog => 0,
                    use_gmt => 1 );
$ret = BGPmon::Log::log_init(%init_params);
my $ecode = BGPmon::Log::get_error_code("log_init");
my $emsg = BGPmon::Log::get_error_msg("log_init");
ok($ret == 0, 
  "Initializing log with log file: $log_file, result is $ecode: $emsg"); 

# error codes and messages should work
$ret = BGPmon::Log::get_error_code("log_init");
ok($ret == 0, 
  "Checking get_error_code, result is $ret");
$ret = BGPmon::Log::get_error_msg("log_init");
ok($ret eq BGPmon::Log::NO_ERROR_MSG, 
  "Checking get_error_msg, result is $ret");
$ret = BGPmon::Log::get_error_message("log_init");
ok($ret eq BGPmon::Log::NO_ERROR_MSG, 
  "Checking get_error_messag, result is $ret");

# see if we can open the result log file 
my $log_fh;
$ret = open($log_fh, $log_file);
ok($ret != 0, "Opening log file: $log_file");

# see if we can write a LOG_NOTICE message
my $log_msg = "Testing BGPmon::Log with a LOG_NOTICE message";
$ret = BGPmon::Log::log_notice($log_msg);
$ecode = BGPmon::Log::get_error_code("log_notice");
$emsg = BGPmon::Log::get_error_msg("log_notice");
my $line = <$log_fh>;
ok($ret == 0 && defined($line), 
  "Writing LOG_NOTICE message to $log_file, result is $ecode: $emsg"); 

# see if starts with the correct time,  excluding minutes and seconds
my $timeval = strftime ("%Y-%m-%d %H:", gmtime()); 
ok($line =~ /^$timeval/, "Checking the test message has a valid time stamp");

# see if includes the hostname
my $hostname = Sys::Hostname::hostname;
ok($line =~ /$hostname/, "Checking the test message includes the hostname");

# test it includes the prog_name
ok($line =~ /$init_params{"prog_name"}/, "Checking prog_name parameter");

# check it really is a log_notice message
my $descr = $BGPmon::Log::function_description{"log_notice"};
my $index = index($line, $descr);
ok($index >= 0, "Checking message level is LOG_NOTICE");

# check it really includes our message a log_notice message
ok($line =~ /$log_msg/, "Checking the test message was included in the log");

# line looks valid,  now lets try all the log level functions
my @function_names = ("log_emerg", "log_emergency", "log_alert",
                      "log_fatal", "log_crit", "log_critical", "log_err",  
                      "log_error", "log_warn", "log_warning", "log_notice", 
                      "log_info", "log_debug", "debug" ); 
my $fn;
for my $function (@function_names) {
    # call the function
    $fn = "BGPmon::Log::".$function;
    $ret = &$fn($log_msg);
    $ecode = BGPmon::Log::get_error_code($function);
    $emsg = BGPmon::Log::get_error_msg($function);
    # get the resulting line and check its valid
    $line = <$log_fh>;
    ok($ret == 0 && defined($line), 
      "Writing a $function message to file, result is $ecode: $emsg"); 
}

# check closing the file
$ret = BGPmon::Log::log_close();
$ecode = BGPmon::Log::get_error_code("log_close");
$emsg = BGPmon::Log::get_error_msg("log_close");
ok($ret == 0, 
  "Closing the log with log file $log_file, result is $ecode: $emsg"); 

# change the log_level to LOG_WARN and verify log_level works
$init_params{"log_level"} = BGPmon::Log::LOG_WARNING;
$ret = BGPmon::Log::log_init(%init_params);
$ecode = BGPmon::Log::get_error_code("log_init");
$emsg = BGPmon::Log::get_error_msg("log_init");
ok($ret == 0, 
"Re-opening with log level changed to LOG_WARNING, result is $ecode: $emsg"); 
for my $function (@function_names) {
    # call the function
    $fn = "BGPmon::Log::".$function;
    $ret = &$fn($log_msg);
    $ecode = BGPmon::Log::get_error_code($function);
    $emsg = BGPmon::Log::get_error_msg($function);
    # get the resulting line and check its valid
    $line = <$log_fh>;
    if ($BGPmon::Log::function_level{$function} <= $init_params{"log_level"}) {
        ok($ret == 0 && defined($line), 
          "Veriyfing $function still works, result is $ecode: $emsg"); 
    } else {
        ok($ret == 0 && !defined($line), "Verifying $function is skipped"); 
    }
}
$ret = BGPmon::Log::log_close();
$ecode = BGPmon::Log::get_error_code("log_close");
$emsg = BGPmon::Log::get_error_msg("log_close");
ok($ret == 0, 
  "Closing the log file, result is $ecode: $emsg"); 

# test setting use_gmt to 0
$init_params{"use_gmt"} = 0;
$init_params{"log_level"} = BGPmon::Log::LOG_NOTICE;
$ret = BGPmon::Log::log_init(%init_params);
$ecode = BGPmon::Log::get_error_code("log_init");
$emsg = BGPmon::Log::get_error_msg("log_init");
ok($ret == 0, 
"Re-opening with use_gmt=0 and level LOG_NOTICE, result is $ecode: $emsg"); 
$ret = BGPmon::Log::log_notice($log_msg);
$ecode = BGPmon::Log::get_error_code("log_notice");
$emsg = BGPmon::Log::get_error_msg("log_notice");
$line = <$log_fh>;
ok($ret == 0 && defined($line), 
"Writing LOG_NOTICE message to $log_file, result is $ecode: $emsg"); 
$timeval = strftime ("%Y-%m-%d %H:", localtime()); 
ok($line =~ /^$timeval/, "Checking the message has a use_gmt=0 time stamp");

# close the log file and clean-up
$ret = BGPmon::Log::log_close();
$ecode = BGPmon::Log::get_error_code("log_close");
$emsg = BGPmon::Log::get_error_msg("log_close");
ok($ret == 0, 
  "Closing the log file, result is $ecode: $emsg"); 
close($log_fh);
$ret = unlink($log_file);
ok($ret == 1, "Removing test log_file $log_file");

# TODO: redirect stdout first
# try writing a messsage to stdout
#$init_params{"use_gmt"} = 0;
#delete $init_params{"log_file"}; 
#$ret = BGPmon::Log::log_init(%init_params);
#$ecode = BGPmon::Log::get_error_code("log_init");
#$emsg = BGPmon::Log::get_error_msg("log_init");
#ok($ret == 0, 
#"Initializing log with STDOUT, result is $ecode: $emsg"); 
#$ret = BGPmon::Log::log_notice($log_msg);
#$ecode = BGPmon::Log::get_error_code("log_notice");
#$emsg = BGPmon::Log::get_error_msg("log_notice");
#ok($ret == 0, 
#"Writing LOG_NOTICE message to STDOUT, result is $ecode: $emsg"); 
#$ret = BGPmon::Log::log_close();
#$ecode = BGPmon::Log::get_error_code("log_close");
#$emsg = BGPmon::Log::get_error_msg("log_close");
#ok($ret == 0, 
  #"Closing the log file, result is $ecode: $emsg"); 

# try writing a message to syslog
$init_params{"use_syslog"} = 1;
delete $init_params{"use_gmt"}; 
$ret = BGPmon::Log::log_init(%init_params);
$ecode = BGPmon::Log::get_error_code("log_init");
$emsg = BGPmon::Log::get_error_msg("log_init");
#ok($ret == 0, 
#"Initializing log using syslog, result is $ecode: $emsg"); 
$ret = BGPmon::Log::log_notice($log_msg);
$ecode = BGPmon::Log::get_error_code("log_notice");
$emsg = BGPmon::Log::get_error_msg("log_notice");
#ok($ret == 0, 
#"Writing LOG_NOTICE message to syslog, result is $ecode: $emsg"); 
$ret = BGPmon::Log::log_close();
$ecode = BGPmon::Log::get_error_code("log_close");
$emsg = BGPmon::Log::get_error_msg("log_close");
ok($ret == 0, 
  "Closing the log file, result is $ecode: $emsg"); 

# we never reallly tested the log_facility...

# try the default with no parameters
$ret = BGPmon::Log::log_init();
$ecode = BGPmon::Log::get_error_code("log_init");
$emsg = BGPmon::Log::get_error_msg("log_init");
ok($ret == 0, 
"Initializing log using default values, result is $ecode: $emsg"); 
$ret = BGPmon::Log::log_notice($log_msg);
$ecode = BGPmon::Log::get_error_code("log_notice");
$emsg = BGPmon::Log::get_error_msg("log_notice");
ok($ret == 0, 
"Writing LOG_NOTICE message to default location, result is $ecode: $emsg"); 
$ret = BGPmon::Log::log_close();
$ecode = BGPmon::Log::get_error_code("log_close");
$emsg = BGPmon::Log::get_error_msg("log_close");
ok($ret == 0, 
  "Closing the log file, result is $ecode: $emsg"); 

#---------------------   Now Check For Various Error Cases ---------------------
# reset my params for error checking
%init_params = ( prog_name => "BGPmon::Log - Testing",
                    log_level => BGPmon::Log::LOG_DEBUG,
                    log_facility => BGPmon::Log::LOG_LOCAL0,
                    log_file => $log_file, 
                    use_syslog => 0,
                    use_gmt => 1 );

# try the with only garbage parameters
$ret = BGPmon::Log::log_init(garbage => "garbage value");
$ecode = BGPmon::Log::get_error_code("log_init");
$emsg = BGPmon::Log::get_error_msg("log_init");
ok($ret == 0, 
"Initializing log using garbage values, result is $ecode: $emsg"); 
$ret = BGPmon::Log::log_notice($log_msg);
$ecode = BGPmon::Log::get_error_code("log_notice");
$emsg = BGPmon::Log::get_error_msg("log_notice");
ok($ret == 0, 
"Writing LOG_NOTICE message to default location, result is $ecode: $emsg"); 
$ret = BGPmon::Log::log_close();
$ecode = BGPmon::Log::get_error_code("log_close");
$emsg = BGPmon::Log::get_error_msg("log_close");
ok($ret == 0, 
  "Closing the log file, result is $ecode: $emsg"); 

# try with good and garbage parameters
$init_params{"use_syslog"} = 0;
$init_params{"garbage"} = "garbage_value";
$ret = BGPmon::Log::log_init(%init_params);
$ecode = BGPmon::Log::get_error_code("log_init");
$emsg = BGPmon::Log::get_error_msg("log_init");
ok($ret == 0, 
"Initializing log using valid and garbage values, result is $ecode: $emsg"); 
$ret = BGPmon::Log::log_notice($log_msg);
$ecode = BGPmon::Log::get_error_code("log_notice");
$emsg = BGPmon::Log::get_error_msg("log_notice");
ok($ret == 0, 
"Writing LOG_NOTICE message to STDOUT, result is $ecode: $emsg"); 
$ret = BGPmon::Log::log_close();
$ecode = BGPmon::Log::get_error_code("log_close");
$emsg = BGPmon::Log::get_error_msg("log_close");
ok($ret == 0, 
  "Closing the log file, result is $ecode: $emsg"); 
delete($init_params{"garbage"});

# try checking error codes on non-existent functions 
$ret = BGPmon::Log::get_error_code();
ok($ret == BGPmon::Log::NO_FUNCTION_SPECIFIED_CODE, 
   "Calling get_error_code with no function name, result is $ret");
$ret = BGPmon::Log::get_error_msg();
ok($ret eq BGPmon::Log::NO_FUNCTION_SPECIFIED_MSG, 
   "Calling get_error_msg with no function name, result is $ret");
$ret = BGPmon::Log::get_error_message();
ok($ret eq BGPmon::Log::NO_FUNCTION_SPECIFIED_MSG, 
   "Calling get_error_msg with no function name, result is $ret");

# try checking error codes on invalid functions 
my $invalid_name = "foo";
$ret = BGPmon::Log::get_error_code($invalid_name);
ok($ret == BGPmon::Log::INVALID_FUNCTION_SPECIFIED_CODE, 
   "Calling get_error_code with invalid function name, result is $ret");
$ret = BGPmon::Log::get_error_msg($invalid_name);
ok($ret eq BGPmon::Log::INVALID_FUNCTION_SPECIFIED_MSG, 
   "Calling get_error_msg with invalid function name, result is $ret");
$ret = BGPmon::Log::get_error_message($invalid_name);
ok($ret eq BGPmon::Log::INVALID_FUNCTION_SPECIFIED_MSG, 
   "Calling get_error_msg with invalid function name, result is $ret");

# not sure how we would test the failure of a hostname
# BGPmon::Log::LOG_INIT_NO_HOSTNAME_CODE

# subroutine for checking a log_init error condition
sub test_init_failure {
   my ($test_msg, $err_code,  $err_msg) = @_;
   my $ret = BGPmon::Log::log_init(%init_params);
   my $ret_code = BGPmon::Log::get_error_code("log_init");
   my $ret_msg = BGPmon::Log::get_error_msg("log_init");
   ok(($ret == 1) && ($ret_code eq $err_code) && ($ret_msg eq $err_msg), 
       $test_msg.", result is $ret_code: $ret_msg");
}

# try a very long program name
my $count;
my $prog_name = "a";
for ($count = 0; $count < BGPmon::Log::MAX_STRING_LEN; $count++) {
    $prog_name .= "a";
}
$init_params{"prog_name"} = $prog_name;
test_init_failure("Testing a long prog_name parameter",
                  BGPmon::Log::LOG_INIT_PROG_SIZE_CODE, 
                  BGPmon::Log::LOG_INIT_PROG_SIZE_MSG );


# try a program name with non-printable characters
$prog_name = "\x74\x65\x73\x74\x07";
$init_params{"prog_name"} = $prog_name;
test_init_failure("Testing a prog_name parameter with non-printable chars",
                  BGPmon::Log::LOG_INIT_PROG_PRINTABLE_CODE, 
                  BGPmon::Log::LOG_INIT_PROG_PRINTABLE_MSG );
delete($init_params{prog_name});

# try a log_level that is not a number 
$init_params{"log_level"} = "foo";
test_init_failure("Testing a log_level that is not a number",
                  BGPmon::Log::LOG_INIT_LEVEL_NOT_NUM_CODE, 
                  BGPmon::Log::LOG_INIT_LEVEL_NOT_NUM_MSG );
# try a log_level that is too big 
$init_params{"log_level"} = 100;
test_init_failure( "Testing a log_level that is too big",
                  BGPmon::Log::LOG_INIT_LEVEL_RANGE_CODE, 
                  BGPmon::Log::LOG_INIT_LEVEL_RANGE_MSG );
# try a log_level that is too small
$init_params{"log_level"} = -1;
test_init_failure("Testing a log_level that is too small",
                  BGPmon::Log::LOG_INIT_LEVEL_NOT_NUM_CODE, 
                  BGPmon::Log::LOG_INIT_LEVEL_NOT_NUM_MSG );
delete($init_params{log_level});

# try a log_facility that is not a number 
$init_params{"log_facility"} = "foo";
test_init_failure( "Testing a log_facility that is not a number",
                  BGPmon::Log::LOG_INIT_FACILITY_NOT_NUM_CODE, 
                  BGPmon::Log::LOG_INIT_FACILITY_NOT_NUM_MSG );

# try a log_facility that is not a postivie number 
$init_params{"log_facility"} = -1;
test_init_failure( "Testing a log_facility that is not a postive number",
                  BGPmon::Log::LOG_INIT_FACILITY_NOT_NUM_CODE, 
                  BGPmon::Log::LOG_INIT_FACILITY_NOT_NUM_MSG );
delete($init_params{log_facility});

# try a very long log file name
my $bad_log_file = "b";
for ($count = 0; $count < BGPmon::Log::MAX_STRING_LEN; $count++) {
    $bad_log_file .= "b";
}
$init_params{log_file} = $bad_log_file;
test_init_failure("Testing a long log_file parameter",
                  BGPmon::Log::LOG_INIT_FILE_SIZE_CODE, 
                  BGPmon::Log::LOG_INIT_FILE_SIZE_MSG );


# try a log file name with non-printable characters
$bad_log_file = "\x74\x65\x73\x74\x07";
$init_params{"log_file"} = $bad_log_file;
test_init_failure("Testing a log_file parameter with non-printable chars",
                  BGPmon::Log::LOG_INIT_FILE_PRINTABLE_CODE, 
                  BGPmon::Log::LOG_INIT_FILE_PRINTABLE_MSG );
delete($init_params{log_file});

# try a use_syslog that is not a number 
$init_params{"use_syslog"} = "foo";
test_init_failure("Testing a use_syslog that is not a number",
                  BGPmon::Log::LOG_INIT_SYSLOG_NOT_NUM_CODE, 
                  BGPmon::Log::LOG_INIT_SYSLOG_NOT_NUM_MSG );

# try a use_syslog that is not 0 or 1
$init_params{"use_syslog"} = 3;
test_init_failure("Testing a use_syslog that is not 0 or 1",
                  BGPmon::Log::LOG_INIT_SYSLOG_RANGE_CODE, 
                  BGPmon::Log::LOG_INIT_SYSLOG_RANGE_MSG );
delete($init_params{use_syslog});

# try a use_gmt that is not a number 
$init_params{"use_gmt"} = "foo";
test_init_failure("Testing a use_gmt that is not a number",
                  BGPmon::Log::LOG_INIT_GMT_NOT_NUM_CODE, 
                  BGPmon::Log::LOG_INIT_GMT_NOT_NUM_MSG );

# try a use_gmt that is not 0 or 1
$init_params{"use_gmt"} = 3;
test_init_failure("Testing a use_gmt that is not 0 or 1",
                  BGPmon::Log::LOG_INIT_GMT_RANGE_CODE, 
                  BGPmon::Log::LOG_INIT_GMT_RANGE_MSG );
delete($init_params{use_gmt});

# try a use_gmt when use_syslog is set
$init_params{"use_syslog"} = 1;
$init_params{"use_gmt"} = 0;
test_init_failure("Testing a use_gmt and use_syslog together",
                  BGPmon::Log::LOG_INIT_GMT_SYSLOG_CODE, 
                  BGPmon::Log::LOG_INIT_GMT_SYSLOG_MSG );
delete($init_params{use_gmt});

# try use_syslog and a file name 
$init_params{"log_file"} = $log_file;
test_init_failure("Testing setting both use_syslog and write to a file ",
                  BGPmon::Log::LOG_INIT_SYSLOG_AND_FILE_CODE, 
                  BGPmon::Log::LOG_INIT_SYSLOG_AND_FILE_MSG );
delete($init_params{use_syslog});
# not sure how we would test a syslog failure
# BGPmon::Log:: LOG_INIT_SYSLOG_OPEN_CODE 

# try a failure opening a file - directory doesn't exit
$init_params{"log_file"} = "/this/directory/cannot/exist/foo.txt";
test_init_failure("Testing unable to open log file ",
                  BGPmon::Log::LOG_INIT_FILE_OPEN_CODE, 
                  BGPmon::Log::LOG_INIT_FILE_OPEN_MSG );

# try a failure opening a file - bad permissions
my $retu = unlink ($log_file);
my $reto = open($log_fh, "> $log_file");
close($log_fh);
chmod(0000, $log_file);
ok($reto != 0, "Making unreadable log file : $log_file");
$init_params{"log_file"} = $log_file;
test_init_failure("Testing bad log file permissions",
                  BGPmon::Log::LOG_INIT_FILE_OPEN_CODE, 
                  BGPmon::Log::LOG_INIT_FILE_OPEN_MSG );
$retu = unlink ($log_file);

# test no init function
$ret = BGPmon::Log::log_close();
$ret = BGPmon::Log::log_notice($log_msg);
my $ret_code = BGPmon::Log::get_error_code("log_notice");
my $ret_msg = BGPmon::Log::get_error_msg("log_notice");
ok(($ret == 1) && 
   ($ret_code eq BGPmon::Log::LOG_NOT_INITIALIZED_CODE ) && 
   ($ret_msg eq BGPmon::Log::LOG_NOT_INITIALIZED_MSG), 
   "Trying to write before log is initialized, result is $ret_code: $ret_msg");

# open the log one last time for write error checking 
# reset my params for error checking
%init_params = ( prog_name => "BGPmon::Log - Testing",
                    log_level => BGPmon::Log::LOG_NOTICE,
                    log_facility => BGPmon::Log::LOG_LOCAL0,
                    log_file => $log_file, 
                    use_syslog => 0,
                    use_gmt => 1 );
$ret = BGPmon::Log::log_init(%init_params);
$ecode = BGPmon::Log::get_error_code("log_init");
$emsg = BGPmon::Log::get_error_msg("log_init");
ok($ret == 0, 
"Initializing log $log_file for error checks, result is $ecode: $emsg"); 

# test invalid function name
# call log_foo
# use constant LOG_UNKNOWN_FUNCTION_CODE => 17;
$ret = BGPmon::Log::log_garbage($log_msg);
$ret_code = BGPmon::Log::get_error_code("log_garbage");
$ret_msg = BGPmon::Log::get_error_msg("log_garbage");
ok(($ret == 1) && 
   ($ret_code eq BGPmon::Log::LOG_UNKNOWN_FUNCTION_CODE ) && 
   ($ret_msg eq BGPmon::Log::LOG_UNKNOWN_FUNCTION_MSG), 
   "Trying to write using invalid log function, result is $ret_code: $ret_msg");

# test failure to specify a log message
$ret = BGPmon::Log::log_notice();
$ret_code = BGPmon::Log::get_error_code("log_notice");
$ret_msg = BGPmon::Log::get_error_msg("log_notice");
ok(($ret == 1) && 
   ($ret_code eq BGPmon::Log::LOG_MISSING_MSG_CODE ) && 
   ($ret_msg eq BGPmon::Log::LOG_MISSING_MSG_MSG), 
   "Trying to write without providing a message, result is $ret_code: $ret_msg");

# test a very long message
my $bad_log_msg = "c";
for ($count = 0; $count < BGPmon::Log::MAX_STRING_LEN; $count++) {
    $bad_log_msg .= "c";
}
$ret = BGPmon::Log::log_notice($bad_log_msg);
$ret_code = BGPmon::Log::get_error_code("log_notice");
$ret_msg = BGPmon::Log::get_error_msg("log_notice");
ok(($ret == 1) && 
   ($ret_code eq BGPmon::Log::LOG_MSG_SIZE_CODE ) && 
   ($ret_msg eq BGPmon::Log::LOG_MSG_SIZE_MSG), 
   "Testing a long log message, result is $ret_code: $ret_msg");

# test a non_printable message
$bad_log_msg = "\x74\x65\x73\x74\x07";
$ret = BGPmon::Log::log_notice($bad_log_msg);
$ret_code = BGPmon::Log::get_error_code("log_notice");
$ret_msg = BGPmon::Log::get_error_msg("log_notice");
ok(($ret == 1) && 
   ($ret_code eq BGPmon::Log::LOG_MSG_PRINTABLE_CODE ) && 
   ($ret_msg eq BGPmon::Log::LOG_MSG_PRINTABLE_MSG), 
   "Testing a non-printable log message, result is $ret_code: $ret_msg");

# test write fails for log_file
# tried removing and unlinking the file,  but 
# both yield no errors
# remove the file we are logging to
#$ret = unlink($log_file);
#chmod(0000, $log_file);
#ok($ret == 1, "Removing test log_file $log_file");
#$ret = BGPmon::Log::log_notice("help");
#$ret_code = BGPmon::Log::get_error_code("log_notice");
#$ret_msg = BGPmon::Log::get_error_msg("log_notice");
#ok(($ret == 1) && 
#   ($ret_code eq BGPmon::Log::LOG_WRITE_FAILED_CODE ) && 
#   ($ret_msg eq BGPmon::Log::LOG_WRITE_FAILED_MSG), 
#   "Testing log message to deleted file");
#

# close the log file and clean-up
close($log_fh);
$ret = BGPmon::Log::log_close();
$ecode = BGPmon::Log::get_error_code("log_init");
$emsg = BGPmon::Log::get_error_msg("log_init");
$retu = unlink($log_file);
ok($ret == 0 && $retu == 1, 
"Closing and removing the log file $log_file"); 

# not sure how we would test a syslog write failure
# BGPmon::Log::LOG_WRITE_FAILED_CODE 

# not sure how we would test a stdout write failure
# BGPmon::Log::LOG_WRITE_FAILED_CODE 

done_testing();
1;
