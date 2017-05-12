#!/usr/bin/perl -w
use strict;

# -------------------------------------------------------------------
# Library Modules

use lib qw(t/lib);
use File::Slurp;
use Test::More tests => 4;

use CPAN::Testers::WWW::Reports::Mailer;

use TestObject;

# -------------------------------------------------------------------
# Variables

my $CONFIG  = 't/_DBDIR/preferences.ini';
my $LOGFILE = 't/_TMPDIR/cpanreps.log';

# -------------------------------------------------------------------
# Tests

unlink $LOGFILE if(-f $LOGFILE);

SKIP: {
    skip "No supported databases available", 4  unless(-f $CONFIG);

    ok( my $obj = TestObject->load(), "got object" );

    ok(!-f $LOGFILE, 'log not found' );
    $obj->check_counts;
    ok( -f $LOGFILE, 'log created' );

    my ($counts,@log);
    my @lines = read_file($LOGFILE);
    for my $line (@lines) {
        next    unless($counts || $line =~ /INFO: COUNTS/);
        $counts = 1;
        $line =~ s/\s+$//;
        push @log, substr($line,21);
    }

    is_deeply(\@log, [
              'INFO: COUNTS for \'daily\' mode:',
              'INFO: REPORTS =      0',
              'INFO:    PASS =      0',
              'INFO:    FAIL =      0',
              'INFO: UNKNOWN =      0',
              'INFO:      NA =      0',
              'INFO:  NOMAIL =      0',
              'INFO:   MAILS =      0',
              'INFO: NEWAUTH =      0',
              'INFO:    GOOD =      0',
              'INFO:     BAD =      0',
              'INFO:    TEST =      0',
    ], "log written");
}
