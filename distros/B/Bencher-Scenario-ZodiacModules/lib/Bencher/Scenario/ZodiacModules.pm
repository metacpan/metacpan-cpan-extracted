package Bencher::Scenario::ZodiacModules;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.05'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark various zodiac modules',
    participants => [
        {
            fcall_template => "Zodiac::Tiny::zodiac_of('2015-11-29')",
        },
        {
            fcall_template => "DateTime::Event::Zodiac::zodiac_date_name(DateTime->new(year=>2015, month=>11, day=>29))",
        },
        {
            fcall_template => "Zodiac::Chinese::Table::chinese_zodiac('2015-11-28')",
        },
        {
            fcall_template => "Zodiac::Chinese::chinese_zodiac(2015,11)",
        },
    ],
};

1;
# ABSTRACT: Benchmark various zodiac modules

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::ZodiacModules - Benchmark various zodiac modules

=head1 VERSION

This document describes version 0.05 of Bencher::Scenario::ZodiacModules (from Perl distribution Bencher-Scenario-ZodiacModules), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m ZodiacModules

To run module startup overhead benchmark:

 % bencher --module-startup -m ZodiacModules

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Zodiac::Tiny> 0.01

L<DateTime::Event::Zodiac> 1.03

L<Zodiac::Chinese::Table> 0.01

L<Zodiac::Chinese> 1

=head1 BENCHMARK PARTICIPANTS

=over

=item * Zodiac::Tiny::zodiac_of (perl_code)

Function call template:

 Zodiac::Tiny::zodiac_of('2015-11-29')



=item * DateTime::Event::Zodiac::zodiac_date_name (perl_code)

Function call template:

 DateTime::Event::Zodiac::zodiac_date_name(DateTime->new(year=>2015, month=>11, day=>29))



=item * Zodiac::Chinese::Table::chinese_zodiac (perl_code)

Function call template:

 Zodiac::Chinese::Table::chinese_zodiac('2015-11-28')



=item * Zodiac::Chinese::chinese_zodiac (perl_code)

Function call template:

 Zodiac::Chinese::chinese_zodiac(2015,11)



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m ZodiacModules >>):

 #table1#
 +-------------------------------------------+-----------+-----------+------------+---------+---------+
 | participant                               | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +-------------------------------------------+-----------+-----------+------------+---------+---------+
 | DateTime::Event::Zodiac::zodiac_date_name |       920 |   1100    |          1 |   4e-06 |      26 |
 | Zodiac::Chinese::Table::chinese_zodiac    |    727000 |      1.37 |        789 | 7.6e-10 |      26 |
 | Zodiac::Tiny::zodiac_of                   |    897000 |      1.11 |        973 | 4.2e-10 |      20 |
 | Zodiac::Chinese::chinese_zodiac           |   1760000 |      0.57 |       1900 | 1.7e-10 |      30 |
 +-------------------------------------------+-----------+-----------+------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m ZodiacModules --module-startup >>):

 #table2#
 +-------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+-----------+---------+
 | participant             | proc_private_dirty_size (MB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors   | samples |
 +-------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+-----------+---------+
 | DateTime::Event::Zodiac | 1.3                          | 4.7                | 18             |      64   |                   58.4 |        1   |   0.00019 |      20 |
 | Zodiac::Chinese::Table  | 1.1                          | 4.4                | 16             |      11   |                    5.4 |        5.8 |   0.0001  |      21 |
 | Zodiac::Chinese         | 0.82                         | 4.1                | 16             |      10   |                    4.4 |        6.2 | 4.4e-05   |      20 |
 | Zodiac::Tiny            | 11                           | 15                 | 51             |       6.7 |                    1.1 |        9.4 | 1.4e-05   |      20 |
 | perl -e1 (baseline)     | 0.94                         | 4.3                | 16             |       5.6 |                    0   |       11   | 1.8e-05   |      20 |
 +-------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+-----------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-ZodiacModules>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-ZodiacModules>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-ZodiacModules>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
