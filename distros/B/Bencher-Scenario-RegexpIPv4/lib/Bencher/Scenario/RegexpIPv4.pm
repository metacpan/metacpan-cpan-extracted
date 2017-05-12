package Bencher::Scenario::RegexpIPv4;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark matching IPv4 address',
    participants => [
        {
            module=>'Regexp::IPv4',
            code_template => '<ip> =~ $Regexp::IPv4::IPv4_re'
        },
    ],
    datasets => [
        {args=>{ip=>'127.0.0.1'}},

        {args=>{ip=>'ff02::1'}},
        {args=>{ip=>'2001:cdba:0000:0000:0000:0000:3257:9652'}},
    ],
};

1;
# ABSTRACT: Benchmark matching IPv4 address

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::RegexpIPv4 - Benchmark matching IPv4 address

=head1 VERSION

This document describes version 0.002 of Bencher::Scenario::RegexpIPv4 (from Perl distribution Bencher-Scenario-RegexpIPv4), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m RegexpIPv4

To run module startup overhead benchmark:

 % bencher --module-startup -m RegexpIPv4

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Regexp::IPv4> 0.003

=head1 BENCHMARK PARTICIPANTS

=over

=item * Regexp::IPv4 (perl_code)

Code template:

 <ip> =~ $Regexp::IPv4::IPv4_re



=back

=head1 BENCHMARK DATASETS

=over

=item * 127.0.0.1

=item * ff02::1

=item * 2001:cdba:0000:0000:0000:0000:3257:9652

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m RegexpIPv4 >>):

 #table1#
 +-----------------------------------------+-----------+-----------+------------+---------+---------+
 | dataset                                 | rate (/s) | time (ns) | vs_slowest |  errors | samples |
 +-----------------------------------------+-----------+-----------+------------+---------+---------+
 | 127.0.0.1                               |   1130000 |       885 |        1   | 4.2e-10 |      20 |
 | ff02::1                                 |   3900000 |       250 |        3.5 | 4.2e-10 |      20 |
 | 2001:cdba:0000:0000:0000:0000:3257:9652 |   4000000 |       250 |        3.5 | 5.2e-10 |      20 |
 +-----------------------------------------+-----------+-----------+------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m RegexpIPv4 --module-startup >>):

 #table2#
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | participant         | proc_private_dirty_size (kB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | Regexp::IPv4        | 840                          | 4.1                | 16             |       9.1 |                    3.3 |        1   | 6.9e-05 |      20 |
 | perl -e1 (baseline) | 932                          | 4.2                | 16             |       5.8 |                    0   |        1.6 | 1.6e-05 |      20 |
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-RegexpIPv4>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-RegexpIPv4>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-RegexpIPv4>

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
