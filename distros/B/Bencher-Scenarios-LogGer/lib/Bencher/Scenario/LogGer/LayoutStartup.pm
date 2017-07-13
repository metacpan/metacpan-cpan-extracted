package Bencher::Scenario::LogGer::LayoutStartup;

our $DATE = '2017-07-13'; # DATE
our $VERSION = '0.010'; # VERSION

use 5.010001;
use strict;
use warnings;

our %layout_modules = (
    Pattern => {format=>'[%d] %m'},
    LTSV => {},
    JSON => {},
    YAML => {},
);

our $scenario = {
    modules => {
    },
    participants => [
        {name=>"baseline", perl_cmdline => ["-e1"]},

        map {
            (
                +{
                    name => "load-$_",
                    module => "Log::ger::Layout::$_",
                    perl_cmdline => ["-mLog::ger::Layout::$_", "-e1"],
                },
            )
        } sort keys %layout_modules,
    ],
};

1;
# ABSTRACT:

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::LogGer::LayoutStartup

=head1 VERSION

This document describes version 0.010 of Bencher::Scenario::LogGer::LayoutStartup (from Perl distribution Bencher-Scenarios-LogGer), released on 2017-07-13.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m LogGer::LayoutStartup

To run module startup overhead benchmark:

 % bencher --module-startup -m LogGer::LayoutStartup

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Log::ger::Layout::JSON> 0.001

L<Log::ger::Layout::LTSV> 0.001

L<Log::ger::Layout::Pattern> 0.001

L<Log::ger::Layout::YAML> 0.001

=head1 BENCHMARK PARTICIPANTS

=over

=item * baseline (command)



=item * load-JSON (command)

L<Log::ger::Layout::JSON>



=item * load-LTSV (command)

L<Log::ger::Layout::LTSV>



=item * load-Pattern (command)

L<Log::ger::Layout::Pattern>



=item * load-YAML (command)

L<Log::ger::Layout::YAML>



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m LogGer::LayoutStartup >>):

 #table1#
 +--------------+-----------+-----------+------------+----------+---------+
 | participant  | rate (/s) | time (ms) | vs_slowest |  errors  | samples |
 +--------------+-----------+-----------+------------+----------+---------+
 | load-JSON    |      60   |      17   |       1    | 5.3e-05  |      20 |
 | load-YAML    |      61   |      16   |       1    |   4e-05  |      20 |
 | load-LTSV    |      62   |      16   |       1    |   0.0001 |      20 |
 | load-Pattern |      64.9 |      15.4 |       1.08 | 8.9e-06  |      20 |
 | baseline     |     160   |       6.3 |       2.6  | 2.4e-05  |      20 |
 +--------------+-----------+-----------+------------+----------+---------+


Benchmark module startup overhead (C<< bencher -m LogGer::LayoutStartup --module-startup >>):

 #table2#
 +---------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | participant               | proc_private_dirty_size (MB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +---------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | Log::ger::Layout::JSON    | 1.6                          | 5                  | 21             |      17   |                   10.2 |       1    | 5.7e-05 |      20 |
 | Log::ger::Layout::YAML    | 1.6                          | 5.02               | 20.7           |      16.3 |                    9.5 |       1.02 | 4.7e-06 |      20 |
 | Log::ger::Layout::Pattern | 1.6                          | 5                  | 21             |      16   |                    9.2 |       1    | 6.9e-05 |      20 |
 | Log::ger::Layout::LTSV    | 1.6                          | 4.9                | 21             |      16   |                    9.2 |       1.1  | 2.4e-05 |      20 |
 | perl -e1 (baseline)       | 0.82                         | 4.1                | 16             |       6.8 |                    0   |       2.4  | 2.9e-05 |      20 |
 +---------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-LogGer>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-LogGer>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-LogGer>

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
