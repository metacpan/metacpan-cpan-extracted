package Bencher::Scenario::ProgressAny::Update;

our $DATE = '2018-05-20'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark update()',

    participants => [
        {
            name => '1000x update()',
            module => 'Progress::Any',
            code_template => q(use Progress::Any '$progress'; $progress->target(1000); for(1..1000) { $progress->update() } $progress->finish),
        },
        {
            name => '1000x update(pos + message)',
            module => 'Progress::Any',
            code_template => q(use Progress::Any '$progress'; $progress->target(1000); for(1..1000) { $progress->update(pos=>$_, message=>$_) } $progress->finish),
        },
    ],
};

1;
# ABSTRACT: Benchmark update()

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::ProgressAny::Update - Benchmark update()

=head1 VERSION

This document describes version 0.001 of Bencher::Scenario::ProgressAny::Update (from Perl distribution Bencher-Scenarios-ProgressAny), released on 2018-05-20.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m ProgressAny::Update

To run module startup overhead benchmark:

 % bencher --module-startup -m ProgressAny::Update

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Progress::Any> 0.214

=head1 BENCHMARK PARTICIPANTS

=over

=item * 1000x update() (perl_code)

Code template:

 use Progress::Any '$progress'; $progress->target(1000); for(1..1000) { $progress->update() } $progress->finish



=item * 1000x update(pos + message) (perl_code)

Code template:

 use Progress::Any '$progress'; $progress->target(1000); for(1..1000) { $progress->update(pos=>$_, message=>$_) } $progress->finish



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.26.1 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 18.3 >>, OS kernel: I<< Linux version 4.10.0-38-generic >>.

Benchmark with default options (C<< bencher -m ProgressAny::Update >>):

 #table1#
 +-----------------------------+-----------+-----------+------------+---------+---------+
 | participant                 | rate (/s) | time (ms) | vs_slowest |  errors | samples |
 +-----------------------------+-----------+-----------+------------+---------+---------+
 | 1000x update(pos + message) |       300 |       3.3 |       1    | 4.2e-06 |      20 |
 | 1000x update()              |       323 |       3.1 |       1.08 | 1.1e-06 |      21 |
 +-----------------------------+-----------+-----------+------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m ProgressAny::Update --module-startup >>):

 #table2#
 +---------------------+-----------+------------------------+------------+---------+---------+
 | participant         | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +---------------------+-----------+------------------------+------------+---------+---------+
 | Progress::Any       |      15   |                    9.2 |        1   | 1.6e-05 |      20 |
 | perl -e1 (baseline) |       5.8 |                    0   |        2.5 | 3.2e-05 |      21 |
 +---------------------+-----------+------------------------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-ProgressAny>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-ProgressAny>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-ProgressAny>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
