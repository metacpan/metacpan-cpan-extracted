#!perl
use warnings;
use strict;

use Activator::Log;
use Activator::Registry;
use IO::Capture::Stderr;
use Test::More tests => 14;

my $logfile = "/tmp/activator-log-test.log";
my $logfile2 = "/tmp/activator-log-test2.log";
my $config  =  {
		'log4perl.logger.Activator.Log' => 'WARN, LOGFILE',
		'log4perl.logger.Activator.Log2' => 'DEBUG, LOGFILE2',
		'log4perl.appender.LOGFILE' => 'Log::Log4perl::Appender::File',
		'log4perl.appender.LOGFILE.filename' => $logfile,
		'log4perl.appender.LOGFILE.mode' => 'append',
		'log4perl.appender.LOGFILE.layout' => 'PatternLayout',
		'log4perl.appender.LOGFILE.layout.ConversionPattern' => '%d{yyyy-mm-dd HH:mm:ss.SSS} [%p] %m (%M %L)%n,',
		'log4perl.appender.LOGFILE2' => 'Log::Log4perl::Appender::File',
		'log4perl.appender.LOGFILE2.filename' => $logfile2,
		'log4perl.appender.LOGFILE2.mode' => 'append',
		'log4perl.appender.LOGFILE2.layout' => 'PatternLayout',
		'log4perl.appender.LOGFILE2.layout.ConversionPattern' => '%d{yyyy-mm-dd HH:mm:ss.SSS} [%p] %m (%M %L)%n,',

	       };
Activator::Registry->register('log4perl', $config );

# tests for all functions
Activator::Log::level( 'TRACE' );
Activator::Log::TRACE('TRACE');
Activator::Log::DEBUG('DEBUG');
Activator::Log::INFO('INFO');
Activator::Log::WARN('WARN');
Activator::Log::ERROR('ERROR');
Activator::Log::FATAL('FATAL');

# change level to FATAL, then only the last line in this block should log
Activator::Log::level( 'FATAL' );
Activator::Log::TRACE('TRACE');
Activator::Log::DEBUG('DEBUG');
Activator::Log::INFO('INFO');
Activator::Log::WARN('WARN');
Activator::Log::ERROR('ERROR');
Activator::Log::FATAL('FATAL');

# log to alternate logger, then orig
Activator::Log::level( 'DEBUG' );
Activator::Log->DEBUG('DEBUG2', 'Activator.Log2');
Activator::Log::DEBUG('DEBUG');

# change default logger, log to it
Activator::Log->default_logger('Activator.Log2');
Activator::Log->DEBUG('DEBUG2');

my $line;
my $cmd_failed = !open LOG, "<$logfile";
ok( !$cmd_failed, "can open log file" );

$cmd_failed = !open LOG2, "<$logfile2";
ok( !$cmd_failed, "can open alternate log file" );

foreach my $msg ( qw/ TRACE DEBUG INFO WARN ERROR FATAL / ) {
    $line = <LOG>;
    ok ( $line =~ /\[$msg\] $msg \(main::/, "$msg logged" );
}

$line = <LOG>;
ok( $line =~ /\[FATAL\] FATAL \(main::/, "Changing log level works" );

$line = <LOG2>;
ok( $line =~ /\[DEBUG\] DEBUG2 \(main::/, "Alternate logger (one off) works" );

$line = <LOG>;
ok( $line =~ /\[DEBUG\] DEBUG \(main::/, "Logging to original logger (still) works" );

$line = <LOG2>;
ok( $line =~ /\[DEBUG\] DEBUG2 \(main::/, "Changing default logger works" );

close LOG;
close LOG2;

$cmd_failed = system ( "rm -f $logfile" );
ok( !$cmd_failed, "rm logfile $logfile" );

$cmd_failed = system ( "rm -f $logfile2" );
ok( !$cmd_failed, "rm logfile $logfile2" );
