use strict;
use warnings;
use Test::More tests => 2;
use lib 't/lib';
BEGIN {
    use_ok( 'TestApp::Plain' );
};

# set up CGI:App for testing
$ENV{CGI_APP_RETURN_ONLY} = 1;

# run our test
my $app = TestApp::Plain->new();
my $res = $app->run();
unlike( $res, qr/^Last-Modified/mi, 'no Last-Modified header present' );
