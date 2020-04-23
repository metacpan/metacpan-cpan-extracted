package Bencher::Scenario::PathNaive::concat_path;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-02-12'; # DATE
our $DIST = 'Bencher-Scenarios-PathNaive'; # DIST
our $VERSION = '0.002'; # VERSION

our $scenario = {
    summary => 'Benchmark concat_path()',
    participants => [
        {
            fcall_template => 'Path::Naive::concat_path(<path1>, <path2>)',
        },
        {
            fcall_template => 'Path::Naive::concat_and_normalize_path(<path1>, <path2>)',
        },
    ],
    datasets => [
        {args=>{path1=>'a', path2=>'b'}},
        {args=>{path1=>'/a/b/c/d/e', path2=>'f/g/h/i/j'}},
        {args=>{path1=>'/a/b/c/./d/e', path2=>'f/g/h/i/j'}},
    ],
};

1;
# ABSTRACT: Benchmark concat_path()

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::PathNaive::concat_path - Benchmark concat_path()

=head1 VERSION

This document describes version 0.002 of Bencher::Scenario::PathNaive::concat_path (from Perl distribution Bencher-Scenarios-PathNaive), released on 2020-02-12.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m PathNaive::concat_path

To run module startup overhead benchmark:

 % bencher --module-startup -m PathNaive::concat_path

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Path::Naive> 0.043

=head1 BENCHMARK PARTICIPANTS

=over

=item * Path::Naive::concat_path (perl_code)

Function call template:

 Path::Naive::concat_path(<path1>, <path2>)



=item * Path::Naive::concat_and_normalize_path (perl_code)

Function call template:

 Path::Naive::concat_and_normalize_path(<path1>, <path2>)



=back

=head1 BENCHMARK DATASETS

=over

=item * a

=item * /a/b/c/d/e

=item * /a/b/c/./d/e

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.30.0 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 19.04 >>, OS kernel: I<< Linux version 5.0.0-37-generic >>.

Benchmark with default options (C<< bencher -m PathNaive::concat_path >>):

 #table1#
 +----------------------------------------+--------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                            | dataset      | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +----------------------------------------+--------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | Path::Naive::concat_and_normalize_path | /a/b/c/./d/e |    117000 |    8.56   |                 0.00% |              1824.80% | 3.2e-09 |      22 |
 | Path::Naive::concat_and_normalize_path | /a/b/c/d/e   |    120000 |    8.1    |                 6.17% |              1712.89% | 1.3e-08 |      20 |
 | Path::Naive::concat_and_normalize_path | a            |    327000 |    3.06   |               179.74% |               588.07% | 2.5e-09 |      20 |
 | Path::Naive::concat_path               | /a/b/c/d/e   |   2228000 |    0.4488 |              1807.08% |                 0.93% | 2.3e-11 |      20 |
 | Path::Naive::concat_path               | /a/b/c/./d/e |   2229000 |    0.4487 |              1807.32% |                 0.92% | 5.8e-12 |      20 |
 | Path::Naive::concat_path               | a            |   2250000 |    0.445  |              1824.80% |                 0.00% | 7.5e-11 |      21 |
 +----------------------------------------+--------------+-----------+-----------+-----------------------+-----------------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m PathNaive::concat_path --module-startup >>):

 #table2#
 +---------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | participant         | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +---------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | Path::Naive         |       9.6 |               2.3 |                 0.00% |                32.67% |   1e-05 |      20 |
 | perl -e1 (baseline) |       7.3 |               0   |                32.67% |                 0.00% | 5.2e-05 |      20 |
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
