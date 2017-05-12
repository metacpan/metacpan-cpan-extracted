#!perl

use 5.008001;
use strict;
use warnings FATAL => 'all';

use Test::More;
eval "use Text::CSV_XS; 1" or eval "use Text::CSV; 1" or plan skip_all => "Text::CSV_XS or Text::CSV required";

use Cwd        ();
use FindBin    ();
use File::Spec ();

use_ok('AnyData2')                          || BAIL_OUT "Couldn't load AnyData2";
use_ok('AnyData2::Format::CSV')             || BAIL_OUT "Couldn't load AnyData2::Format::CSV";
use_ok('AnyData2::Storage::File::Linewise') || BAIL_OUT "Couldn't load AnyData2::Storage::File::Linewise";

my $test_dir = Cwd::abs_path( File::Spec->catdir( $FindBin::Bin, "data" ) );

my $af = AnyData2->new(
    CSV              => {},
    "File::Linewise" => { filename => File::Spec->catfile( $test_dir, "simple.csv" ) }
);

my $cols = $af->cols;
my @rows;

while ( my $row = $af->fetchrow )
{
    push @rows, $row;
}

is_deeply( $cols, [qw(Id Name Color)], "Cols from csv" );
is_deeply( \@rows, [ [ "1", "red", "#ff0000" ], [ "2", "green", "#00ff00" ], [ "3", "blue", "#0000ff" ] ], "Rows from csv" );

done_testing;
