use Test::More;

## TEST PLAN ##
# same as 02-check_output.t, but using a Template
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
# FILES: 07-template_toolkit.t, TestAppTT.pm, output.tt

use lib './t';
use strict;

$ENV{CGI_APP_RETURN_ONLY} = 1;

BEGIN {
    eval "use TestAppTT";
    plan skip_all => "CGI::Application::Plugin::TT 0.09 required for testing TT integration" if $@;
}

use CGI;

plan tests => 8;

my $testapp = TestAppTT->new(QUERY=>CGI->new());
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
$testapp = TestAppTT->new( QUERY => $query );
$output = $testapp->run;

$test_name = "got the expected output";
like( $output, qr/message pushed/, $test_name );

$query->param( -name => 'rm', -value => 'third' );
$testapp = TestAppTT->new( QUERY => $query );
$output = $testapp->run;

$test_name = "message is in the output";
like( $output, qr/this is a test/, $test_name );

$test_name = "classification was in place";
like( $output, qr/div class="ERROR"/, $test_name );

# let's clean up
$query->param( -name => 'rm', -value => 'cleanup' );
$testapp = TestAppTT->new( QUERY => $query );
$output = $testapp->run;

$test_name = 'got the expected output from the cleanup runmode';
like( $output, qr/session deleted/, $test_name );

undef $testapp;

# check & make sure that file doesn't exist...
my $file = 't/cgisess_' . $session_id;
$test_name = 'session flat file was deleted';
ok( ! -e $file, $test_name );
