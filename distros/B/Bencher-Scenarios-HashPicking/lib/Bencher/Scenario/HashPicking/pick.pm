package Bencher::Scenario::HashPicking::pick;

our $DATE = '2019-10-20'; # DATE
our $VERSION = '0.003'; # VERSION

use 5.020000; # for hash slice support
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark hash picking',
    participants => [
        {
            module => 'Hash::Util::Pick',
            function => 'pick',
            code_template => 'state $hash = <hash>; state $keys = <keys>; Hash::Util::Pick::pick($hash, @$keys)',
        },
        {
            module => 'Hash::Subset',
            function => 'hashref_subset',
            code_template => 'state $hash = <hash>; state $keys = <keys>; Hash::Subset::hashref_subset($hash, $keys)',
        },
        {
            module => 'Hash::Subset',
            function => 'hash_subset',
            code_template => 'state $hash = <hash>; state $keys = <keys>; +{ Hash::Subset::hash_subset($hash, $keys) }',
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
            name => 'hash slice',
            description => <<'_',

This particular participant is not entirely equivalent to the others: it creates
all wanted keys, regardless of whether the keys exist in the original hash. When
a key does not exist in the original hash, it will be set with the value of
`undef`.

_
            code_template => 'state $hash = <hash>; { %{$hash}{@{<keys>}} }',
        },
        {
            name => 'hash slice+exists',
            code_template => 'state $hash = <hash>; { %{$hash}{grep { exists $hash->{$_} } @{<keys>}} }',
        },
    ],

    datasets => [
        {
            name => 'keys=2, pick=2, exists=1',
            args => { hash=>{1=>1, 2=>1}, keys=>[1, 3] },
        },

        {
            name => 'keys=10, pick=2, exists=1',
            args => { hash=>{map {$_=>1} 1..10}, keys=>[1, 11] },
        },
        {
            name => 'keys=10, pick=10, exists=5',
            args => { hash=>{map {$_=>1} 1..10}, keys=>[1..5, 11..15] },
        },

        {
            name => 'keys=100, pick=2, exists=1',
            args => { hash=>{map {$_=>1} 1..100}, keys=>[1, 101] },
        },
        {
            name => 'keys=100, pick=10, exists=5',
            args => { hash=>{map {$_=>1} 1..100}, keys=>[1..5, 101..105] },
        },
        {
            name => 'keys=100, pick=100, exists=50',
            args => { hash=>{map {$_=>1} 1..100}, keys=>[1..50, 101..150] },
        },

        {
            name => 'keys=1000, pick=2, exists=1',
            args => { hash=>{map {$_=>1} 1..1000}, keys=>[1, 1001] },
        },
        {
            name => 'keys=1000, pick=10, exists=5',
            args => { hash=>{map {$_=>1} 1..1000}, keys=>[1..5, 1001..1005] },
        },
        {
            name => 'keys=1000, pick=100, exists=50',
            args => { hash=>{map {$_=>1} 1..1000}, keys=>[1..50, 1001..1050] },
        },
        {
            name => 'keys=1000, pick=1000, exists=500',
            args => { hash=>{map {$_=>1} 1..1000}, keys=>[1..500, 1001..1500] },
        },

        {
            name => 'keys=10000, pick=2, exists=1',
            args => { hash=>{map {$_=>1} 1..10000}, keys=>[1,10001] },
        },
        {
            name => 'keys=10000, pick=10, exists=5',
            args => { hash=>{map {$_=>1} 1..10000}, keys=>[1..5,10001..10005] },
        },
        {
            name => 'keys=10000, pick=100, exists=50',
            args => { hash=>{map {$_=>1} 1..10000}, keys=>[1..50,10001..10050] },
        },

        {
            name => 'keys=100000, pick=2, exists=1',
            args => { hash=>{map {$_=>1} 1..100000}, keys=>[1,100001] },
        },
    ],
};

1;
# ABSTRACT: Benchmark hash picking

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::HashPicking::pick - Benchmark hash picking

=head1 VERSION

This document describes version 0.003 of Bencher::Scenario::HashPicking::pick (from Perl distribution Bencher-Scenarios-HashPicking), released on 2019-10-20.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m HashPicking::pick

To run module startup overhead benchmark:

 % bencher --module-startup -m HashPicking::pick

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Hash::Util::Pick> 0.06

L<Hash::Subset> 0.003

=head1 BENCHMARK PARTICIPANTS

=over

=item * Hash::Util::Pick::pick (perl_code)

Code template:

 state $hash = <hash>; state $keys = <keys>; Hash::Util::Pick::pick($hash, @$keys)



=item * Hash::Subset::hashref_subset (perl_code)

Code template:

 state $hash = <hash>; state $keys = <keys>; Hash::Subset::hashref_subset($hash, $keys)



=item * Hash::Subset::hash_subset (perl_code)

Code template:

 state $hash = <hash>; state $keys = <keys>; +{ Hash::Subset::hash_subset($hash, $keys) }



=item * map (perl_code)

Code template:

 state $hash = <hash>; state $keys = <keys>; +{ map { (exists $hash->{$_} ? ($_ => $hash->{$_}) : ()) } @$keys}



=item * map+grep (perl_code)

Code template:

 state $hash = <hash>; state $keys = <keys>; +{ map {$_ => $hash->{$_}} grep { exists $hash->{$_} } @$keys}



=item * hash slice (perl_code)

Code template:

 state $hash = <hash>; { %{$hash}{@{<keys>}} }



=item * hash slice+exists (perl_code)

Code template:

 state $hash = <hash>; { %{$hash}{grep { exists $hash->{$_} } @{<keys>}} }



=back

=head1 BENCHMARK DATASETS

=over

=item * keys=2, pick=2, exists=1

=item * keys=10, pick=2, exists=1

=item * keys=10, pick=10, exists=5

=item * keys=100, pick=2, exists=1

=item * keys=100, pick=10, exists=5

=item * keys=100, pick=100, exists=50

=item * keys=1000, pick=2, exists=1

=item * keys=1000, pick=10, exists=5

=item * keys=1000, pick=100, exists=50

=item * keys=1000, pick=1000, exists=500

=item * keys=10000, pick=2, exists=1

=item * keys=10000, pick=10, exists=5

=item * keys=10000, pick=100, exists=50

=item * keys=100000, pick=2, exists=1

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) i7-4770 CPU @ 3.40GHz (4 cores) >>, OS: I<< GNU/Linux LinuxMint version 18.2 >>, OS kernel: I<< Linux version 4.8.0-53-generic >>.

Benchmark with default options (C<< bencher -m HashPicking::pick >>):

 #table1#
 {dataset=>"keys=10, pick=10, exists=5"}
 +------------------------------+-----------+-----------+------------+---------+---------+
 | participant                  | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +------------------------------+-----------+-----------+------------+---------+---------+
 | Hash::Subset::hash_subset    |    351790 |   2.8426  |     1      | 1.7e-11 |      20 |
 | map+grep                     |    552280 |   1.8107  |     1.5699 | 5.3e-12 |      20 |
 | map                          |    591000 |   1.69    |     1.68   | 7.5e-10 |      25 |
 | hash slice+exists            |    621300 |   1.609   |     1.766  | 1.7e-11 |      20 |
 | Hash::Subset::hashref_subset |    690000 |   1.4     |     2      | 1.7e-09 |      20 |
 | hash slice                   |    862590 |   1.1593  |     2.452  | 5.8e-12 |      24 |
 | Hash::Util::Pick::pick       |   1745900 |   0.57277 |     4.9629 |   0     |      28 |
 +------------------------------+-----------+-----------+------------+---------+---------+

 #table2#
 {dataset=>"keys=10, pick=2, exists=1"}
 +------------------------------+-----------+-----------+------------+---------+---------+
 | participant                  | rate (/s) | time (ns) | vs_slowest |  errors | samples |
 +------------------------------+-----------+-----------+------------+---------+---------+
 | Hash::Subset::hash_subset    |    686000 |    1460   |      1     | 3.9e-10 |      23 |
 | Hash::Subset::hashref_subset |   1700000 |     588   |      2.48  | 5.2e-10 |      29 |
 | map+grep                     |   1800000 |     540   |      2.7   | 8.3e-10 |      20 |
 | map                          |   2000000 |     490   |      3     | 8.3e-10 |      20 |
 | hash slice+exists            |   2060000 |     486   |      3     |   2e-10 |      22 |
 | hash slice                   |   2815000 |     355.3 |      4.101 | 5.5e-12 |      20 |
 | Hash::Util::Pick::pick       |   4100000 |     240   |      6     | 4.2e-10 |      20 |
 +------------------------------+-----------+-----------+------------+---------+---------+

 #table3#
 {dataset=>"keys=100, pick=10, exists=5"}
 +------------------------------+-----------+-----------+------------+---------+---------+
 | participant                  | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +------------------------------+-----------+-----------+------------+---------+---------+
 | Hash::Subset::hash_subset    |    350000 |    2.9    |     1      | 3.3e-09 |      20 |
 | map+grep                     |    547410 |    1.8268 |     1.5665 | 1.7e-11 |      20 |
 | map                          |    589000 |    1.7    |     1.69   | 7.9e-10 |      22 |
 | hash slice+exists            |    603740 |    1.6563 |     1.7277 | 4.8e-12 |      20 |
 | Hash::Subset::hashref_subset |    690000 |    1.5    |     2      | 1.7e-09 |      20 |
 | hash slice                   |    835000 |    1.2    |     2.39   | 3.3e-10 |      33 |
 | Hash::Util::Pick::pick       |   1700000 |    0.58   |     4.9    |   1e-09 |      20 |
 +------------------------------+-----------+-----------+------------+---------+---------+

 #table4#
 {dataset=>"keys=100, pick=100, exists=50"}
 +------------------------------+-----------+-----------+------------+---------+---------+
 | participant                  | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +------------------------------+-----------+-----------+------------+---------+---------+
 | Hash::Subset::hash_subset    |   53000   |   19      |    1       |   2e-08 |      20 |
 | map+grep                     |   62070.2 |   16.1108 |    1.16952 | 5.7e-12 |      30 |
 | map                          |   62100   |   16.1    |    1.17    |   6e-09 |      25 |
 | hash slice+exists            |   68000   |   15      |    1.3     | 4.8e-08 |      25 |
 | Hash::Subset::hashref_subset |   82200   |   12.2    |    1.55    | 3.1e-09 |      23 |
 | hash slice                   |   97000   |   10      |    1.8     | 1.3e-08 |      20 |
 | Hash::Util::Pick::pick       |  170000   |    6      |    3.2     | 6.7e-09 |      20 |
 +------------------------------+-----------+-----------+------------+---------+---------+

 #table5#
 {dataset=>"keys=100, pick=2, exists=1"}
 +------------------------------+-----------+-----------+------------+---------+---------+
 | participant                  | rate (/s) | time (ns) | vs_slowest |  errors | samples |
 +------------------------------+-----------+-----------+------------+---------+---------+
 | Hash::Subset::hash_subset    |    683000 |    1460   |      1     | 4.1e-10 |      21 |
 | Hash::Subset::hashref_subset |   1680000 |     596   |      2.46  | 1.8e-10 |      27 |
 | map+grep                     |   1843000 |     542.6 |      2.698 | 5.8e-12 |      20 |
 | map                          |   2040000 |     491   |      2.98  | 5.2e-11 |      20 |
 | hash slice+exists            |   2048000 |     488.3 |      2.998 | 4.9e-12 |      20 |
 | hash slice                   |   2740000 |     365   |      4.01  | 5.8e-11 |      20 |
 | Hash::Util::Pick::pick       |   4050000 |     247   |      5.93  | 1.2e-10 |      20 |
 +------------------------------+-----------+-----------+------------+---------+---------+

 #table6#
 {dataset=>"keys=1000, pick=10, exists=5"}
 +------------------------------+-----------+-----------+------------+---------+---------+
 | participant                  | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +------------------------------+-----------+-----------+------------+---------+---------+
 | Hash::Subset::hash_subset    |    345000 |    2.9    |     1      | 8.3e-10 |      20 |
 | map+grep                     |    540000 |    1.9    |     1.6    | 6.7e-09 |      20 |
 | map                          |    556700 |    1.796  |     1.614  | 2.7e-11 |      20 |
 | hash slice+exists            |    570930 |    1.7515 |     1.6551 |   5e-12 |      20 |
 | Hash::Subset::hashref_subset |    664000 |    1.51   |     1.93   | 1.2e-09 |      20 |
 | hash slice                   |    785800 |    1.273  |     2.278  | 2.6e-11 |      20 |
 | Hash::Util::Pick::pick       |   1600000 |    0.63   |     4.6    | 1.9e-09 |      20 |
 +------------------------------+-----------+-----------+------------+---------+---------+

 #table7#
 {dataset=>"keys=1000, pick=100, exists=50"}
 +------------------------------+-----------+-----------+------------+---------+---------+
 | participant                  | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +------------------------------+-----------+-----------+------------+---------+---------+
 | Hash::Subset::hash_subset    |   48000   |   21      |    1       | 3.3e-08 |      20 |
 | map+grep                     |   55900   |   17.9    |    1.17    | 5.2e-09 |      33 |
 | map                          |   59591   |   16.781  |    1.2519  | 4.6e-11 |      25 |
 | hash slice+exists            |   64729.5 |   15.4489 |    1.35987 | 5.8e-12 |      20 |
 | Hash::Subset::hashref_subset |   78900   |   12.7    |    1.66    | 6.7e-09 |      20 |
 | hash slice                   |   89000   |   11      |    1.9     | 1.3e-08 |      20 |
 | Hash::Util::Pick::pick       |  160000   |    6.4    |    3.3     | 1.3e-08 |      20 |
 +------------------------------+-----------+-----------+------------+---------+---------+

 #table8#
 {dataset=>"keys=1000, pick=1000, exists=500"}
 +------------------------------+-----------+-----------+------------+---------+---------+
 | participant                  | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +------------------------------+-----------+-----------+------------+---------+---------+
 | Hash::Subset::hash_subset    |      4900 |       200 |       1    | 2.1e-07 |      20 |
 | map+grep                     |      5060 |       198 |       1.04 | 5.3e-08 |      20 |
 | map                          |      5410 |       185 |       1.11 | 1.6e-07 |      20 |
 | hash slice+exists            |      5740 |       174 |       1.17 | 5.3e-08 |      20 |
 | Hash::Subset::hashref_subset |      6900 |       150 |       1.4  | 2.1e-07 |      20 |
 | hash slice                   |      7890 |       127 |       1.61 | 5.3e-08 |      20 |
 | Hash::Util::Pick::pick       |     10000 |       100 |       2    | 1.4e-06 |      20 |
 +------------------------------+-----------+-----------+------------+---------+---------+

 #table9#
 {dataset=>"keys=1000, pick=2, exists=1"}
 +------------------------------+-----------+-----------+------------+---------+---------+
 | participant                  | rate (/s) | time (ns) | vs_slowest |  errors | samples |
 +------------------------------+-----------+-----------+------------+---------+---------+
 | Hash::Subset::hash_subset    |    680000 |   1500    |     1      | 1.7e-09 |      20 |
 | Hash::Subset::hashref_subset |   1700000 |    590    |     2.5    | 8.3e-10 |      20 |
 | map+grep                     |   1800000 |    550    |     2.7    | 6.1e-10 |      21 |
 | map                          |   2020000 |    494    |     2.98   | 1.8e-10 |      26 |
 | hash slice+exists            |   2031600 |    492.22 |     2.9883 | 4.7e-12 |      20 |
 | hash slice                   |   2697000 |    370.8  |     3.967  | 1.7e-11 |      21 |
 | Hash::Util::Pick::pick       |   4000000 |    250    |     5.9    |   3e-10 |      21 |
 +------------------------------+-----------+-----------+------------+---------+---------+

 #table10#
 {dataset=>"keys=10000, pick=10, exists=5"}
 +------------------------------+-----------+-----------+------------+---------+---------+
 | participant                  | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +------------------------------+-----------+-----------+------------+---------+---------+
 | Hash::Subset::hash_subset    |    346000 |    2.89   |    1       | 8.3e-10 |      20 |
 | map+grep                     |    519910 |    1.9234 |    1.5008  | 5.2e-12 |      20 |
 | map                          |    555700 |    1.8    |    1.604   | 2.6e-11 |      20 |
 | hash slice+exists            |    605070 |    1.6527 |    1.74666 |   0     |      20 |
 | Hash::Subset::hashref_subset |    690000 |    1.4    |    2       | 1.7e-09 |      20 |
 | hash slice                   |    830000 |    1.2    |    2.4     | 1.4e-09 |      27 |
 | Hash::Util::Pick::pick       |   1600000 |    0.61   |    4.7     | 8.3e-10 |      20 |
 +------------------------------+-----------+-----------+------------+---------+---------+

 #table11#
 {dataset=>"keys=10000, pick=100, exists=50"}
 +------------------------------+-----------+-----------+------------+---------+---------+
 | participant                  | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +------------------------------+-----------+-----------+------------+---------+---------+
 | Hash::Subset::hash_subset    |     51000 |      19   |       1    | 2.7e-08 |      20 |
 | map+grep                     |     55100 |      18.2 |       1.07 | 6.1e-09 |      24 |
 | map                          |     60000 |      17   |       1.2  |   2e-08 |      21 |
 | hash slice+exists            |     66200 |      15.1 |       1.29 | 6.4e-09 |      22 |
 | Hash::Subset::hashref_subset |     78000 |      13   |       1.5  | 2.7e-08 |      20 |
 | hash slice                   |     88000 |      11   |       1.7  | 1.7e-08 |      20 |
 | Hash::Util::Pick::pick       |    150000 |       6.5 |       3    | 1.3e-08 |      20 |
 +------------------------------+-----------+-----------+------------+---------+---------+

 #table12#
 {dataset=>"keys=10000, pick=2, exists=1"}
 +------------------------------+-----------+-----------+------------+---------+---------+
 | participant                  | rate (/s) | time (ns) | vs_slowest |  errors | samples |
 +------------------------------+-----------+-----------+------------+---------+---------+
 | Hash::Subset::hash_subset    |    680000 |   1500    |     1      | 1.7e-09 |      20 |
 | Hash::Subset::hashref_subset |   1694500 |    590.13 |     2.4855 | 5.8e-12 |      20 |
 | map+grep                     |   1778000 |    562.4  |     2.608  | 5.8e-12 |      20 |
 | map                          |   2030000 |    493    |     2.97   | 2.1e-10 |      20 |
 | hash slice+exists            |   2040000 |    490    |     2.99   | 2.1e-10 |      28 |
 | hash slice                   |   2705000 |    369.6  |     3.968  | 2.9e-11 |      20 |
 | Hash::Util::Pick::pick       |   4100000 |    250    |     6      | 4.2e-10 |      20 |
 +------------------------------+-----------+-----------+------------+---------+---------+

 #table13#
 {dataset=>"keys=100000, pick=2, exists=1"}
 +------------------------------+-----------+-----------+------------+---------+---------+
 | participant                  | rate (/s) | time (ns) | vs_slowest |  errors | samples |
 +------------------------------+-----------+-----------+------------+---------+---------+
 | Hash::Subset::hash_subset    |    680000 |    1500   |      1     | 1.7e-09 |      20 |
 | Hash::Subset::hashref_subset |   1690000 |     592   |      2.48  | 1.9e-10 |      23 |
 | map+grep                     |   1800000 |     560   |      2.6   | 8.3e-10 |      20 |
 | map                          |   2000000 |     490   |      3     | 8.3e-10 |      20 |
 | hash slice+exists            |   2070000 |     483   |      3.04  | 2.1e-10 |      20 |
 | hash slice                   |   2586000 |     386.7 |      3.801 | 5.8e-12 |      20 |
 | Hash::Util::Pick::pick       |   3900000 |     250   |      5.8   | 4.2e-10 |      20 |
 +------------------------------+-----------+-----------+------------+---------+---------+

 #table14#
 {dataset=>"keys=2, pick=2, exists=1"}
 +------------------------------+-----------+-----------+------------+---------+---------+
 | participant                  | rate (/s) | time (ns) | vs_slowest |  errors | samples |
 +------------------------------+-----------+-----------+------------+---------+---------+
 | Hash::Subset::hash_subset    |    690000 |   1500    |     1      | 1.7e-09 |      20 |
 | Hash::Subset::hashref_subset |   1706300 |    586.07 |     2.4875 | 4.7e-12 |      20 |
 | map+grep                     |   1830000 |    546.4  |     2.668  | 5.1e-11 |      20 |
 | hash slice+exists            |   2000000 |    500    |     2.9    | 8.3e-10 |      20 |
 | map                          |   2030000 |    492    |     2.97   |   2e-10 |      23 |
 | hash slice                   |   2844000 |    351.6  |     4.146  | 5.7e-12 |      20 |
 | Hash::Util::Pick::pick       |   4100000 |    240    |     6      | 4.2e-10 |      20 |
 +------------------------------+-----------+-----------+------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m HashPicking::pick --module-startup >>):

 #table15#
 +---------------------+-----------+------------------------+------------+---------+---------+
 | participant         | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +---------------------+-----------+------------------------+------------+---------+---------+
 | Hash::Subset        |      11   |                    1.8 |        1   | 3.2e-05 |      20 |
 | Hash::Util::Pick    |      11   |                    1.8 |        1   | 2.1e-05 |      20 |
 | perl -e1 (baseline) |       9.2 |                    0   |        1.3 | 2.4e-05 |      20 |
 +---------------------+-----------+------------------------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-HashPicking>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-HashPicking>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-HashPicking>

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
