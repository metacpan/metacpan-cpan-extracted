package Bencher::Scenario::HashPicking::pick;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.002'; # VERSION

use 5.010001;
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
            name => 'map',
            code_template => 'state $hash = <hash>; state $keys = <keys>; +{ map { (exists $hash->{$_} ? ($_ => $hash->{$_}) : ()) } @$keys}',
        },
        {
            name => 'map+grep',
            code_template => 'state $hash = <hash>; state $keys = <keys>; +{ map {$_ => $hash->{$_}} grep { exists $hash->{$_} } @$keys}',
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

This document describes version 0.002 of Bencher::Scenario::HashPicking::pick (from Perl distribution Bencher-Scenarios-HashPicking), released on 2017-01-25.

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

L<Hash::Util::Pick> 0.05

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

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m HashPicking::pick >>):

 #table1#
 {dataset=>"keys=10, pick=10, exists=5"}
 +------------------------+-----------+-----------+------------+---------+---------+
 | participant            | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +------------------------+-----------+-----------+------------+---------+---------+
 | map+grep               |    440000 |      2.3  |        1   | 3.3e-09 |      20 |
 | map                    |    460000 |      2.2  |        1   | 4.2e-09 |      20 |
 | Hash::Util::Pick::pick |   1600000 |      0.64 |        3.5 | 8.4e-10 |      20 |
 +------------------------+-----------+-----------+------------+---------+---------+

 #table2#
 {dataset=>"keys=10, pick=2, exists=1"}
 +------------------------+-----------+-----------+------------+---------+---------+
 | participant            | rate (/s) | time (ns) | vs_slowest |  errors | samples |
 +------------------------+-----------+-----------+------------+---------+---------+
 | map+grep               |   1310000 |   762     |    1       | 3.5e-10 |      30 |
 | map                    |   1662900 |   601.358 |    1.26727 |   0     |      20 |
 | Hash::Util::Pick::pick |   3300000 |   310     |    2.5     | 1.8e-09 |      20 |
 +------------------------+-----------+-----------+------------+---------+---------+

 #table3#
 {dataset=>"keys=100, pick=10, exists=5"}
 +------------------------+-----------+-----------+------------+---------+---------+
 | participant            | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +------------------------+-----------+-----------+------------+---------+---------+
 | map+grep               |    417000 |      2.4  |        1   | 7.9e-10 |      22 |
 | map                    |    430000 |      2.3  |        1   | 6.2e-09 |      29 |
 | Hash::Util::Pick::pick |   1300000 |      0.76 |        3.2 | 3.7e-09 |      20 |
 +------------------------+-----------+-----------+------------+---------+---------+

 #table4#
 {dataset=>"keys=100, pick=100, exists=50"}
 +------------------------+-----------+-----------+------------+---------+---------+
 | participant            | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +------------------------+-----------+-----------+------------+---------+---------+
 | map+grep               |     42000 |      24   |       1    | 2.7e-08 |      20 |
 | map                    |     43700 |      22.9 |       1.04 | 6.7e-09 |      20 |
 | Hash::Util::Pick::pick |    140000 |       7.3 |       3.3  | 1.3e-08 |      20 |
 +------------------------+-----------+-----------+------------+---------+---------+

 #table5#
 {dataset=>"keys=100, pick=2, exists=1"}
 +------------------------+-----------+-----------+------------+---------+---------+
 | participant            | rate (/s) | time (ns) | vs_slowest |  errors | samples |
 +------------------------+-----------+-----------+------------+---------+---------+
 | map+grep               |   1469410 |   680.545 |        1   |   0     |      24 |
 | map                    |   1600000 |   620     |        1.1 | 7.5e-10 |      25 |
 | Hash::Util::Pick::pick |   2900000 |   350     |        1.9 | 6.2e-10 |      20 |
 +------------------------+-----------+-----------+------------+---------+---------+

 #table6#
 {dataset=>"keys=1000, pick=10, exists=5"}
 +------------------------+-----------+-----------+------------+---------+---------+
 | participant            | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +------------------------+-----------+-----------+------------+---------+---------+
 | map+grep               |    393000 |      2.54 |        1   | 2.5e-09 |      20 |
 | map                    |    450000 |      2.2  |        1.1 | 3.3e-09 |      20 |
 | Hash::Util::Pick::pick |   1300000 |      0.75 |        3.4 | 8.3e-10 |      20 |
 +------------------------+-----------+-----------+------------+---------+---------+

 #table7#
 {dataset=>"keys=1000, pick=100, exists=50"}
 +------------------------+-----------+-----------+------------+---------+---------+
 | participant            | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +------------------------+-----------+-----------+------------+---------+---------+
 | map+grep               |     41000 |      24   |        1   |   5e-08 |      23 |
 | map                    |     47000 |      21   |        1.2 | 2.8e-08 |      29 |
 | Hash::Util::Pick::pick |    130000 |       7.6 |        3.2 | 1.3e-08 |      21 |
 +------------------------+-----------+-----------+------------+---------+---------+

 #table8#
 {dataset=>"keys=1000, pick=1000, exists=500"}
 +------------------------+-----------+-----------+------------+---------+---------+
 | participant            | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +------------------------+-----------+-----------+------------+---------+---------+
 | map+grep               |      3740 |       267 |       1    | 2.1e-07 |      20 |
 | map                    |      4420 |       226 |       1.18 | 2.1e-07 |      20 |
 | Hash::Util::Pick::pick |     10000 |        99 |       2.7  | 1.2e-07 |      24 |
 +------------------------+-----------+-----------+------------+---------+---------+

 #table9#
 {dataset=>"keys=1000, pick=2, exists=1"}
 +------------------------+-----------+-----------+------------+---------+---------+
 | participant            | rate (/s) | time (ns) | vs_slowest |  errors | samples |
 +------------------------+-----------+-----------+------------+---------+---------+
 | map+grep               |   1300000 |       770 |       1    | 1.7e-09 |      20 |
 | map                    |   1630000 |       614 |       1.26 | 2.1e-10 |      20 |
 | Hash::Util::Pick::pick |   2800000 |       350 |       2.2  | 8.4e-10 |      20 |
 +------------------------+-----------+-----------+------------+---------+---------+

 #table10#
 {dataset=>"keys=10000, pick=10, exists=5"}
 +------------------------+-----------+-----------+------------+---------+---------+
 | participant            | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +------------------------+-----------+-----------+------------+---------+---------+
 | map+grep               |    378000 |      2.65 |        1   | 7.3e-10 |      26 |
 | map                    |    440000 |      2.3  |        1.2 | 3.3e-09 |      20 |
 | Hash::Util::Pick::pick |   1400000 |      0.73 |        3.6 |   5e-09 |      23 |
 +------------------------+-----------+-----------+------------+---------+---------+

 #table11#
 {dataset=>"keys=10000, pick=100, exists=50"}
 +------------------------+-----------+-----------+------------+---------+---------+
 | participant            | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +------------------------+-----------+-----------+------------+---------+---------+
 | map+grep               |     41000 |      24   |       1    | 3.3e-08 |      20 |
 | map                    |     43700 |      22.9 |       1.07 | 6.5e-09 |      21 |
 | Hash::Util::Pick::pick |    140000 |       7   |       3.5  | 1.3e-08 |      20 |
 +------------------------+-----------+-----------+------------+---------+---------+

 #table12#
 {dataset=>"keys=10000, pick=2, exists=1"}
 +------------------------+-----------+-----------+------------+---------+---------+
 | participant            | rate (/s) | time (ns) | vs_slowest |  errors | samples |
 +------------------------+-----------+-----------+------------+---------+---------+
 | map+grep               |   1300000 |       768 |       1    | 3.7e-10 |      26 |
 | map                    |   1620000 |       618 |       1.24 | 2.1e-10 |      20 |
 | Hash::Util::Pick::pick |   2960000 |       338 |       2.27 | 3.1e-10 |      20 |
 +------------------------+-----------+-----------+------------+---------+---------+

 #table13#
 {dataset=>"keys=100000, pick=2, exists=1"}
 +------------------------+-----------+-----------+------------+---------+---------+
 | participant            | rate (/s) | time (ns) | vs_slowest |  errors | samples |
 +------------------------+-----------+-----------+------------+---------+---------+
 | map+grep               |   1300000 |       770 |        1   | 3.2e-10 |      33 |
 | map                    |   1500000 |       680 |        1.1 | 8.3e-10 |      20 |
 | Hash::Util::Pick::pick |   3400000 |       290 |        2.7 | 4.1e-10 |      21 |
 +------------------------+-----------+-----------+------------+---------+---------+

 #table14#
 {dataset=>"keys=2, pick=2, exists=1"}
 +------------------------+-----------+-----------+------------+---------+---------+
 | participant            | rate (/s) | time (ns) | vs_slowest |  errors | samples |
 +------------------------+-----------+-----------+------------+---------+---------+
 | map+grep               |   1310000 |       765 |        1   | 1.7e-10 |      20 |
 | map                    |   1600000 |       610 |        1.3 | 6.2e-10 |      20 |
 | Hash::Util::Pick::pick |   3000000 |       330 |        2.3 | 4.2e-10 |      20 |
 +------------------------+-----------+-----------+------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m HashPicking::pick --module-startup >>):

 #table15#
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | participant         | proc_private_dirty_size (kB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | Hash::Util::Pick    | 848                          | 4.1                | 16             |      12   |                    3.9 |        1   | 3.8e-05 |      20 |
 | perl -e1 (baseline) | 996                          | 4.4                | 18             |       8.1 |                    0   |        1.5 | 1.6e-05 |      20 |
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+


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

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
