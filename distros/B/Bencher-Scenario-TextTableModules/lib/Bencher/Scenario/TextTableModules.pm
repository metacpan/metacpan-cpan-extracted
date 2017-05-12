package Bencher::Scenario::TextTableModules;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.08'; # VERSION

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

our $scenario = {
    summary => 'Benchmark modules that generate text table',
    participants => [
        {
            module => 'Text::ANSITable',
            code => sub {
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
        },
        {
            module => 'Text::ASCIITable',
            code => sub {
                my ($table) = @_;
                my $t = Text::ASCIITable->new();
                $t->setCols(@{ $table->[0] });
                $t->addRow(@{ $table->[$_] }) for 1..@$table-1;
                "$t";
            },
        },
        {
            module => 'Text::FormatTable',
            code => sub {
                my ($table) = @_;
                my $t = Text::FormatTable->new(join('|', ('l') x @{ $table->[0] }));
                $t->head(@{ $table->[0] });
                $t->row(@{ $table->[$_] }) for 1..@$table-1;
                $t->render;
            },
        },
        {
            module => 'Text::MarkdownTable',
            code => sub {
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
        },
        {
            module => 'Text::Table',
            code => sub {
                my ($table) = @_;
                my $t = Text::Table->new(@{ $table->[0] });
                $t->load(@{ $table }[1..@$table-1]);
                $t;
            },
        },
        {
            module => 'Text::Table::Tiny',
            code => sub {
                my ($table) = @_;
                Text::Table::Tiny::table(rows=>$table, header_row=>1);
            },
        },
        {
            module => 'Text::Table::TinyColor',
            code => sub {
                my ($table) = @_;
                Text::Table::TinyColor::table(rows=>$table, header_row=>1);
            },
        },
        {
            module => 'Text::Table::TinyColorWide',
            code => sub {
                my ($table) = @_;
                Text::Table::TinyColorWide::table(rows=>$table, header_row=>1);
            },
        },
        {
            module => 'Text::Table::TinyWide',
            code => sub {
                my ($table) = @_;
                Text::Table::TinyWide::table(rows=>$table, header_row=>1);
            },
        },
        {
            module => 'Text::Table::Org',
            code => sub {
                my ($table) = @_;
                Text::Table::Org::table(rows=>$table, header_row=>1);
            },
        },
        {
            module => 'Text::Table::CSV',
            code => sub {
                my ($table) = @_;
                Text::Table::CSV::table(rows=>$table, header_row=>1);
            },
        },
        {
            module => 'Text::Table::HTML',
            code => sub {
                my ($table) = @_;
                Text::Table::HTML::table(rows=>$table, header_row=>1);
            },
        },
        {
            module => 'Text::Table::HTML::DataTables',
            code => sub {
                my ($table) = @_;
                Text::Table::HTML::DataTables::table(rows=>$table, header_row=>1);
            },
        },
        {
            module => 'Text::TabularDisplay',
            code => sub {
                my ($table) = @_;
                my $t = Text::TabularDisplay->new(@{ $table->[0] });
                $t->add(@{ $table->[$_] }) for 1..@$table-1;
                $t->render; # doesn't add newline
            },
        },
    ],

    datasets => [
        {name=>'tiny (1x1)'    , argv => [_make_table( 1, 1)],},
        {name=>'small (3x5)'   , argv => [_make_table( 3, 5)],},
        {name=>'wide (30x5)'   , argv => [_make_table(30, 5)],},
        {name=>'long (3x300)'  , argv => [_make_table( 3, 300)],},
        {name=>'large (30x300)', argv => [_make_table(30, 300)],},
    ],

};

1;
# ABSTRACT: Benchmark modules that generate text table

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::TextTableModules - Benchmark modules that generate text table

=head1 VERSION

This document describes version 0.08 of Bencher::Scenario::TextTableModules (from Perl distribution Bencher-Scenario-TextTableModules), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m TextTableModules

To run module startup overhead benchmark:

 % bencher --module-startup -m TextTableModules

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Text::ANSITable> 0.48

L<Text::ASCIITable> 0.20

L<Text::FormatTable> 1.03

L<Text::MarkdownTable> 0.3.1

L<Text::Table> 1.131

L<Text::Table::Tiny> 0.04

L<Text::Table::TinyColor> 0.002

L<Text::Table::TinyColorWide> 0.001

L<Text::Table::TinyWide> 0.001

L<Text::Table::Org> 0.02

L<Text::Table::CSV> 0.01

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

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m TextTableModules >>):

 #table1#
 {dataset=>"large (30x300)"}
 +-------------------------------+-----------+-----------+------------+-----------+---------+
 | participant                   | rate (/s) | time (ms) | vs_slowest |  errors   | samples |
 +-------------------------------+-----------+-----------+------------+-----------+---------+
 | Text::ANSITable               |       2.6 |     390   |        1   |   0.00091 |      21 |
 | Text::ASCIITable              |       5.7 |     180   |        2.2 |   0.00022 |      21 |
 | Text::Table::TinyColorWide    |      13   |      75   |        5.2 |   0.00021 |      20 |
 | Text::FormatTable             |      17   |      59   |        6.6 |   0.00034 |      20 |
 | Text::Table::TinyWide         |      18   |      54   |        7.2 | 8.1e-05   |      20 |
 | Text::TabularDisplay          |      39   |      26   |       15   | 7.3e-05   |      21 |
 | Text::Table::TinyColor        |      53   |      19   |       21   |   0.00013 |      20 |
 | Text::MarkdownTable           |      83   |      12   |       32   |   7e-05   |      20 |
 | Text::Table                   |     100   |      10   |       40   |   0.00012 |      20 |
 | Text::Table::HTML::DataTables |     110   |       9.4 |       42   | 8.2e-05   |      20 |
 | Text::Table::HTML             |     110   |       9.1 |       43   | 6.6e-05   |      23 |
 | Text::Table::CSV              |     190   |       5.3 |       74   | 3.6e-05   |      20 |
 | Text::Table::Org              |     230   |       4.4 |       89   | 2.2e-05   |      23 |
 | Text::Table::Tiny             |     260   |       3.8 |      100   | 3.6e-05   |      20 |
 +-------------------------------+-----------+-----------+------------+-----------+---------+

 #table2#
 {dataset=>"long (3x300)"}
 +-------------------------------+-----------+-----------+------------+-----------+---------+
 | participant                   | rate (/s) | time (ms) | vs_slowest |  errors   | samples |
 +-------------------------------+-----------+-----------+------------+-----------+---------+
 | Text::ANSITable               |        23 |    44     |        1   |   0.00023 |      20 |
 | Text::ASCIITable              |        59 |    17     |        2.6 |   0.00017 |      20 |
 | Text::Table::TinyColorWide    |       130 |     7.4   |        5.9 | 3.1e-05   |      20 |
 | Text::FormatTable             |       140 |     7     |        6.3 | 5.1e-05   |      25 |
 | Text::Table::TinyWide         |       200 |     6     |        8   | 5.7e-05   |      20 |
 | Text::TabularDisplay          |       290 |     3.4   |       13   | 2.3e-05   |      23 |
 | Text::MarkdownTable           |       391 |     2.56  |       17.2 | 1.4e-06   |      22 |
 | Text::Table                   |       439 |     2.28  |       19.3 | 1.9e-06   |      21 |
 | Text::Table::TinyColor        |       508 |     1.97  |       22.3 | 1.1e-06   |      20 |
 | Text::Table::HTML::DataTables |       920 |     1.1   |       40   | 3.4e-06   |      21 |
 | Text::Table::HTML             |       930 |     1.1   |       41   | 3.8e-06   |      20 |
 | Text::Table::CSV              |      1500 |     0.69  |       64   | 9.1e-07   |      20 |
 | Text::Table::Org              |      1600 |     0.61  |       72   | 2.6e-06   |      24 |
 | Text::Table::Tiny             |      2060 |     0.486 |       90.4 | 2.7e-07   |      20 |
 +-------------------------------+-----------+-----------+------------+-----------+---------+

 #table3#
 {dataset=>"small (3x5)"}
 +-------------------------------+-----------+-----------+------------+---------+---------+
 | participant                   | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +-------------------------------+-----------+-----------+------------+---------+---------+
 | Text::ANSITable               |     972   | 1030      |     1      | 4.8e-07 |      20 |
 | Text::ASCIITable              |    2500   |  400      |     2.6    | 1.1e-06 |      20 |
 | Text::Table::TinyColorWide    |    5700   |  170      |     5.9    | 4.3e-07 |      20 |
 | Text::FormatTable             |    5900   |  170      |     6.1    | 2.1e-07 |      20 |
 | Text::Table                   |    6700   |  150      |     6.8    | 2.7e-07 |      20 |
 | Text::Table::TinyWide         |    7880   |  127      |     8.11   | 5.3e-08 |      20 |
 | Text::MarkdownTable           |   10000   |   95      |    11      | 4.5e-07 |      20 |
 | Text::TabularDisplay          |   13000   |   77      |    13      | 1.1e-07 |      20 |
 | Text::Table::TinyColor        |   19000   |   53      |    20      |   8e-08 |      20 |
 | Text::Table::HTML::DataTables |   20600   |   48.5    |    21.2    | 4.8e-08 |      25 |
 | Text::Table::HTML             |   38959.9 |   25.6674 |    40.0973 |   0     |      20 |
 | Text::Table::Org              |   51000   |   20      |    52      | 3.6e-08 |      25 |
 | Text::Table::Tiny             |   51000   |   19      |    53      |   2e-08 |      20 |
 | Text::Table::CSV              |   63500   |   15.8    |    65.3    | 6.5e-09 |      21 |
 +-------------------------------+-----------+-----------+------------+---------+---------+

 #table4#
 {dataset=>"tiny (1x1)"}
 +-------------------------------+-----------+-----------+------------+---------+---------+
 | participant                   | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +-------------------------------+-----------+-----------+------------+---------+---------+
 | Text::ANSITable               |      3300 |     300   |        1   | 8.5e-07 |      23 |
 | Text::ASCIITable              |      8800 |     110   |        2.7 | 2.1e-07 |      20 |
 | Text::Table                   |     17000 |      59   |        5.2 | 1.1e-07 |      28 |
 | Text::MarkdownTable           |     21000 |      47   |        6.5 | 6.7e-08 |      20 |
 | Text::FormatTable             |     27000 |      37   |        8.3 | 1.4e-07 |      31 |
 | Text::Table::HTML::DataTables |     32000 |      31   |        9.6 | 1.2e-07 |      35 |
 | Text::Table::TinyColorWide    |     32000 |      31   |        9.7 | 5.3e-08 |      20 |
 | Text::Table::TinyWide         |     45000 |      22   |       14   | 6.7e-08 |      33 |
 | Text::TabularDisplay          |     51000 |      20   |       15   | 5.7e-08 |      22 |
 | Text::Table::TinyColor        |     80000 |      10   |       20   | 2.6e-07 |      23 |
 | Text::Table::Tiny             |    120000 |       8.6 |       35   | 1.7e-08 |      20 |
 | Text::Table::Org              |    130000 |       8   |       38   | 1.3e-08 |      20 |
 | Text::Table::HTML             |    150000 |       6.6 |       46   | 1.3e-08 |      22 |
 | Text::Table::CSV              |    240000 |       4.2 |       72   |   5e-09 |      20 |
 +-------------------------------+-----------+-----------+------------+---------+---------+

 #table5#
 {dataset=>"wide (30x5)"}
 +-------------------------------+-----------+-----------+------------+---------+---------+
 | participant                   | rate (/s) | time (ms) | vs_slowest |  errors | samples |
 +-------------------------------+-----------+-----------+------------+---------+---------+
 | Text::ANSITable               |       110 |     8.8   |       1    | 8.4e-05 |      20 |
 | Text::ASCIITable              |       270 |     3.7   |       2.4  | 2.9e-05 |      23 |
 | Text::Table::TinyColorWide    |       700 |     1     |       6    | 1.9e-05 |      20 |
 | Text::FormatTable             |       709 |     1.41  |       6.24 | 6.9e-07 |      20 |
 | Text::Table::TinyWide         |       980 |     1     |       8.6  | 2.8e-06 |      20 |
 | Text::Table                   |      1040 |     0.96  |       9.17 | 8.5e-07 |      20 |
 | Text::TabularDisplay          |      2000 |     0.51  |      17    | 6.9e-07 |      20 |
 | Text::Table::TinyColor        |      2520 |     0.397 |      22.2  | 2.1e-07 |      20 |
 | Text::MarkdownTable           |      3070 |     0.326 |      27    | 2.1e-07 |      20 |
 | Text::Table::HTML::DataTables |      5210 |     0.192 |      45.9  | 5.3e-08 |      20 |
 | Text::Table::HTML             |      5400 |     0.18  |      48    | 2.7e-07 |      20 |
 | Text::Table::Org              |      8300 |     0.12  |      73    | 8.8e-07 |      21 |
 | Text::Table::CSV              |      9370 |     0.107 |      82.5  | 4.8e-08 |      25 |
 | Text::Table::Tiny             |      9500 |     0.11  |      83    | 1.6e-07 |      20 |
 +-------------------------------+-----------+-----------+------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m TextTableModules --module-startup >>):

 #table6#
 +-------------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+-----------+---------+
 | participant                   | proc_private_dirty_size (MB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors   | samples |
 +-------------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+-----------+---------+
 | Text::ANSITable               | 2.6                          | 6                  | 22             |      53   |                   46.9 |        1   |   0.00018 |      20 |
 | Text::MarkdownTable           | 2.8                          | 6.1                | 20             |      45   |                   38.9 |        1.2 |   0.00014 |      20 |
 | Text::Table::TinyColorWide    | 5.4                          | 9.2                | 29             |      41   |                   34.9 |        1.3 | 8.8e-05   |      20 |
 | Text::Table::TinyWide         | 0.88                         | 4.1                | 16             |      38   |                   31.9 |        1.4 | 7.5e-05   |      20 |
 | Text::ASCIITable              | 1.5                          | 4.8                | 17             |      21   |                   14.9 |        2.5 |   0.00011 |      20 |
 | Text::Table                   | 1.2                          | 4.7                | 18             |      21   |                   14.9 |        2.5 | 5.3e-05   |      20 |
 | Text::FormatTable             | 5.3                          | 9                  | 35             |      13   |                    6.9 |        3.9 | 6.9e-05   |      20 |
 | Text::Table::TinyColor        | 5.4                          | 9.2                | 29             |      13   |                    6.9 |        4   | 6.5e-05   |      20 |
 | Text::Table::Tiny             | 1.5                          | 5                  | 19             |      11   |                    4.9 |        4.7 | 4.5e-05   |      22 |
 | Text::TabularDisplay          | 0.82                         | 4.1                | 16             |       9.9 |                    3.8 |        5.3 | 7.2e-05   |      20 |
 | Text::Table::HTML::DataTables | 1                            | 4.5                | 16             |       8.9 |                    2.8 |        5.9 | 5.3e-05   |      21 |
 | Text::Table::HTML             | 0.89                         | 4.3                | 16             |       8.9 |                    2.8 |        6   | 4.3e-05   |      21 |
 | Text::Table::Org              | 0.86                         | 4.1                | 16             |       6.6 |                    0.5 |        8   | 2.2e-05   |      20 |
 | Text::Table::CSV              | 0.87                         | 4.3                | 16             |       6.5 |                    0.4 |        8.1 | 8.7e-06   |      20 |
 | perl -e1 (baseline)           | 6.7                          | 10                 | 30             |       6.1 |                    0   |        8.7 |   2e-05   |      20 |
 +-------------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+-----------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-TextTableModules>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-TextTableModules>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-TextTableModules>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
