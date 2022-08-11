# Tests for Connector::Builtin::Null
#

use strict;
use warnings;
use English;

use Test::More tests => 16;

use Log::Log4perl;
Log::Log4perl->easy_init( { level   => 'ERROR' } );

BEGIN {
    use_ok( 'Connector::Builtin::Null' );
}

require_ok( 'Connector::Builtin::Null' );

my $conn = Connector::Builtin::Null->new();

is( $conn->get('any.path'), undef);
is( $conn->get(['any','path']), undef);

is( $conn->get_size('any.path'), 0);
is( $conn->get_size(['any','path']), 0);

is( $conn->exists('any.path'), 0);
is( $conn->exists(['any','path']), 0);

is_deeply( [$conn->get_keys('any.path')], []);
is_deeply( [$conn->get_keys(['any','path'])], []);

is( $conn->get_hash('any.path'), undef);
is( $conn->get_hash(['any','path']), undef);

is_deeply( [$conn->get_list('any.path')], []);
is_deeply( [$conn->get_list(['any','path'])], []);

ok( $conn->set('any.path', {}));
ok( $conn->set(['any','path'], {}));
