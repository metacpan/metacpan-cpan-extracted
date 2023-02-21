package Bencher::Scenario::Regexp::IPv4;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-01-17'; # DATE
our $DIST = 'Bencher-Scenario-Regexp-IPv4'; # DIST
our $VERSION = '0.003'; # VERSION

our $scenario = {
    summary => 'Benchmark Regexp::IPv4',
    participants => [
        {
            module=>'Regexp::IPv4',
            code_template => '<ip> =~ $Regexp::IPv4::IPv4_re'
        },
    ],
    datasets => [
        {args=>{ip=>'127.0.0.1'}},

        {args=>{ip=>'ff02::1'}},
        {args=>{ip=>'2001:cdba:0000:0000:0000:0000:3257:9652'}},
    ],
};

1;
# ABSTRACT: Benchmark Regexp::IPv4

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::Regexp::IPv4 - Benchmark Regexp::IPv4

=head1 VERSION

This document describes version 0.003 of Bencher::Scenario::Regexp::IPv4 (from Perl distribution Bencher-Scenario-Regexp-IPv4), released on 2023-01-17.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m Regexp::IPv4

To run module startup overhead benchmark:

 % bencher --module-startup -m Regexp::IPv4

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Regexp::IPv4> 0.003

=head1 BENCHMARK PARTICIPANTS

=over

=item * Regexp::IPv4 (perl_code)

Code template:

 <ip> =~ $Regexp::IPv4::IPv4_re



=back

=head1 BENCHMARK DATASETS

=over

=item * 127.0.0.1

=item * ff02::1

=item * 2001:cdba:0000:0000:0000:0000:3257:9652

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.34.0 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 20.04 >>, OS kernel: I<< Linux version 5.4.0-91-generic >>.

Benchmark with default options (C<< bencher -m Regexp::IPv4 >>):

 #table1#
 +-----------------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | dataset                                 | rate (/s) | time (ns) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-----------------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | 127.0.0.1                               |   1370000 |     732   |                 0.00% |               301.29% |   2e-10 |      21 |
 | 2001:cdba:0000:0000:0000:0000:3257:9652 |   5399000 |     185.2 |               295.13% |                 1.56% | 5.8e-12 |      20 |
 | ff02::1                                 |   5480000 |     182   |               301.29% |                 0.00% | 8.5e-11 |      30 |
 +-----------------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+


Formatted as L<Benchmark.pm|Benchmark> result:

                                                Rate  127.0.0.1  2001:cdba:0000:0000:0000:0000:3257:9652  ff02::1 
  127.0.0.1                                1370000/s         --                                     -74%     -75% 
  2001:cdba:0000:0000:0000:0000:3257:9652  5399000/s       295%                                       --      -1% 
  ff02::1                                  5480000/s       302%                                       1%       -- 
 
 Legends:
   127.0.0.1: dataset=127.0.0.1
   2001:cdba:0000:0000:0000:0000:3257:9652: dataset=2001:cdba:0000:0000:0000:0000:3257:9652
   ff02::1: dataset=ff02::1

Benchmark module startup overhead (C<< bencher -m Regexp::IPv4 --module-startup >>):

 #table2#
 +---------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | participant         | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +---------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | Regexp::IPv4        |       8.7 |               2.7 |                 0.00% |                46.14% | 1.8e-05 |      20 |
 | perl -e1 (baseline) |       6   |               0   |                46.14% |                 0.00% | 9.4e-06 |      20 |
 +---------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+


Formatted as L<Benchmark.pm|Benchmark> result:

                          Rate  R:I  perl -e1 (baseline) 
  R:I                  114.9/s   --                 -31% 
  perl -e1 (baseline)  166.7/s  44%                   -- 
 
 Legends:
   R:I: mod_overhead_time=2.7 participant=Regexp::IPv4
   perl -e1 (baseline): mod_overhead_time=0 participant=perl -e1 (baseline)

To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-Regexp-IPv4>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-RegexpIPv4>.

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

This software is copyright (c) 2023, 2017, 2016 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-Regexp-IPv4>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
