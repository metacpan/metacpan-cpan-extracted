package Acme::CPANModules::TextTable;

our $DATE = '2019-02-24'; # DATE
our $VERSION = '0.002'; # VERSION

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
        color => {summary => 'Whether the module supports ANSI colors'},
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

This document describes version 0.002 of Acme::CPANModules::TextTable (from Perl distribution Acme-CPANModules-TextTable), released on 2019-02-24.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher --cpanmodules-module TextTable

To run module startup overhead benchmark:

 % bencher --module-startup --cpanmodules-module TextTable

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Modules that generate text tables.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Text::ANSITable> 0.501

L<Text::ASCIITable> 0.20

L<Text::FormatTable> 1.03

L<Text::MarkdownTable> 0.3.1

L<Text::Table> 1.131

L<Text::Table::Tiny> 0.04

L<Text::Table::TinyColor> 0.002

L<Text::Table::TinyColorWide> 0.001

L<Text::Table::TinyWide> 0.001

L<Text::Table::Org> 0.02

L<Text::Table::CSV> 0.021

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

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) i7-4770 CPU @ 3.40GHz (4 cores) >>, OS: I<< GNU/Linux LinuxMint version 18.2 >>, OS kernel: I<< Linux version 4.8.0-53-generic >>.

Benchmark with default options (C<< bencher --cpanmodules-module TextTable >>):

 #table1#
 {dataset=>"large (30x300)"}
 +-------------------------------+-----------+-----------+------------+-----------+---------+
 | participant                   | rate (/s) | time (ms) | vs_slowest |  errors   | samples |
 +-------------------------------+-----------+-----------+------------+-----------+---------+
 | Text::ANSITable               |       3.3 |     300   |        1   |   0.0007  |      20 |
 | Text::ASCIITable              |       7.8 |     130   |        2.4 |   0.00023 |      20 |
 | Text::Table::TinyColorWide    |      18   |      56   |        5.4 |   0.00024 |      21 |
 | Text::FormatTable             |      21   |      48   |        6.3 | 9.3e-05   |      20 |
 | Text::Table::TinyWide         |      25   |      40   |        7.6 | 8.7e-05   |      20 |
 | Text::TabularDisplay          |      50   |      20   |       15   | 7.8e-05   |      20 |
 | Text::Table::TinyColor        |      65   |      15   |       20   | 2.9e-05   |      20 |
 | Text::MarkdownTable           |     100   |       9.8 |       31   | 4.7e-05   |      20 |
 | Text::Table                   |     130   |       7.8 |       39   | 5.8e-05   |      20 |
 | Text::Table::HTML::DataTables |     140   |       7.1 |       42   | 1.6e-05   |      20 |
 | Text::Table::HTML             |     140   |       7.1 |       42   | 3.7e-05   |      20 |
 | Text::Table::CSV              |     250   |       4   |       76   | 1.5e-05   |      20 |
 | Text::Table::Org              |     260   |       3.8 |       79   | 2.6e-05   |      22 |
 | Text::Table::Tiny             |     320   |       3.1 |       96   | 1.2e-05   |      20 |
 +-------------------------------+-----------+-----------+------------+-----------+---------+

 #table2#
 {dataset=>"long (3x300)"}
 +-------------------------------+-----------+-----------+------------+-----------+---------+
 | participant                   | rate (/s) | time (ms) | vs_slowest |  errors   | samples |
 +-------------------------------+-----------+-----------+------------+-----------+---------+
 | Text::ANSITable               |        29 |    34     |        1   |   0.00014 |      20 |
 | Text::ASCIITable              |        81 |    12     |        2.8 | 3.3e-05   |      21 |
 | Text::Table::TinyColorWide    |       180 |     5.7   |        5.9 | 3.8e-05   |      22 |
 | Text::FormatTable             |       190 |     5.4   |        6.3 | 2.5e-05   |      20 |
 | Text::Table::TinyWide         |       230 |     4.3   |        7.9 | 6.5e-06   |      20 |
 | Text::TabularDisplay          |       370 |     2.7   |       13   | 9.8e-06   |      20 |
 | Text::MarkdownTable           |       490 |     2     |       17   | 1.8e-05   |      20 |
 | Text::Table                   |       600 |     2     |       20   | 2.5e-05   |      20 |
 | Text::Table::TinyColor        |       650 |     1.5   |       22   | 8.5e-06   |      20 |
 | Text::Table::HTML             |      1000 |     0.8   |       40   | 8.5e-06   |      20 |
 | Text::Table::HTML::DataTables |      1200 |     0.83  |       41   | 8.8e-07   |      21 |
 | Text::Table::Org              |      1900 |     0.51  |       66   | 6.8e-07   |      21 |
 | Text::Table::CSV              |      2000 |     0.501 |       67.7 | 2.7e-07   |      20 |
 | Text::Table::Tiny             |      2400 |     0.417 |       81.4 | 2.1e-07   |      20 |
 +-------------------------------+-----------+-----------+------------+-----------+---------+

 #table3#
 {dataset=>"small (3x5)"}
 +-------------------------------+-----------+-----------+------------+---------+---------+
 | participant                   | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +-------------------------------+-----------+-----------+------------+---------+---------+
 | Text::ANSITable               |    1200   |  830      |     1      | 4.4e-06 |      20 |
 | Text::ASCIITable              |    3440   |  291      |     2.87   | 2.1e-07 |      20 |
 | Text::Table::TinyColorWide    |    8100   |  120      |     6.7    | 4.3e-07 |      20 |
 | Text::FormatTable             |    8200   |  120      |     6.8    | 2.1e-07 |      20 |
 | Text::Table                   |    8800   |  110      |     7.4    | 2.1e-07 |      20 |
 | Text::Table::TinyWide         |   11700   |   85.2    |     9.78   | 2.7e-08 |      20 |
 | Text::MarkdownTable           |   15000   |   67      |    12      | 1.3e-07 |      20 |
 | Text::TabularDisplay          |   17000   |   59      |    14      | 7.5e-08 |      23 |
 | Text::Table::HTML::DataTables |   26000   |   39      |    21      | 5.2e-08 |      21 |
 | Text::Table::TinyColor        |   27000   |   38      |    22      | 1.7e-07 |      20 |
 | Text::Table::HTML             |   54700   |   18.3    |    45.6    | 6.4e-09 |      22 |
 | Text::Table::Org              |   60000   |   17      |    50      | 2.4e-08 |      24 |
 | Text::Table::Tiny             |   64895.4 |   15.4094 |    54.1096 | 5.8e-12 |      22 |
 | Text::Table::CSV              |   89036.3 |   11.2314 |    74.2382 | 5.8e-12 |      20 |
 +-------------------------------+-----------+-----------+------------+---------+---------+

 #table4#
 {dataset=>"tiny (1x1)"}
 +-------------------------------+-----------+-----------+------------+---------+---------+
 | participant                   | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +-------------------------------+-----------+-----------+------------+---------+---------+
 | Text::ANSITable               |      4600 |     220   |        1   | 6.4e-07 |      20 |
 | Text::ASCIITable              |     13000 |      77   |        2.8 | 1.2e-07 |      24 |
 | Text::Table                   |     22000 |      45   |        4.9 | 3.3e-07 |      20 |
 | Text::MarkdownTable           |     28000 |      36   |        6.1 | 2.7e-07 |      21 |
 | Text::FormatTable             |     38000 |      26   |        8.4 | 5.3e-08 |      20 |
 | Text::Table::HTML::DataTables |     42000 |      24   |        9.2 | 3.2e-08 |      22 |
 | Text::Table::TinyColorWide    |     48000 |      21   |       11   | 2.7e-08 |      20 |
 | Text::Table::TinyWide         |     64000 |      16   |       14   | 2.7e-08 |      20 |
 | Text::TabularDisplay          |     68000 |      15   |       15   | 2.7e-08 |      20 |
 | Text::Table::TinyColor        |    110000 |       9.5 |       23   |   1e-08 |      20 |
 | Text::Table::Tiny             |    150000 |       6.5 |       34   |   1e-08 |      20 |
 | Text::Table::Org              |    200000 |       6   |       40   | 6.3e-08 |      20 |
 | Text::Table::HTML             |    200000 |       4.9 |       45   | 1.3e-08 |      20 |
 | Text::Table::CSV              |    340000 |       3   |       74   | 6.7e-09 |      20 |
 +-------------------------------+-----------+-----------+------------+---------+---------+

 #table5#
 {dataset=>"wide (30x5)"}
 +-------------------------------+-----------+-----------+------------+---------+---------+
 | participant                   | rate (/s) | time (ms) | vs_slowest |  errors | samples |
 +-------------------------------+-----------+-----------+------------+---------+---------+
 | Text::ANSITable               |       150 |     6.7   |        1   | 2.9e-05 |      20 |
 | Text::ASCIITable              |       370 |     2.7   |        2.5 |   2e-05 |      20 |
 | Text::FormatTable             |       830 |     1.2   |        5.6 | 6.9e-06 |      20 |
 | Text::Table::TinyColorWide    |       920 |     1.1   |        6.2 | 4.5e-06 |      20 |
 | Text::Table::TinyWide         |      1200 |     0.83  |        8.1 |   4e-06 |      20 |
 | Text::Table                   |      1300 |     0.76  |        8.8 | 5.6e-06 |      20 |
 | Text::TabularDisplay          |      2400 |     0.41  |       16   | 1.2e-06 |      20 |
 | Text::Table::TinyColor        |      3400 |     0.3   |       23   | 1.6e-06 |      20 |
 | Text::MarkdownTable           |      4200 |     0.24  |       28   | 4.3e-07 |      20 |
 | Text::Table::HTML::DataTables |      6000 |     0.17  |       40   |   1e-06 |      21 |
 | Text::Table::HTML             |      7500 |     0.133 |       50.3 | 5.3e-08 |      20 |
 | Text::Table::Org              |     10000 |     0.096 |       70   | 1.1e-07 |      20 |
 | Text::Table::Tiny             |     11000 |     0.089 |       76   | 5.6e-07 |      20 |
 | Text::Table::CSV              |     13500 |     0.074 |       90.6 | 2.7e-08 |      20 |
 +-------------------------------+-----------+-----------+------------+---------+---------+


Benchmark module startup overhead (C<< bencher --cpanmodules-module TextTable --module-startup >>):

 #table6#
 +-------------------------------+-----------+------------------------+------------+-----------+---------+
 | participant                   | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors   | samples |
 +-------------------------------+-----------+------------------------+------------+-----------+---------+
 | Text::ANSITable               |      40   |                   36   |        1   |   0.00021 |      20 |
 | Text::MarkdownTable           |      32   |                   28   |        1.2 |   0.00021 |      20 |
 | Text::Table::TinyColorWide    |      31   |                   27   |        1.3 |   0.00011 |      20 |
 | Text::Table::TinyWide         |      30   |                   26   |        1.3 |   0.00016 |      21 |
 | Text::ASCIITable              |      20   |                   16   |        2   |   0.00017 |      20 |
 | Text::Table                   |      16   |                   12   |        2.5 | 7.3e-05   |      20 |
 | Text::FormatTable             |      11   |                    7   |        3.8 | 7.5e-05   |      20 |
 | Text::Table::TinyColor        |       9.7 |                    5.7 |        4.1 | 7.8e-05   |      20 |
 | Text::Table::Tiny             |       8   |                    4   |        5   |   0.00013 |      20 |
 | Text::TabularDisplay          |       8   |                    4   |        5   |   0.00011 |      20 |
 | Text::Table::HTML             |       8   |                    4   |        5   |   0.00015 |      20 |
 | Text::Table::HTML::DataTables |       7   |                    3   |        5   |   0.00015 |      20 |
 | Text::Table::CSV              |       6   |                    2   |        7   |   0.00012 |      20 |
 | Text::Table::Org              |       5   |                    1   |        7   |   0.00013 |      20 |
 | perl -e1 (baseline)           |       4   |                    0   |       10   | 3.9e-05   |      20 |
 +-------------------------------+-----------+------------------------+------------+-----------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 INCLUDED MODULES

=over

=item * L<Text::ANSITable>

=item * L<Text::ASCIITable>

=item * L<Text::FormatTable>

=item * L<Text::MarkdownTable>

=item * L<Text::Table>

=item * L<Text::Table::Tiny>

=item * L<Text::Table::TinyColor>

=item * L<Text::Table::TinyColorWide>

=item * L<Text::Table::TinyWide>

=item * L<Text::Table::Org>

=item * L<Text::Table::CSV>

=item * L<Text::Table::HTML>

=item * L<Text::Table::HTML::DataTables>

=item * L<Text::TabularDisplay>

=back

=head1 FEATURE COMPARISON MATRIX

 +-------------------------------+--------------+-----------+---------------+
 | module                        | box_char *1) | color *2) | wide_char *3) |
 +-------------------------------+--------------+-----------+---------------+
 | Text::ANSITable               | yes          | yes       | yes           |
 | Text::ASCIITable              | no           | no        | no            |
 | Text::FormatTable             | no           | no        | no            |
 | Text::MarkdownTable           | no           | no        | no            |
 | Text::Table                   | N/A *4)      | no        | no            |
 | Text::Table::Tiny             | no           | no        | no            |
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

=item 2. color: Whether the module supports ANSI colors

=item 3. wide_char: Whether the use of wide characters (e.g. Kanji) in cells does not cause the table to be misaligned

=item 4. Does not draw borders

=item 5. Irrelevant

=item 6. Irrelevant

=back

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

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
