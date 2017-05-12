use Test::More tests => 16;

use strict;
use warnings;

use Config::PFiles::Path;

sub test {

    my ( $pfiles, $method, $set, $dirs, $exp ) = @_;

    delete $ENV{PFILES};
    $ENV{PFILES} = $pfiles if defined $pfiles;

    
    $pfiles ||= "''";
    Config::PFiles::Path->$method( $set=> @$dirs );
    is( $ENV{PFILES}, $exp, "$method ($set): $pfiles => $ENV{PFILES}" );
}

##########################
# test mutators

# other tests test the whole functionality so just make sure mutators
# are called correctly

test( undef, append => RO => [ 'a' ], ';a' );
test( undef, append => RW => [ 'a' ], 'a'  );

test( ';b' , prepend => RO => [ 'a' ], ';a:b' );
test( 'a;' , prepend => RW => [ 'c' ], 'c:a' );
test( 'a' , prepend => RW => [ 'c' ], 'c:a' );

test( 'a;b', replace => RO => ['d'], 'a;d' );
test( 'a;b', replace => RW => ['d'], 'd;b' );

# test return
{
    $ENV{PFILES} = 'a:b;c:d';
    my @ro = Config::PFiles::Path->replace( RO => qw( e f ) );
    is_deeply( [@ro], [ qw( c d ) ], "replace (RO): return" );

    my @rw = Config::PFiles::Path->replace( RW => qw( g h ) );
    is_deeply( [@rw], [ qw( a b ) ], "replace (RW): return" );

}


test( 'a;b', remove => RO => [], 'a' );
test( 'a;b', remove => RW => [], ';b' );

# test return
{
    $ENV{PFILES} = 'a:b;c:d';
    my @ro = Config::PFiles::Path->remove( 'RO' );
    is_deeply( [@ro], [ qw( c d ) ], "remove (RO): return" );

    my @rw = Config::PFiles::Path->remove( 'RW' );
    is_deeply( [@rw], [ qw( a b ) ], "remove (RW): return" );

}

##########################
# extract

{
    $ENV{PFILES} = 'a:b;c:d';
    my @ro = Config::PFiles::Path->extract( 'RO' );
    is_deeply( [@ro], [ qw( c d ) ], "extract (RO)" );

    my @rw = Config::PFiles::Path->extract( 'RW' );
    is_deeply( [@rw], [ qw( a b ) ], "extract (RW)" );

}

##########################
# export (kind of useless)

$ENV{PFILES} = 'a:b;c:d';
is( Config::PFiles::Path->export, 'a:b;c:d', "export" );

