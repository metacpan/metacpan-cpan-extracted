package Bencher::Scenario::LogAny::Startup;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.08'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    module_startup => 1,
    modules => {
        'Log::Any::IfLOG' => {version=>0.07},
    },
    participants => [
        {module => 'Log::Any'},
        {module => 'Log::Any::Adapter::Null'},
        {module => 'Log::Any::Adapter::Screen'},
        {module => 'Log::Any::Adapter::Stdout'},
        {module => 'Log::Any::IfLOG'},
        {module => 'Log::Any::Proxy'},
    ],
};

1;
# ABSTRACT:

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::LogAny::Startup

=head1 VERSION

This document describes version 0.08 of Bencher::Scenario::LogAny::Startup (from Perl distribution Bencher-Scenarios-LogAny), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m LogAny::Startup

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Log::Any> 1.042

L<Log::Any::Adapter::Null> 1.042

L<Log::Any::Adapter::Screen> 0.13

L<Log::Any::Adapter::Stdout> 1.042

L<Log::Any::IfLOG> 0.08

L<Log::Any::Proxy> 1.042

=head1 BENCHMARK PARTICIPANTS

=over

=item * Log::Any (perl_code)

L<Log::Any>



=item * Log::Any::Adapter::Null (perl_code)

L<Log::Any::Adapter::Null>



=item * Log::Any::Adapter::Screen (perl_code)

L<Log::Any::Adapter::Screen>



=item * Log::Any::Adapter::Stdout (perl_code)

L<Log::Any::Adapter::Stdout>



=item * Log::Any::IfLOG (perl_code)

L<Log::Any::IfLOG>



=item * Log::Any::Proxy (perl_code)

L<Log::Any::Proxy>



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with C<< bencher -m LogAny::Startup --include-path archive/Log-Any-0.15/lib --include-path archive/Log-Any-1.032/lib --include-path archive/Log-Any-1.038/lib --include-path archive/Log-Any-1.040/lib --include-path archive/Log-Any-1.041/lib --multimodver Log::Any >>:

 #table1#
 +-------------------------+---------------+-----------+---------------------------+--------+-----------+------------------------+------------+---------+---------+
 | proc_private_dirty_size | proc_rss_size | proc_size | participant               | modver | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +-------------------------+---------------+-----------+---------------------------+--------+-----------+------------------------+------------+---------+---------+
 | 1.4                     | 4.8           | 17        | Log::Any                  | 1.032  |      16   |                   14.1 |        1   | 6.5e-05 |      21 |
 | 1.4                     | 4.7           | 17        | Log::Any::Adapter::Screen |        |      11   |                    9.1 |        1.5 | 3.1e-05 |      20 |
 | 0.86                    | 4.1           | 16        | Log::Any::Adapter::Stdout |        |       9.8 |                    7.9 |        1.6 | 5.2e-05 |      21 |
 | 1.6                     | 5             | 17        | Log::Any::Adapter::Null   |        |       9.4 |                    7.5 |        1.7 | 1.6e-05 |      22 |
 | 0.82                    | 4.1           | 16        | Log::Any::Proxy           |        |       8.9 |                    7   |        1.8 | 4.5e-05 |      20 |
 | 1.4                     | 4.9           | 17        | Log::Any                  | 1.041  |       8.8 |                    6.9 |        1.8 | 5.2e-05 |      20 |
 | 1.4                     | 4.7           | 17        | Log::Any                  | 1.042  |       8.8 |                    6.9 |        1.8 | 4.7e-05 |      20 |
 | 1.4                     | 4.8           | 17        | Log::Any                  | 1.038  |       7.7 |                    5.8 |        2   | 3.3e-05 |      20 |
 | 1.5                     | 4.7           | 17        | Log::Any                  | 1.040  |       7.7 |                    5.8 |        2.1 | 4.3e-05 |      20 |
 | 1.5                     | 4.8           | 17        | Log::Any                  | 0.15   |       4.7 |                    2.8 |        3.3 | 2.7e-05 |      20 |
 | 1.4                     | 4.7           | 17        | Log::Any::IfLOG           |        |       2.3 |                    0.4 |        6.7 | 5.5e-06 |      20 |
 | 1.4                     | 4.7           | 17        | perl -e1 (baseline)       |        |       1.9 |                    0   |        8.4 | 1.2e-05 |      20 |
 +-------------------------+---------------+-----------+---------------------------+--------+-----------+------------------------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-LogAny>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-LogAny>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-LogAny>

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
