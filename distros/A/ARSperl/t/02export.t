#!perl

use ARS;
require './t/config.cache';

print "1..9\n";

my($ctrl) = ars_Login(&CCACHE::SERVER, &CCACHE::USERNAME, &CCACHE::PASSWORD, "", "", &CCACHE::TCPPORT);
if(!defined($ctrl)) {
  print "not ok (login $ars_errstr)\n";
  exit 0;
}

my $d = "aptest.def";
if(ars_APIVersion() >= 4) {
  $d = "aptest50.def";
}

my $def = "";
my $c = 1;

my @objects =  (
		"schema", "ARSperl Test",
		"schema", "ARSperl Test2",
		"schema", "ARSperl Test-join",
		"filter", "ARSperl Test-Filter1",
		"active_link", "ARSperl Test-alink1",
		"escalation", "ARSperl Test-escalation1",
		"char_menu", "ARSperl Test-menu-search1",
		"container", "ARSperl Test-FilterGuide1",
	);

my $junk = ars_Export($ctrl, "", 0, "schema", "blarg292394");
if (defined($junk)) {
  print "not ok [$c]\n";
} else {
  print "ok [$c]\n";
}
$c++;

for (my $i = 0 ; $i < $#objects ; $i += 2) {
  my $d2 = ars_Export($ctrl, "", 0, $objects[$i], $objects[$i+1]);
  if (!defined($d2)) {
    print "not ok [$c] ($ars_errstr)\n";
  } else {
    if ($ars_errstr) { 
      print "ok [$c] ($ars_errstr)\n";
    } else {
      print "ok [$c]\n";
    }
  }
  $c++;
  $def .= $d2;
}

ars_Logoff($ctrl);

exit(0);
