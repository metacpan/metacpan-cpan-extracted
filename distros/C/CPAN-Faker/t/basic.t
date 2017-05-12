use strict;
use warnings;

use Test::More tests => 2;

use CPAN::Faker;
use File::Temp ();

my $tmpdir = File::Temp::tempdir(CLEANUP => 1);
# my $tmpdir = '.';
# diag "output to $tmpdir";

my $cpan = CPAN::Faker->new({
  source => './eg',
  dest   => $tmpdir,
});

$cpan->make_cpan;

ok(
  -e File::Spec->catfile($tmpdir, 'modules', '02packages.details.txt.gz'),
  "we made a 02packages",
);

ok(
  -e File::Spec->catfile(
    $tmpdir, qw(authors id L LO LOCAL), 'Multi-Relevant-1.00.tar.gz'
  ),
  "there are files in LOCAL's dir, including the wonky old-but-dangling one",
);
