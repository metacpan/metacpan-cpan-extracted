package Bencher::Scenario::StringFunctions::Trim;

our $DATE = '2018-09-16'; # DATE
our $VERSION = '0.001'; # VERSION

use strict;
use warnings;

our $scenario = {
    summary => "Benchmark string trimming (removing whitespace at the start and end of string)",
    participants => [
        {fcall_template=>'String::Trim::More::trim(<str>)'},
        {fcall_template=>'String::Util::trim(<str>)'},
    ],
    datasets => [
        {name=>'empty'        , args=>{str=>''}},
        {name=>'len10ws1'     , args=>{str=>' '.('x' x   10).' '}},
        {name=>'len100ws1'    , args=>{str=>' '.('x' x  100).' '}},
        {name=>'len100ws10'   , args=>{str=>(' ' x   10).('x' x  100).(' ' x 10)}},
        {name=>'len100ws100'  , args=>{str=>(' ' x  100).('x' x  100).(' ' x 100)}},
        {name=>'len1000ws1'   , args=>{str=>' '.('x' x 1000).' '}},
        {name=>'len1000ws10'  , args=>{str=>(' ' x   10).('x' x 1000).(' ' x 10)}},
        {name=>'len1000ws100' , args=>{str=>(' ' x  100).('x' x 1000).(' ' x 100)}},
        {name=>'len1000ws1000', args=>{str=>(' ' x 1000).('x' x 1000).(' ' x 1000)}},
    ],
};

1;
# ABSTRACT: Benchmark string trimming (removing whitespace at the start and end of string)

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::StringFunctions::Trim - Benchmark string trimming (removing whitespace at the start and end of string)

=head1 VERSION

This document describes version 0.001 of Bencher::Scenario::StringFunctions::Trim (from Perl distribution Bencher-Scenarios-StringFunctions), released on 2018-09-16.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m StringFunctions::Trim

To run module startup overhead benchmark:

 % bencher --module-startup -m StringFunctions::Trim

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<String::Trim::More> 0.03

L<String::Util> 1.26

=head1 BENCHMARK PARTICIPANTS

=over

=item * String::Trim::More::trim (perl_code)

Function call template:

 String::Trim::More::trim(<str>)



=item * String::Util::trim (perl_code)

Function call template:

 String::Util::trim(<str>)



=back

=head1 BENCHMARK DATASETS

=over

=item * empty

=item * len10ws1

=item * len100ws1

=item * len100ws10

=item * len100ws100

=item * len1000ws1

=item * len1000ws10

=item * len1000ws100

=item * len1000ws1000

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.26.1 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 18.3 >>, OS kernel: I<< Linux version 4.10.0-38-generic >>.

Benchmark with default options (C<< bencher -m StringFunctions::Trim >>):

 #table1#
 +--------------------------+---------------+-----------+-----------+------------+---------+---------+
 | participant              | dataset       | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +--------------------------+---------------+-----------+-----------+------------+---------+---------+
 | String::Util::trim       | len1000ws1000 |    207000 |   4.84    |     1      | 1.4e-09 |      28 |
 | String::Trim::More::trim | len1000ws1000 |    219230 |   4.5615  |     1.0607 | 3.4e-11 |      20 |
 | String::Util::trim       | len1000ws100  |    260000 |   3.9     |     1.2    | 4.9e-09 |      37 |
 | String::Util::trim       | len1000ws10   |    268000 |   3.73    |     1.3    | 1.3e-09 |      32 |
 | String::Util::trim       | len1000ws1    |    273000 |   3.66    |     1.32   | 1.5e-09 |      26 |
 | String::Trim::More::trim | len1000ws100  |    275900 |   3.6245  |     1.335  | 3.4e-11 |      20 |
 | String::Trim::More::trim | len1000ws10   |    290000 |   3.4     |     1.4    | 5.4e-09 |      31 |
 | String::Trim::More::trim | len1000ws1    |    291100 |   3.436   |     1.408  | 4.7e-11 |      20 |
 | String::Util::trim       | len100ws100   |    630000 |   1.6     |     3      | 2.3e-09 |      23 |
 | String::Util::trim       | len100ws10    |    707600 |   1.413   |     3.424  | 3.4e-11 |      21 |
 | String::Util::trim       | len100ws1     |    712000 |   1.4     |     3.44   | 3.8e-10 |      25 |
 | String::Trim::More::trim | len100ws100   |    745300 |   1.342   |     3.606  | 4.6e-11 |      22 |
 | String::Trim::More::trim | len100ws1     |    840000 |   1.2     |     4.1    | 1.6e-09 |      22 |
 | String::Trim::More::trim | len100ws10    |    840000 |   1.2     |     4.1    | 1.3e-09 |      31 |
 | String::Util::trim       | len10ws1      |    910000 |   1.1     |     4.4    | 1.2e-09 |      21 |
 | String::Trim::More::trim | len10ws1      |   1140000 |   0.88    |     5.5    | 4.2e-10 |      20 |
 | String::Util::trim       | empty         |   2790000 |   0.358   |    13.5    | 4.6e-11 |      20 |
 | String::Trim::More::trim | empty         |   5535560 |   0.18065 |    26.7844 |   0     |      21 |
 +--------------------------+---------------+-----------+-----------+------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m StringFunctions::Trim --module-startup >>):

 #table2#
 +---------------------+-----------+------------------------+------------+---------+---------+
 | participant         | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +---------------------+-----------+------------------------+------------+---------+---------+
 | String::Util        |      14   |                    8.5 |        1   | 1.4e-05 |      20 |
 | String::Trim::More  |       8.1 |                    2.6 |        1.7 | 9.4e-06 |      21 |
 | perl -e1 (baseline) |       5.5 |                    0   |        2.5 | 1.7e-05 |      20 |
 +---------------------+-----------+------------------------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-StringFunctions>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-StringFunctions>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-StringFunctions>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
