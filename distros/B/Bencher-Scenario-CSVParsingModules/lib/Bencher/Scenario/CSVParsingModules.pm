package Bencher::Scenario::CSVParsingModules;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-07-31'; # DATE
our $DIST = 'Bencher-Scenario-CSVParsingModules'; # DIST
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;

use File::ShareDir::Tarball qw(dist_dir);

our $scenario = {
    summary => 'Benchmark CSV parsing modules',
    modules => {
        # minimum versions
        #'Foo' => {version=>'0.31'},
    },
    participants => [
        {
            module => 'Text::CSV_PP',
            code_template => 'my $csv = Text::CSV_PP->new({binary=>1}); open my $fh, "<", <filename>; my $rows = []; while (my $row = $csv->getline($fh)) { push @$rows, $row }',
        },
        {
            module => 'Text::CSV_XS',
            code_template => 'my $csv = Text::CSV_XS->new({binary=>1}); open my $fh, "<", <filename>; my $rows = []; while (my $row = $csv->getline($fh)) { push @$rows, $row }',
        },
        {
            name => 'naive-split',
            code_template => 'open my $fh, "<", <filename>; my $rows = []; while (defined(my $row = <$fh>)) { chomp $row; push @$rows, [split /,/, $row] }',
        },
    ],

    datasets => [
    ],
};

my $dir = dist_dir('CSV-Examples')
    or die "Can't find share dir for CSV-Examples";
for my $filename (glob "$dir/examples/*bench*.csv") {
    my $basename = $filename; $basename =~ s!.+/!!;
    push @{ $scenario->{datasets} }, {
        name => $basename,
        args => {filename => $filename},
    };
}

1;
# ABSTRACT: Benchmark CSV parsing modules

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::CSVParsingModules - Benchmark CSV parsing modules

=head1 VERSION

This document describes version 0.002 of Bencher::Scenario::CSVParsingModules (from Perl distribution Bencher-Scenario-CSVParsingModules), released on 2021-07-31.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m CSVParsingModules

To run module startup overhead benchmark:

 % bencher --module-startup -m CSVParsingModules

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Text::CSV_PP> 2.01

L<Text::CSV_XS> 1.46

=head1 BENCHMARK PARTICIPANTS

=over

=item * Text::CSV_PP (perl_code)

Code template:

 my $csv = Text::CSV_PP->new({binary=>1}); open my $fh, "<", <filename>; my $rows = []; while (my $row = $csv->getline($fh)) { push @$rows, $row }



=item * Text::CSV_XS (perl_code)

Code template:

 my $csv = Text::CSV_XS->new({binary=>1}); open my $fh, "<", <filename>; my $rows = []; while (my $row = $csv->getline($fh)) { push @$rows, $row }



=item * naive-split (perl_code)

Code template:

 open my $fh, "<", <filename>; my $rows = []; while (defined(my $row = <$fh>)) { chomp $row; push @$rows, [split /,/, $row] }



=back

=head1 BENCHMARK DATASETS

=over

=item * bench-100x100.csv

=item * bench-10x10.csv

=item * bench-1x1.csv

=item * bench-5x5.csv

=back

=head1 BENCHMARK SAMPLE RESULTS

=head2 Sample benchmark #1

Run on: perl: I<< v5.34.0 >>, CPU: I<< Intel(R) Core(TM) i7-4770 CPU @ 3.40GHz (4 cores) >>, OS: I<< GNU/Linux LinuxMint version 19 >>, OS kernel: I<< Linux version 5.3.0-68-generic >>.

Benchmark command (default options):

 % bencher -m CSVParsingModules

Result formatted as table (split, part 1 of 4):

 #table1#
 {dataset=>"bench-100x100.csv"}
 | participant  | rate (/s) | time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 |--------------+-----------+-----------+-----------------------+-----------------------+---------+---------|
 | Text::CSV_PP |      32.7 |      30.6 |                 0.00% |              2073.95% |   2e-05 |      20 |
 | Text::CSV_XS |     640   |       1.6 |              1854.86% |                11.21% | 6.2e-06 |      20 |
 | naive-split  |     710   |       1.4 |              2073.95% |                 0.00% | 2.5e-06 |      20 |

The above result formatted in L<Benchmark.pm|Benchmark> style:

                  Rate  Text::CSV_PP  Text::CSV_XS  naive-split 
  Text::CSV_PP  32.7/s            --          -94%         -95% 
  Text::CSV_XS   640/s         1812%            --         -12% 
  naive-split    710/s         2085%           14%           -- 
 
 Legends:
   Text::CSV_PP: participant=Text::CSV_PP
   Text::CSV_XS: participant=Text::CSV_XS
   naive-split: participant=naive-split

The above result presented as chart:

=begin html

<img src="data:image/png;base64,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" />

=end html


Result formatted as table (split, part 2 of 4):

 #table2#
 {dataset=>"bench-10x10.csv"}
 | participant  | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 |--------------+-----------+-----------+-----------------------+-----------------------+---------+---------|
 | Text::CSV_PP |      1600 |       620 |                 0.00% |              2364.58% | 1.1e-06 |      20 |
 | Text::CSV_XS |     19000 |        54 |              1061.89% |               112.12% | 1.1e-07 |      20 |
 | naive-split  |     39000 |        25 |              2364.58% |                 0.00% | 5.3e-08 |      20 |

The above result formatted in L<Benchmark.pm|Benchmark> style:

                   Rate  Text::CSV_PP  Text::CSV_XS  naive-split 
  Text::CSV_PP   1600/s            --          -91%         -95% 
  Text::CSV_XS  19000/s         1048%            --         -53% 
  naive-split   39000/s         2380%          116%           -- 
 
 Legends:
   Text::CSV_PP: participant=Text::CSV_PP
   Text::CSV_XS: participant=Text::CSV_XS
   naive-split: participant=naive-split

The above result presented as chart:

=begin html

<img src="data:image/png;base64,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" />

=end html


Result formatted as table (split, part 3 of 4):

 #table3#
 {dataset=>"bench-1x1.csv"}
 | participant  | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 |--------------+-----------+-----------+-----------------------+-----------------------+---------+---------|
 | Text::CSV_PP |      7500 |     130   |                 0.00% |              2000.62% | 2.7e-07 |      20 |
 | Text::CSV_XS |     42700 |      23.4 |               466.40% |               270.87% |   2e-08 |      20 |
 | naive-split  |    160000 |       6.3 |              2000.62% |                 0.00% | 1.3e-08 |      20 |

The above result formatted in L<Benchmark.pm|Benchmark> style:

                    Rate  Text::CSV_PP  Text::CSV_XS  naive-split 
  Text::CSV_PP    7500/s            --          -82%         -95% 
  Text::CSV_XS   42700/s          455%            --         -73% 
  naive-split   160000/s         1963%          271%           -- 
 
 Legends:
   Text::CSV_PP: participant=Text::CSV_PP
   Text::CSV_XS: participant=Text::CSV_XS
   naive-split: participant=naive-split

The above result presented as chart:

=begin html

<img src="data:image/png;base64,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" />

=end html


Result formatted as table (split, part 4 of 4):

 #table4#
 {dataset=>"bench-5x5.csv"}
 | participant  | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 |--------------+-----------+-----------+-----------------------+-----------------------+---------+---------|
 | Text::CSV_PP |      3370 |     296   |                 0.00% |              2429.52% | 2.5e-07 |      22 |
 | Text::CSV_XS |     33000 |      30   |               878.84% |               158.42% | 5.3e-08 |      20 |
 | naive-split  |     85400 |      11.7 |              2429.52% |                 0.00% | 3.2e-09 |      22 |

The above result formatted in L<Benchmark.pm|Benchmark> style:

                   Rate  Text::CSV_PP  Text::CSV_XS  naive-split 
  Text::CSV_PP   3370/s            --          -89%         -96% 
  Text::CSV_XS  33000/s          886%            --         -61% 
  naive-split   85400/s         2429%          156%           -- 
 
 Legends:
   Text::CSV_PP: participant=Text::CSV_PP
   Text::CSV_XS: participant=Text::CSV_XS
   naive-split: participant=naive-split

The above result presented as chart:

=begin html

<img src="data:image/png;base64,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" />

=end html


=head2 Sample benchmark #2

Benchmark command (benchmarking module startup overhead):

 % bencher -m CSVParsingModules --module-startup

Result formatted as table:

 #table5#
 | participant         | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 |---------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------|
 | Text::CSV_PP        |      20   |              13.9 |                 0.00% |               233.89% | 9.8e-05 |      20 |
 | Text::CSV_XS        |      17   |              10.9 |                21.13% |               175.64% | 5.4e-05 |      20 |
 | perl -e1 (baseline) |       6.1 |               0   |               233.89% |                 0.00% | 5.3e-05 |      20 |


The above result formatted in L<Benchmark.pm|Benchmark> style:

                          Rate  T:C_P  T:C_X  perl -e1 (baseline) 
  T:C_P                 50.0/s     --   -15%                 -69% 
  T:C_X                 58.8/s    17%     --                 -64% 
  perl -e1 (baseline)  163.9/s   227%   178%                   -- 
 
 Legends:
   T:C_P: mod_overhead_time=13.9 participant=Text::CSV_PP
   T:C_X: mod_overhead_time=10.9 participant=Text::CSV_XS
   perl -e1 (baseline): mod_overhead_time=0 participant=perl -e1 (baseline)

The above result presented as chart:

=begin html

<img src="data:image/png;base64,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bFeVYdi/fQa0LUAb2gU61HP7XxXQlgBtaA/oez9fIB72vyqgLQHa0M6jHK8M0JYAbWgP6LJ57asC2hKgDe2aQ9cNUw5AX6Ndx6FTx04hoK/RzlPfrwzQlgBtaNdRDnYKAX2V9oB2dTnfB2//qwLaEqAN7ZtDL+1/VUBbArQhLsECtFSABrRUgAa0VD8J2ifPHBrQl2nPFrpajm+U+z9hAtCWAG3op0FX/t5MB+2GyCVY7xOgDf006LLu4nzm+8YlWO8ToA3tuo3BKy6+WgK0JUAb4igHoKUCNKClAjSgpQI0oKUCNKClAjSgpQI0oKU6APTjBGL7xZlxQFsCtCE76GpetNTGlJ63RAe0JUAbsoKuhm4G3TeFa+L6LKAtAdqQFXRZz6B9ctO2et1EA9oSoA3Zpxx+Au38/GidRgPaEqANHQR6quq2+3cA2hKgDR0G2oX0vH3Hp8/zgtNXr9J7pwCt2HLT56NAt139xce+sYW2BGhDR4GOL24XBmhLgDZ0EOghvbi3EqAtAdrQQaDDy+vCAW0J0IZYywFoqQANaKkADWipAA1oqQANaKkADWipAA1oqQANaKkADWipAA1oqQANaKkADWipAA1oqQANaKkADWipAA1oqQANaKkADWipAA1oqQANaKkADWipAA1oqQANaKkADWipAA1oqQANaKkADWipAA1oqQANaKkADWipAA1oqQANaKkADWipAA1oqQANaKkADWipAA1oqQANaKkADWipAA1oqQANaKkADWipDgD9+ITv1j2fArQlQBuyg67mT/iuupSa7TlAWwK0ISvoauhm0PXNVTGszwLaEqANWUGX9Qy6Sm1R3Lv1WUBbArQh+5TDpxdf5gBtCdCGDgJdLqDX/cJP3/mp6uyf7isBWrF2NncQ6PsCehX86dsw5c/+Gb8SoBUrZ3NMOQAt1UGgq2njXMb1OUBbArShg0AXdVj+WwK0JUAbOgp023ex284VAtoSoA0dtpbD+S92AQFtCdCGWJwEaKkADWipAA1oqQANaKkADWipAA1oqQANaKkADWipAA1oqQANaKkADWipAA1oqQANaKkADWipAA1oqQANaKkADWipAA1oqQANaKkADWipAA1oqQANaKkADWipAA1oqQANaKkADWipAA1oqQANaKkADWipAA1oqQANaKkADWipAA1oqQANaKkADWipAA1o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" />

=end html


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 CONTRIBUTOR

=for stopwords perlancar (on pc-office)

perlancar (on pc-office) <perlancar@gmail.com>

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-CSVParsingModules>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-CSVParsingModules>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-CSVParsingModules>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
