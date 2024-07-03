package Bencher::Scenario::SmartMatch::str_in_ary_of_str;

use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-07-02'; # DATE
our $DIST = 'Bencher-ScenarioBundle-SmartMatch'; # DIST
our $VERSION = '0.001'; # VERSION

our $scenario = {
    summary => 'Benchmark searching string in array-of-string using smartmatch: $str ~~ @ary_of_str',
    participants => [
        {module=>'match::simple', code_template=>q{my $str = <str>; my $ary = <ary>; for (1..100) { match::simple::match($str, $ary) } }},
        {module=>'Switch::Right', code_template=>q{my $str = <str>; my $ary = <ary>; for (1..100) { Switch::Right::smartmatch($str, $ary) } }},
    ],
    datasets => [
        {name => '0-str', args => {str=>'a', ary=>[]}},
        {name => '1-str-found', args => {str=>'a', ary=>['a']}},
        {name => '10-str-found-at-the-beginning', args => {str=>'a', ary=>['a'..'j']}},
        {name => '10-str-found-at-the-end', args => {str=>'j', ary=>['a'..'j']}},
        {name => '1000-str-found-at-the-end', args => {str=>'bml', ary=>['aaa'..'bml']}},
    ],
};

1;
# ABSTRACT: Benchmark searching string in array-of-string using smartmatch: $str ~~ @ary_of_str

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::SmartMatch::str_in_ary_of_str - Benchmark searching string in array-of-string using smartmatch: $str ~~ @ary_of_str

=head1 VERSION

This document describes version 0.001 of Bencher::Scenario::SmartMatch::str_in_ary_of_str (from Perl distribution Bencher-ScenarioBundle-SmartMatch), released on 2024-07-02.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m SmartMatch::str_in_ary_of_str

To run module startup overhead benchmark:

 % bencher --module-startup -m SmartMatch::str_in_ary_of_str

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<match::simple> 0.012

L<Switch::Right> 0.000005

=head1 BENCHMARK PARTICIPANTS

=over

=item * match::simple (perl_code)

Code template:

 my $str = <str>; my $ary = <ary>; for (1..100) { match::simple::match($str, $ary) } 



=item * Switch::Right (perl_code)

Code template:

 my $str = <str>; my $ary = <ary>; for (1..100) { Switch::Right::smartmatch($str, $ary) } 



=back

=head1 BENCHMARK DATASETS

=over

=item * 0-str

=item * 1-str-found

=item * 10-str-found-at-the-beginning

=item * 10-str-found-at-the-end

=item * 1000-str-found-at-the-end

=back

=head1 BENCHMARK SAMPLE RESULTS

=head2 Sample benchmark #1

Run on: perl: I<< v5.38.2 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 20.04 >>, OS kernel: I<< Linux version 5.4.0-164-generic >>.

Benchmark command (default options):

 % bencher -m SmartMatch::str_in_ary_of_str

Result formatted as table:

 #table1#
 +---------------+-------------------------------+-----------+-----------+-----------------------+-----------------------+-----------+---------+
 | participant   | dataset                       | rate (/s) | time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors   | samples |
 +---------------+-------------------------------+-----------+-----------+-----------------------+-----------------------+-----------+---------+
 | Switch::Right | 1000-str-found-at-the-end     |      31   |   33      |                 0.00% |             37393.25% |   0.00014 |      20 |
 | match::simple | 1000-str-found-at-the-end     |      32.1 |   31.2    |                 4.79% |             35678.64% | 5.1e-06   |      21 |
 | Switch::Right | 0-str                         |      30   |   30      |                 9.95% |             33999.86% |   0.00047 |      21 |
 | Switch::Right | 10-str-found-at-the-end       |      30   |   30      |                10.75% |             33753.46% |   0.00063 |      20 |
 | Switch::Right | 10-str-found-at-the-beginning |      40   |   30      |                16.42% |             32104.46% |   0.00037 |      20 |
 | Switch::Right | 1-str-found                   |      37.7 |   26.5    |                23.27% |             30316.50% | 1.4e-05   |      23 |
 | match::simple | 10-str-found-at-the-end       |    2460   |    0.407  |              7934.37% |               366.66% | 6.8e-08   |      20 |
 | match::simple | 10-str-found-at-the-beginning |    8150   |    0.123  |             26543.33% |                40.72% | 3.9e-08   |      20 |
 | match::simple | 1-str-found                   |    8310   |    0.12   |             27061.90% |                38.04% |   6e-08   |      21 |
 | match::simple | 0-str                         |   11500   |    0.0871 |             37393.25% |                 0.00% | 2.9e-08   |      20 |
 +---------------+-------------------------------+-----------+-----------+-----------------------+-----------------------+-----------+---------+


The above result formatted in L<Benchmark.pm|Benchmark> style:

                                        Rate  S:R 1000-str-found-at-the-end  m:s 1000-str-found-at-the-end  S:R 0-str  S:R 10-str-found-at-the-end  S:R 10-str-found-at-the-beginning  S:R 1-str-found  m:s 10-str-found-at-the-end  m:s 10-str-found-at-the-beginning  m:s 1-str-found  m:s 0-str 
  S:R 1000-str-found-at-the-end         31/s                             --                            -5%        -9%                          -9%                                -9%             -19%                         -98%                               -99%             -99%       -99% 
  m:s 1000-str-found-at-the-end       32.1/s                             5%                             --        -3%                          -3%                                -3%             -15%                         -98%                               -99%             -99%       -99% 
  S:R 0-str                             30/s                            10%                             4%         --                           0%                                 0%             -11%                         -98%                               -99%             -99%       -99% 
  S:R 10-str-found-at-the-end           30/s                            10%                             4%         0%                           --                                 0%             -11%                         -98%                               -99%             -99%       -99% 
  S:R 10-str-found-at-the-beginning     40/s                            10%                             4%         0%                           0%                                 --             -11%                         -98%                               -99%             -99%       -99% 
  S:R 1-str-found                     37.7/s                            24%                            17%        13%                          13%                                13%               --                         -98%                               -99%             -99%       -99% 
  m:s 10-str-found-at-the-end         2460/s                          8008%                          7565%      7271%                        7271%                              7271%            6411%                           --                               -69%             -70%       -78% 
  m:s 10-str-found-at-the-beginning   8150/s                         26729%                         25265%     24290%                       24290%                             24290%           21444%                         230%                                 --              -2%       -29% 
  m:s 1-str-found                     8310/s                         27400%                         25900%     24900%                       24900%                             24900%           21983%                         239%                                 2%               --       -27% 
  m:s 0-str                          11500/s                         37787%                         35720%     34343%                       34343%                             34343%           30324%                         367%                                41%              37%         -- 
 
 Legends:
   S:R 0-str: dataset=0-str participant=Switch::Right
   S:R 1-str-found: dataset=1-str-found participant=Switch::Right
   S:R 10-str-found-at-the-beginning: dataset=10-str-found-at-the-beginning participant=Switch::Right
   S:R 10-str-found-at-the-end: dataset=10-str-found-at-the-end participant=Switch::Right
   S:R 1000-str-found-at-the-end: dataset=1000-str-found-at-the-end participant=Switch::Right
   m:s 0-str: dataset=0-str participant=match::simple
   m:s 1-str-found: dataset=1-str-found participant=match::simple
   m:s 10-str-found-at-the-beginning: dataset=10-str-found-at-the-beginning participant=match::simple
   m:s 10-str-found-at-the-end: dataset=10-str-found-at-the-end participant=match::simple
   m:s 1000-str-found-at-the-end: dataset=1000-str-found-at-the-end participant=match::simple

=head2 Sample benchmark #2

Benchmark command (benchmarking module startup overhead):

 % bencher -m SmartMatch::str_in_ary_of_str --module-startup

Result formatted as table:

 #table2#
 +---------------------+-----------+-------------------+-----------------------+-----------------------+-----------+---------+
 | participant         | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors   | samples |
 +---------------------+-----------+-------------------+-----------------------+-----------------------+-----------+---------+
 | Switch::Right       |     770   |             762.6 |                 0.00% |             10343.68% |   0.0047  |      20 |
 | match::simple       |      21   |              13.6 |              3543.36% |               186.65% |   0.00013 |      20 |
 | perl -e1 (baseline) |       7.4 |               0   |             10343.68% |                 0.00% | 3.8e-05   |      20 |
 +---------------------+-----------+-------------------+-----------------------+-----------------------+-----------+---------+


The above result formatted in L<Benchmark.pm|Benchmark> style:

                          Rate     S:R   m:s  perl -e1 (baseline) 
  S:R                    1.3/s      --  -97%                 -99% 
  m:s                   47.6/s   3566%    --                 -64% 
  perl -e1 (baseline)  135.1/s  10305%  183%                   -- 
 
 Legends:
   S:R: mod_overhead_time=762.6 participant=Switch::Right
   m:s: mod_overhead_time=13.6 participant=match::simple
   perl -e1 (baseline): mod_overhead_time=0 participant=perl -e1 (baseline)

To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 BENCHMARK NOTES

Each participant code does a 100x matching.

On my system, L<Switch::Right> seems to have the base overhead of ~0.25ms even
for the simplest string and shortest array. So as cool as that module is, for
most practical purposes it's a no-go.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-ScenarioBundle-SmartMatch>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-ScenarioBundle-SmartMatch>.

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

This software is copyright (c) 2024 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-ScenarioBundle-SmartMatch>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
