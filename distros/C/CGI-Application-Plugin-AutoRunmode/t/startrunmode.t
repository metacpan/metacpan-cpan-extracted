#!perl -T

use Test::More tests => 6;
use strict;
use warnings;
BEGIN { use_ok('CGI::Application::Plugin::AutoRunmode') };

$ENV{CGI_APP_RETURN_ONLY} = 1;

{
	package MyTestApp;
	use base 'CGI::Application';
	use CGI::Application::Plugin::AutoRunmode
		qw [ cgiapp_prerun ]; # for CGI::App 3 compatibility
 	sub mode1 : StartRunmode {
	 	'called mode1';
	 }
	 sub mode2 {
	 	'called mode2 in the super class'
	 	}
}



{
	package MyTestSubApp;
	use base 'MyTestApp';
 	sub mode2 : StartrunMode {
	 	'called mode2 in the sub class';
	 }
}


{
	package MyTestSubAppWithStartCalledStart;
	use base 'MyTestApp';
 	sub start : StartrunMode {
	 	'called start mode called start';
	 }
}




	{
		my $testname = "autodetect startrunmode ";
	
		my $app = new MyTestApp();
		my $t = $app->run;
		ok ($t =~ /called mode1/, $testname);
	}
	
	{
		my $testname = "autodetect startrunmode in subclass and case-insensitive ";
	
		my $app = new MyTestSubApp();
		my $t = $app->run;
		ok ($t =~ /called mode2 in the sub class/, $testname);
	}
	
	{
		my $testname = "cannot install two StartRunmodes ";
		eval <<'CODE';
		package MyTestAppBroken;
		use base 'CGI::Application';
		use CGI::Application::Plugin::AutoRunmode;
 		sub mode1 : StartRunmode {
	 		'called mode1';
		 }
		sub mode2 : StartRunmode {
		 	'called mode2';
		}
CODE
		ok ($@ =~ /StartRunmode for package MyTestAppBroken is already installed/, $testname);
	}
	
	

TODO:
{ 

	{
		my $testname = "autodetect startrunmode called start";
		local $TODO = 'you cannot have a runmode called start, because CGI::App already registers one';
	
		my $app = new MyTestApp();
		my $t = $app->run;
		ok ($t =~ /called start mode called start/, $testname);
	}

	
	{
		my $testname = "override startrunmode per instance";
		local $TODO = 'http://rt.cpan.org/Ticket/Display.html?id=23966';	
		my $app = new MyTestApp();
		$app->start_mode('mode2');
		my $t = $app->run;
		ok ($t =~ /called mode2 in the super class/, $testname)
			or diag $t;
	}
}

