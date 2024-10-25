#!perl

use Data::Frame::Setup;

use Data::Frame;
use Data::Frame::Indexer qw(:all);

use PDL::Core qw(pdl);
use PDL::SV ();

use Test2::V0;
use Test2::Tools::DataFrame;
use Test2::Tools::PDL;

subtest construction => sub {
    my $df = Data::Frame->new(
            columns => [ a => pdl( [ 0 .. 9 ] ),
                         b => pdl->new([1]),
                         c => PDL::SV->new([qw(foo)]),
            ] );
    ok( $df, 'for construction column length can be either max or 1' );
};

my $df = Data::Frame->new( columns => [ a => pdl( [ 0 .. 9 ] ) ] );
ok( $df, 'constructor' );

$df->set( 'b', [ qw(foo bar) x 5 ] );
dataframe_is(
    $df,
    Data::Frame->new(
        columns => [ a => pdl( 0 .. 9 ), b => [ qw(foo bar) x 5 ] ]
    ),
    '$df->set(): add a new column by name'
);

$df->set( 'b', pdl( [ 0 .. 9 ] ) / 10 );
dataframe_is(
    $df,
    Data::Frame->new(
        columns => [ a => pdl( 0 .. 9 ), b => pdl( 0 .. 9 ) / 10 ]
    ),
    '$df->set(): adding a new column by name'
);

is(
    $df->string, <<'END_OF_TEXT'
-----------
    a  b   
-----------
 0  0  0   
 1  1  0.1 
 2  2  0.2 
 3  3  0.3 
 4  4  0.4 
 5  5  0.5 
 6  6  0.6 
 7  7  0.7 
 8  8  0.8 
 9  9  0.9 
-----------
END_OF_TEXT
    , '$df->string'
);

is(
    Data::Frame->new(
        columns => [ a => pdl( 0 .. 10 ), b => pdl( 0 .. 10 ) / 10 ]
    )->string,
    <<'END_OF_TEXT'
-----------
    a  b   
-----------
 0  0  0   
 1  1  0.1 
 2  2  0.2 
 3  3  0.3 
 4  4  0.4 
 5  5  0.5 
 6  6  0.6 
 7  7  0.7 
 8  8  0.8 
 9  9  0.9 
-----------
# ... with 1 more rows
END_OF_TEXT
    ,
    '$df->string for df with more rows'
);

is( $df->number_of_columns, 2,                      '$df->number_of_columns' );
is( $df->ncol,              $df->number_of_columns, '$df->ncol' );
is( $df->length,            $df->number_of_columns, '$df->length' );

is( $df->names, [ 'a', 'b' ], '$df->names' );
is( $df->column_names, $df->column_names, '$df->column_names' );

ok( $df->exists('a'),  '$df->exists' );
ok( !$df->exists('c'), '$df->exists' );

pdl_is( $df->row_names, pdl( [ 0 .. 9 ] ), '$df->row_names' );

subtest at => sub {
    pdl_is( $df->at('b'), pdl( [ 0 .. 9 ] ) / 10, '$df->at($str)' );
    pdl_is(
        $df->at( indexer_i(1) ),
        pdl( [ 0 .. 9 ] ) / 10,
        '$df->at($indexer)'
    );
    pdl_is(
        $df->at( indexer_s('b') ),
        pdl( [ 0 .. 9 ] ) / 10,
        '$df->at($indexer)'
    );
    pdl_is( $df->at(1), pdl( [ 0 .. 9 ] ) / 10, '$df->at($idx)' );
    is( $df->at( indexer_i(1), 'b' ), float(0.1), '$df->at($str, $indexer)' );
    is( $df->at( indexer_i(1), indexer_i(1) ),
        float(0.1), '$df->at($indexer, $indexer)' );
    is( $df->at( 1, indexer_i(1) ), float(0.1), '$df->at($indexer, $idx)' );
};

dataframe_is(
    $df->select_columns( [qw(b a)] ),
    Data::Frame->new(
        columns => [ b => pdl( [ 0 .. 9 ] ) / 10, a => pdl( [ 0 .. 9 ] ) ]
    ),
    '$df->select_columns()'
);

dataframe_is(
    $df->select_rows( [ 1, 5 ] ),
    Data::Frame->new(
        columns => [ a => pdl( [ 1, 5 ] ), b => pdl( [ 0.1, 0.5 ] ) ],
        row_names => [ 1, 5 ]
    ),
    '$df->select_rows()'
);

#is( $df->{'[1]'},   [ 4, 5, 6 ], 'select column data by column index' );
#is( $df->{'["a"]'}, [ 1, 2, 3 ], 'select column data by column name' );
#is( $df->{'[1, "a"]'}, 2, 'select cell data' );
#dataframe_is(
#    $df->{'[1,undef]'},
#    Data::Frame::Tiny->new(
#        columns  => [ a => [2], b => [5] ],
#        rownames => [1]
#    ),
#    'select row'
#);
#is( $df->{'[undef,"a"]'}, [ 1, 2, 3 ], 'select column data' );

subtest head => sub {

    dataframe_is(
        $df->head(),
        Data::Frame->new(
            columns => [ a => pdl( [ 0 .. 5 ] ), b => pdl( [ 0 .. 5 ] ) / 10 ]
        ),
        'head()'
    );
    dataframe_is(
        $df->head(2),
        Data::Frame->new(
            columns => [ a => pdl( [ 0 .. 1 ] ), b => pdl( [ 0 .. 1 ] ) / 10 ]
        ),
        'head(2)'
    );
    dataframe_is(
        $df->head(0),
        Data::Frame->new( columns => [ a => pdl( [] ), b => pdl( [] ) ] ),
        'head(0)'
    );
};

subtest tail => sub {
    dataframe_is(
        $df->tail(),
        Data::Frame->new(
            columns => [ a => pdl( [ 4 .. 9 ] ), b => pdl( [ 4 .. 9 ] ) / 10 ],
            row_names => [ 4 .. 9 ]
        ),
        'tail()'
    );
    dataframe_is(
        $df->tail(2),
        Data::Frame->new(
            columns => [ a => pdl( [ 8 .. 9 ] ), b => pdl( [ 8 .. 9 ] ) / 10 ],
            row_names => [ 8 .. 9 ]
        ),
        'tail(2)'
    );
    dataframe_is( $df->tail(0),
        Data::Frame->new( columns => [ a => [], b => [] ] ), 'tail(0)' );
};

subtest append => sub {
    dataframe_is(
        $df->append(
            Data::Frame->new(
                columns =>
                  [ a => pdl( [ 10 .. 11 ] ), b => pdl( [ 10 .. 11 ] ) / 10 ]
            )
        ),
        Data::Frame->new(
            columns => [ a => pdl( [ 0 .. 11 ] ), b => pdl( [ 0 .. 11 ] ) / 10 ]
        ),
        '$df->append'
    );

    my $df1 =
      Data::Frame->new( columns => [ a => pdl(1), b => ["foo"] ] );
    my $df2 =
      Data::Frame->new( columns => [ a => pdl(2), b => ["bar"] ] );

    dataframe_is(
        $df1->append($df2),
        Data::Frame->new(
            columns => [ a => pdl( 1, 2 ), b => [qw(foo bar)] ]
        ),
        'append'
    );
};

{
    my $merged = $df->merge(
        Data::Frame->new( columns => [ c => PDL->sequence(10) ] ) );

    dataframe_is(
        $merged,
        Data::Frame->new(
            columns => [
                a => pdl( [ 0 .. 9 ] ),
                b => pdl( [ 0 .. 9 ] ) / 10,
                c => PDL->sequence(10),
            ]
        ),
        '$df->merge'
    );

    $merged->rename( { 'c' => 'd' } );
    dataframe_is(
        $merged,
        Data::Frame->new(
            columns => [
                a => pdl( [ 0 .. 9 ] ),
                b => pdl( [ 0 .. 9 ] ) / 10,
                d => PDL->sequence(10),
            ]
        ),
        '$df->rename($hashref)'
    );
    $merged->rename( sub { return ( $_[0] eq 'd' ? 'e' : undef ) } );
    dataframe_is(
        $merged,
        Data::Frame->new(
            columns => [
                a => pdl( [ 0 .. 9 ] ),
                b => pdl( [ 0 .. 9 ] ) / 10,
                e => PDL->sequence(10),
            ]
        ),
        '$df->rename($coderef)'
    );

    $merged->delete('e');
    dataframe_is( $merged, $df, '$df->delete' );
}

my $splitted = $df->split( $df->at('a') % 2 );
dataframe_is(
    $splitted->{0}->rbind( $splitted->{1} ),
    Data::Frame->new(
        columns => [
            a => pdl( [ 0, 2, 4, 6, 8, 1, 3, 5, 7, 9 ] ),
            b => pdl( [ 0, 2, 4, 6, 8, 1, 3, 5, 7, 9 ] ) / 10
        ],
    ),
    '$df->split'
);

subtest slice => sub {
    dataframe_is(
        $df->slice( pdl( [ 1, 5 ] ), undef ),
        Data::Frame->new(
            columns => [ a => pdl( [ 1, 5 ] ), b => pdl( [ 0.1, 0.5 ] ) ],
            row_names => [ 1, 5 ]
        ),
        '$df->slice() on rows'
    );
    dataframe_is(
        $df->slice( pdl( [ 1, 5 ] ), pdl( [ 0, 1 ] ) ),
        Data::Frame->new(
            columns => [ a => pdl( [ 1, 5 ] ), b => pdl( [ 0.1, 0.5 ] ) ],
            row_names => [ 1, 5 ]
        ),
        '$df->slice() on both rows and columns'
    );
    dataframe_is(
        $df->slice( pdl( [ 1, 5 ] ), pdl( [1] ) ),
        Data::Frame->new(
            columns   => [ b => pdl( [ 0.1, 0.5 ] ) ],
            row_names => [ 1, 5 ]
        ),
        '$df->slice() on rows of a single column'
    );

    my $df1 = $df->clone();
    dataframe_is( $df, $df1, '$df->clone' );

    $df1->slice( pdl( [ 1, 5 ] ), pdl( [1] ) ) .= pdl( [ 0.5, 0.1 ] );
    dataframe_is(
        $df1,
        Data::Frame->new(
            columns => [
                a => pdl( 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 ),
                b => pdl( 0, 5, 2, 3, 4, 1, 6, 7, 8, 9 ) / 10
            ]
        ),
        '$df->slice as lvalue, assign a 1D piddle'
    );

    $df1->slice( pdl( [ 1, 5 ] ), [qw(a b)] ) .=
      Data::Frame->new(
        columns => [ a => pdl( [ 4, 3 ] ), b => pdl( [ 2, 1 ] ) ] );
    dataframe_is(
        $df1,
        Data::Frame->new(
            columns => [
                a => pdl( 0, 4,  2, 3, 4, 3,  6, 7, 8, 9 ),
                b => pdl( 0, 20, 2, 3, 4, 10, 6, 7, 8, 9 ) / 10
            ]
        ),
        '$df->slice as lvalue, assign a data frame'
    );
    $df1->slice( pdl( [ 1, 5 ] ), pdl( [ 0, 1 ] ) ) .=
      pdl( [ [ 4, 3 ], [ 2, 1 ] ] );
    dataframe_is(
        $df1,
        Data::Frame->new(
            columns => [
                a => pdl( 0, 4,  2, 3, 4, 3,  6, 7, 8, 9 ),
                b => pdl( 0, 20, 2, 3, 4, 10, 6, 7, 8, 9 ) / 10
            ]
        ),
        '$df->slice as lvalue, assign a 2D piddle'
    );
};

done_testing;

