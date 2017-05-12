package Bencher::Scenario::LogDispatch::Startup;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.02'; # VERSION

use 5.010001;
use strict;
use warnings;

#our @modules = grep {!/\ALog::Dispatch::(XXX)\z/} do { require App::lcpan::Call; @{ App::lcpan::Call::call_lcpan_script(argv=>["modules", "--namespace", "Regexp::Common"])->[2] } }; # PRECOMPUTE
our @modules = qw(
    Log::Dispatch::Base
    Log::Dispatch::Dir
    Log::Dispatch::File
    Log::Dispatch::FileWriteRotate
    Log::Dispatch::Null
    Log::Dispatch::Perl
    Log::Dispatch::Screen
    Log::Dispatch::Screen::Color
);

our $scenario = {
    summary => 'Benchmark module startup overhead of some Log::Dispatch modules',
    # minimum versions
    modules => {
        'Log::Dispatch::FileWriteRotate' => {version=>'0.04'},
    },
    module_startup => 1,

    participants => [
        map { +{module=>$_} } @modules,
    ],
};

1;
# ABSTRACT: Benchmark module startup overhead of some Log::Dispatch modules

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::LogDispatch::Startup - Benchmark module startup overhead of some Log::Dispatch modules

=head1 VERSION

This document describes version 0.02 of Bencher::Scenario::LogDispatch::Startup (from Perl distribution Bencher-Scenarios-LogDispatch), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m LogDispatch::Startup

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Log::Dispatch::Base> 2.57

L<Log::Dispatch::Dir> 0.14

L<Log::Dispatch::File> 2.57

L<Log::Dispatch::FileWriteRotate> 0.05

L<Log::Dispatch::Null> 2.57

L<Log::Dispatch::Perl> 0.04

L<Log::Dispatch::Screen> 2.57

L<Log::Dispatch::Screen::Color> 0.04

=head1 BENCHMARK PARTICIPANTS

=over

=item * Log::Dispatch::Base (perl_code)

L<Log::Dispatch::Base>



=item * Log::Dispatch::Dir (perl_code)

L<Log::Dispatch::Dir>



=item * Log::Dispatch::File (perl_code)

L<Log::Dispatch::File>



=item * Log::Dispatch::FileWriteRotate (perl_code)

L<Log::Dispatch::FileWriteRotate>



=item * Log::Dispatch::Null (perl_code)

L<Log::Dispatch::Null>



=item * Log::Dispatch::Perl (perl_code)

L<Log::Dispatch::Perl>



=item * Log::Dispatch::Screen (perl_code)

L<Log::Dispatch::Screen>



=item * Log::Dispatch::Screen::Color (perl_code)

L<Log::Dispatch::Screen::Color>



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m LogDispatch::Startup >>):

 #table1#
 +--------------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+-----------+---------+
 | participant                    | proc_private_dirty_size (MB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors   | samples |
 +--------------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+-----------+---------+
 | Log::Dispatch::FileWriteRotate | 2.4                          | 5.9                | 21             |      46   |                   41.5 |        1   | 8.2e-05   |      20 |
 | Log::Dispatch::Dir             | 2.4                          | 5.8                | 22             |      34   |                   29.5 |        1.4 |   0.00011 |      20 |
 | Log::Dispatch::Screen::Color   | 0.82                         | 4                  | 16             |      31   |                   26.5 |        1.5 | 6.3e-05   |      20 |
 | Log::Dispatch::Screen          | 3.8                          | 7.3                | 27             |      28   |                   23.5 |        1.7 |   4e-05   |      20 |
 | Log::Dispatch::File            | 5.5                          | 9.1                | 41             |      21   |                   16.5 |        2.1 |   0.00011 |      20 |
 | Log::Dispatch::Perl            | 3.2                          | 6.8                | 26             |      21   |                   16.5 |        2.2 |   4e-05   |      20 |
 | Log::Dispatch::Null            | 2.4                          | 5.8                | 22             |      21   |                   16.5 |        2.2 |   0.00011 |      20 |
 | Log::Dispatch::Base            | 4.1                          | 7.6                | 31             |       8.7 |                    4.2 |        5.3 | 9.9e-06   |      20 |
 | perl -e1 (baseline)            | 1.1                          | 4.4                | 18             |       4.5 |                    0   |       10   | 2.2e-05   |      20 |
 +--------------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+-----------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-LogDispatch>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-LogDispatch>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-LogDispatch>

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
