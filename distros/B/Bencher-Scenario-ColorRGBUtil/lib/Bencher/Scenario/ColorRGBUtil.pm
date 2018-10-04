package Bencher::Scenario::ColorRGBUtil;

our $DATE = '2018-09-26'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

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

Bencher::Scenario::ColorRGBUtil - Benchmark Color::RGB::Util

=head1 VERSION

This document describes version 0.001 of Bencher::Scenario::ColorRGBUtil (from Perl distribution Bencher-Scenario-ColorRGBUtil), released on 2018-09-26.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m ColorRGBUtil

To run module startup overhead benchmark:

 % bencher --module-startup -m ColorRGBUtil

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Color::RGB::Util> 0.590

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

Run on: perl: I<< v5.26.0 >>, CPU: I<< Intel(R) Core(TM) i5-2400 CPU @ 3.10GHz (4 cores) >>, OS: I<< GNU/Linux LinuxMint version 18.2 >>, OS kernel: I<< Linux version 4.8.0-53-generic >>.

Benchmark with C<< bencher -m ColorRGBUtil --env-hashes-json '[{"PERL5OPT":"-Iarchive/Color-RGB-Util-0.58/lib"},{"PERL5OPT":"-Iarchive/Color-RGB-Util-0.590/lib"}]' >>:

 #table1#
 +------------------------------------+---------------------------------------------+-----------+-----------+------------+---------+---------+
 | participant                        | env                                         | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +------------------------------------+---------------------------------------------+-----------+-----------+------------+---------+---------+
 | Color::RGB::Util::rand_rgb_color   | PERL5OPT=-Iarchive/Color-RGB-Util-0.58/lib  |     70900 |      14.1 |        1   |   5e-09 |      36 |
 | Color::RGB::Util::mix_2_rgb_colors | PERL5OPT=-Iarchive/Color-RGB-Util-0.590/lib |     72000 |      14   |        1   | 2.5e-08 |      23 |
 | Color::RGB::Util::rand_rgb_color   | PERL5OPT=-Iarchive/Color-RGB-Util-0.590/lib |     72000 |      14   |        1   |   2e-08 |      20 |
 | Color::RGB::Util::mix_2_rgb_colors | PERL5OPT=-Iarchive/Color-RGB-Util-0.58/lib  |     75000 |      13   |        1.1 | 2.7e-08 |      20 |
 +------------------------------------+---------------------------------------------+-----------+-----------+------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m ColorRGBUtil --module-startup >>):

 #table2#
 +---------------------+---------------------------------------------+-----------+------------------------+------------+---------+---------+
 | participant         | env                                         | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +---------------------+---------------------------------------------+-----------+------------------------+------------+---------+---------+
 | Color::RGB::Util    | PERL5OPT=-Iarchive/Color-RGB-Util-0.58/lib  |       8.3 |     3.7                |        1   | 3.7e-05 |      20 |
 | Color::RGB::Util    | PERL5OPT=-Iarchive/Color-RGB-Util-0.590/lib |       8.3 |     3.7                |        1   |   4e-05 |      20 |
 | perl -e1 (baseline) | PERL5OPT=-Iarchive/Color-RGB-Util-0.58/lib  |       4.6 |     0                  |        1.8 | 2.6e-05 |      20 |
 | perl -e1 (baseline) | PERL5OPT=-Iarchive/Color-RGB-Util-0.590/lib |       4.5 |    -0.0999999999999996 |        1.9 | 2.4e-05 |      20 |
 +---------------------+---------------------------------------------+-----------+------------------------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-ColorRGBUtil>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-ColorRGBUtil>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-ColorRGBUtil>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
