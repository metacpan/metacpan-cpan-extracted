package Bencher::Scenario::PathNaive::rel_path;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-02-12'; # DATE
our $DIST = 'Bencher-Scenarios-PathNaive'; # DIST
our $VERSION = '0.002'; # VERSION

our $scenario = {
    summary => 'Benchmark rel_path()',
    participants => [
        {
            fcall_template => 'Path::Naive::rel_path(<path>, <base>)',
        },
    ],
    datasets => [
        {args=>{path=>'/a/b/c', base=>'/a/d/e'}},
    ],
};

1;
# ABSTRACT: Benchmark rel_path()

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::PathNaive::rel_path - Benchmark rel_path()

=head1 VERSION

This document describes version 0.002 of Bencher::Scenario::PathNaive::rel_path (from Perl distribution Bencher-Scenarios-PathNaive), released on 2020-02-12.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m PathNaive::rel_path

To run module startup overhead benchmark:

 % bencher --module-startup -m PathNaive::rel_path

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Path::Naive> 0.043

=head1 BENCHMARK PARTICIPANTS

=over

=item * Path::Naive::rel_path (perl_code)

Function call template:

 Path::Naive::rel_path(<path>, <base>)



=back

=head1 BENCHMARK DATASETS

=over

=item * {base=>"/a/d/e",path=>"/a/b/c"}

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.30.0 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 19.04 >>, OS kernel: I<< Linux version 5.0.0-37-generic >>.

Benchmark with default options (C<< bencher -m PathNaive::rel_path >>):

 #table1#
 +-----------------------+---------------------------------+---------+--------+------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant           | dataset                         | ds_tags | p_tags | perl | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-----------------------+---------------------------------+---------+--------+------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | Path::Naive::rel_path | {base=>"/a/d/e",path=>"/a/b/c"} |         |        | perl |     35000 |        29 |                 0.00% |                 0.00% | 1.6e-07 |      20 |
 +-----------------------+---------------------------------+---------+--------+------+-----------+-----------+-----------------------+-----------------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m PathNaive::rel_path --module-startup >>):

 #table2#
 +---------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | participant         | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +---------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | Path::Naive         |       9.8 |               2.7 |                 0.00% |                38.78% | 1.5e-05 |      20 |
 | perl -e1 (baseline) |       7.1 |               0   |                38.78% |                 0.00% | 2.8e-05 |      23 |
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
