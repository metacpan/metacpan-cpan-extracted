#!perl

use ARS;
use strict;
require './t/config.cache';

print "1..4\n";

my $c = ars_Login(&CCACHE::SERVER, 
		  &CCACHE::USERNAME,
                  &CCACHE::PASSWORD, "","", &CCACHE::TCPPORT);

if (defined($c)) {
	print "ok [1] (login)\n";
} else {
	print "not ok [1] (login $ars_errstr)\n";
	exit(0);
}

my $a = ars_GetEscalation($c, "ARSperl Test-escalation1");

if (defined($a)) {
	print "ok [2] (GESC) \n";
} else {
	print "not ok [2] (GESC $ars_errstr)\n";
	exit(0);
}

# the escalation should have a schemaList key

if( (!exists($a->{'schemaList'})         ) || 
    ( ref($a->{'schemaList'}) ne "ARRAY" ) 
  ) {
	print "not ok [3] (no schemaList?)\n";
	exit(0);
} else {
	print "ok [3] (schemaList exists)\n";
}


# the schemaList should have 2 entries

if ($#{$a->{'schemaList'}} != 1) {
	print "not ok [4] (schemaList != 2 entries)\n";
	exit(0);
} else {
	print "ok [4] (schemaList ok, 2 entries)\n";
}

ars_Logoff($c);
exit(0);


