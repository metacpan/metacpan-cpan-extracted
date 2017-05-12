#!perl -T
use Test::More tests => 7;
BEGIN { use_ok('CGI::Application::Plugin::AutoRunmode') };

#########################

# Test CGI::App class
{ 
	package MyTestApp;
	use base 'CGI::Application';
	use CGI::Application::Plugin::AutoRunmode 
		qw [ cgiapp_prerun];
		
	sub setup{
		my $self = shift;
		$self->param(
			'::Plugin::AutoRunmode::delegate' => 'MyTestDelegate'
		);
	}
	
	sub not_a_runmode{
        'not a runmode';
     }
}

# Test delegate
{
	package MyTestDelegate;
	
	 sub mode1  {
	 	my ($self, $delegate) = @_;
		die "expected CGI::App instance as first parameter" unless $self->isa('CGI::Application');
		die "expected delegate class or instance as second parameter" unless $delegate;
		'called mode1';
	 }
}

$ENV{CGI_APP_RETURN_ONLY} = 1;
$ENV{REQUEST_METHOD} = 'GET';
$ENV{QUERY_STRING} = 'rm=mode1';


use CGI;
my $q = new CGI;
{
    my $testname = "call with no runmode";
    my $app = new MyTestApp(QUERY=>$q);
    my $t = $app->run;
    ok( CGI::Application::Plugin::AutoRunmode::is_auto_runmode($app, 'mode1'),         "[$testname] mode1");
    ok(!CGI::Application::Plugin::AutoRunmode::is_auto_runmode($app, 'not_a_runmode'), "[$testname] not_a_runode");
    ok(!CGI::Application::Plugin::AutoRunmode::is_auto_runmode($app, 'non_existing'),  "[$testname] non_existing");
}

{
    my $testname = "call with mode1";
    $q->param(rm => 'mode1');
    my $app = new MyTestApp(QUERY=>$q);
    my $t = $app->run;
    ok( CGI::Application::Plugin::AutoRunmode::is_auto_runmode($app, 'mode1'),         "[$testname] mode1");
    ok(!CGI::Application::Plugin::AutoRunmode::is_auto_runmode($app, 'not_a_runmode'), "[$testname] not_a_runode");
    ok(!CGI::Application::Plugin::AutoRunmode::is_auto_runmode($app, 'non_existing'),  "[$testname] non_existing");
 }


1;