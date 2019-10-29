package Bencher::Scenario::TruncatingString;

our $DATE = '2019-09-11'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark modules that truncate/elide string',
    participants => [
        {
            fcall_template => 'String::Elide::Parts::elide(<string>, <max_len>)',
        },
        {
            fcall_template => 'String::Elide::Tiny::elide(<string>, <max_len>)',
        },
        {
            fcall_template => 'String::Truncate::elide(<string>, <max_len>)',
        },
        {
            fcall_template => 'Text::Elide::elide(<string>, <max_len>)',
        },
        {
            fcall_template => 'Text::Truncate::truncstr(<string>, <max_len>)',
        },
    ],
    datasets => [
        {name=>'str100-70', args=>{string=>"1234567890" x 10, max_len=>70}},
    ],
};

1;
# ABSTRACT: Benchmark modules that truncate/elide string

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::TruncatingString - Benchmark modules that truncate/elide string

=head1 VERSION

This document describes version 0.001 of Bencher::Scenario::TruncatingString (from Perl distribution Bencher-Scenario-TruncatingString), released on 2019-09-11.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m TruncatingString

To run module startup overhead benchmark:

 % bencher --module-startup -m TruncatingString

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<String::Elide::Parts> 0.07

L<String::Elide::Tiny> 0.002

L<String::Truncate> 1.100602

L<Text::Elide> 0.0.3

L<Text::Truncate> 1.06

=head1 BENCHMARK PARTICIPANTS

=over

=item * String::Elide::Parts::elide (perl_code)

Function call template:

 String::Elide::Parts::elide(<string>, <max_len>)



=item * String::Elide::Tiny::elide (perl_code)

Function call template:

 String::Elide::Tiny::elide(<string>, <max_len>)



=item * String::Truncate::elide (perl_code)

Function call template:

 String::Truncate::elide(<string>, <max_len>)



=item * Text::Elide::elide (perl_code)

Function call template:

 Text::Elide::elide(<string>, <max_len>)



=item * Text::Truncate::truncstr (perl_code)

Function call template:

 Text::Truncate::truncstr(<string>, <max_len>)



=back

=head1 BENCHMARK DATASETS

=over

=item * str100-70

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.28.2 >>, CPU: I<< Intel(R) Core(TM) i5-2400 CPU @ 3.10GHz (4 cores) >>, OS: I<< GNU/Linux LinuxMint version 18.3 >>, OS kernel: I<< Linux version 4.8.0-53-generic >>.

Benchmark with default options (C<< bencher -m TruncatingString >>):

 #table1#
 +-----------------------------+-----------+-----------+------------+---------+---------+
 | participant                 | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +-----------------------------+-----------+-----------+------------+---------+---------+
 | String::Elide::Parts::elide |     81000 |     12    |        1   |   3e-08 |      20 |
 | Text::Elide::elide          |    130000 |      7.6  |        1.6 | 2.7e-08 |      20 |
 | String::Truncate::elide     |    600000 |      1.7  |        7.4 | 6.5e-09 |      21 |
 | String::Elide::Tiny::elide  |    910000 |      1.1  |       11   | 2.1e-09 |      20 |
 | Text::Truncate::truncstr    |   1400000 |      0.72 |       17   | 1.6e-09 |      22 |
 +-----------------------------+-----------+-----------+------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m TruncatingString --module-startup >>):

 #table2#
 +----------------------+-----------+------------------------+------------+-----------+---------+
 | participant          | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors   | samples |
 +----------------------+-----------+------------------------+------------+-----------+---------+
 | String::Truncate     |      25   |                   19.8 |        1   |   0.00011 |      20 |
 | Text::Elide          |      20   |                   14.8 |        1.3 | 7.1e-05   |      20 |
 | Text::Truncate       |      14   |                    8.8 |        1.8 | 5.6e-05   |      20 |
 | String::Elide::Parts |       9.9 |                    4.7 |        2.5 | 5.9e-05   |      20 |
 | String::Elide::Tiny  |       5.8 |                    0.6 |        4.3 | 4.2e-05   |      20 |
 | perl -e1 (baseline)  |       5.2 |                    0   |        4.8 | 2.7e-05   |      20 |
 +----------------------+-----------+------------------------+------------+-----------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-TruncatingString>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-TruncatingString>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-TruncatingString>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
