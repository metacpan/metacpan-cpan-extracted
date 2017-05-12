use Test::More tests => 3;
use strict;

use lib 't/';

# 1
BEGIN { 
	use_ok('CGI::Application');
};

use TestAppRunmode;
use CGI;

$ENV{CGI_APP_RETURN_ONLY} = 1;

{
	local $ENV{PATH_INFO} = '/runmode_rm';
	my $app = TestAppRunmode->new();
	my $output = $app->run();

	like($output, qr{^Content-Type: text/html});
	like($output, qr/Runmode: runmode_rm/);
}
