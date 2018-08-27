package Bencher::Scenario::ISBN::Validating;

our $DATE = '2018-08-26'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark validating ISBN',
    modules => {

    },
    participants => [
        {
            module => 'Business::ISBN',
            code_template => 'Business::ISBN->new(<isbn>)->is_valid ? 1:0',
            tags => ['isbn10', 'isbn13'],
        },
        {
            module => 'Algorithm::CheckDigits::M10_004',
            extra_modules => ['Algorithm::CheckDigits'],
            tags => ['isbn13'],
            code_template => 'require Algorithm::CheckDigits; Algorithm::CheckDigits::CheckDigits("ean")->is_valid(<isbn>) ? 1:0',
        },
        {
            module => 'Algorithm::CheckDigits::M11_001',
            extra_modules => ['Algorithm::CheckDigits'],
            tags => ['isbn10'],
            code_template => 'require Algorithm::CheckDigits; Algorithm::CheckDigits::CheckDigits("ISBN")->is_valid(<isbn>) ? 1:0',
        },
    ],
    datasets => [
        {
            include_participant_tags => ['isbn10'],
            args => {isbn => '1-56592-257-3'},
            result => 1,
        },
        {
            include_participant_tags => ['isbn10'],
            args => {isbn => '1-56592-257-2'},
            result => 0,
        },

        {
            include_participant_tags => ['isbn13'],
            args => {isbn => '978-0-596-52724-2'},
            result => 1,
        },
        {
            include_participant_tags => ['isbn13'],
            args => {isbn => '978-0-596-52724-1'},
            result => 0,
        },
    ],
};

1;
# ABSTRACT: Benchmark validating ISBN

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::ISBN::Validating - Benchmark validating ISBN

=head1 VERSION

This document describes version 0.001 of Bencher::Scenario::ISBN::Validating (from Perl distribution Bencher-Scenarios-ISBN), released on 2018-08-26.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m ISBN::Validating

To run module startup overhead benchmark:

 % bencher --module-startup -m ISBN::Validating

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Algorithm::CheckDigits::M10_004> v1.3.2

L<Algorithm::CheckDigits::M11_001> v1.3.2

L<Business::ISBN> 3.004

=head1 BENCHMARK PARTICIPANTS

=over

=item * Business::ISBN (perl_code) [isbn10, isbn13]

Code template:

 Business::ISBN->new(<isbn>)->is_valid ? 1:0



=item * Algorithm::CheckDigits::M10_004 (perl_code) [isbn13]

Code template:

 require Algorithm::CheckDigits; Algorithm::CheckDigits::CheckDigits("ean")->is_valid(<isbn>) ? 1:0



=item * Algorithm::CheckDigits::M11_001 (perl_code) [isbn10]

Code template:

 require Algorithm::CheckDigits; Algorithm::CheckDigits::CheckDigits("ISBN")->is_valid(<isbn>) ? 1:0



=back

=head1 BENCHMARK DATASETS

=over

=item * 1-56592-257-3

=item * 1-56592-257-2

=item * 978-0-596-52724-2

=item * 978-0-596-52724-1

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.26.1 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 18.3 >>, OS kernel: I<< Linux version 4.10.0-38-generic >>.

Benchmark with default options (C<< bencher -m ISBN::Validating >>):

 #table1#
 +---------------------------------+-------------------+----------------+-----------+-----------+------------+---------+---------+
 | participant                     | dataset           | p_tags         | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +---------------------------------+-------------------+----------------+-----------+-----------+------------+---------+---------+
 | Business::ISBN                  | 1-56592-257-3     | isbn10, isbn13 |     32000 |    32     |      1     | 5.3e-08 |      20 |
 | Business::ISBN                  | 1-56592-257-2     | isbn10, isbn13 |     32000 |    32     |      1     | 5.3e-08 |      20 |
 | Business::ISBN                  | 978-0-596-52724-2 | isbn10, isbn13 |     33000 |    31     |      1     | 5.1e-08 |      34 |
 | Business::ISBN                  | 978-0-596-52724-1 | isbn10, isbn13 |     33000 |    30     |      1.1   | 5.3e-08 |      20 |
 | Algorithm::CheckDigits::M10_004 | 978-0-596-52724-2 | isbn13         |    120000 |     8.5   |      3.7   | 1.3e-08 |      21 |
 | Algorithm::CheckDigits::M10_004 | 978-0-596-52724-1 | isbn13         |    120000 |     8.334 |      3.792 |   2e-10 |      20 |
 | Algorithm::CheckDigits::M11_001 | 1-56592-257-3     | isbn10         |    130000 |     7.8   |      4     |   1e-08 |      20 |
 | Algorithm::CheckDigits::M11_001 | 1-56592-257-2     | isbn10         |    130000 |     7.8   |      4.1   | 9.8e-09 |      21 |
 +---------------------------------+-------------------+----------------+-----------+-----------+------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m ISBN::Validating --module-startup >>):

 #table2#
 +---------------------------------+-----------+------------------------+------------+---------+---------+
 | participant                     | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +---------------------------------+-----------+------------------------+------------+---------+---------+
 | Business::ISBN                  |      31   |                   26   |        1   | 3.6e-05 |      20 |
 | Algorithm::CheckDigits::M11_001 |       8.7 |                    3.7 |        3.6 | 1.8e-05 |      20 |
 | Algorithm::CheckDigits::M10_004 |       8.6 |                    3.6 |        3.6 | 4.3e-05 |      20 |
 | perl -e1 (baseline)             |       5   |                    0   |        6.2 | 2.2e-05 |      20 |
 +---------------------------------+-----------+------------------------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-ISBN>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-ISBN>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-ISBN>

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
