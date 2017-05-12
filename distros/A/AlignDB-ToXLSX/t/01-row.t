use strict;
use warnings;
use Test::More;

use Path::Tiny;
use Spreadsheet::XLSX;

use AlignDB::ToXLSX;

my $temp = Path::Tiny->tempfile;

{
    my $toxlsx = AlignDB::ToXLSX->new( outfile => $temp->stringify, );

    $toxlsx->row(0);
    $toxlsx->column(1);

    my $sheet = $toxlsx->write_header(
        "basic",
        {   query_name => 'Item',
            header     => [ 'B' .. 'F' ],
        }
    );

    $toxlsx->write_row(
        $sheet,
        {   query_name => 'First',
            row        => [ 2 .. 6 ],
        }
    );
}

{
    my $xlsx  = Spreadsheet::XLSX->new( $temp->stringify );
    my $sheet = $xlsx->{Worksheet}[0];

    is( $sheet->{Name},             "basic", "Sheet Name" );
    is( $sheet->{MaxRow},           1,       "Sheet MaxRow" );
    is( $sheet->{MaxCol},           5,       "Sheet MaxCol" );
    is( $sheet->{Cells}[1][0]{Val}, "First", "Cell content 1" );
    is( $sheet->{Cells}[0][5]{Val}, "F",     "Cell content 2" );
    is( $sheet->{Cells}[1][4]{Val}, 5,       "Cell content 3" );
}

done_testing();
