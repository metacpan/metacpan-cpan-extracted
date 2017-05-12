#!/usr/bin/perl -w
use strict;

use Test::More tests => 22;
use File::Path;

use lib 't';
use CTDU_Testing;

my $LOG = '50logging.log';
my $CFG = 't/50logging.ini';

unlink($LOG) if(-f $LOG);

{
    ok( my $obj = CTDU_Testing::getObj(config => $CFG), "got object" );

    is($obj->logfile, $LOG, 'logfile default set');
    is($obj->logclean, 0, 'logclean default set');

    $obj->_log("Hello");
    $obj->_log("Goodbye");

    ok( -f $LOG, "$LOG created in current dir" );

    my @log = do { open FILE, '<', $LOG; <FILE> };
    chomp @log;

    is(scalar(@log),2, 'log written');
    like($log[0], qr!\d{4}/\d\d/\d\d \d\d:\d\d:\d\d Hello!,      'line 2 of log');
    like($log[1], qr!\d{4}/\d\d/\d\d \d\d:\d\d:\d\d Goodbye!,    'line 3 of log');
}


{
    ok( my $obj = CTDU_Testing::getObj(config => $CFG), "got object" );

    is($obj->logfile, $LOG, 'logfile default set');
    is($obj->logclean, 0, 'logclean default set');

    $obj->_log("Back Again");

    ok( -f $LOG, "$LOG created in current dir" );

    my @log = do { open FILE, '<', $LOG; <FILE> };
    chomp @log;

    is(scalar(@log),3, 'log written');
    like($log[0], qr!\d{4}/\d\d/\d\d \d\d:\d\d:\d\d Hello!,      'line 2 of log');
    like($log[1], qr!\d{4}/\d\d/\d\d \d\d:\d\d:\d\d Goodbye!,    'line 3 of log');
    like($log[2], qr!\d{4}/\d\d/\d\d \d\d:\d\d:\d\d Back Again!, 'line 5 of log');
}

{
    ok( my $obj = CTDU_Testing::getObj(config => $CFG), "got object" );

    is($obj->logfile, $LOG, 'logfile default set');
    is($obj->logclean, 0, 'logclean default set');
    $obj->logclean(1);
    is($obj->logclean, 1, 'logclean reset');

    $obj->_log("Start Again");

    ok( -f $LOG, "$LOG created in current dir" );

    my @log = do { open FILE, '<', $LOG; <FILE> };
    chomp @log;

    is(scalar(@log),1, 'log written');
    like($log[0], qr!\d{4}/\d\d/\d\d \d\d:\d\d:\d\d Start Again!, 'line 1 of log');
}

unlink($LOG);
