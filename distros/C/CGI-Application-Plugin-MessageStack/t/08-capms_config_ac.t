use Test::More;

# The cgiapp adds 1 more test to the mix...

## TEST PLAN ##
#* capms_config w/ Automatic Clearing
# * cgiapp w/ various configuration runmodes
#  * first request
#    - establish session
#    - call capms_config with -automatic_clearing
#    - push in some messages
#  * second request
#    - pass in session
#    - check output for message
#  * third request
#    - pass in session
#    - call messages() and compare
#FILES: 08-capms_config_ac.t, TestAppConfigAC.pm, output.TMPL

use lib './t';
use strict;

BEGIN {
    eval "use CGI::Application::Plugin::Session";
    plan skip_all => "CGI::Application::Plugin::Session required for this test" if $@;
}

plan tests => 7;

$ENV{CGI_APP_RETURN_ONLY} = 1;

use CGI;
use TestAppConfigAC;

my $testapp = TestAppConfigAC->new(QUERY=>CGI->new());
my $output = $testapp->run();
my $test_name;

# $output should have the session setup w/ a cookie
# Get the ID # to establish the session in a second request
$output =~ /Set-Cookie: CGISESSID=(\w+);/;
my $session_id = $1;

$ENV{HTTP_COOKIE} = "CGISESSID=$session_id";
my $query = new CGI;
$query->param( -name => 'rm', -value => 'second' );
$testapp = TestAppConfigAC->new( QUERY => $query );
$output = $testapp->run;

$test_name = "got the expected outputs";
# testing for an array of data here...
like( $output, qr/this is a test/, $test_name );
like( $output, qr/this is another test/, $test_name );
like( $output, qr/got your stuff updated/, $test_name );
like( $output, qr/another info/, $test_name );
like( $output, qr/some bad stuff/, $test_name );

$query->param( -name => 'rm', -value => 'third' );
$testapp = TestAppConfigAC->new( QUERY => $query );
$output = $testapp->run;

$test_name = "good automatic clearing";
like( $output, qr/succeeded/, $test_name );

# let's clean up
$query->param( -name => 'rm', -value => 'cleanup' );
$testapp = TestAppConfigAC->new( QUERY => $query );
$output = $testapp->run;

undef $testapp;

# check & make sure that file doesn't exist...
my $file = 't/cgisess_' . $session_id;
$test_name = 'session flat file was deleted';
