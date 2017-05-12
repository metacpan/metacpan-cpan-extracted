#!perl
use warnings;
use strict;

use Activator::Log;
use Activator::Registry;
use Test::More tests => 9;

my $logfile = "/tmp/activator-log-test.log";
my $config  = "$ENV{PWD}/t/data/Log-log4perl.conf";
Activator::Registry->register('log4perl.conf', $config );

# tests for all functions
Activator::Log::level( 'TRACE' );
Activator::Log::TRACE('TRACE');
Activator::Log::DEBUG('DEBUG');
Activator::Log::INFO('INFO');
Activator::Log::WARN('WARN');
Activator::Log::ERROR('ERROR');
Activator::Log::FATAL('FATAL');

# test log levels
Activator::Log::level( 'FATAL' );
Activator::Log::TRACE('TRACE');
Activator::Log::DEBUG('DEBUG');
Activator::Log::INFO('INFO');
Activator::Log::WARN('WARN');
Activator::Log::ERROR('ERROR');
Activator::Log::FATAL('FATAL');

my $line;
my $cmd_failed = !open LOG, "<$logfile";
ok( !$cmd_failed, "can open log file" );

foreach my $msg ( qw/ TRACE DEBUG INFO WARN ERROR FATAL / ) {
    $line = <LOG>;
    ok ( $line =~ /\[$msg\] $msg \(main::/, "$msg logged" );
}

$line = <LOG>;
ok( $line =~ /\[FATAL\] FATAL \(main::/, "Changing log level works" );

$cmd_failed = system ( "rm -f $logfile" );
ok( !$cmd_failed, "rm logfile $logfile" );
