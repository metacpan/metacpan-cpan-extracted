package Bencher::Scenario::Example::HashCreation;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark creation of hash of N keys (1..N) and value=1',
    participants => [
        {name=>'create_hash', code_template=>'+{map {($_=>1)} 1..<size>}'},
    ],
    datasets => [
        {args => {'size@' => [1, 1000, 1000000]}},
    ],
};

1;
# ABSTRACT: Benchmark creation of hash of N keys (1..N) and value=1

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::Example::HashCreation - Benchmark creation of hash of N keys (1..N) and value=1

=head1 VERSION

This document describes version 0.002 of Bencher::Scenario::Example::HashCreation (from Perl distribution Bencher-Scenarios-Examples), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m Example::HashCreation

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARK PARTICIPANTS

=over

=item * create_hash (perl_code)

Code template:

 +{map {($_=>1)} 1..<size>}



=back

=head1 BENCHMARK DATASETS

=over

=item * [1,1000,1000000]

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m Example::HashCreation >>):

 #table1#
 +----------+------------+-------------+------------+----------+---------+
 | arg_size | rate (/s)  | time (ms)   | vs_slowest |  errors  | samples |
 +----------+------------+-------------+------------+----------+---------+
 | 1000000  |       0.99 | 1000        |          1 |   0.0095 |      20 |
 | 1000     |    2000    |    0.4      |       2000 | 1.1e-05  |      20 |
 | 1        | 1770000    |    0.000565 |    1790000 | 2.1e-10  |      20 |
 +----------+------------+-------------+------------+----------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-Examples>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-Examples>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-Examples>

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
