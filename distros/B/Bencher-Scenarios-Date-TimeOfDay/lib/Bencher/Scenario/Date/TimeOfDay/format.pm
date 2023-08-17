package Bencher::Scenario::Date::TimeOfDay::format;

use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-01-19'; # DATE
our $DIST = 'Bencher-Scenarios-Date-TimeOfDay'; # DIST
our $VERSION = '0.002'; # VERSION

our $scenario = {
    summary => "Benchmark timeofday formatting",
    participants => [
        {name=>"hms", module=>"Date::TimeOfDay", code_template=>'state $tod = Date::TimeOfDay->from_float(float=>86399); $tod->hms'},
        {name=>"stringify", module=>"Date::TimeOfDay", code_template=>'state $tod = Date::TimeOfDay->from_float(float=>86399); $tod->stringify'},
    ],
};

1;
# ABSTRACT: Benchmark timeofday formatting

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::Date::TimeOfDay::format - Benchmark timeofday formatting

=head1 VERSION

This document describes version 0.002 of Bencher::Scenario::Date::TimeOfDay::format (from Perl distribution Bencher-Scenarios-Date-TimeOfDay), released on 2023-01-19.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m Date::TimeOfDay::format

To run module startup overhead benchmark:

 % bencher --module-startup -m Date::TimeOfDay::format

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Date::TimeOfDay> 0.006

=head1 BENCHMARK PARTICIPANTS

=over

=item * hms (perl_code)

Code template:

 state $tod = Date::TimeOfDay->from_float(float=>86399); $tod->hms



=item * stringify (perl_code)

Code template:

 state $tod = Date::TimeOfDay->from_float(float=>86399); $tod->stringify



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.34.0 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 20.04 >>, OS kernel: I<< Linux version 5.4.0-91-generic >>.

Benchmark with default options (C<< bencher -m Date::TimeOfDay::format >>):

 #table1#
 +-------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | hms         |    650000 |    1.5    |                 0.00% |                 4.14% | 2.2e-09 |      27 |
 | stringify   |    675270 |    1.4809 |                 4.14% |                 0.00% | 5.7e-12 |      28 |
 +-------------+-----------+-----------+-----------------------+-----------------------+---------+---------+


Formatted as L<Benchmark.pm|Benchmark> result:

                 Rate  hms  stringify 
  hms        650000/s   --        -1% 
  stringify  675270/s   1%         -- 
 
 Legends:
   hms: participant=hms
   stringify: participant=stringify

Benchmark module startup overhead (C<< bencher -m Date::TimeOfDay::format --module-startup >>):

 #table2#
 +---------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | participant         | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +---------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | Date::TimeOfDay     |      9.85 |              3.85 |                 0.00% |                63.46% | 6.9e-06 |      20 |
 | perl -e1 (baseline) |      6    |              0    |                63.46% |                 0.00% | 1.4e-05 |      20 |
 +---------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+


Formatted as L<Benchmark.pm|Benchmark> result:

                          Rate  D:T  perl -e1 (baseline) 
  D:T                  101.5/s   --                 -39% 
  perl -e1 (baseline)  166.7/s  64%                   -- 
 
 Legends:
   D:T: mod_overhead_time=3.85 participant=Date::TimeOfDay
   perl -e1 (baseline): mod_overhead_time=0 participant=perl -e1 (baseline)

To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-Date-TimeOfDay>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-Date-TimeOfDay>.

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

This software is copyright (c) 2023 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-Date-TimeOfDay>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
