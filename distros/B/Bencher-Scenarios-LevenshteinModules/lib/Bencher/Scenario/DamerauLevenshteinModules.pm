package Bencher::Scenario::DamerauLevenshteinModules;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.13'; # VERSION

use 5.010001;
use strict;
use utf8;
use warnings;

our $scenario = {
    summary => 'Benchmark various modules calculating the Damerau-Levenshtein edit distance',
    modules => {
    },
    participants => [
        {
            fcall_template => "Text::Levenshtein::Damerau::PP::pp_edistance(<word1>, <word2>)",
        },
        {
            fcall_template => "Text::Levenshtein::Damerau::XS::xs_edistance(<word1>, <word2>)",
        },
        {
            module => 'Text::Fuzzy',
            code_template => "Text::Fuzzy->new(<word1>, trans=>1)->distance(<word2>)",
        },
    ],
    datasets => [
        { name=>"a",       args => {word1=>"a"      , word2=>"aa"},      result => 1 },
        { name=>"foo",     args => {word1=>"foo"    , word2=>"bar"},     result => 3 },
        { name=>"program", args => {word1=>"program", word2=>"porgram"}, result => 1 },
        { name=>"reve"   , args => {word1=>"reve"   , word2=>"rêves"},   result => 2, tags=>['unicode'], exclude_participant_tags=>['no_unicode_support'] },
        { name=>"euro"   , args => {word1=>"Euro"   , word2=>"€uro"},    result => 1, tags=>['unicode'], exclude_participant_tags=>['no_unicode_support'] },
    ],
    on_result_failure => 'warn',
};

1;
# ABSTRACT: Benchmark various modules calculating the Damerau-Levenshtein edit distance

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::DamerauLevenshteinModules - Benchmark various modules calculating the Damerau-Levenshtein edit distance

=head1 VERSION

This document describes version 0.13 of Bencher::Scenario::DamerauLevenshteinModules (from Perl distribution Bencher-Scenarios-LevenshteinModules), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m DamerauLevenshteinModules

To run module startup overhead benchmark:

 % bencher --module-startup -m DamerauLevenshteinModules

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Text::Fuzzy> 0.25

L<Text::Levenshtein::Damerau::PP> 0.25

L<Text::Levenshtein::Damerau::XS> 3.1

=head1 BENCHMARK PARTICIPANTS

=over

=item * Text::Levenshtein::Damerau::PP::pp_edistance (perl_code)

Function call template:

 Text::Levenshtein::Damerau::PP::pp_edistance(<word1>, <word2>)



=item * Text::Levenshtein::Damerau::XS::xs_edistance (perl_code)

Function call template:

 Text::Levenshtein::Damerau::XS::xs_edistance(<word1>, <word2>)



=item * Text::Fuzzy (perl_code)

Code template:

 Text::Fuzzy->new(<word1>, trans=>1)->distance(<word2>)



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

Benchmark with default options (C<< bencher -m DamerauLevenshteinModules >>):

 #table1#
 +----------------------------------------------+---------+-----------+-----------+------------+---------+---------+
 | participant                                  | dataset | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +----------------------------------------------+---------+-----------+-----------+------------+---------+---------+
 | Text::Levenshtein::Damerau::PP::pp_edistance | program |   20000   |   50      |    1       | 1.3e-08 |      20 |
 | Text::Levenshtein::Damerau::PP::pp_edistance | reve    |   38000   |   26      |    1.9     | 2.7e-08 |      20 |
 | Text::Levenshtein::Damerau::PP::pp_edistance | euro    |   38863.1 |   25.7313 |    1.94496 | 1.1e-11 |      23 |
 | Text::Levenshtein::Damerau::PP::pp_edistance | foo     |   71800   |   13.9    |    3.59    |   6e-09 |      25 |
 | Text::Levenshtein::Damerau::PP::pp_edistance | a       |  220000   |    4.6    |   11       | 6.7e-09 |      20 |
 | Text::Fuzzy                                  | euro    |  450000   |    2.2    |   23       | 3.3e-09 |      20 |
 | Text::Levenshtein::Damerau::XS::xs_edistance | program |  471800   |    2.119  |   23.61    | 5.6e-11 |      22 |
 | Text::Fuzzy                                  | program |  560000   |    1.8    |   28       | 6.4e-09 |      22 |
 | Text::Levenshtein::Damerau::XS::xs_edistance | reve    |  628900   |    1.5901 |   31.474   | 1.2e-11 |      20 |
 | Text::Levenshtein::Damerau::XS::xs_edistance | euro    |  678000   |    1.48   |   33.9     | 4.2e-10 |      20 |
 | Text::Fuzzy                                  | reve    |  729000   |    1.37   |   36.5     | 3.6e-10 |      27 |
 | Text::Fuzzy                                  | foo     |  775000   |    1.29   |   38.8     | 3.5e-10 |      28 |
 | Text::Levenshtein::Damerau::XS::xs_edistance | foo     |  780000   |    1.28   |   39.1     | 4.5e-10 |      21 |
 | Text::Fuzzy                                  | a       |  900000   |    1.1    |   45       | 3.3e-09 |      20 |
 | Text::Levenshtein::Damerau::XS::xs_edistance | a       | 1000000   |    0.96   |   52       | 1.5e-09 |      25 |
 +----------------------------------------------+---------+-----------+-----------+------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m DamerauLevenshteinModules --module-startup >>):

 #table2#
 +--------------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | participant                    | proc_private_dirty_size (MB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +--------------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | Text::Fuzzy                    | 0.82                         | 4.1                | 16             |       9.8 |                    5.3 |        1   | 1.4e-05 |      20 |
 | Text::Levenshtein::Damerau::PP | 0.98                         | 4.5                | 18             |       8.4 |                    3.9 |        1.2 | 1.9e-05 |      20 |
 | Text::Levenshtein::Damerau::XS | 1.3                          | 4.7                | 18             |       6.4 |                    1.9 |        1.5 | 2.2e-05 |      20 |
 | perl -e1 (baseline)            | 1.1                          | 4.4                | 18             |       4.5 |                    0   |        2.2 | 1.9e-05 |      20 |
 +--------------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+


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

L<Bencher::Scenario::LevenshteinModules>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
