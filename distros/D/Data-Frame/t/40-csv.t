#!perl

use Data::Frame::Setup;

use FindBin;
use Path::Tiny;

use Test2::V0;
use Test2::Tools::DataFrame;

use Data::Frame;
use PDL::Core qw(pdl);
use PDL::DateTime ();
use PDL::Logical ();
use PDL::Factor ();
use PDL::SV ();

my $path_test_data = path("$FindBin::RealBin/../data-raw");

subtest mtcars => sub {
    my $mtcars_csv = path( $path_test_data, 'mtcars.csv' );
    my $df = Data::Frame->from_csv( $mtcars_csv, row_names => 0 );
    ok( $df, 'Data::Frame->from_csv' );
    is( $df->number_of_rows, 32, 'number_of_rows()' );
    is( $df->number_of_columns, 11, 'number_of_columns()' );
    is( $df->nrow, $df->number_of_rows, 'nrow() is same as number_of_rows()' );
    is( $df->ncol, $df->number_of_columns,
        'ncol() is same as number_of_columns()' );

    is( $df->column_names, [qw(mpg cyl disp hp drat wt qsec vs am gear carb)],
        'column_names()' );
    is( $df->column_names, $df->column_names,
        'column_names() is same as column_names()' );
    diag( $df->string );

    my $tempfile = Path::Tiny->tempfile( SUFFIX => '.csv' );
    $df->to_csv($tempfile);

    my $df_recovered = Data::Frame->from_csv( $tempfile, row_names => 0 );
    dataframe_is( $df_recovered, $df, '$df->to_csv' );
};

subtest na => sub {
    my $tempfile = Path::Tiny->tempfile( SUFFIX => '.csv' );
    $tempfile->spew(<<'EOT');
c1,c2,c3
A,1,2019-01-01
NA,0,
,NA,NA
B,,2019-01-02
EOT

    my $df1 = Data::Frame->from_csv( $tempfile,
        dtype => { c1 => 'factor', c3 => 'datetime' } );
    dataframe_is(
        $df1,
        Data::Frame->new(
            columns => [
                'c1' => PDL::Factor->new( [ 'A', '', '', 'B' ],
                    levels => [ '', 'A', 'B' ] )->setbadat(1),
                'c2' => pdl( 1, 0, 'nan', 'nan' )->setnantobad,
                'c3' => PDL::DateTime->new_from_datetime(
                    [qw(2019-01-01 1970 1970 2019-01-02)]
                )->setbadif( pdl( 0, 1, 1, 0 ) ),
            ]
        ),
        'when dtype parameter is specified'
    );
};

done_testing;
