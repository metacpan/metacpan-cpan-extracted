use Test::More;

## TEST PLAN ##
#* capms_config w/ parameter name overrides
# * cgiapp w/ parameter name configs
#  * first request
#    - establish session
#    - call capms_config with parameter name overrides
#    - push in some messages
#  * second request
#    - pass in session
#    - load original template (output.TMPL) and check for no message
#  * third request
#    - pass in session
#    - load in different template (output_params.TMPL) and check for message
#  * fourth request
#    - pass in session
#    - call messages() and compare
#FILES: 09-capms_config_params.t, TestAppConfigParams.pm, output.TMPL, output_params.TMPL

use lib './t';
use strict;

BEGIN {
    eval "use CGI::Application::Plugin::Session";
    plan skip_all => "CGI::Application::Plugin::Session required for this test" if $@;
}

# The cgiapp adds 1 more test to the mix...
plan tests => 9;

$ENV{CGI_APP_RETURN_ONLY} = 1;


use CGI;
use TestAppConfigParams;

my $testapp = TestAppConfigParams->new(QUERY=>CGI->new());
my $output = $testapp->run();
my $test_name;

# $output should have the session setup w/ a cookie
# Get the ID # to establish the session in a second request
$output =~ /Set-Cookie: CGISESSID=(\w+);/;
my $session_id = $1;

$ENV{HTTP_COOKIE} = "CGISESSID=$session_id";
my $query = new CGI;
$query->param( -name => 'rm', -value => 'second' );
$testapp = TestAppConfigParams->new( QUERY => $query );
$output = $testapp->run;

$test_name = "making sure bad template params aren't being filled";
# testing for an array of data here...
unlike( $output, qr/this is a test/, $test_name );
unlike( $output, qr/this is another test/, $test_name );

$query->param( -name => 'rm', -value => 'third' );
$testapp = TestAppConfigParams->new( QUERY => $query );
$output = $testapp->run;

$test_name = "making sure good template params are being filled";
like( $output, qr/this is a test/, $test_name );
like( $output, qr/this is another test/, $test_name );
like( $output, qr/got your stuff updated/, $test_name );
like( $output, qr/another info/, $test_name );
like( $output, qr/some bad stuff/, $test_name );

$query->param( -name => 'rm', -value => 'fourth' );
$testapp = TestAppConfigParams->new( QUERY => $query );
$output = $testapp->run;

$test_name = "the message stack compared ok";
like( $output, qr/succeeded/, $test_name );

# let's clean up
$query->param( -name => 'rm', -value => 'cleanup' );
$testapp = TestAppConfigParams->new( QUERY => $query );
$output = $testapp->run;

undef $testapp;

# check & make sure that file doesn't exist...
my $file = 't/cgisess_' . $session_id;
$test_name = 'session flat file was deleted';
