#!./perl

# 
# test out importing a schema definition
#

use ARS;
require './t/config.cache';

print "1..1\n";

my($ctrl) = ars_Login(&CCACHE::SERVER, &CCACHE::USERNAME, &CCACHE::PASSWORD, "", "", &CCACHE::TCPPORT);
if(!defined($ctrl)) {
  print "not ok (login $ars_errstr)\n";
  exit 0;
}

my $d = "aptest.def";

# if we're compiled against 4.0, we'll import a schema
# with an attachment field so we can test that out.

if(ars_APIVersion() >= 6) {
  $d = "aptest51.def";
}elsif(ars_APIVersion() >= 4) {
  $d = "aptest50.def";
}


#  delete the schema (assuming it already exists). if it doesnt,
#  we ignore the error.

ars_DeleteSchema($ctrl, "ARSperl Test", ARS::AR_SCHEMA_FORCE_DELETE); 
ars_DeleteSchema($ctrl, "ARSperl Test2", ARS::AR_SCHEMA_FORCE_DELETE); 
ars_DeleteSchema($ctrl, "ARSperl Test-join", ARS::AR_SCHEMA_FORCE_DELETE); 
ars_DeleteSchema($ctrl, "ARSperl Test3", ARS::AR_SCHEMA_FORCE_DELETE); 
ars_DeleteFilter($ctrl, "ARSperl Test-Filter1"); 
ars_DeleteActiveLink($ctrl, "ARSperl Test-alink1");
ars_DeleteEscalation($ctrl, "ARSperl Test-escalation1");
ars_DeleteCharMenu($ctrl, "ARSperl Test-menu-search1");
ars_DeleteContainer($ctrl,"ARSperl Test-FilterGuide1");

# read in the schema definition

my $buf = "";
open(FD, "./t/".$d) || die "not ok (open $!)\n";
while(<FD>) {
  $buf .= $_;
}
close(FD);

# import it

my $rv = ars_Import($ctrl,
		    &ARS::AR_IMPORT_OPT_CREATE,
		    $buf, 
		    "Schema", "ARSperl Test",
		    "Schema", "ARSperl Test2",
		    "Schema", "ARSperl Test-join",
		    "Schema", "ARSperl Test3",
		    "Filter", "ARSperl Test-Filter1",
		    "Active_Link", "ARSperl Test-alink1",
		    "Escalation", "ARSperl Test-escalation1",
		    "Char_Menu", "ARSperl Test-menu-search1",
			"Container", "ARSperl Test-FilterGuide1",
	);


if(defined($rv) && ($rv == 1)) {
	print "ok\n";
} else {
	print "not ok [$ars_errstr]\n";
}

ars_Logoff($ctrl);

sleep 5;
exit 0;

