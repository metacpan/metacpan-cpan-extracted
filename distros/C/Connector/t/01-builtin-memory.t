# Tests for Connector::Builtin::Static
#

use strict;
use warnings;
use English;

use Test::More tests => 18;

use Log::Log4perl;
Log::Log4perl->easy_init( { level   => 'ERROR' } );

# diag "LOAD MODULE\n";

BEGIN {
    use_ok( 'Connector::Builtin::Memory' );
    use_ok( 'Connector::Builtin::Static' );
}

require_ok( 'Connector::Builtin::Memory' );
require_ok( 'Connector::Builtin::Static' );

# diag "Connector::Proxy::Static tests\n";
###########################################################################
my $conn = Connector::Builtin::Memory->new(
    {
    });


$conn->set('bar', '1234');
$conn->set('foo', '4567');

$conn->set('use.hash', { foo => 1, bar => 2});
$conn->set('use.list', [ 'foo','baz' ] );

is( $conn->get('bar'), '1234');
is( $conn->get('foo'), '4567');

is( $conn->get_meta('use.hash')->{TYPE}, 'hash' );
is( $conn->get_meta('use.list')->{TYPE}, 'list' );
is_deeply( [ $conn->get_list('use.list') ], [ 'foo','baz' ] );

# Top Level
is( $conn->get_meta('')->{TYPE}, 'hash' );

my @keys = $conn->get_keys('');
@keys = sort @keys;
is_deeply( \@keys, [ 'bar','foo','use' ] );

ok ($conn->exists(''), 'Base exists');
ok ($conn->exists('foo'), 'Node Exists');
ok ($conn->exists( [ 'foo' ] ), 'Node Exists Array');
ok (!$conn->exists('baz'), 'Not exists');

$conn->set('bar', undef);
ok (!$conn->exists('bar'), 'Not exists after delete');

my $sub = Connector::Builtin::Static->new({
    LOCATION => "foo"
});
is( $sub->get(''), 'foo' );
$conn->set('bar', $sub);

is($conn->get_meta('bar')->{TYPE}, 'connector');
