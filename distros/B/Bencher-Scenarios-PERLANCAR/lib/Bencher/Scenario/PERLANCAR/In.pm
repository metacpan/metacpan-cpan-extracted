package Bencher::Scenario::PERLANCAR::In;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.06'; # VERSION

use 5.010001;
use strict;
use warnings;

@main::ary_100  = (1..100);
@main::ary_10k  = (1..10_000);
@main::ary_1mil = (1..1000_000);

eval "package main; use List::Util 'first'"; die if $@;

our $scenario = {
    summary => 'Benchmark the task of checking whether an item is in an array',
    participants => [
        {
            name => 'grep',
            code_template => 'grep { $_ <op:raw> <needle> } @main::<haystack:raw>',
        },
        {
            name => 'first',
            code_template => 'first { $_ <op:raw> <needle> } @main::<haystack:raw>',
        },
        {
            name => 'first (array)',
            fcall_template => 'Array::AllUtils::first(sub { $_ <op:raw> <needle> }, \\@main::<haystack:raw>)',
        },
        {
            name => 'smartmatch',
            code_template => 'use experimental "smartmatch"; <needle> ~~ @main::<haystack:raw>',
        },
    ],
    datasets => [
        {name => '100 items' , args => {'haystack'=>'ary_100' , op => '==', 'needle@' => [1, 50, 100]}},
        {name => '10k' , args => {'haystack'=>'ary_10k' , op => '==', 'needle@' => [1, 5000, 10_000]}},
        {name => '1mil', args => {'haystack'=>'ary_1mil', op => '==', 'needle@' => [1, 500_000, 1000_000]}},
    ],
};

1;
# ABSTRACT: Benchmark the task of checking whether an item is in an array

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::PERLANCAR::In - Benchmark the task of checking whether an item is in an array

=head1 VERSION

This document describes version 0.06 of Bencher::Scenario::PERLANCAR::In (from Perl distribution Bencher-Scenarios-PERLANCAR), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m PERLANCAR::In

To run module startup overhead benchmark:

 % bencher --module-startup -m PERLANCAR::In

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Array::AllUtils> 0.002

=head1 BENCHMARK PARTICIPANTS

=over

=item * grep (perl_code)

Code template:

 grep { $_ <op:raw> <needle> } @main::<haystack:raw>



=item * first (perl_code)

Code template:

 first { $_ <op:raw> <needle> } @main::<haystack:raw>



=item * first (array) (perl_code)

Function call template:

 Array::AllUtils::first(sub { $_ <op:raw> <needle> }, \@main::<haystack:raw>)



=item * smartmatch (perl_code)

Code template:

 use experimental "smartmatch"; <needle> ~~ @main::<haystack:raw>



=back

=head1 BENCHMARK DATASETS

=over

=item * 100 items

=item * 10k

=item * 1mil

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m PERLANCAR::In >>):

 #table1#
 +---------------+-----------+------------+--------------+----------------+--------------+-----------+---------+
 | participant   | dataset   | arg_needle | rate (/s)    |    time (ms)   | vs_slowest   |  errors   | samples |
 +---------------+-----------+------------+--------------+----------------+--------------+-----------+---------+
 | first (array) | 1mil      | 1000000    |        5.2   | 190            |       1      |   0.00059 |      20 |
 | first (array) | 1mil      | 500000     |       10     |  96            |       2      |   0.00026 |      21 |
 | grep          | 1mil      | 1000000    |       32     |  31            |       6.2    |   0.00012 |      20 |
 | grep          | 1mil      | 1          |       32     |  31            |       6.2    | 6.5e-05   |      20 |
 | grep          | 1mil      | 500000     |       32     |  31            |       6.2    |   0.0001  |      20 |
 | first         | 1mil      | 1000000    |       38     |  27            |       7.2    | 9.5e-05   |      20 |
 | smartmatch    | 1mil      | 1000000    |       53     |  19            |      10      |   0.00012 |      21 |
 | first         | 1mil      | 500000     |       65     |  15            |      12      |   0.00013 |      20 |
 | smartmatch    | 1mil      | 500000     |      110     |   9.3          |      21      | 2.2e-05   |      20 |
 | first         | 1mil      | 1          |      260     |   3.9          |      49      |   3e-05   |      20 |
 | first (array) | 10k       | 10000      |      551     |   1.81         |     105      | 6.4e-07   |      20 |
 | first (array) | 10k       | 5000       |     1110     |   0.904        |     212      | 2.1e-07   |      20 |
 | grep          | 10k       | 10000      |     3380     |   0.296        |     646      | 1.9e-07   |      24 |
 | grep          | 10k       | 5000       |     3380     |   0.296        |     647      | 5.3e-08   |      20 |
 | grep          | 10k       | 1          |     3488.846 |   0.2866277    |     667.1007 |   1e-11   |      22 |
 | first         | 10k       | 10000      |     3790     |   0.264        |     725      | 5.2e-08   |      21 |
 | smartmatch    | 10k       | 10000      |     5527.91  |   0.1809       |    1056.99   |   0       |      20 |
 | first         | 10k       | 5000       |     6997.11  |   0.142916     |    1337.91   |   0       |      21 |
 | smartmatch    | 10k       | 5000       |    11042.7   |   0.0905574    |    2111.47   |   0       |      20 |
 | first         | 10k       | 1          |    50000     |   0.02         |    9500      |   2e-07   |      20 |
 | first (array) | 100 items | 100        |    53500     |   0.0187       |   10200      | 6.1e-09   |      24 |
 | first (array) | 100 items | 50         |   105000     |   0.00949      |   20100      | 3.1e-09   |      23 |
 | grep          | 100 items | 50         |   280000     |   0.0035       |   54000      | 4.9e-09   |      21 |
 | grep          | 100 items | 1          |   280000     |   0.0035       |   54000      | 8.3e-09   |      20 |
 | grep          | 100 items | 100        |   323760     |   0.0030887    |   61906      |   1e-11   |      20 |
 | first         | 100 items | 100        |   358000     |   0.0028       |   68400      | 8.7e-10   |      20 |
 | smartmatch    | 100 items | 100        |   530026     |   0.0018867    |  101346      |   0       |      20 |
 | first         | 100 items | 50         |   620000     |   0.0016       |  120000      | 3.3e-09   |      20 |
 | smartmatch    | 100 items | 50         |  1028000     |   0.0009727    |  196600      | 1.2e-11   |      20 |
 | first (array) | 10k       | 1          |  2253000     |   0.0004439    |  430700      |   9e-12   |      20 |
 | first (array) | 100 items | 1          |  2340000     |   0.000427     |  447000      | 1.8e-10   |      26 |
 | first (array) | 1mil      | 1          |  2349000     |   0.0004257    |  449200      | 1.2e-11   |      21 |
 | first         | 100 items | 1          |  3190000     |   0.000313     |  610000      | 1.1e-10   |      20 |
 | smartmatch    | 100 items | 1          | 14400000     |   0.0000693    | 2760000      | 8.8e-12   |      22 |
 | smartmatch    | 10k       | 1          | 14473400     |   0.0000690925 | 2767440      |   0       |      20 |
 | smartmatch    | 1mil      | 1          | 15800000     |   0.0000631    | 3030000      | 5.7e-11   |      20 |
 +---------------+-----------+------------+--------------+----------------+--------------+-----------+---------+


Benchmark module startup overhead (C<< bencher -m PERLANCAR::In --module-startup >>):

 #table2#
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | participant         | proc_private_dirty_size (kB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | Array::AllUtils     | 844                          | 4.1                | 16             |       9.4 |                    1.2 |        1   | 4.3e-05 |      20 |
 | perl -e1 (baseline) | 844                          | 4.1                | 16             |       8.2 |                    0   |        1.2 | 1.1e-05 |      20 |
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-PERLANCAR>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-PERLANCAR>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-PERLANCAR>

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
