use Test::More;

## TEST PLAN ##
#* cgiapp w/ html-template
# * same as before, but check scoping:
#    - in 2nd request, scope info message for non-existent runmode
#    - in 3rd request, check for ! message
#    - in 4th request, scope info message for arrayref runmodes
#    - in 5th request, check for message (1st arrayref value)
#    - in 6th request, check for message (2nd arrayref value)
#    - in 7th request, check for ! message
#FILES: 03-scope.t, TestAppScope.pm, output.TMPL

use lib './t';
use strict;

$ENV{CGI_APP_RETURN_ONLY} = 1;

BEGIN {
    eval "use CGI::Application::Plugin::Session";
    plan skip_all => "CGI::Application::Plugin::Session required for this test" if $@;
}

plan tests => 6;

use CGI;
use TestAppScope;

my $testapp = TestAppScope->new(QUERY=>CGI->new());
my $output = $testapp->run();

# $output should have the session setup w/ a cookie
# Get the ID # to establish the session in a second request
$output =~ /Set-Cookie: CGISESSID=(\w+);/;
my $session_id = $1;

$ENV{HTTP_COOKIE} = "CGISESSID=$session_id";
my $query = new CGI;
$query->param( -name => 'rm', -value => 'second' );
$testapp = TestAppScope->new( QUERY => $query );
$output = $testapp->run;

my $test_name = "got the expected output";
like( $output, qr/scoped message pushed/, $test_name );

$query->param( -name => 'rm', -value => 'third' );
$testapp = TestAppScope->new( QUERY => $query );
$output = $testapp->run;

$test_name = "message is not in the output";
unlike( $output, qr/this is a test/, $test_name );

$query->param( -name => 'rm', -value => 'fourth' );
$testapp = TestAppScope->new( QUERY => $query );
$output = $testapp->run;

$test_name = "pushed the arrayref scope";
like( $output, qr/scoped message with arrayref pushed/, $test_name );

$query->param( -name => 'rm', -value => 'fifth' );
$testapp = TestAppScope->new( QUERY => $query );
$output = $testapp->run;

$test_name = "got the message in first arrayref value scope runmode";
like( $output, qr/arrayref test/, $test_name );

$query->param( -name => 'rm', -value => 'sixth' );
$testapp = TestAppScope->new( QUERY => $query );
$output = $testapp->run;

$test_name = "got the message in second arrayref value scope runmode";
like( $output, qr/arrayref test/, $test_name );

$query->param( -name => 'rm', -value => 'third' );
$testapp = TestAppScope->new( QUERY => $query );
$output = $testapp->run;

$test_name = "scoped arrayref message isn't in other runmode";
unlike( $output, qr/arrayref test/, $test_name );

# let's clean up
$query->param( -name => 'rm', -value => 'cleanup' );
$testapp = TestAppScope->new( QUERY => $query );
$output = $testapp->run;

undef $testapp;
