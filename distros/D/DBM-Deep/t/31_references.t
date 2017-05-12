use strict;
use warnings FATAL => 'all';

use Test::More;
use Test::Deep;
use Test::Exception;
use t::common qw( new_dbm );

use_ok( 'DBM::Deep' );
my $dbm_factory = new_dbm();
while ( my $dbm_maker = $dbm_factory->() ) {
    my $db = $dbm_maker->();

    my %hash = (
        foo => 1,
        bar => [ 1 .. 3 ],
        baz => { a => 42 },
    );

    $db->{hash} = \%hash;
    isa_ok( tied(%hash), 'DBM::Deep::Hash' );

    is( $db->{hash}{foo}, 1 );
    cmp_deeply( $db->{hash}{bar}, noclass([ 1 .. 3 ]) );
    cmp_deeply( $db->{hash}{baz}, noclass({ a => 42 }) );

    $hash{foo} = 2;
    is( $db->{hash}{foo}, 2 );

    $hash{bar}[1] = 90;
    is( $db->{hash}{bar}[1], 90 );

    $hash{baz}{b} = 33;
    is( $db->{hash}{baz}{b}, 33 );

    my @array = (
        1, [ 1 .. 3 ], { a => 42 },
    );

    $db->{array} = \@array;
    isa_ok( tied(@array), 'DBM::Deep::Array' );

    is( $db->{array}[0], 1 );
    cmp_deeply( $db->{array}[1], noclass([ 1 .. 3 ]) );
    cmp_deeply( $db->{array}[2], noclass({ a => 42 }) );

    $array[0] = 2;
    is( $db->{array}[0], 2 );

    $array[1][2] = 9;
    is( $db->{array}[1][2], 9 );

    $array[2]{b} = 'floober';
    is( $db->{array}[2]{b}, 'floober' );

    my %hash2 = ( abc => [ 1 .. 3 ] );
    $array[3] = \%hash2;

    $hash2{ def } = \%hash;
    is( $array[3]{def}{foo}, 2 );
}

done_testing;
