package Acme::CPANModules::TextTable;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-09-13'; # DATE
our $DIST = 'Acme-CPANModules-TextTable'; # DIST
our $VERSION = '0.006'; # VERSION

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
                    border_style => 'ASCII::SingleLine',
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
                wide_char => 1,
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

This document describes version 0.006 of Acme::CPANModules::TextTable (from Perl distribution Acme-CPANModules-TextTable), released on 2020-09-13.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher --cpanmodules-module TextTable

To run module startup overhead benchmark:

 % bencher --module-startup --cpanmodules-module TextTable

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Text::ANSITable> 0.600

L<Text::ASCIITable> 0.22

L<Text::FormatTable> 1.03

L<Text::MarkdownTable> 0.3.1

L<Text::Table> 1.133

L<Text::Table::Tiny> 1.0101

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

Run on: perl: I<< v5.30.2 >>, CPU: I<< Intel(R) Core(TM) i7-4770 CPU @ 3.40GHz (4 cores) >>, OS: I<< GNU/Linux LinuxMint version 19 >>, OS kernel: I<< Linux version 4.15.0-91-generic >>.

Benchmark with default options (C<< bencher --cpanmodules-module TextTable >>):

 #table1#
 {dataset=>"large (30x300)"}
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+-----------+---------+
 | participant                   | rate (/s) | time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors   | samples |
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+-----------+---------+
 | Text::ANSITable               |      3.24 |    308    |                 0.00% |             16674.90% |   0.00023 |      20 |
 | Text::ASCIITable              |     15    |     66    |               369.92% |              3469.74% | 8.3e-05   |      20 |
 | Text::Table::TinyColorWide    |     22    |     46    |               571.05% |              2399.81% | 4.6e-05   |      20 |
 | Text::FormatTable             |     23    |     43    |               612.40% |              2254.72% | 5.3e-05   |      20 |
 | Text::Table::TinyWide         |     31.1  |     32.2  |               858.53% |              1650.07% |   3e-05   |      20 |
 | Text::Table::Tiny             |     54    |     18.5  |              1566.83% |               906.39% | 1.8e-05   |      20 |
 | Text::TabularDisplay          |     58    |     17    |              1684.50% |               840.03% | 3.8e-05   |      20 |
 | Text::Table::TinyColor        |     79    |     13    |              2324.55% |               591.88% | 4.2e-05   |      23 |
 | Text::MarkdownTable           |    115    |      8.68 |              3455.01% |               371.87% | 4.7e-06   |      20 |
 | Text::Table                   |    140    |      6.9  |              4358.77% |               276.22% | 1.9e-05   |      21 |
 | Text::Table::HTML::DataTables |    162    |      6.19 |              4886.46% |               236.41% | 6.1e-06   |      20 |
 | Text::Table::HTML             |    167    |      6    |              5038.23% |               226.47% |   2e-06   |      20 |
 | Text::Table::CSV              |    284    |      3.52 |              8671.60% |                91.24% | 1.1e-06   |      20 |
 | Text::Table::Org              |    297    |      3.37 |              9061.61% |                83.10% | 1.2e-06   |      24 |
 | Text::Table::Sprintf          |    544    |      1.84 |             16674.90% |                 0.00% | 4.3e-07   |      20 |
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+-----------+---------+

 #table2#
 {dataset=>"long (3x300)"}
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                   | rate (/s) | time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | Text::ANSITable               |     29    | 34        |                 0.00% |             13332.77% | 6.5e-05 |      20 |
 | Text::ASCIITable              |    164    |  6.11     |               460.25% |              2297.63% | 3.4e-06 |      20 |
 | Text::FormatTable             |    204    |  4.9      |               597.89% |              1824.76% | 3.1e-06 |      20 |
 | Text::Table::TinyColorWide    |    210    |  4.7      |               627.62% |              1746.14% | 6.5e-06 |      20 |
 | Text::Table::TinyWide         |    304    |  3.28     |               941.79% |              1189.39% | 2.5e-06 |      20 |
 | Text::TabularDisplay          |    429    |  2.33     |              1367.74% |               815.20% |   2e-06 |      20 |
 | Text::Table::Tiny             |    483    |  2.07     |              1553.46% |               712.40% | 6.8e-07 |      21 |
 | Text::MarkdownTable           |    540    |  1.8      |              1751.92% |               625.34% | 3.3e-06 |      20 |
 | Text::Table                   |    600    |  1.7      |              1961.60% |               551.57% | 1.2e-05 |      35 |
 | Text::Table::TinyColor        |    733    |  1.36     |              2407.03% |               435.80% | 1.2e-06 |      26 |
 | Text::Table::HTML::DataTables |   1290    |  0.773    |              4324.34% |               203.61% |   2e-07 |      22 |
 | Text::Table::HTML             |   1350    |  0.741    |              4515.31% |               191.05% | 2.7e-07 |      20 |
 | Text::Table::Org              |   2157.23 |  0.463558 |              7281.87% |                81.97% |   0     |      23 |
 | Text::Table::CSV              |   2180    |  0.459    |              7347.86% |                80.36% | 2.1e-07 |      20 |
 | Text::Table::Sprintf          |   3930    |  0.255    |             13332.77% |                 0.00% | 2.1e-07 |      20 |
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

 #table3#
 {dataset=>"small (3x5)"}
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                   | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | Text::ANSITable               |   1110    | 899       |                 0.00% |             10766.79% | 2.7e-07 |      20 |
 | Text::ASCIITable              |   6200    | 160       |               455.09% |              1857.66% | 3.7e-07 |      20 |
 | Text::FormatTable             |   8727.25 | 114.584   |               684.62% |              1284.97% |   0     |      22 |
 | Text::Table                   |   9500    | 100       |               757.80% |              1166.82% |   2e-07 |      22 |
 | Text::Table::TinyColorWide    |   9750    | 103       |               776.72% |              1139.48% | 5.2e-08 |      21 |
 | Text::Table::TinyWide         |  14000    |  72       |              1140.93% |               775.70% | 1.1e-07 |      20 |
 | Text::MarkdownTable           |  15000    |  67       |              1251.11% |               704.29% | 1.9e-07 |      26 |
 | Text::TabularDisplay          |  18600    |  53.6     |              1576.31% |               548.26% | 2.7e-08 |      20 |
 | Text::Table::Tiny             |  18776.9  |  53.2569  |              1588.13% |               543.72% |   0     |      20 |
 | Text::Table::HTML::DataTables |  28000    |  36       |              2419.86% |               331.25% | 1.6e-07 |      39 |
 | Text::Table::TinyColor        |  29614    |  33.7678  |              2562.43% |               308.15% |   0     |      22 |
 | Text::Table::HTML             |  58600    |  17.1     |              5165.48% |               106.38% | 5.3e-09 |      32 |
 | Text::Table::Org              |  67600    |  14.8     |              5979.50% |                78.74% | 5.4e-09 |      30 |
 | Text::Table::CSV              |  96701.9  |  10.3411  |              8593.95% |                24.99% |   0     |      21 |
 | Text::Table::Sprintf          | 120870    |   8.27335 |             10766.79% |                 0.00% |   0     |      20 |
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

 #table4#
 {dataset=>"tiny (1x1)"}
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                   | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | Text::ANSITable               |    3970   | 252       |                 0.00% |              8969.60% | 1.9e-07 |      24 |
 | Text::ASCIITable              |   22000   |  45       |               457.59% |              1526.57% | 5.3e-08 |      20 |
 | Text::Table                   |   25000   |  40       |               528.25% |              1343.62% | 6.7e-08 |      20 |
 | Text::MarkdownTable           |   30000   |  33       |               654.24% |              1102.48% | 5.3e-08 |      20 |
 | Text::FormatTable             |   43000   |  23       |               978.37% |               741.04% | 2.9e-08 |      27 |
 | Text::Table::HTML::DataTables |   46000   |  22       |              1058.69% |               682.74% | 5.3e-08 |      20 |
 | Text::Table::TinyColorWide    |   57672.6 |  17.3393  |              1354.53% |               523.54% |   0     |      20 |
 | Text::Table::Tiny             |   60000   |  20       |              1378.29% |               513.52% |   2e-07 |      20 |
 | Text::Table::TinyWide         |   75000   |  13.3     |              1792.00% |               379.37% | 5.1e-09 |      34 |
 | Text::TabularDisplay          |   75000   |  13       |              1793.80% |               378.91% | 2.7e-08 |      20 |
 | Text::Table::TinyColor        |  116000   |   8.62    |              2826.12% |               209.95% | 2.8e-09 |      28 |
 | Text::Table::Org              |  184256   |   5.42722 |              4547.04% |                95.17% |   0     |      20 |
 | Text::Table::HTML             |  224283   |   4.45865 |              5556.54% |                60.34% |   0     |      20 |
 | Text::Table::CSV              |  357000   |   2.8     |              8900.47% |                 0.77% | 8.1e-10 |      21 |
 | Text::Table::Sprintf          |  360000   |   2.78    |              8969.60% |                 0.00% | 8.3e-10 |      20 |
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

 #table5#
 {dataset=>"wide (30x5)"}
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                   | rate (/s) | time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | Text::ANSITable               |    140    |   7.2     |                 0.00% |             13367.08% | 2.3e-05 |      23 |
 | Text::ASCIITable              |    647    |   1.55    |               364.09% |              2801.80% | 1.1e-06 |      20 |
 | Text::FormatTable             |    860    |   1.2     |               515.55% |              2087.80% | 3.8e-06 |      20 |
 | Text::Table::TinyColorWide    |   1080    |   0.927   |               673.30% |              1641.52% | 2.1e-07 |      20 |
 | Text::Table                   |   1000    |   0.7     |               862.81% |              1298.73% | 1.5e-05 |      20 |
 | Text::Table::TinyWide         |   1500    |   0.65    |               998.44% |              1126.02% |   1e-06 |      21 |
 | Text::Table::Tiny             |   2500    |   0.401   |              1689.78% |               652.44% | 5.2e-08 |      21 |
 | Text::TabularDisplay          |   2800    |   0.36    |              1878.08% |               580.81% | 3.7e-07 |      20 |
 | Text::Table::TinyColor        |   3733.57 |   0.26784 |              2577.78% |               402.92% |   0     |      26 |
 | Text::MarkdownTable           |   4400    |   0.227   |              3056.99% |               326.58% | 2.1e-07 |      20 |
 | Text::Table::HTML::DataTables |   6900    |   0.14    |              4858.71% |               171.58% | 1.8e-07 |      29 |
 | Text::Table::HTML             |   8210    |   0.122   |              5788.46% |               128.70% | 4.9e-08 |      24 |
 | Text::Table::Org              |  11300    |   0.0885  |              8006.26% |                66.13% | 2.5e-08 |      22 |
 | Text::Table::CSV              |  14600    |   0.0686  |             10347.90% |                28.90% | 2.7e-08 |      20 |
 | Text::Table::Sprintf          |  18800    |   0.0533  |             13367.08% |                 0.00% | 2.2e-08 |      30 |
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+


Benchmark module startup overhead (C<< bencher --cpanmodules-module TextTable --module-startup >>):

 #table6#
 +-------------------------------+-----------+-------------------+-----------------------+-----------------------+-----------+---------+
 | participant                   | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors   | samples |
 +-------------------------------+-----------+-------------------+-----------------------+-----------------------+-----------+---------+
 | Text::ANSITable               |      36   |              30   |                 0.00% |               748.19% |   0.0001  |      20 |
 | Text::MarkdownTable           |      34   |              28   |                 6.09% |               699.49% | 9.9e-05   |      20 |
 | Text::Table::TinyColorWide    |      26   |              20   |                39.59% |               507.63% |   0.00018 |      20 |
 | Text::Table::TinyWide         |      24   |              18   |                49.52% |               467.28% | 9.2e-05   |      20 |
 | Text::Table                   |      17   |              11   |               107.81% |               308.15% | 9.3e-05   |      24 |
 | Text::Table::Tiny             |      10   |               4   |               160.32% |               225.82% |   0.00031 |      20 |
 | Text::ASCIITable              |      10   |               4   |               164.39% |               220.81% |   0.00025 |      20 |
 | Text::FormatTable             |      10   |               4   |               236.26% |               152.25% |   0.00014 |      20 |
 | Text::Table::TinyColor        |      10   |               4   |               271.83% |               128.11% |   0.00013 |      20 |
 | Text::TabularDisplay          |       9   |               3   |               317.88% |               102.97% |   0.00013 |      20 |
 | Text::Table::HTML             |       8   |               2   |               347.70% |                89.46% |   0.00018 |      20 |
 | Text::Table::HTML::DataTables |       8   |               2   |               352.66% |                87.38% | 8.8e-05   |      22 |
 | Text::Table::CSV              |       6.8 |               0.8 |               427.09% |                60.92% | 4.8e-05   |      20 |
 | Text::Table::Org              |       6   |               0   |               465.76% |                49.92% |   0.00011 |      20 |
 | perl -e1 (baseline)           |       6   |               0   |               473.15% |                47.99% | 7.8e-05   |      20 |
 | Text::Table::Sprintf          |       4.3 |              -1.7 |               748.19% |                 0.00% | 2.7e-05   |      20 |
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
 | Text::Table::Tiny             | yes          | yes       | yes           |
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
