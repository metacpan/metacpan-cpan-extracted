package Bencher::Scenario::LogAny::Startup;

our $DATE = '2017-07-10'; # DATE
our $VERSION = '0.09'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    module_startup => 1,
    modules => {
    },
    participants => [
        {module => 'Log::Any'},
        {module => 'Log::Any::Adapter::Null'},
        {module => 'Log::Any::Adapter::Screen'},
        {module => 'Log::Any::Adapter::Stdout'},
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

This document describes version 0.09 of Bencher::Scenario::LogAny::Startup (from Perl distribution Bencher-Scenarios-LogAny), released on 2017-07-10.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m LogAny::Startup

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Log::Any> 1.049

L<Log::Any::Adapter::Null> 1.049

L<Log::Any::Adapter::Screen> 0.13

L<Log::Any::Adapter::Stdout> 1.049

L<Log::Any::Proxy> 1.049

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



=item * Log::Any::Proxy (perl_code)

L<Log::Any::Proxy>



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.26.0 >>, CPU: I<< Intel(R) Core(TM) i5-2400 CPU @ 3.10GHz (4 cores) >>, OS: I<< GNU/Linux Debian version 8.0 >>, OS kernel: I<< Linux version 3.16.0-4-amd64 >>.

Benchmark with C<< bencher -m LogAny::Startup --include-path archive/Log-Any-0.15/lib --include-path archive/Log-Any-1.032/lib --include-path archive/Log-Any-1.038/lib --include-path archive/Log-Any-1.040/lib --include-path archive/Log-Any-1.041/lib --multimodver Log::Any >>:

 #table1#
 +-------------------------+---------------+-----------+---------------------------+--------+-----------+------------------------+------------+---------+---------+
 | proc_private_dirty_size | proc_rss_size | proc_size | participant               | modver | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +-------------------------+---------------+-----------+---------------------------+--------+-----------+------------------------+------------+---------+---------+
 | 1.6                     | 5             | 21        | Log::Any                  | 1.032  |      17   |                   15.1 |        1   | 6.1e-05 |      20 |
 | 1.6                     | 5             | 21        | Log::Any::Adapter::Screen |        |      13   |                   11.1 |        1.3 | 2.7e-05 |      20 |
 | 1.5                     | 5             | 21        | Log::Any::Adapter::Stdout |        |      12   |                   10.1 |        1.4 | 4.9e-05 |      20 |
 | 1.7                     | 5.2           | 21        | Log::Any::Adapter::Null   |        |      12   |                   10.1 |        1.4 | 3.7e-05 |      20 |
 | 1.6                     | 5.1           | 21        | Log::Any                  | 1.049  |      11   |                    9.1 |        1.5 | 6.4e-05 |      20 |
 | 0.83                    | 4.2           | 20        | Log::Any::Proxy           |        |      11   |                    9.1 |        1.5 | 4.1e-05 |      20 |
 | 1.6                     | 5.1           | 21        | Log::Any                  | 1.041  |       9.5 |                    7.6 |        1.8 | 3.4e-05 |      20 |
 | 1.6                     | 5             | 21        | Log::Any                  | 1.040  |       8.3 |                    6.4 |        2   | 4.7e-05 |      20 |
 | 1.6                     | 5             | 21        | Log::Any                  | 1.038  |       8.1 |                    6.2 |        2   | 3.3e-05 |      20 |
 | 1.6                     | 5             | 21        | Log::Any                  | 0.15   |       4.9 |                    3   |        3.4 | 1.2e-05 |      20 |
 | 1.5                     | 5             | 21        | perl -e1 (baseline)       |        |       1.9 |                    0   |        9   | 1.6e-05 |      20 |
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

This software is copyright (c) 2017, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
