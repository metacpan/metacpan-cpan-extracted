package Bencher::Scenario::DataCSel::Parsing;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.04'; # VERSION

our $scenario = {
    summary => 'Benchmark parsing speed',
    modules => {
        'Data::CSel' => {version => '0.04'},
    },
    participants => [
        { fcall_template => 'Data::CSel::parse_csel(<expr>)' },
    ],
    datasets => [
        {args=>{expr=>'*'}},
        {args=>{expr=>'T'}},
        {args=>{expr=>'T T2 T3 T4 T5'}},
        {args=>{expr=>'T ~ T ~ T ~ T ~ T'}},
        {args=>{expr=>':has(T[length > 1])'}},
    ],
};

1;
# ABSTRACT: Benchmark parsing speed

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::DataCSel::Parsing - Benchmark parsing speed

=head1 VERSION

This document describes version 0.04 of Bencher::Scenario::DataCSel::Parsing (from Perl distribution Bencher-Scenarios-DataCSel), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m DataCSel::Parsing

To run module startup overhead benchmark:

 % bencher --module-startup -m DataCSel::Parsing

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Data::CSel> 0.11

=head1 BENCHMARK PARTICIPANTS

=over

=item * Data::CSel::parse_csel (perl_code)

Function call template:

 Data::CSel::parse_csel(<expr>)



=back

=head1 BENCHMARK DATASETS

=over

=item * *

=item * T

=item * T T2 T3 T4 T5

=item * T ~ T ~ T ~ T ~ T

=item * :has(T[length > 1])

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m DataCSel::Parsing >>):

 #table1#
 +---------------------+-----------+-----------+------------+---------+---------+
 | dataset             | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +---------------------+-----------+-----------+------------+---------+---------+
 | :has(T[length > 1]) |     20000 |      49   |        1   | 5.3e-08 |      20 |
 | T ~ T ~ T ~ T ~ T   |     34000 |      29   |        1.7 | 5.3e-08 |      20 |
 | T T2 T3 T4 T5       |     36000 |      28   |        1.7 | 5.3e-08 |      20 |
 | T                   |    140000 |       7.4 |        6.6 | 1.3e-08 |      20 |
 | *                   |    140000 |       7.1 |        6.9 | 1.3e-08 |      20 |
 +---------------------+-----------+-----------+------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m DataCSel::Parsing --module-startup >>):

 #table2#
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | participant         | proc_private_dirty_size (MB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | Data::CSel          | 0.82                         | 4.2                | 16             |      12   |                    6.5 |        1   | 2.1e-05 |      20 |
 | perl -e1 (baseline) | 1.6                          | 4.9                | 19             |       5.5 |                    0   |        2.3 | 1.8e-05 |      20 |
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-DataCSel>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-DataCSel>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-DataCSel>

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
