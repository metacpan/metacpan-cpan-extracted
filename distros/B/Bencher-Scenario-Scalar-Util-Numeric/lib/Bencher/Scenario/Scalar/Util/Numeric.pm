package Bencher::Scenario::Scalar::Util::Numeric;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-01-17'; # DATE
our $DIST = 'Bencher-Scenario-Scalar-Util-Numeric'; # DIST
our $VERSION = '0.021'; # VERSION

our $scenario = {
    summary => 'Benchmark Scalar::Util::Numeric vs Scalar::Util::Numeric::PP',
    participants => [
        map {
            my $which = $_;
            my $mod = $which eq 'pp' ?
                "Scalar::Util::Numeric::PP" : "Scalar::Util::Numeric";
            (
                {
                    module => $mod,
                    name => "isint-int-$which",
                    fcall_template => "$mod\::isint(1)",
                    tags => [$which, "func:isint"],
                },
                {
                    module => $mod,
                    name => "isint-str-$which",
                    fcall_template => "$mod\::isint('a')",
                    tags => [$which, "func:isint"],
                },
                {
                    module => $mod,
                    name => "isint-float-$which",
                    fcall_template => "$mod\::isint(1.23)",
                    tags => [$which, "func:isint"],
                },

                {
                    module => $mod,
                    name => "isfloat-int-$which",
                    fcall_template => "$mod\::isfloat(1)",
                    tags => [$which, "func:isfloat"],
                },
                {
                    module => $mod,
                    name => "isfloat-str-$which",
                    fcall_template => "$mod\::isfloat('a')",
                    tags => [$which, "func:isfloat"],
                },
                {
                    module => $mod,
                    name => "isfloat-float-$which",
                    fcall_template => "$mod\::isfloat(1.23)",
                    tags => [$which, "func:isfloat"],
                },

                {
                    module => $mod,
                    name => "isnum-int-$which",
                    fcall_template => "$mod\::isnum(1)",
                    tags => [$which, "func:isnum"],
                },
                {
                    module => $mod,
                    name => "isnum-str-$which",
                    fcall_template => "$mod\::isnum('a')",
                    tags => [$which, "func:isnum"],
                },
                {
                    module => $mod,
                    name => "isnum-float-$which",
                    fcall_template => "$mod\::isnum(1.23)",
                    tags => [$which, "func:isnum"],
                },
            );
        } ("pp", "xs"),
    ],
};

1;
# ABSTRACT: Benchmark Scalar::Util::Numeric vs Scalar::Util::Numeric::PP

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::Scalar::Util::Numeric - Benchmark Scalar::Util::Numeric vs Scalar::Util::Numeric::PP

=head1 VERSION

This document describes version 0.021 of Bencher::Scenario::Scalar::Util::Numeric (from Perl distribution Bencher-Scenario-Scalar-Util-Numeric), released on 2023-01-17.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m Scalar::Util::Numeric

To run module startup overhead benchmark:

 % bencher --module-startup -m Scalar::Util::Numeric

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Scalar::Util::Numeric::PP> 0.04

L<Scalar::Util::Numeric> 0.40

=head1 BENCHMARK PARTICIPANTS

=over

=item * isint-int-pp (perl_code) [pp, func:isint]

Function call template:

 Scalar::Util::Numeric::PP::isint(1)



=item * isint-str-pp (perl_code) [pp, func:isint]

Function call template:

 Scalar::Util::Numeric::PP::isint('a')



=item * isint-float-pp (perl_code) [pp, func:isint]

Function call template:

 Scalar::Util::Numeric::PP::isint(1.23)



=item * isfloat-int-pp (perl_code) [pp, func:isfloat]

Function call template:

 Scalar::Util::Numeric::PP::isfloat(1)



=item * isfloat-str-pp (perl_code) [pp, func:isfloat]

Function call template:

 Scalar::Util::Numeric::PP::isfloat('a')



=item * isfloat-float-pp (perl_code) [pp, func:isfloat]

Function call template:

 Scalar::Util::Numeric::PP::isfloat(1.23)



=item * isnum-int-pp (perl_code) [pp, func:isnum]

Function call template:

 Scalar::Util::Numeric::PP::isnum(1)



=item * isnum-str-pp (perl_code) [pp, func:isnum]

Function call template:

 Scalar::Util::Numeric::PP::isnum('a')



=item * isnum-float-pp (perl_code) [pp, func:isnum]

Function call template:

 Scalar::Util::Numeric::PP::isnum(1.23)



=item * isint-int-xs (perl_code) [xs, func:isint]

Function call template:

 Scalar::Util::Numeric::isint(1)



=item * isint-str-xs (perl_code) [xs, func:isint]

Function call template:

 Scalar::Util::Numeric::isint('a')



=item * isint-float-xs (perl_code) [xs, func:isint]

Function call template:

 Scalar::Util::Numeric::isint(1.23)



=item * isfloat-int-xs (perl_code) [xs, func:isfloat]

Function call template:

 Scalar::Util::Numeric::isfloat(1)



=item * isfloat-str-xs (perl_code) [xs, func:isfloat]

Function call template:

 Scalar::Util::Numeric::isfloat('a')



=item * isfloat-float-xs (perl_code) [xs, func:isfloat]

Function call template:

 Scalar::Util::Numeric::isfloat(1.23)



=item * isnum-int-xs (perl_code) [xs, func:isnum]

Function call template:

 Scalar::Util::Numeric::isnum(1)



=item * isnum-str-xs (perl_code) [xs, func:isnum]

Function call template:

 Scalar::Util::Numeric::isnum('a')



=item * isnum-float-xs (perl_code) [xs, func:isnum]

Function call template:

 Scalar::Util::Numeric::isnum(1.23)



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.34.0 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 20.04 >>, OS kernel: I<< Linux version 5.4.0-91-generic >>.

Benchmark with default options (C<< bencher -m Scalar::Util::Numeric >>):

 #table1#
 +------------------+------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant      | p_tags           | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +------------------+------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | isnum-float-pp   | pp, func:isnum   |    490000 |    2      |                 0.00% |              4111.51% | 3.3e-09 |      20 |
 | isnum-str-pp     | pp, func:isnum   |    615800 |    1.624  |                25.70% |              3250.31% | 2.2e-11 |      20 |
 | isfloat-int-pp   | pp, func:isfloat |    860000 |    1.2    |                75.96% |              2293.38% | 1.6e-09 |      22 |
 | isfloat-float-pp | pp, func:isfloat |   1030000 |    0.971  |               110.29% |              1902.76% | 3.9e-10 |      23 |
 | isfloat-str-pp   | pp, func:isfloat |   1087000 |    0.9202 |               121.86% |              1798.31% | 2.2e-11 |      20 |
 | isint-float-pp   | pp, func:isint   |   1297000 |    0.7712 |               164.70% |              1491.08% | 4.6e-11 |      20 |
 | isnum-int-pp     | pp, func:isnum   |   1577000 |    0.6342 |               221.91% |              1208.27% | 2.3e-11 |      20 |
 | isint-int-pp     | pp, func:isint   |   2200000 |    0.45   |               352.58% |               830.55% | 8.3e-10 |      20 |
 | isint-float-xs   | xs, func:isint   |   2734000 |    0.3658 |               458.12% |               654.58% | 2.2e-11 |      20 |
 | isnum-float-xs   | xs, func:isnum   |   2735000 |    0.3656 |               458.41% |               654.20% | 2.1e-11 |      20 |
 | isfloat-float-xs | xs, func:isfloat |   2738000 |    0.3653 |               458.86% |               653.59% | 2.9e-11 |      20 |
 | isint-str-pp     | pp, func:isint   |   2980000 |    0.336  |               508.04% |               592.64% | 1.1e-10 |      20 |
 | isint-str-xs     | xs, func:isint   |  17000000 |    0.059  |              3383.67% |                20.89% | 2.1e-10 |      20 |
 | isnum-str-xs     | xs, func:isnum   |  18000000 |    0.057  |              3491.02% |                17.28% | 2.1e-10 |      20 |
 | isfloat-str-xs   | xs, func:isfloat |  18000000 |    0.054  |              3667.33% |                11.79% | 1.2e-10 |      20 |
 | isnum-int-xs     | xs, func:isnum   |  19000000 |    0.052  |              3805.01% |                 7.85% | 2.1e-10 |      20 |
 | isfloat-int-xs   | xs, func:isfloat |  19000000 |    0.052  |              3845.40% |                 6.74% | 2.1e-10 |      20 |
 | isint-int-xs     | xs, func:isint   |  21000000 |    0.048  |              4111.51% |                 0.00% | 3.4e-10 |      20 |
 +------------------+------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+


Formatted as L<Benchmark.pm|Benchmark> result:

                            Rate  i pp, func:isnum  i pp, func:isnum  i pp, func:isfloat  i pp, func:isfloat  i pp, func:isfloat  i pp, func:isint  i pp, func:isnum  i pp, func:isint  i xs, func:isint  i xs, func:isnum  i xs, func:isfloat  i pp, func:isint  i xs, func:isint  i xs, func:isnum  i xs, func:isfloat  i xs, func:isnum  i xs, func:isfloat  i xs, func:isint 
  i pp, func:isnum      490000/s                --              -18%                -40%                -51%                -53%              -61%              -68%              -77%              -81%              -81%                -81%              -83%              -97%              -97%                -97%              -97%                -97%              -97% 
  i pp, func:isnum      615800/s               23%                --                -26%                -40%                -43%              -52%              -60%              -72%              -77%              -77%                -77%              -79%              -96%              -96%                -96%              -96%                -96%              -97% 
  i pp, func:isfloat    860000/s               66%               35%                  --                -19%                -23%              -35%              -47%              -62%              -69%              -69%                -69%              -72%              -95%              -95%                -95%              -95%                -95%              -96% 
  i pp, func:isfloat   1030000/s              105%               67%                 23%                  --                 -5%              -20%              -34%              -53%              -62%              -62%                -62%              -65%              -93%              -94%                -94%              -94%                -94%              -95% 
  i pp, func:isfloat   1087000/s              117%               76%                 30%                  5%                  --              -16%              -31%              -51%              -60%              -60%                -60%              -63%              -93%              -93%                -94%              -94%                -94%              -94% 
  i pp, func:isint     1297000/s              159%              110%                 55%                 25%                 19%                --              -17%              -41%              -52%              -52%                -52%              -56%              -92%              -92%                -92%              -93%                -93%              -93% 
  i pp, func:isnum     1577000/s              215%              156%                 89%                 53%                 45%               21%                --              -29%              -42%              -42%                -42%              -47%              -90%              -91%                -91%              -91%                -91%              -92% 
  i pp, func:isint     2200000/s              344%              260%                166%                115%                104%               71%               40%                --              -18%              -18%                -18%              -25%              -86%              -87%                -88%              -88%                -88%              -89% 
  i xs, func:isint     2734000/s              446%              343%                228%                165%                151%              110%               73%               23%                --                0%                  0%               -8%              -83%              -84%                -85%              -85%                -85%              -86% 
  i xs, func:isnum     2735000/s              447%              344%                228%                165%                151%              110%               73%               23%                0%                --                  0%               -8%              -83%              -84%                -85%              -85%                -85%              -86% 
  i xs, func:isfloat   2738000/s              447%              344%                228%                165%                151%              111%               73%               23%                0%                0%                  --               -8%              -83%              -84%                -85%              -85%                -85%              -86% 
  i pp, func:isint     2980000/s              495%              383%                257%                188%                173%              129%               88%               33%                8%                8%                  8%                --              -82%              -83%                -83%              -84%                -84%              -85% 
  i xs, func:isint    17000000/s             3289%             2652%               1933%               1545%               1459%             1207%              974%              662%              520%              519%                519%              469%                --               -3%                 -8%              -11%                -11%              -18% 
  i xs, func:isnum    18000000/s             3408%             2749%               2005%               1603%               1514%             1252%             1012%              689%              541%              541%                540%              489%                3%                --                 -5%               -8%                 -8%              -15% 
  i xs, func:isfloat  18000000/s             3603%             2907%               2122%               1698%               1604%             1328%             1074%              733%              577%              577%                576%              522%                9%                5%                  --               -3%                 -3%              -11% 
  i xs, func:isnum    19000000/s             3746%             3023%               2207%               1767%               1669%             1383%             1119%              765%              603%              603%                602%              546%               13%                9%                  3%                --                  0%               -7% 
  i xs, func:isfloat  19000000/s             3746%             3023%               2207%               1767%               1669%             1383%             1119%              765%              603%              603%                602%              546%               13%                9%                  3%                0%                  --               -7% 
  i xs, func:isint    21000000/s             4066%             3283%               2400%               1922%               1817%             1506%             1221%              837%              662%              661%                661%              600%               22%               18%                 12%                8%                  8%                -- 
 
 Legends:
   i pp, func:isfloat: p_tags=pp, func:isfloat participant=isfloat-str-pp
   i pp, func:isint: p_tags=pp, func:isint participant=isint-str-pp
   i pp, func:isnum: p_tags=pp, func:isnum participant=isnum-int-pp
   i xs, func:isfloat: p_tags=xs, func:isfloat participant=isfloat-int-xs
   i xs, func:isint: p_tags=xs, func:isint participant=isint-int-xs
   i xs, func:isnum: p_tags=xs, func:isnum participant=isnum-int-xs

Benchmark module startup overhead (C<< bencher -m Scalar::Util::Numeric --module-startup >>):

 #table2#
 +---------------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | participant               | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +---------------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | Scalar::Util::Numeric     |      11   |               4.4 |                 0.00% |                63.80% | 6.1e-05 |      21 |
 | Scalar::Util::Numeric::PP |       9.8 |               3.2 |                11.43% |                47.01% | 2.9e-05 |      20 |
 | perl -e1 (baseline)       |       6.6 |               0   |                63.80% |                 0.00% | 3.6e-05 |      21 |
 +---------------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+


Formatted as L<Benchmark.pm|Benchmark> result:

                          Rate  SU:N  SUN:P  perl -e1 (baseline) 
  SU:N                  90.9/s    --   -10%                 -40% 
  SUN:P                102.0/s   12%     --                 -32% 
  perl -e1 (baseline)  151.5/s   66%    48%                   -- 
 
 Legends:
   SU:N: mod_overhead_time=4.4 participant=Scalar::Util::Numeric
   SUN:P: mod_overhead_time=3.2 participant=Scalar::Util::Numeric::PP
   perl -e1 (baseline): mod_overhead_time=0 participant=perl -e1 (baseline)

To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-Scalar-Util-Numeric>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-Scalar-Util-Numeric>.

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

This software is copyright (c) 2023, 2017, 2016 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-Scalar-Util-Numeric>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
