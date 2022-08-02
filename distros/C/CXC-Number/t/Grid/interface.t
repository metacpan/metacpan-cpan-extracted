#! perl

use Test2::V0;
use Test2::V0 qw( meta );
use Test::Lib;
use CXC::Number::Grid;

sub Grid { join( '::', 'CXC::Number::Grid', @_ ) }

subtest sequence => sub {

    require CXC::Number::Sequence;

    my $sequence
      = CXC::Number::Sequence->build( fixed => elements => [ 0, 1, 2, 3, 4 ] );
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

    ok( lives { $grid = Grid->new( edges => [ 0 .. 11 ] )->bignum } )
      or diag $@;

    my $isa_bignum          = meta { prop blessed => 'Math::BigFloat' };
    my $isa_array_of_bignum = array { all_items( $isa_bignum ); etc; };

    is( $grid->min,     $isa_bignum,          'min' );
    is( $grid->max,     $isa_bignum,          'max' );
    is( $grid->spacing, $isa_array_of_bignum, 'spacing' );
    is( $grid->edges,   $isa_array_of_bignum, 'edges' );

};

subtest PDL => sub {

  SKIP: {
        skip( q[PDL isn't installed; skipping tests] )
          unless eval "require PDL; 1;";

        my $pdl = sub { PDL->pdl( @_ ) };

        my $grid;

        ok( lives { $grid = Grid->new( edges => [ 0 .. 11 ] )->pdl } )
          or diag $@;

        my $isa_PDL = meta { prop blessed => 'PDL' };

        isnt( $grid->min, $isa_PDL, 'min' );
        isnt( $grid->max, $isa_PDL, 'max' );

        is( $grid->spacing,        $isa_PDL, 'spacing' );
        is( $grid->spacing->nelem, 11,       'spacing has correct shape' );

        is( $grid->edges,        $isa_PDL, 'edges' );
        is( $grid->edges->nelem, 12,       'edges has correct shape' );
    }

};

done_testing;
