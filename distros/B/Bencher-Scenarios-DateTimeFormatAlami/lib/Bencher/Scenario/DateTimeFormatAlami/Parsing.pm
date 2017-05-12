package Bencher::Scenario::DateTimeFormatAlami::Parsing;

our $DATE = '2016-06-30'; # DATE
our $VERSION = '0.004'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark parsing speed of DateTime::Format::Alami against some other modules',
    modules => {
        'DateTime::Format::Alami::EN' => {version => 0.13},
        'DateTime::Format::Alami::ID' => {version => 0.13},
    },
    participants => [
        {
            module=>'DateTime::Format::Alami::EN',
            code_template => 'state $parser = DateTime::Format::Alami::EN->new; $parser->parse_datetime(<text>)',
            tags => ['lang:en'],
        },
        {
            module=>'DateTime::Format::Alami::ID',
            code_template => 'state $parser = DateTime::Format::Alami::ID->new; $parser->parse_datetime(<text>)',
            tags => ['lang:id'],
        },
        {
            module=>'Date::Extract',
            code_template => 'state $parser = Date::Extract->new; $parser->extract(<text>)',
            tags => ['lang:en'],
        },
        {
            module=>'DateTime::Format::Natural',
            code_template => 'state $parser = DateTime::Format::Natural->new; $parser->parse_datetime(<text>)',
            tags => ['lang:en'],
        },
        {
            module=>'DateTime::Format::Flexible',
            code_template => 'DateTime::Format::Flexible->parse_datetime(<text>)',
            tags => ['lang:en'],
        },
    ],
    datasets => [
        {args => {text => '18 feb'}},
        {args => {text => '18 feb 2011'}},
        {args => {text => '18 feb 2011 06:30:45'}},
        {args => {text => 'today'}, include_participant_tags => ['lang:en']},
        {args => {text => 'hari ini'}, include_participant_tags => ['lang:id']},
    ],
};

1;
# ABSTRACT: Benchmark parsing speed of DateTime::Format::Alami against some other modules

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::DateTimeFormatAlami::Parsing - Benchmark parsing speed of DateTime::Format::Alami against some other modules

=head1 VERSION

This document describes version 0.004 of Bencher::Scenario::DateTimeFormatAlami::Parsing (from Perl distribution Bencher-Scenarios-DateTimeFormatAlami), released on 2016-06-30.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m DateTimeFormatAlami::Parsing

To run module startup overhead benchmark:

 % bencher --module-startup -m DateTimeFormatAlami::Parsing

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Date::Extract> 0.05

L<DateTime::Format::Alami::EN> 0.13

L<DateTime::Format::Alami::ID> 0.13

L<DateTime::Format::Flexible> 0.26

L<DateTime::Format::Natural> 1.03

=head1 BENCHMARK PARTICIPANTS

=over

=item * DateTime::Format::Alami::EN (perl_code) [lang:en]

Code template:

 state $parser = DateTime::Format::Alami::EN->new; $parser->parse_datetime(<text>)



=item * DateTime::Format::Alami::ID (perl_code) [lang:id]

Code template:

 state $parser = DateTime::Format::Alami::ID->new; $parser->parse_datetime(<text>)



=item * Date::Extract (perl_code) [lang:en]

Code template:

 state $parser = Date::Extract->new; $parser->extract(<text>)



=item * DateTime::Format::Natural (perl_code) [lang:en]

Code template:

 state $parser = DateTime::Format::Natural->new; $parser->parse_datetime(<text>)



=item * DateTime::Format::Flexible (perl_code) [lang:en]

Code template:

 DateTime::Format::Flexible->parse_datetime(<text>)



=back

=head1 BENCHMARK DATASETS

=over

=item * 18 feb

=item * 18 feb 2011

=item * 18 feb 2011 06:30:45

=item * today

=item * hari ini

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.22.1 >>, CPU: I<< Intel(R) Core(TM) i5-2400 CPU @ 3.10GHz (4 cores) >>, OS: I<< GNU/Linux Debian version 8.0 >>, OS kernel: I<< Linux version 3.16.0-4-amd64 >>.

Benchmark with default options (C<< bencher -m DateTimeFormatAlami::Parsing >>):

 #table1#
 {dataset=>"18 feb"}
 +-----------------------------+-----------+-----------+------------+---------+---------+
 | participant                 | rate (/s) | time (ms) | vs_slowest |  errors | samples |
 +-----------------------------+-----------+-----------+------------+---------+---------+
 | DateTime::Format::Flexible  |       330 |     3     |       1    | 2.9e-05 |      21 |
 | Date::Extract               |       750 |     1.33  |       2.25 | 4.1e-07 |      22 |
 | DateTime::Format::Alami::EN |       940 |     1.1   |       2.8  | 1.7e-06 |      21 |
 | DateTime::Format::Alami::ID |      1420 |     0.704 |       4.27 | 6.4e-07 |      20 |
 | DateTime::Format::Natural   |      1460 |     0.683 |       4.4  | 4.3e-07 |      20 |
 +-----------------------------+-----------+-----------+------------+---------+---------+

 #table2#
 {dataset=>"18 feb 2011"}
 +-----------------------------+-----------+-----------+------------+---------+---------+
 | participant                 | rate (/s) | time (ms) | vs_slowest |  errors | samples |
 +-----------------------------+-----------+-----------+------------+---------+---------+
 | Date::Extract               |       148 |      6.76 |       1    | 2.5e-06 |      20 |
 | DateTime::Format::Natural   |       166 |      6.02 |       1.12 | 1.8e-06 |      20 |
 | DateTime::Format::Alami::EN |       370 |      2.71 |       2.5  | 1.4e-06 |      20 |
 | DateTime::Format::Flexible  |       370 |      2.7  |       2.5  | 1.5e-05 |      20 |
 | DateTime::Format::Alami::ID |       622 |      1.61 |       4.21 |   1e-06 |      23 |
 +-----------------------------+-----------+-----------+------------+---------+---------+

 #table3#
 {dataset=>"18 feb 2011 06:30:45"}
 +-----------------------------+-----------+-----------+------------+---------+---------+
 | participant                 | rate (/s) | time (ms) | vs_slowest |  errors | samples |
 +-----------------------------+-----------+-----------+------------+---------+---------+
 | Date::Extract               |       149 |     6.7   |       1    | 2.7e-06 |      20 |
 | DateTime::Format::Flexible  |       370 |     2.7   |       2.5  |   2e-05 |      21 |
 | DateTime::Format::Natural   |      1020 |     0.983 |       6.82 | 6.9e-07 |      20 |
 | DateTime::Format::Alami::EN |      1300 |     0.75  |       9    | 3.8e-06 |      20 |
 | DateTime::Format::Alami::ID |      1380 |     0.727 |       9.22 | 4.7e-07 |      21 |
 +-----------------------------+-----------+-----------+------------+---------+---------+

 #table4#
 {dataset=>"hari ini"}
 +-----------------------------+----------+------+-----------+-----------+------------+---------+---------+
 | participant                 | dataset  | perl | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +-----------------------------+----------+------+-----------+-----------+------------+---------+---------+
 | DateTime::Format::Alami::ID | hari ini | perl |      3400 |       300 |          1 | 4.8e-07 |      20 |
 +-----------------------------+----------+------+-----------+-----------+------------+---------+---------+

 #table5#
 {dataset=>"today"}
 +-----------------------------+-----------+-----------+------------+---------+---------+
 | participant                 | rate (/s) | time (ms) | vs_slowest |  errors | samples |
 +-----------------------------+-----------+-----------+------------+---------+---------+
 | DateTime::Format::Flexible  |       370 |     2.7   |       1    | 9.6e-06 |      22 |
 | Date::Extract               |       979 |     1.02  |       2.61 | 9.1e-07 |      20 |
 | DateTime::Format::Natural   |      2600 |     0.385 |       6.93 | 2.7e-07 |      20 |
 | DateTime::Format::Alami::EN |      3300 |     0.3   |       8.8  | 4.1e-07 |      22 |
 +-----------------------------+-----------+-----------+------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m DateTimeFormatAlami::Parsing --module-startup >>):

 #table6#
 +-----------------------------+-----------+------------------------+------------+-----------+---------+
 | participant                 | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors   | samples |
 +-----------------------------+-----------+------------------------+------------+-----------+---------+
 | DateTime::Format::Flexible  |     120   |                  115.6 |        1   |   0.0011  |      21 |
 | Date::Extract               |      86   |                   81.6 |        1.4 |   0.00072 |      20 |
 | DateTime::Format::Natural   |      82   |                   77.6 |        1.5 |   0.00036 |      20 |
 | DateTime::Format::Alami::ID |      25   |                   20.6 |        4.9 |   0.00017 |      20 |
 | DateTime::Format::Alami::EN |      23   |                   18.6 |        5.2 | 6.2e-05   |      21 |
 | perl -e1 (baseline)         |       4.4 |                    0   |       27   | 1.2e-05   |      20 |
 +-----------------------------+-----------+------------------------+------------+-----------+---------+

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-DateTimeFormatAlami>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-DateTimeFormatAlami>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-DateTimeFormatAlami>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
