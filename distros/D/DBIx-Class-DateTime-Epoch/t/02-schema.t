use strict;
use warnings;

use lib 't/lib';

use Test::More tests => 19;

use DBICx::TestDatabase;
use DateTime;
my $schema = DBICx::TestDatabase->new( 'MySchema' );

my $rs = $schema->resultset( 'Foo' );

{
    my $now = DateTime->now;
    my $epoch = $now->epoch;

    $schema->populate( 'Foo', [ [ qw( id bar baz creation_time modification_time dt ) ], [ 1, ( $epoch ) x 4, $now ] ] );

    {
        my $row = $rs->find( 1 );

        isa_ok( $row->bar, 'DateTime' );
        isa_ok( $row->baz, 'DateTime' );
        isa_ok( $row->dt, 'DateTime' );
        ok( $row->bar == $now, 'inflate: epoch as int' ); 
        ok( $row->baz == $now, 'inflate: epoch as varchar' ); 
        ok( $row->dt == $now, 'inflate: regular datetime column' ); 
    }

    {
        $rs->create( { bar => $now, baz => $now, dt => $now } );
        my $row = $rs->find( 2 );

        isa_ok( $row->bar, 'DateTime' );
        isa_ok( $row->baz, 'DateTime' );
        isa_ok( $row->dt, 'DateTime' );
        is( $row->get_column( 'bar' ), $epoch, 'deflate: epoch as int' );
        is( $row->get_column( 'baz' ), $epoch, 'deflate: epoch as varchar' );
        is( $row->get_column( 'dt' ), join( ' ', $now->ymd, $now->hms ), 'deflate: regular datetime column' );

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
