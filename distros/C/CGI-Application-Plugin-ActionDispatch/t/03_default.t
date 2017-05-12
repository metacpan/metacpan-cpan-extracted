use Test::More tests => 2;
use strict;

use lib 't/';

# 1
BEGIN { 
	use_ok('CGI::Application');
};

use TestAppDefault;
use CGI;

$ENV{CGI_APP_RETURN_ONLY} = 1;

{
	my $app = TestAppDefault->new();
	my $output = $app->run();

	like($output, qr/Runmode: default_rm/);
}
