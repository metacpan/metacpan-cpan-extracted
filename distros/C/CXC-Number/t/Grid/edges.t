#! perl

use Test2::V0;
use CXC::Number::Grid qw( join_n );

use constant Grid => 'CXC::Number::Grid';

sub Failure { join( '::', 'CXC::Number::Grid::Failure', @_ ) }

is(
    Grid->new( edges => [ 0 .. 11 ] ),
    object {
        prop blessed   => Grid;
        call min       => 0;
        call max       => 11;
        call nbins     => 11;
        call nedges    => 12;
        call edges     => [ 0 .. 11 ];
        call bin_edges => [ 0 .. 11 ];
    },
    'baseline'
);

subtest constraints => sub {

    subtest 'out of order' => sub {
        my $err = dies { Grid->new( edges => [ 1, 0, 2 ] ) };
        isa_ok( $err, 'Error::TypeTiny::Assertion' );
        like( $err, qr/array of monotonically increasing numbers/ );
    };

    subtest 'duplicate' => sub {
        my $err = dies { Grid->new( edges => [ 1, 1, 2 ] ) };
        isa_ok( $err, 'Error::TypeTiny::Assertion' );
        like( $err, qr/array of monotonically increasing numbers/ );
    };

    subtest 'not numbers' => sub {
        my $err = dies { Grid->new( edges => [ 'foo', 'bar' ] ) };
        isa_ok( $err, 'Error::TypeTiny::Assertion' );
        # $err stringifies via validate_explain?
        like( $err, qr/constrains .* with "BigNum"/ );
    };

    subtest 'empty grid' => sub {
        my $err = dies { Grid->new( edges => [] ) };
        isa_ok( $err, 'Error::TypeTiny::Assertion' );
        like( $err, qr/array length/ );
    };
};


done_testing;
