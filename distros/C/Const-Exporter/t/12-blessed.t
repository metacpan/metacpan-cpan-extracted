use Test::Most;
use if $ENV{RELEASE_TESTING}, 'Test::Warnings';

use Hash::Objectify;

use Const::Exporter

    default => [

    '$foo' => objectify { bar => 'baz' },

    ];

isa_ok( $foo, 'Hash::Objectified' );
can_ok( $foo, 'bar' );

is( $foo->bar, 'baz', 'baz method' );

done_testing;
