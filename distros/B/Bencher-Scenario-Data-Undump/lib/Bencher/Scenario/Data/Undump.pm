package Bencher::Scenario::Data::Undump;

use 5.010001;
use strict;
use warnings;

use Data::Dumper;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-03-19'; # DATE
our $DIST = 'Bencher-Scenario-Data-Undump'; # DIST
our $VERSION = '0.003'; # VERSION

my $array10mixed = [
    undef,
    1,
    1.1,
    "",
    "string",

    "string with some control characters: \n, \b",
    [],
    [1,2,3],
    {},
    {a=>1,b=>2,c=>3},
];

our $scenario = {
    summary => 'Benchmark Data::Undump against eval() for loading a Data::Dumper output',
    participants => [
        {
            fcall_template=>'Data::Undump::undump(<dump>)',
        },
        {
            name=>'eval',
            code_template=>'eval(<dump>)',
        },
    ],
    datasets => [
        {
            name => 'array100i',
            summary => 'Array of 100 integers',
            args => {dump=> Data::Dumper->new([[1..100]])->Terse(1)->Dump },
            result => [1..100],
        },
        {
            name => 'array1000i',
            summary => 'Array of 1000 integers',
            args => {dump=> Data::Dumper->new([[1..1000]])->Terse(1)->Dump },
            result => [1..1000],
        },
        {
            name => 'array10mixed',
            summary => 'A 10-element array containing a mix of various Perl data items',
            args => {dump=> Data::Dumper->new([$array10mixed])->Terse(1)->Dump },
            result => $array10mixed,
        },
    ],
};

1;
# ABSTRACT: Benchmark Data::Undump against eval() for loading a Data::Dumper output

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::Data::Undump - Benchmark Data::Undump against eval() for loading a Data::Dumper output

=head1 VERSION

This document describes version 0.003 of Bencher::Scenario::Data::Undump (from Perl distribution Bencher-Scenario-Data-Undump), released on 2022-03-19.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m Data::Undump

To run module startup overhead benchmark:

 % bencher --module-startup -m Data::Undump

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Data::Undump> 0.15

=head1 BENCHMARK PARTICIPANTS

=over

=item * Data::Undump::undump (perl_code)

Function call template:

 Data::Undump::undump(<dump>)



=item * eval (perl_code)

Code template:

 eval(<dump>)



=back

=head1 BENCHMARK DATASETS

=over

=item * array100i

Array of 100 integers.

=item * array1000i

Array of 1000 integers.

=item * array10mixed

A 10-element array containing a mix of various Perl data items.

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.34.0 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 20.04 >>, OS kernel: I<< Linux version 5.4.0-91-generic >>.

Benchmark with default options (C<< bencher -m Data::Undump >>):

 #table1#
 {dataset=>"array1000i"}
 +----------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant          | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +----------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | eval                 |      5300 |     190   |                 0.00% |               445.39% | 2.6e-07 |      21 |
 | Data::Undump::undump |     29200 |      34.3 |               445.39% |                 0.00% | 1.3e-08 |      22 |
 +----------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

Formatted as L<Benchmark.pm|Benchmark> result:

           Rate     e  DU:u 
  e      5300/s    --  -81% 
  DU:u  29200/s  453%    -- 
 
 Legends:
   DU:u: participant=Data::Undump::undump
   e: participant=eval

 #table2#
 {dataset=>"array100i"}
 +----------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant          | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +----------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | eval                 |     44000 |      22   |                 0.00% |               434.05% | 2.7e-08 |      20 |
 | Data::Undump::undump |    240000 |       4.2 |               434.05% |                 0.00% |   5e-09 |      20 |
 +----------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

Formatted as L<Benchmark.pm|Benchmark> result:

            Rate     e  DU:u 
  e      44000/s    --  -80% 
  DU:u  240000/s  423%    -- 
 
 Legends:
   DU:u: participant=Data::Undump::undump
   e: participant=eval

 #table3#
 {dataset=>"array10mixed"}
 +----------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant          | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +----------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | eval                 |     75000 |      13   |                 0.00% |               680.30% |   2e-08 |      20 |
 | Data::Undump::undump |    587000 |       1.7 |               680.30% |                 0.00% | 7.9e-10 |      22 |
 +----------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

Formatted as L<Benchmark.pm|Benchmark> result:

            Rate     e  DU:u 
  e      75000/s    --  -86% 
  DU:u  587000/s  664%    -- 
 
 Legends:
   DU:u: participant=Data::Undump::undump
   e: participant=eval


Benchmark module startup overhead (C<< bencher -m Data::Undump --module-startup >>):

 #table4#
 +---------------------+-----------+-------------------+-----------------------+-----------------------+-----------+---------+
 | participant         | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors   | samples |
 +---------------------+-----------+-------------------+-----------------------+-----------------------+-----------+---------+
 | Data::Undump        |      9.25 |              2.25 |                 0.00% |                25.88% | 8.5e-06   |      21 |
 | perl -e1 (baseline) |      7    |              0    |                25.88% |                 0.00% |   0.00013 |      20 |
 +---------------------+-----------+-------------------+-----------------------+-----------------------+-----------+---------+


Formatted as L<Benchmark.pm|Benchmark> result:

                          Rate  D:U  perl -e1 (baseline) 
  D:U                  108.1/s   --                 -24% 
  perl -e1 (baseline)  142.9/s  32%                   -- 
 
 Legends:
   D:U: mod_overhead_time=2.25 participant=Data::Undump
   perl -e1 (baseline): mod_overhead_time=0 participant=perl -e1 (baseline)

To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-Data-Undump>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-DataUndump>.

=head1 SEE ALSO

L<https://www.reddit.com/r/perl/comments/czhwe6/syntax_differences_from_data_dumper_to_json/ez95r7c?utm_source=share&utm_medium=web2x>

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-Data-Undump>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
