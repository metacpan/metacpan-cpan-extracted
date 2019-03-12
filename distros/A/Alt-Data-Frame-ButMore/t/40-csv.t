#!perl

use Data::Frame::Setup;

use FindBin;
use Path::Tiny;

use Test2::V0;
use Test2::Tools::DataFrame;

use Data::Frame;

my $path_test_data = path( "$FindBin::RealBin/../data-raw" );

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

my $tempfile = Path::Tiny->tempfile;
$df->to_csv($tempfile);

my $df_recovered = Data::Frame->from_csv( $tempfile, row_names => 0 );
dataframe_is( $df_recovered, $df, '$df->to_csv' );

done_testing;
