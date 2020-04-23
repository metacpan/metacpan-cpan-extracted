package Bencher::Scenario::PathNaive::normalize_path;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-02-12'; # DATE
our $DIST = 'Bencher-Scenarios-PathNaive'; # DIST
our $VERSION = '0.002'; # VERSION

our $scenario = {
    summary => 'Benchmark normalize_path()',
    participants => [
        {
            fcall_template => 'Path::Naive::normalize_path(<string>)',
        },
    ],
    datasets => [
        {args=>{string=>'/'}},
        {args=>{string=>'/a'}},
        {args=>{string=>'/a/b/c/d/e'}},
        {args=>{string=>'/a/./b/../b/c///d/././e'}},
    ],
};

1;
# ABSTRACT: Benchmark normalize_path()

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::PathNaive::normalize_path - Benchmark normalize_path()

=head1 VERSION

This document describes version 0.002 of Bencher::Scenario::PathNaive::normalize_path (from Perl distribution Bencher-Scenarios-PathNaive), released on 2020-02-12.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m PathNaive::normalize_path

To run module startup overhead benchmark:

 % bencher --module-startup -m PathNaive::normalize_path

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Path::Naive> 0.043

=head1 BENCHMARK PARTICIPANTS

=over

=item * Path::Naive::normalize_path (perl_code)

Function call template:

 Path::Naive::normalize_path(<string>)



=back

=head1 BENCHMARK DATASETS

=over

=item * /

=item * /a

=item * /a/b/c/d/e

=item * /a/./b/../b/c///d/././e

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.30.0 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 19.04 >>, OS kernel: I<< Linux version 5.0.0-37-generic >>.

Benchmark with default options (C<< bencher -m PathNaive::normalize_path >>):

 #table1#
 +-------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | dataset                 | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | /a/./b/../b/c///d/././e |    147584 |   6.77581 |                 0.00% |               363.35% | 5.8e-12 |      20 |
 | /a/b/c/d/e              |    232000 |   4.31    |                57.14% |               194.86% | 1.6e-09 |      23 |
 | /a                      |    481000 |   2.08    |               226.17% |                42.06% | 7.9e-10 |      22 |
 | /                       |    684000 |   1.46    |               363.35% |                 0.00% | 4.2e-10 |      20 |
 +-------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m PathNaive::normalize_path --module-startup >>):

 #table2#
 +---------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | participant         | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +---------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | Path::Naive         |       9.7 |               2.5 |                 0.00% |                35.25% | 2.2e-05 |      20 |
 | perl -e1 (baseline) |       7.2 |               0   |                35.25% |                 0.00% | 5.1e-05 |      20 |
 +---------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-PathNaive>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-PathNaive>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-PathNaive>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
