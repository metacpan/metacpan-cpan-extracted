package Acme::CPANModules::TextTable;

our $DATE = '2020-08-10'; # DATE
our $VERSION = '0.005'; # VERSION

use 5.010001;
use strict;
use warnings;

sub _make_table {
    my ($cols, $rows) = @_;
    my $res = [];
    push @$res, [];
    for (0..$cols-1) { $res->[0][$_] = "col" . ($_+1) }
    for my $row (1..$rows) {
        push @$res, [ map { "row$row.$_" } 1..$cols ];
    }
    $res;
}

our $LIST = {
    summary => 'Modules that generate text tables',
    entry_features => {
        wide_char => {summary => 'Whether the use of wide characters (e.g. Kanji) in cells does not cause the table to be misaligned'},
        color => {summary => 'Whether the module supports ANSI colors (i.e. text with ANSI color codes can still be aligned properly)'},
        box_char => {summary => 'Whether the module can utilize box-drawing characters'},
    },
    entries => [
        {
            module => 'Text::ANSITable',
            bench_code => sub {
                my ($table) = @_;
                my $t = Text::ANSITable->new(
                    use_utf8 => 0,
                    use_box_chars => 0,
                    use_color => 0,
                    columns => $table->[0],
                    border_style => 'Default::single_ascii',
                );
                $t->add_row($table->[$_]) for 1..@$table-1;
                $t->draw;
            },
            features => {
                wide_char => 1,
                color => 1,
                box_char => 1,
            },
        },
        {
            module => 'Text::ASCIITable',
            bench_code => sub {
                my ($table) = @_;
                my $t = Text::ASCIITable->new();
                $t->setCols(@{ $table->[0] });
                $t->addRow(@{ $table->[$_] }) for 1..@$table-1;
                "$t";
            },
            features => {
                wide_char => 0,
                color => 0,
                box_char => 0,
            },
        },
        {
            module => 'Text::FormatTable',
            bench_code => sub {
                my ($table) = @_;
                my $t = Text::FormatTable->new(join('|', ('l') x @{ $table->[0] }));
                $t->head(@{ $table->[0] });
                $t->row(@{ $table->[$_] }) for 1..@$table-1;
                $t->render;
            },
            features => {
                wide_char => 0,
                color => 0,
                box_char => 0,
            },
        },
        {
            module => 'Text::MarkdownTable',
            bench_code => sub {
                my ($table) = @_;
                my $out = "";
                my $t = Text::MarkdownTable->new(file => \$out);
                my $fields = $table->[0];
                foreach (1..@$table-1) {
                    my $row = $table->[$_];
                    $t->add( {
                        map { $fields->[$_] => $row->[$_] } 0..@$fields-1
                    });
                }
                $t->done;
                $out;
            },
            features => {
                wide_char => 0,
                color => 0,
                box_char => 0,
            },
        },
        {
            module => 'Text::Table',
            bench_code => sub {
                my ($table) = @_;
                my $t = Text::Table->new(@{ $table->[0] });
                $t->load(@{ $table }[1..@$table-1]);
                $t;
            },
            features => {
                wide_char => 0,
                color => 0,
                box_char => {value=>undef, summary=>'Does not draw borders'},
            },
        },
        {
            module => 'Text::Table::Tiny',
            bench_code => sub {
                my ($table) = @_;
                Text::Table::Tiny::table(rows=>$table, header_row=>1);
            },
            features => {
                wide_char => 0,
                color => 1,
                box_char => 1,
            },
        },
        {
            module => 'Text::Table::Sprintf',
            bench_code => sub {
                my ($table) = @_;
                Text::Table::Sprintf::table(rows=>$table, header_row=>1);
            },
            features => {
                wide_char => 0,
                color => 0,
                box_char => 0,
            },
        },
        {
            module => 'Text::Table::TinyColor',
            bench_code => sub {
                my ($table) = @_;
                Text::Table::TinyColor::table(rows=>$table, header_row=>1);
            },
            features => {
                wide_char => 0,
                color => 1,
                box_char => 0,
            },
        },
        {
            module => 'Text::Table::TinyColorWide',
            bench_code => sub {
                my ($table) = @_;
                Text::Table::TinyColorWide::table(rows=>$table, header_row=>1);
            },
            features => {
                wide_char => 1,
                color => 1,
                box_char => 0,
            },
        },
        {
            module => 'Text::Table::TinyWide',
            bench_code => sub {
                my ($table) = @_;
                Text::Table::TinyWide::table(rows=>$table, header_row=>1);
            },
            features => {
                wide_char => 1,
                color => 0,
                box_char => 0,
            },
        },
        {
            module => 'Text::Table::Org',
            bench_code => sub {
                my ($table) = @_;
                Text::Table::Org::table(rows=>$table, header_row=>1);
            },
            features => {
                wide_char => 0,
                color => 0,
                box_char => 0,
            },
        },
        {
            module => 'Text::Table::CSV',
            bench_code => sub {
                my ($table) = @_;
                Text::Table::CSV::table(rows=>$table, header_row=>1);
            },
            features => {
                wide_char => 1,
                color => 0,
                box_char => {value=>undef, summary=>"Irrelevant"},
            },
        },
        {
            module => 'Text::Table::HTML',
            bench_code => sub {
                my ($table) = @_;
                Text::Table::HTML::table(rows=>$table, header_row=>1);
            },
            features => {
            },
        },
        {
            module => 'Text::Table::HTML::DataTables',
            bench_code => sub {
                my ($table) = @_;
                Text::Table::HTML::DataTables::table(rows=>$table, header_row=>1);
            },
            features => {
            },
        },
        {
            module => 'Text::TabularDisplay',
            bench_code => sub {
                my ($table) = @_;
                my $t = Text::TabularDisplay->new(@{ $table->[0] });
                $t->add(@{ $table->[$_] }) for 1..@$table-1;
                $t->render; # doesn't add newline
            },
            features => {
                wide_char => 1,
                color => 0,
                box_char => {value=>undef, summary=>"Irrelevant"},
            },
        },
    ],

    bench_datasets => [
        {name=>'tiny (1x1)'    , argv => [_make_table( 1, 1)],},
        {name=>'small (3x5)'   , argv => [_make_table( 3, 5)],},
        {name=>'wide (30x5)'   , argv => [_make_table(30, 5)],},
        {name=>'long (3x300)'  , argv => [_make_table( 3, 300)],},
        {name=>'large (30x300)', argv => [_make_table(30, 300)],},
    ],

};

1;
# ABSTRACT: Modules that generate text tables

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::TextTable - Modules that generate text tables

=head1 VERSION

This document describes version 0.005 of Acme::CPANModules::TextTable (from Perl distribution Acme-CPANModules-TextTable), released on 2020-08-10.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher --cpanmodules-module TextTable

To run module startup overhead benchmark:

 % bencher --module-startup --cpanmodules-module TextTable

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Text::ANSITable> 0.501

L<Text::ASCIITable> 0.22

L<Text::FormatTable> 1.03

L<Text::MarkdownTable> 0.3.1

L<Text::Table> 1.133

L<Text::Table::Tiny> 1.00

L<Text::Table::Sprintf> 0.001

L<Text::Table::TinyColor> 0.002

L<Text::Table::TinyColorWide> 0.001

L<Text::Table::TinyWide> 0.001

L<Text::Table::Org> 0.02

L<Text::Table::CSV> 0.023

L<Text::Table::HTML> 0.003

L<Text::Table::HTML::DataTables> 0.002

L<Text::TabularDisplay> 1.38

=head1 BENCHMARK PARTICIPANTS

=over

=item * Text::ANSITable (perl_code)

L<Text::ANSITable>



=item * Text::ASCIITable (perl_code)

L<Text::ASCIITable>



=item * Text::FormatTable (perl_code)

L<Text::FormatTable>



=item * Text::MarkdownTable (perl_code)

L<Text::MarkdownTable>



=item * Text::Table (perl_code)

L<Text::Table>



=item * Text::Table::Tiny (perl_code)

L<Text::Table::Tiny>



=item * Text::Table::Sprintf (perl_code)

L<Text::Table::Sprintf>



=item * Text::Table::TinyColor (perl_code)

L<Text::Table::TinyColor>



=item * Text::Table::TinyColorWide (perl_code)

L<Text::Table::TinyColorWide>



=item * Text::Table::TinyWide (perl_code)

L<Text::Table::TinyWide>



=item * Text::Table::Org (perl_code)

L<Text::Table::Org>



=item * Text::Table::CSV (perl_code)

L<Text::Table::CSV>



=item * Text::Table::HTML (perl_code)

L<Text::Table::HTML>



=item * Text::Table::HTML::DataTables (perl_code)

L<Text::Table::HTML::DataTables>



=item * Text::TabularDisplay (perl_code)

L<Text::TabularDisplay>



=back

=head1 BENCHMARK DATASETS

=over

=item * tiny (1x1)

=item * small (3x5)

=item * wide (30x5)

=item * long (3x300)

=item * large (30x300)

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.30.0 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 19.10 >>, OS kernel: I<< Linux version 5.3.0-62-generic >>.

Benchmark with default options (C<< bencher --cpanmodules-module TextTable >>):

 #table1#
 {dataset=>"large (30x300)"}
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+-----------+---------+
 | participant                   | rate (/s) | time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors   | samples |
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+-----------+---------+
 | Text::ANSITable               |       2.7 |     370   |                 0.00% |             15633.54% |   0.0011  |      20 |
 | Text::ASCIITable              |      11   |      87   |               322.58% |              3623.18% |   0.00034 |      21 |
 | Text::Table::TinyColorWide    |      17   |      60   |               510.11% |              2478.80% |   0.00031 |      21 |
 | Text::FormatTable             |      18   |      56   |               555.23% |              2301.23% |   0.00027 |      20 |
 | Text::Table::TinyWide         |      23   |      44   |               740.72% |              1771.44% |   0.00038 |      20 |
 | Text::TabularDisplay          |      44   |      23   |              1532.02% |               864.05% |   0.00017 |      20 |
 | Text::Table::TinyColor        |      61   |      16   |              2134.53% |               604.11% | 5.9e-05   |      20 |
 | Text::Table::Tiny             |      64   |      16   |              2269.75% |               563.93% | 3.8e-05   |      20 |
 | Text::MarkdownTable           |      89   |      11   |              3179.63% |               379.73% | 5.7e-05   |      20 |
 | Text::Table                   |     100   |       9   |              3820.67% |               301.30% |   0.00011 |      20 |
 | Text::Table::HTML::DataTables |     130   |       7.9 |              4584.70% |               235.85% | 1.5e-05   |      20 |
 | Text::Table::HTML             |     130   |       7.9 |              4587.60% |               235.64% | 1.3e-05   |      20 |
 | Text::Table::CSV              |     240   |       4.2 |              8578.87% |                81.29% | 6.5e-06   |      20 |
 | Text::Table::Org              |     240   |       4.2 |              8704.72% |                78.69% | 1.4e-05   |      20 |
 | Text::Table::Sprintf          |     430   |       2.3 |             15633.54% |                 0.00% | 1.8e-05   |      20 |
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+-----------+---------+

 #table2#
 {dataset=>"long (3x300)"}
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+-----------+---------+
 | participant                   | rate (/s) | time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors   | samples |
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+-----------+---------+
 | Text::ANSITable               |        20 |    50     |                 0.00% |             13649.56% |   0.00049 |      20 |
 | Text::ASCIITable              |       120 |     8     |               470.78% |              2308.92% | 2.1e-05   |      20 |
 | Text::FormatTable             |       160 |     6.2   |               639.62% |              1759.00% | 1.1e-05   |      20 |
 | Text::Table::TinyColorWide    |       170 |     6     |               665.05% |              1697.21% | 2.2e-05   |      20 |
 | Text::Table::TinyWide         |       230 |     4.3   |               976.30% |              1177.48% | 2.1e-05   |      20 |
 | Text::TabularDisplay          |       350 |     2.9   |              1495.09% |               761.99% | 1.5e-05   |      20 |
 | Text::MarkdownTable           |       420 |     2.4   |              1806.01% |               621.38% | 2.1e-05   |      20 |
 | Text::Table                   |       510 |     1.9   |              2254.22% |               484.04% | 8.7e-06   |      20 |
 | Text::Table::Tiny             |       550 |     1.8   |              2426.47% |               444.22% | 9.4e-06   |      20 |
 | Text::Table::TinyColor        |       580 |     1.7   |              2579.14% |               413.21% | 1.1e-05   |      20 |
 | Text::Table::HTML::DataTables |       990 |     1     |              4425.78% |               203.81% | 7.6e-06   |      21 |
 | Text::Table::HTML             |      1100 |     0.92  |              4909.46% |               174.47% | 1.3e-06   |      20 |
 | Text::Table::CSV              |      1810 |     0.551 |              8226.13% |                65.14% | 2.7e-07   |      20 |
 | Text::Table::Org              |      1800 |     0.54  |              8350.51% |                62.71% | 1.1e-06   |      21 |
 | Text::Table::Sprintf          |      3000 |     0.3   |             13649.56% |                 0.00% | 6.3e-06   |      21 |
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+-----------+---------+

 #table3#
 {dataset=>"small (3x5)"}
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                   | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | Text::ANSITable               |       980 |    1000   |                 0.00% |              9795.39% | 5.9e-06 |      20 |
 | Text::ASCIITable              |      4800 |     210   |               391.26% |              1914.28% | 6.4e-07 |      20 |
 | Text::FormatTable             |      7000 |     140   |               617.31% |              1279.51% | 2.1e-07 |      21 |
 | Text::Table                   |      7700 |     130   |               682.99% |              1163.79% | 2.4e-07 |      25 |
 | Text::Table::TinyColorWide    |      7800 |     130   |               699.94% |              1137.01% | 2.1e-07 |      21 |
 | Text::Table::TinyWide         |     11000 |      90   |              1030.32% |               775.45% | 1.1e-07 |      20 |
 | Text::MarkdownTable           |     10000 |      90   |              1033.55% |               772.96% | 1.8e-06 |      20 |
 | Text::TabularDisplay          |     15000 |      65   |              1475.59% |               528.04% | 9.2e-08 |      27 |
 | Text::Table::Tiny             |     21000 |      48   |              2018.65% |               367.06% | 6.7e-08 |      20 |
 | Text::Table::HTML::DataTables |     23000 |      44   |              2238.39% |               323.17% | 1.1e-07 |      20 |
 | Text::Table::TinyColor        |     24000 |      42   |              2345.56% |               304.63% | 5.3e-08 |      20 |
 | Text::Table::HTML             |     47500 |      21   |              4742.64% |               104.34% |   2e-08 |      20 |
 | Text::Table::Org              |     56000 |      18   |              5604.92% |                73.45% | 2.7e-08 |      20 |
 | Text::Table::CSV              |     80800 |      12.4 |              8134.77% |                20.17% |   1e-08 |      20 |
 | Text::Table::Sprintf          |     97100 |      10.3 |              9795.39% |                 0.00% | 3.3e-09 |      20 |
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

 #table4#
 {dataset=>"tiny (1x1)"}
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                   | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | Text::ANSITable               |      3800 |    260    |                 0.00% |              7500.38% | 6.6e-07 |      22 |
 | Text::ASCIITable              |     18000 |     57    |               358.01% |              1559.43% | 1.1e-07 |      20 |
 | Text::Table                   |     21000 |     48    |               445.20% |              1294.04% | 1.1e-07 |      20 |
 | Text::MarkdownTable           |     25000 |     40    |               551.77% |              1066.11% | 1.1e-07 |      20 |
 | Text::FormatTable             |     34000 |     29    |               794.08% |               750.08% |   5e-08 |      23 |
 | Text::Table::HTML::DataTables |     38000 |     26    |               887.99% |               669.28% | 5.3e-08 |      20 |
 | Text::Table::TinyColorWide    |     44000 |     23    |              1054.15% |               558.53% | 2.7e-08 |      20 |
 | Text::Table::TinyWide         |     50000 |     20    |              1112.17% |               527.00% | 3.6e-07 |      24 |
 | Text::TabularDisplay          |     62000 |     16    |              1520.67% |               368.97% | 2.7e-08 |      20 |
 | Text::Table::Tiny             |     63000 |     16    |              1546.42% |               361.63% | 3.3e-08 |      20 |
 | Text::Table::TinyColor        |     94000 |     11    |              2352.06% |               209.96% | 1.3e-08 |      20 |
 | Text::Table::Org              |    151000 |      6.61 |              3852.70% |                92.28% | 3.3e-09 |      21 |
 | Text::Table::HTML             |    180000 |      5.6  |              4571.03% |                62.71% | 6.7e-09 |      20 |
 | Text::Table::Sprintf          |    200000 |      4    |              6351.94% |                17.80% | 5.7e-08 |      20 |
 | Text::Table::CSV              |    290000 |      3.4  |              7500.38% |                 0.00% | 6.7e-09 |      20 |
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

 #table5#
 {dataset=>"wide (30x5)"}
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                   | rate (/s) | time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | Text::ANSITable               |       130 |     8     |                 0.00% |             11509.16% | 1.5e-05 |      20 |
 | Text::ASCIITable              |       520 |     1.9   |               315.64% |              2693.06% | 4.1e-06 |      20 |
 | Text::FormatTable             |       720 |     1.4   |               474.77% |              1919.79% |   5e-06 |      20 |
 | Text::Table::TinyColorWide    |       850 |     1.2   |               579.94% |              1607.38% | 3.4e-06 |      20 |
 | Text::Table                   |      1200 |     0.83  |               858.40% |              1111.31% | 2.2e-06 |      20 |
 | Text::Table::TinyWide         |      1200 |     0.81  |               880.96% |              1083.44% | 9.1e-07 |      20 |
 | Text::TabularDisplay          |      2300 |     0.43  |              1757.95% |               524.84% | 6.9e-07 |      20 |
 | Text::Table::Tiny             |      3000 |     0.34  |              2250.85% |               393.83% | 1.1e-06 |      20 |
 | Text::Table::TinyColor        |      3100 |     0.33  |              2342.20% |               375.36% | 4.3e-07 |      20 |
 | Text::MarkdownTable           |      3600 |     0.28  |              2768.12% |               304.77% | 6.9e-07 |      20 |
 | Text::Table::HTML::DataTables |      5700 |     0.18  |              4402.09% |               157.86% | 2.7e-07 |      20 |
 | Text::Table::HTML             |      6620 |     0.151 |              5164.87% |               120.50% | 5.2e-08 |      21 |
 | Text::Table::Org              |      9300 |     0.11  |              7322.71% |                56.40% | 2.1e-07 |      20 |
 | Text::Table::CSV              |     12200 |     0.082 |              9605.19% |                19.62% |   8e-08 |      20 |
 | Text::Table::Sprintf          |     15000 |     0.069 |             11509.16% |                 0.00% | 1.3e-07 |      20 |
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+


Benchmark module startup overhead (C<< bencher --cpanmodules-module TextTable --module-startup >>):

 #table6#
 +-------------------------------+-----------+-------------------+-----------------------+-----------------------+-----------+---------+
 | participant                   | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors   | samples |
 +-------------------------------+-----------+-------------------+-----------------------+-----------------------+-----------+---------+
 | Text::ANSITable               |      55   |              46.4 |                 0.00% |               605.95% |   0.00023 |      20 |
 | Text::MarkdownTable           |      43   |              34.4 |                28.89% |               447.69% |   0.00013 |      20 |
 | Text::Table::TinyColorWide    |      33   |              24.4 |                68.74% |               318.38% | 7.3e-05   |      20 |
 | Text::Table::TinyWide         |      32   |              23.4 |                72.30% |               309.72% |   0.00012 |      20 |
 | Text::Table                   |      21.9 |              13.3 |               152.58% |               179.49% |   2e-05   |      20 |
 | Text::ASCIITable              |      18   |               9.4 |               207.79% |               129.36% | 9.1e-05   |      20 |
 | Text::Table::Tiny             |      15   |               6.4 |               267.30% |                92.20% | 4.4e-05   |      23 |
 | Text::FormatTable             |      14   |               5.4 |               287.86% |                82.01% | 2.8e-05   |      20 |
 | Text::Table::TinyColor        |      14   |               5.4 |               309.25% |                72.50% | 3.6e-05   |      21 |
 | Text::Table::HTML             |      10   |               1.4 |               356.93% |                54.50% |   0.00031 |      20 |
 | Text::Table::HTML::DataTables |      10   |               1.4 |               411.84% |                37.92% |   0.00022 |      23 |
 | Text::TabularDisplay          |      10   |               1.4 |               430.28% |                33.13% | 2.8e-05   |      20 |
 | Text::Table::Sprintf          |       9.6 |               1   |               474.16% |                22.95% | 3.4e-05   |      20 |
 | Text::Table::Org              |       9   |               0.4 |               528.40% |                12.34% |   0.00016 |      20 |
 | perl -e1 (baseline)           |       8.6 |               0   |               541.15% |                10.11% |   4e-05   |      21 |
 | Text::Table::CSV              |       7.8 |              -0.8 |               605.95% |                 0.00% | 2.1e-05   |      21 |
 +-------------------------------+-----------+-------------------+-----------------------+-----------------------+-----------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 FEATURE COMPARISON MATRIX

 +-------------------------------+--------------+-----------+---------------+
 | module                        | box_char *1) | color *2) | wide_char *3) |
 +-------------------------------+--------------+-----------+---------------+
 | Text::ANSITable               | yes          | yes       | yes           |
 | Text::ASCIITable              | no           | no        | no            |
 | Text::FormatTable             | no           | no        | no            |
 | Text::MarkdownTable           | no           | no        | no            |
 | Text::Table                   | N/A *4)      | no        | no            |
 | Text::Table::Tiny             | yes          | yes       | no            |
 | Text::Table::Sprintf          | no           | no        | no            |
 | Text::Table::TinyColor        | no           | yes       | no            |
 | Text::Table::TinyColorWide    | no           | yes       | yes           |
 | Text::Table::TinyWide         | no           | no        | yes           |
 | Text::Table::Org              | no           | no        | no            |
 | Text::Table::CSV              | N/A *5)      | no        | yes           |
 | Text::Table::HTML             | N/A          | N/A       | N/A           |
 | Text::Table::HTML::DataTables | N/A          | N/A       | N/A           |
 | Text::TabularDisplay          | N/A *6)      | no        | yes           |
 +-------------------------------+--------------+-----------+---------------+


Notes:

=over

=item 1. box_char: Whether the module can utilize box-drawing characters

=item 2. color: Whether the module supports ANSI colors (i.e. text with ANSI color codes can still be aligned properly)

=item 3. wide_char: Whether the use of wide characters (e.g. Kanji) in cells does not cause the table to be misaligned

=item 4. Does not draw borders

=item 5. Irrelevant

=item 6. Irrelevant

=back

=head1 INCLUDED MODULES

=over

=item * L<Text::ANSITable>

=item * L<Text::ASCIITable>

=item * L<Text::FormatTable>

=item * L<Text::MarkdownTable>

=item * L<Text::Table>

=item * L<Text::Table::Tiny>

=item * L<Text::Table::Sprintf>

=item * L<Text::Table::TinyColor>

=item * L<Text::Table::TinyColorWide>

=item * L<Text::Table::TinyWide>

=item * L<Text::Table::Org>

=item * L<Text::Table::CSV>

=item * L<Text::Table::HTML>

=item * L<Text::Table::HTML::DataTables>

=item * L<Text::TabularDisplay>

=back

=head1 FAQ

=head2 What are ways to use this module?

Aside from reading it, you can install all the listed modules using
L<cpanmodules>:

    % cpanmodules ls-entries TextTable | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=TextTable -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

This module contains benchmark instructions. You can run a benchmark
for some/all the modules listed in this Acme::CPANModules module using
L<bencher>:

    % bencher --cpanmodules-module TextTable

This module also helps L<lcpan> produce a more meaningful result for C<lcpan
related-mods> when it comes to finding related modules for the modules listed
in this Acme::CPANModules module.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-TextTable>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-TextTable>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-TextTable>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Acme::CPANModules> - about the Acme::CPANModules namespace

L<cpanmodules> - CLI tool to let you browse/view the lists

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
