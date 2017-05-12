use strict;
use warnings;
use Test::More;

use Path::Tiny;
use Spreadsheet::XLSX;

use AlignDB::ToXLSX;

my $temp = Path::Tiny->tempfile;

{
    my $toxlsx = AlignDB::ToXLSX->new( outfile => $temp->stringify, );

    my $sheet = $toxlsx->write_header( "columns", { header => [ 'A' .. 'F' ], } );

    for my $i ( 1 .. 6 ) {
        $toxlsx->write_column( $sheet, { column => [ 1 .. $i ], } );
    }
}

{
    my $xlsx  = Spreadsheet::XLSX->new( $temp->stringify );
    my $sheet = $xlsx->{Worksheet}[0];

    is( $sheet->{Name},             "columns", "Sheet Name" );
    is( $sheet->{MaxRow},           6,         "Sheet MaxRow" );
    is( $sheet->{MaxCol},           5,         "Sheet MaxCol" );
    is( $sheet->{Cells}[0][5]{Val}, "F",       "Cell content 1" );
    is( $sheet->{Cells}[1][0]{Val}, 1,         "Cell content 2" );
    is( $sheet->{Cells}[3][5]{Val}, 3,         "Cell content 3" );
}

done_testing();
