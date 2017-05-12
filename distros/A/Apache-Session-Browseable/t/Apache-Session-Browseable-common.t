use Test::More;

plan tests => 3;

use_ok('Apache::Session::Browseable::_common');

my ( $a, $b ) = ( [qw(0 1 a)], [qw(0 1 a b)] );

ok( Apache::Session::Browseable::_common->_tabInTab( $a, $b ) );

ok( !Apache::Session::Browseable::_common->_tabInTab( $b, $a ) );

