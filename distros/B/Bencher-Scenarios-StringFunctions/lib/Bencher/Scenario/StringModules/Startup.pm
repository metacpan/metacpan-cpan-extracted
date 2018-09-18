package Bencher::Scenario::StringModules::Startup;

our $DATE = '2018-09-16'; # DATE
our $VERSION = '0.001'; # VERSION

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

This document describes version 0.001 of Bencher::Scenario::StringModules::Startup (from Perl distribution Bencher-Scenarios-StringFunctions), released on 2018-09-16.

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

L<String::Util> 1.26

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

Run on: perl: I<< v5.26.1 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 18.3 >>, OS kernel: I<< Linux version 4.10.0-38-generic >>.

Benchmark with default options (C<< bencher -m StringModules::Startup >>):

 #table1#
 +----------------------+-----------+------------------------+------------+---------+---------+
 | participant          | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +----------------------+-----------+------------------------+------------+---------+---------+
 | String::Util         |      14   |                    8.5 |        1   | 1.5e-05 |      20 |
 | String::Trim::More   |       8.2 |                    2.7 |        1.7 | 1.2e-05 |      24 |
 | String::CommonPrefix |       8.2 |                    2.7 |        1.7 | 9.9e-06 |      20 |
 | String::CommonSuffix |       8.1 |                    2.6 |        1.7 | 1.5e-05 |      20 |
 | perl -e1 (baseline)  |       5.5 |                    0   |        2.5 | 2.3e-05 |      20 |
 +----------------------+-----------+------------------------+------------+---------+---------+


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

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
