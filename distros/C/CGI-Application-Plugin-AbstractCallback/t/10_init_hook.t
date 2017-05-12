use lib qw(./t/lib);
use Test::More qw|no_plan|;

#########################

{
	use CGI::Application::Plugin::AbstractCallback::Test::InitHook;
	
	my CGI::Application $webapp = CGI::Application::Plugin::AbstractCallback::Test::InitHook->new;
	
	ok($webapp->param('INIT', 1));
}

#########################