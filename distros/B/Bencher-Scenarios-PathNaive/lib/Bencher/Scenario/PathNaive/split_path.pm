package Bencher::Scenario::PathNaive::split_path;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-02-10'; # DATE
our $DIST = 'Bencher-Scenarios-PathNaive'; # DIST
our $VERSION = '0.001'; # VERSION

our $scenario = {
    summary => 'Benchmark split_path()',
    participants => [
        {
            fcall_template => 'Path::Naive::split_path(<string>)',
            result_is_list => 1,
        },
        {
            name => 'split with /',
            code_template => 'split "/", <string>',
            result_is_list => 1,
        },
    ],
    datasets => [
        {args=>{string=>'/'}},
        {args=>{string=>'/a/b/c/d/e'}},
        {args=>{string=>'/a/b/////c/d/e'}},
    ],
};

1;
# ABSTRACT: Benchmark split_path()

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::PathNaive::split_path - Benchmark split_path()

=head1 VERSION

This document describes version 0.001 of Bencher::Scenario::PathNaive::split_path (from Perl distribution Bencher-Scenarios-PathNaive), released on 2020-02-10.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m PathNaive::split_path

To run module startup overhead benchmark:

 % bencher --module-startup -m PathNaive::split_path

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Path::Naive> 0.042

=head1 BENCHMARK PARTICIPANTS

=over

=item * Path::Naive::split_path (perl_code)

Function call template:

 Path::Naive::split_path(<string>)



=item * split with / (perl_code)

Code template:

 split "/", <string>



=back

=head1 BENCHMARK DATASETS

=over

=item * /

=item * /a/b/c/d/e

=item * /a/b/////c/d/e

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.30.0 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 19.04 >>, OS kernel: I<< Linux version 5.0.0-37-generic >>.

Benchmark with default options (C<< bencher -m PathNaive::split_path >>):

 #table1#
 +-------------------------+----------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant             | dataset        | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------------------+----------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | Path::Naive::split_path | /a/b/////c/d/e |    510000 |    2      |                 0.00% |              1639.52% | 3.3e-09 |      21 |
 | Path::Naive::split_path | /a/b/c/d/e     |    524090 |    1.9081 |                 2.44% |              1598.08% | 5.7e-12 |      20 |
 | Path::Naive::split_path | /              |   1300000 |    0.76   |               156.74% |               577.54% | 1.4e-09 |      29 |
 | split with /            | /a/b/////c/d/e |   1330000 |    0.754  |               159.27% |               570.92% | 3.8e-10 |      24 |
 | split with /            | /a/b/c/d/e     |   2123000 |    0.471  |               315.01% |               319.15% | 1.7e-11 |      20 |
 | split with /            | /              |   8900000 |    0.112  |              1639.52% |                 0.00% | 4.9e-11 |      23 |
 +-------------------------+----------------+-----------+-----------+-----------------------+-----------------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m PathNaive::split_path --module-startup >>):

 #table2#
 +---------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | participant         | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +---------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | Path::Naive         |       9.6 |               2.3 |                 0.00% |                31.03% | 1.2e-05 |      20 |
 | perl -e1 (baseline) |       7.3 |               0   |                31.03% |                 0.00% | 1.3e-05 |      20 |
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
