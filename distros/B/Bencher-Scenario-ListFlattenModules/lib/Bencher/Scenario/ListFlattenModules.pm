package Bencher::Scenario::ListFlattenModules;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-02-11'; # DATE
our $DIST = 'Bencher-Scenario-ListFlattenModules'; # DIST
our $VERSION = '0.002'; # VERSION

our $scenario = {
    summary => 'Benchmark various List::Flatten implementaitons',
    participants => [
        {
            fcall_template => 'List::Flatten::flat(@{<data>})',
            result_is_list => 1,
        },
        {
            fcall_template => 'List::Flatten::XS::flatten(<data>)',
        },
        {
            fcall_template => 'List::Flat::flat(@{<data>})',
            result_is_list => 1,
        },
    ],
    datasets => [
        {name => '10_1_1', args => {data=>[1, 2, 3, 4, [5], 6, 7, 8, 9, 10]}},
        {name => '10_10_1', args => {data=>[[1], [2], [3], [4], [5], [6], [7], [8], [9], [10]]}},
        {name => '10_1_10', args => {data=>[1, 2, 3, 4, [5, 2..10], 6, 7, 8, 9, 10]}},
        {name => '10_1_100', args => {data=>[1, 2, 3, 4, [5, 2..100], 6, 7, 8, 9, 10]}},

        {name => '100_1_1', args => {data=>[1..49, [50], 51..100]}},

        {name => '1000_1_1', args => {data=>[1..499, [500], 501..1000]}},
    ],
};

1;
# ABSTRACT: Benchmark various List::Flatten implementaitons

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::ListFlattenModules - Benchmark various List::Flatten implementaitons

=head1 VERSION

This document describes version 0.002 of Bencher::Scenario::ListFlattenModules (from Perl distribution Bencher-Scenario-ListFlattenModules), released on 2024-02-11.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m ListFlattenModules

To run module startup overhead benchmark:

 % bencher --module-startup -m ListFlattenModules

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<List::Flatten> 0.01

L<List::Flatten::XS> 0.05

L<List::Flat> 0.003

=head1 BENCHMARK PARTICIPANTS

=over

=item * List::Flatten::flat (perl_code)

Function call template:

 List::Flatten::flat(@{<data>})



=item * List::Flatten::XS::flatten (perl_code)

Function call template:

 List::Flatten::XS::flatten(<data>)



=item * List::Flat::flat (perl_code)

Function call template:

 List::Flat::flat(@{<data>})



=back

=head1 BENCHMARK DATASETS

=over

=item * 10_1_1

=item * 10_10_1

=item * 10_1_10

=item * 10_1_100

=item * 100_1_1

=item * 1000_1_1

=back

=head1 BENCHMARK SAMPLE RESULTS

=head2 Sample benchmark #1

Run on: perl: I<< v5.38.2 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 20.04 >>, OS kernel: I<< Linux version 5.4.0-164-generic >>.

Benchmark command (default options):

 % bencher -m ListFlattenModules

Result formatted as table:

 #table1#
 +----------------------------+----------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                | dataset  | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +----------------------------+----------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | List::Flatten::XS::flatten | 1000_1_1 |      5300 |   190     |                 0.00% |             19967.80% | 4.4e-07 |      22 |
 | List::Flat::flat           | 1000_1_1 |      6180 |   162     |                17.12% |             17034.89% | 1.2e-07 |      21 |
 | List::Flatten::flat        | 1000_1_1 |     17100 |    58.4   |               224.46% |              6085.01% | 1.2e-08 |      20 |
 | List::Flatten::XS::flatten | 10_1_100 |     19000 |    52     |               261.07% |              5457.86% | 8.9e-08 |      20 |
 | List::Flat::flat           | 10_1_100 |     39200 |    25.5   |               642.49% |              2602.79% | 8.4e-09 |      20 |
 | List::Flatten::XS::flatten | 100_1_1  |     45000 |    22     |               750.03% |              2260.85% | 5.8e-08 |      20 |
 | List::Flat::flat           | 100_1_1  |     53600 |    18.7   |               915.25% |              1876.63% | 9.3e-09 |      21 |
 | List::Flatten::XS::flatten | 10_10_1  |    120000 |     8.7   |              2088.04% |               817.16% |   5e-08 |      20 |
 | List::Flat::flat           | 10_10_1  |    137000 |     7.31  |              2493.05% |               673.91% | 2.2e-09 |      20 |
 | List::Flatten::flat        | 100_1_1  |    157000 |     6.35  |              2885.02% |               572.28% | 1.3e-09 |      20 |
 | List::Flatten::XS::flatten | 10_1_10  |    180000 |     5.5   |              3345.78% |               482.39% | 2.5e-08 |      20 |
 | List::Flat::flat           | 10_1_10  |    183000 |     5.46  |              3374.60% |               477.56% | 2.4e-09 |      20 |
 | List::Flatten::XS::flatten | 10_1_1   |    310000 |     3.2   |              5825.05% |               238.69% | 1.5e-08 |      20 |
 | List::Flat::flat           | 10_1_1   |    343000 |     2.92  |              6392.36% |               209.10% | 6.7e-10 |      21 |
 | List::Flatten::flat        | 10_1_100 |    372000 |     2.69  |              6942.68% |               184.95% | 4.9e-10 |      20 |
 | List::Flatten::flat        | 10_10_1  |    513000 |     1.95  |              9624.78% |               106.36% | 3.7e-10 |      20 |
 | List::Flatten::flat        | 10_1_10  |    891000 |     1.12  |             16792.50% |                18.80% | 3.7e-10 |      20 |
 | List::Flatten::flat        | 10_1_1   |   1060000 |     0.945 |             19967.80% |                 0.00% | 2.4e-10 |      24 |
 +----------------------------+----------+-----------+-----------+-----------------------+-----------------------+---------+---------+


The above result formatted in L<Benchmark.pm|Benchmark> style:

                       Rate  LFX:f 1000_1_1  LF:f 1000_1_1  LF:f 1000_1_1  LFX:f 10_1_100  LF:f 10_1_100  LFX:f 100_1_1  LF:f 100_1_1  LFX:f 10_10_1  LF:f 10_10_1  LF:f 100_1_1  LFX:f 10_1_10  LF:f 10_1_10  LFX:f 10_1_1  LF:f 10_1_1  LF:f 10_1_100  LF:f 10_10_1  LF:f 10_1_10  LF:f 10_1_1 
  LFX:f 1000_1_1     5300/s              --           -14%           -69%            -72%           -86%           -88%          -90%           -95%          -96%          -96%           -97%          -97%          -98%         -98%           -98%          -98%          -99%         -99% 
  LF:f 1000_1_1      6180/s             17%             --           -63%            -67%           -84%           -86%          -88%           -94%          -95%          -96%           -96%          -96%          -98%         -98%           -98%          -98%          -99%         -99% 
  LF:f 1000_1_1     17100/s            225%           177%             --            -10%           -56%           -62%          -67%           -85%          -87%          -89%           -90%          -90%          -94%         -95%           -95%          -96%          -98%         -98% 
  LFX:f 10_1_100    19000/s            265%           211%            12%              --           -50%           -57%          -64%           -83%          -85%          -87%           -89%          -89%          -93%         -94%           -94%          -96%          -97%         -98% 
  LF:f 10_1_100     39200/s            645%           535%           129%            103%             --           -13%          -26%           -65%          -71%          -75%           -78%          -78%          -87%         -88%           -89%          -92%          -95%         -96% 
  LFX:f 100_1_1     45000/s            763%           636%           165%            136%            15%             --          -15%           -60%          -66%          -71%           -75%          -75%          -85%         -86%           -87%          -91%          -94%         -95% 
  LF:f 100_1_1      53600/s            916%           766%           212%            178%            36%            17%            --           -53%          -60%          -66%           -70%          -70%          -82%         -84%           -85%          -89%          -94%         -94% 
  LFX:f 10_10_1    120000/s           2083%          1762%           571%            497%           193%           152%          114%             --          -15%          -27%           -36%          -37%          -63%         -66%           -69%          -77%          -87%         -89% 
  LF:f 10_10_1     137000/s           2499%          2116%           698%            611%           248%           200%          155%            19%            --          -13%           -24%          -25%          -56%         -60%           -63%          -73%          -84%         -87% 
  LF:f 100_1_1     157000/s           2892%          2451%           819%            718%           301%           246%          194%            37%           15%            --           -13%          -14%          -49%         -54%           -57%          -69%          -82%         -85% 
  LFX:f 10_1_10    180000/s           3354%          2845%           961%            845%           363%           300%          240%            58%           32%           15%             --            0%          -41%         -46%           -51%          -64%          -79%         -82% 
  LF:f 10_1_10     183000/s           3379%          2867%           969%            852%           367%           302%          242%            59%           33%           16%             0%            --          -41%         -46%           -50%          -64%          -79%         -82% 
  LFX:f 10_1_1     310000/s           5837%          4962%          1725%           1525%           696%           587%          484%           171%          128%           98%            71%           70%            --          -8%           -15%          -39%          -64%         -70% 
  LF:f 10_1_1      343000/s           6406%          5447%          1900%           1680%           773%           653%          540%           197%          150%          117%            88%           86%            9%           --            -7%          -33%          -61%         -67% 
  LF:f 10_1_100    372000/s           6963%          5922%          2071%           1833%           847%           717%          595%           223%          171%          136%           104%          102%           18%           8%             --          -27%          -58%         -64% 
  LF:f 10_10_1     513000/s           9643%          8207%          2894%           2566%          1207%          1028%          858%           346%          274%          225%           182%          180%           64%          49%            37%            --          -42%         -51% 
  LF:f 10_1_10     891000/s          16864%         14364%          5114%           4542%          2176%          1864%         1569%           676%          552%          466%           391%          387%          185%         160%           140%           74%            --         -15% 
  LF:f 10_1_1     1060000/s          20005%         17042%          6079%           5402%          2598%          2228%         1878%           820%          673%          571%           482%          477%          238%         208%           184%          106%           18%           -- 
 
 Legends:
   LF:f 1000_1_1: dataset=1000_1_1 participant=List::Flatten::flat
   LF:f 100_1_1: dataset=100_1_1 participant=List::Flatten::flat
   LF:f 10_10_1: dataset=10_10_1 participant=List::Flatten::flat
   LF:f 10_1_1: dataset=10_1_1 participant=List::Flatten::flat
   LF:f 10_1_10: dataset=10_1_10 participant=List::Flatten::flat
   LF:f 10_1_100: dataset=10_1_100 participant=List::Flatten::flat
   LFX:f 1000_1_1: dataset=1000_1_1 participant=List::Flatten::XS::flatten
   LFX:f 100_1_1: dataset=100_1_1 participant=List::Flatten::XS::flatten
   LFX:f 10_10_1: dataset=10_10_1 participant=List::Flatten::XS::flatten
   LFX:f 10_1_1: dataset=10_1_1 participant=List::Flatten::XS::flatten
   LFX:f 10_1_10: dataset=10_1_10 participant=List::Flatten::XS::flatten
   LFX:f 10_1_100: dataset=10_1_100 participant=List::Flatten::XS::flatten

=head2 Sample benchmark #2

Benchmark command (benchmarking module startup overhead):

 % bencher -m ListFlattenModules --module-startup

Result formatted as table:

 #table2#
 +---------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | participant         | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +---------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | List::Flat          |     10.6  |              4.29 |                 0.00% |                68.17% | 4.7e-06 |      20 |
 | List::Flatten       |     10    |              3.69 |                 5.68% |                59.12% | 3.5e-06 |      20 |
 | List::Flatten::XS   |      9.66 |              3.35 |                 9.92% |                52.99% | 4.7e-06 |      20 |
 | perl -e1 (baseline) |      6.31 |              0    |                68.17% |                 0.00% | 3.4e-06 |      20 |
 +---------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+


The above result formatted in L<Benchmark.pm|Benchmark> style:

                          Rate  List::Flat  List::Flatten  List::Flatten::XS  perl -e1 (baseline) 
  List::Flat            94.3/s          --            -5%                -8%                 -40% 
  List::Flatten        100.0/s          6%             --                -3%                 -36% 
  List::Flatten::XS    103.5/s          9%             3%                 --                 -34% 
  perl -e1 (baseline)  158.5/s         67%            58%                53%                   -- 
 
 Legends:
   List::Flat: mod_overhead_time=4.29 participant=List::Flat
   List::Flatten: mod_overhead_time=3.69 participant=List::Flatten
   List::Flatten::XS: mod_overhead_time=3.35 participant=List::Flatten::XS
   perl -e1 (baseline): mod_overhead_time=0 participant=perl -e1 (baseline)

To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 BENCHMARK NOTES

In general, from the provided benchmark datasets, I don't see the advantage of
using the XS implementation.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-ListFlattenModules>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-ListFlattenModules>.

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

This software is copyright (c) 2024, 2018 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-ListFlattenModules>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
