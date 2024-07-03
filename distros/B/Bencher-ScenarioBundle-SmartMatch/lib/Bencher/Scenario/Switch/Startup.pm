package Bencher::Scenario::Switch::Startup;

use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-07-02'; # DATE
our $DIST = 'Bencher-ScenarioBundle-SmartMatch'; # DIST
our $VERSION = '0.001'; # VERSION

our $scenario = {
    summary => "Benchmark the startup overhead of various switch modules",
    participants => [
        {module=>'Switch::Right'},
        {module=>'Switch::Back'},
        {module=>'Switch::Perlish'},
        {module=>'Switch::Plain'},
    ],
    module_startup => 1,
};

1;
# ABSTRACT: Benchmark the startup overhead of various switch modules

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::Switch::Startup - Benchmark the startup overhead of various switch modules

=head1 VERSION

This document describes version 0.001 of Bencher::Scenario::Switch::Startup (from Perl distribution Bencher-ScenarioBundle-SmartMatch), released on 2024-07-02.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m Switch::Startup

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Switch::Right> 0.000005

L<Switch::Back> 0.000002

L<Switch::Perlish> 1.0.5

L<Switch::Plain> 0.0501

=head1 BENCHMARK PARTICIPANTS

=over

=item * Switch::Right (perl_code)

L<Switch::Right>



=item * Switch::Back (perl_code)

L<Switch::Back>



=item * Switch::Perlish (perl_code)

L<Switch::Perlish>



=item * Switch::Plain (perl_code)

L<Switch::Plain>



=back

=head1 BENCHMARK SAMPLE RESULTS

=head2 Sample benchmark #1

Run on: perl: I<< v5.38.2 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 20.04 >>, OS kernel: I<< Linux version 5.4.0-164-generic >>.

Benchmark command (default options):

 % bencher -m Switch::Startup

Result formatted as table:

 #table1#
 +---------------------+-----------+-------------------+-----------------------+-----------------------+----------+---------+
 | participant         | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors  | samples |
 +---------------------+-----------+-------------------+-----------------------+-----------------------+----------+---------+
 | Switch::Right       |    760    |            753.16 |                 0.00% |             10969.46% |   0.0028 |      20 |
 | Switch::Back        |    620    |            613.16 |                21.83% |              8985.69% |   0.001  |      20 |
 | Switch::Perlish     |     20    |             13.16 |              3767.04% |               186.25% | 2.5e-05  |      20 |
 | Switch::Plain       |     13.2  |              6.36 |              5643.72% |                92.72% | 7.1e-06  |      20 |
 | perl -e1 (baseline) |      6.84 |              0    |             10969.46% |                 0.00% | 5.3e-06  |      20 |
 +---------------------+-----------+-------------------+-----------------------+-----------------------+----------+---------+


The above result formatted in L<Benchmark.pm|Benchmark> style:

                          Rate  Switch::Right  Switch::Back  Switch::Perlish  Switch::Plain  perl -e1 (baseline) 
  Switch::Right          1.3/s             --          -18%             -97%           -98%                 -99% 
  Switch::Back           1.6/s            22%            --             -96%           -97%                 -98% 
  Switch::Perlish       50.0/s          3700%         3000%               --           -34%                 -65% 
  Switch::Plain         75.8/s          5657%         4596%              51%             --                 -48% 
  perl -e1 (baseline)  146.2/s         11011%         8964%             192%            92%                   -- 
 
 Legends:
   Switch::Back: mod_overhead_time=613.16 participant=Switch::Back
   Switch::Perlish: mod_overhead_time=13.16 participant=Switch::Perlish
   Switch::Plain: mod_overhead_time=6.36 participant=Switch::Plain
   Switch::Right: mod_overhead_time=753.16 participant=Switch::Right
   perl -e1 (baseline): mod_overhead_time=0 participant=perl -e1 (baseline)

To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 BENCHMARK NOTES

So, as I suspected, L<Switch::Right> and L<Switch::Back> has a large startup
overhead, too large for my taste. Won't be using them anytime soon.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-ScenarioBundle-SmartMatch>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-ScenarioBundle-SmartMatch>.

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

This software is copyright (c) 2024 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-ScenarioBundle-SmartMatch>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
