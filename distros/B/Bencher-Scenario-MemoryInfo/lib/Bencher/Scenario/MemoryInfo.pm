package Bencher::Scenario::MemoryInfo;

our $DATE = '2017-11-19'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark getting system memory information',

    participants => [
        {fcall_template => 'Sys::MemInfo::freemem()'},
        {fcall_template => 'Linux::MemInfo::get_mem_info()'},
        {module => 'Linux::Info::MemStats', code_template=>'my $lxs = Linux::Info::MemStats->new; $lxs->get'},
    ],
};

1;
# ABSTRACT: Benchmark getting system memory information

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::MemoryInfo - Benchmark getting system memory information

=head1 VERSION

This document describes version 0.001 of Bencher::Scenario::MemoryInfo (from Perl distribution Bencher-Scenario-MemoryInfo), released on 2017-11-19.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m MemoryInfo

To run module startup overhead benchmark:

 % bencher --module-startup -m MemoryInfo

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Sys::MemInfo> 0.99

L<Linux::MemInfo> 0.03

L<Linux::Info::MemStats> 1.3

=head1 BENCHMARK PARTICIPANTS

=over

=item * Sys::MemInfo::freemem (perl_code)

Function call template:

 Sys::MemInfo::freemem()



=item * Linux::MemInfo::get_mem_info (perl_code)

Function call template:

 Linux::MemInfo::get_mem_info()



=item * Linux::Info::MemStats (perl_code)

Code template:

 my $lxs = Linux::Info::MemStats->new; $lxs->get



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 18.2 >>, OS kernel: I<< Linux version 4.8.0-53-generic >>.

Benchmark with default options (C<< bencher -m MemoryInfo >>):

 #table1#
 +------------------------------+-----------+-----------+------------+---------+---------+
 | participant                  | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +------------------------------+-----------+-----------+------------+---------+---------+
 | Linux::MemInfo::get_mem_info |     11000 |    90     |        1   | 1.1e-07 |      29 |
 | Linux::Info::MemStats        |     17000 |    58     |        1.5 | 1.2e-07 |      24 |
 | Sys::MemInfo::freemem        |   4426000 |     0.226 |      397.6 | 1.2e-11 |      22 |
 +------------------------------+-----------+-----------+------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m MemoryInfo --module-startup >>):

 #table2#
 +-----------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | participant           | proc_private_dirty_size (MB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +-----------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | Linux::Info::MemStats | 0.82                         | 4.2                | 16             |      11   |                    5.8 |        1   | 4.4e-05 |      20 |
 | Sys::MemInfo          | 1                            | 4.6                | 16             |      11   |                    5.8 |        1   | 5.7e-05 |      20 |
 | Linux::MemInfo        | 1.3                          | 4.8                | 16             |       9.4 |                    4.2 |        1.1 | 5.4e-05 |      20 |
 | perl -e1 (baseline)   | 1.2                          | 4.7                | 18             |       5.2 |                    0   |        2.1 |   1e-05 |      20 |
 +-----------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-MemoryInfo>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-MemoryInfo>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-MemoryInfo>

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
