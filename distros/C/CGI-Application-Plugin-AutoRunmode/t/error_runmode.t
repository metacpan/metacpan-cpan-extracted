#!perl -T

use Test::More tests => 7;
use strict;
use warnings;
use CGI;
BEGIN { use_ok('CGI::Application::Plugin::AutoRunmode') };


SKIP: {
	skip 'requires CGI::App v3.30 and above', 6
		unless $CGI::Application::VERSION >= '3.30';
		
$ENV{CGI_APP_RETURN_ONLY} = 1;

{
	package MyTestApp;
	use base 'CGI::Application';
	use CGI::Application::Plugin::AutoRunmode
		qw [ cgiapp_prerun ]; # for CGI::App 3 compatibility
 	sub mode1 : ErrorRunmode {
	 	'called mode1';
	 }
	 sub mode2 {
	 	'called mode2 in the super class'
	 	}
	 sub mode3 : StartRunmode{
	 	die 'hey';
	 }
	 
}



{
	package MyTestSubApp;
	use base 'MyTestApp';
 	sub mode2 : ErrorRunMode {
	 	'called mode2 in the sub class';
	 }
}




	{
		my $testname = "autodetect error runmode ";
	
		my $app = new MyTestApp();
		my $t = $app->run;
		ok ($t =~ /called mode1/, $testname) or diag $t;
	}
	
	
	{
		my $testname = "error runmode is not a regular runmode";
		my $q = new CGI({'rm' =>'mode1'});
		my $app = new MyTestApp(QUERY=>$q);
		
		eval{ $app->run; };
		ok ($@ =~ /No such run mode 'mode1'/, $testname);
	}
	
		
	{
		package MyTestSubApp2;
		use base 'MyTestApp';
 		sub mode2 : ErrorRunmode :Runmode {
	 		'called mode2 in the sub class';
	 	}
	}
	
	{
		my $testname = "error runmode is also a regular runmode";
		my $q = new CGI({'rm' =>'mode2'});
		my $app = new MyTestSubApp2(QUERY=>$q);
		my $t = $app->run; 
		ok ($t =~ /called mode2 in the sub class/, $testname);
	}
	
	
	
	{
		my $testname = "autodetect error runmode in subclass and case-insensitive ";
	
		my $app = new MyTestSubApp();
		my $t = $app->run;
		ok ($t =~ /called mode2 in the sub class/, $testname);
	}
	
	{
		my $testname = "cannot install two ErrorRunmodes ";
		eval <<'CODE';
		package MyTestAppBroken;
		use base 'CGI::Application';
		use CGI::Application::Plugin::AutoRunmode;
 		sub mode1 : ErrorRunmode {
	 		'called mode1';
		 }
		sub mode2 : ErrorRunmode {
		 	'called mode2';
		}
CODE
		ok ($@ =~ /ErrorRunmode for package MyTestAppBroken is already installed/, $testname);
	}
	
	
	

	

TODO:
{ 
	
	{
		my $testname = "override error runmode per instance";
		local $TODO = 'http://rt.cpan.org/Ticket/Display.html?id=23966';	
		my $app = new MyTestApp();
		$app->error_mode('mode2');
		my $t = $app->run;
		ok ($t =~ /called mode2 in the super class/, $testname)
			or diag $t;
	}
}



	
	
	




}