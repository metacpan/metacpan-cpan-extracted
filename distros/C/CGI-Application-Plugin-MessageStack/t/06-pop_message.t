use Test::More;

# five tests below and then one from the TestAppPop cgiapp

## TEST PLAN ##
#* pop_message
# * first request:
#    - establish session
#    - clear private session var
#    - push in a few messages
# * second request:
#    - pass in session
#    - call pop_message() and compare
# * recall first request
# * third request:
#    - pass in session
#    - call pop_message() with scope and compare
# * recall first request
# * fourth request:
#    - pass in session
#    - call pop_message() with classification and compare
# * recall first request
# * fifth request:
#    - pass in session
#    - call pop_message() with scope & classification and compare
# * sixth request:
#    - pass in session
#    - compare the remaining messages()
#FILES: 06-pop_message.t, TestAppPop.pm

use lib './t';
use strict;

BEGIN {
    eval "use CGI::Application::Plugin::Session";
    plan skip_all => "CGI::Application::Plugin::Session required for this test" if $@;
}

plan tests => 6;

$ENV{CGI_APP_RETURN_ONLY} = 1;

use CGI;
use TestAppPop;

my $testapp = TestAppPop->new(QUERY=>CGI->new());
my $output = $testapp->run();

# $output should have the session setup w/ a cookie
# Get the ID # to establish the session in a second request
$output =~ /Set-Cookie: CGISESSID=(\w+);/;
my $session_id = $1;

$ENV{HTTP_COOKIE} = "CGISESSID=$session_id";
my $query = new CGI;
$query->param( -name => 'rm', -value => 'second' );
$testapp = TestAppPop->new( QUERY => $query );
$output = $testapp->run;

my $test_name = "got the expected output (pop'd the last msg)";
like( $output, qr/succeeded/, $test_name );

$query->param( -name => 'rm', -value => 'third' );
$testapp = TestAppPop->new( QUERY => $query );
$output = $testapp->run;

$test_name = "got the expected output (pop'd the scoped msg)";
like( $output, qr/succeeded/, $test_name );

$query->param( -name => 'rm', -value => 'fourth' );
$testapp = TestAppPop->new( QUERY => $query );
$output = $testapp->run;

$test_name = "got the expected output (pop'd the classified message)";
like( $output, qr/succeeded/, $test_name );

$query->param( -name => 'rm', -value => 'fifth' );
$testapp = TestAppPop->new( QUERY => $query );
$output = $testapp->run;

$test_name = "got the expected output (pop'd both the scope & classification message)";
like( $output, qr/succeeded/, $test_name );

$query->param( -name => 'rm', -value => 'sixth' );
$testapp = TestAppPop->new( QUERY => $query );
$output = $testapp->run;

$test_name = "the remaining data structure is as expected";
like( $output, qr/succeeded/, $test_name );

# let's clean up
$query->param( -name => 'rm', -value => 'cleanup' );
$testapp = TestAppPop->new( QUERY => $query );
$output = $testapp->run;

undef $testapp;
