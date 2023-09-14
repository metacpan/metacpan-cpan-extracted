# Tests for Connector::Builtin::Inline

use strict;
use warnings;
use English;

use Test::More tests => 14;

use Log::Log4perl;
Log::Log4perl->easy_init( { level   => 'ERROR' } );

BEGIN {
    use_ok( 'Connector::Builtin::Inline' );
}

require_ok( 'Connector::Builtin::Inline' );

my $conn = Connector::Builtin::Inline->new(
    data => {
        foo => {
            bar => 'baz',
            foo => ['baz']
        }
    }
);

is( $conn->get('foo.bar'), 'baz' );
is( $conn->get(['foo','bar']),'baz');
is( $conn->get(['foo','baz']), undef);
is( $conn->get(['bar']), undef);

is( $conn->get_size('foo.foo'), 1);
is( $conn->get_size(['foo','nofoo']), 0);

is( $conn->exists('foo.bar'), 1);
is( $conn->exists(['foo','nofoo']), '');

is_deeply( [sort $conn->get_keys('foo')], ['bar','foo']);
is_deeply( $conn->get_hash('foo'), { bar => 'baz', foo => ['baz'] });

ok( $conn->set(['foo','baz'], 'bar' ));
ok( $conn->get(['foo','baz'], 'bar' ));
