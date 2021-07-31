package Bencher::Scenario::CloneModules;

our $DATE = '2021-07-31'; # DATE
our $VERSION = '0.051'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark various data cloning modules',
    participants => [
        {fcall_template=>'Clone::clone(<data>)'},
        {fcall_template=>'Clone::PP::clone(<data>)'},
        {fcall_template=>'Data::Clone::clone(<data>)'},
        {fcall_template=>'Sereal::Dclone::dclone(<data>)'},
        {fcall_template=>'Storable::dclone(<data>)'},
    ],
    datasets => [
        {name=>'array0'   , args=>{data=>[]}},
        {name=>'array1'   , args=>{data=>[1]}},
        {name=>'array10'  , args=>{data=>[1..10]}},
        {name=>'array100' , args=>{data=>[1..100]}},
        {name=>'array1k'  , args=>{data=>[1..1000]}},
        {name=>'array10k' , args=>{data=>[1..10_000]}},

        {name=>'hash1k'   , args=>{data=>{map {$_=>1} 1..1000}}},
        {name=>'hash10k'  , args=>{data=>{map {$_=>1} 1..10_000}}},
    ],
};

1;
# ABSTRACT: Benchmark various data cloning modules

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::CloneModules - Benchmark various data cloning modules

=head1 VERSION

This document describes version 0.051 of Bencher::Scenario::CloneModules (from Perl distribution Bencher-Scenarios-CloneModules), released on 2021-07-31.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m CloneModules

To run module startup overhead benchmark:

 % bencher --module-startup -m CloneModules

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Clone> 0.45

L<Clone::PP> 1.08

L<Data::Clone> 0.004

L<Sereal::Dclone> 0.003

L<Storable> 3.23

=head1 BENCHMARK PARTICIPANTS

=over

=item * Clone::clone (perl_code)

Function call template:

 Clone::clone(<data>)



=item * Clone::PP::clone (perl_code)

Function call template:

 Clone::PP::clone(<data>)



=item * Data::Clone::clone (perl_code)

Function call template:

 Data::Clone::clone(<data>)



=item * Sereal::Dclone::dclone (perl_code)

Function call template:

 Sereal::Dclone::dclone(<data>)



=item * Storable::dclone (perl_code)

Function call template:

 Storable::dclone(<data>)



=back

=head1 BENCHMARK DATASETS

=over

=item * array0

=item * array1

=item * array10

=item * array100

=item * array1k

=item * array10k

=item * hash1k

=item * hash10k

=back

=head1 BENCHMARK SAMPLE RESULTS

=head2 Sample benchmark #1

Run on: perl: I<< v5.34.0 >>, CPU: I<< Intel(R) Core(TM) i7-4770 CPU @ 3.40GHz (4 cores) >>, OS: I<< GNU/Linux LinuxMint version 19 >>, OS kernel: I<< Linux version 5.3.0-68-generic >>.

Benchmark command (cloning a 10k-element array):

 % bencher -m CloneModules --include-datasets array10k

Result formatted as table:

 #table1#
 +------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant            | rate (/s) | time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | Clone::clone           |       492 |     2.03  |                 0.00% |               519.53% | 9.1e-07 |      20 |
 | Clone::PP::clone       |      1240 |     0.804 |               153.02% |               144.85% | 4.3e-07 |      20 |
 | Storable::dclone       |      1380 |     0.727 |               179.88% |               121.36% | 6.4e-07 |      20 |
 | Sereal::Dclone::dclone |      2820 |     0.355 |               472.99% |                 8.12% | 2.1e-07 |      21 |
 | Data::Clone::clone     |      3050 |     0.328 |               519.53% |                 0.00% | 2.1e-07 |      20 |
 +------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+


The above result formatted in L<Benchmark.pm|Benchmark> style:

          Rate   C:c  CP:c   S:d  SD:d  DC:c 
  C:c    492/s    --  -60%  -64%  -82%  -83% 
  CP:c  1240/s  152%    --   -9%  -55%  -59% 
  S:d   1380/s  179%   10%    --  -51%  -54% 
  SD:d  2820/s  471%  126%  104%    --   -7% 
  DC:c  3050/s  518%  145%  121%    8%    -- 
 
 Legends:
   C:c: participant=Clone::clone
   CP:c: participant=Clone::PP::clone
   DC:c: participant=Data::Clone::clone
   S:d: participant=Storable::dclone
   SD:d: participant=Sereal::Dclone::dclone

The above result presented as chart:

=begin html

<img src="data:image/png;base64,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" />

=end html


=head2 Sample benchmark #2

Benchmark command (cloning a 10k-pair hash):

 % bencher -m CloneModules --include-datasets hash10k

Result formatted as table:

 #table2#
 +------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant            | rate (/s) | time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | Clone::clone           |       190 |      5.1  |                 0.00% |               117.84% | 7.8e-06 |      20 |
 | Clone::PP::clone       |       210 |      4.7  |                 9.40% |                99.12% | 5.5e-06 |      20 |
 | Storable::dclone       |       335 |      2.99 |                72.11% |                26.57% | 2.9e-06 |      20 |
 | Data::Clone::clone     |       360 |      2.8  |                84.80% |                17.88% | 3.8e-06 |      20 |
 | Sereal::Dclone::dclone |       420 |      2.4  |               117.84% |                 0.00% | 2.7e-06 |      20 |
 +------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+


The above result formatted in L<Benchmark.pm|Benchmark> style:

         Rate   C:c  CP:c   S:d  DC:c  SD:d 
  C:c   190/s    --   -7%  -41%  -45%  -52% 
  CP:c  210/s    8%    --  -36%  -40%  -48% 
  S:d   335/s   70%   57%    --   -6%  -19% 
  DC:c  360/s   82%   67%    6%    --  -14% 
  SD:d  420/s  112%   95%   24%   16%    -- 
 
 Legends:
   C:c: participant=Clone::clone
   CP:c: participant=Clone::PP::clone
   DC:c: participant=Data::Clone::clone
   S:d: participant=Storable::dclone
   SD:d: participant=Sereal::Dclone::dclone

The above result presented as chart:

=begin html

<img src="data:image/png;base64,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" />

=end html


=head2 Sample benchmark #3

Benchmark command (benchmarking module startup overhead):

 % bencher -m CloneModules --module-startup

Result formatted as table:

 #table3#
 +---------------------+-----------+-------------------+-----------------------+-----------------------+-----------+---------+
 | participant         | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors   | samples |
 +---------------------+-----------+-------------------+-----------------------+-----------------------+-----------+---------+
 | Storable            |      10   |               6   |                 0.00% |               215.06% |   0.00034 |      21 |
 | Sereal::Dclone      |      10   |               6   |                 0.43% |               213.70% |   0.00023 |      20 |
 | Clone::PP           |       9   |               5   |                48.96% |               111.50% |   0.00022 |      20 |
 | Clone               |       8.6 |               4.6 |                50.27% |               109.67% |   6e-05   |      22 |
 | Data::Clone         |       7   |               3   |                76.04% |                78.97% |   0.00014 |      20 |
 | perl -e1 (baseline) |       4   |               0   |               215.06% |                 0.00% | 4.6e-05   |      23 |
 +---------------------+-----------+-------------------+-----------------------+-----------------------+-----------+---------+


The above result formatted in L<Benchmark.pm|Benchmark> style:

                          Rate     S   S:D   C:P     C   D:C  perl -e1 (baseline) 
  S                    100.0/s    --    0%   -9%  -14%  -30%                 -60% 
  S:D                  100.0/s    0%    --   -9%  -14%  -30%                 -60% 
  C:P                  111.1/s   11%   11%    --   -4%  -22%                 -55% 
  C                    116.3/s   16%   16%    4%    --  -18%                 -53% 
  D:C                  142.9/s   42%   42%   28%   22%    --                 -42% 
  perl -e1 (baseline)  250.0/s  150%  150%  125%  114%   75%                   -- 
 
 Legends:
   C: mod_overhead_time=4.6 participant=Clone
   C:P: mod_overhead_time=5 participant=Clone::PP
   D:C: mod_overhead_time=3 participant=Data::Clone
   S: mod_overhead_time=6 participant=Storable
   S:D: mod_overhead_time=6 participant=Sereal::Dclone
   perl -e1 (baseline): mod_overhead_time=0 participant=perl -e1 (baseline)

The above result presented as chart:

=begin html

<img src="data:image/png;base64,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" />

=end html


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-CloneModules>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-CloneModules>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-CloneModules>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2017, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
