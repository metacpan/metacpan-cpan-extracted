package Bencher::Scenario::Data::Dmp::Dump;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-01-19'; # DATE
our $DIST = 'Bencher-Scenarios-Data-Dmp'; # DIST
our $VERSION = '0.003'; # VERSION

our $scenario = {
    summary => 'Benchmark Data::Dmp',
    modules => {
        'Data::Dmp' => {version=>'0.242'},
    },
    participants => [
        {name => 'Data::Dmp', fcall_template => 'Data::Dmp::dmp(<data>)'},
        {module => 'Data::Dump', code_template => 'my $dummy = Data::Dump::dump(<data>)'},
    ],
    datasets => [
        {
            name => 'a100-num-various',
            args => { data => [ (0, 1, -1, "+1", 1e100,
                                 -1e-100, "0123", "Inf", "-Inf", "NaN") x 10 ] },
        },
        {
            name => 'a100-num-int',
            args => { data => [ 1..100 ] },
        },
        {
            name => 'a100-str',
            args => { data => [ "a" x 100 ] },
        },
    ],
};

# ABSTRACT: Benchmark Data::Dmp

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::Data::Dmp::Dump - Benchmark Data::Dmp

=head1 VERSION

This document describes version 0.003 of Bencher::Scenario::Data::Dmp::Dump (from Perl distribution Bencher-Scenarios-Data-Dmp), released on 2023-01-19.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m Data::Dmp::Dump

To run module startup overhead benchmark:

 % bencher --module-startup -m Data::Dmp::Dump

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Data::Dmp> 0.242

L<Data::Dump> 1.23

=head1 BENCHMARK PARTICIPANTS

=over

=item * Data::Dmp (perl_code)

Function call template:

 Data::Dmp::dmp(<data>)



=item * Data::Dump (perl_code)

Code template:

 my $dummy = Data::Dump::dump(<data>)



=back

=head1 BENCHMARK DATASETS

=over

=item * a100-num-various

=item * a100-num-int

=item * a100-str

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.34.0 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 20.04 >>, OS kernel: I<< Linux version 5.4.0-91-generic >>.

Benchmark with default options (C<< bencher -m Data::Dmp::Dump >>):

 #table1#
 +-------------+------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant | dataset          | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------+------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | Data::Dump  | a100-num-various |      1900 |    530    |                 0.00% |             14877.50% | 9.1e-07 |      20 |
 | Data::Dump  | a100-num-int     |      3070 |    326    |                62.17% |              9135.81% | 5.3e-08 |      20 |
 | Data::Dmp   | a100-num-various |      6000 |    170    |               218.27% |              4605.86% |   2e-07 |      22 |
 | Data::Dmp   | a100-num-int     |     13000 |     76    |               595.19% |              2054.44% | 1.1e-07 |      20 |
 | Data::Dump  | a100-str         |     82000 |     12    |              4219.88% |               246.71% | 2.7e-08 |      20 |
 | Data::Dmp   | a100-str         |    283000 |      3.53 |             14877.50% |                 0.00% | 1.7e-09 |      20 |
 +-------------+------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+


Formatted as L<Benchmark.pm|Benchmark> result:

                                   Rate  Data::Dump a100-num-various  Data::Dump a100-num-int  Data::Dmp a100-num-various  Data::Dmp a100-num-int  Data::Dump a100-str  Data::Dmp a100-str 
  Data::Dump a100-num-various    1900/s                           --                     -38%                        -67%                    -85%                 -97%                -99% 
  Data::Dump a100-num-int        3070/s                          62%                       --                        -47%                    -76%                 -96%                -98% 
  Data::Dmp a100-num-various     6000/s                         211%                      91%                          --                    -55%                 -92%                -97% 
  Data::Dmp a100-num-int        13000/s                         597%                     328%                        123%                      --                 -84%                -95% 
  Data::Dump a100-str           82000/s                        4316%                    2616%                       1316%                    533%                   --                -70% 
  Data::Dmp a100-str           283000/s                       14914%                    9135%                       4715%                   2052%                 239%                  -- 
 
 Legends:
   Data::Dmp a100-num-int: dataset=a100-num-int participant=Data::Dmp
   Data::Dmp a100-num-various: dataset=a100-num-various participant=Data::Dmp
   Data::Dmp a100-str: dataset=a100-str participant=Data::Dmp
   Data::Dump a100-num-int: dataset=a100-num-int participant=Data::Dump
   Data::Dump a100-num-various: dataset=a100-num-various participant=Data::Dump
   Data::Dump a100-str: dataset=a100-str participant=Data::Dump

Benchmark module startup overhead (C<< bencher -m Data::Dmp::Dump --module-startup >>):

 #table2#
 +---------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | participant         | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +---------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | Data::Dump          |      13   |               6.4 |                 0.00% |               100.46% | 6.1e-05 |      20 |
 | Data::Dmp           |      11   |               4.4 |                16.95% |                71.40% | 4.4e-05 |      20 |
 | perl -e1 (baseline) |       6.6 |               0   |               100.46% |                 0.00% | 4.5e-05 |      20 |
 +---------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+


Formatted as L<Benchmark.pm|Benchmark> result:

                          Rate  Data::Dump  Data::Dmp  perl -e1 (baseline) 
  Data::Dump            76.9/s          --       -15%                 -49% 
  Data::Dmp             90.9/s         18%         --                 -40% 
  perl -e1 (baseline)  151.5/s         96%        66%                   -- 
 
 Legends:
   Data::Dmp: mod_overhead_time=4.4 participant=Data::Dmp
   Data::Dump: mod_overhead_time=6.4 participant=Data::Dump
   perl -e1 (baseline): mod_overhead_time=0 participant=perl -e1 (baseline)

To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-Data-Dmp>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-Data-Dmp>.

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-Data-Dmp>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
