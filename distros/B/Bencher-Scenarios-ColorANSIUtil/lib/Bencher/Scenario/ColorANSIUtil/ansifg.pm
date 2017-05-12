package Bencher::Scenario::ColorANSIUtil::ansifg;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;

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

Bencher::Scenario::ColorANSIUtil::ansifg - Benchmark ansifg()

=head1 VERSION

This document describes version 0.002 of Bencher::Scenario::ColorANSIUtil::ansifg (from Perl distribution Bencher-Scenarios-ColorANSIUtil), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m ColorANSIUtil::ansifg

To run module startup overhead benchmark:

 % bencher --module-startup -m ColorANSIUtil::ansifg

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Color::ANSI::Util> 0.15

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

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m ColorANSIUtil::ansifg >>):

 #table1#
 +------------------------------+---------+-----------+-----------+------------+---------+---------+
 | participant                  | dataset | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +------------------------------+---------+-----------+-----------+------------+---------+---------+
 | Color::ANSI::Util::ansi16fg  | eeeeef  |    129000 |    7.76   |    1       |   3e-09 |      24 |
 | Color::ANSI::Util::ansi256fg | eeeeef  |    131000 |    7.61   |    1.02    | 2.9e-09 |      27 |
 | Color::ANSI::Util::ansi16fg  | 000000  |    540000 |    1.9    |    4.2     | 3.1e-09 |      23 |
 | Color::ANSI::Util::ansi256fg | 000000  |    560000 |    1.8    |    4.4     | 3.3e-09 |      20 |
 | Color::ANSI::Util::ansi24bfg | eeeeef  |   1208610 |    0.8274 |    9.37589 |   0     |      20 |
 | Color::ANSI::Util::ansi24bfg | 000000  |   1300000 |    0.78   |    9.9     | 1.7e-09 |      20 |
 +------------------------------+---------+-----------+-----------+------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m ColorANSIUtil::ansifg --module-startup >>):

 #table2#
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | participant         | proc_private_dirty_size (MB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | Color::ANSI::Util   | 1.2                          | 4.6                | 16             |       8.7 |                    4.6 |        1   | 3.5e-05 |      20 |
 | perl -e1 (baseline) | 1.2                          | 4.7                | 16             |       4.1 |                    0   |        2.1 | 7.2e-06 |      21 |
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 BENCHMARK NOTES

We can see the overhead of C<_rgb_to_indexed()> in the C<ansi16fg()> and
C<ansi256fg()> functions. For colors that immediately result in an exact match
like C<000000>, the overhead is smaller. For colors that need calculation of
minimum square distance like C<eeeeef>, the overhead is larger.

Although in general we do not need to worry about this overhead unless we're
calculating colors at rates of hundreds of thousands per seconds.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-ColorANSIUtil>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-ColorANSIUtil>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-ColorANSIUtil>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
