package Bencher::Scenario::LogAny;

our $DATE = '2016-08-19'; # DATE
our $VERSION = '0.04'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark Log::Any',

    description => <<'_',

Early release. Todos include: benchmark enabled level, adapters, string
formatting.

_

    participants => [
        {
            name => 'log_trace',
            module => 'Log::Any',
            code_template => 'state $log = do { require Log::Any; require Log::Any::Adapter; Log::Any::Adapter->set("Null"); Log::Any->get_logger }; $log->trace("")',
        },
        {
            name => 'if_trace' ,
            module => 'Log::Any',
            code_template => 'state $log = do { require Log::Any; require Log::Any::Adapter; Log::Any::Adapter->set("Null"); Log::Any->get_logger }; if ($log->is_trace) {}'},
    ],
};

1;
# ABSTRACT: Benchmark Log::Any

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::LogAny - Benchmark Log::Any

=head1 VERSION

This document describes version 0.04 of Bencher::Scenario::LogAny (from Perl distribution Bencher-Scenario-LogAny), released on 2016-08-19.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m LogAny

To run module startup overhead benchmark:

 % bencher --module-startup -m LogAny

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Log::Any> 1.041

=head1 BENCHMARK PARTICIPANTS

=over

=item * log_trace (perl_code)

Code template:

 state $log = do { require Log::Any; require Log::Any::Adapter; Log::Any::Adapter->set("Null"); Log::Any->get_logger }; $log->trace("")



=item * if_trace (perl_code)

Code template:

 state $log = do { require Log::Any; require Log::Any::Adapter; Log::Any::Adapter->set("Null"); Log::Any->get_logger }; if ($log->is_trace) {}



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.22.1 >>, CPU: I<< Intel(R) Core(TM) i5-2400 CPU @ 3.10GHz (4 cores) >>, OS: I<< GNU/Linux Debian version 8.0 >>, OS kernel: I<< Linux version 3.16.0-4-amd64 >>.

Benchmark with C<< bencher -m LogAny --include-path archive/Log-Any-1.040/lib --include-path archive/Log-Any-1.041/lib --multimodver Log::Any >>:

 #table1#
 +-------------+--------+-----------+-----------+------------+---------+---------+
 | participant | modver | rate (/s) | time (ns) | vs_slowest |  errors | samples |
 +-------------+--------+-----------+-----------+------------+---------+---------+
 | log_trace   | 1.040  |   1430000 |     701   |      1     | 9.2e-11 |      20 |
 | log_trace   | 1.041  |   1500000 |     680   |      1     | 4.3e-09 |      21 |
 | if_trace    | 1.041  |   1898000 |     526.8 |      1.331 | 4.4e-11 |      20 |
 | if_trace    | 1.040  |   1910000 |     523   |      1.34  | 2.3e-10 |      20 |
 +-------------+--------+-----------+-----------+------------+---------+---------+


Benchmark with C<< bencher -m LogAny --include-path archive/Log-Any-1.040/lib --include-path archive/Log-Any-1.041/lib --module-startup --multimodver Log::Any >>:

 #table2#
 +---------------------+--------+-----------+------------------------+------------+---------+---------+
 | participant         | modver | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +---------------------+--------+-----------+------------------------+------------+---------+---------+
 | Log::Any            | 1.041  |       9   |                    7.5 |        1   | 2.9e-05 |      20 |
 | Log::Any            | 1.040  |       8   |                    6.5 |        1.1 | 1.8e-05 |      21 |
 | perl -e1 (baseline) |        |       1.5 |                    0   |        6   | 1.1e-05 |      20 |
 +---------------------+--------+-----------+------------------------+------------+---------+---------+

=head1 DESCRIPTION

Early release. Todos include: benchmark enabled level, adapters, string
formatting.


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
