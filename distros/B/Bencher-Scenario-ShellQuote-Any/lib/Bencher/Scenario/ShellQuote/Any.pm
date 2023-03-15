package Bencher::Scenario::ShellQuote::Any;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-01-17'; # DATE
our $DIST = 'Bencher-Scenario-ShellQuote-Any'; # DIST
our $VERSION = '0.005'; # VERSION

our $scenario = {
    summary => 'Benchmark cross-platform shell quoting',
    participants => [
        {
            fcall_template=>'ShellQuote::Any::shell_quote(<cmd>)',
        },
        {
            fcall_template=>'PERLANCAR::ShellQuote::Any::shell_quote(@{<cmd>})',
        },
        {
            fcall_template=>'ShellQuote::Any::Tiny::shell_quote(<cmd>)',
        },
    ],
    datasets => [
        {name=>'empty0', args=>{cmd=>[]}},
        {name=>'empty1', args=>{cmd=>['']}},
        {name=>'cmd1', args=>{cmd=>['foo bar']}},
        {name=>'cmd5', args=>{cmd=>['foo', 'bar', 'baz', 'qux', 'quux']}},
    ],
};

1;
# ABSTRACT: Benchmark cross-platform shell quoting

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::ShellQuote::Any - Benchmark cross-platform shell quoting

=head1 VERSION

This document describes version 0.005 of Bencher::Scenario::ShellQuote::Any (from Perl distribution Bencher-Scenario-ShellQuote-Any), released on 2023-01-17.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m ShellQuote::Any

To run module startup overhead benchmark:

 % bencher --module-startup -m ShellQuote::Any

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<ShellQuote::Any> 0.04

L<PERLANCAR::ShellQuote::Any> 0.002

L<ShellQuote::Any::Tiny> 0.007

=head1 BENCHMARK PARTICIPANTS

=over

=item * ShellQuote::Any::shell_quote (perl_code)

Function call template:

 ShellQuote::Any::shell_quote(<cmd>)



=item * PERLANCAR::ShellQuote::Any::shell_quote (perl_code)

Function call template:

 PERLANCAR::ShellQuote::Any::shell_quote(@{<cmd>})



=item * ShellQuote::Any::Tiny::shell_quote (perl_code)

Function call template:

 ShellQuote::Any::Tiny::shell_quote(<cmd>)



=back

=head1 BENCHMARK DATASETS

=over

=item * empty0

=item * empty1

=item * cmd1

=item * cmd5

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.34.0 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 20.04 >>, OS kernel: I<< Linux version 5.4.0-91-generic >>.

Benchmark with default options (C<< bencher -m ShellQuote::Any >>):

 #table1#
 {dataset=>"cmd1"}
 +-----------------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                             | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-----------------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | ShellQuote::Any::shell_quote            |    480000 |      2.08 |                 0.00% |               106.15% | 8.3e-10 |      20 |
 | PERLANCAR::ShellQuote::Any::shell_quote |    519000 |      1.93 |                 8.08% |                90.75% | 7.8e-10 |      23 |
 | ShellQuote::Any::Tiny::shell_quote      |    990000 |      1    |               106.15% |                 0.00% | 1.2e-09 |      20 |
 +-----------------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

Formatted as L<Benchmark.pm|Benchmark> result:

               Rate  SA:s_q  PSA:s_q  SAT:s_q 
  SA:s_q   480000/s      --      -7%     -51% 
  PSA:s_q  519000/s      7%       --     -48% 
  SAT:s_q  990000/s    108%      93%       -- 
 
 Legends:
   PSA:s_q: participant=PERLANCAR::ShellQuote::Any::shell_quote
   SA:s_q: participant=ShellQuote::Any::shell_quote
   SAT:s_q: participant=ShellQuote::Any::Tiny::shell_quote

 #table2#
 {dataset=>"cmd5"}
 +-----------------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                             | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-----------------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | ShellQuote::Any::shell_quote            |    270000 |    3.71   |                 0.00% |               201.05% | 1.7e-09 |      20 |
 | PERLANCAR::ShellQuote::Any::shell_quote |    275320 |    3.6321 |                 2.03% |               195.08% | 1.7e-11 |      20 |
 | ShellQuote::Any::Tiny::shell_quote      |    810000 |    1.2    |               201.05% |                 0.00% | 1.7e-09 |      20 |
 +-----------------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

Formatted as L<Benchmark.pm|Benchmark> result:

               Rate  SA:s_q  PSA:s_q  SAT:s_q 
  SA:s_q   270000/s      --      -2%     -67% 
  PSA:s_q  275320/s      2%       --     -66% 
  SAT:s_q  810000/s    209%     202%       -- 
 
 Legends:
   PSA:s_q: participant=PERLANCAR::ShellQuote::Any::shell_quote
   SA:s_q: participant=ShellQuote::Any::shell_quote
   SAT:s_q: participant=ShellQuote::Any::Tiny::shell_quote

 #table3#
 {dataset=>"empty0"}
 +-----------------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                             | rate (/s) | time (ns) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-----------------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | ShellQuote::Any::shell_quote            |    800000 |      1000 |                 0.00% |                81.09% | 6.5e-08 |      22 |
 | ShellQuote::Any::Tiny::shell_quote      |   1100000 |       930 |                36.99% |                32.19% | 1.7e-09 |      20 |
 | PERLANCAR::ShellQuote::Any::shell_quote |   1400000 |       700 |                81.09% |                 0.00% | 8.5e-10 |      20 |
 +-----------------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

Formatted as L<Benchmark.pm|Benchmark> result:

                Rate  SA:s_q  SAT:s_q  PSA:s_q 
  SA:s_q    800000/s      --      -6%     -30% 
  SAT:s_q  1100000/s      7%       --     -24% 
  PSA:s_q  1400000/s     42%      32%       -- 
 
 Legends:
   PSA:s_q: participant=PERLANCAR::ShellQuote::Any::shell_quote
   SA:s_q: participant=ShellQuote::Any::shell_quote
   SAT:s_q: participant=ShellQuote::Any::Tiny::shell_quote

 #table4#
 {dataset=>"empty1"}
 +-----------------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                             | rate (/s) | time (ns) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-----------------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | ShellQuote::Any::shell_quote            |    750000 |      1300 |                 0.00% |                32.65% | 1.7e-09 |      20 |
 | PERLANCAR::ShellQuote::Any::shell_quote |    810000 |      1200 |                 8.74% |                21.99% | 1.7e-09 |      20 |
 | ShellQuote::Any::Tiny::shell_quote      |    990000 |      1000 |                32.65% |                 0.00% | 1.7e-09 |      20 |
 +-----------------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

Formatted as L<Benchmark.pm|Benchmark> result:

               Rate  SA:s_q  PSA:s_q  SAT:s_q 
  SA:s_q   750000/s      --      -7%     -23% 
  PSA:s_q  810000/s      8%       --     -16% 
  SAT:s_q  990000/s     30%      19%       -- 
 
 Legends:
   PSA:s_q: participant=PERLANCAR::ShellQuote::Any::shell_quote
   SA:s_q: participant=ShellQuote::Any::shell_quote
   SAT:s_q: participant=ShellQuote::Any::Tiny::shell_quote


Benchmark module startup overhead (C<< bencher -m ShellQuote::Any --module-startup >>):

 #table5#
 +----------------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | participant                | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +----------------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | ShellQuote::Any            |        10 |                 2 |                 0.00% |                51.94% | 0.0004  |      20 |
 | PERLANCAR::ShellQuote::Any |        10 |                 2 |                12.46% |                35.11% | 0.00016 |      20 |
 | ShellQuote::Any::Tiny      |         9 |                 1 |                27.78% |                18.91% | 0.00017 |      20 |
 | perl -e1 (baseline)        |         8 |                 0 |                51.94% |                 0.00% | 0.00018 |      20 |
 +----------------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+


Formatted as L<Benchmark.pm|Benchmark> result:

                          Rate  S:A  PS:A  SA:T  perl -e1 (baseline) 
  S:A                  100.0/s   --    0%   -9%                 -19% 
  PS:A                 100.0/s   0%    --   -9%                 -19% 
  SA:T                 111.1/s  11%   11%    --                 -11% 
  perl -e1 (baseline)  125.0/s  25%   25%   12%                   -- 
 
 Legends:
   PS:A: mod_overhead_time=2 participant=PERLANCAR::ShellQuote::Any
   S:A: mod_overhead_time=2 participant=ShellQuote::Any
   SA:T: mod_overhead_time=1 participant=ShellQuote::Any::Tiny
   perl -e1 (baseline): mod_overhead_time=0 participant=perl -e1 (baseline)

To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-ShellQuote-Any>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-ShellQuote-Any>.

=head1 SEE ALSO

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-ShellQuote-Any>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
