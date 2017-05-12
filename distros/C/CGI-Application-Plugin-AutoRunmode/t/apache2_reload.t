#!perl -T

use CGI;
use lib 't/mocklibs';
use Apache2::Reload;
use Test::More tests => 1;
use strict;
use warnings;




{
	my $testname = "can redeclare start and error modes with Apache2::Reload";
	

{
	package MyTestApp;
	use base 'CGI::Application';
	use CGI::Application::Plugin::AutoRunmode
		qw [ cgiapp_prerun ]; # for CGI::App 3 compatibility
 	sub mode1 : StartRunmode {
	 }
	sub mode2 : StartRunmode {
	 }
	sub mode3 : ErrorRunmode {
	 }
	sub mode4 : ErrorRunmode {
	 }
	 
}
	ok(1);
}


