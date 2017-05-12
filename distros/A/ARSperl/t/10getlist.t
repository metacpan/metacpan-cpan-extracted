#!perl

use ARS;
use strict;
require './t/config.cache';

use Test::More tests => 9;

my $c = ars_Login(&CCACHE::SERVER, 
		  &CCACHE::USERNAME,
                  &CCACHE::PASSWORD, "","", &CCACHE::TCPPORT);

ok(defined($c), "login") || diag "login: $ars_errstr";

SKIP: {
	skip 8, "login failed" unless defined($c);

	my @a = ars_GetListEscalation($c, "ARSperl Test");

	ok($#a == 0, "GetListEscalation") ||
		diag "GetListEscalation ($#a) $ars_errstr";

	@a = ars_GetListField($c, "ARSperl Test", 0, 1);
	ok($#a == 110, "GetListField") ||
		diag "GetListField ($#a) $ars_errstr";

	@a = ars_GetListFilter($c, "ARSperl Test");
	ok($#a == 0, "GetListFilter") ||
		diag "GetListFilter ($#a) $ars_errstr";

	@a = ars_GetListGroup($c);
	ok(@a, "GetListGroup") || 
		diag "GetListGroup $ars_errstr";

	@a = ars_GetListSchema($c, 0, 0 + 1024);
	ok(@a, "GetListSchema") ||
		diag "GetListSchema $ars_errstr";

	# since this test can fail and still be OK
	# (/etc/ar is empty) we wont do it.
	#@a = ars_GetListServer();

	# this test might fail if the sql is bad or this
	# isnt an admin account we are running with
	@a = ars_GetListSQL($c, "select name, schemaid, nextid from arschema");
	ok(@a, "GetListSQL") || 
		diag("GetListSQL ($ars_errstr) - it's OK if this fails");

	@a = ars_GetListUser($c);
	ok (@a, "GetListUser") ||
		diag("GetListUser ($ars_errstr)");

	@a = ars_GetListVUI($c, "ARSperl Test");
	ok (@a, "GetListVUI") ||
		diag("GetListVUI ($ars_errstr)");

}
ars_Logoff($c);
exit(0);


