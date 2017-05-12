#!perl
use warnings;
use strict;

use Activator::Log;
use Activator::Registry;
use IO::Capture::Stderr;
use Test::More tests => 18;

Activator::Log::level( 'TRACE' );
my $capture = IO::Capture::Stderr->new();
my $line;
$capture->start();

# tests for all functions :: calls
Activator::Log::TRACE('TRACE');
Activator::Log::DEBUG('DEBUG');
Activator::Log::INFO('INFO');
Activator::Log::WARN('WARN');
Activator::Log::ERROR('ERROR');
Activator::Log::FATAL('FATAL');

# tests for all functions -> calls
Activator::Log->TRACE('TRACE');
Activator::Log->DEBUG('DEBUG');
Activator::Log->INFO('INFO');
Activator::Log->WARN('WARN');
Activator::Log->ERROR('ERROR');
Activator::Log->FATAL('FATAL');

# test that changing log level does the right thing
Activator::Log::level( 'FATAL' );
Activator::Log->TRACE('TRACE');
Activator::Log->DEBUG('DEBUG');
Activator::Log->INFO('INFO');
Activator::Log->WARN('WARN');
Activator::Log->ERROR('ERROR');
Activator::Log->FATAL('FATAL');

$capture->stop();

foreach my $msg ( qw/ TRACE DEBUG INFO WARN ERROR FATAL / ) {
    $line = $capture->read;
    ok ( $line =~ /\[$msg\] $msg \(main::/, "$msg works static( :: )" );
}

foreach my $msg ( qw/ TRACE DEBUG INFO WARN ERROR FATAL / ) {
    $line = $capture->read;
    ok ( $line =~ /\[$msg\] $msg \(main::/, "$msg works indirect( -> )" );
}

# test that empty messages are printed properly
$capture->start();
Activator::Log::level('TRACE');
Activator::Log->TRACE('');
Activator::Log->DEBUG('');
Activator::Log->INFO('');
Activator::Log->WARN();
Activator::Log->ERROR();
Activator::Log->FATAL();
$capture->stop();

foreach my $msg ( qw/ TRACE DEBUG INFO WARN ERROR FATAL / ) {
    $line = $capture->read;
    ok ( $line =~ /\[$msg\] <empty> \(main::/, "$msg works with null message" );
}

1;
