package Bencher::Scenario::FileFlockRetry::Startup;

our $DATE = '2017-07-01'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark startup of File::Flock::Retry',
    participants => [
        {module=>'File::Flock'},
        {module=>'File::Flock::Retry'},
        {module=>'File::Flock::Tiny'},
    ],
    module_startup => 1,
};

1;
# ABSTRACT: Benchmark startup of File::Flock::Retry

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::FileFlockRetry::Startup - Benchmark startup of File::Flock::Retry

=head1 VERSION

This document describes version 0.001 of Bencher::Scenario::FileFlockRetry::Startup (from Perl distribution Bencher-Scenarios-FileFlockRetry), released on 2017-07-01.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m FileFlockRetry::Startup

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<File::Flock> 2014.01

L<File::Flock::Retry> 0.62

L<File::Flock::Tiny> 0.14

=head1 BENCHMARK PARTICIPANTS

=over

=item * File::Flock (perl_code)

L<File::Flock>



=item * File::Flock::Retry (perl_code)

L<File::Flock::Retry>



=item * File::Flock::Tiny (perl_code)

L<File::Flock::Tiny>



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) i7-4770 CPU @ 3.40GHz (4 cores) >>, OS: I<< GNU/Linux Debian version 8.5 >>, OS kernel: I<< Linux version 3.16.0-4-amd64 >>.

Benchmark with default options (C<< bencher -m FileFlockRetry::Startup >>):

 #table1#
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | participant         | proc_private_dirty_size (MB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | File::Flock         | 1.2                          | 4.6                | 22             |      19   |                   16.4 |        1   | 4.4e-05 |      22 |
 | File::Flock::Tiny   | 0.82                         | 4.1                | 20             |      11   |                    8.4 |        1.7 | 6.8e-05 |      20 |
 | File::Flock::Retry  | 2                            | 5.3                | 25             |       6.6 |                    4   |        3   | 4.7e-05 |      20 |
 | perl -e1 (baseline) | 3.4                          | 6.9                | 35             |       2.6 |                    0   |        7.5 | 1.4e-05 |      21 |
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-FileFlockRetry>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-FileFlockRetry>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-FileFlockRetry>

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
