use Test::More tests => 2;
use strict;

use lib 't/';

# 1
BEGIN { 
	use_ok('CGI::Application');
};

use TestAppErrorRunmode;
use CGI;

$ENV{CGI_APP_RETURN_ONLY} = 1;

{
	my $app = TestAppErrorRunmode->new();
	my $output = $app->run();
	like($output, qr/Runmode: error_rm/);
}
