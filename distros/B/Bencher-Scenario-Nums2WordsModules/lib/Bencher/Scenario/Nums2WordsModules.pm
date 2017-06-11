package Bencher::Scenario::Nums2WordsModules;

our $DATE = '2017-06-09'; # DATE
our $VERSION = '0.004'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark various number-to-words modules '.
        'of different languages against one another',
    participants => [
        {
            fcall_template => 'Lingua::ID::Nums2Words::nums2words(<num>)',
        },
        {
            fcall_template => 'Lingua::FR::Numbers::number_to_fr(<num>)',
        },
        {
            fcall_template => 'Lingua::EN::Numbers::num2en(<num>)',
        },
    ],
    datasets => [
        {args=>{num=>1}},
        {args=>{num=>123}},
        {args=>{num=>123_456_789}},
    ],
};

1;
# ABSTRACT: Benchmark various number-to-words modules of different languages against one another

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::Nums2WordsModules - Benchmark various number-to-words modules of different languages against one another

=head1 VERSION

This document describes version 0.004 of Bencher::Scenario::Nums2WordsModules (from Perl distribution Bencher-Scenario-Nums2WordsModules), released on 2017-06-09.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m Nums2WordsModules

To run module startup overhead benchmark:

 % bencher --module-startup -m Nums2WordsModules

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Lingua::ID::Nums2Words> 0.04

L<Lingua::FR::Numbers> 1.161910

L<Lingua::EN::Numbers> 2.03

=head1 BENCHMARK PARTICIPANTS

=over

=item * Lingua::ID::Nums2Words::nums2words (perl_code)

Function call template:

 Lingua::ID::Nums2Words::nums2words(<num>)



=item * Lingua::FR::Numbers::number_to_fr (perl_code)

Function call template:

 Lingua::FR::Numbers::number_to_fr(<num>)



=item * Lingua::EN::Numbers::num2en (perl_code)

Function call template:

 Lingua::EN::Numbers::num2en(<num>)



=back

=head1 BENCHMARK DATASETS

=over

=item * 1

=item * 123

=item * 123456789

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) i5-2400 CPU @ 3.10GHz (4 cores) >>, OS: I<< GNU/Linux Debian version 8.0 >>, OS kernel: I<< Linux version 3.16.0-4-amd64 >>.

Benchmark with default options (C<< bencher -m Nums2WordsModules >>):

 #table1#
 +------------------------------------+-----------+-----------+-----------+------------+---------+---------+
 | participant                        | dataset   | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +------------------------------------+-----------+-----------+-----------+------------+---------+---------+
 | Lingua::ID::Nums2Words::nums2words | 123456789 |     25600 |     39    |       1    | 1.3e-08 |      21 |
 | Lingua::EN::Numbers::num2en        | 123456789 |     30000 |     33.3  |       1.17 | 1.3e-08 |      20 |
 | Lingua::ID::Nums2Words::nums2words | 123       |     62000 |     16    |       2.4  | 2.7e-08 |      20 |
 | Lingua::FR::Numbers::number_to_fr  | 123456789 |     74000 |     14    |       2.9  |   2e-08 |      20 |
 | Lingua::ID::Nums2Words::nums2words | 1         |     80000 |     12    |       3.1  | 5.3e-08 |      20 |
 | Lingua::EN::Numbers::num2en        | 123       |    110000 |      9    |       4.3  | 1.7e-08 |      20 |
 | Lingua::FR::Numbers::number_to_fr  | 123       |    160000 |      6.2  |       6.3  |   2e-08 |      23 |
 | Lingua::FR::Numbers::number_to_fr  | 1         |    210000 |      4.7  |       8.3  | 7.9e-09 |      22 |
 | Lingua::EN::Numbers::num2en        | 1         |   2200000 |      0.44 |      88    | 3.5e-09 |      21 |
 +------------------------------------+-----------+-----------+-----------+------------+---------+---------+


=begin html

<img src="https://st.aticpan.org/source/PERLANCAR/Bencher-Scenario-Nums2WordsModules-0.004/share/images/bencher-result-1.png" />

=end html


Benchmark module startup overhead (C<< bencher -m Nums2WordsModules --module-startup >>):

 #table2#
 +------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | participant            | proc_private_dirty_size (MB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | Lingua::FR::Numbers    | 1                            | 4.4                | 20             |      13   |                    7.5 |        1   | 6.8e-05 |      20 |
 | Lingua::ID::Nums2Words | 1.4                          | 4.8                | 21             |      10   |                    4.5 |        1.3 | 3.3e-05 |      20 |
 | Lingua::EN::Numbers    | 0.82                         | 4.1                | 20             |       9.6 |                    4.1 |        1.4 | 2.4e-05 |      21 |
 | perl -e1 (baseline)    | 1.1                          | 4.4                | 20             |       5.5 |                    0   |        2.4 | 1.7e-05 |      21 |
 +------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+


=begin html

<img src="https://st.aticpan.org/source/PERLANCAR/Bencher-Scenario-Nums2WordsModules-0.004/share/images/bencher-result-2.png" />

=end html


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-Nums2WordsModules>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-Nums2WordsModules>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-Nums2WordsModules>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
