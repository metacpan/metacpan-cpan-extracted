package Bencher::Scenario::StringSimpleEscape;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-05-28'; # DATE
our $DIST = 'Bencher-Scenario-StringSimpleEscape'; # DIST
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

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

Bencher::Scenario::StringSimpleEscape - Benchmark String::SimpleEscape

=head1 VERSION

This document describes version 0.001 of Bencher::Scenario::StringSimpleEscape (from Perl distribution Bencher-Scenario-StringSimpleEscape), released on 2020-05-28.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m StringSimpleEscape

To run module startup overhead benchmark:

 % bencher --module-startup -m StringSimpleEscape

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

Run on: perl: I<< v5.30.2 >>, CPU: I<< Intel(R) Core(TM) i7-4770 CPU @ 3.40GHz (4 cores) >>, OS: I<< GNU/Linux LinuxMint version 19 >>, OS kernel: I<< Linux version 4.15.0-91-generic >>.

Benchmark with default options (C<< bencher -m StringSimpleEscape >>):

 #table1#
 +----------------------------------------------+--------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                                  | dataset      | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +----------------------------------------------+--------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | String::Escape::backslash                    | backslash100 |     37900 |   26.4    |                 0.00% |             27100.67% | 1.3e-08 |      20 |
 | String::SimpleEscape::simple_escape_string   | backslash100 |     41900 |   23.9    |                10.50% |             24515.99% | 6.7e-09 |      20 |
 | String::Escape::unbackslash                  | backslash100 |     46000 |   22      |                21.90% |             22213.99% | 2.7e-08 |      20 |
 | String::SimpleEscape::simple_unescape_string | backslash100 |     68000 |   15      |                80.55% |             14965.36% |   2e-08 |      20 |
 | String::Escape::backslash                    | a100         |   3771000 |    0.2652 |              9847.59% |               173.44% | 2.3e-11 |      20 |
 | String::SimpleEscape::simple_escape_string   | a100         |   4300000 |    0.23   |             11351.05% |               137.54% | 4.2e-10 |      20 |
 | String::Escape::unbackslash                  | a100         |   5910000 |    0.169  |             15477.03% |                74.62% | 2.4e-11 |      20 |
 | String::Escape::unbackslash                  | str0         |   7050000 |    0.142  |             18506.87% |                46.19% | 5.8e-11 |      20 |
 | String::Escape::backslash                    | str0         |   7300000 |    0.14   |             19040.07% |                42.11% | 2.1e-10 |      20 |
 | String::SimpleEscape::simple_unescape_string | a100         |   7860000 |    0.127  |             20623.37% |                31.26% |   2e-11 |      20 |
 | String::SimpleEscape::simple_escape_string   | str0         |   9200000 |    0.11   |             24253.49% |                11.69% | 2.6e-10 |      21 |
 | String::SimpleEscape::simple_unescape_string | str0         |  10300000 |    0.097  |             27100.67% |                 0.00% | 2.5e-11 |      20 |
 +----------------------------------------------+--------------+-----------+-----------+-----------------------+-----------------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m StringSimpleEscape --module-startup >>):

 #table2#
 +----------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | participant          | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +----------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | String::Escape       |        12 |                 8 |                 0.00% |               181.32% | 0.00011 |      20 |
 | String::SimpleEscape |         7 |                 3 |                59.21% |                76.70% | 0.00029 |      20 |
 | perl -e1 (baseline)  |         4 |                 0 |               181.32% |                 0.00% | 0.00017 |      20 |
 +----------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-StringSimpleEscape>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-StringSimpleEscape>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-StringSimpleEscape>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
