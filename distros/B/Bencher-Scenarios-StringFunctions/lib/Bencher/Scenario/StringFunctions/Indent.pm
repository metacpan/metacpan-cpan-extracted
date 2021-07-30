package Bencher::Scenario::StringFunctions::Indent;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-07-30'; # DATE
our $DIST = 'Bencher-Scenarios-StringFunctions'; # DIST
our $VERSION = '0.004'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => "Benchmark string indenting (adding whitespace to lines of text)",
    participants => [
        {fcall_template=>'String::Nudge::nudge(<num_spaces>, <str>)'},
        {fcall_template=>'String::Indent::indent(<indent>, <str>)'},
        {fcall_template=>'String::Indent::Join::indent(<indent>, <str>)'},
        # TODO: Indent::String
        # TODO: Indent::Utils
        # TODO: Text::Indent
    ],
    datasets => [
        {name=>'empty'        , args=>{num_spaces=>4, indent=>'    ', str=>''}},
        {name=>'1line'        , args=>{num_spaces=>4, indent=>'    ', str=>join("", map {"line $_\n"} 1..1)}},
        {name=>'10line'       , args=>{num_spaces=>4, indent=>'    ', str=>join("", map {"line $_\n"} 1..10)}},
        {name=>'100line'      , args=>{num_spaces=>4, indent=>'    ', str=>join("", map {"line $_\n"} 1..100)}},
        {name=>'1000line'     , args=>{num_spaces=>4, indent=>'    ', str=>join("", map {"line $_\n"} 1..1000)}},
    ],
};

1;
# ABSTRACT: Benchmark string indenting (adding whitespace to lines of text)

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::StringFunctions::Indent - Benchmark string indenting (adding whitespace to lines of text)

=head1 VERSION

This document describes version 0.004 of Bencher::Scenario::StringFunctions::Indent (from Perl distribution Bencher-Scenarios-StringFunctions), released on 2021-07-30.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m StringFunctions::Indent

To run module startup overhead benchmark:

 % bencher --module-startup -m StringFunctions::Indent

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<String::Nudge> 1.0002

L<String::Indent> 0.03

L<String::Indent::Join>

=head1 BENCHMARK PARTICIPANTS

=over

=item * String::Nudge::nudge (perl_code)

Function call template:

 String::Nudge::nudge(<num_spaces>, <str>)



=item * String::Indent::indent (perl_code)

Function call template:

 String::Indent::indent(<indent>, <str>)



=item * String::Indent::Join::indent (perl_code)

Function call template:

 String::Indent::Join::indent(<indent>, <str>)



=back

=head1 BENCHMARK DATASETS

=over

=item * empty

=item * 1line

=item * 10line

=item * 100line

=item * 1000line

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.34.0 >>, CPU: I<< Intel(R) Core(TM) i7-4770 CPU @ 3.40GHz (4 cores) >>, OS: I<< GNU/Linux LinuxMint version 19 >>, OS kernel: I<< Linux version 5.3.0-68-generic >>.

Benchmark with default options (C<< bencher -m StringFunctions::Indent >>):

 #table1#
 {dataset=>"1000line"}
 +------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                  | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | String::Indent::indent       |      3000 |       333 |                 0.00% |                61.66% | 4.8e-08 |      25 |
 | String::Nudge::nudge         |      4000 |       250 |                33.38% |                21.20% | 5.3e-08 |      20 |
 | String::Indent::Join::indent |      4850 |       206 |                61.66% |                 0.00% | 1.6e-07 |      35 |
 +------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

Formatted as L<Benchmark.pm|Benchmark> result:

           Rate  SI:i  SN:n  SIJ:i 
  SI:i   3000/s    --  -24%   -38% 
  SN:n   4000/s   33%    --   -17% 
  SIJ:i  4850/s   61%   21%     -- 
 
 Legends:
   SI:i: participant=String::Indent::indent
   SIJ:i: participant=String::Indent::Join::indent
   SN:n: participant=String::Nudge::nudge

 #table2#
 {dataset=>"100line"}
 +------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                  | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | String::Indent::indent       |   28385.9 |   35.2288 |                 0.00% |                88.36% |   0     |      21 |
 | String::Nudge::nudge         |   36903.3 |   27.0978 |                30.01% |                44.89% | 5.8e-12 |      26 |
 | String::Indent::Join::indent |   53468   |   18.703  |                88.36% |                 0.00% | 2.3e-11 |      20 |
 +------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

Formatted as L<Benchmark.pm|Benchmark> result:

              Rate  SI:i  SN:n  SIJ:i 
  SI:i   28385.9/s    --  -23%   -46% 
  SN:n   36903.3/s   30%    --   -30% 
  SIJ:i    53468/s   88%   44%     -- 
 
 Legends:
   SI:i: participant=String::Indent::indent
   SIJ:i: participant=String::Indent::Join::indent
   SN:n: participant=String::Nudge::nudge

 #table3#
 {dataset=>"10line"}
 +------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                  | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | String::Indent::indent       |    219830 |   4.5489  |                 0.00% |               109.38% | 5.4e-12 |      20 |
 | String::Nudge::nudge         |    280000 |   3.6     |                26.62% |                65.36% | 6.7e-09 |      20 |
 | String::Indent::Join::indent |    460297 |   2.17251 |               109.38% |                 0.00% |   0     |      20 |
 +------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

Formatted as L<Benchmark.pm|Benchmark> result:

             Rate  SI:i  SN:n  SIJ:i 
  SI:i   219830/s    --  -20%   -52% 
  SN:n   280000/s   26%    --   -39% 
  SIJ:i  460297/s  109%   65%     -- 
 
 Legends:
   SI:i: participant=String::Indent::indent
   SIJ:i: participant=String::Indent::Join::indent
   SN:n: participant=String::Nudge::nudge

 #table4#
 {dataset=>"1line"}
 +------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                  | rate (/s) | time (ns) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | String::Indent::indent       |    856314 |  1167.8   |                 0.00% |               171.82% |   0     |      20 |
 | String::Nudge::nudge         |   1020000 |   980.4   |                19.11% |               128.20% | 5.6e-12 |      20 |
 | String::Indent::Join::indent |   2327620 |   429.624 |               171.82% |                 0.00% |   0     |      29 |
 +------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

Formatted as L<Benchmark.pm|Benchmark> result:

              Rate  SI:i  SN:n  SIJ:i 
  SI:i    856314/s    --  -16%   -63% 
  SN:n   1020000/s   19%    --   -56% 
  SIJ:i  2327620/s  171%  128%     -- 
 
 Legends:
   SI:i: participant=String::Indent::indent
   SIJ:i: participant=String::Indent::Join::indent
   SN:n: participant=String::Nudge::nudge

 #table5#
 {dataset=>"empty"}
 +------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                  | rate (/s) | time (ns) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | String::Indent::indent       |    903880 |    1106.3 |                 0.00% |               565.74% | 5.8e-12 |      20 |
 | String::Nudge::nudge         |   1226000 |     815.6 |                35.64% |               390.80% |   2e-11 |      20 |
 | String::Indent::Join::indent |   6017000 |     166.2 |               565.74% |                 0.00% | 5.8e-12 |      20 |
 +------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

Formatted as L<Benchmark.pm|Benchmark> result:

              Rate  SI:i  SN:n  SIJ:i 
  SI:i    903880/s    --  -26%   -84% 
  SN:n   1226000/s   35%    --   -79% 
  SIJ:i  6017000/s  565%  390%     -- 
 
 Legends:
   SI:i: participant=String::Indent::indent
   SIJ:i: participant=String::Indent::Join::indent
   SN:n: participant=String::Nudge::nudge


Benchmark module startup overhead (C<< bencher -m StringFunctions::Indent --module-startup >>):

 #table6#
 +----------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | participant          | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +----------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | String::Indent::Join |       7   |               3   |                 0.00% |                81.24% | 0.00012 |      20 |
 | String::Nudge        |       7.3 |               3.3 |                 0.94% |                79.55% | 7e-05   |      20 |
 | String::Indent       |       7   |               3   |                 4.08% |                74.14% | 0.00013 |      20 |
 | perl -e1 (baseline)  |       4   |               0   |                81.24% |                 0.00% | 0.00019 |      20 |
 +----------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+


Formatted as L<Benchmark.pm|Benchmark> result:

                Rate  S:N  SI:J  S:I  :perl -e1 ( 
  S:N          0.1/s   --   -4%  -4%         -45% 
  SI:J         0.1/s   4%    --   0%         -42% 
  S:I          0.1/s   4%    0%   --         -42% 
  :perl -e1 (  0.2/s  82%   75%  75%           -- 
 
 Legends:
   :perl -e1 (: mod_overhead_time=0 participant=perl -e1 (baseline)
   S:I: mod_overhead_time=3 participant=String::Indent
   S:N: mod_overhead_time=3.3 participant=String::Nudge
   SI:J: mod_overhead_time=3 participant=String::Indent::Join

To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 BENCHMARK NOTES

Joining is faster than regex substitution for the datasets tested (0-1000
lines of short text).

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-StringFunctions>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-StringFunctions>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-StringFunctions>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
