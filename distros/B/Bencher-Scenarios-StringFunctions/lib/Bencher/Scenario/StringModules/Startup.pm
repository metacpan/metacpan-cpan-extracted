package Bencher::Scenario::StringModules::Startup;

our $DATE = '2021-06-23'; # DATE
our $VERSION = '0.003'; # VERSION

use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark startup of string modules',
    module_startup => 1,
    participants => [
        {module => 'String::CommonPrefix'},
        {module => 'String::CommonSuffix'},
        {module => 'String::Trim::More'},
        {module => 'String::Util'},
    ],
};

1;
# ABSTRACT: Benchmark startup of string modules

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::StringModules::Startup - Benchmark startup of string modules

=head1 VERSION

This document describes version 0.003 of Bencher::Scenario::StringModules::Startup (from Perl distribution Bencher-Scenarios-StringFunctions), released on 2021-06-23.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m StringModules::Startup

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<String::CommonPrefix> 0.01

L<String::CommonSuffix> 0.01

L<String::Trim::More> 0.03

L<String::Util> 1.32

=head1 BENCHMARK PARTICIPANTS

=over

=item * String::CommonPrefix (perl_code)

L<String::CommonPrefix>



=item * String::CommonSuffix (perl_code)

L<String::CommonSuffix>



=item * String::Trim::More (perl_code)

L<String::Trim::More>



=item * String::Util (perl_code)

L<String::Util>



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.34.0 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 20.04 >>, OS kernel: I<< Linux version 5.3.0-64-generic >>.

Benchmark with default options (C<< bencher -m StringModules::Startup >>):

 #table1#
 {dataset=>undef}
 +----------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | participant          | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +----------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | String::Util         |      14   |               7.4 |                 0.00% |               118.92% | 3.4e-05 |      20 |
 | String::CommonPrefix |       9.3 |               2.7 |                54.98% |                41.25% | 4.1e-05 |      22 |
 | String::Trim::More   |       9.2 |               2.6 |                55.86% |                40.46% | 1.1e-05 |      20 |
 | String::CommonSuffix |       9.1 |               2.5 |                57.88% |                38.66% | 5.8e-05 |      20 |
 | perl -e1 (baseline)  |       6.6 |               0   |               118.92% |                 0.00% | 3.5e-05 |      20 |
 +----------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-StringFunctions>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-StringFunctions>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-StringFunctions>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
