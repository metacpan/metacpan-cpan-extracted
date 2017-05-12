#!perl

use ARS;
use strict;
require './t/config.cache';

print "1..2\n";

my $c = ars_Login(&CCACHE::SERVER, 
		  &CCACHE::USERNAME,
                  &CCACHE::PASSWORD, "","", &CCACHE::TCPPORT);

if (defined($c)) {
	print "ok [1] (login)\n";
} else {
	print "not ok [1] (login $ars_errstr)\n";
	exit(0);
}

my $a = ars_GetFullTextInfo($c);

if (defined($a)) {
	print "ok [2] (GFTI) \n";
} else {
	print "not ok [2] (GFTI $ars_errstr)\n";
	exit(0);
}


ars_Logoff($c);
exit(0);


