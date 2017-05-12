package Bencher::Scenario::DataModeMerge::Startup;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.003'; # VERSION

our $scenario = {
    summary => 'Benchmark module startup overhead of Data::ModeMerge',

    module_startup => 1,

    participants => [
        {module=>'Data::ModeMerge'},
    ],
};

1;
# ABSTRACT: Benchmark module startup overhead of Data::ModeMerge

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::DataModeMerge::Startup - Benchmark module startup overhead of Data::ModeMerge

=head1 VERSION

This document describes version 0.003 of Bencher::Scenario::DataModeMerge::Startup (from Perl distribution Bencher-Scenarios-DataModeMerge), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m DataModeMerge::Startup

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Data::ModeMerge> 0.35

=head1 BENCHMARK PARTICIPANTS

=over

=item * Data::ModeMerge (perl_code)

L<Data::ModeMerge>



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with C<< bencher -m DataModeMerge::Startup --include-path archive/0.22/lib --include-path archive/0.23/lib --include-path archive/0.26/lib --include-path archive/0.31/lib --include-path archive/0.32/lib --include-path archive/0.33/lib --include-path archive/0.34/lib --module-startup --multimodver Data::ModeMerge >>:

 #table1#
 +-------------------------+---------------+-----------+---------------------+--------+-----------+------------------------+------------+-----------+---------+
 | proc_private_dirty_size | proc_rss_size | proc_size | participant         | modver | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors   | samples |
 +-------------------------+---------------+-----------+---------------------+--------+-----------+------------------------+------------+-----------+---------+
 | 0.83                    | 4.1           | 16        | Data::ModeMerge     | 0.22   |     170   |                  168.1 |       1    |   0.00052 |      20 |
 | 0.832                   | 4.16          | 16        | Data::ModeMerge     | 0.26   |      34.7 |                   32.8 |       5.01 | 3.4e-05   |      20 |
 | 0.83                    | 4.1           | 16        | Data::ModeMerge     | 0.23   |      31   |                   29.1 |       5.6  | 7.7e-05   |      20 |
 | 0.84                    | 4.1           | 16        | Data::ModeMerge     | 0.31   |      16   |                   14.1 |      11    |   3e-05   |      20 |
 | 0.83                    | 4.1           | 16        | Data::ModeMerge     | 0.33   |       9.2 |                    7.3 |      19    | 3.1e-05   |      20 |
 | 0.83                    | 4.1           | 16        | Data::ModeMerge     | 0.35   |       7.2 |                    5.3 |      24    | 4.5e-05   |      20 |
 | 0.83                    | 4.1           | 16        | Data::ModeMerge     | 0.34   |       7.1 |                    5.2 |      24    | 3.6e-05   |      20 |
 | 0.84                    | 4.1           | 16        | Data::ModeMerge     | 0.32   |       7   |                    5.1 |      25    | 1.9e-05   |      20 |
 | 1.3                     | 4.8           | 16        | perl -e1 (baseline) |        |       1.9 |                    0   |      90    | 1.1e-05   |      20 |
 +-------------------------+---------------+-----------+---------------------+--------+-----------+------------------------+------------+-----------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-DataModeMerge>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-DataModeMerge>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-DataModeMerge>

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
