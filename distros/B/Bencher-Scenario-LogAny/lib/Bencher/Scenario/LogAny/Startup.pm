package Bencher::Scenario::LogAny::Startup;

our $DATE = '2016-08-19'; # DATE
our $VERSION = '0.04'; # VERSION

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

This document describes version 0.04 of Bencher::Scenario::LogAny::Startup (from Perl distribution Bencher-Scenario-LogAny), released on 2016-08-19.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m LogAny::Startup

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Log::Any> 1.041

L<Log::Any::Adapter::Null> 1.041

L<Log::Any::Adapter::Screen> 0.12

L<Log::Any::Adapter::Stdout> 1.041

L<Log::Any::IfLOG> 0.08

L<Log::Any::Proxy> 1.041

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

Run on: perl: I<< v5.22.1 >>, CPU: I<< Intel(R) Core(TM) i5-2400 CPU @ 3.10GHz (4 cores) >>, OS: I<< GNU/Linux Debian version 8.0 >>, OS kernel: I<< Linux version 3.16.0-4-amd64 >>.

Benchmark with C<< bencher -m LogAny::Startup --include-path archive/Log-Any-1.040/lib --include-path archive/Log-Any-1.041/lib --multimodver Log::Any >>:

 #table1#
 +---------------------------+--------+-----------+------------------------+------------+---------+---------+
 | participant               | modver | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +---------------------------+--------+-----------+------------------------+------------+---------+---------+
 | Log::Any::Adapter::Screen |        |      11   |                    9.4 |        1   | 4.1e-05 |      20 |
 | Log::Any::Adapter::Null   |        |       9.8 |                    8.2 |        1.1 | 5.7e-05 |      24 |
 | Log::Any::Adapter::Stdout |        |       9.7 |                    8.1 |        1.1 | 3.3e-05 |      20 |
 | Log::Any::Proxy           |        |       9.1 |                    7.5 |        1.2 | 2.8e-05 |      20 |
 | Log::Any                  | 1.041  |       9   |                    7.4 |        1.2 | 6.3e-05 |      21 |
 | Log::Any                  | 1.040  |       7.9 |                    6.3 |        1.4 |   3e-05 |      20 |
 | Log::Any::IfLOG           |        |       1.9 |                    0.3 |        5.9 | 6.8e-06 |      21 |
 | perl -e1 (baseline)       |        |       1.6 |                    0   |        6.9 | 1.3e-05 |      20 |
 +---------------------------+--------+-----------+------------------------+------------+---------+---------+


Benchmark with C<< bencher -m LogAny::Startup --include-path archive/Log-Any-1.040/lib --include-path archive/Log-Any-1.041/lib --module-startup --multimodver Log::Any >>:

 #table2#
 +---------------------------+--------+-----------+------------------------+------------+-----------+---------+
 | participant               | modver | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors   | samples |
 +---------------------------+--------+-----------+------------------------+------------+-----------+---------+
 | Log::Any::Adapter::Null   |        |      10   |                    8   |        1   |   0.00012 |      20 |
 | Log::Any::Adapter::Screen |        |      11   |                    9   |        1   | 3.9e-05   |      20 |
 | Log::Any::Adapter::Stdout |        |       9.8 |                    7.8 |        1.1 | 3.1e-05   |      20 |
 | Log::Any::Proxy           |        |       9.1 |                    7.1 |        1.2 | 3.6e-05   |      20 |
 | Log::Any                  | 1.041  |       8.9 |                    6.9 |        1.2 | 2.9e-05   |      20 |
 | Log::Any                  | 1.040  |       7.9 |                    5.9 |        1.4 | 1.2e-05   |      20 |
 | perl -e1 (baseline)       |        |       2   |                    0   |        5   | 3.7e-05   |      21 |
 | Log::Any::IfLOG           |        |       1.8 |                   -0.2 |        6   | 9.1e-06   |      20 |
 +---------------------------+--------+-----------+------------------------+------------+-----------+---------+

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-LogAny>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-LogAny>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-LogAny>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
