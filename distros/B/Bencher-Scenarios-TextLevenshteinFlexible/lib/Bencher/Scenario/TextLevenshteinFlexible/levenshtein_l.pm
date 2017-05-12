package Bencher::Scenario::TextLevenshteinFlexible::levenshtein_l;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark levenshtein_l()',
    modules => {
    },
    participants => [
        {
            fcall_template => "Text::Levenshtein::XS::distance(<word1>, <word2>)",
        },
        {
            fcall_template => "Text::Levenshtein::Flexible::levenshtein_l(<word1>, <word2>, <limit>)",
        },
    ],
    datasets => [
        { args => {word1=>"program", word2=>"porgram", limit=>1 } },
        { args => {word1=>"program", word2=>"porgram", limit=>2 } },
    ],
    on_result_failure => 'warn',
};

1;
# ABSTRACT: Benchmark levenshtein_l()

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::TextLevenshteinFlexible::levenshtein_l - Benchmark levenshtein_l()

=head1 VERSION

This document describes version 0.002 of Bencher::Scenario::TextLevenshteinFlexible::levenshtein_l (from Perl distribution Bencher-Scenarios-TextLevenshteinFlexible), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m TextLevenshteinFlexible::levenshtein_l

To run module startup overhead benchmark:

 % bencher --module-startup -m TextLevenshteinFlexible::levenshtein_l

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Text::Levenshtein::Flexible> 0.09

L<Text::Levenshtein::XS> 0.503

=head1 BENCHMARK PARTICIPANTS

=over

=item * Text::Levenshtein::XS::distance (perl_code)

Function call template:

 Text::Levenshtein::XS::distance(<word1>, <word2>)



=item * Text::Levenshtein::Flexible::levenshtein_l (perl_code)

Function call template:

 Text::Levenshtein::Flexible::levenshtein_l(<word1>, <word2>, <limit>)



=back

=head1 BENCHMARK DATASETS

=over

=item * 1

=item * 2

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m TextLevenshteinFlexible::levenshtein_l >>):

 #table1#
 +--------------------------------------------+---------+-----------+-----------+------------+---------+---------+
 | participant                                | dataset | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +--------------------------------------------+---------+-----------+-----------+------------+---------+---------+
 | Text::Levenshtein::XS::distance            | 1       |    469000 |    2.13   |      1     | 7.9e-10 |      22 |
 | Text::Levenshtein::XS::distance            | 2       |    470000 |    2.1    |      1     | 2.4e-09 |      21 |
 | Text::Levenshtein::Flexible::levenshtein_l | 2       |   3908000 |    0.2559 |      8.338 | 1.1e-11 |      20 |
 | Text::Levenshtein::Flexible::levenshtein_l | 1       |   5740000 |    0.174  |     12.3   | 3.3e-11 |      20 |
 +--------------------------------------------+---------+-----------+-----------+------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m TextLevenshteinFlexible::levenshtein_l --module-startup >>):

 #table2#
 +-----------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | participant                 | proc_private_dirty_size (MB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +-----------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | Text::Levenshtein::Flexible | 0.83                         | 4                  | 16             |      10   |                    5.6 |        1   | 3.2e-05 |      20 |
 | Text::Levenshtein::XS       | 1.3                          | 4.6                | 18             |       7.8 |                    3.4 |        1.3 | 3.3e-05 |      20 |
 | perl -e1 (baseline)         | 0.98                         | 4.4                | 18             |       4.4 |                    0   |        2.3 | 1.1e-05 |      20 |
 +-----------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-TextLevenshteinFlexible>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-TextLevenshteinFlexible>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-TextLevenshteinFlexible>

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
