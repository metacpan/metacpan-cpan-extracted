#!perl

use Data::Frame::Setup;

use PDL::Core qw(pdl);

use Test2::V0;
use Test2::Tools::DataFrame;
use Test2::Tools::PDL;

use Test::File::ShareDir -share =>
  { -dist => { 'Alt-Data-Frame-ButMore' => 'data-raw' } };

use Data::Frame;
use Data::Frame::Examples qw(mtcars);

my $mtcars = mtcars();

subtest transform => sub {
    my $df =
      Data::Frame->new(
        columns => [ a => pdl( [ 0 .. 9 ] ), b => pdl( [ 0 .. 9 ] ) / 10 ] );

    dataframe_is(
        $df->transform( sub { my ($col) = @_; $col * 2 } ),
        Data::Frame->new(
            columns =>
              [ a => pdl( [ 0 .. 9 ] ) * 2, b => pdl( [ 0 .. 9 ] ) / 10 * 2 ]
        ),
        '$df->transform($coderef)'
    );

    dataframe_is(
        $mtcars->transform(
            {
                kpg => sub {
                    my ( $col, $df ) = @_;
                    return $df->at('mpg') * 1.609;
                }
            }
        ),
        do {
            my $x = $mtcars->copy;
            $x->set( kpg => $mtcars->at('mpg') * 1.609 );
            $x;
        },
        '$df->transform($hashref)'
    );
    dataframe_is(
        $mtcars->transform(
            [
                kpg => sub {
                    my ( $col, $df ) = @_;
                    return $df->at('mpg') * 1.609;
                }
            ]
        ),
        do {
            my $x = $mtcars->copy;
            $x->set( kpg => $mtcars->at('mpg') * 1.609 );
            $x;
        },
        '$df->transform($arrayref)'
    );

    dataframe_is(
        $mtcars->transform(
            {
                kpg => sub {
                    my ( $col, $df ) = @_;
                    return $df->at('mpg') * 1.609;
                },
                mpg => undef,
                cyl => sub { undef }, 
            }
        ),
        do {
            my $x = $mtcars->copy;
            $x->set( kpg => $mtcars->at('mpg') * 1.609 );
            $x->delete('mpg');
            $x->delete('cyl');
            $x;
        },
        '$df->transform($hashref) with deleting'
    );

    dataframe_is(
        $mtcars->transform(
            [
                kpg => sub {
                    my ( $col, $df ) = @_;
                    return $df->at('mpg') * 1.609;
                },
                mpg => undef,
                cyl => sub { undef }, 
            ]
        ),
        do {
            my $x = $mtcars->copy;
            $x->set( kpg => $mtcars->at('mpg') * 1.609 );
            $x->delete('mpg');
            $x->delete('cyl');
            $x;
        },
        '$df->transform($arrayref) with deleting'
    );
    
};

subtest sort => sub {
    my $df_uniq = $mtcars->select_columns( [qw(vs am)] )->uniq;
    dataframe_is(
        $df_uniq,
        Data::Frame->new(
            columns => [
                vs => pdl( [ 0, 1, 1, 0 ] ),
                am => pdl( [ 1, 1, 0, 0 ] )
            ],
            row_names => [
                'Mazda RX4',
                'Datsun 710',
                'Hornet 4 Drive',
                'Hornet Sportabout',
            ],
        ),
        '$df->uniq()'
    );

    my $df_sorted1 = $df_uniq->sort( [qw(vs am)] );
    dataframe_is(
        $df_sorted1,
        Data::Frame->new(
            columns => [
                vs => pdl( [ 0, 0, 1, 1 ] ),
                am => pdl( [ 0, 1, 0, 1 ] )
            ],
            row_names => [
                'Hornet Sportabout',
                'Mazda RX4',
                'Hornet 4 Drive',
                'Datsun 710',
            ],
        ),
        '$df->sort($by)'
    );
    dataframe_is( $df_uniq->sort( [qw(vs am)], true ),
        $df_sorted1, '$df->sort($by, true)' );
    dataframe_is( $df_uniq->sort( [qw(vs am)], [ 1, 1 ] ),
        $df_sorted1, '$df->sort($by, $aref)' );

    my $df_sorted2 = $df_uniq->sort( [qw(vs am)], false );

    dataframe_is(
        $df_sorted2,
        Data::Frame->new(
            columns => [
                vs => pdl( [ 1, 1, 0, 0 ] ),
                am => pdl( [ 1, 0, 1, 0 ] )
            ],
            row_names => [
                'Datsun 710',
                'Hornet 4 Drive',
                'Mazda RX4',
                'Hornet Sportabout',
            ],
        ),
        '$df->sort($by, false)'
    );

    dataframe_is( $df_uniq->sort( [qw(vs am)], [ 0, 0 ] ),
        $df_sorted2, '$df->sort($by, $aref)' );
    dataframe_is( $df_uniq->sort( [qw(vs am)], pdl( [ 0, 0 ] ) ),
        $df_sorted2, '$df->sort($by, $pdl)' );
};

subtest compare => sub {
    my $df1 = Data::Frame->new(
        columns => [
            x => pdl( 1, 2, 3 ),
            y => PDL::SV->new( [qw(foo bar baz])] ),
        ]
    );

    my $df2 = Data::Frame->new(
        columns => [
            x => pdl( 1, 1, 3 ),
            y => PDL::SV->new( [qw(foo bar qux])] ),
        ]
    );

    dataframe_is(
        ( $df1 == $df2 ),
        Data::Frame->new(
            columns => [ x => pdl( 1, 0, 1 ), y => pdl( 1, 1, 0 ) ]
        ),
        'overload ==',
    );
    dataframe_is(
        ( $df1 != $df2 ),
        Data::Frame->new(
            columns => [ x => pdl( 0, 1, 0 ), y => pdl( 0, 0, 1 ) ]
        ),
        'overload !=',
    );
    dataframe_is(
        ( $df1 < $df2 ),
        Data::Frame->new(
            columns => [ x => pdl( 0, 0, 0 ), y => pdl( 0, 0, 1 ) ]
        ),
        'overload <',
    );
    dataframe_is(
        ( $df1 <= $df2 ),
        Data::Frame->new(
            columns => [ x => pdl( 1, 0, 1 ), y => pdl( 1, 1, 1 ) ]
        ),
        'overload <=',
    );
    dataframe_is(
        ( $df1 > $df2 ),
        Data::Frame->new(
            columns => [ x => pdl( 0, 1, 0 ), y => pdl( 0, 0, 0 ) ]
        ),
        'overload >',
    );
    dataframe_is(
        ( $df1 >= $df2 ),
        Data::Frame->new(
            columns => [ x => pdl( 1, 1, 1 ), y => pdl( 1, 1, 0 ) ]
        ),
        'overload >=',
    );

    pdl_is(
        ( $df1 != $df2 )->which(),
        pdl( [ [ 1, 0 ], [ 2, 1 ] ] ),
        '$df->which()'
    );
};

subtest compare_df_with_bad => sub {
    my $df1 = Data::Frame->new(
        columns => [
            x => pdl( [ 1, 2, 3, "nan" ] )->setnantobad,
            y => PDL::SV->new( [qw(foo bar baz qux])] )->setbadat(1),
        ]
    );

    my $df2 = Data::Frame->new(
        columns => [
            x => pdl( [ 1, 1, "nan", "nan" ] )->setnantobad,
            y =>
              PDL::SV->new( [qw(foo bar qux qux])] )->setbadat(1)->setbadat(3),
        ]
    );

    my $diff = ( $df1 != $df2 );

    dataframe_is(
        $diff->both_bad,
        Data::Frame->new(
            columns => [
                x => pdl( 0, 0, 0, 1 ),
                y => pdl( 0, 1, 0, 0 )
            ]
        ),
        '$diff->both_bad'
    );

    dataframe_is(
        $diff,
        Data::Frame->new(
            columns => [
                x => pdl( 0, 1,     'nan', 'nan' )->setnantobad,
                y => pdl( 0, 'nan', 1,     'nan' )->setnantobad,
            ]
        ),
        'overload !=',
    );

    pdl_is( $diff->which(), pdl( [ [ 1, 0 ], [ 2, 1 ] ] ), '$df->which()' );

    pdl_is(
        $diff->which( bad_to_val => 0 ),
        pdl( [ [ 1, 0 ], [ 2, 1 ] ] ),
        '$df->which(bad_to_val => 0)'
    );

    pdl_is(
        $diff->which( bad_to_val => 1 ),
        pdl( [ [ 1, 0 ], [ 2, 0 ], [ 2, 1 ], [ 3, 1 ] ] ),
        '$df->which(bad_to_val => 1)'
    );

};

done_testing;
