package Bencher::Scenario::Color::RGB::Util;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-10-12'; # DATE
our $DIST = 'Bencher-Scenario-Color-RGB-Util'; # DIST
our $VERSION = '0.002'; # VERSION

our $scenario = {
    summary => 'Benchmark Color::RGB::Util',
    participants => [
        {
            fcall_template => 'Color::RGB::Util::mix_2_rgb_colors("000000","ffffff")',
        },
        {
            fcall_template => 'Color::RGB::Util::rand_rgb_color()',
        },
    ],
};

1;
# ABSTRACT: Benchmark Color::RGB::Util

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::Color::RGB::Util - Benchmark Color::RGB::Util

=head1 VERSION

This document describes version 0.002 of Bencher::Scenario::Color::RGB::Util (from Perl distribution Bencher-Scenario-Color-RGB-Util), released on 2021-10-12.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m Color::RGB::Util

To run module startup overhead benchmark:

 % bencher --module-startup -m Color::RGB::Util

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Color::RGB::Util> 0.604

=head1 BENCHMARK PARTICIPANTS

=over

=item * Color::RGB::Util::mix_2_rgb_colors (perl_code)

Function call template:

 Color::RGB::Util::mix_2_rgb_colors("000000","ffffff")



=item * Color::RGB::Util::rand_rgb_color (perl_code)

Function call template:

 Color::RGB::Util::rand_rgb_color()



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.34.0 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 20.04 >>, OS kernel: I<< Linux version 5.3.0-64-generic >>.

Benchmark with C<< bencher -m Color::RGB::Util --env-hashes-json '[{"PERL5OPT":"-Iarchive/Color-RGB-Util-0.58/lib"},{"PERL5OPT":"-Iarchive/Color-RGB-Util-0.590/lib"}]' >>:

 #table1#
 +------------------------------------+---------------------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                        | env                                         | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +------------------------------------+---------------------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | Color::RGB::Util::rand_rgb_color   | PERL5OPT=-Iarchive/Color-RGB-Util-0.590/lib |    160000 |    6.3    |                 0.00% |                 2.52% | 6.7e-09 |      20 |
 | Color::RGB::Util::mix_2_rgb_colors | PERL5OPT=-Iarchive/Color-RGB-Util-0.590/lib |    159160 |    6.2828 |                 0.97% |                 1.54% | 1.1e-11 |      20 |
 | Color::RGB::Util::rand_rgb_color   | PERL5OPT=-Iarchive/Color-RGB-Util-0.58/lib  |    160000 |    6.26   |                 1.26% |                 1.25% |   5e-09 |      20 |
 | Color::RGB::Util::mix_2_rgb_colors | PERL5OPT=-Iarchive/Color-RGB-Util-0.58/lib  |    160000 |    6.2    |                 2.52% |                 0.00% | 6.7e-09 |      20 |
 +------------------------------------+---------------------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+


Formatted as L<Benchmark.pm|Benchmark> result:

                                          Rate  Color::RGB::Util::rand_rgb_color  Color::RGB::Util::mix_2_rgb_colors  Color::RGB::Util::rand_rgb_color  Color::RGB::Util::mix_2_rgb_colors 
  Color::RGB::Util::rand_rgb_color    160000/s                                --                                  0%                                0%                                 -1% 
  Color::RGB::Util::mix_2_rgb_colors  159160/s                                0%                                  --                                0%                                 -1% 
  Color::RGB::Util::rand_rgb_color    160000/s                                0%                                  0%                                --                                  0% 
  Color::RGB::Util::mix_2_rgb_colors  160000/s                                1%                                  1%                                0%                                  -- 
 
 Legends:
   Color::RGB::Util::mix_2_rgb_colors: env=PERL5OPT=-Iarchive/Color-RGB-Util-0.58/lib participant=Color::RGB::Util::mix_2_rgb_colors
   Color::RGB::Util::rand_rgb_color: env=PERL5OPT=-Iarchive/Color-RGB-Util-0.58/lib participant=Color::RGB::Util::rand_rgb_color

Benchmark module startup overhead (C<< bencher -m Color::RGB::Util --module-startup >>):

 #table2#
 +---------------------+---------------------------------------------+-----------+-------------------+-----------------------+-----------------------+-----------+---------+
 | participant         | env                                         | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors   | samples |
 +---------------------+---------------------------------------------+-----------+-------------------+-----------------------+-----------------------+-----------+---------+
 | Color::RGB::Util    | PERL5OPT=-Iarchive/Color-RGB-Util-0.58/lib  |      10   | 1.2               |                 0.00% |                59.79% |   0.00017 |      21 |
 | Color::RGB::Util    | PERL5OPT=-Iarchive/Color-RGB-Util-0.590/lib |      14   | 5.2               |                 0.66% |                58.74% |   6e-05   |      24 |
 | perl -e1 (baseline) | PERL5OPT=-Iarchive/Color-RGB-Util-0.590/lib |       8.8 | 0                 |                56.98% |                 1.79% | 4.5e-05   |      20 |
 | perl -e1 (baseline) | PERL5OPT=-Iarchive/Color-RGB-Util-0.58/lib  |       9   | 0.199999999999999 |                59.79% |                 0.00% | 9.4e-05   |      21 |
 +---------------------+---------------------------------------------+-----------+-------------------+-----------------------+-----------------------+-----------+---------+


Formatted as L<Benchmark.pm|Benchmark> result:

                          Rate  Color::RGB::Util  Color::RGB::Util  perl -e1 (baseline)  perl -e1 (baseline) 
  Color::RGB::Util      71.4/s                --              -28%                 -35%                 -37% 
  Color::RGB::Util     100.0/s               39%                --                  -9%                 -11% 
  perl -e1 (baseline)  111.1/s               55%               11%                   --                  -2% 
  perl -e1 (baseline)  113.6/s               59%               13%                   2%                   -- 
 
 Legends:
   Color::RGB::Util: env=PERL5OPT=-Iarchive/Color-RGB-Util-0.58/lib mod_overhead_time=1 participant=Color::RGB::Util
   perl -e1 (baseline): env=PERL5OPT=-Iarchive/Color-RGB-Util-0.590/lib mod_overhead_time=-0.199999999999999 participant=perl -e1 (baseline)

To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-Color-RGB-Util>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-Color-RGB-Util>.

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

This software is copyright (c) 2021, 2018 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-Color-RGB-Util>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
