package Bencher::Scenario::DataSah::normalize_schema;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.07'; # VERSION

# TODO: benchmark normalize_clset

our $scenario = {
    summary => 'Benchmark normalizing Sah schema',
    participants => [
        {
            fcall_template => 'Data::Sah::Normalize::normalize_schema(<schema>)'
        },
    ],
    datasets => [

        {
            name    => 'str',
            summary => '',
            args    => {
                schema => 'str',
            },
        },

        {
            name => 'str_wildcard',
            args => {
                schema => 'str*',
            },
        },

        {
            name => 'array1',
            args => {
                schema => ['str'],
            },
        },

        {
            name => 'array3',
            args => {
                schema => ['str', len=>1],
            },
        },

        {
            name => 'array5',
            args => {
                schema => ['str', min_len=>8, max_len=>16],
            },
        },

    ],
};

1;
# ABSTRACT: Benchmark normalizing Sah schema

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::DataSah::normalize_schema - Benchmark normalizing Sah schema

=head1 VERSION

This document describes version 0.07 of Bencher::Scenario::DataSah::normalize_schema (from Perl distribution Bencher-Scenarios-DataSah), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m DataSah::normalize_schema

To run module startup overhead benchmark:

 % bencher --module-startup -m DataSah::normalize_schema

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Data::Sah::Normalize> 0.04

=head1 BENCHMARK PARTICIPANTS

=over

=item * Data::Sah::Normalize::normalize_schema (perl_code)

Function call template:

 Data::Sah::Normalize::normalize_schema(<schema>)



=back

=head1 BENCHMARK DATASETS

=over

=item * str

=item * str_wildcard

=item * array1

=item * array3

=item * array5

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m DataSah::normalize_schema >>):

 #table1#
 +--------------+-----------+-----------+------------+---------+---------+
 | dataset      | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +--------------+-----------+-----------+------------+---------+---------+
 | array5       |    120000 |    8.4    |     1      |   1e-08 |      20 |
 | array3       |    160000 |    6.4    |     1.3    | 1.3e-08 |      20 |
 | array1       |    348000 |    2.87   |     2.92   | 2.5e-09 |      20 |
 | str_wildcard |    551990 |    1.8116 |     4.6271 | 1.2e-11 |      23 |
 | str          |    720000 |    1.4    |     6      | 3.4e-09 |      20 |
 +--------------+-----------+-----------+------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m DataSah::normalize_schema --module-startup >>):

 #table2#
 +----------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | participant          | proc_private_dirty_size (kB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +----------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | Data::Sah::Normalize | 840                          | 4                  | 20             |        10 |                      4 |          1 | 0.00034 |      20 |
 | perl -e1 (baseline)  | 1048                         | 4                  | 20             |         6 |                      0 |          2 | 0.00013 |      20 |
 +----------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-DataSah>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-DataSah>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-DataSah>

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
