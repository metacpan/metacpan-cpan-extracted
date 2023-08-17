package Bencher::Scenario::Data::Sah::gen_validator;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-01-19'; # DATE
our $DIST = 'Bencher-Scenarios-Data-Sah'; # DIST
our $VERSION = '0.071'; # VERSION

my $return_types = ['bool', 'str', 'full'];

our $scenario = {
    summary => 'Benchmark validator generation',
    modules => {
        'Data::Sah' => {version=>'0.84'},
    },
    participants => [
        {
            name => 'gen_validator',
            fcall_template => 'Data::Sah::gen_validator(<schema>, {return_type=> <return_type>})',
        },
    ],
    datasets => [
        {args => {'return_type@' => $return_types, schema => 'int'}},
        {args => {'return_type@' => $return_types, schema => 'int*'}},
        {args => {'return_type@' => $return_types, schema => 'str'}},
        {args => {'return_type@' => $return_types, schema => 'str*'}},
        {args => {'return_type@' => $return_types, schema => ['str', len=>8]}},
        {args => {'return_type@' => $return_types, schema => ['str', min_len=>1, max_len=>10]}},
        {args => {'return_type@' => $return_types, schema => 'date'}},
        {args => {'return_type@' => $return_types, schema => ['array', of=>['str', min_len=>1, max_len=>10]]}},
        {args => {'return_type@' => $return_types, schema => ['array', elems=>['int*', 'str*', 'float*', 're*']]}},
    ],
};

1;
# ABSTRACT: Benchmark validator generation

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::Data::Sah::gen_validator - Benchmark validator generation

=head1 VERSION

This document describes version 0.071 of Bencher::Scenario::Data::Sah::gen_validator (from Perl distribution Bencher-Scenarios-Data-Sah), released on 2023-01-19.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m Data::Sah::gen_validator

To run module startup overhead benchmark:

 % bencher --module-startup -m Data::Sah::gen_validator

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Data::Sah> 0.914

=head1 BENCHMARK PARTICIPANTS

=over

=item * gen_validator (perl_code)

Function call template:

 Data::Sah::gen_validator(<schema>, {return_type=> <return_type>})



=back

=head1 BENCHMARK DATASETS

=over

=item * int

=item * int*

=item * str

=item * str*

=item * ["str","len",8]

=item * ["str","min_len",1,"max_len",10]

=item * date

=item * ["array","of",["str","min_len",1,"max_len",10]]

=item * ["array","elems",["int*","str*","float*","re*"]]

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.34.0 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 20.04 >>, OS kernel: I<< Linux version 5.4.0-91-generic >>.

Benchmark with default options (C<< bencher -m Data::Sah::gen_validator >>):

 #table1#
 +--------------------------------------------------+-----------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | dataset                                          | arg_return_type | rate (/s) | time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +--------------------------------------------------+-----------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | ["array","elems",["int*","str*","float*","re*"]] | str             |       200 |      5    |                 0.00% |               495.12% | 3.1e-05 |      20 |
 | ["array","elems",["int*","str*","float*","re*"]] | full            |       200 |      4.9  |                 1.42% |               486.82% |   4e-05 |      21 |
 | ["array","elems",["int*","str*","float*","re*"]] | bool            |       200 |      5    |                 4.54% |               469.27% | 5.8e-05 |      20 |
 | ["array","of",["str","min_len",1,"max_len",10]]  | full            |       390 |      2.6  |                91.65% |               210.52% | 1.4e-05 |      22 |
 | ["array","of",["str","min_len",1,"max_len",10]]  | str             |       400 |      3    |                93.19% |               208.05% |   3e-05 |      21 |
 | ["array","of",["str","min_len",1,"max_len",10]]  | bool            |       400 |      2    |               117.86% |               173.16% | 2.4e-05 |      20 |
 | ["str","min_len",1,"max_len",10]                 | full            |       500 |      2    |               141.46% |               146.47% | 7.1e-05 |      20 |
 | ["str","min_len",1,"max_len",10]                 | str             |       640 |      1.6  |               218.42% |                86.90% | 1.5e-05 |      20 |
 | date                                             | full            |       700 |      2    |               230.87% |                79.87% | 2.3e-05 |      20 |
 | ["str","min_len",1,"max_len",10]                 | bool            |       700 |      1    |               264.35% |                63.34% | 2.3e-05 |      20 |
 | date                                             | bool            |       760 |      1.3  |               279.79% |                56.70% | 9.2e-06 |      20 |
 | date                                             | str             |       800 |      1    |               280.37% |                56.46% | 1.4e-05 |      20 |
 | ["str","len",8]                                  | str             |       800 |      1    |               299.18% |                49.09% | 1.2e-05 |      20 |
 | ["str","len",8]                                  | full            |       800 |      1    |               302.53% |                47.85% | 1.7e-05 |      20 |
 | ["str","len",8]                                  | bool            |       900 |      1    |               337.28% |                36.10% | 1.4e-05 |      20 |
 | str*                                             | full            |       900 |      1    |               344.15% |                33.99% | 2.1e-05 |      20 |
 | int*                                             | full            |       990 |      1    |               391.99% |                20.96% | 6.2e-06 |      22 |
 | str                                              | full            |      1000 |      1    |               401.88% |                18.58% | 1.6e-05 |      20 |
 | int                                              | full            |      1000 |      0.98 |               409.39% |                16.83% | 7.4e-06 |      20 |
 | str*                                             | bool            |      1000 |      0.97 |               413.98% |                15.79% | 7.8e-06 |      20 |
 | int*                                             | str             |      1000 |      1    |               418.32% |                14.82% | 1.5e-05 |      20 |
 | str*                                             | str             |      1000 |      0.9  |               430.35% |                12.21% | 1.1e-05 |      20 |
 | int                                              | str             |      1100 |      0.92 |               438.14% |                10.59% | 6.4e-06 |      24 |
 | int                                              | bool            |      1000 |      0.9  |               450.88% |                 8.03% | 1.6e-05 |      20 |
 | int*                                             | bool            |      1100 |      0.89 |               457.44% |                 6.76% | 4.4e-06 |      20 |
 | str                                              | bool            |      1100 |      0.88 |               466.69% |                 5.02% | 6.2e-06 |      20 |
 | str                                              | str             |      1000 |      0.8  |               495.12% |                 0.00% | 1.3e-05 |      20 |
 +--------------------------------------------------+-----------------+-----------+-----------+-----------------------+-----------------------+---------+---------+


Formatted as L<Benchmark.pm|Benchmark> result:

                                                           Rate  ["array","elems",["int*","str*","float*","re*"]] str  ["array","elems",["int*","str*","float*","re*"]] bool  ["array","elems",["int*","str*","float*","re*"]] full  ["array","of",["str","min_len",1,"max_len",10]] str  ["array","of",["str","min_len",1,"max_len",10]] full  ["array","of",["str","min_len",1,"max_len",10]] bool  ["str","min_len",1,"max_len",10] full  date full  ["str","min_len",1,"max_len",10] str  date bool  ["str","min_len",1,"max_len",10] bool  date str  ["str","len",8] str  ["str","len",8] full  ["str","len",8] bool  str* full  int* full  str full  int* str  int full  str* bool  int str  str* str  int bool  int* bool  str bool  str str 
  ["array","elems",["int*","str*","float*","re*"]] str    200/s                                                    --                                                     0%                                                    -1%                                                 -40%                                                  -48%                                                  -60%                                   -60%       -60%                                  -68%       -74%                                   -80%      -80%                 -80%                  -80%                  -80%       -80%       -80%      -80%      -80%      -80%       -80%     -81%      -82%      -82%       -82%      -82%     -84% 
  ["array","elems",["int*","str*","float*","re*"]] bool   200/s                                                    0%                                                     --                                                    -1%                                                 -40%                                                  -48%                                                  -60%                                   -60%       -60%                                  -68%       -74%                                   -80%      -80%                 -80%                  -80%                  -80%       -80%       -80%      -80%      -80%      -80%       -80%     -81%      -82%      -82%       -82%      -82%     -84% 
  ["array","elems",["int*","str*","float*","re*"]] full   200/s                                                    2%                                                     2%                                                     --                                                 -38%                                                  -46%                                                  -59%                                   -59%       -59%                                  -67%       -73%                                   -79%      -79%                 -79%                  -79%                  -79%       -79%       -79%      -79%      -79%      -80%       -80%     -81%      -81%      -81%       -81%      -82%     -83% 
  ["array","of",["str","min_len",1,"max_len",10]] str     400/s                                                   66%                                                    66%                                                    63%                                                   --                                                  -13%                                                  -33%                                   -33%       -33%                                  -46%       -56%                                   -66%      -66%                 -66%                  -66%                  -66%       -66%       -66%      -66%      -66%      -67%       -67%     -69%      -70%      -70%       -70%      -70%     -73% 
  ["array","of",["str","min_len",1,"max_len",10]] full    390/s                                                   92%                                                    92%                                                    88%                                                  15%                                                    --                                                  -23%                                   -23%       -23%                                  -38%       -50%                                   -61%      -61%                 -61%                  -61%                  -61%       -61%       -61%      -61%      -61%      -62%       -62%     -64%      -65%      -65%       -65%      -66%     -69% 
  ["array","of",["str","min_len",1,"max_len",10]] bool    400/s                                                  150%                                                   150%                                                   145%                                                  50%                                                   30%                                                    --                                     0%         0%                                  -19%       -35%                                   -50%      -50%                 -50%                  -50%                  -50%       -50%       -50%      -50%      -50%      -51%       -51%     -54%      -55%      -55%       -55%      -56%     -60% 
  ["str","min_len",1,"max_len",10] full                   500/s                                                  150%                                                   150%                                                   145%                                                  50%                                                   30%                                                    0%                                     --         0%                                  -19%       -35%                                   -50%      -50%                 -50%                  -50%                  -50%       -50%       -50%      -50%      -50%      -51%       -51%     -54%      -55%      -55%       -55%      -56%     -60% 
  date full                                               700/s                                                  150%                                                   150%                                                   145%                                                  50%                                                   30%                                                    0%                                     0%         --                                  -19%       -35%                                   -50%      -50%                 -50%                  -50%                  -50%       -50%       -50%      -50%      -50%      -51%       -51%     -54%      -55%      -55%       -55%      -56%     -60% 
  ["str","min_len",1,"max_len",10] str                    640/s                                                  212%                                                   212%                                                   206%                                                  87%                                                   62%                                                   25%                                    25%        25%                                    --       -18%                                   -37%      -37%                 -37%                  -37%                  -37%       -37%       -37%      -37%      -37%      -38%       -39%     -42%      -43%      -43%       -44%      -45%     -50% 
  date bool                                               760/s                                                  284%                                                   284%                                                   276%                                                 130%                                                  100%                                                   53%                                    53%        53%                                   23%         --                                   -23%      -23%                 -23%                  -23%                  -23%       -23%       -23%      -23%      -23%      -24%       -25%     -29%      -30%      -30%       -31%      -32%     -38% 
  ["str","min_len",1,"max_len",10] bool                   700/s                                                  400%                                                   400%                                                   390%                                                 200%                                                  160%                                                  100%                                   100%       100%                                   60%        30%                                     --        0%                   0%                    0%                    0%         0%         0%        0%        0%       -2%        -3%      -7%       -9%       -9%       -10%      -12%     -19% 
  date str                                                800/s                                                  400%                                                   400%                                                   390%                                                 200%                                                  160%                                                  100%                                   100%       100%                                   60%        30%                                     0%        --                   0%                    0%                    0%         0%         0%        0%        0%       -2%        -3%      -7%       -9%       -9%       -10%      -12%     -19% 
  ["str","len",8] str                                     800/s                                                  400%                                                   400%                                                   390%                                                 200%                                                  160%                                                  100%                                   100%       100%                                   60%        30%                                     0%        0%                   --                    0%                    0%         0%         0%        0%        0%       -2%        -3%      -7%       -9%       -9%       -10%      -12%     -19% 
  ["str","len",8] full                                    800/s                                                  400%                                                   400%                                                   390%                                                 200%                                                  160%                                                  100%                                   100%       100%                                   60%        30%                                     0%        0%                   0%                    --                    0%         0%         0%        0%        0%       -2%        -3%      -7%       -9%       -9%       -10%      -12%     -19% 
  ["str","len",8] bool                                    900/s                                                  400%                                                   400%                                                   390%                                                 200%                                                  160%                                                  100%                                   100%       100%                                   60%        30%                                     0%        0%                   0%                    0%                    --         0%         0%        0%        0%       -2%        -3%      -7%       -9%       -9%       -10%      -12%     -19% 
  str* full                                               900/s                                                  400%                                                   400%                                                   390%                                                 200%                                                  160%                                                  100%                                   100%       100%                                   60%        30%                                     0%        0%                   0%                    0%                    0%         --         0%        0%        0%       -2%        -3%      -7%       -9%       -9%       -10%      -12%     -19% 
  int* full                                               990/s                                                  400%                                                   400%                                                   390%                                                 200%                                                  160%                                                  100%                                   100%       100%                                   60%        30%                                     0%        0%                   0%                    0%                    0%         0%         --        0%        0%       -2%        -3%      -7%       -9%       -9%       -10%      -12%     -19% 
  str full                                               1000/s                                                  400%                                                   400%                                                   390%                                                 200%                                                  160%                                                  100%                                   100%       100%                                   60%        30%                                     0%        0%                   0%                    0%                    0%         0%         0%        --        0%       -2%        -3%      -7%       -9%       -9%       -10%      -12%     -19% 
  int* str                                               1000/s                                                  400%                                                   400%                                                   390%                                                 200%                                                  160%                                                  100%                                   100%       100%                                   60%        30%                                     0%        0%                   0%                    0%                    0%         0%         0%        0%        --       -2%        -3%      -7%       -9%       -9%       -10%      -12%     -19% 
  int full                                               1000/s                                                  410%                                                   410%                                                   400%                                                 206%                                                  165%                                                  104%                                   104%       104%                                   63%        32%                                     2%        2%                   2%                    2%                    2%         2%         2%        2%        2%        --        -1%      -6%       -8%       -8%        -9%      -10%     -18% 
  str* bool                                              1000/s                                                  415%                                                   415%                                                   405%                                                 209%                                                  168%                                                  106%                                   106%       106%                                   64%        34%                                     3%        3%                   3%                    3%                    3%         3%         3%        3%        3%        1%         --      -5%       -7%       -7%        -8%       -9%     -17% 
  int str                                                1100/s                                                  443%                                                   443%                                                   432%                                                 226%                                                  182%                                                  117%                                   117%       117%                                   73%        41%                                     8%        8%                   8%                    8%                    8%         8%         8%        8%        8%        6%         5%       --       -2%       -2%        -3%       -4%     -13% 
  str* str                                               1000/s                                                  455%                                                   455%                                                   444%                                                 233%                                                  188%                                                  122%                                   122%       122%                                   77%        44%                                    11%       11%                  11%                   11%                   11%        11%        11%       11%       11%        8%         7%       2%        --        0%        -1%       -2%     -11% 
  int bool                                               1000/s                                                  455%                                                   455%                                                   444%                                                 233%                                                  188%                                                  122%                                   122%       122%                                   77%        44%                                    11%       11%                  11%                   11%                   11%        11%        11%       11%       11%        8%         7%       2%        0%        --        -1%       -2%     -11% 
  int* bool                                              1100/s                                                  461%                                                   461%                                                   450%                                                 237%                                                  192%                                                  124%                                   124%       124%                                   79%        46%                                    12%       12%                  12%                   12%                   12%        12%        12%       12%       12%       10%         8%       3%        1%        1%         --       -1%     -10% 
  str bool                                               1100/s                                                  468%                                                   468%                                                   456%                                                 240%                                                  195%                                                  127%                                   127%       127%                                   81%        47%                                    13%       13%                  13%                   13%                   13%        13%        13%       13%       13%       11%        10%       4%        2%        2%         1%        --      -9% 
  str str                                                1000/s                                                  525%                                                   525%                                                   512%                                                 275%                                                  225%                                                  150%                                   150%       150%                                  100%        62%                                    25%       25%                  25%                   25%                   25%        25%        25%       25%       25%       22%        21%      14%       12%       12%        11%        9%       -- 
 
 Legends:
   ["array","elems",["int*","str*","float*","re*"]] bool: arg_return_type=bool dataset=["array","elems",["int*","str*","float*","re*"]]
   ["array","elems",["int*","str*","float*","re*"]] full: arg_return_type=full dataset=["array","elems",["int*","str*","float*","re*"]]
   ["array","elems",["int*","str*","float*","re*"]] str: arg_return_type=str dataset=["array","elems",["int*","str*","float*","re*"]]
   ["array","of",["str","min_len",1,"max_len",10]] bool: arg_return_type=bool dataset=["array","of",["str","min_len",1,"max_len",10]]
   ["array","of",["str","min_len",1,"max_len",10]] full: arg_return_type=full dataset=["array","of",["str","min_len",1,"max_len",10]]
   ["array","of",["str","min_len",1,"max_len",10]] str: arg_return_type=str dataset=["array","of",["str","min_len",1,"max_len",10]]
   ["str","len",8] bool: arg_return_type=bool dataset=["str","len",8]
   ["str","len",8] full: arg_return_type=full dataset=["str","len",8]
   ["str","len",8] str: arg_return_type=str dataset=["str","len",8]
   ["str","min_len",1,"max_len",10] bool: arg_return_type=bool dataset=["str","min_len",1,"max_len",10]
   ["str","min_len",1,"max_len",10] full: arg_return_type=full dataset=["str","min_len",1,"max_len",10]
   ["str","min_len",1,"max_len",10] str: arg_return_type=str dataset=["str","min_len",1,"max_len",10]
   date bool: arg_return_type=bool dataset=date
   date full: arg_return_type=full dataset=date
   date str: arg_return_type=str dataset=date
   int bool: arg_return_type=bool dataset=int
   int full: arg_return_type=full dataset=int
   int str: arg_return_type=str dataset=int
   int* bool: arg_return_type=bool dataset=int*
   int* full: arg_return_type=full dataset=int*
   int* str: arg_return_type=str dataset=int*
   str bool: arg_return_type=bool dataset=str
   str full: arg_return_type=full dataset=str
   str str: arg_return_type=str dataset=str
   str* bool: arg_return_type=bool dataset=str*
   str* full: arg_return_type=full dataset=str*
   str* str: arg_return_type=str dataset=str*

Benchmark module startup overhead (C<< bencher -m Data::Sah::gen_validator --module-startup >>):

 #table2#
 +---------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | participant         | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +---------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | Data::Sah           |      13   |               5.8 |                 0.00% |                82.19% | 8.3e-05 |      21 |
 | perl -e1 (baseline) |       7.2 |               0   |                82.19% |                 0.00% |   6e-05 |      20 |
 +---------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+


Formatted as L<Benchmark.pm|Benchmark> result:

                          Rate  D:S  perl -e1 (baseline) 
  D:S                   76.9/s   --                 -44% 
  perl -e1 (baseline)  138.9/s  80%                   -- 
 
 Legends:
   D:S: mod_overhead_time=5.8 participant=Data::Sah
   perl -e1 (baseline): mod_overhead_time=0 participant=perl -e1 (baseline)

To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-Data-Sah>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-Data-Sah>.

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-Data-Sah>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
