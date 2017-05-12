use Test::More tests => 6;
use strict;

use lib 't/';

BEGIN { 
	use_ok('CGI::Application');
};

use TestAppRegex;
use CGI;

$ENV{CGI_APP_RETURN_ONLY} = 1;

{
	local $ENV{PATH_INFO} = '/products/books/war_and_peace/ch/3/';
	my $app = TestAppRegex->new();
	my $output = $app->run();

	like($output, qr{^Content-Type: text/html});
	like($output, qr/Runmode: product/);
	like($output, qr/Category: books/);
	like($output, qr/Product: war_and_peace/);
	like($output, qr/Args: ch 3/);
}
