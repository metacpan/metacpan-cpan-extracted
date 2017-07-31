package Bencher::Scenario::AlgorithmDiff::Diff;

our $DATE = '2017-07-29'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => "Benchmark Algorithm::Diff's diff(), sdiff(), compact_diff(), LCS(), LCSidx(), LCS_length()",
    participants => [
        {fcall_template=>'Algorithm::Diff::diff(<ary1>, <ary2>)'},
        {fcall_template=>'Algorithm::Diff::sdiff(<ary1>, <ary2>)'},
        {fcall_template=>'Algorithm::Diff::compact_diff(<ary1>, <ary2>)'},
        {fcall_template=>'Algorithm::Diff::LCS(<ary1>, <ary2>)'},
        {fcall_template=>'Algorithm::Diff::LCSidx(<ary1>, <ary2>)'},
        {fcall_template=>'Algorithm::Diff::LCS_length(<ary1>, <ary2>)'},
        {fcall_template=>'Algorithm::Diff::XS::compact_diff(<ary1>, <ary2>)'},
        {fcall_template=>'Algorithm::Diff::XS::LCSidx(<ary1>, <ary2>)'},
    ],
    datasets => [
        {name=>'empty'        , args=>{ary1=>[], ary2=>[]}},
        {name=>'insert 1x1'   , args=>{ary1=>[], ary2=>[1]}},
        {name=>'insert 1x10'  , args=>{ary1=>[], ary2=>[1..10]}},
        {name=>'insert 10x1'  , args=>{ary1=>[1..10], ary2=>[map {$_,$_+10} 1..10]}},
        {name=>'delete 1x1'   , args=>{ary1=>[1], ary2=>[]}},
        {name=>'delete 1x10'  , args=>{ary1=>[1..10], ary2=>[]}},
        {name=>'delete 10x1'  , args=>{ary1=>[map {$_,$_+10} 1..10], ary2=>[1..10]}},

        {name=>'insert+delete 150x1'  , args=>{ary1=>[qw/a b d/ x 50], ary2=>[qw/b a d c/ x 50]}},
    ],
};

1;
# ABSTRACT: Benchmark Algorithm::Diff's diff(), sdiff(), compact_diff(), LCS(), LCSidx(), LCS_length()

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::AlgorithmDiff::Diff - Benchmark Algorithm::Diff's diff(), sdiff(), compact_diff(), LCS(), LCSidx(), LCS_length()

=head1 VERSION

This document describes version 0.001 of Bencher::Scenario::AlgorithmDiff::Diff (from Perl distribution Bencher-Scenarios-AlgorithmDiff), released on 2017-07-29.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m AlgorithmDiff::Diff

To run module startup overhead benchmark:

 % bencher --module-startup -m AlgorithmDiff::Diff

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Algorithm::Diff> 1.1903

L<Algorithm::Diff::XS> 1.1903

=head1 BENCHMARK PARTICIPANTS

=over

=item * Algorithm::Diff::diff (perl_code)

Function call template:

 Algorithm::Diff::diff(<ary1>, <ary2>)



=item * Algorithm::Diff::sdiff (perl_code)

Function call template:

 Algorithm::Diff::sdiff(<ary1>, <ary2>)



=item * Algorithm::Diff::compact_diff (perl_code)

Function call template:

 Algorithm::Diff::compact_diff(<ary1>, <ary2>)



=item * Algorithm::Diff::LCS (perl_code)

Function call template:

 Algorithm::Diff::LCS(<ary1>, <ary2>)



=item * Algorithm::Diff::LCSidx (perl_code)

Function call template:

 Algorithm::Diff::LCSidx(<ary1>, <ary2>)



=item * Algorithm::Diff::LCS_length (perl_code)

Function call template:

 Algorithm::Diff::LCS_length(<ary1>, <ary2>)



=item * Algorithm::Diff::XS::compact_diff (perl_code)

Function call template:

 Algorithm::Diff::XS::compact_diff(<ary1>, <ary2>)



=item * Algorithm::Diff::XS::LCSidx (perl_code)

Function call template:

 Algorithm::Diff::XS::LCSidx(<ary1>, <ary2>)



=back

=head1 BENCHMARK DATASETS

=over

=item * empty

=item * insert 1x1

=item * insert 1x10

=item * insert 10x1

=item * delete 1x1

=item * delete 1x10

=item * delete 10x1

=item * insert+delete 150x1

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) i7-4770 CPU @ 3.40GHz (4 cores) >>, OS: I<< GNU/Linux Debian version 8.5 >>, OS kernel: I<< Linux version 3.16.0-4-amd64 >>.

Benchmark with default options (C<< bencher -m AlgorithmDiff::Diff >>):

 #table1#
 +-----------------------------------+---------------------+-----------+-----------+------------+---------+---------+
 | participant                       | dataset             | rate (/s) | time (ms) | vs_slowest |  errors | samples |
 +-----------------------------------+---------------------+-----------+-----------+------------+---------+---------+
 | Algorithm::Diff::sdiff            | insert+delete 150x1 |     123   | 8.11      |      1     | 3.8e-06 |      20 |
 | Algorithm::Diff::diff             | insert+delete 150x1 |     124   | 8.08      |      1     | 1.1e-06 |      21 |
 | Algorithm::Diff::compact_diff     | insert+delete 150x1 |     125   | 8.01      |      1.01  | 1.1e-06 |      22 |
 | Algorithm::Diff::LCS              | insert+delete 150x1 |     125.5 | 7.97      |      1.018 | 6.4e-07 |      20 |
 | Algorithm::Diff::LCSidx           | insert+delete 150x1 |     126   | 7.96      |      1.02  | 8.5e-07 |      20 |
 | Algorithm::Diff::LCS_length       | insert+delete 150x1 |     126.1 | 7.929     |      1.023 | 5.9e-07 |      20 |
 | Algorithm::Diff::XS::compact_diff | insert+delete 150x1 |    4010   | 0.25      |     32.5   | 2.1e-07 |      20 |
 | Algorithm::Diff::XS::LCSidx       | insert+delete 150x1 |    5000   | 0.2       |     41     | 2.1e-07 |      20 |
 | Algorithm::Diff::diff             | delete 10x1         |   30000   | 0.04      |    200     | 6.8e-07 |      34 |
 | Algorithm::Diff::sdiff            | insert 10x1         |   25437   | 0.0393128 |    206.364 | 5.7e-12 |      20 |
 | Algorithm::Diff::sdiff            | delete 10x1         |   27000   | 0.037     |    220     |   4e-08 |      20 |
 | Algorithm::Diff::diff             | insert 10x1         |   27000   | 0.037     |    220     |   5e-08 |      23 |
 | Algorithm::Diff::compact_diff     | insert 10x1         |   31189.7 | 0.0320619 |    253.033 |   0     |      20 |
 | Algorithm::Diff::compact_diff     | delete 10x1         |   34000   | 0.029     |    280     |   5e-08 |      23 |
 | Algorithm::Diff::LCS              | insert 10x1         |   30000   | 0.03      |    300     | 4.7e-07 |      28 |
 | Algorithm::Diff::LCSidx           | insert 10x1         |   39056.8 | 0.0256037 |    316.857 |   0     |      20 |
 | Algorithm::Diff::LCS              | delete 10x1         |   42700   | 0.0234    |    347     | 6.4e-09 |      22 |
 | Algorithm::Diff::LCSidx           | delete 10x1         |   43576.1 | 0.0229483 |    353.522 | 5.8e-12 |      20 |
 | Algorithm::Diff::LCS_length       | insert 10x1         |   45000   | 0.022     |    360     | 2.4e-08 |      25 |
 | Algorithm::Diff::XS::compact_diff | insert 10x1         |   45508.8 | 0.0219738 |    369.2   | 5.8e-12 |      20 |
 | Algorithm::Diff::LCS_length       | delete 10x1         |   51000   | 0.02      |    410     | 2.5e-08 |      23 |
 | Algorithm::Diff::XS::compact_diff | delete 10x1         |   53400   | 0.0187    |    433     | 6.5e-09 |      21 |
 | Algorithm::Diff::XS::LCSidx       | insert 10x1         |   64000   | 0.016     |    520     | 2.7e-08 |      20 |
 | Algorithm::Diff::sdiff            | insert 1x10         |   65000   | 0.0154    |    527     | 5.8e-09 |      26 |
 | Algorithm::Diff::diff             | insert 1x10         |   68600   | 0.0146    |    556     | 6.7e-09 |      20 |
 | Algorithm::Diff::XS::LCSidx       | delete 10x1         |   78000   | 0.013     |    630     | 2.7e-08 |      20 |
 | Algorithm::Diff::sdiff            | delete 1x10         |   83200   | 0.012     |    675     | 9.3e-09 |      23 |
 | Algorithm::Diff::diff             | delete 1x10         |   87000   | 0.011     |    710     | 1.3e-08 |      20 |
 | Algorithm::Diff::compact_diff     | insert 1x10         |  120000   | 0.0085    |    960     |   1e-08 |      20 |
 | Algorithm::Diff::LCSidx           | insert 1x10         |  133000   | 0.00754   |   1080     | 2.6e-09 |      32 |
 | Algorithm::Diff::LCS              | insert 1x10         |  140000   | 0.0072    |   1100     | 1.2e-08 |      23 |
 | Algorithm::Diff::LCS_length       | insert 1x10         |  140000   | 0.007     |   1200     | 1.3e-08 |      20 |
 | Algorithm::Diff::sdiff            | insert 1x1          |  140000   | 0.007     |   1200     | 1.2e-08 |      25 |
 | Algorithm::Diff::XS::compact_diff | insert 1x10         |  150000   | 0.0069    |   1200     | 9.8e-09 |      21 |
 | Algorithm::Diff::diff             | insert 1x1          |  149000   | 0.0067    |   1210     | 2.8e-09 |      28 |
 | Algorithm::Diff::sdiff            | delete 1x1          |  150000   | 0.0066    |   1200     | 8.9e-09 |      25 |
 | Algorithm::Diff::diff             | delete 1x1          |  154000   | 0.00649   |   1250     | 2.8e-09 |      28 |
 | Algorithm::Diff::XS::LCSidx       | insert 1x10         |  174000   | 0.00574   |   1410     | 1.7e-09 |      20 |
 | Algorithm::Diff::sdiff            | empty               |  176000   | 0.00569   |   1430     | 1.3e-09 |      31 |
 | Algorithm::Diff::compact_diff     | delete 1x10         |  187000   | 0.00534   |   1520     | 1.5e-09 |      26 |
 | Algorithm::Diff::diff             | empty               |  192000   | 0.00522   |   1550     | 1.3e-09 |      31 |
 | Algorithm::Diff::LCSidx           | delete 1x10         |  227580   | 0.0043941 |   1846.3   | 5.8e-12 |      20 |
 | Algorithm::Diff::LCS              | delete 1x10         |  239000   | 0.00419   |   1940     | 3.9e-09 |      33 |
 | Algorithm::Diff::XS::compact_diff | delete 1x10         |  239000   | 0.00418   |   1940     | 1.5e-09 |      24 |
 | Algorithm::Diff::LCS_length       | delete 1x10         |  252990   | 0.0039528 |   2052.4   | 5.8e-12 |      21 |
 | Algorithm::Diff::compact_diff     | insert 1x1          |  250000   | 0.0039    |   2100     | 6.2e-09 |      23 |
 | Algorithm::Diff::compact_diff     | delete 1x1          |  280000   | 0.0036    |   2300     | 5.4e-09 |      31 |
 | Algorithm::Diff::XS::compact_diff | insert 1x1          |  280000   | 0.0036    |   2300     |   4e-09 |      31 |
 | Algorithm::Diff::XS::LCSidx       | delete 1x10         |  306000   | 0.00327   |   2480     | 1.4e-09 |      27 |
 | Algorithm::Diff::XS::compact_diff | delete 1x1          |  306030   | 0.0032676 |   2482.8   | 5.8e-12 |      20 |
 | Algorithm::Diff::compact_diff     | empty               |  326000   | 0.00307   |   2640     | 7.5e-10 |      25 |
 | Algorithm::Diff::LCSidx           | insert 1x1          |  340810   | 0.0029342 |   2764.9   | 5.8e-12 |      20 |
 | Algorithm::Diff::XS::compact_diff | empty               |  349000   | 0.00287   |   2830     | 2.4e-09 |      21 |
 | Algorithm::Diff::LCS              | insert 1x1          |  370000   | 0.0027    |   3000     | 3.1e-09 |      23 |
 | Algorithm::Diff::LCSidx           | delete 1x1          |  380000   | 0.00263   |   3090     | 8.3e-10 |      20 |
 | Algorithm::Diff::XS::LCSidx       | insert 1x1          |  397000   | 0.00252   |   3220     |   7e-10 |      28 |
 | Algorithm::Diff::LCS_length       | insert 1x1          |  404000   | 0.00247   |   3280     | 8.3e-10 |      20 |
 | Algorithm::Diff::LCS              | delete 1x1          |  420000   | 0.0024    |   3400     | 3.3e-09 |      20 |
 | Algorithm::Diff::LCSidx           | empty               |  430000   | 0.0023    |   3500     | 2.4e-09 |      21 |
 | Algorithm::Diff::XS::LCSidx       | delete 1x1          |  440000   | 0.0023    |   3500     | 3.3e-09 |      20 |
 | Algorithm::Diff::LCS_length       | delete 1x1          |  460000   | 0.0022    |   3800     | 3.3e-09 |      20 |
 | Algorithm::Diff::LCS              | empty               |  474000   | 0.00211   |   3840     | 7.9e-10 |      22 |
 | Algorithm::Diff::XS::LCSidx       | empty               |  480000   | 0.0021    |   3900     | 2.4e-09 |      21 |
 | Algorithm::Diff::LCS_length       | empty               |  530000   | 0.0019    |   4300     | 3.3e-09 |      20 |
 +-----------------------------------+---------------------+-----------+-----------+------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m AlgorithmDiff::Diff --module-startup >>):

 #table2#
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | participant         | proc_private_dirty_size (MB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | Algorithm::Diff::XS | 1.4                          | 4.8                | 21             |       8.9 |                    6.4 |        1   | 3.1e-05 |      20 |
 | Algorithm::Diff     | 1.4                          | 4.8                | 21             |       6.4 |                    3.9 |        1.4 | 1.6e-05 |      21 |
 | perl -e1 (baseline) | 1.4                          | 4.8                | 21             |       2.5 |                    0   |        3.6 | 4.6e-06 |      21 |
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-AlgorithmDiff>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-AlgorithmDiff>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-AlgorithmDiff>

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
