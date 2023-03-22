package Bencher::Scenario::Sort::BySpec;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-01-17'; # DATE
our $DIST = 'Bencher-Scenario-Sort-BySpec'; # DIST
our $VERSION = '0.041'; # VERSION

our $scenario = {
    summary => 'Benchmark Sort::BySpec (e.g. against Sort::ByExample, etc)',
    participants => [
        {
            name => 'gen_sorter-sbe',
            tags => ['gen_sorter', 'sbe'],
            module => 'Sort::ByExample',
            code_template => 'Sort::ByExample::sbe(<spec>)',
        },
        {
            name => 'gen_sorter-sbs',
            tags => ['gen_sorter', 'sbs'],
            module => 'Sort::BySpec',
            code_template => 'Sort::BySpec::sort_by_spec(spec => <spec>)',
        },

        {
            name => 'sort-sbe',
            tags => ['sort', 'sbe'],
            module => 'Sort::ByExample',
            code_template => 'state $sorter = Sort::ByExample::sbe(<spec>); [$sorter->(@{<list>})]',
        },
        {
            name => 'sort-sbs',
            tags => ['sort', 'sbs'],
            module => 'Sort::BySpec',
            code_template => 'state $sorter = Sort::BySpec::sort_by_spec(spec => <spec>); [$sorter->(@{<list>})]',
        },
    ],

    datasets => [
        {
            name => 'eg-num5-list10',
            args => {
                spec => [5,4,3,2,1],
                # currently unwieldy, need to use hash
                #'list@' => [
                #    [1..10],  # 10-elem
                #    [1..100], # 100-elem
                #],
                'list' => [1..10],
            },
        },
        {
            name => 'eg-num5-list100',
            args => {
                spec => [5,4,3,2,1],
                'list' => [1..100],
            },
        },
        {
            name => 'eg-num5-list1000',
            args => {
                spec => [5,4,3,2,1],
                'list' => [1..1000],
            },
        },
    ],
};

1;
# ABSTRACT: Benchmark Sort::BySpec (e.g. against Sort::ByExample, etc)

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::Sort::BySpec - Benchmark Sort::BySpec (e.g. against Sort::ByExample, etc)

=head1 VERSION

This document describes version 0.041 of Bencher::Scenario::Sort::BySpec (from Perl distribution Bencher-Scenario-Sort-BySpec), released on 2023-01-17.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m Sort::BySpec

To run module startup overhead benchmark:

 % bencher --module-startup -m Sort::BySpec

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Sort::ByExample> 0.007

L<Sort::BySpec> 0.040

=head1 BENCHMARK PARTICIPANTS

=over

=item * gen_sorter-sbe (perl_code) [gen_sorter, sbe]

Code template:

 Sort::ByExample::sbe(<spec>)



=item * gen_sorter-sbs (perl_code) [gen_sorter, sbs]

Code template:

 Sort::BySpec::sort_by_spec(spec => <spec>)



=item * sort-sbe (perl_code) [sort, sbe]

Code template:

 state $sorter = Sort::ByExample::sbe(<spec>); [$sorter->(@{<list>})]



=item * sort-sbs (perl_code) [sort, sbs]

Code template:

 state $sorter = Sort::BySpec::sort_by_spec(spec => <spec>); [$sorter->(@{<list>})]



=back

=head1 BENCHMARK DATASETS

=over

=item * eg-num5-list10

=item * eg-num5-list100

=item * eg-num5-list1000

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.34.0 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 20.04 >>, OS kernel: I<< Linux version 5.4.0-91-generic >>.

Benchmark with default options (C<< bencher -m Sort::BySpec >>):

 #table1#
 +----------------+------------------+-----------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant    | dataset          | p_tags          | rate (/s) | time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +----------------+------------------+-----------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | sort-sbs       | eg-num5-list1000 | sort, sbs       |       250 | 4         |                 0.00% |            112867.98% | 6.2e-06 |      20 |
 | sort-sbe       | eg-num5-list1000 | sort, sbe       |      2590 | 0.386     |               930.03% |             10867.49% | 2.1e-07 |      20 |
 | sort-sbs       | eg-num5-list100  | sort, sbs       |      2620 | 0.382     |               942.00% |             10741.48% | 2.1e-07 |      21 |
 | sort-sbe       | eg-num5-list100  | sort, sbe       |     24300 | 0.0411    |              9578.23% |              1067.24% | 1.3e-08 |      22 |
 | sort-sbs       | eg-num5-list10   | sort, sbs       |     34600 | 0.0289    |             13652.82% |               721.42% | 1.3e-08 |      20 |
 | sort-sbe       | eg-num5-list10   | sort, sbe       |    121000 | 0.00826   |             48030.83% |               134.71% | 3.3e-09 |      20 |
 | gen_sorter-sbe | eg-num5-list1000 | gen_sorter, sbe |    220000 | 0.0046    |             85838.15% |                31.45% | 6.7e-09 |      20 |
 | gen_sorter-sbe | eg-num5-list10   | gen_sorter, sbe |    220000 | 0.0046    |             87069.76% |                29.60% | 6.5e-09 |      21 |
 | gen_sorter-sbe | eg-num5-list100  | gen_sorter, sbe |    220000 | 0.0045    |             87927.99% |                28.33% |   5e-09 |      20 |
 | gen_sorter-sbs | eg-num5-list100  | gen_sorter, sbs |    283000 | 0.00353   |            112526.73% |                 0.30% | 1.7e-09 |      20 |
 | gen_sorter-sbs | eg-num5-list10   | gen_sorter, sbs |    283860 | 0.0035229 |            112801.80% |                 0.06% | 1.5e-11 |      20 |
 | gen_sorter-sbs | eg-num5-list1000 | gen_sorter, sbs |    284030 | 0.0035208 |            112867.98% |                 0.00% | 1.5e-11 |      24 |
 +----------------+------------------+-----------------+-----------+-----------+-----------------------+-----------------------+---------+---------+


Formatted as L<Benchmark.pm|Benchmark> result:

                                            Rate  s sort, sbs eg-num5-list1000  s sort, sbe eg-num5-list1000  s sort, sbs eg-num5-list100  s sort, sbe eg-num5-list100  s sort, sbs eg-num5-list10  s sort, sbe eg-num5-list10  g_s gen_sorter, sbe eg-num5-list1000  g_s gen_sorter, sbe eg-num5-list10  g_s gen_sorter, sbe eg-num5-list100  g_s gen_sorter, sbs eg-num5-list100  g_s gen_sorter, sbs eg-num5-list10  g_s gen_sorter, sbs eg-num5-list1000 
  s sort, sbs eg-num5-list1000             250/s                            --                          -90%                         -90%                         -98%                        -99%                        -99%                                  -99%                                -99%                                 -99%                                 -99%                                -99%                                  -99% 
  s sort, sbe eg-num5-list1000            2590/s                          936%                            --                          -1%                         -89%                        -92%                        -97%                                  -98%                                -98%                                 -98%                                 -99%                                -99%                                  -99% 
  s sort, sbs eg-num5-list100             2620/s                          947%                            1%                           --                         -89%                        -92%                        -97%                                  -98%                                -98%                                 -98%                                 -99%                                -99%                                  -99% 
  s sort, sbe eg-num5-list100            24300/s                         9632%                          839%                         829%                           --                        -29%                        -79%                                  -88%                                -88%                                 -89%                                 -91%                                -91%                                  -91% 
  s sort, sbs eg-num5-list10             34600/s                        13740%                         1235%                        1221%                          42%                          --                        -71%                                  -84%                                -84%                                 -84%                                 -87%                                -87%                                  -87% 
  s sort, sbe eg-num5-list10            121000/s                        48326%                         4573%                        4524%                         397%                        249%                          --                                  -44%                                -44%                                 -45%                                 -57%                                -57%                                  -57% 
  g_s gen_sorter, sbe eg-num5-list1000  220000/s                        86856%                         8291%                        8204%                         793%                        528%                         79%                                    --                                  0%                                  -2%                                 -23%                                -23%                                  -23% 
  g_s gen_sorter, sbe eg-num5-list10    220000/s                        86856%                         8291%                        8204%                         793%                        528%                         79%                                    0%                                  --                                  -2%                                 -23%                                -23%                                  -23% 
  g_s gen_sorter, sbe eg-num5-list100   220000/s                        88788%                         8477%                        8388%                         813%                        542%                         83%                                    2%                                  2%                                   --                                 -21%                                -21%                                  -21% 
  g_s gen_sorter, sbs eg-num5-list100   283000/s                       113214%                        10834%                       10721%                        1064%                        718%                        133%                                   30%                                 30%                                  27%                                   --                                  0%                                    0% 
  g_s gen_sorter, sbs eg-num5-list10    283860/s                       113442%                        10856%                       10743%                        1066%                        720%                        134%                                   30%                                 30%                                  27%                                   0%                                  --                                    0% 
  g_s gen_sorter, sbs eg-num5-list1000  284030/s                       113510%                        10863%                       10749%                        1067%                        720%                        134%                                   30%                                 30%                                  27%                                   0%                                  0%                                    -- 
 
 Legends:
   g_s gen_sorter, sbe eg-num5-list10: dataset=eg-num5-list10 p_tags=gen_sorter, sbe participant=gen_sorter-sbe
   g_s gen_sorter, sbe eg-num5-list100: dataset=eg-num5-list100 p_tags=gen_sorter, sbe participant=gen_sorter-sbe
   g_s gen_sorter, sbe eg-num5-list1000: dataset=eg-num5-list1000 p_tags=gen_sorter, sbe participant=gen_sorter-sbe
   g_s gen_sorter, sbs eg-num5-list10: dataset=eg-num5-list10 p_tags=gen_sorter, sbs participant=gen_sorter-sbs
   g_s gen_sorter, sbs eg-num5-list100: dataset=eg-num5-list100 p_tags=gen_sorter, sbs participant=gen_sorter-sbs
   g_s gen_sorter, sbs eg-num5-list1000: dataset=eg-num5-list1000 p_tags=gen_sorter, sbs participant=gen_sorter-sbs
   s sort, sbe eg-num5-list10: dataset=eg-num5-list10 p_tags=sort, sbe participant=sort-sbe
   s sort, sbe eg-num5-list100: dataset=eg-num5-list100 p_tags=sort, sbe participant=sort-sbe
   s sort, sbe eg-num5-list1000: dataset=eg-num5-list1000 p_tags=sort, sbe participant=sort-sbe
   s sort, sbs eg-num5-list10: dataset=eg-num5-list10 p_tags=sort, sbs participant=sort-sbs
   s sort, sbs eg-num5-list100: dataset=eg-num5-list100 p_tags=sort, sbs participant=sort-sbs
   s sort, sbs eg-num5-list1000: dataset=eg-num5-list1000 p_tags=sort, sbs participant=sort-sbs

Benchmark module startup overhead (C<< bencher -m Sort::BySpec --module-startup >>):

 #table2#
 +---------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | participant         | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +---------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | Sort::ByExample     |      19   |              12   |                 0.00% |               192.74% | 5.5e-05 |      22 |
 | Sort::BySpec        |       9.8 |               2.8 |                96.39% |                49.07% | 7.2e-05 |      20 |
 | perl -e1 (baseline) |       7   |               0   |               192.74% |                 0.00% |   7e-05 |      21 |
 +---------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+


Formatted as L<Benchmark.pm|Benchmark> result:

                          Rate  Sort::ByExample  Sort::BySpec  perl -e1 (baseline) 
  Sort::ByExample       52.6/s               --          -48%                 -63% 
  Sort::BySpec         102.0/s              93%            --                 -28% 
  perl -e1 (baseline)  142.9/s             171%           40%                   -- 
 
 Legends:
   Sort::ByExample: mod_overhead_time=12 participant=Sort::ByExample
   Sort::BySpec: mod_overhead_time=2.8 participant=Sort::BySpec
   perl -e1 (baseline): mod_overhead_time=0 participant=perl -e1 (baseline)

To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-Sort-BySpec>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-Sort-BySpec>.

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

This software is copyright (c) 2023, 2017, 2016, 2015 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-Sort-BySpec>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
