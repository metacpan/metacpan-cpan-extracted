package Bencher::Scenario::AlgorithmDiff::Startup;

our $DATE = '2017-07-29'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark startup of Algorithm::Diff',
    module_startup => 1,
    participants => [
        {module => 'Algorithm::Diff'},
        {module => 'Algorithm::Diff::XS'},
        {module => 'Algorithm::LCSS'},
    ],
};

1;
# ABSTRACT: Benchmark startup of Algorithm::Diff

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::AlgorithmDiff::Startup - Benchmark startup of Algorithm::Diff

=head1 VERSION

This document describes version 0.001 of Bencher::Scenario::AlgorithmDiff::Startup (from Perl distribution Bencher-Scenarios-AlgorithmDiff), released on 2017-07-29.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m AlgorithmDiff::Startup

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Algorithm::Diff> 1.1903

L<Algorithm::Diff::XS> 1.1903

L<Algorithm::LCSS> 0.01

=head1 BENCHMARK PARTICIPANTS

=over

=item * Algorithm::Diff (perl_code)

L<Algorithm::Diff>



=item * Algorithm::Diff::XS (perl_code)

L<Algorithm::Diff::XS>



=item * Algorithm::LCSS (perl_code)

L<Algorithm::LCSS>



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) i7-4770 CPU @ 3.40GHz (4 cores) >>, OS: I<< GNU/Linux Debian version 8.5 >>, OS kernel: I<< Linux version 3.16.0-4-amd64 >>.

Benchmark with default options (C<< bencher -m AlgorithmDiff::Startup >>):

 #table1#
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | participant         | proc_private_dirty_size (MB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | Algorithm::Diff::XS | 1.5                          | 4.9                | 21             |       8.9 |                    6.4 |        1   | 1.2e-05 |      20 |
 | Algorithm::LCSS     | 0.82                         | 4.1                | 20             |       6.7 |                    4.2 |        1.3 |   2e-05 |      20 |
 | Algorithm::Diff     | 2.2                          | 5.6                | 23             |       6.3 |                    3.8 |        1.4 | 2.5e-05 |      20 |
 | perl -e1 (baseline) | 1.4                          | 4.8                | 21             |       2.5 |                    0   |        3.5 | 2.9e-06 |      20 |
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
