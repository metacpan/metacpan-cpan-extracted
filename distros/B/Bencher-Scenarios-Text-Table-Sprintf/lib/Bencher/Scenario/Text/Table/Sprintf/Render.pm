package Bencher::Scenario::Text::Table::Sprintf::Render;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-11-11'; # DATE
our $DIST = 'Bencher-Scenarios-Text-Table-Sprintf'; # DIST
our $VERSION = '0.001'; # VERSION

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
    summary => "Benchmark Text::Table::Sprintf's rendering speed",
    participants => [
        {
            module => 'Text::Table::Sprintf',
            code_template => 'Text::Table::Sprintf::table(rows=><table>, header_row=>1)',
        },
    ],
    datasets => [
        {name=>'tiny (1x1)'    , args => {table=>_make_table( 1, 1)},},
        {name=>'small (3x5)'   , args => {table=>_make_table( 3, 5)},},
        {name=>'wide (30x5)'   , args => {table=>_make_table(30, 5)},},
        {name=>'long (3x300)'  , args => {table=>_make_table( 3, 300)},},
        {name=>'large (30x300)', args => {table=>_make_table(30, 300)},},
    ],
};

1;
# ABSTRACT: Benchmark Text::Table::Sprintf's rendering speed

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::Text::Table::Sprintf::Render - Benchmark Text::Table::Sprintf's rendering speed

=head1 VERSION

This document describes version 0.001 of Bencher::Scenario::Text::Table::Sprintf::Render (from Perl distribution Bencher-Scenarios-Text-Table-Sprintf), released on 2023-11-11.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m Text::Table::Sprintf::Render

To run module startup overhead benchmark:

 % bencher --module-startup -m Text::Table::Sprintf::Render

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Text::Table::Sprintf> 0.008

=head1 BENCHMARK PARTICIPANTS

=over

=item * Text::Table::Sprintf (perl_code)

Code template:

 Text::Table::Sprintf::table(rows=><table>, header_row=>1)



=back

=head1 BENCHMARK DATASETS

=over

=item * tiny (1x1)

=item * small (3x5)

=item * wide (30x5)

=item * long (3x300)

=item * large (30x300)

=back

=head1 BENCHMARK SAMPLE RESULTS

=head2 Sample benchmark #1

Run on: perl: I<< v5.38.0 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 20.04 >>, OS kernel: I<< Linux version 5.4.0-164-generic >>.

Benchmark command:

 % bencher -m Text::Table::Sprintf::Render --include-path archive/Text-Table-Sprintf-0.006/lib --include-path archive/Text-Table-Sprintf-0.007/lib --multimodver Text::Table::Sprintf

Result formatted as table:

 #table1#
 +----------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | dataset        | modver | rate (/s) | time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +----------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | large (30x300) | 0.006  |       400 |   3       |                 0.00% |             77113.79% | 3.4e-05 |      20 |
 | large (30x300) | 0.007  |       380 |   2.7     |                 5.86% |             72838.07% | 4.8e-06 |      20 |
 | large (30x300) | 0.008  |       380 |   2.6     |                 6.36% |             72498.48% | 3.4e-06 |      20 |
 | long (3x300)   | 0.007  |      2430 |   0.411   |               584.13% |             11186.48% | 2.7e-07 |      21 |
 | long (3x300)   | 0.008  |      2440 |   0.41    |               584.98% |             11172.46% | 2.5e-07 |      20 |
 | long (3x300)   | 0.006  |      2460 |   0.406   |               592.22% |             11054.55% | 2.2e-07 |      20 |
 | wide (30x5)    | 0.007  |     10000 |   0.09    |              2861.12% |              2507.59% | 2.2e-06 |      25 |
 | wide (30x5)    | 0.008  |     12900 |   0.0776  |              3524.63% |              2030.25% | 3.9e-08 |      26 |
 | wide (30x5)    | 0.006  |     14000 |   0.073   |              3735.99% |              1912.88% | 1.2e-07 |      20 |
 | small (3x5)    | 0.007  |     78000 |   0.0128  |             21846.02% |               251.83% | 4.6e-09 |      20 |
 | small (3x5)    | 0.008  |     78200 |   0.0128  |             21897.52% |               251.01% | 1.3e-08 |      20 |
 | small (3x5)    | 0.006  |     85000 |   0.0118  |             23797.87% |               223.10% | 8.7e-09 |      20 |
 | tiny (1x1)     | 0.007  |    240000 |   0.00416 |             67483.48% |                14.25% | 3.2e-09 |      20 |
 | tiny (1x1)     | 0.008  |    242000 |   0.00414 |             67881.71% |                13.58% | 1.9e-09 |      20 |
 | tiny (1x1)     | 0.006  |    275000 |   0.00364 |             77113.79% |                 0.00% |   2e-09 |      20 |
 +----------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+


The above result formatted in L<Benchmark.pm|Benchmark> style:

                      Rate  large (30x300)  large (30x300)  large (30x300)  long (3x300)  long (3x300)  long (3x300)  wide (30x5)  wide (30x5)  wide (30x5)  small (3x5)  small (3x5)  small (3x5)  tiny (1x1)  tiny (1x1)  tiny (1x1) 
  large (30x300)     400/s              --             -9%            -13%          -86%          -86%          -86%         -97%         -97%         -97%         -99%         -99%         -99%        -99%        -99%        -99% 
  large (30x300)     380/s             11%              --             -3%          -84%          -84%          -84%         -96%         -97%         -97%         -99%         -99%         -99%        -99%        -99%        -99% 
  large (30x300)     380/s             15%              3%              --          -84%          -84%          -84%         -96%         -97%         -97%         -99%         -99%         -99%        -99%        -99%        -99% 
  long (3x300)      2430/s            629%            556%            532%            --            0%           -1%         -78%         -81%         -82%         -96%         -96%         -97%        -98%        -98%        -99% 
  long (3x300)      2440/s            631%            558%            534%            0%            --            0%         -78%         -81%         -82%         -96%         -96%         -97%        -98%        -98%        -99% 
  long (3x300)      2460/s            638%            565%            540%            1%            0%            --         -77%         -80%         -82%         -96%         -96%         -97%        -98%        -98%        -99% 
  wide (30x5)      10000/s           3233%           2900%           2788%          356%          355%          351%           --         -13%         -18%         -85%         -85%         -86%        -95%        -95%        -95% 
  wide (30x5)      12900/s           3765%           3379%           3250%          429%          428%          423%          15%           --          -5%         -83%         -83%         -84%        -94%        -94%        -95% 
  wide (30x5)      14000/s           4009%           3598%           3461%          463%          461%          456%          23%           6%           --         -82%         -82%         -83%        -94%        -94%        -95% 
  small (3x5)      78000/s          23337%          20993%          20212%         3110%         3103%         3071%         603%         506%         470%           --           0%          -7%        -67%        -67%        -71% 
  small (3x5)      78200/s          23337%          20993%          20212%         3110%         3103%         3071%         603%         506%         470%           0%           --          -7%        -67%        -67%        -71% 
  small (3x5)      85000/s          25323%          22781%          21933%         3383%         3374%         3340%         662%         557%         518%           8%           8%           --        -64%        -64%        -69% 
  tiny (1x1)      240000/s          72015%          64803%          62400%         9779%         9755%         9659%        2063%        1765%        1654%         207%         207%         183%          --          0%        -12% 
  tiny (1x1)      242000/s          72363%          65117%          62701%         9827%         9803%         9706%        2073%        1774%        1663%         209%         209%         185%          0%          --        -12% 
  tiny (1x1)      275000/s          82317%          74075%          71328%        11191%        11163%        11053%        2372%        2031%        1905%         251%         251%         224%         14%         13%          -- 
 
 Legends:
   large (30x300): dataset=large (30x300) modver=0.008
   long (3x300): dataset=long (3x300) modver=0.006
   small (3x5): dataset=small (3x5) modver=0.006
   tiny (1x1): dataset=tiny (1x1) modver=0.006
   wide (30x5): dataset=wide (30x5) modver=0.006

To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-Text-Table-Sprintf>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-Text-Table-Sprintf>.

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

This software is copyright (c) 2023 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-Text-Table-Sprintf>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
