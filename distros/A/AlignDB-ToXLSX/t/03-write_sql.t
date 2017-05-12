use strict;
use warnings;
use Test::More;

use Path::Tiny;
use Spreadsheet::XLSX;
use DBI;
use Archive::Zip;

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

    my $sql_query = q{
        SELECT
            isw.isw_distance distance,
            AVG(isw.isw_pi) AVG_pi,
            COUNT(*) COUNT
        FROM
            isw
        WHERE
            isw.isw_distance <= 20
        GROUP BY
            distance
        ORDER BY
            distance
    };

    my $toxlsx = AlignDB::ToXLSX->new(
        dbh => $dbh,

        outfile => $temp->stringify,

        #                outfile => "03.xlsx",
    );

    my $sheet_name = 'd1_pi';
    my $sheet;

    {    # header
        my @names = $toxlsx->sql2names($sql_query);
        $sheet = $toxlsx->write_header( $sheet_name, { header => \@names, } );
    }

    my $data;    # for scales
    {            # content
        $data = $toxlsx->write_sql(
            $sheet,
            {   sql_query => $sql_query,
                data      => 1,
            }
        );
    }

    {            # draw_y
        my %opt = (
            x_column  => 0,
            y_column  => 1,
            first_row => 2,
            last_row  => 17,

            #            x_max_scale => 15,
            x_scale_unit => 5,
            y_data       => $data->[1],
            x_title      => "Distance to indels (d1)",
            y_title      => "Nucleotide diversity",
            top          => 1,
            left         => 4,
        );

        $toxlsx->draw_y( $sheet, \%opt );
    }

    {    # draw_2y
        my %opt = (
            x_column  => 0,
            y_column  => 1,
            first_row => 2,
            last_row  => 17,

            #            x_max_scale => 15,
            x_scale_unit => 5,
            y_data       => $data->[1],
            x_title      => "Distance to indels (d1)",
            y_title      => "Nucleotide diversity",
            y2_column    => 2,
            y2_data      => $data->[2],
            y2_title     => "Count",
            top          => 1 + 18,
            left         => 4,
        );

        $toxlsx->draw_2y( $sheet, \%opt );
    }

    {    # draw_xy
        my %opt = (
            x_column  => 0,
            y_column  => 1,
            first_row => 2,
            last_row  => 17,
            x_data    => $data->[0],
            y_data    => $data->[1],
            x_title   => "Distance to indels (d1)",
            y_title   => "Nucleotide diversity",
            top       => 1 + 18 * 2,
            left      => 4,
        );
        $toxlsx->replace( { diversity => "divergence" } );
        $toxlsx->draw_xy( $sheet, \%opt );
    }

    $toxlsx->add_index_sheet;
}

{
    my $xlsx  = Spreadsheet::XLSX->new( $temp->stringify );
    my $sheet = $xlsx->{Worksheet}[0];

    is( $sheet->{Name},              "d1_pi", "Sheet Name" );
    is( $sheet->{MaxRow},            22,      "Sheet MaxRow" );
    is( $sheet->{MaxCol},            2,       "Sheet MaxCol" );
    is( $sheet->{Cells}[0][2]{Val},  "COUNT", "Cell content 1" );
    is( $sheet->{Cells}[1][0]{Val},  -1,      "Cell content 2" );
    is( $sheet->{Cells}[22][2]{Val}, 15,      "Cell content 3" );
}

{
    my $xlsx  = Spreadsheet::XLSX->new( $temp->stringify );
    my $sheet = $xlsx->{Worksheet}[1];

    is( $sheet->{Name},   "INDEX", "Sheet Name" );
    is( $sheet->{MaxRow}, 1,       "Sheet MaxRow" );
    is( $sheet->{MaxCol}, 0,       "Sheet MaxCol" );
    like( $sheet->{Cells}[0][0]{Val}, qr{\d+\-\d+}, "Cell content 1" );
    is( $sheet->{Cells}[1][0]{Val}, "d1_pi", "Cell content 2" );
}

{    # chech chart*.xml exist
    my $zipobj = Archive::Zip->new();
    $zipobj->read( $temp->stringify );

    my @filenames = $zipobj->memberNames();

    #    print YAML::Syck::Dump \@filenames;
    ok( scalar( grep {/chart1\.xml/} @filenames ), "chart 1" );
    ok( scalar( grep {/chart2\.xml/} @filenames ), "chart 2" );
    ok( scalar( grep {/chart2\.xml/} @filenames ), "chart 3" );
}

ok(1);    # for manual check, need at least 1 test.

done_testing();
