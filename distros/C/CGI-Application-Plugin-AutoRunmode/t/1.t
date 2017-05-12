#!perl -T
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################


use Test::More tests => 9;
BEGIN { use_ok('CGI::Application::Plugin::AutoRunmode') };

#########################

# Test CGI::App class
{ 
	package MyTestApp;
	use base 'CGI::Application';
	use CGI::Application::Plugin::AutoRunmode
		qw [ cgiapp_prerun ];
	
	
	 sub mode1 : Runmode {
	 	'called mode1';
	 }
	 
	 sub not_a_runmode{
	 	'not a runmode';
	}
}

$ENV{CGI_APP_RETURN_ONLY} = 1;
$ENV{REQUEST_METHOD} = 'GET';
$ENV{QUERY_STRING} = 'rm=mode1';

use CGI;
my $q = new CGI;
{
	my $testname = "autodetect runmode in CGI::App class";
	
	my $app = new MyTestApp(QUERY=>$q);
	my $t = $app->run;
	ok ($t =~ /called mode1/, $testname);
}


{ 
	package MyTestAppCased;
	use base 'CGI::Application';
	use CGI::Application::Plugin::AutoRunmode
		qw [ cgiapp_prerun ];
	
	
	 sub mode1 : RunMode {
	 	'called mode1';
	 }
	 
	 sub not_a_runmode{
	 	'not a runmode';
	}
}



{
	my $testname = "case insensitivity";
	
	my $app = new MyTestAppCased(QUERY=>$q);
	my $t = $app->run;
	ok ($t =~ /called mode1/, $testname);
}

{
	my $testname = "try to call a not-runmode";
	$q->param(rm => 'not_a_runmode');
	my $app = new MyTestApp(QUERY=>$q);
	eval{ my $t = $app->run; };
	ok ($@ =~ /not_a_runmode/, $testname);
}
	
# Test CGI::App subclass
{ 
	package MyTestSubApp;
	use base qw[MyTestApp ];
	
	 sub mode2 : Runmode {
	 	'called mode2';
	 }
}

# Callback test package
{

	package MyCallBackTest;
	use base  'CGI::Application';
	use CGI::Application::Plugin::AutoRunmode;
		
	 sub mode2 : Runmode {
	 	'called mode2';
	 }
	 
	 sub cgiapp_prerun{
	 	my ($self, $rm) = @_;
		$self->prerun_mode('mode2')
			if $rm eq 'change_to_2';
		CGI::Application::Plugin::AutoRunmode::cgiapp_prerun($self);
	 }


}




{	
	my $testname = "runmode from a superclass";
	$q->param(rm => 'mode1');
	my $app = new MyTestSubApp(QUERY=>$q);
	my $t = $app->run;
	ok ($t =~ /called mode1/, $testname);
}

{	
	my $testname = "runmode from a subclass";
	$q->param(rm => 'mode2');
	my $app = new MyTestSubApp(QUERY=>$q);
	my $t = $app->run;
	ok ($t =~ /called mode2/, $testname);
}

{	
	my $testname = "security check - calling packaged runmode";
	$q->param(rm => 'MyTestSubApp::mode2');
	my $app = new MyTestApp(QUERY=>$q);
	eval{ my $t = $app->run; };
	ok ($@ =~ /^No such/, $testname);
}


# CGI::App::Callbacks tests (4.0 hooks)
 SKIP: {
 	my $has_callbacks = $CGI::Application::VERSION >= 4;
 	
 
	skip 'callback hooks require CGI::Application version 4', 2 
	     	unless $has_callbacks;



{	
	my $testname = "install via Callbacks";
	$q->param(rm => 'mode2');
	my $app = new MyCallBackTest(QUERY=>$q);
	my $t = $app->run;
	ok ($t =~ /called mode2/, $testname);
}

{	
	my $testname = "prerun changed mode";
	$q->param(rm => 'change_to_2');
	my $app = new MyCallBackTest(QUERY=>$q);
	my $t = $app->run;
	ok ($t =~ /called mode2/, $testname);
}

}; # end skip


