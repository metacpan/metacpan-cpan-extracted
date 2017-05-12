use AIX::LPP::lpp_name;

print "1..1\n";

open(INLPP,"<data/lpp_name") or die "Can't open file lpp_name: $!";
open(OUTLPP,">data/lpp_test.3") or die "Can't open file lpp_name: $!";

$package = AIX::LPP::lpp_name->read(\*INLPP);
$package->write(\*OUTLPP);

print "ok 1\n";
