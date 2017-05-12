# Tests for Connector::Proxy::YAML
#

use strict;
use warnings;
use English;

use Test::More tests => 30;

# diag "LOAD MODULE\n";

BEGIN {
    use_ok( 'Connector::Proxy::YAML' );
}

require_ok( 'Connector::Proxy::YAML' );

Log::Log4perl->easy_init( { level   => 'ERROR' } );

# diag "Connector::Proxy::YAML tests\n";
###########################################################################
my $conn = Connector::Proxy::YAML->new(
    {
    LOCATION  => 't/config/config.yaml',
    PREFIX    => 'test.entry',
    });

is($conn->get('foo'), '1234');
is($conn->get('bar'), '5678');


is($conn->get('nonexistent'), undef);

# Top node (not really due to prefix)
ok( grep 'foo', $conn->get_keys());

# try full path access
# diag('Tests without PREFIX');
$conn->PREFIX(undef);
is($conn->PREFIX(), undef, 'Accessor test');

# Top node, really!
ok( grep 'list', $conn->get_keys());

# and repeat above tests
is($conn->get('test.entry.foo'), '1234');
is($conn->get('test.entry.bar'), '5678');

# test with array ref path
is($conn->get( [ 'test','entry','foo' ] ), '1234');
is($conn->get( [ ('test','entry'),'bar' ] ), '5678');

# check for completely wrong entry
is($conn->get('test1.entry.bar'), undef, 'handle completely wrong entry gracefully');

# diag "Test get_meta functionality\n";
is($conn->get_meta('')->{TYPE}, 'hash', 'Root');
is($conn->get_meta('list.test')->{TYPE}, 'list', 'Array');
is($conn->get_meta('test.entry')->{TYPE}, 'hash', 'Hash');
is($conn->get_meta('test.entry.foo')->{TYPE}, 'scalar', 'Scalar');
is($conn->get_meta('test.entry.nonexisting'), undef, 'undef');


# diag "Test List functionality\n";
my @data = $conn->get_list('list.test');

is( $conn->get_size('list.test'), 4, 'size');
is( ref \@data, 'ARRAY', 'ref');
is( shift @data, 'first', 'element');

# diag "Test Hash functionality\n";
my @keys = $conn->get_keys('test.entry');
is( ref \@keys, 'ARRAY', 'keys');
is( ref $conn->get_hash('test.entry'), 'HASH', 'hash');
is( $conn->get_hash('test.entry')->{bar}, '5678', 'element');


is_deeply( [ sort ($conn->get_keys('')) ], [ 'list', 'test' ]  , 'top node');

ok ($conn->exists(''), 'Connector exists');
ok ($conn->exists('test'), 'Node Exists');
ok ($conn->exists('test.entry'), 'Leaf Exists');
ok ($conn->exists( [ 'test', 'entry' ] ), 'Node Exists Array');
ok (!$conn->exists('test.entry2'), 'Not Exists');

