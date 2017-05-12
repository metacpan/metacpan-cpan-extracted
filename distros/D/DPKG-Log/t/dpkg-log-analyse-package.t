use Test::More tests => 13;
use strict;
use warnings;
use lib 'lib';
use DPKG::Log::Analyse::Package;

can_ok('DPKG::Log::Analyse::Package', 'name');
can_ok('DPKG::Log::Analyse::Package', 'version');
can_ok('DPKG::Log::Analyse::Package', 'previous_version');
can_ok('DPKG::Log::Analyse::Package', 'status');

ok (my $package1 = DPKG::Log::Analyse::Package->new('package' => 'foobar'), 'Init DPKG::Log::Analyse::Package');
ok (my $package2 = DPKG::Log::Analyse::Package->new('package' => 'foobaz'), 'Init second package');
$package1->version('1.2.3');
$package2->version('1.2.3');
my $package3 = DPKG::Log::Analyse::Package->new(package => 'foobar');
$package3->version('1.2.4');

ok ($package1 == $package1, "package1 == package1");
ok ($package1 != $package2, "package1 != package2");
ok ($package1 ne $package2, "package1 ne package2");
ok ($package1 ne $package3, "package1 ne package3");
ok ($package1 != $package3, "package1 != package3");
ok ($package1 <= $package3, "package1 <= package3");
ok (sprintf("%s", $package1) eq sprintf("%s", $package1), "string version of package1 and package2 equal");
