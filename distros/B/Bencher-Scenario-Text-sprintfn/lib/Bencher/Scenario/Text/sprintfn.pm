package Bencher::Scenario::Text::sprintfn;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-01-18'; # DATE
our $DIST = 'Bencher-Scenario-Text-sprintfn'; # DIST
our $VERSION = '0.004'; # VERSION

our $scenario = {
    summary => 'Benchmark Text::sprintfn vs sprintf()',
    participants => [
        {
            fcall_template => 'Text::sprintfn::sprintfn(<format>, @{<data>})',
            tags => ['sprintfn'],
        },
        {
            name => 'sprintf',
            code_template => 'sprintf(<format>, @{<data>})',
            tags => ['sprintf'],
        },
    ],
    datasets => [
        {
            args => {format => '%s', data => [1]},
        },
        {
            args => {format => '%s%d%f', data => [1,2,3]},
        },
        {
            args => {format => '%(a)s', data => [{a=>1}]},
            exclude_participant_tags => ['sprintf'],
        },
        {
            args => {format => '%(a)s%(b)d%(c)f', data => [{a=>1,b=>2,c=>3}]},
            exclude_participant_tags => ['sprintf'],
        },
    ],
};

1;
# ABSTRACT: Benchmark Text::sprintfn vs sprintf()

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::Text::sprintfn - Benchmark Text::sprintfn vs sprintf()

=head1 VERSION

This document describes version 0.004 of Bencher::Scenario::Text::sprintfn (from Perl distribution Bencher-Scenario-Text-sprintfn), released on 2023-01-18.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m Text::sprintfn

To run module startup overhead benchmark:

 % bencher --module-startup -m Text::sprintfn

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Text::sprintfn> 0.090

=head1 BENCHMARK PARTICIPANTS

=over

=item * Text::sprintfn::sprintfn (perl_code) [sprintfn]

Function call template:

 Text::sprintfn::sprintfn(<format>, @{<data>})



=item * sprintf (perl_code) [sprintf]

Code template:

 sprintf(<format>, @{<data>})



=back

=head1 BENCHMARK DATASETS

=over

=item * {data=>[1],format=>"%s"}

=item * {data=>[1,2,3],format=>"%s%d%f"}

=item * {data=>[{a=>1}],format=>"%(a)s"}

=item * {data=>[{a=>1,b=>2,c=>3}],format=>"%(a)s%(b)d%(c)f"}

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.34.0 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 20.04 >>, OS kernel: I<< Linux version 5.4.0-91-generic >>.

Benchmark with default options (C<< bencher -m Text::sprintfn >>):

 #table1#
 +--------------------------+------------------------------------------------------+----------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant              | dataset                                              | p_tags   | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +--------------------------+------------------------------------------------------+----------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | Text::sprintfn::sprintfn | {data=>[{a=>1,b=>2,c=>3}],format=>"%(a)s%(b)d%(c)f"} | sprintfn |     77000 |   13      |                 0.00% |              5222.11% | 1.6e-08 |      22 |
 | Text::sprintfn::sprintfn | {data=>[{a=>1}],format=>"%(a)s"}                     | sprintfn |    200000 |    5      |               157.08% |              1970.18% | 8.3e-09 |      20 |
 | sprintf                  | {data=>[1,2,3],format=>"%s%d%f"}                     | sprintf  |    600000 |    1.7    |               672.12% |               589.29% |   1e-08 |      20 |
 | Text::sprintfn::sprintfn | {data=>[1,2,3],format=>"%s%d%f"}                     | sprintfn |   1054000 |    0.9491 |              1263.28% |               290.39% | 4.5e-11 |      20 |
 | Text::sprintfn::sprintfn | {data=>[1],format=>"%s"}                             | sprintfn |   2200000 |    0.46   |              2686.86% |                90.97% |   1e-09 |      20 |
 | sprintf                  | {data=>[1],format=>"%s"}                             | sprintf  |   4100000 |    0.24   |              5222.11% |                 0.00% | 4.3e-10 |      21 |
 +--------------------------+------------------------------------------------------+----------+-----------+-----------+-----------------------+-----------------------+---------+---------+


Formatted as L<Benchmark.pm|Benchmark> result:

                                                                           Rate  Ts:s sprintfn {data=>[{a=>1,b=>2,c=>3}],format=>"%(a)s%(b)d%(c)f"}  Ts:s sprintfn {data=>[{a=>1}],format=>"%(a)s"}  s sprintf {data=>[1,2,3],format=>"%s%d%f"}  Ts:s sprintfn {data=>[1,2,3],format=>"%s%d%f"}  Ts:s sprintfn {data=>[1],format=>"%s"}  s sprintf {data=>[1],format=>"%s"} 
  Ts:s sprintfn {data=>[{a=>1,b=>2,c=>3}],format=>"%(a)s%(b)d%(c)f"}    77000/s                                                                  --                                            -61%                                        -86%                                            -92%                                    -96%                                -98% 
  Ts:s sprintfn {data=>[{a=>1}],format=>"%(a)s"}                       200000/s                                                                160%                                              --                                        -66%                                            -81%                                    -90%                                -95% 
  s sprintf {data=>[1,2,3],format=>"%s%d%f"}                           600000/s                                                                664%                                            194%                                          --                                            -44%                                    -72%                                -85% 
  Ts:s sprintfn {data=>[1,2,3],format=>"%s%d%f"}                      1054000/s                                                               1269%                                            426%                                         79%                                              --                                    -51%                                -74% 
  Ts:s sprintfn {data=>[1],format=>"%s"}                              2200000/s                                                               2726%                                            986%                                        269%                                            106%                                      --                                -47% 
  s sprintf {data=>[1],format=>"%s"}                                  4100000/s                                                               5316%                                           1983%                                        608%                                            295%                                     91%                                  -- 
 
 Legends:
   Ts:s sprintfn {data=>[1,2,3],format=>"%s%d%f"}: dataset={data=>[1,2,3],format=>"%s%d%f"} p_tags=sprintfn participant=Text::sprintfn::sprintfn
   Ts:s sprintfn {data=>[1],format=>"%s"}: dataset={data=>[1],format=>"%s"} p_tags=sprintfn participant=Text::sprintfn::sprintfn
   Ts:s sprintfn {data=>[{a=>1,b=>2,c=>3}],format=>"%(a)s%(b)d%(c)f"}: dataset={data=>[{a=>1,b=>2,c=>3}],format=>"%(a)s%(b)d%(c)f"} p_tags=sprintfn participant=Text::sprintfn::sprintfn
   Ts:s sprintfn {data=>[{a=>1}],format=>"%(a)s"}: dataset={data=>[{a=>1}],format=>"%(a)s"} p_tags=sprintfn participant=Text::sprintfn::sprintfn
   s sprintf {data=>[1,2,3],format=>"%s%d%f"}: dataset={data=>[1,2,3],format=>"%s%d%f"} p_tags=sprintf participant=sprintf
   s sprintf {data=>[1],format=>"%s"}: dataset={data=>[1],format=>"%s"} p_tags=sprintf participant=sprintf

Benchmark module startup overhead (C<< bencher -m Text::sprintfn --module-startup >>):

 #table2#
 +---------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | participant         | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +---------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | Text::sprintfn      |        10 |                 2 |                 0.00% |                74.48% | 0.00039 |      20 |
 | perl -e1 (baseline) |         8 |                 0 |                74.48% |                 0.00% | 0.0002  |      23 |
 +---------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+


Formatted as L<Benchmark.pm|Benchmark> result:

                          Rate  T:s  perl -e1 (baseline) 
  T:s                  100.0/s   --                 -19% 
  perl -e1 (baseline)  125.0/s  25%                   -- 
 
 Legends:
   T:s: mod_overhead_time=2 participant=Text::sprintfn
   perl -e1 (baseline): mod_overhead_time=0 participant=perl -e1 (baseline)

To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-Text-sprintfn>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-Text-sprintfn>.

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-Text-sprintfn>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
