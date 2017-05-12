#!perl


open(INP,"<VERSION.STRING");
my $VERSION_STRING = <INP>;
close(INP);

use Test::More tests => 4;

BEGIN {
	use_ok( 'Comskil::JWand' ) || print "Bail out!\n";
	use_ok( 'Comskil::JServer' ) || print "Bail out!\n";
	use_ok( 'Comskil::JQueue' ) || print "Bail out!\n";
	use_ok( 'Comskil::JQueue::POP' ) || print "Bail out!\n";
}


diag("<<< Testing Comskil-JIRA $VERSION_STRING, Perl $], $^X >>>");