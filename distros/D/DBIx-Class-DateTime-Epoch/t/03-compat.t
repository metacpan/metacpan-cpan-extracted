use strict;
use warnings;

use lib 't/lib';

use Test::More tests => 15;

use DBICx::TestDatabase;
use DateTime;
my $schema = DBICx::TestDatabase->new( 'MySchema' );

my $rs = $schema->resultset( 'FooCompat' );

{
    my $now = DateTime->now;
    my $epoch = $now->epoch;

    $schema->populate( 'FooCompat', [ [ qw( id bar baz creation_time modification_time ) ], [ 1, ( $epoch ) x 4 ] ] );

    {
        my $row = $rs->find( 1 );

        isa_ok( $row->bar, 'DateTime' );
        isa_ok( $row->baz, 'DateTime' );
        ok( $row->bar == $now, 'inflate: epoch as int' ); 
        ok( $row->baz == $now, 'inflate: epoch as varchar' ); 
    }

    {
        $rs->create( { bar => $now, baz => $now } );
        my $row = $rs->find( 2 );

        isa_ok( $row->bar, 'DateTime' );
        isa_ok( $row->baz, 'DateTime' );
        is( $row->get_column( 'bar' ), $epoch, 'deflate: epoch as int' );
        is( $row->get_column( 'baz' ), $epoch, 'deflate: epoch as varchar' );

        # courtesy of TimeStamp
        isa_ok( $row->creation_time, 'DateTime' ); # courtesy of TimeStamp
        isa_ok( $row->modification_time, 'DateTime' );
        like( $row->get_column( 'creation_time' ), qr/^\d+$/, 'TimeStamp as epoch' );
        like( $row->get_column( 'modification_time' ), qr/^\d+$/, 'TimeStamp as epoch' );

        my $mtime = $row->modification_time;
        sleep( 1 );
        $row->update( { name => 'test' } );

        $row = $rs->find( 2 );
        isa_ok( $row->modification_time, 'DateTime' );
        like( $row->get_column( 'modification_time' ), qr/^\d+$/, 'TimeStamp as epoch' );
        ok( $row->modification_time > $mtime, 'mtime column was updated' );
    }
}
