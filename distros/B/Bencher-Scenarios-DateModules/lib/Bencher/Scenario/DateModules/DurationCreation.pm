package Bencher::Scenario::DateModules::DurationCreation;

our $DATE = '2017-08-27'; # DATE
our $VERSION = '0.004'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark duration creation',
    participants => [
        {
            name => 'DateTime::Duration->new',
            fcall_template => 'DateTime::Duration->new(months=>1, days=>2, minutes=>3, seconds=>4, nanoseconds=>5)',
        },
    ],
    with_result_size => 1,
};

1;
# ABSTRACT: Benchmark duration creation

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::DateModules::DurationCreation - Benchmark duration creation

=head1 VERSION

This document describes version 0.004 of Bencher::Scenario::DateModules::DurationCreation (from Perl distribution Bencher-Scenarios-DateModules), released on 2017-08-27.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m DateModules::DurationCreation

To run module startup overhead benchmark:

 % bencher --module-startup -m DateModules::DurationCreation

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<DateTime::Duration> 1.36

=head1 BENCHMARK PARTICIPANTS

=over

=item * DateTime::Duration->new (perl_code)

Function call template:

 DateTime::Duration->new(months=>1, days=>2, minutes=>3, seconds=>4, nanoseconds=>5)



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m DateModules::DurationCreation >>):

 #table1#
 +-------------------------+---------+--------+------+-----------+-----------+------------+-----------------+---------+---------+
 | participant             | ds_tags | p_tags | perl | rate (/s) | time (μs) | vs_slowest | result_size (b) |  errors | samples |
 +-------------------------+---------+--------+------+-----------+-----------+------------+-----------------+---------+---------+
 | DateTime::Duration->new |         |        | perl |     53000 |        19 |          1 |             751 | 2.6e-08 |      21 |
 +-------------------------+---------+--------+------+-----------+-----------+------------+-----------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m DateModules::DurationCreation --module-startup >>):

 #table2#
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+----------+---------+
 | participant         | proc_private_dirty_size (MB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors  | samples |
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+----------+---------+
 | DateTime::Duration  | 0.82                         | 4.2                | 16             |      60   |                   55.7 |          1 |   0.0002 |      20 |
 | perl -e1 (baseline) | 11                           | 15                 | 44             |       4.3 |                    0   |         14 | 7.6e-06  |      20 |
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+----------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-DateModules>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-DateModules>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-DateModules>

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
