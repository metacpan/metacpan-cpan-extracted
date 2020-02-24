package Bencher::Scenario::StringInterpolate;

our $DATE = '2019-11-25'; # DATE
our $DIST = 'Bencher-Scenario-StringInterpolate'; # DIST
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark string interpolation',
    participants => [
        {
            fcall_template => 'String::Interpolate::interpolate(<string>)',
        },
        {
            name => 'eval',
            code_template => 'eval q("<string:raw>")',
        },
    ],
    datasets => [
        {args => {string=>'$main::foo $main::bar'}},
    ],
};

package main;
our $foo = "Foo";
our $bar = "BAR";

1;
# ABSTRACT: Benchmark string interpolation

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::StringInterpolate - Benchmark string interpolation

=head1 VERSION

This document describes version 0.001 of Bencher::Scenario::StringInterpolate (from Perl distribution Bencher-Scenario-StringInterpolate), released on 2019-11-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m StringInterpolate

To run module startup overhead benchmark:

 % bencher --module-startup -m StringInterpolate

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<String::Interpolate> 0.32

=head1 BENCHMARK PARTICIPANTS

=over

=item * String::Interpolate::interpolate (perl_code)

Function call template:

 String::Interpolate::interpolate(<string>)



=item * eval (perl_code)

Code template:

 eval q("<string:raw>")



=back

=head1 BENCHMARK DATASETS

=over

=item * $main::foo $main::bar

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.30.0 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 19.04 >>, OS kernel: I<< Linux version 5.0.0-31-generic >>.

Benchmark with default options (C<< bencher -m StringInterpolate >>):

 #table1#
 +----------------------------------+-----------+-----------+------------+---------+---------+
 | participant                      | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +----------------------------------+-----------+-----------+------------+---------+---------+
 | eval                             |    140000 |       7   |       1    | 1.3e-08 |      20 |
 | String::Interpolate::interpolate |    227000 |       4.4 |       1.59 | 1.7e-09 |      20 |
 +----------------------------------+-----------+-----------+------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m StringInterpolate --module-startup >>):

 #table2#
 +---------------------+-----------+------------------------+------------+---------+---------+
 | participant         | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +---------------------+-----------+------------------------+------------+---------+---------+
 | String::Interpolate |      14.5 |                    8.2 |        1   | 1.1e-05 |      20 |
 | perl -e1 (baseline) |       6.3 |                    0   |        2.3 | 1.3e-05 |      20 |
 +---------------------+-----------+------------------------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-StringInterpolate>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-StringInterpolate>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-StringInterpolate>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
