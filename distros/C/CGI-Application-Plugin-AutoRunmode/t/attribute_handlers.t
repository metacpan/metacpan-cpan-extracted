#!perl -T

# test to check interoperability with other plugins that use
# Attribute::Handlers
#

use Test::More tests => 16;
use strict;
use warnings;
use Data::Dumper;
use lib 'blib/../t';
my $has_ah;
my $has_myplugin;
my $has_myapp;
BEGIN {
	eval <<'EVAL';
		use Attribute::Handlers;
		$has_ah = 1;
		package MyPlugin;

		our %RUNMODES;

		use Attribute::Handlers;

		sub CGI::Application::Authen : ATTR(CODE) {
    		my ( $package, $symbol, $referent, $attr, $data, $phase ) = @_;
    		no strict 'refs';
    		$RUNMODES{$referent} = 1;
		}
		
		$has_myplugin = 1;
		package MyApp;

    	use base qw(CGI::Application);
    	use CGI::Application::Plugin::AutoRunmode qw(cgiapp_prerun);

    	sub test :Authen { return 'test' }
    	sub test2 :Authen :Runmode { return 'test2' }
    	sub test3 :Runmode { return 'test3' }
    	
    	package MySubApp;
    	use base qw[ MyApp] ;
    	
    	sub test :Runmode { return 'made into a run mode'; }
    	sub test2 { return 'no longer a run mode' }
    	sub test3 :Runmode { 'still a run mode' }

		    	
    	
    	$has_myapp = 1;
EVAL
	diag $@ if $@;
}

SKIP: {

skip 'needs Attribute::Handlers', 16 unless $has_ah;


is($has_myplugin, 1, 'compile plugin that defines attributes');
is($has_myapp, 1, 'compile MyApp that uses attributes');



$ENV{CGI_APP_RETURN_ONLY} = 1;
$ENV{REQUEST_METHOD} = 'GET';
$ENV{QUERY_STRING} = 'rm=test2';

use CGI;
my $q = new CGI;

{
	my $app = new MyApp(QUERY=>$q);
	my $t = $app->run;
	like ($t , qr/test2/, 'call runmode with extra attribute');
	ok($MyPlugin::RUNMODES{$app->can('test2')}, 
		'extra attribute has been installed');
	

}


{
	$q->param(rm => 'test3');	
	my $app = new MyApp(QUERY=>$q);
	my $t = $app->run;
	like ($t , qr/test3/, 'call runmode without extra attribute');
	ok ( not ($MyPlugin::RUNMODES{$app->can('test3')}), 
		'no extra attribute has been installed when not requested');

}	


	
	
{
	my $testname = "try to call a not-runmode";
	$q->param(rm => 'test');
	my $app = new MyApp(QUERY=>$q);
	eval{ my $t = $app->run; };
	ok ($@ =~ /test/, $testname);
	ok($MyPlugin::RUNMODES{$app->can('test')},
		'extra attribute has been installed on non-runmode');
}
	

skip 'needs CGI::Application version 4', 8 unless $CGI::Application::VERSION >= 4;

{
	my $testname = "run-modes have been inserted into modemap";
	$q->param(rm => '');	
	my $app = new MyApp(QUERY=>$q);
	$app->run;
	my %rmodes = $app->run_modes();
	is (scalar(keys %rmodes), 3, 'number of runmodes') || diag Dumper \%rmodes;
	ok ($rmodes{$_}, "runmode $_ registered") foreach qw[ test2 test3 start] ;
}
	
{
	my $testname = "subclass can override run-modes inserted into modemap";
	$q->param(rm => '');	
	my $app = new MySubApp(QUERY=>$q);
	$app->run;
	my %rmodes = $app->run_modes();
	is (scalar(keys %rmodes), 3, 'number of runmodes') || diag Dumper \%rmodes;
	ok ($rmodes{$_}, "runmode $_ registered") foreach qw[ test test3 start] ;
}
	


}
