# Tests for Connector::Builtin::Env
#

use strict;
use warnings;
use English;

use Test::More tests => 12;

use Log::Log4perl;
Log::Log4perl->easy_init( { level   => 'ERROR' } );

# diag "LOAD MODULE\n";

BEGIN {
    use_ok( 'Connector::Builtin::Env' );
}

require_ok( 'Connector::Builtin::Env' );

# Setup the test values in the environment
$ENV{'CONNECTOR_TEST_FOO'} = 'foo';
delete $ENV{'CONNECTOR_TEST_BAR'};

# diag "Connector::Builtin::Env tests\n";
###########################################################################
my $conn = Connector::Builtin::Env->new(
    {
        LOCATION => '',
        prefix => ''
    });

is( $conn->get('CONNECTOR_TEST_FOO'), 'foo');
is( $conn->get('CONNECTOR_TEST_BAR'), undef);

is( $conn->get( [ 'CONNECTOR_TEST_FOO' ]), 'foo');

ok ($conn->exists('CONNECTOR_TEST_FOO'));
ok (!$conn->exists('CONNECTOR_TEST_BAR'));

# Now try with prefix

$conn->prefix('CONNECTOR_TEST_');

is( $conn->get('FOO'), 'foo');
is( $conn->get('BAR'), undef);

is( $conn->get( [ 'FOO' ]), 'foo');

ok ($conn->exists('FOO'));
ok (!$conn->exists('BAR'));
