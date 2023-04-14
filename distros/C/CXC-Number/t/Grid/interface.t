#! perl

use Test2::V0;
use Test2::V0 qw( meta );
use Test::Lib;

use CXC::Number::Grid;

use constant Grid => 'CXC::Number::Grid';

subtest sequence => sub {

    require CXC::Number::Sequence;

    my $sequence = CXC::Number::Sequence->build( fixed => elements => [ 0, 1, 2, 3, 4 ] );
    my $grid;

    ok( lives { $grid = Grid->new( edges => $sequence ) } )
      or diag $@;
    is(
        $grid,
        object {
            call edges => [ 0, 1, 2, 3, 4, ]
        },
    );

};

subtest bignum => sub {

    my $grid;

    ok(
        lives {
            $grid = Grid->new(
                edges   => [ 0 .. 11 ],
                include => [ ( 1, 0 ) x 5, 1 ],
            )->bignum
        } ) or diag $@;

    my $isa_bignum          = meta { prop blessed => 'Math::BigFloat' };
    my $isa_array_of_bignum = array { all_items( $isa_bignum ); etc; };

    is( $grid->min,     $isa_bignum,          'min' );
    is( $grid->max,     $isa_bignum,          'max' );
    is( $grid->spacing, $isa_array_of_bignum, 'spacing' );
    is( $grid->edges,   $isa_array_of_bignum, 'edges' );
    is( $grid->include, [ ( 1, 0 ) x 5, 1 ],  'include' );

};

subtest PDL => sub {

  SKIP: {
        skip( q[PDL isn't installed; skipping tests] )
          unless eval "require PDL; 1;";

        my $pdl = sub { PDL->pdl( @_ ) };

        my $grid;

        ok( lives { $grid = Grid->new( edges => [ 0 .. 11 ], include => [ ( 1, 0 ) x 5, 1 ] )->pdl } )
          or diag $@;

        my $isa_PDL = meta { prop blessed => 'PDL' };

        isnt( $grid->min, $isa_PDL, 'min' ) or bail_out;
        isnt( $grid->max, $isa_PDL, 'max' ) or bail_out;

        is( $grid->spacing,        $isa_PDL, 'spacing' ) or bail_out;
        is( $grid->spacing->nelem, 11,       'spacing has correct shape' );

        is( $grid->edges,        $isa_PDL,    'edges' ) or bail_out;
        is( $grid->edges->nelem, 12,          'edges has correct shape' );
        is( $grid->edges->unpdl, [ 0 .. 11 ], 'edges value' );

        is( $grid->include,        $isa_PDL,            'include' ) or bail_out;
        is( $grid->include->nelem, 11,                  'include has correct shape' );
        is( $grid->include->unpdl, [ ( 1, 0 ) x 5, 1 ], 'include value' );

    }

};

subtest 'bounds' => sub {

    subtest 'mismatched include' => sub {

        like(
            dies {
                Grid->new( bounds => [ 0, 1 ], include => [] )
            },
            qr/does not match number of bounds/
        );

    };

    subtest 'bad bounds' => sub {

        like(
            dies {
                Grid->new( bounds => [1] )
            },
            qr/even number of elements/
        );

    };

    subtest 'no bounds' => sub {

        like(
            dies {
                Grid->new( bounds => [] )
            },
            qr/non-empty/
        );

    };

    subtest 'contiguous bins' => sub {

        my @bounds = ( ( 1, 2 ), ( 2, 4 ), ( 4, 7 ), ( 7, 9 ) );

        subtest 'with include' => sub {
            my @include = ( 0, 0, 0, 0 );
            my $grid    = Grid->new( bounds => \@bounds, include => \@include );
            is(
                $grid,
                object {
                    call edges => [ 1, 2, 4, 7, 9 ];
                    call include => [ 0, 0, 0, 0 ];
                } );
        };
        subtest 'without include' => sub {
            my $grid = Grid->new( bounds => \@bounds );
            is(
                $grid,
                object {
                    call edges => [ 1, 2, 4, 7, 9 ];
                    call include => [ 1, 1, 1, 1 ];
                } );
        }
    };

    subtest 'interstitial bins' => sub {

        my @bounds = ( ( 1, 2 ), ( 2, 3 ), ( 4, 5 ), ( 7, 9 ) );

        subtest 'with include' => sub {
            my @include = ( 1, 1, 0, 1 );
            my $grid    = Grid->new( bounds => \@bounds, include => \@include );
            is(
                $grid,
                object {
                    call edges => [ 1, 2, 3, 4, 5, 7, 9 ];
                    call include => [ 1, 1, 0, 0, 0, 1 ];
                } );
        };

        subtest 'without include' => sub {
            my $grid = Grid->new( bounds => \@bounds );
            is(
                $grid,
                object {
                    call edges => [ 1, 2, 3, 4, 5, 7, 9 ];
                    call include => [ 1, 1, 0, 1, 0, 1 ];
                } );
        };

    };

};

done_testing;
