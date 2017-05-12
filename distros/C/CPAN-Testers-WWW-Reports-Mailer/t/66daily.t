#!perl -w
use strict;

$|=1;

# -------------------------------------------------------------------
# Library Modules

use lib qw(t/lib);
use Test::More;

use CPAN::Testers::WWW::Reports::Mailer;

use TestEnvironment;
use TestObject;

# -------------------------------------------------------------------
# Variables

my $TESTS = 14;

my %COUNTS = (
    REPORTS => 1907,
    PASS    => 1565,
    FAIL    => 327,
    UNKNOWN => 11,
    NA      => 4,
    NOMAIL  => 0,
    MAILS   => 0,
    NEWAUTH => 0,
    GOOD    => 0,
    BAD     => 0,
    TEST    => 0
);

my @DATA = (
    'auth|BARBIE|3|NULL',
    'dist|BARBIE|-|0|3|NONE|FIRST|LATEST|1|ALL|ALL'
);

my %files = (
    'lastmail' => 't/_TMPDIR/test-lastmail.txt',
    'logfile'  => 't/_TMPDIR/test-daily.log',
    'mailfile' => 'mailer-debug.log'
);

my $CONFIG = 't/_DBDIR/preferences-daily.ini';

# -------------------------------------------------------------------
# Tests

for(keys %files) {
    unlink $files{$_}   if(-f $files{$_});
}

my $handles = TestEnvironment::Handles();
if(!$handles)   { plan skip_all => "Unable to create test environment"; }
else            { plan tests    => $TESTS }

SKIP: {
    skip "No supported databases available", $TESTS  unless($handles->{CPANPREFS});

    my ($pa,$pd) = TestEnvironment::ResetPrefs(\@DATA);
    is($pa,1,'author records added');
    is($pd,1,'distro records added');

    my $mailer = TestObject->load(config => $CONFIG);

    if($mailer->nomail) {
        $mailer->check_reports();
        $mailer->check_counts();
    }

    is($mailer->{counts}{$_},$COUNTS{$_},"Matched count for $_") for(keys %COUNTS);

    ok(-f $files{mailfile} ? 0 : 1,'no mail files sent');
}
