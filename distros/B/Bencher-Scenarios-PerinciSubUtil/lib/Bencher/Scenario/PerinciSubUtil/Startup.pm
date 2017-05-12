package Bencher::Scenario::PerinciSubUtil::Startup;

our $DATE = '2017-01-31'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark startup of Perinci::Sub::Util',
    modules => {
        'Perinci::Sub::Util' => {version=>'0.46'},
    },
    module_startup => 1,
    participants => [
        {
            module => 'Perinci::Sub::Util',
        },
    ],
};

1;
# ABSTRACT: Benchmark startup of Perinci::Sub::Util

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::PerinciSubUtil::Startup - Benchmark startup of Perinci::Sub::Util

=head1 VERSION

This document describes version 0.001 of Bencher::Scenario::PerinciSubUtil::Startup (from Perl distribution Bencher-Scenarios-PerinciSubUtil), released on 2017-01-31.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m PerinciSubUtil::Startup

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Perinci::Sub::Util> 0.46

=head1 BENCHMARK PARTICIPANTS

=over

=item * Perinci::Sub::Util (perl_code)

L<Perinci::Sub::Util>



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m PerinciSubUtil::Startup >>):

 #table1#
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | participant         | proc_private_dirty_size (kB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | Perinci::Sub::Util  | 844                          | 4.1                | 16             |       7.7 |                    3.9 |          1 | 3.8e-05 |      20 |
 | perl -e1 (baseline) | 1120                         | 4.5                | 16             |       3.8 |                    0   |          2 | 4.2e-06 |      21 |
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-PerinciSubUtil>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-PerinciSubUtil>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-PerinciSubUtil>

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
