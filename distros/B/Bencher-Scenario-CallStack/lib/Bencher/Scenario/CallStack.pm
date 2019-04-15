package Bencher::Scenario::CallStack;

our $DATE = '2019-04-14'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark different methods to produce call stack',
    participants => [
        {
            name => 'Devel::Caller::Util::callers',
            fcall_template => 'Devel::Caller::Util::callers()',
            result_is_list => 1,
        },
        {
            name => 'Devel::Caller::Util::callers with-args',
            fcall_template => 'Devel::Caller::Util::callers(0, 1)',
            result_is_list => 1,
        },
        {
            fcall_template => 'Carp::ret_backtrace()',
        },
    ],
};

1;
# ABSTRACT: Benchmark different methods to produce call stack

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::CallStack - Benchmark different methods to produce call stack

=head1 VERSION

This document describes version 0.001 of Bencher::Scenario::CallStack (from Perl distribution Bencher-Scenario-CallStack), released on 2019-04-14.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m CallStack

To run module startup overhead benchmark:

 % bencher --module-startup -m CallStack

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Devel::Caller::Util> 0.042

L<Carp> 1.42

=head1 BENCHMARK PARTICIPANTS

=over

=item * Devel::Caller::Util::callers (perl_code)

Function call template:

 Devel::Caller::Util::callers()



=item * Devel::Caller::Util::callers with-args (perl_code)

Function call template:

 Devel::Caller::Util::callers(0, 1)



=item * Carp::ret_backtrace (perl_code)

Function call template:

 Carp::ret_backtrace()



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.26.1 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 18.3 >>, OS kernel: I<< Linux version 4.10.0-38-generic >>.

Benchmark with default options (C<< bencher -m CallStack >>):

 #table1#
 +----------------------------------------+-----------+-----------+------------+---------+---------+
 | participant                            | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +----------------------------------------+-----------+-----------+------------+---------+---------+
 | Carp::ret_backtrace                    |      2150 |       465 |        1   | 4.6e-07 |      22 |
 | Devel::Caller::Util::callers with-args |     18000 |        55 |        8.5 |   1e-07 |      22 |
 | Devel::Caller::Util::callers           |     25700 |        39 |       11.9 | 1.3e-08 |      20 |
 +----------------------------------------+-----------+-----------+------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m CallStack --module-startup >>):

 #table2#
 +---------------------+-----------+------------------------+------------+---------+---------+
 | participant         | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +---------------------+-----------+------------------------+------------+---------+---------+
 | Carp                |       9   |                    4.1 |        1   | 1.2e-05 |      20 |
 | Devel::Caller::Util |       7.2 |                    2.3 |        1.2 | 1.5e-05 |      20 |
 | perl -e1 (baseline) |       4.9 |                    0   |        1.8 | 1.6e-05 |      22 |
 +---------------------+-----------+------------------------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-CallStack>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-CallStack>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-CallStack>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
