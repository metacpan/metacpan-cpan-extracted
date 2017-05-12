use Test::More;

# that 8 above -- I'm using Test::More in the TestAppMessages class for the
# convenient is_deeply method.  So that doubles the number of tests below.

## TEST PLAN ##
#* messages
# * first request:
#    - establish session
#    - push in a few messages
# * second request:
#    - pass in session
#    - call messages() and compare data structure
# * third request:
#    - pass in session
#    - call messages() with scope and compare data structure
# * fourth request:
#    - pass in session
#    - call messages() with classification and compare data structure
# * fifth request:
#    - pass in session
#    - call messages() with both scope & classification and compare data structure
#FILES: 04-messages.t, TestMessages.pm

use lib './t';
use strict;

BEGIN {
    eval "use CGI::Application::Plugin::Session";
    plan skip_all => "CGI::Application::Plugin::Session required for this test" if $@;
}

plan tests => 8;

$ENV{CGI_APP_RETURN_ONLY} = 1;

use CGI;
use TestAppClear;

my $testapp = TestAppClear->new(QUERY=>CGI->new());
my $output = $testapp->run();

# $output should have the session setup w/ a cookie
# Get the ID # to establish the session in a second request
$output =~ /Set-Cookie: CGISESSID=(\w+);/;
my $session_id = $1;

$ENV{HTTP_COOKIE} = "CGISESSID=$session_id";
my $query = new CGI;
$query->param( -name => 'rm', -value => 'second' );
$testapp = TestAppClear->new( QUERY => $query );
$output = $testapp->run;

my $test_name = "got the expected output (cleared all messages)";
like( $output, qr/succeeded/, $test_name );

# calling this to reset the messages
$testapp = TestAppClear->new(QUERY=>CGI->new());
$output = $testapp->run();

$query->param( -name => 'rm', -value => 'third' );
$testapp = TestAppClear->new( QUERY => $query );
$output = $testapp->run;

$test_name = "got the expected output (cleared scoped messages)";
like( $output, qr/succeeded/, $test_name );

# calling this to reset the messages
$testapp = TestAppClear->new(QUERY=>CGI->new());
$output = $testapp->run();

$query->param( -name => 'rm', -value => 'fourth' );
$testapp = TestAppClear->new( QUERY => $query );
$output = $testapp->run;

$test_name = "got the expected output (cleared classified messages)";
like( $output, qr/succeeded/, $test_name );

# calling this to reset the messages
$testapp = TestAppClear->new(QUERY=>CGI->new());
$output = $testapp->run();

$query->param( -name => 'rm', -value => 'fifth' );
$testapp = TestAppClear->new( QUERY => $query );
$output = $testapp->run;

$test_name = "got the expected output (cleared both scope & classification)";
like( $output, qr/succeeded/, $test_name );

# let's clean up
$query->param( -name => 'rm', -value => 'cleanup' );
$testapp = TestAppClear->new( QUERY => $query );
$output = $testapp->run;

undef $testapp;
