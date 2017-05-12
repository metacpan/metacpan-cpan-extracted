use strict;
use warnings;
use Test::More tests => 2;
use lib 't/lib';
BEGIN {
    use_ok( 'TestApp::AutoLastModified' );
};

# set up CGI:App for testing
$ENV{CGI_APP_RETURN_ONLY} = 1;

# run our test
my $app = TestApp::AutoLastModified->new();
my $res = $app->run();
like( $res, qr/^Last-Modified:/mi, 'Last-Modified header present' );
