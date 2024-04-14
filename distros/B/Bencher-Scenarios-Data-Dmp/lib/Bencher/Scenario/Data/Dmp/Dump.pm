package Bencher::Scenario::Data::Dmp::Dump;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-03-02'; # DATE
our $DIST = 'Bencher-Scenarios-Data-Dmp'; # DIST
our $VERSION = '0.004'; # VERSION

our $scenario = {
    summary => 'Benchmark Data::Dmp',
    modules => {
        'Data::Dmp' => {version=>'0.242'},
    },
    participants => [
        {name => 'Data::Dmp', fcall_template => 'Data::Dmp::dmp(<data>)'},
        {name => 'Data::MiniDumpX', fcall_template => 'Data::MiniDumpX::dump(<data>)'},
        {module => 'Data::Dump', code_template => 'my $dummy = Data::Dump::dump(<data>)'},
    ],
    datasets => [
        {
            name => 'a100-num-various',
            args => { data => [ (0, 1, -1, "+1", 1e100,
                                 -1e-100, "0123", "Inf", "-Inf", "NaN") x 10 ] },
        },
        {
            name => 'a100-num-int',
            args => { data => [ 1..100 ] },
        },
        {
            name => 'a100-str',
            args => { data => [ "a" x 100 ] },
        },
    ],
};

# ABSTRACT: Benchmark Data::Dmp

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::Data::Dmp::Dump - Benchmark Data::Dmp

=head1 VERSION

This document describes version 0.004 of Bencher::Scenario::Data::Dmp::Dump (from Perl distribution Bencher-Scenarios-Data-Dmp), released on 2024-03-02.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m Data::Dmp::Dump

To run module startup overhead benchmark:

 % bencher --module-startup -m Data::Dmp::Dump

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Data::Dmp> 0.242

L<Data::Dump> 1.25

L<Data::MiniDumpX> 0.000001

=head1 BENCHMARK PARTICIPANTS

=over

=item * Data::Dmp (perl_code)

Function call template:

 Data::Dmp::dmp(<data>)



=item * Data::MiniDumpX (perl_code)

Function call template:

 Data::MiniDumpX::dump(<data>)



=item * Data::Dump (perl_code)

Code template:

 my $dummy = Data::Dump::dump(<data>)



=back

=head1 BENCHMARK DATASETS

=over

=item * a100-num-various

=item * a100-num-int

=item * a100-str

=back

=head1 BENCHMARK SAMPLE RESULTS

=head2 Sample benchmark #1

Run on: perl: I<< v5.38.2 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 20.04 >>, OS kernel: I<< Linux version 5.4.0-164-generic >>.

Benchmark command (default options):

 % bencher -m Data::Dmp::Dump

Result formatted as table:

 #table1#
 +-----------------+------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant     | dataset          | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-----------------+------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | Data::Dump      | a100-num-various |      1600 |    630    |                 0.00% |             17587.16% | 8.3e-07 |      20 |
 | Data::Dump      | a100-num-int     |      3100 |    323    |                95.03% |              8968.85% | 2.3e-07 |      20 |
 | Data::MiniDumpX | a100-num-various |      3660 |    273    |               130.63% |              7569.15% | 2.7e-07 |      24 |
 | Data::MiniDumpX | a100-num-int     |      4310 |    232    |               171.28% |              6419.96% | 2.1e-07 |      20 |
 | Data::Dmp       | a100-num-various |      5720 |    175    |               260.32% |              4808.78% | 1.1e-07 |      23 |
 | Data::Dmp       | a100-num-int     |     12300 |     81.2  |               676.23% |              2178.60% | 5.2e-08 |      20 |
 | Data::Dump      | a100-str         |     76000 |     13    |              4701.80% |               268.34% | 5.1e-08 |      20 |
 | Data::MiniDumpX | a100-str         |    201000 |      4.97 |             12584.93% |                39.43% | 1.3e-09 |      21 |
 | Data::Dmp       | a100-str         |    281000 |      3.56 |             17587.16% |                 0.00% | 2.4e-09 |      20 |
 +-----------------+------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+


The above result formatted in L<Benchmark.pm|Benchmark> style:

                                  Rate  Dump a100-num-various  Dump a100-num-int  MiniDumpX a100-num-various  MiniDumpX a100-num-int  Dmp a100-num-various  Dmp a100-num-int  Dump a100-str  MiniDumpX a100-str  Dmp a100-str 
  Dump a100-num-various         1600/s                     --               -48%                        -56%                    -63%                  -72%              -87%           -97%                -99%          -99% 
  Dump a100-num-int             3100/s                    95%                 --                        -15%                    -28%                  -45%              -74%           -95%                -98%          -98% 
  MiniDumpX a100-num-various    3660/s                   130%                18%                          --                    -15%                  -35%              -70%           -95%                -98%          -98% 
  MiniDumpX a100-num-int        4310/s                   171%                39%                         17%                      --                  -24%              -64%           -94%                -97%          -98% 
  Dmp a100-num-various          5720/s                   260%                84%                         56%                     32%                    --              -53%           -92%                -97%          -97% 
  Dmp a100-num-int             12300/s                   675%               297%                        236%                    185%                  115%                --           -83%                -93%          -95% 
  Dump a100-str                76000/s                  4746%              2384%                       2000%                   1684%                 1246%              524%             --                -61%          -72% 
  MiniDumpX a100-str          201000/s                 12576%              6398%                       5392%                   4568%                 3421%             1533%           161%                  --          -28% 
  Dmp a100-str                281000/s                 17596%              8973%                       7568%                   6416%                 4815%             2180%           265%                 39%            -- 
 
 Legends:
   Dmp a100-num-int: dataset=a100-num-int participant=Data::Dmp
   Dmp a100-num-various: dataset=a100-num-various participant=Data::Dmp
   Dmp a100-str: dataset=a100-str participant=Data::Dmp
   Dump a100-num-int: dataset=a100-num-int participant=Data::Dump
   Dump a100-num-various: dataset=a100-num-various participant=Data::Dump
   Dump a100-str: dataset=a100-str participant=Data::Dump
   MiniDumpX a100-num-int: dataset=a100-num-int participant=Data::MiniDumpX
   MiniDumpX a100-num-various: dataset=a100-num-various participant=Data::MiniDumpX
   MiniDumpX a100-str: dataset=a100-str participant=Data::MiniDumpX

=head2 Sample benchmark #2

Benchmark command (benchmarking module startup overhead):

 % bencher -m Data::Dmp::Dump --module-startup

Result formatted as table:

 #table2#
 +---------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | participant         | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +---------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | Data::Dump          |      12.7 |               6.7 |                 0.00% |               113.40% | 1.2e-05 |      20 |
 | Data::Dmp           |      11   |               5   |                17.13% |                82.19% | 1.2e-05 |      20 |
 | Data::MiniDumpX     |      10   |               4   |                24.09% |                71.97% | 2.3e-05 |      20 |
 | perl -e1 (baseline) |       6   |               0   |               113.40% |                 0.00% | 9.3e-06 |      20 |
 +---------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+


The above result formatted in L<Benchmark.pm|Benchmark> style:

                          Rate  Data::Dump  Data::Dmp  Data::MiniDumpX  perl -e1 (baseline) 
  Data::Dump            78.7/s          --       -13%             -21%                 -52% 
  Data::Dmp             90.9/s         15%         --              -9%                 -45% 
  Data::MiniDumpX      100.0/s         27%        10%               --                 -40% 
  perl -e1 (baseline)  166.7/s        111%        83%              66%                   -- 
 
 Legends:
   Data::Dmp: mod_overhead_time=5 participant=Data::Dmp
   Data::Dump: mod_overhead_time=6.7 participant=Data::Dump
   Data::MiniDumpX: mod_overhead_time=4 participant=Data::MiniDumpX
   perl -e1 (baseline): mod_overhead_time=0 participant=perl -e1 (baseline)

To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-Data-Dmp>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-Data-Dmp>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024, 2023, 2017, 2016 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-Data-Dmp>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
