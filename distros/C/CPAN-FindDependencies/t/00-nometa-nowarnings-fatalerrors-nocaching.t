#!perl -w
use strict;

use Test::More;

use LWP::Simple;

unless(
    head("http://fastapi.metacpan.org/source/DCANTRELL/Number-Phone-1.0/MANIFEST") &&
    head("http://www.cpan.org/modules/02packages.details.txt.gz")
) {
    plan skip_all => "Need web access to the CPAN";
    exit;
}

plan tests => 5;

use_ok('CPAN::FindDependencies', 'finddeps');

my $caught = '';
$SIG{__WARN__} = sub {
    $caught = $_[0];
    die $caught
        if($caught !~ /^WARNING: CPAN::FindDependencies:.*no META.yml/);
};

my @results = finddeps('Acme::Licence');
ok(@results == 1 && $results[0]->name() eq 'Acme::Licence',
   "Modules with no META.yml appear in the list of results");

# Acme::License has a Makefile.PL
ok($caught eq "WARNING: CPAN::FindDependencies: DCANTRELL/Acme-Licence-1.0: no META.yml\n",
   "... and generate a warning");

$caught = '';
eval { finddeps('Acme::Licence', fatalerrors => 1) };
ok($@ eq "FATAL: CPAN::FindDependencies: DCANTRELL/Acme-Licence-1.0: no META.yml\n" &&
   $caught eq '',
   "fatalerrors really does make META.yml errors fatal");

$caught = '';
finddeps('Acme::Licence', nowarnings => 1);
ok($caught eq '', "nowarnings suppresses warnings");
