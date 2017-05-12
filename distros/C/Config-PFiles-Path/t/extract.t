#!perl

use Test::More tests => 14;

use strict;
use warnings;

use Config::PFiles::Path;


sub test {
    my ( $pfiles, @exp ) = @_;

    my %exp;
    @exp{qw( RW RO)} = @exp;

    my $path = Config::PFiles::Path->new( $pfiles );

    $pfiles ||= "''";
    is_deeply( [ $path->extract( $_ ) ], $exp{$_}, "$pfiles ($_)" )
      foreach qw( RW RO );
}


# empty paths
test( undef, [], [] );

# empty RO
test( 'a', ['a'], [] );
test( 'a;', ['a'], [] );

# empty RW
test( ';a', [], ['a'] );

# multiple entries
test( 'a:b;c:d', [qw(a b)], [qw(c d)] );

# multiple, empty RO
test( 'a:b;', [qw(a b)], [] );


# blank entries
test( ':a::b:;:c::d:', [qw(a b)], [qw(c d)] );
