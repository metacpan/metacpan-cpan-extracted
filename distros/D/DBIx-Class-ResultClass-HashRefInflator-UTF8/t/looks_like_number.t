use strict;
use warnings;
use Scalar::Util qw( looks_like_number );

use Test::More tests => 7;

my @CASES = (
    { value => undef, number => 0 },
    { value => {}, number => 0 },
    { value => [], number => 0 },
    { value => "", number => 0 },
    { value => "45b", number => 0 },
    { value => "45", number => 1 },
    { value => 45, number => 1 },
);

for ( @CASES ) {
    my $res = looks_like_number( $_->{value} );
    if ( $_->{number} ) {
        ok( $res, "$_->{value} is number" );
    }
    else {
        ok( !$res, ( $_->{value} // "undef" ). " is not number" );
    }
}
