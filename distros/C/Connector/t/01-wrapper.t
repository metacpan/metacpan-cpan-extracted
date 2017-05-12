# Tests for Connector::Proxy::Config::Std
#

use strict;
use warnings;
use English;

use Test::More tests => 19;

# diag "LOAD MODULE\n";

use Log::Log4perl;
Log::Log4perl->easy_init( { level   => 'ERROR' } );


BEGIN {
    use_ok( 'Connector::Proxy::Config::Std' );
    use_ok( 'Connector::Multi' );
}

require_ok( 'Connector::Proxy::Config::Std' );
require_ok( 'Connector::Multi' );

# diag "Connector::Proxy::Config::Std tests\n";
###########################################################################
my $base = Connector::Proxy::Config::Std->new(
    {
    LOCATION  => 't/config/config.ini',
    PREFIX    => '',
    });
=cut
# Test if connector is good
is($base->get('test.entry.foo'), '1234');
is($base->get('test.entry.bar'), '5678');
=cut
# Load Multi
my $conn = Connector::Multi->new( {
        BASECONNECTOR => $base,
});
=cut
# diag "Test Connector::Mutli is working\n";
# Test if multi is good
is($conn->get('test.entry.foo'), '1234');
is($conn->get('test.entry.bar'), '5678');

=cut

my $wrapper = $conn->get_wrapper( ['test','entry' ]);
is($wrapper->get('foo'), '1234','Test Wrapper with arrayref path');
is($wrapper->get('bar'), '5678');

$wrapper = $conn->get_wrapper( 'test.entry' );
is($wrapper->get('foo'), '1234', 'Test Wrapper with string path');
is($wrapper->get('bar'), '5678');

$base->PREFIX('test');
my $wrapper_prefix = $conn->get_wrapper('entry');
is($conn->get('entry.foo'), '1234', 'Test Wrapper with Prefix in base connetor');
is($wrapper_prefix->get('foo'), '1234');
is($wrapper_prefix->get('bar'), '5678');

$base->PREFIX('');
$wrapper_prefix = $conn->get_wrapper('test');
$wrapper_prefix->PREFIX('entry');
is($wrapper_prefix->get('foo'), '1234', 'Test Wrapper with Prefix');
is($wrapper_prefix->get('bar'), '5678');

$conn->PREFIX('test');
$wrapper_prefix = $conn->get_wrapper('entry');
is($wrapper_prefix->get('foo'), '1234', 'Test Wrapper with Prefix in connector');
is($wrapper_prefix->get('bar'), '5678');

$conn->PREFIX('a.very');
$wrapper_prefix = $conn->get_wrapper('long.path');
is($wrapper_prefix->get('to.test.foo'), '1234', 'Test Wrapper with Prefix in both');
is($wrapper_prefix->get( ['to','test','bar']), '5678');

$conn->PREFIX( [ 'a','very' ]);
$wrapper_prefix = $conn->get_wrapper( [ 'long','path' ]);
is($wrapper_prefix->get('to.test.foo'), '1234', 'Test Wrapper with Prefix in both - array notation');
is($wrapper_prefix->get( ['to','test','bar']), '5678');





