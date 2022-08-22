package Bencher::Scenario::Data::Walk::More::walking;

use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-07-21'; # DATE
our $DIST = 'Bencher-Scenarios-Data-Walk-More'; # DIST
our $VERSION = '0.001'; # VERSION

our $scenario = {
    summary => 'Benchmark walk() & walkdepth() with an empty walker subroutine against various data structures',
    participants => [
        { fcall_template => 'Data::Walk::More::walk(sub {}, <data>)' },
        { fcall_template => 'Data::Walk::More::walkdepth(sub {}, <data>)' },
        { fcall_template => 'Data::Walk::walk(sub {}, <data>)' },
        { fcall_template => 'Data::Walk::walkdepth(sub {}, <data>)' },
    ],
    datasets => [
        {name=>'ary0', args=>{data=>[]}},
        {name=>'ary10', args=>{data=>[1..10]}},
        {name=>'ary100', args=>{data=>[1..100]}},
        {name=>'ary1k', args=>{data=>[1..1000]}},
        {name=>'ary10k', args=>{data=>[1..10_000]}},
    ],
};

1;
# ABSTRACT: Benchmark walk() & walkdepth() with an empty walker subroutine against various data structures

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::Data::Walk::More::walking - Benchmark walk() & walkdepth() with an empty walker subroutine against various data structures

=head1 VERSION

This document describes version 0.001 of Bencher::Scenario::Data::Walk::More::walking (from Perl distribution Bencher-Scenarios-Data-Walk-More), released on 2022-07-21.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m Data::Walk::More::walking

To run module startup overhead benchmark:

 % bencher --module-startup -m Data::Walk::More::walking

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Data::Walk::More> 0.002

L<Data::Walk> 2.01

=head1 BENCHMARK PARTICIPANTS

=over

=item * Data::Walk::More::walk (perl_code)

Function call template:

 Data::Walk::More::walk(sub {}, <data>)



=item * Data::Walk::More::walkdepth (perl_code)

Function call template:

 Data::Walk::More::walkdepth(sub {}, <data>)



=item * Data::Walk::walk (perl_code)

Function call template:

 Data::Walk::walk(sub {}, <data>)



=item * Data::Walk::walkdepth (perl_code)

Function call template:

 Data::Walk::walkdepth(sub {}, <data>)



=back

=head1 BENCHMARK DATASETS

=over

=item * ary0

=item * ary10

=item * ary100

=item * ary1k

=item * ary10k

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.34.0 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 20.04 >>, OS kernel: I<< Linux version 5.4.0-91-generic >>.

Benchmark with default options (C<< bencher -m Data::Walk::More::walking >>):

 #table1#
 {dataset=>"ary0"}
 +-----------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                 | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-----------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | Data::Walk::walkdepth       |    260000 |      3.9  |                 0.00% |                45.18% | 6.7e-09 |      20 |
 | Data::Walk::walk            |    270000 |      3.7  |                 5.32% |                37.85% | 6.2e-09 |      23 |
 | Data::Walk::More::walkdepth |    289000 |      3.47 |                11.36% |                30.37% | 1.6e-09 |      23 |
 | Data::Walk::More::walk      |    380000 |      2.7  |                45.18% |                 0.00% | 3.3e-09 |      20 |
 +-----------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

Formatted as L<Benchmark.pm|Benchmark> result:

                                   Rate  Data::Walk::walkdepth  Data::Walk::walk  Data::Walk::More::walkdepth  Data::Walk::More::walk 
  Data::Walk::walkdepth        260000/s                     --               -5%                         -11%                    -30% 
  Data::Walk::walk             270000/s                     5%                --                          -6%                    -27% 
  Data::Walk::More::walkdepth  289000/s                    12%                6%                           --                    -22% 
  Data::Walk::More::walk       380000/s                    44%               37%                          28%                      -- 
 
 Legends:
   Data::Walk::More::walk: participant=Data::Walk::More::walk
   Data::Walk::More::walkdepth: participant=Data::Walk::More::walkdepth
   Data::Walk::walk: participant=Data::Walk::walk
   Data::Walk::walkdepth: participant=Data::Walk::walkdepth

 #table2#
 {dataset=>"ary10"}
 +-----------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                 | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-----------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | Data::Walk::walkdepth       |     73700 |     13.6  |                 0.00% |                78.43% | 6.4e-09 |      22 |
 | Data::Walk::walk            |     76000 |     13    |                 3.53% |                72.34% |   2e-08 |      21 |
 | Data::Walk::More::walkdepth |    118000 |      8.49 |                59.72% |                11.72% | 3.3e-09 |      20 |
 | Data::Walk::More::walk      |    132000 |      7.6  |                78.43% |                 0.00% | 3.3e-09 |      20 |
 +-----------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

Formatted as L<Benchmark.pm|Benchmark> result:

                                   Rate  Data::Walk::walkdepth  Data::Walk::walk  Data::Walk::More::walkdepth  Data::Walk::More::walk 
  Data::Walk::walkdepth         73700/s                     --               -4%                         -37%                    -44% 
  Data::Walk::walk              76000/s                     4%                --                         -34%                    -41% 
  Data::Walk::More::walkdepth  118000/s                    60%               53%                           --                    -10% 
  Data::Walk::More::walk       132000/s                    78%               71%                          11%                      -- 
 
 Legends:
   Data::Walk::More::walk: participant=Data::Walk::More::walk
   Data::Walk::More::walkdepth: participant=Data::Walk::More::walkdepth
   Data::Walk::walk: participant=Data::Walk::walk
   Data::Walk::walkdepth: participant=Data::Walk::walkdepth

 #table3#
 {dataset=>"ary100"}
 +-----------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                 | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-----------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | Data::Walk::walkdepth       |   10600   |   94      |                 0.00% |                92.26% | 2.7e-08 |      20 |
 | Data::Walk::walk            |   10900   |   91.6    |                 2.62% |                87.36% | 2.7e-08 |      20 |
 | Data::Walk::More::walkdepth |   19361.4 |   51.6493 |                81.95% |                 5.67% | 1.1e-11 |      22 |
 | Data::Walk::More::walk      |   20000   |   49      |                92.26% |                 0.00% | 5.3e-08 |      20 |
 +-----------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

Formatted as L<Benchmark.pm|Benchmark> result:

                                    Rate  Data::Walk::walkdepth  Data::Walk::walk  Data::Walk::More::walkdepth  Data::Walk::More::walk 
  Data::Walk::walkdepth          10600/s                     --               -2%                         -45%                    -47% 
  Data::Walk::walk               10900/s                     2%                --                         -43%                    -46% 
  Data::Walk::More::walkdepth  19361.4/s                    81%               77%                           --                     -5% 
  Data::Walk::More::walk         20000/s                    91%               86%                           5%                      -- 
 
 Legends:
   Data::Walk::More::walk: participant=Data::Walk::More::walk
   Data::Walk::More::walkdepth: participant=Data::Walk::More::walkdepth
   Data::Walk::walk: participant=Data::Walk::walk
   Data::Walk::walkdepth: participant=Data::Walk::walkdepth

 #table4#
 {dataset=>"ary10k"}
 +-----------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                 | rate (/s) | time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-----------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | Data::Walk::walkdepth       |       112 |      8.9  |                 0.00% |                85.95% | 2.2e-06 |      20 |
 | Data::Walk::walk            |       115 |      8.69 |                 2.40% |                81.59% | 2.9e-06 |      20 |
 | Data::Walk::More::walkdepth |       210 |      4.8  |                84.66% |                 0.70% | 6.5e-06 |      20 |
 | Data::Walk::More::walk      |       209 |      4.78 |                85.95% |                 0.00% | 4.7e-06 |      20 |
 +-----------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

Formatted as L<Benchmark.pm|Benchmark> result:

                                Rate  Data::Walk::walkdepth  Data::Walk::walk  Data::Walk::More::walkdepth  Data::Walk::More::walk 
  Data::Walk::walkdepth        112/s                     --               -2%                         -46%                    -46% 
  Data::Walk::walk             115/s                     2%                --                         -44%                    -44% 
  Data::Walk::More::walkdepth  210/s                    85%               81%                           --                      0% 
  Data::Walk::More::walk       209/s                    86%               81%                           0%                      -- 
 
 Legends:
   Data::Walk::More::walk: participant=Data::Walk::More::walk
   Data::Walk::More::walkdepth: participant=Data::Walk::More::walkdepth
   Data::Walk::walk: participant=Data::Walk::walk
   Data::Walk::walkdepth: participant=Data::Walk::walkdepth

 #table5#
 {dataset=>"ary1k"}
 +-----------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                 | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-----------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | Data::Walk::walkdepth       |      1120 |       891 |                 0.00% |                94.75% | 4.2e-07 |      21 |
 | Data::Walk::walk            |      1150 |       873 |                 2.04% |                90.85% | 2.7e-07 |      20 |
 | Data::Walk::More::walkdepth |      2150 |       466 |                91.29% |                 1.81% | 4.3e-07 |      20 |
 | Data::Walk::More::walk      |      2190 |       457 |                94.75% |                 0.00% | 2.1e-07 |      20 |
 +-----------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

Formatted as L<Benchmark.pm|Benchmark> result:

                                 Rate  Data::Walk::walkdepth  Data::Walk::walk  Data::Walk::More::walkdepth  Data::Walk::More::walk 
  Data::Walk::walkdepth        1120/s                     --               -2%                         -47%                    -48% 
  Data::Walk::walk             1150/s                     2%                --                         -46%                    -47% 
  Data::Walk::More::walkdepth  2150/s                    91%               87%                           --                     -1% 
  Data::Walk::More::walk       2190/s                    94%               91%                           1%                      -- 
 
 Legends:
   Data::Walk::More::walk: participant=Data::Walk::More::walk
   Data::Walk::More::walkdepth: participant=Data::Walk::More::walkdepth
   Data::Walk::walk: participant=Data::Walk::walk
   Data::Walk::walkdepth: participant=Data::Walk::walkdepth


Benchmark module startup overhead (C<< bencher -m Data::Walk::More::walking --module-startup >>):

 #table6#
 +---------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | participant         | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +---------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | Data::Walk::More    |      10.9 |               4.6 |                 0.00% |                72.40% | 4.5e-06 |      20 |
 | Data::Walk          |      10.8 |               4.5 |                 1.26% |                70.26% | 3.4e-06 |      20 |
 | perl -e1 (baseline) |       6.3 |               0   |                72.40% |                 0.00% | 1.8e-05 |      20 |
 +---------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+


Formatted as L<Benchmark.pm|Benchmark> result:

                          Rate  DW:M  D:W  perl -e1 (baseline) 
  DW:M                  91.7/s    --   0%                 -42% 
  D:W                   92.6/s    0%   --                 -41% 
  perl -e1 (baseline)  158.7/s   73%  71%                   -- 
 
 Legends:
   D:W: mod_overhead_time=4.5 participant=Data::Walk
   DW:M: mod_overhead_time=4.6 participant=Data::Walk::More
   perl -e1 (baseline): mod_overhead_time=0 participant=perl -e1 (baseline)

To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-Data-Walk-More>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-Data-Walk-More>.

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-Data-Walk-More>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
