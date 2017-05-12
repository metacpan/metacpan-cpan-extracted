use AIX::LPP::lpp_name;

print "1..1\n";

open(LPP_NAME,">data/lpp_test.2") or die "Can't open file lpp_name: $!";

$package = AIX::LPP::lpp_name->new(NAME => 'test.lpp',TYPE => 'I',
		FORMAT => '4', PLATFORM => 'R');
$package->fileset('test.lpp.rte', VRMF => '01.01.0000.0000',DISK => '01',
		BOSBOOT => 'N',CONTENT => 'U', LANG => 'en_US',
		DESCRIPTION => 'test package description' );
# $package->requisites();
# $package->sizeinfo();

$package->write(\*LPP_NAME);

print "ok 1\n";
