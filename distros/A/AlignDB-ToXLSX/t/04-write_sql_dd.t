use strict;
use warnings;
use Test::More;

use Path::Tiny;
use Spreadsheet::XLSX;
use DBI;
use Archive::Zip;
use Tie::IxHash;

use AlignDB::ToXLSX;

# cd ~/Scripts/alignDB
# perl util/query_sql.pl -d ScervsRM11_1a_Spar -t csv -o isw.csv \
#     -q "SELECT isw_id, isw_length, isw_distance, isw_pi FROM isw LIMIT 1000"

my $temp = Path::Tiny->tempfile;

{
    #@type DBI
    my $dbh = DBI->connect("DBI:CSV:");
    $dbh->{csv_tables}->{isw} = {
        eol            => "\n",
        sep_char       => ",",
        file           => "t/isw.csv",
        skip_first_row => 1,
        quote_char     => '',
        col_names      => [qw{ isw_id isw_length isw_distance isw_pi }],
    };

    my $sql_query_1 = q{
        SELECT
            isw.isw_distance distance,
            AVG(isw.isw_pi) AVG_pi,
            COUNT(*) COUNT
        FROM
            isw
        WHERE
            isw.isw_distance <= 5
        AND isw.isw_distance >= 1
        AND isw.isw_length = 100
        GROUP BY
            distance
        ORDER BY
            distance
    };

    my $sql_query_2 = q{
        SELECT
            isw.isw_distance distance,
            AVG(isw.isw_pi) AVG_pi,
            COUNT(*) COUNT
        FROM
            isw
        WHERE
            isw.isw_distance <= 5
        AND isw.isw_distance >= 1
        AND isw.isw_length <> 100
        GROUP BY
            distance
        ORDER BY
            distance
    };

    my $toxlsx = AlignDB::ToXLSX->new(
        dbh => $dbh,

        outfile => $temp->stringify,

        #        outfile => "04.xlsx",
    );

    my $sheet_name = 'd1_pi';
    my $sheet;
    $toxlsx->row(0);
    $toxlsx->column(1);

    {    # header
        $sheet = $toxlsx->write_header( $sheet_name, { header => [qw{distance AVG_pi COUNT}], } );
    }

    tie my %data_of, 'Tie::IxHash';
    {    # content
        my $group_name = "group_1";
        $toxlsx->increase_row;

        my $data = $toxlsx->write_sql(
            $sheet,
            {   sql_query  => $sql_query_1,
                query_name => $group_name,
                data       => 1,
            }
        );
        $data_of{$group_name} = $data;
    }
    {    # content
        my $group_name = "group_2";
        $toxlsx->increase_row;

        my $data = $toxlsx->write_sql(
            $sheet,
            {   sql_query  => $sql_query_2,
                query_name => $group_name,
                data       => 1,
            }
        );
        $data_of{$group_name} = $data;
    }

    {    # draw_dd
        my @keys = keys %data_of;
        $toxlsx->row(2);
        $toxlsx->column(7);
        $toxlsx->write_column( $sheet, { column => $data_of{ $keys[-1] }->[0], } );
        for my $key (@keys) {
            $toxlsx->write_column(
                $sheet,
                {   query_name => $key,
                    column     => $data_of{$key}->[1],
                }
            );
        }

        my %opt = (
            x_column      => 7,
            y_column      => 8,
            y_last_column => 8 + @keys - 1,
            first_row     => 2,
            last_row      => 7,
            x_min_scale   => 0,
            x_max_scale   => 5,
            y_data        => [ map { $data_of{$_}->[1] } @keys ],
            x_title       => "Distance to indels (d1)",
            y_title       => "Nucleotide diversity",
            top           => 11,
            left          => 7,
            height        => 480,
            width         => 480,
        );

        $toxlsx->draw_dd( $sheet, \%opt );
    }

}

{
    my $xlsx  = Spreadsheet::XLSX->new( $temp->stringify );
    my $sheet = $xlsx->{Worksheet}[0];

    is( $sheet->{Name},             "d1_pi",   "Sheet Name" );
    is( $sheet->{MaxRow},           12,        "Sheet MaxRow" );
    is( $sheet->{MaxCol},           9,         "Sheet MaxCol" );
    is( $sheet->{Cells}[0][3]{Val}, "COUNT",   "Cell content 1" );
    is( $sheet->{Cells}[2][0]{Val}, "group_1", "Cell content 2" );
    is( $sheet->{Cells}[1][9]{Val}, "group_2", "Cell content 3" );
}

{    # chech chart*.xml exist
    my $zipobj = Archive::Zip->new();
    $zipobj->read( $temp->stringify );

    my @filenames = $zipobj->memberNames();

    ok( scalar( grep {/chart1\.xml/} @filenames ), "chart 1" );
}

ok(1);    # for manual check, need at least 1 test.

done_testing();
