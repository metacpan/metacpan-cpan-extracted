# Tests for Connector::Proxy::Config::Std
#

use strict;
use warnings;
use English;

use Test::More tests => 23;

use Log::Log4perl;
Log::Log4perl->easy_init( { level   => 'ERROR' } );

# diag "LOAD MODULE\n";

BEGIN {
    use_ok( 'Connector::Proxy::Config::Std' );
}

require_ok( 'Connector::Proxy::Config::Std' );


# diag "Connector::Proxy::Config::Std tests\n";
###########################################################################
my $conn = Connector::Proxy::Config::Std->new(
    {
	LOCATION  => 't/config/config.ini',
	PREFIX    => 'test',
    });

is($conn->get('abc'), '1111');
is($conn->get('def'), '2222');

is($conn->get('nonexistent'), undef);

# try full path access
is($conn->PREFIX(''), '');

# and repeat above tests
is($conn->get('test.entry.foo'), '1234');
is($conn->get('test.entry.bar'), '5678');

# diag "Test get_meta functionality\n";
is($conn->get_meta('')->{TYPE}, 'connector', 'Toplevel');
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
#a.very.long.path
ok ($conn->exists('test.entry'), 'Section Exists');
ok ($conn->exists('test.entry.foo'), 'Node Exists');
ok ($conn->exists( [ 'test', 'entry', 'foo' ] ), 'Node Exists Array');
ok (!$conn->exists('test.noentry'), 'Not exists');


