package Bencher::Scenario::FileWriteRotate::Startup;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.002'; # VERSION

use strict;
use warnings;

use File::Temp;

our $scenario = {
    participants => [
        {
            module => 'File::Write::Rotate',
        },
        {
            module => 'Log::Dispatch::FileRotate',
        },
    ],
    module_startup => 1,
};

1;
# ABSTRACT:

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::FileWriteRotate::Startup

=head1 VERSION

This document describes version 0.002 of Bencher::Scenario::FileWriteRotate::Startup (from Perl distribution Bencher-Scenarios-FileWriteRotate), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m FileWriteRotate::Startup

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<File::Write::Rotate> 0.31

L<Log::Dispatch::FileRotate> 1.19

=head1 BENCHMARK PARTICIPANTS

=over

=item * File::Write::Rotate (perl_code)

L<File::Write::Rotate>



=item * Log::Dispatch::FileRotate (perl_code)

L<Log::Dispatch::FileRotate>



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m FileWriteRotate::Startup >>):

 #table1#
 +---------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | participant               | proc_private_dirty_size (MB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +---------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | Log::Dispatch::FileRotate | 0.82                         | 4                  | 16             |      91   |                   84.6 |        1   | 0.00028 |      20 |
 | File::Write::Rotate       | 13                           | 17                 | 47             |      41   |                   34.6 |        2.2 | 0.00011 |      20 |
 | perl -e1 (baseline)       | 4.8                          | 8.5                | 38             |       6.4 |                    0   |       14   | 2e-05   |      20 |
 +---------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-FileWriteRotate>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-FileWriteRotate>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-FileWriteRotate>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
