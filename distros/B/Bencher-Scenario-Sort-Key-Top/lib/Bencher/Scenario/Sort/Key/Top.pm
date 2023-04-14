package Bencher::Scenario::Sort::Key::Top;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-01-17'; # DATE
our $DIST = 'Bencher-Scenario-Sort-Key-Top'; # DIST
our $VERSION = '0.003'; # VERSION

our $scenario = {
    summary => 'Benchmark Sort::Key::Top',
    participants => [
        {
            name => 'sort',
            summary => "Perl's sort() builtin",
            code_template=>'state $elems=<elems>; my @sorted = sort { $a <=> $b } @$elems; splice @sorted, 0, <n>',
            result_is_list => 1,
        },
        {
            name => 'Sort::Key::Top',
            fcall_template => 'Sort::Key::Top::nkeytopsort(sub { $_ }, <n>, @{<elems>})',
            result_is_list => 1,
        },
        {
            name => 'Sort::Key::Top::PP',
            fcall_template => 'Sort::Key::Top::PP::nkeytopsort(sub { $_ }, <n>, @{<elems>})',
            result_is_list => 1,
        },
    ],
    datasets => [
        {name=>'elems=10 , n=5'    , args=>{elems=>[reverse 1..10]  , n=>  5}},
        {name=>'elems=100, n=10'   , args=>{elems=>[reverse 1..100] , n=> 10}},
        {name=>'elems=1000, n=10'  , args=>{elems=>[reverse 1..1000], n=> 10}},
    ],
};

1;
# ABSTRACT: Benchmark Sort::Key::Top

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::Sort::Key::Top - Benchmark Sort::Key::Top

=head1 VERSION

This document describes version 0.003 of Bencher::Scenario::Sort::Key::Top (from Perl distribution Bencher-Scenario-Sort-Key-Top), released on 2023-01-17.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m Sort::Key::Top

To run module startup overhead benchmark:

 % bencher --module-startup -m Sort::Key::Top

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Sort::Key::Top> 0.08

L<Sort::Key::Top::PP> 0.003

=head1 BENCHMARK PARTICIPANTS

=over

=item * sort (perl_code)

Perl's sort() builtin.

Code template:

 state $elems=<elems>; my @sorted = sort { $a <=> $b } @$elems; splice @sorted, 0, <n>



=item * Sort::Key::Top (perl_code)

Function call template:

 Sort::Key::Top::nkeytopsort(sub { $_ }, <n>, @{<elems>})



=item * Sort::Key::Top::PP (perl_code)

Function call template:

 Sort::Key::Top::PP::nkeytopsort(sub { $_ }, <n>, @{<elems>})



=back

=head1 BENCHMARK DATASETS

=over

=item * elems=10 , n=5

=item * elems=100, n=10

=item * elems=1000, n=10

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.34.0 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 20.04 >>, OS kernel: I<< Linux version 5.4.0-91-generic >>.

Benchmark with default options (C<< bencher -m Sort::Key::Top >>):

 #table1#
 +--------------------+------------------+-----------+------------+-----------------------+-----------------------+---------+---------+
 | participant        | dataset          | rate (/s) | time (μs)  | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +--------------------+------------------+-----------+------------+-----------------------+-----------------------+---------+---------+
 | Sort::Key::Top::PP | elems=1000, n=10 |       870 | 1200       |                 0.00% |            222715.67% | 2.9e-06 |      20 |
 | Sort::Key::Top     | elems=1000, n=10 |      6000 |  170       |               597.83% |             31829.83% | 4.3e-07 |      20 |
 | Sort::Key::Top::PP | elems=100, n=10  |      9000 |  110       |               937.16% |             21383.34% | 1.6e-07 |      20 |
 | sort               | elems=1000, n=10 |     39000 |   25       |              4457.13% |              4789.39% | 2.7e-08 |      20 |
 | Sort::Key::Top     | elems=100, n=10  |     59000 |   17       |              6738.28% |              3158.36% | 5.3e-08 |      20 |
 | Sort::Key::Top::PP | elems=10 , n=5   |    100691 |    9.93135 |             11522.11% |              1817.17% | 5.7e-12 |      20 |
 | sort               | elems=100, n=10  |    364000 |    2.75    |             41941.81% |               429.99% | 2.5e-09 |      20 |
 | Sort::Key::Top     | elems=10 , n=5   |    500000 |    2       |             57818.64% |               284.70% | 3.3e-09 |      20 |
 | sort               | elems=10 , n=5   |   1900000 |    0.52    |            222715.67% |                 0.00% | 8.3e-10 |      20 |
 +--------------------+------------------+-----------+------------+-----------------------+-----------------------+---------+---------+


Formatted as L<Benchmark.pm|Benchmark> result:

                               Rate  SKT:P elems=1000, n=10  SK:T elems=1000, n=10  SKT:P elems=100, n=10  s elems=1000, n=10  SK:T elems=100, n=10  SKT:P elems=10 , n=5  s elems=100, n=10  SK:T elems=10 , n=5  s elems=10 , n=5 
  SKT:P elems=1000, n=10      870/s                      --                   -85%                   -90%                -97%                  -98%                  -99%               -99%                 -99%              -99% 
  SK:T elems=1000, n=10      6000/s                    605%                     --                   -35%                -85%                  -90%                  -94%               -98%                 -98%              -99% 
  SKT:P elems=100, n=10      9000/s                    990%                    54%                     --                -77%                  -84%                  -90%               -97%                 -98%              -99% 
  s elems=1000, n=10        39000/s                   4700%                   580%                   340%                  --                  -31%                  -60%               -89%                 -92%              -97% 
  SK:T elems=100, n=10      59000/s                   6958%                   900%                   547%                 47%                    --                  -41%               -83%                 -88%              -96% 
  SKT:P elems=10 , n=5     100691/s                  11982%                  1611%                  1007%                151%                   71%                    --               -72%                 -79%              -94% 
  s elems=100, n=10        364000/s                  43536%                  6081%                  3900%                809%                  518%                  261%                 --                 -27%              -81% 
  SK:T elems=10 , n=5      500000/s                  59900%                  8400%                  5400%               1150%                  750%                  396%                37%                   --              -74% 
  s elems=10 , n=5        1900000/s                 230669%                 32592%                 21053%               4707%                 3169%                 1809%               428%                 284%                -- 
 
 Legends:
   SK:T elems=10 , n=5: dataset=elems=10 , n=5 participant=Sort::Key::Top
   SK:T elems=100, n=10: dataset=elems=100, n=10 participant=Sort::Key::Top
   SK:T elems=1000, n=10: dataset=elems=1000, n=10 participant=Sort::Key::Top
   SKT:P elems=10 , n=5: dataset=elems=10 , n=5 participant=Sort::Key::Top::PP
   SKT:P elems=100, n=10: dataset=elems=100, n=10 participant=Sort::Key::Top::PP
   SKT:P elems=1000, n=10: dataset=elems=1000, n=10 participant=Sort::Key::Top::PP
   s elems=10 , n=5: dataset=elems=10 , n=5 participant=sort
   s elems=100, n=10: dataset=elems=100, n=10 participant=sort
   s elems=1000, n=10: dataset=elems=1000, n=10 participant=sort

Benchmark module startup overhead (C<< bencher -m Sort::Key::Top --module-startup >>):

 #table2#
 +---------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | participant         | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +---------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | Sort::Key::Top::PP  |        30 |                22 |                 0.00% |               245.26% | 0.00053 |      20 |
 | Sort::Key::Top      |        20 |                12 |                58.48% |               117.86% | 0.00021 |      20 |
 | perl -e1 (baseline) |         8 |                 0 |               245.26% |                 0.00% | 0.00025 |      23 |
 +---------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+


Formatted as L<Benchmark.pm|Benchmark> result:

                          Rate  SKT:P  SK:T  perl -e1 (baseline) 
  SKT:P                 33.3/s     --  -33%                 -73% 
  SK:T                  50.0/s    50%    --                 -60% 
  perl -e1 (baseline)  125.0/s   275%  150%                   -- 
 
 Legends:
   SK:T: mod_overhead_time=12 participant=Sort::Key::Top
   SKT:P: mod_overhead_time=22 participant=Sort::Key::Top::PP
   perl -e1 (baseline): mod_overhead_time=0 participant=perl -e1 (baseline)

To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-Sort-Key-Top>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-Sort-Key-Top>.

=head1 SEE ALSO

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-Sort-Key-Top>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
