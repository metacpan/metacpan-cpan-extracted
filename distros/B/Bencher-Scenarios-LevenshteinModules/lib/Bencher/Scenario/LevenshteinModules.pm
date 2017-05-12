package Bencher::Scenario::LevenshteinModules;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.13'; # VERSION

use 5.010001;
use strict;
use utf8;
use warnings;

our $scenario = {
    summary => 'Benchmark various modules calculating the Levenshtein edit distance',
    modules => {
        'Text::Levenshtein' => {version => 0.11},
    },
    participants => [
        {
            fcall_template => "PERLANCAR::Text::Levenshtein::editdist(<word1>, <word2>)",
            tags => ['no_unicode_support'],
        },
        {
            fcall_template => "Text::Levenshtein::fastdistance(<word1>, <word2>)",
        },
        {
            fcall_template => "Text::Levenshtein::XS::distance(<word1>, <word2>)",
        },
        {
            fcall_template => "Text::Levenshtein::Flexible::levenshtein(<word1>, <word2>)",
        },
        {
            fcall_template => "Text::LevenshteinXS::distance(<word1>, <word2>)",
            tags => ['no_unicode_support'],
        },
        {
            module => 'Text::Fuzzy',
            code_template => "Text::Fuzzy->new(<word1>)->distance(<word2>)",
        },
    ],
    datasets => [
        { name=>"a",       args => {word1=>"a"      , word2=>"aa"},      result => 1 },
        { name=>"foo",     args => {word1=>"foo"    , word2=>"bar"},     result => 3 },
        { name=>"program", args => {word1=>"program", word2=>"porgram"}, result => 2 },
        { name=>"reve"   , args => {word1=>"reve"   , word2=>"rêves"},   result => 2, tags=>['unicode'], exclude_participant_tags=>['no_unicode_support'] },
        { name=>"euro"   , args => {word1=>"Euro"   , word2=>"€uro"},    result => 1, tags=>['unicode'], exclude_participant_tags=>['no_unicode_support'] },
    ],
    on_result_failure => 'warn',
};

1;
# ABSTRACT: Benchmark various modules calculating the Levenshtein edit distance

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::LevenshteinModules - Benchmark various modules calculating the Levenshtein edit distance

=head1 VERSION

This document describes version 0.13 of Bencher::Scenario::LevenshteinModules (from Perl distribution Bencher-Scenarios-LevenshteinModules), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m LevenshteinModules

To run module startup overhead benchmark:

 % bencher --module-startup -m LevenshteinModules

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<PERLANCAR::Text::Levenshtein> 0.02

L<Text::Fuzzy> 0.25

L<Text::Levenshtein> 0.13

L<Text::Levenshtein::Flexible> 0.09

L<Text::Levenshtein::XS> 0.503

L<Text::LevenshteinXS> 0.03

=head1 BENCHMARK PARTICIPANTS

=over

=item * PERLANCAR::Text::Levenshtein::editdist (perl_code) [no_unicode_support]

Function call template:

 PERLANCAR::Text::Levenshtein::editdist(<word1>, <word2>)



=item * Text::Levenshtein::fastdistance (perl_code)

Function call template:

 Text::Levenshtein::fastdistance(<word1>, <word2>)



=item * Text::Levenshtein::XS::distance (perl_code)

Function call template:

 Text::Levenshtein::XS::distance(<word1>, <word2>)



=item * Text::Levenshtein::Flexible::levenshtein (perl_code)

Function call template:

 Text::Levenshtein::Flexible::levenshtein(<word1>, <word2>)



=item * Text::LevenshteinXS::distance (perl_code) [no_unicode_support]

Function call template:

 Text::LevenshteinXS::distance(<word1>, <word2>)



=item * Text::Fuzzy (perl_code)

Code template:

 Text::Fuzzy->new(<word1>)->distance(<word2>)



=back

=head1 BENCHMARK DATASETS

=over

=item * a

=item * foo

=item * program

=item * reve [unicode]

=item * euro [unicode]

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m LevenshteinModules >>):

 #table1#
 +------------------------------------------+---------+-----------+-----------+------------+---------+---------+
 | participant                              | dataset | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +------------------------------------------+---------+-----------+-----------+------------+---------+---------+
 | Text::Levenshtein::fastdistance          | program |     14000 | 73        |      1     | 5.6e-07 |      20 |
 | PERLANCAR::Text::Levenshtein::editdist   | program |     28100 | 35.5      |      2.06  | 1.1e-08 |      28 |
 | Text::Levenshtein::fastdistance          | reve    |     34000 | 30        |      2.5   | 1.1e-07 |      20 |
 | Text::Levenshtein::fastdistance          | euro    |     39000 | 25        |      2.9   |   5e-08 |      23 |
 | Text::Levenshtein::fastdistance          | foo     |     70000 | 14        |      5.1   | 2.7e-08 |      20 |
 | PERLANCAR::Text::Levenshtein::editdist   | foo     |    110000 |  9.2      |      7.9   | 1.3e-08 |      20 |
 | Text::Levenshtein::fastdistance          | a       |    230000 |  4.4      |     17     | 8.3e-09 |      20 |
 | PERLANCAR::Text::Levenshtein::editdist   | a       |    400000 |  2.5      |     30     | 2.6e-09 |      20 |
 | Text::Levenshtein::XS::distance          | program |    513000 |  1.95     |     37.6   | 8.1e-10 |      21 |
 | Text::Fuzzy                              | euro    |    600000 |  1.7      |     44     | 3.3e-09 |      20 |
 | Text::Levenshtein::XS::distance          | reve    |    656000 |  1.52     |     48.1   | 1.5e-10 |      31 |
 | Text::Levenshtein::XS::distance          | euro    |    700000 |  1.4      |     51     | 1.7e-09 |      20 |
 | Text::Levenshtein::XS::distance          | foo     |    789220 |  1.2671   |     57.804 | 1.1e-11 |      24 |
 | Text::Fuzzy                              | program |    990000 |  1        |     72     | 1.7e-09 |      20 |
 | Text::Levenshtein::XS::distance          | a       |   1010000 |  0.993    |     73.7   | 4.1e-10 |      21 |
 | Text::Fuzzy                              | reve    |   1090000 |  0.914    |     80.2   | 3.2e-10 |      34 |
 | Text::Fuzzy                              | foo     |   1140000 |  0.879    |     83.3   | 4.1e-10 |      21 |
 | Text::Fuzzy                              | a       |   1200000 |  0.83     |     88     | 1.6e-09 |      21 |
 | Text::LevenshteinXS::distance            | program |   3680000 |  0.271    |    270     |   1e-10 |      21 |
 | Text::Levenshtein::Flexible::levenshtein | program |   4850000 |  0.206    |    355     |   1e-10 |      20 |
 | Text::Levenshtein::Flexible::levenshtein | euro    |   5175710 |  0.19321  |    379.081 |   0     |      20 |
 | Text::Levenshtein::Flexible::levenshtein | reve    |   7051530 |  0.141813 |    516.47  |   0     |      24 |
 | Text::LevenshteinXS::distance            | foo     |   8400000 |  0.12     |    610     | 2.1e-10 |      20 |
 | Text::Levenshtein::Flexible::levenshtein | foo     |   8600000 |  0.1163   |    629.9   | 9.8e-12 |      22 |
 | Text::LevenshteinXS::distance            | a       |  10000000 |  0.0998   |    734     | 5.1e-11 |      21 |
 | Text::Levenshtein::Flexible::levenshtein | a       |  10000000 |  0.0997   |    735     | 5.3e-11 |      20 |
 +------------------------------------------+---------+-----------+-----------+------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m LevenshteinModules --module-startup >>):

 #table2#
 +------------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | participant                  | proc_private_dirty_size (MB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +------------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | Text::LevenshteinXS          | 1.3                          | 4.6                | 18             |      13   |                    8.5 |        1   | 5.9e-05 |      20 |
 | Text::Levenshtein            | 0.99                         | 4.3                | 18             |      11   |                    6.5 |        1.2 | 4.8e-05 |      20 |
 | Text::Levenshtein::Flexible  | 1.6                          | 5                  | 19             |      10   |                    5.5 |        1.3 | 1.4e-05 |      20 |
 | Text::Fuzzy                  | 0.83                         | 4.1                | 16             |      10   |                    5.5 |        1.3 | 5.7e-05 |      20 |
 | Text::Levenshtein::XS        | 1.3                          | 4.6                | 18             |       8.1 |                    3.6 |        1.6 | 5.1e-05 |      20 |
 | PERLANCAR::Text::Levenshtein | 1.4                          | 4.8                | 19             |       5   |                    0.5 |        2.6 | 1.4e-05 |      20 |
 | perl -e1 (baseline)          | 0.85                         | 4.1                | 16             |       4.5 |                    0   |        2.8 | 1.5e-05 |      20 |
 +------------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-LevenshteinModules>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-LevenshteinModules>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-LevenshteinModules>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Bencher::Scenario::DamerauLevenshteinModules>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
