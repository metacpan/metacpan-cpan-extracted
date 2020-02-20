package Bencher::Scenario::DataThrottling;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-02-19'; # DATE
our $DIST = 'Bencher-Scenario-DataThrottling'; # DIST
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark modules that do throttling',
    participants => [
        {
            name => 'Data::Throttler (Memory backend)',
            module => 'Data::Throttler',
            code_template => 'my $t = Data::Throttler->new(max_items=><max_items>, interval=><interval>); for (1..<inserts>) { $t->try_push }',
        },
        # XXX Data::Valve currently not installable from CPAN
        {
            name => 'Data::Throttler_CHI (Memory backend)',
            module => 'Data::Throttler_CHI',
            code_template => 'require CHI; my $t = Data::Throttler_CHI->new(max_items=><max_items>, interval=><interval>, cache=>CHI->new(driver=>"Memory", datastore=>{})); for (1..<inserts>) { $t->try_push }',
        },
    ],
    datasets => [
        {name=>'max_items=1000, interval=3600, inserts/checks=1000', args=>{max_items=>1000, interval=>3600, inserts=>1000}},
        {name=>'max_items=100, interval=3600, inserts/checks=100', args=>{max_items=>100, interval=>3600, inserts=>100}},
        {name=>'max_items=10, interval=3600, inserts/checks=10', args=>{max_items=>10, interval=>3600, inserts=>10}},
    ],
};

1;
# ABSTRACT: Benchmark modules that do throttling

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::DataThrottling - Benchmark modules that do throttling

=head1 VERSION

This document describes version 0.001 of Bencher::Scenario::DataThrottling (from Perl distribution Bencher-Scenario-DataThrottling), released on 2020-02-19.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m DataThrottling

To run module startup overhead benchmark:

 % bencher --module-startup -m DataThrottling

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Data::Throttler> 0.08

L<Data::Throttler_CHI> 0.001

=head1 BENCHMARK PARTICIPANTS

=over

=item * Data::Throttler (Memory backend) (perl_code)

Code template:

 my $t = Data::Throttler->new(max_items=><max_items>, interval=><interval>); for (1..<inserts>) { $t->try_push }



=item * Data::Throttler_CHI (Memory backend) (perl_code)

Code template:

 require CHI; my $t = Data::Throttler_CHI->new(max_items=><max_items>, interval=><interval>, cache=>CHI->new(driver=>"Memory", datastore=>{})); for (1..<inserts>) { $t->try_push }



=back

=head1 BENCHMARK DATASETS

=over

=item * max_items=1000, interval=3600, inserts/checks=1000

=item * max_items=100, interval=3600, inserts/checks=100

=item * max_items=10, interval=3600, inserts/checks=10

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) i7-4770 CPU @ 3.40GHz (4 cores) >>, OS: I<< GNU/Linux LinuxMint version 18.2 >>, OS kernel: I<< Linux version 4.8.0-53-generic >>.

Benchmark with default options (C<< bencher -m DataThrottling >>):

 #table1#
 +--------------------------------------+----------------------------------------------------+-----------+-----------+-----------------------+-----------------------+-----------+---------+
 | participant                          | dataset                                            | rate (/s) | time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors   | samples |
 +--------------------------------------+----------------------------------------------------+-----------+-----------+-----------------------+-----------------------+-----------+---------+
 | Data::Throttler_CHI (Memory backend) | max_items=1000, interval=3600, inserts/checks=1000 |      3.68 |    272    |                 0.00% |            149506.55% |   0.00013 |      20 |
 | Data::Throttler (Memory backend)     | max_items=1000, interval=3600, inserts/checks=1000 |     78.3  |     12.8  |              2026.52% |              6935.29% | 9.4e-06   |      20 |
 | Data::Throttler_CHI (Memory backend) | max_items=100, interval=3600, inserts/checks=100   |    247    |      4.05 |              6613.28% |              2128.52% | 2.4e-06   |      20 |
 | Data::Throttler (Memory backend)     | max_items=100, interval=3600, inserts/checks=100   |    757    |      1.32 |             20452.80% |               627.91% | 8.8e-07   |      21 |
 | Data::Throttler_CHI (Memory backend) | max_items=10, interval=3600, inserts/checks=10     |   4100    |      0.25 |            110077.43% |                35.79% | 2.7e-07   |      20 |
 | Data::Throttler (Memory backend)     | max_items=10, interval=3600, inserts/checks=10     |   5500    |      0.18 |            149506.55% |                 0.00% | 1.9e-07   |      25 |
 +--------------------------------------+----------------------------------------------------+-----------+-----------+-----------------------+-----------------------+-----------+---------+


Benchmark module startup overhead (C<< bencher -m DataThrottling --module-startup >>):

 #table2#
 +---------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | participant         | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +---------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | Data::Throttler     |      26.1 |              23.3 |                 0.00% |               840.52% | 1.6e-05 |      20 |
 | Data::Throttler_CHI |       4.4 |               1.6 |               490.88% |                59.17% | 1.8e-05 |      20 |
 | perl -e1 (baseline) |       2.8 |               0   |               840.52% |                 0.00% | 2.9e-06 |      20 |
 +---------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-DataThrottling>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-Throttling>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-DataThrottling>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
