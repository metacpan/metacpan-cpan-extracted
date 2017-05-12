#!/usr/bin/perl -w
use strict;

use CPAN::Testers::Data::Addresses;
use File::Path;
use Test::More tests => 22;

my $config  = 't/_DBDIR/50logging.ini';
my $logfile = 't/_DBDIR/50logging.log';

SKIP: {
    skip "Unable to locate config file [$config]", 22   unless(-f $config);

    unlink($logfile) if(-f $logfile);

    {
        ok( my $obj = CPAN::Testers::Data::Addresses->new(config => $config), "got object" );

        is($obj->logfile, $logfile, 'logfile default set');
        is($obj->logclean, 0, 'logclean default set');

        $obj->_log("Hello");
        $obj->_log("Goodbye");

        ok( -f $logfile, '50logging.log created in current dir' );

        my @log = do { open FILE, '<', $logfile; <FILE> };
        chomp @log;

        is(scalar(@log),2, 'log written');
        like($log[0], qr!\d{4}/\d\d/\d\d \d\d:\d\d:\d\d Hello!,      'line 2 of log');
        like($log[1], qr!\d{4}/\d\d/\d\d \d\d:\d\d:\d\d Goodbye!,    'line 3 of log');
    }


    {
        ok( my $obj = CPAN::Testers::Data::Addresses->new(config => $config), "got object" );

        is($obj->logfile, $logfile, 'logfile default set');
        is($obj->logclean, 0, 'logclean default set');

        $obj->_log("Back Again");

        ok( -f $logfile, '50logging.log created in current dir' );

        my @log = do { open FILE, '<', $logfile; <FILE> };
        chomp @log;

        is(scalar(@log),3, 'log written');
        like($log[0], qr!\d{4}/\d\d/\d\d \d\d:\d\d:\d\d Hello!,      'line 2 of log');
        like($log[1], qr!\d{4}/\d\d/\d\d \d\d:\d\d:\d\d Goodbye!,    'line 3 of log');
        like($log[2], qr!\d{4}/\d\d/\d\d \d\d:\d\d:\d\d Back Again!, 'line 5 of log');
    }

    {
        ok( my $obj = CPAN::Testers::Data::Addresses->new(config => $config), "got object" );

        is($obj->logfile, $logfile, 'logfile default set');
        is($obj->logclean, 0, 'logclean default set');
        $obj->logclean(1);
        is($obj->logclean, 1, 'logclean reset');

        $obj->_log("Start Again");

        ok( -f $logfile, '50logging.log created in current dir' );

        my @log = do { open FILE, '<', $logfile; <FILE> };
        chomp @log;

        is(scalar(@log),1, 'log written');
        like($log[0], qr!\d{4}/\d\d/\d\d \d\d:\d\d:\d\d Start Again!, 'line 1 of log');
    }

    unlink($logfile) if(-f $logfile);
}
