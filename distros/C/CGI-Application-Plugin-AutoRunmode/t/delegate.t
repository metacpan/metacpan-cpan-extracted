#!perl -T
#########################


use Test::More tests => 10;
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
	my $testname = "call delegate runmode (class)";
	
	my $app = new MyTestApp(QUERY=>$q);
	my $t = $app->run;
	ok ($t =~ /called mode1/, $testname);
}

{
	my $testname = "call delegate runmode (object)";
	
	my $app = new MyTestApp(QUERY=>$q);
	$app->param("::Plugin::AutoRunmode::delegate"
		=> bless {}, 'MyTestDelegate');
	my $t = $app->run;
	ok ($t =~ /called mode1/, $testname);
}

{
	my $testname = "try to call a not-runmode";
	$q->param(rm => 'can');
	my $app = new MyTestApp(QUERY=>$q);
	eval{ 
		my $t = $app->run;
		};
	ok ($@ =~ /No such run.mode/, $testname);
}
	
# delegate subclass
{ 
	package MyTestSubDelegate;
	@MyTestSubDelegate::ISA = qw[MyTestDelegate ];
	
	 sub mode2  {
	 	'called mode2';
	 }
	 
	 sub mode3{
	 	my ($app, $delegate) = @_;
		'called mode3 '.$delegate->{hey};
	}
}


{	
	my $testname = "runmode from a superclass";
	$q->param(rm => 'mode1');
	my $app = new MyTestApp(QUERY=>$q);
	$app->param("::Plugin::AutoRunmode::delegate"
		=> 'MyTestSubDelegate');
	my $t = $app->run;
	ok ($t =~ /called mode1/, $testname);
}

{	
	my $testname = "runmode from a subclass";
	$q->param(rm => 'mode2');
	my $app = new MyTestApp(QUERY=>$q);
	$app->param("::Plugin::AutoRunmode::delegate"
		=> 'MyTestSubDelegate');
	my $t = $app->run;
	ok ($t =~ /called mode2/, $testname);
}

{	
	my $testname = "security check - calling packaged runmode";
	$q->param(rm => 'MyTestApp::setup');
	my $app = new MyTestApp(QUERY=>$q);
	eval{ my $t = $app->run; };
	ok ($@ =~ /^No such/, $testname);
}

{	
	my $testname = "stateful delegate";
	$q->param(rm => 'mode3');
	my $app = new MyTestApp(QUERY=>$q);
	$app->param("::Plugin::AutoRunmode::delegate"
		=> bless {hey => 'aaa'}, 'MyTestSubDelegate');
	my $t = $app->run;
	ok ($t =~ /called mode3 aaa/, $testname);
}

# delegate chain

{	
	my $testname = "delegate chain: call first one";
	$q->param(rm => 'mode1');
	my $app = new MyTestApp(QUERY=>$q);
	$app->param("::Plugin::AutoRunmode::delegate"
		=> [
			 'MyTestDelegate',
		   	bless {hey => 'bbb'}, 'MyTestSubDelegate'
		   ]);
	my $t = $app->run;
	ok ($t =~ /called mode1/, $testname);
}

{	
	my $testname = "delegate chain: call second one";
	$q->param(rm => 'mode3');
	my $app = new MyTestApp(QUERY=>$q);
	$app->param("::Plugin::AutoRunmode::delegate"
		=> [
			 'MyTestDelegate',
		   	bless {hey => 'bbb'}, 'MyTestSubDelegate'
		   ]);
	my $t = $app->run;
	ok ($t =~ /called mode3 bbb/, $testname);
}



