package Bencher::Scenario::ExceptionHandling;

use 5.034;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-02-23'; # DATE
our $DIST = 'Bencher-Scenario-ExceptionHandling'; # DIST
our $VERSION = '0.001'; # VERSION

our $scenario = {
    summary => 'Benchmark various ways to do exception handling in Perl',
    participants => [
        {
            name => "builtin-try",
            description => <<'MARKDOWN',

Requires perl 5.34+.

MARKDOWN
            code_template => q|use feature 'try'; use experimental 'try'; try { <code_try:raw> } catch($e) { <code_catch:raw> }|,
            # TODO: finally block (in 5.36)
        },

        {
            name => "naive-eval",
            description => <<'MARKDOWN',

MARKDOWN
            code_template => q|eval { <code_try:raw> }; if ($@) { <code_catch:raw> }|,
        },

        {
            name => "eval-localize-die-signal-and-eval-error",
            description => <<'MARKDOWN',

MARKDOWN
            code_template => q|{ local $@; local $SIG{__DIE__}; eval { <code_try:raw> }; if ($@) { <code_catch:raw> } }|,
        },

        {
            name => "Try::Tiny",
            module => 'Try::Tiny',
            description => <<'MARKDOWN',

MARKDOWN
            code_template => q|use Try::Tiny; try { <code_try:raw> } catch { <code_catch:raw> }|,
        },
    ],
    precision => 7,
    datasets => [
        {name=>'empty try, empty catch', args=>{code_try=>'', code_catch=>''}},
        {name=>'die in try, empty catch', args=>{code_try=>'die', code_catch=>''}},
    ],
};

1;
# ABSTRACT: Benchmark various ways to do exception handling in Perl

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::ExceptionHandling - Benchmark various ways to do exception handling in Perl

=head1 VERSION

This document describes version 0.001 of Bencher::Scenario::ExceptionHandling (from Perl distribution Bencher-Scenario-ExceptionHandling), released on 2024-02-23.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m ExceptionHandling

To run module startup overhead benchmark:

 % bencher --module-startup -m ExceptionHandling

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Keywords: try-catch, eval, die

TODO: benchmark other try-catch modules.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Try::Tiny> 0.31

=head1 BENCHMARK PARTICIPANTS

=over

=item * builtin-try (perl_code)

Code template:

 use feature 'try'; use experimental 'try'; try { <code_try:raw> } catch($e) { <code_catch:raw> }

Requires perl 5.34+.




=item * naive-eval (perl_code)

Code template:

 eval { <code_try:raw> }; if ($@) { <code_catch:raw> }






=item * eval-localize-die-signal-and-eval-error (perl_code)

Code template:

 { local $@; local $SIG{__DIE__}; eval { <code_try:raw> }; if ($@) { <code_catch:raw> } }






=item * Try::Tiny (perl_code)

Code template:

 use Try::Tiny; try { <code_try:raw> } catch { <code_catch:raw> }






=back

=head1 BENCHMARK DATASETS

=over

=item * empty try, empty catch

=item * die in try, empty catch

=back

=head1 BENCHMARK SAMPLE RESULTS

=head2 Sample benchmark #1

Run on: perl: I<< v5.38.2 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 20.04 >>, OS kernel: I<< Linux version 5.4.0-164-generic >>.

Benchmark command (default options):

 % bencher -m ExceptionHandling

Result formatted as table (split, part 1 of 2):

 #table1#
 {dataset=>"die in try, empty catch"}
 +-----------------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                             | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-----------------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | Try::Tiny                               |    310000 |      3.23 |                 0.00% |               602.22% | 2.1e-09 |       8 |
 | eval-localize-die-signal-and-eval-error |   1000000 |      1    |               207.56% |               128.32% | 1.2e-08 |       9 |
 | builtin-try                             |   1700000 |      0.6  |               438.20% |                30.48% | 1.1e-09 |       7 |
 | naive-eval                              |   2170000 |      0.46 |               602.22% |                 0.00% | 3.6e-10 |       8 |
 +-----------------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

The above result formatted in L<Benchmark.pm|Benchmark> style:

            Rate   T:T     e     b     n 
  T:T   310000/s    --  -69%  -81%  -85% 
  e    1000000/s  223%    --  -40%  -54% 
  b    1700000/s  438%   66%    --  -23% 
  n    2170000/s  602%  117%   30%    -- 
 
 Legends:
   T:T: participant=Try::Tiny
   b: participant=builtin-try
   e: participant=eval-localize-die-signal-and-eval-error
   n: participant=naive-eval

The above result presented as chart:

#IMAGE: share/images/bencher-result-1.png|/tmp/VHOUgvh_oa/bencher-result-1.png

Result formatted as table (split, part 2 of 2):

 #table2#
 {dataset=>"empty try, empty catch"}
 +-----------------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                             | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-----------------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | Try::Tiny                               |    397000 |      2.52 |                 0.00% |              6147.90% | 5.8e-10 |       8 |
 | eval-localize-die-signal-and-eval-error |   1700000 |      0.59 |               328.63% |              1357.65% | 6.5e-10 |       7 |
 | builtin-try                             |   8400000 |      0.12 |              2022.06% |               194.43% | 1.9e-10 |       7 |
 | naive-eval                              |  25000000 |      0.04 |              6147.90% |                 0.00% |   8e-11 |       7 |
 +-----------------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

The above result formatted in L<Benchmark.pm|Benchmark> style:

             Rate    T:T      e     b     n 
  T:T    397000/s     --   -76%  -95%  -98% 
  e     1700000/s   327%     --  -79%  -93% 
  b     8400000/s  2000%   391%    --  -66% 
  n    25000000/s  6200%  1374%  200%    -- 
 
 Legends:
   T:T: participant=Try::Tiny
   b: participant=builtin-try
   e: participant=eval-localize-die-signal-and-eval-error
   n: participant=naive-eval

The above result presented as chart:

#IMAGE: share/images/bencher-result-2.png|/tmp/VHOUgvh_oa/bencher-result-2.png


=head2 Sample benchmark #2

Benchmark command (benchmarking module startup overhead):

 % bencher -m ExceptionHandling --module-startup

Result formatted as table:

 #table3#
 +---------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | participant         | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +---------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | Try::Tiny           |      14   |               8.4 |                 0.00% |               145.39% | 1.8e-05 |       7 |
 | perl -e1 (baseline) |       5.6 |               0   |               145.39% |                 0.00% | 1.6e-05 |       7 |
 +---------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+


The above result formatted in L<Benchmark.pm|Benchmark> style:

                          Rate   T:T  perl -e1 (baseline) 
  T:T                   71.4/s    --                 -60% 
  perl -e1 (baseline)  178.6/s  150%                   -- 
 
 Legends:
   T:T: mod_overhead_time=8.4 participant=Try::Tiny
   perl -e1 (baseline): mod_overhead_time=0 participant=perl -e1 (baseline)

The above result presented as chart:

#IMAGE: share/images/bencher-result-3.png|/tmp/VHOUgvh_oa/bencher-result-3.png

To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-ExceptionHandling>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-ExceptionHandling>.

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-ExceptionHandling>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
