use Test::More tests => 17;
use strict;

use lib 't/';

# 1
BEGIN { 
	use_ok('CGI::Application');
};

use TestAppMatch;
use CGI;

$ENV{CGI_APP_RETURN_ONLY} = 1;

{
	my $app = TestAppMatch->new();
	$app->query(CGI->new({'test_rm' => 'basic_runmode'}));
	my $output = $app->run();
	like($output, qr/Runmode: basic_runmode/);
}

{
	local $ENV{PATH_INFO} = '';
	my $app = TestAppMatch->new();
	my $output = $app->run();

	like($output, qr{^Content-Type: text/html});
	like($output, qr/Runmode: starter_rm/);
}

{
	local $ENV{PATH_INFO} = '/products';
	my $app = TestAppMatch->new();
	my $output = $app->run();

	like($output, qr{^Content-Type: text/html});
	like($output, qr/Runmode: products/);
}

{
	local $ENV{PATH_INFO} = '/products/';
	my $app = TestAppMatch->new();
	my $output = $app->run();

	like($output, qr{^Content-Type: text/html});
	like($output, qr/Runmode: products/);
}

{
	local $ENV{PATH_INFO} = '/products/books/war_and_peace';
	my $app = TestAppMatch->new();
	my $output = $app->run();

	like($output, qr{^Content-Type: text/html});
	like($output, qr/Runmode: product/);
	like($output, qr/Category: books/);
	like($output, qr/Product: war_and_peace/);
}

{
	local $ENV{PATH_INFO} = '/products/music/rolling_stones';
	my $app = TestAppMatch->new();
	my $output = $app->run();

	like($output, qr{^Content-Type: text/html});
	like($output, qr/Runmode: music/);
	like($output, qr/Product: rolling_stones/);
}

{
	local $ENV{PATH_INFO} = '/products/music/beatles';
	my $app = TestAppMatch->new();
	my $output = $app->run();

	like($output, qr{^Content-Type: text/html});
	like($output, qr/Runmode: beatles/);
}
