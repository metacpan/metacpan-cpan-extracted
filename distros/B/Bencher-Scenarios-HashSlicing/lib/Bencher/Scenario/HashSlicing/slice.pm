package Bencher::Scenario::HashSlicing::slice;

our $DATE = '2020-04-19'; # DATE
our $VERSION = '0.005'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark hash slicing',
    participants => [
        {
            module => 'Hash::Util::Pick',
            function => 'pick',
            code_template => 'state $hash = <hash>; state $keys = <keys>; Hash::Util::Pick::pick($hash, @$keys)',
        },
        {
            name => 'map',
            code_template => 'state $hash = <hash>; state $keys = <keys>; +{ map { (exists $hash->{$_} ? ($_ => $hash->{$_}) : ()) } @$keys}',
        },
        {
            name => 'map+grep',
            code_template => 'state $hash = <hash>; state $keys = <keys>; +{ map {$_ => $hash->{$_}} grep { exists $hash->{$_} } @$keys}',
        },
        {
            module => 'Hash::Subset',
            function => 'hashref_subset',
            code_template => 'state $hash = <hash>; state $keys = <keys>; Hash::Subset::hashref_subset($hash, $keys)',
        },
        {
            module => 'Hash::MoreUtils',
            function => 'slice_exists',
            code_template => 'state $hash = <hash>; state $keys = <keys>; my %h = Hash::MoreUtils::slice_exists($hash, @$keys); \%h',
        },
    ],

    datasets => [
        {
            name => 'keys=2, slice=2, exists=1',
            args => { hash=>{1=>1, 2=>1}, keys=>[1, 3] },
        },

        {
            name => 'keys=10, slice=2, exists=1',
            args => { hash=>{map {$_=>1} 1..10}, keys=>[1, 11] },
        },
        {
            name => 'keys=10, slice=10, exists=5',
            args => { hash=>{map {$_=>1} 1..10}, keys=>[1..5, 11..15] },
        },

        {
            name => 'keys=100, slice=2, exists=1',
            args => { hash=>{map {$_=>1} 1..100}, keys=>[1, 101] },
        },
        {
            name => 'keys=100, slice=10, exists=5',
            args => { hash=>{map {$_=>1} 1..100}, keys=>[1..5, 101..105] },
        },
        {
            name => 'keys=100, slice=100, exists=50',
            args => { hash=>{map {$_=>1} 1..100}, keys=>[1..50, 101..150] },
        },

        {
            name => 'keys=1000, slice=2, exists=1',
            args => { hash=>{map {$_=>1} 1..1000}, keys=>[1, 1001] },
        },
        {
            name => 'keys=1000, slice=10, exists=5',
            args => { hash=>{map {$_=>1} 1..1000}, keys=>[1..5, 1001..1005] },
        },
        {
            name => 'keys=1000, slice=100, exists=50',
            args => { hash=>{map {$_=>1} 1..1000}, keys=>[1..50, 1001..1050] },
        },
        {
            name => 'keys=1000, slice=1000, exists=500',
            args => { hash=>{map {$_=>1} 1..1000}, keys=>[1..500, 1001..1500] },
        },

        {
            name => 'keys=10000, slice=2, exists=1',
            args => { hash=>{map {$_=>1} 1..10000}, keys=>[1,10001] },
        },
        {
            name => 'keys=10000, slice=10, exists=5',
            args => { hash=>{map {$_=>1} 1..10000}, keys=>[1..5,10001..10005] },
        },
        {
            name => 'keys=10000, slice=100, exists=50',
            args => { hash=>{map {$_=>1} 1..10000}, keys=>[1..50,10001..10050] },
        },

        {
            name => 'keys=100000, slice=2, exists=1',
            args => { hash=>{map {$_=>1} 1..100000}, keys=>[1,100001] },
        },
    ],
};

1;
# ABSTRACT: Benchmark hash slicing

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::HashSlicing::slice - Benchmark hash slicing

=head1 VERSION

This document describes version 0.005 of Bencher::Scenario::HashSlicing::slice (from Perl distribution Bencher-Scenarios-HashSlicing), released on 2020-04-19.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m HashSlicing::slice

To run module startup overhead benchmark:

 % bencher --module-startup -m HashSlicing::slice

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Hash::Util::Pick> 0.13

L<Hash::Subset> 0.005

L<Hash::MoreUtils> 0.06

=head1 BENCHMARK PARTICIPANTS

=over

=item * Hash::Util::Pick::pick (perl_code)

Code template:

 state $hash = <hash>; state $keys = <keys>; Hash::Util::Pick::pick($hash, @$keys)



=item * map (perl_code)

Code template:

 state $hash = <hash>; state $keys = <keys>; +{ map { (exists $hash->{$_} ? ($_ => $hash->{$_}) : ()) } @$keys}



=item * map+grep (perl_code)

Code template:

 state $hash = <hash>; state $keys = <keys>; +{ map {$_ => $hash->{$_}} grep { exists $hash->{$_} } @$keys}



=item * Hash::Subset::hashref_subset (perl_code)

Code template:

 state $hash = <hash>; state $keys = <keys>; Hash::Subset::hashref_subset($hash, $keys)



=item * Hash::MoreUtils::slice_exists (perl_code)

Code template:

 state $hash = <hash>; state $keys = <keys>; my %h = Hash::MoreUtils::slice_exists($hash, @$keys); \%h



=back

=head1 BENCHMARK DATASETS

=over

=item * keys=2, slice=2, exists=1

=item * keys=10, slice=2, exists=1

=item * keys=10, slice=10, exists=5

=item * keys=100, slice=2, exists=1

=item * keys=100, slice=10, exists=5

=item * keys=100, slice=100, exists=50

=item * keys=1000, slice=2, exists=1

=item * keys=1000, slice=10, exists=5

=item * keys=1000, slice=100, exists=50

=item * keys=1000, slice=1000, exists=500

=item * keys=10000, slice=2, exists=1

=item * keys=10000, slice=10, exists=5

=item * keys=10000, slice=100, exists=50

=item * keys=100000, slice=2, exists=1

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.30.2 >>, CPU: I<< Intel(R) Core(TM) i7-4770 CPU @ 3.40GHz (4 cores) >>, OS: I<< GNU/Linux LinuxMint version 19 >>, OS kernel: I<< Linux version 4.15.0-91-generic >>.

Benchmark with default options (C<< bencher -m HashSlicing::slice >>):

 #table1#
 {dataset=>"keys=10, slice=10, exists=5"}
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                   | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | Hash::MoreUtils::slice_exists |    360000 |    2.78   |                 0.00% |               425.30% | 6.4e-10 |      34 |
 | Hash::Subset::hashref_subset  |    564700 |    1.771  |                56.92% |               234.76% | 2.6e-11 |      21 |
 | map+grep                      |    571000 |    1.75   |                58.74% |               230.92% | 8.4e-10 |      20 |
 | map                           |    596010 |    1.6778 |                65.62% |               217.17% | 5.8e-12 |      20 |
 | Hash::Util::Pick::pick        |   1900000 |    0.53   |               425.30% |                 0.00% | 8.3e-10 |      20 |
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

 #table2#
 {dataset=>"keys=10, slice=2, exists=1"}
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                   | rate (/s) | time (ns) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | Hash::Subset::hashref_subset  |   1100000 |       930 |                 0.00% |               301.52% | 1.5e-09 |      25 |
 | Hash::MoreUtils::slice_exists |   1100000 |       880 |                 5.45% |               280.77% | 1.7e-09 |      20 |
 | map+grep                      |   1930000 |       517 |                79.17% |               124.10% | 2.5e-10 |      20 |
 | map                           |   2150000 |       465 |                99.34% |               101.43% | 1.9e-10 |      24 |
 | Hash::Util::Pick::pick        |   4300000 |       230 |               301.52% |                 0.00% | 4.3e-10 |      20 |
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

 #table3#
 {dataset=>"keys=100, slice=10, exists=5"}
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                   | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | Hash::MoreUtils::slice_exists |    363000 |    2.75   |                 0.00% |               394.10% | 8.3e-10 |      20 |
 | Hash::Subset::hashref_subset  |    560000 |    1.8    |                54.58% |               219.64% | 2.2e-09 |      27 |
 | map+grep                      |    568000 |    1.76   |                56.29% |               216.15% | 8.9e-10 |      20 |
 | map                           |    600790 |    1.6645 |                65.43% |               198.68% | 5.8e-12 |      22 |
 | Hash::Util::Pick::pick        |   1800000 |    0.56   |               394.10% |                 0.00% | 3.5e-09 |      20 |
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

 #table4#
 {dataset=>"keys=100, slice=100, exists=50"}
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                   | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | Hash::MoreUtils::slice_exists |   35748.8 |    27.973 |                 0.00% |               421.53% | 1.7e-11 |      20 |
 | map+grep                      |   62674   |    15.956 |                75.32% |               197.48% | 1.4e-10 |      20 |
 | map                           |   64500   |    15.5   |                80.53% |               188.89% | 5.5e-09 |      29 |
 | Hash::Subset::hashref_subset  |   84400   |    11.9   |               136.02% |               120.97% | 3.2e-09 |      22 |
 | Hash::Util::Pick::pick        |  190000   |     5.4   |               421.53% |                 0.00% | 6.5e-09 |      21 |
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

 #table5#
 {dataset=>"keys=100, slice=2, exists=1"}
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                   | rate (/s) | time (ns) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | Hash::Subset::hashref_subset  |   1080000 |     926   |                 0.00% |               309.68% | 3.5e-10 |      29 |
 | Hash::MoreUtils::slice_exists |   1156000 |     865.2 |                 7.08% |               282.58% | 1.7e-11 |      20 |
 | map+grep                      |   1920000 |     520   |                78.30% |               129.78% |   2e-10 |      23 |
 | map                           |   2120000 |     471   |                96.78% |               108.19% |   2e-10 |      21 |
 | Hash::Util::Pick::pick        |   4400000 |     230   |               309.68% |                 0.00% | 2.8e-10 |      22 |
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

 #table6#
 {dataset=>"keys=1000, slice=10, exists=5"}
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                   | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | Hash::MoreUtils::slice_exists |    354730 |    2.8191 |                 0.00% |               405.16% | 5.7e-12 |      20 |
 | Hash::Subset::hashref_subset  |    554700 |    1.803  |                56.37% |               223.06% | 2.3e-11 |      20 |
 | map+grep                      |    566000 |    1.77   |                59.54% |               216.63% | 1.2e-09 |      20 |
 | map                           |    601900 |    1.661  |                69.69% |               197.69% | 2.3e-11 |      20 |
 | Hash::Util::Pick::pick        |   1800000 |    0.56   |               405.16% |                 0.00% |   1e-09 |      20 |
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

 #table7#
 {dataset=>"keys=1000, slice=100, exists=50"}
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                   | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | Hash::MoreUtils::slice_exists |   35567.4 |   28.1157 |                 0.00% |               402.20% | 5.8e-12 |      28 |
 | map+grep                      |   61000   |   16      |                70.40% |               194.72% | 2.4e-08 |      24 |
 | map                           |   63400   |   15.8    |                78.26% |               181.72% | 6.7e-09 |      20 |
 | Hash::Subset::hashref_subset  |   81694   |   12.241  |               129.69% |               118.65% | 1.7e-11 |      22 |
 | Hash::Util::Pick::pick        |  180000   |    5.6    |               402.20% |                 0.00% | 8.3e-09 |      20 |
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

 #table8#
 {dataset=>"keys=1000, slice=1000, exists=500"}
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                   | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | Hash::MoreUtils::slice_exists |      3460 |       289 |                 0.00% |               276.88% |   2e-07 |      22 |
 | map+grep                      |      5400 |       180 |                57.24% |               139.68% | 2.1e-07 |      20 |
 | map                           |      5600 |       180 |                63.20% |               130.93% | 6.2e-07 |      21 |
 | Hash::Subset::hashref_subset  |      7700 |       130 |               122.44% |                69.43% | 2.7e-07 |      20 |
 | Hash::Util::Pick::pick        |     13000 |        77 |               276.88% |                 0.00% | 2.1e-07 |      20 |
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

 #table9#
 {dataset=>"keys=1000, slice=2, exists=1"}
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                   | rate (/s) | time (ns) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | Hash::Subset::hashref_subset  |   1060000 |     940   |                 0.00% |               293.79% | 4.2e-10 |      20 |
 | Hash::MoreUtils::slice_exists |   1156000 |     865.4 |                 8.65% |               262.45% | 1.7e-11 |      20 |
 | map+grep                      |   1920000 |     522   |                80.17% |               118.56% | 2.1e-10 |      20 |
 | map                           |   2100000 |     470   |               100.76% |                96.15% | 6.2e-10 |      21 |
 | Hash::Util::Pick::pick        |   4200000 |     240   |               293.79% |                 0.00% | 4.2e-10 |      20 |
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

 #table10#
 {dataset=>"keys=10000, slice=10, exists=5"}
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                   | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | Hash::MoreUtils::slice_exists |    350000 |    2.8    |                 0.00% |               405.48% |   3e-09 |      25 |
 | Hash::Subset::hashref_subset  |    550130 |    1.8178 |                56.51% |               222.98% | 1.7e-11 |      20 |
 | map+grep                      |    556600 |    1.797  |                58.34% |               219.23% | 1.2e-10 |      20 |
 | map                           |    590500 |    1.693  |                68.00% |               200.88% | 2.3e-11 |      20 |
 | Hash::Util::Pick::pick        |   1800000 |    0.56   |               405.48% |                 0.00% | 8.3e-10 |      20 |
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

 #table11#
 {dataset=>"keys=10000, slice=100, exists=50"}
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                   | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | Hash::MoreUtils::slice_exists |   38700   |   25.9    |                 0.00% |               323.82% | 1.3e-08 |      21 |
 | map+grep                      |   56807.7 |   17.6033 |                46.94% |               188.42% | 5.8e-12 |      20 |
 | map                           |   61300   |   16.3    |                58.54% |               167.33% | 6.7e-09 |      20 |
 | Hash::Subset::hashref_subset  |   77921.6 |   12.8334 |               101.56% |               110.27% | 5.8e-12 |      20 |
 | Hash::Util::Pick::pick        |  160000   |    6.1    |               323.82% |                 0.00% | 1.3e-08 |      20 |
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

 #table12#
 {dataset=>"keys=10000, slice=2, exists=1"}
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                   | rate (/s) | time (ns) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | Hash::Subset::hashref_subset  |   1070000 |     935   |                 0.00% |               303.97% | 3.6e-10 |      27 |
 | Hash::MoreUtils::slice_exists |   1150000 |     872   |                 7.32% |               276.42% | 4.2e-10 |      20 |
 | map+grep                      |   1849000 |     540.8 |                72.97% |               133.55% | 5.7e-12 |      32 |
 | map                           |   2100000 |     470   |               100.64% |               101.35% | 8.3e-10 |      20 |
 | Hash::Util::Pick::pick        |   4300000 |     230   |               303.97% |                 0.00% | 4.4e-10 |      20 |
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

 #table13#
 {dataset=>"keys=100000, slice=2, exists=1"}
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                   | rate (/s) | time (ns) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | Hash::Subset::hashref_subset  |   1070000 |     932   |                 0.00% |               291.04% | 3.9e-10 |      23 |
 | Hash::MoreUtils::slice_exists |   1147000 |     871.5 |                 6.90% |               265.81% | 2.3e-11 |      23 |
 | map+grep                      |   1904000 |     525.3 |                77.35% |               120.49% | 5.7e-12 |      20 |
 | map                           |   2100000 |     470   |                99.68% |                95.84% | 8.3e-10 |      20 |
 | Hash::Util::Pick::pick        |   4200000 |     240   |               291.04% |                 0.00% | 8.3e-10 |      20 |
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

 #table14#
 {dataset=>"keys=2, slice=2, exists=1"}
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                   | rate (/s) | time (ns) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | Hash::Subset::hashref_subset  |   1100000 |     900   |                 0.00% |               289.43% | 1.2e-09 |      20 |
 | Hash::MoreUtils::slice_exists |   1160000 |     864   |                 4.48% |               272.74% | 4.2e-10 |      21 |
 | map+grep                      |   1904000 |     525.3 |                71.80% |               126.68% | 5.7e-12 |      20 |
 | map                           |   2130000 |     470   |                91.96% |               102.87% | 2.1e-10 |      20 |
 | Hash::Util::Pick::pick        |   4300000 |     230   |               289.43% |                 0.00% | 5.2e-10 |      20 |
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m HashSlicing::slice --module-startup >>):

 #table15#
 +---------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | participant         | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +---------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | Hash::MoreUtils     |        10 |                 0 |                 0.00% |                29.02% | 0.00031 |      21 |
 | Hash::Util::Pick    |        10 |                 0 |                 7.65% |                19.85% | 0.00028 |      20 |
 | Hash::Subset        |        10 |                 0 |                10.15% |                17.13% | 0.00018 |      20 |
 | perl -e1 (baseline) |        10 |                 0 |                29.02% |                 0.00% | 0.00026 |      20 |
 +---------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-HashSlicing>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-HashSlicing>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-HashSlicing>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
