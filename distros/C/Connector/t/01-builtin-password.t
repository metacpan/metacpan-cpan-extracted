# Tests for Connector::Builtin::Authentication::Password
#

use strict;
use warnings;
use English;
use Log::Log4perl qw(:easy);
use Test::More tests => 15;

# diag "LOAD MODULE\n";

BEGIN {
    use_ok( 'Connector::Builtin::Authentication::Password' );
}

require_ok( 'Connector::Builtin::Authentication::Password' );

Log::Log4perl->easy_init( { level   => 'FATAL' } );

# diag "Connector::Proxy::Static tests\n";
###########################################################################
my $conn = Connector::Builtin::Authentication::Password->new(
    {
	LOCATION  => 't/config/password.txt',
    });

ok($conn->get('foo', {password => 'nofoo'} ), 'match for foo');
ok($conn->get('bar', {password => 'nobar'} ), 'match for bar');
ok(!$conn->get('foo', {password => 'wrong'} ), 'wrong pass foo');
ok(!$conn->get('fo', {password => 'wrong'} ), 'invalid user fo');
ok(!$conn->get('foo2', {password => 'wrong'} ), 'invalid user foo2');

ok(!defined $conn->get('foo:', {password => 'wrong'}), 'invalid char in user');

eval { $conn->get('bar'); };
ok($EVAL_ERROR ne '', 'no password');

is($conn->get_meta()->{TYPE}, 'connector', 'Identifies as connector');
is($conn->get_meta('foo')->{TYPE}, 'scalar', 'Identifies as scalar');

ok ($conn->exists(''), 'Connector exists');
ok ($conn->exists('foo'), 'Node Exists');
ok ($conn->exists( [ 'foo' ] ), 'Node Exists Array');
ok (!$conn->exists('baz'), 'Not exists');
