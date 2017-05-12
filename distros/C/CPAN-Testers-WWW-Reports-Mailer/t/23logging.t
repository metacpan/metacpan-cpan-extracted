#!/usr/bin/perl -w
use strict;

# -------------------------------------------------------------------
# Library Modules

use lib qw(t/lib);
use File::Path;
use File::Slurp;
use Test::More tests => 22;

use TestObject;

# -------------------------------------------------------------------
# Variables

my $LOGFILE = 't/_TMPDIR/logging.log';
my $CONFIG  = 't/_DBDIR/logging.ini';

# -------------------------------------------------------------------
# Tests

unlink($LOGFILE) if(-f $LOGFILE);

SKIP: {
    skip "No supported databases available", 7  unless(-f $CONFIG);

    ok( my $obj = TestObject->load(config => $CONFIG), "got object" );

    is($obj->logfile, $LOGFILE, 'logfile default set');
    is($obj->logclean, 0, 'logclean default set');

    $obj->_log("Hello\n");
    $obj->_log("Goodbye\n");

    ok( -f $LOGFILE, '50logging.log created in current dir' );

    my @log = read_file($LOGFILE);
    chomp @log;

    is(scalar(@log),2, 'log written');
    like($log[0], qr!\d{4}/\d\d/\d\d \d\d:\d\d:\d\d: Hello!,   'line 1 of log');
    like($log[1], qr!\d{4}/\d\d/\d\d \d\d:\d\d:\d\d: Goodbye!, 'line 2 of log');
}


SKIP: {
    skip "No supported databases available", 8  unless(-f $CONFIG);

    ok( my $obj = TestObject->load(config => $CONFIG), "got object" );

    is($obj->logfile, $LOGFILE, 'logfile default set');
    is($obj->logclean, 0, 'logclean default set');

    $obj->_log("Back Again\n");

    ok( -f $LOGFILE, '50logging.log created in current dir' );

    my @log = read_file($LOGFILE);
    chomp @log;

    is(scalar(@log),3, 'log extended');
    like($log[0], qr!\d{4}/\d\d/\d\d \d\d:\d\d:\d\d: Hello!,      'line 1 of log');
    like($log[1], qr!\d{4}/\d\d/\d\d \d\d:\d\d:\d\d: Goodbye!,    'line 2 of log');
    like($log[2], qr!\d{4}/\d\d/\d\d \d\d:\d\d:\d\d: Back Again!, 'line 3 of log');
}

SKIP: {
    skip "No supported databases available", 7  unless(-f $CONFIG);

    ok( my $obj = TestObject->load(config => $CONFIG), "got object" );

    is($obj->logfile, $LOGFILE, 'logfile default set');
    is($obj->logclean, 0, 'logclean default set');
    $obj->logclean(1);
    is($obj->logclean, 1, 'logclean reset');

    $obj->_log("Start Again\n");

    ok( -f $LOGFILE, '50logging.log created in current dir' );

    my @log = read_file($LOGFILE);
    chomp @log;

    is(scalar(@log),1, 'log overwritten');
    like($log[0], qr!\d{4}/\d\d/\d\d \d\d:\d\d:\d\d: Start Again!, 'line 1 of log');
}

unlink($LOGFILE);
