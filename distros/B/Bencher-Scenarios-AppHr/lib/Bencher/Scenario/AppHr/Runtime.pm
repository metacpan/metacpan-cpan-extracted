package Bencher::Scenario::AppHr::Runtime;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.02'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark runtime, to monitor regression',
    modules => {
        'App::hr' => {version=>0},
    },
    participants => [
        {
            name => 'version',
            summary => 'Run `hr --version`',
            code=>sub {
                my $out = `hr --version`;
                die "Bactick failed: $?" if $?;
                $out;
            },
        },
        {
            name=>'help',
            summary => 'Run `hr --help`',
            code=>sub {
                my $out = `hr --help`;
                die "Bactick failed: $?" if $?;
                $out;
            },
        },
        {
            name=>'default',
            summary => 'Run `hr` which prints a single uncolored bar',
            code=>sub {
                my $out = `hr`;
                die "Bactick failed: $?" if $?;
                $out;
            },
        },
        {
            name=>'random',
            summary => 'Run `hr -r` which prints a random-colored, random-pattern bar',
            code=>sub {
                my $out = `hr -r`;
                die "Bactick failed: $?" if $?;
                $out;
            },
        },
    ],
};

1;
# ABSTRACT: Benchmark runtime, to monitor regression

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::AppHr::Runtime - Benchmark runtime, to monitor regression

=head1 VERSION

This document describes version 0.02 of Bencher::Scenario::AppHr::Runtime (from Perl distribution Bencher-Scenarios-AppHr), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m AppHr::Runtime

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<App::hr> 0.25

=head1 BENCHMARK PARTICIPANTS

=over

=item * version (perl_code)

Run `hr --version`.



=item * help (perl_code)

Run `hr --help`.



=item * default (perl_code)

Run `hr` which prints a single uncolored bar.



=item * random (perl_code)

Run `hr -r` which prints a random-colored, random-pattern bar.



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m AppHr::Runtime >>):

 #table1#
 +-------------+-----------+-----------+------------+-----------+---------+
 | participant | rate (/s) | time (ms) | vs_slowest |  errors   | samples |
 +-------------+-----------+-----------+------------+-----------+---------+
 | random      |        36 |        28 |        1   |   0.00011 |      20 |
 | default     |        42 |        24 |        1.2 | 6.3e-05   |      20 |
 | version     |        56 |        18 |        1.5 | 7.3e-05   |      20 |
 | help        |        91 |        11 |        2.5 | 6.7e-05   |      20 |
 +-------------+-----------+-----------+------------+-----------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-AppHr>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-AppHr>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-AppHr>

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
