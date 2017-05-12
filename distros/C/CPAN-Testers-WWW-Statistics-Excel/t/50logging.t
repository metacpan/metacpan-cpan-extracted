#!/usr/bin/perl -w
use strict;

use CPAN::Testers::WWW::Statistics::Excel;
use File::Path;
use File::Slurp;
use Test::More tests => 22;

my $LOG = '50logging.log';

unlink($LOG) if(-f $LOG);

{
    my $obj = CPAN::Testers::WWW::Statistics::Excel->new(
                logfile     => $LOG,
                logclean    => 0);

    ok( $obj, "got object" );

    is($obj->logfile, $LOG, 'logfile default set');
    is($obj->logclean, 0, 'logclean default set');

    $obj->_log("Hello");
    $obj->_log("Goodbye");

    ok( -f $LOG, '50logging.log created in current dir' );

    my @log = read_file($LOG);
    chomp @log;

    is(scalar(@log),4, 'log written');
    like($log[2], qr!\d{4}/\d\d/\d\d \d\d:\d\d:\d\d Hello!,   'line 1 of log');
    like($log[3], qr!\d{4}/\d\d/\d\d \d\d:\d\d:\d\d Goodbye!, 'line 2 of log');
}


{
    my $obj = CPAN::Testers::WWW::Statistics::Excel->new(
                logfile     => $LOG,
                logclean    => 0);

    ok( $obj, "got object" );

    is($obj->logfile, $LOG, 'logfile default set');
    is($obj->logclean, 0, 'logclean default set');

    $obj->_log("Back Again");

    ok( -f $LOG, '50logging.log created in current dir' );

    my @log = read_file($LOG);
    chomp @log;

    is(scalar(@log),7, 'log extended');
    like($log[2], qr!\d{4}/\d\d/\d\d \d\d:\d\d:\d\d Hello!,      'line 1 of log');
    like($log[3], qr!\d{4}/\d\d/\d\d \d\d:\d\d:\d\d Goodbye!,    'line 2 of log');
    like($log[6], qr!\d{4}/\d\d/\d\d \d\d:\d\d:\d\d Back Again!, 'line 3 of log');
}

{
    my $obj = CPAN::Testers::WWW::Statistics::Excel->new(
                logfile     => $LOG,
                logclean    => 0);

    ok( $obj, "got object" );

    is($obj->logfile, $LOG, 'logfile default set');
    is($obj->logclean, 0, 'logclean default set');
    $obj->logclean(1);
    is($obj->logclean, 1, 'logclean reset');

    $obj->_log("Start Again");

    ok( -f $LOG, '50logging.log created in current dir' );

    my @log = read_file($LOG);
    chomp @log;

    is(scalar(@log),1, 'log overwritten');
    like($log[0], qr!\d{4}/\d\d/\d\d \d\d:\d\d:\d\d Start Again!, 'line 1 of log');
}

unlink($LOG);    # remove 50logging.log (cannot test due to MSWin32)
