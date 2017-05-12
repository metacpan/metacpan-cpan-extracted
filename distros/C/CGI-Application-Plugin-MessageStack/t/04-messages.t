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

$ENV{CGI_APP_RETURN_ONLY} = 1;

BEGIN {
    eval "use CGI::Application::Plugin::Session";
    plan skip_all => "CGI::Application::Plugin::Session required for this test" if $@;
}

plan tests => 8;

use CGI;
use TestAppMessages;

my $testapp = TestAppMessages->new(QUERY=>CGI->new());
my $output = $testapp->run();

# $output should have the session setup w/ a cookie
# Get the ID # to establish the session in a second request
$output =~ /Set-Cookie: CGISESSID=(\w+);/;
my $session_id = $1;

$ENV{HTTP_COOKIE} = "CGISESSID=$session_id";
my $query = new CGI;
$query->param( -name => 'rm', -value => 'second' );
$testapp = TestAppMessages->new( QUERY => $query );
$output = $testapp->run;

my $test_name = "got the expected output (all messages)";
like( $output, qr/succeeded/, $test_name );

$query->param( -name => 'rm', -value => 'third' );
$testapp = TestAppMessages->new( QUERY => $query );
$output = $testapp->run;

$test_name = "got the expected output (scoped messages)";
like( $output, qr/succeeded/, $test_name );

$query->param( -name => 'rm', -value => 'fourth' );
$testapp = TestAppMessages->new( QUERY => $query );
$output = $testapp->run;

$test_name = "got the expected output (classified messages)";
like( $output, qr/succeeded/, $test_name );

$query->param( -name => 'rm', -value => 'fifth' );
$testapp = TestAppMessages->new( QUERY => $query );
$output = $testapp->run;

$test_name = "got the expected output (both scope & classification)";
like( $output, qr/succeeded/, $test_name );

# let's clean up
$query->param( -name => 'rm', -value => 'cleanup' );
$testapp = TestAppMessages->new( QUERY => $query );
$output = $testapp->run;

undef $testapp;
