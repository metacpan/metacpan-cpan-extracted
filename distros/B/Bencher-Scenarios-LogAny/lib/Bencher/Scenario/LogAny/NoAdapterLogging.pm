package Bencher::Scenario::LogAny::NoAdapterLogging;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.08'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark Log::Any logging speed when no adapter has been configured',
    participants => [
        {
            name => '100k_log_trace',
            perl_cmdline_template => ['-MLog::Any', '-e', 'my $log = Log::Any->get_logger; for(1..100_000) { $log->trace(q[]) }'],
        },
        {
            name => '100k_is_trace' ,
            perl_cmdline_template => ['-MLog::Any', '-e', 'my $log = Log::Any->get_logger; for(1..100_000) { $log->is_trace }'],
        },
    ],
};

1;
# ABSTRACT: Benchmark Log::Any logging speed when no adapter has been configured

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::LogAny::NoAdapterLogging - Benchmark Log::Any logging speed when no adapter has been configured

=head1 VERSION

This document describes version 0.08 of Bencher::Scenario::LogAny::NoAdapterLogging (from Perl distribution Bencher-Scenarios-LogAny), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m LogAny::NoAdapterLogging

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARK PARTICIPANTS

=over

=item * 100k_log_trace (command)

Command line:

 #TEMPLATE: #perl -MLog::Any -e my $log = Log::Any->get_logger; for(1..100_000) { $log->trace(q[]) }



=item * 100k_is_trace (command)

Command line:

 #TEMPLATE: #perl -MLog::Any -e my $log = Log::Any->get_logger; for(1..100_000) { $log->is_trace }



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with C<< bencher -m LogAny::NoAdapterLogging --env-hashes-json '[{"PERL5OPT":"-Iarchive/Log-Any-1.040/lib"},{"PERL5OPT":"-Iarchive/Log-Any-1.041/lib"}]' >>:

 #table1#
 +----------------+--------------------------------------+-----------+-----------+------------+-----------+---------+
 | participant    | env                                  | rate (/s) | time (ms) | vs_slowest |  errors   | samples |
 +----------------+--------------------------------------+-----------+-----------+------------+-----------+---------+
 | 100k_log_trace | PERL5OPT=-Iarchive/Log-Any-1.040/lib |        15 |        65 |        1   |   0.00017 |      20 |
 | 100k_is_trace  | PERL5OPT=-Iarchive/Log-Any-1.041/lib |        23 |        44 |        1.5 |   0.00011 |      20 |
 | 100k_is_trace  | PERL5OPT=-Iarchive/Log-Any-1.040/lib |        23 |        44 |        1.5 |   0.00012 |      22 |
 | 100k_log_trace | PERL5OPT=-Iarchive/Log-Any-1.041/lib |        43 |        23 |        2.8 | 7.6e-05   |      20 |
 +----------------+--------------------------------------+-----------+-----------+------------+-----------+---------+


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
