#!perl -w
use strict;

$|=1;

# -------------------------------------------------------------------
# Library Modules

use lib qw(t/lib);
use File::Basename;
use File::Path;
use File::Slurp;
use Test::More;

use CPAN::Testers::WWW::Reports::Mailer;

use TestEnvironment;
use TestObject;

# -------------------------------------------------------------------
# Variables

my $TESTS = 14;

my %COUNTS = (
    REPORTS => 2,
    PASS    => 0,
    FAIL    => 2,
    UNKNOWN => 0,
    NA      => 0,
    NOMAIL  => 0,
    MAILS   => 2,
    NEWAUTH => 0,
    GOOD    => 0,
    BAD     => 0,
    TEST    => 2
);

my @DATA = (
    'auth|BARBIE|3|NULL',
    'dist|BARBIE|-|0|3|FAIL|FIRST|LATEST|1|ALL|ALL'
);
my %files = (
    'lastmail' => 't/_TMPDIR/test-lastmail.txt',
    'logfile'  => 't/_TMPDIR/test-reports.log',
    'mailfile' => 'mailer-debug.log'
);

my $CONFIG = 't/_DBDIR/preferences-reports.ini';

# -------------------------------------------------------------------
# Tests

for(keys %files) {
    unlink $files{$_}   if(-f $files{$_});
}

mkpath(dirname($files{lastmail}));
overwrite_file($files{lastmail}, 'daily=4766100,weekly=4766100,reports=4766100' );

my $handles = TestEnvironment::Handles();
if(!$handles)   { plan skip_all => "Unable to create test environment"; }
else            { plan tests    => $TESTS }

SKIP: {
    skip "No supported databases available", $TESTS  unless($handles->{CPANPREFS});

    my ($pa,$pd) = TestEnvironment::ResetPrefs(\@DATA);
    is($pa,1,'author records added');
    is($pd,1,'distro records added');

    # remove some older entries to ensure we get some hits, but not all
    $handles->{CPANPREFS}->do_query('DELETE FROM cpanstats WHERE id < ? AND dist=? AND version=?',4766103,'WWW-Scraper-ISBN-Yahoo_Driver','0.08');
    $handles->{CPANPREFS}->do_query('DELETE FROM cpanstats WHERE id < ? AND dist=? AND version=?',4766801,'WWW-Scraper-ISBN-Amazon_Driver','0.14');

    my $mailer = TestObject->load(config => $CONFIG);
    #$mailer->verbose(1);

    if($mailer->nomail) {
        $mailer->check_reports();
        $mailer->check_counts();
    }

    is($mailer->{counts}{$_},$COUNTS{$_},"Matched count for $_") for(keys %COUNTS);

    my ($mail1,$mail2) = TestObject::mail_check($files{mailfile},'t/data/67reports.eml');
    is_deeply($mail1,$mail2,'mail files match');
}
