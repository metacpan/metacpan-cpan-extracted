package Bencher::Scenario::Ref::Util;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-12-04'; # DATE
our $DIST = 'Bencher-ScenarioBundle-Ref-Util'; # DIST
our $VERSION = '0.003'; # VERSION

our $scenario = {
    summary => 'Benchmark Ref::Util',
    precision => 0.001,
    participants => [
        {
            name=>'is_arrayref',
            module => 'Ref::Util',
            code_template => 'no warnings "void"; state $ref = []; Ref::Util::is_arrayref($ref) for 1..1000',
        },
        {
            name=>'is_plain_arrayref',
            module => 'Ref::Util',
            code_template => 'no warnings "void"; state $ref = []; Ref::Util::is_plain_arrayref($ref) for 1..1000',
        },
        {
            name=>'ref(ARRAY)',
            code_template => 'no warnings "void"; state $ref = []; ref($ref) eq "ARRAY" for 1..1000',
        },
        {
            name=>'reftype(ARRAY)',
            module => 'Scalar::Util',
            code_template => 'no warnings "void"; state $ref = []; Scalar::Util::reftype($ref) eq "ARRAY" for 1..1000',
        },
    ],
};

1;
# ABSTRACT: Benchmark Ref::Util

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::Ref::Util - Benchmark Ref::Util

=head1 VERSION

This document describes version 0.003 of Bencher::Scenario::Ref::Util (from Perl distribution Bencher-ScenarioBundle-Ref-Util), released on 2024-12-04.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m Ref::Util

To run module startup overhead benchmark:

 % bencher --module-startup -m Ref::Util

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Ref::Util> 0.204

L<Scalar::Util> 1.63

=head1 BENCHMARK PARTICIPANTS

=over

=item * is_arrayref (perl_code)

Code template:

 no warnings "void"; state $ref = []; Ref::Util::is_arrayref($ref) for 1..1000



=item * is_plain_arrayref (perl_code)

Code template:

 no warnings "void"; state $ref = []; Ref::Util::is_plain_arrayref($ref) for 1..1000



=item * ref(ARRAY) (perl_code)

Code template:

 no warnings "void"; state $ref = []; ref($ref) eq "ARRAY" for 1..1000



=item * reftype(ARRAY) (perl_code)

Code template:

 no warnings "void"; state $ref = []; Scalar::Util::reftype($ref) eq "ARRAY" for 1..1000



=back

=head1 BENCHMARK SAMPLE RESULTS

=head2 Sample benchmark #1

Run on: perl: I<< v5.40.0 >>, CPU: I<< 12th Gen Intel(R) Core(TM) i7-1250U (10 cores) >>, OS: I<< GNU/Linux Debian version 12 >>, OS kernel: I<< Linux version 6.1.0-26-amd64 >>.

Benchmark command (default options):

 % bencher -m Ref::Util

Result formatted as table:

 #table1#
 +-------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant       | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | reftype(ARRAY)    |     20100 |     49.8  |                 0.00% |               210.49% | 4.8e-08 |     136 |
 | ref(ARRAY)        |     30700 |     32.6  |                53.02% |               102.91% | 3.2e-08 |     135 |
 | is_plain_arrayref |     62000 |     16.1  |               209.05% |                 0.47% | 1.5e-08 |      22 |
 | is_arrayref       |     62290 |     16.05 |               210.49% |                 0.00% | 9.5e-10 |      20 |
 +-------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+


The above result formatted in L<Benchmark.pm|Benchmark> style:

                        Rate  reftype(ARRAY)  ref(ARRAY)  is_plain_arrayref  is_arrayref 
  reftype(ARRAY)     20100/s              --        -34%               -67%         -67% 
  ref(ARRAY)         30700/s             52%          --               -50%         -50% 
  is_plain_arrayref  62000/s            209%        102%                 --           0% 
  is_arrayref        62290/s            210%        103%                 0%           -- 
 
 Legends:
   is_arrayref: participant=is_arrayref
   is_plain_arrayref: participant=is_plain_arrayref
   ref(ARRAY): participant=ref(ARRAY)
   reftype(ARRAY): participant=reftype(ARRAY)

=head2 Sample benchmark #2

Benchmark command (benchmarking module startup overhead):

 % bencher -m Ref::Util --module-startup

Result formatted as table:

 #table2#
 +---------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | participant         | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +---------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | Ref::Util           |       7.6 |               4   |                 0.00% |               111.74% | 1.1e-05 |    9461 |
 | Scalar::Util        |       7.2 |               3.6 |                 5.56% |               100.58% | 7.9e-06 |    9402 |
 | perl -e1 (baseline) |       3.6 |               0   |               111.74% |                 0.00% | 3.5e-06 |    3802 |
 +---------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+


The above result formatted in L<Benchmark.pm|Benchmark> style:

                          Rate   R:U   S:U  perl -e1 (baseline) 
  R:U                  131.6/s    --   -5%                 -52% 
  S:U                  138.9/s    5%    --                 -50% 
  perl -e1 (baseline)  277.8/s  111%  100%                   -- 
 
 Legends:
   R:U: mod_overhead_time=4 participant=Ref::Util
   S:U: mod_overhead_time=3.6 participant=Scalar::Util
   perl -e1 (baseline): mod_overhead_time=0 participant=perl -e1 (baseline)

To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-ScenarioBundle-Ref-Util>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-ScenarioBundle-Ref-Util>.

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

This software is copyright (c) 2024 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-ScenarioBundle-Ref-Util>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
