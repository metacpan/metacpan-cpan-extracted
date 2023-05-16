package Bencher::Scenario::Color::ANSI::Util::ansifg;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-01-18'; # DATE
our $DIST = 'Bencher-Scenarios-Color-ANSI-Util'; # DIST
our $VERSION = '0.003'; # VERSION

our $scenario = {
    summary => 'Benchmark ansifg()',
    participants => [
        {
            fcall_template => 'Color::ANSI::Util::ansi16fg(<rgb>)',
        },
        {
            fcall_template => 'Color::ANSI::Util::ansi256fg(<rgb>)',
        },
        {
            fcall_template => 'Color::ANSI::Util::ansi24bfg(<rgb>)',
        },
    ],
    datasets => [
        { args => { rgb => '000000' } },
        { args => { rgb => 'eeeeef' } },
    ],
};

1;
# ABSTRACT: Benchmark ansifg()

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::Color::ANSI::Util::ansifg - Benchmark ansifg()

=head1 VERSION

This document describes version 0.003 of Bencher::Scenario::Color::ANSI::Util::ansifg (from Perl distribution Bencher-Scenarios-Color-ANSI-Util), released on 2023-01-18.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m Color::ANSI::Util::ansifg

To run module startup overhead benchmark:

 % bencher --module-startup -m Color::ANSI::Util::ansifg

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Color::ANSI::Util> 0.164

=head1 BENCHMARK PARTICIPANTS

=over

=item * Color::ANSI::Util::ansi16fg (perl_code)

Function call template:

 Color::ANSI::Util::ansi16fg(<rgb>)



=item * Color::ANSI::Util::ansi256fg (perl_code)

Function call template:

 Color::ANSI::Util::ansi256fg(<rgb>)



=item * Color::ANSI::Util::ansi24bfg (perl_code)

Function call template:

 Color::ANSI::Util::ansi24bfg(<rgb>)



=back

=head1 BENCHMARK DATASETS

=over

=item * 000000

=item * eeeeef

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.34.0 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 20.04 >>, OS kernel: I<< Linux version 5.4.0-91-generic >>.

Benchmark with default options (C<< bencher -m Color::ANSI::Util::ansifg >>):

 #table1#
 +------------------------------+---------+-------------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                  | dataset | rate (/s)   | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +------------------------------+---------+-------------+-----------+-----------------------+-----------------------+---------+---------+
 | Color::ANSI::Util::ansi16fg  | eeeeef  |    5030     |  199      |                 0.00% |             31333.39% | 1.6e-07 |      20 |
 | Color::ANSI::Util::ansi256fg | eeeeef  |    5081.174 |  196.8049 |                 0.92% |             31047.23% | 5.5e-12 |      21 |
 | Color::ANSI::Util::ansi16fg  | 000000  |   88000     |   11      |              1652.67% |              1693.45% | 1.3e-08 |      20 |
 | Color::ANSI::Util::ansi256fg | 000000  |   90000     |   11      |              1684.59% |              1661.37% | 1.3e-08 |      20 |
 | Color::ANSI::Util::ansi24bfg | eeeeef  | 1458000     |    0.6856 |             28867.56% |                 8.51% |   1e-11 |      20 |
 | Color::ANSI::Util::ansi24bfg | 000000  | 1583000     |    0.6319 |             31333.39% |                 0.00% |   1e-11 |      22 |
 +------------------------------+---------+-------------+-----------+-----------------------+-----------------------+---------+---------+


Formatted as L<Benchmark.pm|Benchmark> result:

                          Rate  ansi16fg eeeeef  ansi256fg eeeeef  ansi16fg 000000  ansi256fg 000000  ansi24bfg eeeeef  ansi24bfg 000000 
  ansi16fg eeeeef       5030/s               --               -1%             -94%              -94%              -99%              -99% 
  ansi256fg eeeeef  5081.174/s               1%                --             -94%              -94%              -99%              -99% 
  ansi16fg 000000      88000/s            1709%             1689%               --                0%              -93%              -94% 
  ansi256fg 000000     90000/s            1709%             1689%               0%                --              -93%              -94% 
  ansi24bfg eeeeef   1458000/s           28925%            28605%            1504%             1504%                --               -7% 
  ansi24bfg 000000   1583000/s           31392%            31044%            1640%             1640%                8%                -- 
 
 Legends:
   ansi16fg 000000: dataset=000000 participant=Color::ANSI::Util::ansi16fg
   ansi16fg eeeeef: dataset=eeeeef participant=Color::ANSI::Util::ansi16fg
   ansi24bfg 000000: dataset=000000 participant=Color::ANSI::Util::ansi24bfg
   ansi24bfg eeeeef: dataset=eeeeef participant=Color::ANSI::Util::ansi24bfg
   ansi256fg 000000: dataset=000000 participant=Color::ANSI::Util::ansi256fg
   ansi256fg eeeeef: dataset=eeeeef participant=Color::ANSI::Util::ansi256fg

Benchmark module startup overhead (C<< bencher -m Color::ANSI::Util::ansifg --module-startup >>):

 #table2#
 +---------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | participant         | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +---------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | Color::ANSI::Util   |      12   |               5.6 |                 0.00% |                95.14% | 7.9e-05 |      20 |
 | perl -e1 (baseline) |       6.4 |               0   |                95.14% |                 0.00% | 4.6e-05 |      21 |
 +---------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+


Formatted as L<Benchmark.pm|Benchmark> result:

                          Rate  CA:U  perl -e1 (baseline) 
  CA:U                  83.3/s    --                 -46% 
  perl -e1 (baseline)  156.2/s   87%                   -- 
 
 Legends:
   CA:U: mod_overhead_time=5.6 participant=Color::ANSI::Util
   perl -e1 (baseline): mod_overhead_time=0 participant=perl -e1 (baseline)

To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 BENCHMARK NOTES

We can see the overhead of C<_rgb_to_indexed()> in the C<ansi16fg()> and
C<ansi256fg()> functions. For colors that immediately result in an exact match
like C<000000>, the overhead is smaller. For colors that need calculation of
minimum square distance like C<eeeeef>, the overhead is larger.

Although in general we do not need to worry about this overhead unless we're
calculating colors at rates of hundreds of thousands per seconds.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-Color-ANSI-Util>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-Color-ANSI-Util>.

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-Color-ANSI-Util>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
