use strict;
use warnings;

use Test::More;
use Test::Differences;
use Test::Time;

use CPAN::FindDependencies qw(finddeps);
use LWP::Simple;

unless(
    head("http://www.cpan.org/modules/02packages.details.txt.gz")
) {
    plan skip_all => "Need web access to the CPAN";
    exit;
}

my $caught = '';
$SIG{__WARN__} = sub {
    $caught = $_[0];
    die $caught
        if($caught !~ /^WARNING: CPAN::FindDependencies:.*no metadata/);
};

my @results = finddeps('Acme::Licence');
ok(@results == 1 && $results[0]->name() eq 'Acme::Licence',
   "Modules with no metadata appear in the list of results");
ok($caught eq "WARNING: CPAN::FindDependencies: DCANTRELL/Acme-Licence-1.0: no metadata\n",
   "... and generate a warning");
like($CPAN::FindDependencies::net_log[0],
    qr/^https?:.*02packages/,
    "Fetched 02packages from the network");

$caught = '';
eval { finddeps('Acme::Licence', fatalerrors => 1) };
ok($@ eq "FATAL: CPAN::FindDependencies: DCANTRELL/Acme-Licence-1.0: no metadata\n" &&
   $caught eq '',
   "fatalerrors really does make metadata errors fatal");

$caught = '';
finddeps('Acme::Licence', nowarnings => 1);
ok($caught eq '', "nowarnings suppresses warnings");
eq_or_diff(
    \@CPAN::FindDependencies::net_log,
    [
        # no 02packages here because that's memoized
        'https://cpan.metacpan.org/authors/id/D/DC/DCANTRELL/Acme-Licence-1.0.meta',
        'https://cpan.metacpan.org/authors/id/D/DC/DCANTRELL/Acme-Licence-1.0.tar.gz'
    ],
    "network traffic was as expected when there's no meta-file available (and 02packages was memoized)"
);

note("pretending to pause for a bit for cache expiry tests");
sleep 360;
@results = finddeps('CPAN::FindDependencies', maxdepth => 0);
ok($CPAN::FindDependencies::net_log[0] =~ /02packages/,
    "when the index expires out of the cache it is re-fetched");
ok(@results == 1 && $results[0]->name() eq 'CPAN::FindDependencies',
    "we return plausible looking data");
ok($CPAN::FindDependencies::net_log[1] =~ /CPAN-FindDependencies-[\d.]+\.meta$/,
    "when there is a meta-file available we fetch it ...");
ok(!exists($CPAN::FindDependencies::net_log[2]),
    "...and don't fetch the archive file");

@results = finddeps('CPAN::FindDependencies', maxdepth => 0);
ok($CPAN::FindDependencies::net_log[0] =~ /CPAN-FindDependencies-[\d.]+\.meta/,
    "now we re-use the second cached index");
ok(@results == 1 && $results[0]->name() eq 'CPAN::FindDependencies',
    "we return plausible looking data");

done_testing();
