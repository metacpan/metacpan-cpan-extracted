package Bencher::Scenario::String::Interpolate;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-01-18'; # DATE
our $DIST = 'Bencher-Scenario-String-Interpolate'; # DIST
our $VERSION = '0.002'; # VERSION

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

Bencher::Scenario::String::Interpolate - Benchmark string interpolation

=head1 VERSION

This document describes version 0.002 of Bencher::Scenario::String::Interpolate (from Perl distribution Bencher-Scenario-String-Interpolate), released on 2023-01-18.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m String::Interpolate

To run module startup overhead benchmark:

 % bencher --module-startup -m String::Interpolate

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<String::Interpolate> 0.33

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

Run on: perl: I<< v5.34.0 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 20.04 >>, OS kernel: I<< Linux version 5.4.0-91-generic >>.

Benchmark with default options (C<< bencher -m String::Interpolate >>):

 #table1#
 +----------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                      | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +----------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | eval                             |    130000 |      7.4  |                 0.00% |                67.37% | 2.7e-08 |      20 |
 | String::Interpolate::interpolate |    226000 |      4.43 |                67.37% |                 0.00% | 1.7e-09 |      20 |
 +----------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+


Formatted as L<Benchmark.pm|Benchmark> result:

            Rate    e  SI:i 
  e     130000/s   --  -40% 
  SI:i  226000/s  67%    -- 
 
 Legends:
   SI:i: participant=String::Interpolate::interpolate
   e: participant=eval

Benchmark module startup overhead (C<< bencher -m String::Interpolate --module-startup >>):

 #table2#
 +---------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | participant         | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +---------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | String::Interpolate |        16 |                10 |                 0.00% |               159.05% | 8.9e-05 |      20 |
 | perl -e1 (baseline) |         6 |                 0 |               159.05% |                 0.00% | 2.1e-05 |      20 |
 +---------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+


Formatted as L<Benchmark.pm|Benchmark> result:

                          Rate   S:I  perl -e1 (baseline) 
  S:I                   62.5/s    --                 -62% 
  perl -e1 (baseline)  166.7/s  166%                   -- 
 
 Legends:
   S:I: mod_overhead_time=10 participant=String::Interpolate
   perl -e1 (baseline): mod_overhead_time=0 participant=perl -e1 (baseline)

To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-String-Interpolate>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-String-Interpolate>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023, 2019 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-String-Interpolate>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
