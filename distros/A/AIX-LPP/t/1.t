use AIX::LPP::lpp_name;

print "1..8\n";

$package = AIX::LPP::lpp_name->new(NAME => 'test.lpp',TYPE => 'I',
	PLATFORM => 'R',FORMAT => '4');
print "ok 1\n";
$package->fileset('test.lpp.rte',VRMF => '1.0.0.0',DISK => '01',BOSBOOT => 'N',
	CONTENT => 'I',LANG => 'en_US',DESCRIPTION => 'test.lpp description',
	COMMENTS => '');
print "ok 2\n";
$package->fileset('test.lpp.adt');
print "ok 3\n";
my @reqs = [ ['*prereq','bos.rte','4.3.3.0'] ];
$package->requisites('test.lpp.adt', \@reqs);
print "ok 4\n";
$package->sizeinfo('test.lpp.adt');
print "ok 5\n";
$package->lpp(FORMAT => 5) && print "ok 6\n";
$package->lpp() && print "ok 7\n";
$package->{FORMAT} && print "ok 8\n";
