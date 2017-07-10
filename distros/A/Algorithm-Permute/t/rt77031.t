#!perl

use strict;
use warnings;
use Test::More;

use Algorithm::Permute;

my $p = Algorithm::Permute->new( [ 'a' .. 'd' ], 2 );

my $i = 0;
while ( my @res = $p->peek ) {
    my @next = $p->next;
    diag(
        sprintf( "peek: %s, next: %s", join( ' ', @res ), join( ' ', @next ) )
    );
    $i++;
}

is( $i, 12 );

done_testing;
