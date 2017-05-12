# Base tests for Connector
#

use strict;
use warnings;
use English;
use Data::Dumper;

use Test::More tests => 27;

use Log::Log4perl;
Log::Log4perl->easy_init( { level   => 'ERROR' } );

# diag "LOAD MODULE\n";

BEGIN {
    use_ok( 'Connector' ); 
}

require_ok( 'Connector' );

my $conn = Connector->new(
    {
	LOCATION  => 'n/a',
    });

ok(defined $conn, 'Connector constructor');

#################################################################
# tests for path building
# diag('_build_path tests with empty PREFIX, without arguments');

# scalar return no longer supported
#is($conn->_build_path(), (), '_build_path: no arguments');
#is($conn->_build_path(''), (), '_build_path: empty scalar');
#is($conn->_build_path([]), (), '_build_path: empty arrayref');
is_deeply( [ $conn->_build_path() ], [], '_build_path in array context: no arguments');
is_deeply( [ $conn->_build_path('') ], [], '_build_path in array context: empty scalar');
is_deeply( [ $conn->_build_path([]) ], [], '_build_path in array context: empty arrayref');

# diag('_build_path tests with empty PREFIX, with arguments');
is_deeply( [ $conn->_build_path('foo.bar.baz') ], [ ('foo', 'bar','baz' )], '_build_path: string path');
is_deeply( [ $conn->_build_path([ 'foo', 'bar', 'baz' ]) ], [ ('foo', 'bar','baz' )], '_build_path: arrayref');

# diag('_build_path tests with empty PREFIX, with compound arguments');
#is($conn->_build_path([ 'foo', 'bar' ], 'baz.bla'), 'foo.bar.baz.bla', '_build_path in scalar context: compound expression');
is_deeply( [ $conn->_build_path([ ('foo', 'bar' ), ('baz','bla' ) ] ) ], [ 'foo', 'bar', 'baz','bla' ], '_build_path: compound expression');

# path element with delimiter
is_deeply( [ $conn->_build_path([ 'foo', 'bar', 'baz.bla' ] ) ], [ 'foo', 'bar', 'baz.bla' ], '_build_path: delimiter in path');


# accessor tests
# diag('Accessor tests');
$conn->PREFIX('this.is.a.test');
is($conn->PREFIX(), 'this.is.a.test', 'Accessor: PREFIX');
is_deeply( $conn->_prefix_path , [ 'this', 'is', 'a', 'test' ], 'internal prefix');

# diag('Tests with PREFIX');
# building paths with prefix
is_deeply( [ $conn->_build_path() ], [  ], '_build_path: as array');

is_deeply( [ $conn->_build_path_with_prefix() ], [ 'this', 'is', 'a', 'test' ], '_build_path_with_prefix: as array');

is_deeply( [ $conn->_build_path('abc123') ] , [ 'abc123' ], '_build_path: as scalar, with scalar argument');
is_deeply( [ $conn->_build_path_with_prefix('abc123') ], [ 'this','is','a','test','abc123' ], '_build_path_with_prefix: as scalar, with scalar argument');
is_deeply( [ $conn->_build_path('abc123.def456') ], [ 'abc123','def456' ], '_build_path: as scalar, with deep scalar argument');
is_deeply( [ $conn->_build_path_with_prefix('abc123.def456') ], [ 'this','is','a','test','abc123','def456' ], '_build_path_with_prefix: as scalar, with deep scalar argument');

# with prefix and delimiter in string
is_deeply( [ $conn->_build_path([ 'abc123','def.456' ] ) ],  [ 'abc123','def.456' ], '_build_path: delimiter in path');
is_deeply( [ $conn->_build_path_with_prefix([ 'foo', 'bar', 'baz.bla' ] ) ],  [ 'this','is','a','test','foo','bar','baz.bla' ], '_build_path: delimiter in path');

# Delimiter in prefix
$conn->PREFIX( ['this','is','a.test' ] );
is_deeply( $conn->_prefix_path , [ 'this', 'is', 'a.test' ], 'prefix with delimiter');
is_deeply( [ $conn->_build_path([ 'abc123','def.456' ] ) ],  [ 'abc123','def.456' ], '_build_path: delimiter in path and prefix');
is_deeply( [ $conn->_build_path_with_prefix([ 'foo', 'bar', 'baz.bla' ] ) ],  [ 'this','is','a.test','foo','bar','baz.bla' ], '_build_path_with_prefix: delimiter in path and prefix');

# Test RECURSEPATH
$conn->RECURSEPATH(1);
$conn->PREFIX(['this.is','a.test']);
is_deeply( $conn->_prefix_path , [ 'this', 'is', 'a', 'test' ], 'internal prefix');
 
is_deeply( [ $conn->_build_path( [ 'abc123','def.456' ]) ], [ 'abc123','def','456' ], 'prefix with delimiter');
is_deeply( [ $conn->_build_path_with_prefix( [ 'abc123','def.456' ]) ], [ 'this', 'is', 'a', 'test', 'abc123','def','456' ], 'prefix with delimiter');
is( $conn->_build_path( [ 'abc123','def.456' ]), 'abc123.def.456', 'prefix with delimiter as scalar');


