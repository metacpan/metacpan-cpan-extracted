#!perl -w
use strict;

$|=1;

# -------------------------------------------------------------------
# Library Modules

use lib qw(t/lib);
use File::Slurp;
use File::Path;
use File::Basename;
use Test::More;

use CPAN::Testers::WWW::Reports::Mailer;

use TestEnvironment;
use TestObject;

# -------------------------------------------------------------------
# Variables

my $TESTS = 47;

my %COUNTS = (
    REPORTS => 165,
    PASS    => 137,
    FAIL    => 17,
    UNKNOWN => 11,
    NA      => 0,
    NOMAIL  => 0,
    MAILS   => 1,
    NEWAUTH => 0,
    GOOD    => 0,
    BAD     => 0,
    TEST    => 1
);

my @DATA = (
    'auth|DCANTRELL|3|1248533160',
    'dist|DCANTRELL|-|0|1|FAIL,UNKNOWN|FIRST|LATEST|1|ALL|ALL',
    'dist|DCANTRELL|Acme-Licence|1|1|FAIL|FIRST|LATEST|0|ALL|ALL',
    'dist|DCANTRELL|Acme-Pony|1|1|FAIL|FIRST|LATEST|0|ALL|ALL',
    'dist|DCANTRELL|Acme-Scurvy-Whoreson-BilgeRat|1|1|FAIL|FIRST|LATEST|0|ALL|ALL',
    'dist|DCANTRELL|Bryar|1|1|FAIL|FIRST|LATEST|0|ALL|ALL',
    'dist|DCANTRELL|Pony|1|1|FAIL|FIRST|LATEST|0|ALL|ALL'
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
    is($pd,6,'distro records added');

    mkpath(dirname($files{lastmail}));
    overwrite_file($files{lastmail}, 'daily=4587509,weekly=4587509,reports=4587509' );
    run_mailer();

    $COUNTS{REPORTS} = 84;
    $COUNTS{PASS}    = 72;
    $COUNTS{FAIL}    = 10;
    $COUNTS{UNKNOWN} = 2;
    overwrite_file($files{lastmail}, 'daily=4722317,weekly=4722317,reports=4722317' );
    run_mailer();

    $COUNTS{MAILS}   = 1;
    $COUNTS{REPORTS} = 58;
    $COUNTS{PASS}    = 50;
    $COUNTS{TEST}    = 1;
    $COUNTS{FAIL}    = 7;
    $COUNTS{UNKNOWN} = 1;
    overwrite_file($files{lastmail}, 'daily=4766000,weekly=4766000,reports=4766000' );
    run_mailer();

    $COUNTS{MAILS}   = 1;
    $COUNTS{REPORTS} = 57;
    $COUNTS{FAIL}    = 6;
    overwrite_file($files{lastmail}, 'daily=4766100,weekly=4766100,reports=4766100' );
    run_mailer();

    my ($mail1,$mail2) = TestObject::mail_check($files{mailfile},'t/data/71daily.eml');
    is_deeply($mail1,$mail2,'mail files match');
}

sub run_mailer {
    my $mailer = TestObject->load(config => $CONFIG);
    if($mailer->nomail) {
        $mailer->check_reports();
        $mailer->check_counts();
    }

    is($mailer->{counts}{$_},$COUNTS{$_},"Matched count for $_") for(keys %COUNTS);
}
