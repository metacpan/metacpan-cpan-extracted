use Test::More tests => 20;

use strict;
use warnings;

use Config::PFiles::Path;

sub test {
    my ( $method, $pfiles, $dirs, @exp ) = @_;

    my %exp;
    @exp{qw( RW RO)} = @exp;

    my $path = Config::PFiles::Path->new( $pfiles );

    $pfiles ||= "''";
    foreach my $set ( qw( RW RO ) )
    {
	$path->$method( $set, @$dirs );
	is_deeply( [ $path->extract( $set )  ], $exp{$set}, "$method ($set): $pfiles" )
    }
}

#------------
# append

# empty paths
test( append => undef, [ qw( a b ) ], [ qw( a b ) ], [ qw( a b ) ] );

# non-empty paths
test( append => 'd;e', [ qw( a b ) ], [ qw( d a b ) ], [ qw( e a b ) ] );

#------------
# prepend

# empty paths
test( prepend => undef, [ qw( a b ) ], [ qw( a b ) ], [ qw( a b ) ] );

# non-empty paths
test( prepend => 'd;e', [ qw( a b ) ], [ qw( a b d ) ], [ qw( a b e ) ] );

#------------
# replace

# empty paths
test( replace => undef, [ qw( a b ) ], [ qw( a b ) ], [ qw( a b ) ] );

# non-empty paths
test( replace => 'd;e', [ qw( a b ) ], [ qw( a b ) ], [ qw( a b ) ] );

# test return
{
  my $path = Config::PFiles::Path->new( 'a:b;c:d' );
  my @ro = $path->replace( RO => qw( e f ) );
  is_deeply( [@ro], [ qw( c d ) ], "replace (RO): return" );

  my @rw = $path->replace( RW => qw( g h ) );
  is_deeply( [@rw], [ qw( a b ) ], "replace (RW): return" );

}

#------------
# remove

# empty paths
test( remove => undef, [], [], [] );

# non-empty paths
test( remove => 'd;e', [], [], [] );

# test return
{
  my $path = Config::PFiles::Path->new( 'a:b;c:d' );
  my @ro = $path->remove( 'RO' );
  is_deeply( [@ro], [ qw( c d ) ], "remove (RO): return" );

  my @rw = $path->remove( 'RW' );
  is_deeply( [@rw], [ qw( a b ) ], "remove (RW): return" );

}
