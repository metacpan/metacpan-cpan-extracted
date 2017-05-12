use Test::More tests => 5;

## TEST PLAN ##
# * capms_config w/ dont_use_session
#  * cgiapp w/ dont_use_session config
#   * first request
#     - push in some messages
#     - check for no messages
#     - load_tmpl and check for output
#   * second request
#     - load_tmpl and check for no messages in output
# FILES: 10-capms_config_no_session.t, TestAppConfigNoSession.pm, output.TMPL

use lib './t';
use strict;

$ENV{CGI_APP_RETURN_ONLY} = 1;

use CGI;
use TestAppConfigNoSession;

my $cgiapp;
my $output;

eval {
    $cgiapp = TestAppConfigNoSession->new(QUERY=>CGI->new());
    $output = $cgiapp->run();
};

my $test_name = "didn't die() w/ no session";
ok( !$@, $test_name );

$test_name = "output has message in it";
like( $output, qr/this is a test/, $test_name );

$test_name = "output has classification in it";
like( $output, qr/ERROR/, $test_name );

my $query = new CGI;
$query->param( -name => 'rm', -value => 'second' );
$cgiapp = TestAppConfigNoSession->new(QUERY=>$query);
$output = $cgiapp->run();

$test_name = "output doesn't have message in it";
unlike( $output, qr/this is a test/, $test_name );

$test_name = "output doesn't have classification in it";
unlike( $output, qr/"ERROR"/, $test_name );