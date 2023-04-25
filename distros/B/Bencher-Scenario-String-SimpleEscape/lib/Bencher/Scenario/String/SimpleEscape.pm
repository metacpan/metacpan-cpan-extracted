package Bencher::Scenario::String::SimpleEscape;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-01-18'; # DATE
our $DIST = 'Bencher-Scenario-String-SimpleEscape'; # DIST
our $VERSION = '0.002'; # VERSION

our $scenario = {
    summary => 'Benchmark String::SimpleEscape',
    participants => [
        {fcall_template => 'String::Escape::backslash(<str>)'},
        {fcall_template => 'String::Escape::unbackslash(<str>)'},
        {fcall_template => 'String::SimpleEscape::simple_escape_string(<str>)'},
        {fcall_template => 'String::SimpleEscape::simple_unescape_string(<str>)'},
    ],
    datasets => [
        {name=>'str0', args=>{str=>''}},
        {name=>'a100', args=>{str=>'a' x 100}},
        {name=>'backslash100', args=>{str=>"\\" x 100}},
    ],
};

1;
# ABSTRACT: Benchmark String::SimpleEscape

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::String::SimpleEscape - Benchmark String::SimpleEscape

=head1 VERSION

This document describes version 0.002 of Bencher::Scenario::String::SimpleEscape (from Perl distribution Bencher-Scenario-String-SimpleEscape), released on 2023-01-18.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m String::SimpleEscape

To run module startup overhead benchmark:

 % bencher --module-startup -m String::SimpleEscape

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<String::Escape> 2010.002

L<String::SimpleEscape> 0.001

=head1 BENCHMARK PARTICIPANTS

=over

=item * String::Escape::backslash (perl_code)

Function call template:

 String::Escape::backslash(<str>)



=item * String::Escape::unbackslash (perl_code)

Function call template:

 String::Escape::unbackslash(<str>)



=item * String::SimpleEscape::simple_escape_string (perl_code)

Function call template:

 String::SimpleEscape::simple_escape_string(<str>)



=item * String::SimpleEscape::simple_unescape_string (perl_code)

Function call template:

 String::SimpleEscape::simple_unescape_string(<str>)



=back

=head1 BENCHMARK DATASETS

=over

=item * str0

=item * a100

=item * backslash100

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.34.0 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 20.04 >>, OS kernel: I<< Linux version 5.4.0-91-generic >>.

Benchmark with default options (C<< bencher -m String::SimpleEscape >>):

 #table1#
 +----------------------------------------------+--------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                                  | dataset      | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +----------------------------------------------+--------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | String::Escape::backslash                    | backslash100 |   31139.4 |   32.1136 |                 0.00% |             28420.89% | 1.1e-11 |      20 |
 | String::SimpleEscape::simple_escape_string   | backslash100 |   33000   |   30      |                 6.73% |             26623.69% | 1.2e-07 |      20 |
 | String::Escape::unbackslash                  | backslash100 |   39900   |   25      |                28.24% |             22140.90% | 5.5e-09 |      29 |
 | String::SimpleEscape::simple_unescape_string | backslash100 |   59000   |   17      |                90.23% |             14892.95% |   2e-08 |      20 |
 | String::Escape::backslash                    | a100         | 2439000   |    0.41   |              7731.71% |               264.17% | 3.5e-11 |      20 |
 | String::SimpleEscape::simple_escape_string   | a100         | 2720000   |    0.368  |              8627.49% |               226.79% |   2e-10 |      22 |
 | String::Escape::unbackslash                  | a100         | 5060000   |    0.198  |             16135.76% |                75.67% | 8.1e-11 |      34 |
 | String::Escape::unbackslash                  | str0         | 6009000   |    0.1664 |             19195.62% |                47.81% | 1.2e-11 |      20 |
 | String::Escape::backslash                    | str0         | 6160000   |    0.162  |             19668.54% |                44.27% |   1e-10 |      20 |
 | String::SimpleEscape::simple_unescape_string | a100         | 6663000   |    0.1501 |             21296.23% |                33.30% | 1.2e-11 |      26 |
 | String::SimpleEscape::simple_escape_string   | str0         | 8100000   |    0.123  |             25925.57% |                 9.59% | 4.6e-11 |      20 |
 | String::SimpleEscape::simple_unescape_string | str0         | 8900000   |    0.11   |             28420.89% |                 0.00% | 1.6e-10 |      20 |
 +----------------------------------------------+--------------+-----------+-----------+-----------------------+-----------------------+---------+---------+


Formatted as L<Benchmark.pm|Benchmark> result:

                              Rate  SE:b backslash100  SS:s_e_s backslash100  SE:u backslash100  SS:s_u_s backslash100  SE:b a100  SS:s_e_s a100  SE:u a100  SE:u str0  SE:b str0  SS:s_u_s a100  SS:s_e_s str0  SS:s_u_s str0 
  SE:b backslash100      31139.4/s                 --                    -6%               -22%                   -47%       -98%           -98%       -99%       -99%       -99%           -99%           -99%           -99% 
  SS:s_e_s backslash100    33000/s                 7%                     --               -16%                   -43%       -98%           -98%       -99%       -99%       -99%           -99%           -99%           -99% 
  SE:u backslash100        39900/s                28%                    19%                 --                   -31%       -98%           -98%       -99%       -99%       -99%           -99%           -99%           -99% 
  SS:s_u_s backslash100    59000/s                88%                    76%                47%                     --       -97%           -97%       -98%       -99%       -99%           -99%           -99%           -99% 
  SE:b a100              2439000/s              7732%                  7217%              5997%                  4046%         --           -10%       -51%       -59%       -60%           -63%           -70%           -73% 
  SS:s_e_s a100          2720000/s              8626%                  8052%              6693%                  4519%        11%             --       -46%       -54%       -55%           -59%           -66%           -70% 
  SE:u a100              5060000/s             16118%                 15051%             12526%                  8485%       107%            85%         --       -15%       -18%           -24%           -37%           -44% 
  SE:u str0              6009000/s             19199%                 17928%             14924%                 10116%       146%           121%        18%         --        -2%            -9%           -26%           -33% 
  SE:b str0              6160000/s             19723%                 18418%             15332%                 10393%       153%           127%        22%         2%         --            -7%           -24%           -32% 
  SS:s_u_s a100          6663000/s             21294%                 19886%             16555%                 11225%       173%           145%        31%        10%         7%             --           -18%           -26% 
  SS:s_e_s str0          8100000/s             26008%                 24290%             20225%                 13721%       233%           199%        60%        35%        31%            22%             --           -10% 
  SS:s_u_s str0          8900000/s             29094%                 27172%             22627%                 15354%       272%           234%        80%        51%        47%            36%            11%             -- 
 
 Legends:
   SE:b a100: dataset=a100 participant=String::Escape::backslash
   SE:b backslash100: dataset=backslash100 participant=String::Escape::backslash
   SE:b str0: dataset=str0 participant=String::Escape::backslash
   SE:u a100: dataset=a100 participant=String::Escape::unbackslash
   SE:u backslash100: dataset=backslash100 participant=String::Escape::unbackslash
   SE:u str0: dataset=str0 participant=String::Escape::unbackslash
   SS:s_e_s a100: dataset=a100 participant=String::SimpleEscape::simple_escape_string
   SS:s_e_s backslash100: dataset=backslash100 participant=String::SimpleEscape::simple_escape_string
   SS:s_e_s str0: dataset=str0 participant=String::SimpleEscape::simple_escape_string
   SS:s_u_s a100: dataset=a100 participant=String::SimpleEscape::simple_unescape_string
   SS:s_u_s backslash100: dataset=backslash100 participant=String::SimpleEscape::simple_unescape_string
   SS:s_u_s str0: dataset=str0 participant=String::SimpleEscape::simple_unescape_string

Benchmark module startup overhead (C<< bencher -m String::SimpleEscape --module-startup >>):

 #table2#
 +----------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | participant          | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +----------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | String::Escape       |      15   |               9   |                 0.00% |               144.86% | 7.6e-05 |      21 |
 | String::SimpleEscape |       8.9 |               2.9 |                64.03% |                49.28% | 4.6e-05 |      20 |
 | perl -e1 (baseline)  |       6   |               0   |               144.86% |                 0.00% | 2.7e-05 |      21 |
 +----------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+


Formatted as L<Benchmark.pm|Benchmark> result:

                          Rate   S:E   S:S  perl -e1 (baseline) 
  S:E                   66.7/s    --  -40%                 -60% 
  S:S                  112.4/s   68%    --                 -32% 
  perl -e1 (baseline)  166.7/s  150%   48%                   -- 
 
 Legends:
   S:E: mod_overhead_time=9 participant=String::Escape
   S:S: mod_overhead_time=2.9 participant=String::SimpleEscape
   perl -e1 (baseline): mod_overhead_time=0 participant=perl -e1 (baseline)

To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-String-SimpleEscape>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-String-SimpleEscape>.

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-String-SimpleEscape>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
