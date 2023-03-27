package Bencher::Scenario::Sort::HashKeys;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-01-17'; # DATE
our $DIST = 'Bencher-Scenario-Sort-HashKeys'; # DIST
our $VERSION = '0.002'; # VERSION

our $scenario = {
    summary => 'Benchmark Sort::HashKeys',
    participants => [
        {
            name => 'map',
            code_template => 'state $h = <hash>; map {($_, $h->{$_})} sort keys %$h',
            result_is_list => 1,
        },
        {
            module => 'Sort::HashKeys',
            function => 'sort',
            code_template => 'state $h = <hash>; Sort::HashKeys::sort(%$h)',
            result_is_list => 1,
        },
    ],
    datasets => [
        {name=>'2key'   , args=>{hash=>{map {$_=>1} 1..   2}} },
        {name=>'10key'  , args=>{hash=>{map {$_=>1} 1..  10}} },
        {name=>'100key' , args=>{hash=>{map {$_=>1} 1.. 100}} },
        {name=>'1000key', args=>{hash=>{map {$_=>1} 1..1000}} },
    ],
};

1;
# ABSTRACT: Benchmark Sort::HashKeys

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::Sort::HashKeys - Benchmark Sort::HashKeys

=head1 VERSION

This document describes version 0.002 of Bencher::Scenario::Sort::HashKeys (from Perl distribution Bencher-Scenario-Sort-HashKeys), released on 2023-01-17.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m Sort::HashKeys

To run module startup overhead benchmark:

 % bencher --module-startup -m Sort::HashKeys

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Sort::HashKeys> 0.007

=head1 BENCHMARK PARTICIPANTS

=over

=item * map (perl_code)

Code template:

 state $h = <hash>; map {($_, $h->{$_})} sort keys %$h



=item * Sort::HashKeys::sort (perl_code)

Code template:

 state $h = <hash>; Sort::HashKeys::sort(%$h)



=back

=head1 BENCHMARK DATASETS

=over

=item * 2key

=item * 10key

=item * 100key

=item * 1000key

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.34.0 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 20.04 >>, OS kernel: I<< Linux version 5.4.0-91-generic >>.

Benchmark with default options (C<< bencher -m Sort::HashKeys >>):

 #table1#
 +----------------------+---------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant          | dataset | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +----------------------+---------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | map                  | 1000key |    3200   |  312      |                 0.00% |            137659.07% | 2.1e-07 |      20 |
 | Sort::HashKeys::sort | 1000key |    3680   |  272      |                14.80% |            119900.42% | 1.6e-07 |      20 |
 | map                  | 100key  |   51587.5 |   19.3845 |              1510.05% |              8456.21% | 5.8e-12 |      34 |
 | Sort::HashKeys::sort | 100key  |   58138   |   17.2    |              1714.48% |              7492.19% | 2.2e-11 |      20 |
 | map                  | 10key   |  610300   |    1.638  |             18948.95% |               623.18% | 2.3e-11 |      20 |
 | Sort::HashKeys::sort | 10key   |  937000   |    1.07   |             29137.61% |               371.17% | 4.2e-10 |      20 |
 | map                  | 2key    | 2510000   |    0.398  |             78309.78% |                75.69% | 2.1e-10 |      20 |
 | Sort::HashKeys::sort | 2key    | 4400000   |    0.23   |            137659.07% |                 0.00% | 4.2e-10 |      20 |
 +----------------------+---------+-----------+-----------+-----------------------+-----------------------+---------+---------+


Formatted as L<Benchmark.pm|Benchmark> result:

                     Rate  m 1000key  SH:s 1000key  m 100key  SH:s 100key  m 10key  SH:s 10key  m 2key  SH:s 2key 
  m 1000key        3200/s         --          -12%      -93%         -94%     -99%        -99%    -99%       -99% 
  SH:s 1000key     3680/s        14%            --      -92%         -93%     -99%        -99%    -99%       -99% 
  m 100key      51587.5/s      1509%         1303%        --         -11%     -91%        -94%    -97%       -98% 
  SH:s 100key     58138/s      1713%         1481%       12%           --     -90%        -93%    -97%       -98% 
  m 10key        610300/s     18947%        16505%     1083%         950%       --        -34%    -75%       -85% 
  SH:s 10key     937000/s     29058%        25320%     1711%        1507%      53%          --    -62%       -78% 
  m 2key        2510000/s     78291%        68241%     4770%        4221%     311%        168%      --       -42% 
  SH:s 2key     4400000/s    135552%       118160%     8328%        7378%     612%        365%     73%         -- 
 
 Legends:
   SH:s 1000key: dataset=1000key participant=Sort::HashKeys::sort
   SH:s 100key: dataset=100key participant=Sort::HashKeys::sort
   SH:s 10key: dataset=10key participant=Sort::HashKeys::sort
   SH:s 2key: dataset=2key participant=Sort::HashKeys::sort
   m 1000key: dataset=1000key participant=map
   m 100key: dataset=100key participant=map
   m 10key: dataset=10key participant=map
   m 2key: dataset=2key participant=map

Benchmark module startup overhead (C<< bencher -m Sort::HashKeys --module-startup >>):

 #table2#
 +---------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | participant         | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +---------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | Sort::HashKeys      |       9   |               2.3 |                 0.00% |                34.53% | 3.8e-05 |      20 |
 | perl -e1 (baseline) |       6.7 |               0   |                34.53% |                 0.00% | 6.3e-05 |      20 |
 +---------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+


Formatted as L<Benchmark.pm|Benchmark> result:

                          Rate  S:H  perl -e1 (baseline) 
  S:H                  111.1/s   --                 -25% 
  perl -e1 (baseline)  149.3/s  34%                   -- 
 
 Legends:
   S:H: mod_overhead_time=2.3 participant=Sort::HashKeys
   perl -e1 (baseline): mod_overhead_time=0 participant=perl -e1 (baseline)

To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-Sort-HashKeys>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-Sort-HashKeys>.

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

This software is copyright (c) 2023, 2017 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-Sort-HashKeys>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
