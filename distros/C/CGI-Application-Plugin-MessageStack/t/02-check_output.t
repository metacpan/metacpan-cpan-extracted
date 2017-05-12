use Test::More;

# the cgiapp adds one more to the test # above

## TEST PLAN ##
# * cgiapp w/ html-template
#  * first request:
#     - establish/check for session
#     - check output for ! message
#  * second request:
#     - pass in session
#     - push an info message
#  * third request:
#     - pass in session
#     - check output for message
#     - check message for proper classification
#  * fourth request:
#     - pass in session
#     - call messages() and compare
#     - check output for 'succeeded'
# FILES: 02-check_output.t, TestAppOutput.pm, output.TMPL

use lib './t';
use strict;

BEGIN {
    eval "use CGI::Application::Plugin::Session";
    plan skip_all => "CGI::Application::Plugin::Session required for this test" if $@;
}

plan tests => 10;

$ENV{CGI_APP_RETURN_ONLY} = 1;

use CGI;
use TestAppOutput;

my $testapp = TestAppOutput->new(QUERY=>CGI->new());
my $output = $testapp->run();

# $output should have the session setup w/ a cookie
# Get the ID # to establish the session in a second request
my $test_name = 'session cookie was setup';
like( $output, qr/Set-Cookie: CGISESSID=\w+/, $test_name );
$output =~ /Set-Cookie: CGISESSID=(\w+);/;
my $session_id = $1;
$test_name = "got the session id ($session_id)";
ok( $session_id, $test_name );

$test_name = "message isn't in output";
unlike( $output, qr/this is a test/, $test_name );

$ENV{HTTP_COOKIE} = "CGISESSID=$session_id";
my $query = new CGI;
$query->param( -name => 'rm', -value => 'second' );
$testapp = TestAppOutput->new( QUERY => $query );
$output = $testapp->run;

$test_name = "got the expected output";
like( $output, qr/message pushed/, $test_name );

$query->param( -name => 'rm', -value => 'third' );
$testapp = TestAppOutput->new( QUERY => $query );
$output = $testapp->run;

$test_name = "message is in the output";
like( $output, qr/this is a test/, $test_name );

$test_name = "classification was in place";
like( $output, qr/div class="ERROR"/, $test_name );

$query->param( -name => 'rm', -value => 'fourth' );
$testapp = TestAppOutput->new( QUERY => $query );
$output = $testapp->run;

$test_name = "messages weren't automatically cleared";
like( $output, qr/succeeded/, $test_name );

# let's clean up
$query->param( -name => 'rm', -value => 'cleanup' );
$testapp = TestAppOutput->new( QUERY => $query );
$output = $testapp->run;

$test_name = 'got the expected output from the cleanup runmode';
like( $output, qr/session deleted/, $test_name );

undef $testapp;

# check & make sure that file doesn't exist...
my $file = 't/cgisess_' . $session_id;
$test_name = 'session flat file was deleted';
ok( ! -e $file, $test_name );
