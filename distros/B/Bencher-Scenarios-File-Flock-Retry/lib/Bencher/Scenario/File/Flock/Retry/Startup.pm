package Bencher::Scenario::File::Flock::Retry::Startup;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-01-19'; # DATE
our $DIST = 'Bencher-Scenarios-File-Flock-Retry'; # DIST
our $VERSION = '0.002'; # VERSION

our $scenario = {
    summary => 'Benchmark startup of File::Flock::Retry',
    participants => [
        {module=>'File::Flock'},
        {module=>'File::Flock::Retry'},
        {module=>'File::Flock::Tiny'},
    ],
    module_startup => 1,
};

1;
# ABSTRACT: Benchmark startup of File::Flock::Retry

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::File::Flock::Retry::Startup - Benchmark startup of File::Flock::Retry

=head1 VERSION

This document describes version 0.002 of Bencher::Scenario::File::Flock::Retry::Startup (from Perl distribution Bencher-Scenarios-File-Flock-Retry), released on 2023-01-19.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m File::Flock::Retry::Startup

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<File::Flock> 2014.01

L<File::Flock::Retry> 0.632

L<File::Flock::Tiny> 0.14

=head1 BENCHMARK PARTICIPANTS

=over

=item * File::Flock (perl_code)

L<File::Flock>



=item * File::Flock::Retry (perl_code)

L<File::Flock::Retry>



=item * File::Flock::Tiny (perl_code)

L<File::Flock::Tiny>



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.34.0 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 20.04 >>, OS kernel: I<< Linux version 5.4.0-91-generic >>.

Benchmark with default options (C<< bencher -m File::Flock::Retry::Startup >>):

 #table1#
 +---------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | participant         | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +---------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | File::Flock         |      25   |              19.3 |                 0.00% |               349.36% | 4.7e-05 |      20 |
 | File::Flock::Tiny   |      16   |              10.3 |                60.09% |               180.69% | 4.5e-05 |      21 |
 | File::Flock::Retry  |      11   |               5.3 |               140.83% |                86.59% | 2.7e-05 |      21 |
 | perl -e1 (baseline) |       5.7 |               0   |               349.36% |                 0.00% | 8.5e-06 |      21 |
 +---------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+


Formatted as L<Benchmark.pm|Benchmark> result:

                          Rate   F:F  FF:T  FF:R  perl -e1 (baseline) 
  F:F                   40.0/s    --  -36%  -56%                 -77% 
  FF:T                  62.5/s   56%    --  -31%                 -64% 
  FF:R                  90.9/s  127%   45%    --                 -48% 
  perl -e1 (baseline)  175.4/s  338%  180%   92%                   -- 
 
 Legends:
   F:F: mod_overhead_time=19.3 participant=File::Flock
   FF:R: mod_overhead_time=5.3 participant=File::Flock::Retry
   FF:T: mod_overhead_time=10.3 participant=File::Flock::Tiny
   perl -e1 (baseline): mod_overhead_time=0 participant=perl -e1 (baseline)

To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-File-Flock-Retry>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-File-Flock-Retry>.

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

This software is copyright (c) 2023, 2017 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-File-Flock-Retry>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
