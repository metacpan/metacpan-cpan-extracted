package Bencher::Scenario::HashSlicing::slice;

our $DATE = '2019-11-20'; # DATE
our $VERSION = '0.003'; # VERSION

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

This document describes version 0.003 of Bencher::Scenario::HashSlicing::slice (from Perl distribution Bencher-Scenarios-HashSlicing), released on 2019-11-20.

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

L<Hash::Subset> 0.004

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

Run on: perl: I<< v5.30.0 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 19.04 >>, OS kernel: I<< Linux version 5.0.0-31-generic >>.

Benchmark with default options (C<< bencher -m HashSlicing::slice >>):

 #table1#
 {dataset=>"keys=10, slice=10, exists=5"}
 +-------------------------------+-----------+-----------+------------+---------+---------+
 | participant                   | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +-------------------------------+-----------+-----------+------------+---------+---------+
 | Hash::MoreUtils::slice_exists |    290150 |    3.4465 |      1     | 1.9e-11 |      20 |
 | map+grep                      |    486000 |    2.06   |      1.68  | 8.3e-10 |      20 |
 | map                           |    525100 |    1.905  |      1.81  | 2.2e-11 |      20 |
 | Hash::Subset::hashref_subset  |    551800 |    1.812  |      1.902 | 1.9e-11 |      20 |
 | Hash::Util::Pick::pick        |   1500000 |    0.65   |      5.3   | 1.7e-09 |      20 |
 +-------------------------------+-----------+-----------+------------+---------+---------+

 #table2#
 {dataset=>"keys=10, slice=2, exists=1"}
 +-------------------------------+-----------+-----------+------------+---------+---------+
 | participant                   | rate (/s) | time (ns) | vs_slowest |  errors | samples |
 +-------------------------------+-----------+-----------+------------+---------+---------+
 | Hash::MoreUtils::slice_exists |    919000 |    1090   |      1     | 3.1e-10 |      37 |
 | Hash::Subset::hashref_subset  |   1420000 |     705   |      1.54  | 1.7e-10 |      31 |
 | map+grep                      |   1600000 |     623   |      1.75  | 1.7e-10 |      30 |
 | map                           |   1815000 |     550.9 |      1.976 | 2.1e-11 |      20 |
 | Hash::Util::Pick::pick        |   3500000 |     280   |      3.8   | 8.3e-10 |      20 |
 +-------------------------------+-----------+-----------+------------+---------+---------+

 #table3#
 {dataset=>"keys=100, slice=10, exists=5"}
 +-------------------------------+-----------+-----------+------------+---------+---------+
 | participant                   | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +-------------------------------+-----------+-----------+------------+---------+---------+
 | Hash::MoreUtils::slice_exists |    295980 |    3.3786 |      1     | 1.8e-11 |      26 |
 | map+grep                      |    493000 |    2.03   |      1.67  |   7e-10 |      28 |
 | map                           |    529200 |    1.89   |      1.788 | 3.8e-11 |      20 |
 | Hash::Subset::hashref_subset  |    569000 |    1.76   |      1.92  | 7.9e-10 |      22 |
 | Hash::Util::Pick::pick        |   1000000 |    1      |      3     | 1.6e-08 |      21 |
 +-------------------------------+-----------+-----------+------------+---------+---------+

 #table4#
 {dataset=>"keys=100, slice=100, exists=50"}
 +-------------------------------+-----------+-----------+------------+---------+---------+
 | participant                   | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +-------------------------------+-----------+-----------+------------+---------+---------+
 | Hash::MoreUtils::slice_exists |     34000 |      30   |       1    | 5.3e-08 |      20 |
 | map+grep                      |     55200 |      18.1 |       1.63 | 6.7e-09 |      20 |
 | map                           |     57000 |      18   |       1.7  | 2.7e-08 |      20 |
 | Hash::Subset::hashref_subset  |     73000 |      14   |       2.2  | 5.3e-08 |      20 |
 | Hash::Util::Pick::pick        |    150000 |       6.7 |       4.4  | 2.6e-08 |      21 |
 +-------------------------------+-----------+-----------+------------+---------+---------+

 #table5#
 {dataset=>"keys=100, slice=2, exists=1"}
 +-------------------------------+-----------+-----------+------------+---------+---------+
 | participant                   | rate (/s) | time (ns) | vs_slowest |  errors | samples |
 +-------------------------------+-----------+-----------+------------+---------+---------+
 | Hash::MoreUtils::slice_exists |    919200 |    1088   |      1     | 2.2e-11 |      21 |
 | Hash::Subset::hashref_subset  |   1420000 |     706   |      1.54  | 2.1e-10 |      20 |
 | map+grep                      |   1589000 |     629.3 |      1.729 | 2.2e-11 |      20 |
 | map                           |   1800000 |     560   |      2     | 6.9e-10 |      29 |
 | Hash::Util::Pick::pick        |   3400000 |     290   |      3.7   | 8.3e-10 |      20 |
 +-------------------------------+-----------+-----------+------------+---------+---------+

 #table6#
 {dataset=>"keys=1000, slice=10, exists=5"}
 +-------------------------------+-----------+-----------+------------+---------+---------+
 | participant                   | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +-------------------------------+-----------+-----------+------------+---------+---------+
 | Hash::MoreUtils::slice_exists |    289565 |   3.45345 |      1     |   0     |      20 |
 | map+grep                      |    477100 |   2.096   |      1.648 | 2.3e-11 |      20 |
 | map                           |    510000 |   1.96    |      1.76  | 8.3e-10 |      20 |
 | Hash::Subset::hashref_subset  |    541000 |   1.85    |      1.87  | 7.6e-10 |      24 |
 | Hash::Util::Pick::pick        |   1600000 |   0.64    |      5.4   | 8.3e-10 |      20 |
 +-------------------------------+-----------+-----------+------------+---------+---------+

 #table7#
 {dataset=>"keys=1000, slice=100, exists=50"}
 +-------------------------------+-----------+-----------+------------+---------+---------+
 | participant                   | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +-------------------------------+-----------+-----------+------------+---------+---------+
 | Hash::MoreUtils::slice_exists |     30000 |    33     |     1      | 1.2e-07 |      20 |
 | map+grep                      |     51855 |    19.285 |     1.7137 | 2.2e-11 |      26 |
 | map                           |     54000 |    18.5   |     1.78   | 6.7e-09 |      20 |
 | Hash::Subset::hashref_subset  |     71300 |    14     |     2.36   |   6e-09 |      25 |
 | Hash::Util::Pick::pick        |    140000 |     7     |     4.7    | 1.3e-08 |      20 |
 +-------------------------------+-----------+-----------+------------+---------+---------+

 #table8#
 {dataset=>"keys=1000, slice=1000, exists=500"}
 +-------------------------------+-----------+-----------+------------+---------+---------+
 | participant                   | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +-------------------------------+-----------+-----------+------------+---------+---------+
 | Hash::MoreUtils::slice_exists |      3180 |       315 |       1    | 2.4e-07 |      24 |
 | map+grep                      |      4840 |       207 |       1.52 |   2e-07 |      22 |
 | map                           |      5000 |       200 |       1.6  |   2e-07 |      22 |
 | Hash::Subset::hashref_subset  |      6600 |       150 |       2.1  | 2.1e-07 |      20 |
 | Hash::Util::Pick::pick        |     11000 |        88 |       3.6  |   2e-07 |      22 |
 +-------------------------------+-----------+-----------+------------+---------+---------+

 #table9#
 {dataset=>"keys=1000, slice=2, exists=1"}
 +-------------------------------+-----------+-----------+------------+---------+---------+
 | participant                   | rate (/s) | time (ns) | vs_slowest |  errors | samples |
 +-------------------------------+-----------+-----------+------------+---------+---------+
 | Hash::MoreUtils::slice_exists |    922000 |    1080   |      1     | 3.4e-10 |      30 |
 | Hash::Subset::hashref_subset  |   1420000 |     703   |      1.54  | 2.1e-10 |      20 |
 | map+grep                      |   1621000 |     617.1 |      1.758 | 2.5e-11 |      20 |
 | map                           |   1791000 |     558.5 |      1.943 | 1.9e-11 |      22 |
 | Hash::Util::Pick::pick        |   3500000 |     280   |      3.8   | 9.4e-10 |      20 |
 +-------------------------------+-----------+-----------+------------+---------+---------+

 #table10#
 {dataset=>"keys=10000, slice=10, exists=5"}
 +-------------------------------+-----------+-----------+------------+---------+---------+
 | participant                   | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +-------------------------------+-----------+-----------+------------+---------+---------+
 | Hash::MoreUtils::slice_exists |    289670 |    3.4521 |      1     | 2.4e-11 |      20 |
 | map+grep                      |    300000 |    3      |      1     | 1.4e-07 |      20 |
 | map                           |    497000 |    2.01   |      1.71  | 7.9e-10 |      22 |
 | Hash::Subset::hashref_subset  |    556500 |    1.797  |      1.921 |   2e-11 |      20 |
 | Hash::Util::Pick::pick        |   1500000 |    0.66   |      5.2   | 8.3e-10 |      20 |
 +-------------------------------+-----------+-----------+------------+---------+---------+

 #table11#
 {dataset=>"keys=10000, slice=100, exists=50"}
 +-------------------------------+-----------+-----------+------------+---------+---------+
 | participant                   | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +-------------------------------+-----------+-----------+------------+---------+---------+
 | Hash::MoreUtils::slice_exists |     31900 |      31.3 |       1    | 1.2e-08 |      23 |
 | map+grep                      |     46000 |      22   |       1.4  | 1.5e-07 |      20 |
 | map                           |     52800 |      18.9 |       1.65 | 6.7e-09 |      20 |
 | Hash::Subset::hashref_subset  |     67000 |      15   |       2.1  | 2.7e-08 |      20 |
 | Hash::Util::Pick::pick        |    140000 |       7.3 |       4.3  | 2.7e-08 |      20 |
 +-------------------------------+-----------+-----------+------------+---------+---------+

 #table12#
 {dataset=>"keys=10000, slice=2, exists=1"}
 +-------------------------------+-----------+-----------+------------+---------+---------+
 | participant                   | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +-------------------------------+-----------+-----------+------------+---------+---------+
 | map+grep                      |    500000 |     2     |      1     | 1.5e-08 |      20 |
 | Hash::MoreUtils::slice_exists |    925200 |     1.081 |      1.851 |   2e-11 |      28 |
 | Hash::Subset::hashref_subset  |   1410000 |     0.707 |      2.83  | 1.9e-10 |      26 |
 | map                           |   1800000 |     0.56  |      3.6   | 8.3e-10 |      20 |
 | Hash::Util::Pick::pick        |   3600000 |     0.28  |      7.2   |   4e-10 |      22 |
 +-------------------------------+-----------+-----------+------------+---------+---------+

 #table13#
 {dataset=>"keys=100000, slice=2, exists=1"}
 +-------------------------------+-----------+-----------+------------+---------+---------+
 | participant                   | rate (/s) | time (ns) | vs_slowest |  errors | samples |
 +-------------------------------+-----------+-----------+------------+---------+---------+
 | Hash::MoreUtils::slice_exists |    915300 |    1092   |      1     |   5e-11 |      20 |
 | Hash::Subset::hashref_subset  |   1420000 |     702   |      1.56  | 1.8e-10 |      28 |
 | map+grep                      |   1601000 |     624.7 |      1.749 | 2.3e-11 |      20 |
 | map                           |   1800000 |     556   |      1.96  | 1.7e-10 |      30 |
 | Hash::Util::Pick::pick        |   3600000 |     280   |      3.9   | 4.2e-10 |      20 |
 +-------------------------------+-----------+-----------+------------+---------+---------+

 #table14#
 {dataset=>"keys=2, slice=2, exists=1"}
 +-------------------------------+-----------+-----------+------------+---------+---------+
 | participant                   | rate (/s) | time (ns) | vs_slowest |  errors | samples |
 +-------------------------------+-----------+-----------+------------+---------+---------+
 | Hash::MoreUtils::slice_exists |    939710 |    1064.2 |      1     | 5.8e-12 |      20 |
 | Hash::Subset::hashref_subset  |   1500000 |     665   |      1.6   | 1.8e-10 |      26 |
 | map+grep                      |   1600000 |     620   |      1.7   | 8.3e-10 |      20 |
 | map                           |   1791000 |     558.3 |      1.906 |   2e-11 |      20 |
 | Hash::Util::Pick::pick        |   3500000 |     280   |      3.8   | 1.2e-09 |      23 |
 +-------------------------------+-----------+-----------+------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m HashSlicing::slice --module-startup >>):

 #table15#
 +---------------------+-----------+------------------------+------------+---------+---------+
 | participant         | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +---------------------+-----------+------------------------+------------+---------+---------+
 | Hash::MoreUtils     |      20.5 |                    3.4 |       1    | 1.6e-05 |      20 |
 | Hash::Util::Pick    |      19   |                    1.9 |       1    |   2e-05 |      20 |
 | Hash::Subset        |      19.2 |                    2.1 |       1.07 | 9.4e-06 |      22 |
 | perl -e1 (baseline) |      17.1 |                    0   |       1.19 | 9.1e-06 |      20 |
 +---------------------+-----------+------------------------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-HashSlicing>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-HashPicking>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-HashSlicing>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2017, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
