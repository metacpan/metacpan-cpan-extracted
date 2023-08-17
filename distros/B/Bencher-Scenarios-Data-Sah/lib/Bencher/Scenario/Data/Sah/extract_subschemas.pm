package Bencher::Scenario::Data::Sah::extract_subschemas;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-01-19'; # DATE
our $DIST = 'Bencher-Scenarios-Data-Sah'; # DIST
our $VERSION = '0.071'; # VERSION

our $scenario = {
    summary => 'Benchmark extracting subschemas',
    participants => [
        {
            fcall_template => 'Data::Sah::Util::Subschema::extract_subschemas(<schema>)',
            result_is_list => 1,
        },
    ],
    datasets => [

        {
            args    => {
                schema => 'int',
            },
        },

        {
            args => {
                schema => [array => of=>"int"],
            },
        },

        {
            args => {
                schema => [any => of => ["int*", [array => of=>"int"]]],
            },
        },

        {
            args => {
                schema => [array => "of|"=>["int","float"]],
            },
        },

    ],
};

1;
# ABSTRACT: Benchmark extracting subschemas

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::Data::Sah::extract_subschemas - Benchmark extracting subschemas

=head1 VERSION

This document describes version 0.071 of Bencher::Scenario::Data::Sah::extract_subschemas (from Perl distribution Bencher-Scenarios-Data-Sah), released on 2023-01-19.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m Data::Sah::extract_subschemas

To run module startup overhead benchmark:

 % bencher --module-startup -m Data::Sah::extract_subschemas

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Data::Sah::Util::Subschema> 0.005

=head1 BENCHMARK PARTICIPANTS

=over

=item * Data::Sah::Util::Subschema::extract_subschemas (perl_code)

Function call template:

 Data::Sah::Util::Subschema::extract_subschemas(<schema>)



=back

=head1 BENCHMARK DATASETS

=over

=item * int

=item * ["array","of","int"]

=item * ["any","of",["int*",["array","of","int"]]]

=item * ["array","of|",["int","float"]]

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.34.0 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 20.04 >>, OS kernel: I<< Linux version 5.4.0-91-generic >>.

Benchmark with default options (C<< bencher -m Data::Sah::extract_subschemas >>):

 #table1#
 +--------------------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | dataset                                    | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +--------------------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | ["any","of",["int*",["array","of","int"]]] |     16000 |     61    |                 0.00% |               642.10% | 3.5e-07 |      20 |
 | ["array","of|",["int","float"]]            |     25000 |     40    |                54.81% |               379.37% |   6e-08 |      25 |
 | ["array","of","int"]                       |     35000 |     28    |               114.85% |               245.40% | 5.2e-08 |      21 |
 | int                                        |    121000 |      8.24 |               642.10% |                 0.00% | 3.3e-09 |      20 |
 +--------------------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+


Formatted as L<Benchmark.pm|Benchmark> result:

                                                  Rate  ["any","of",["int*",["array","of","int"]]]  ["array","of|",["int","float"]]  ["array","of","int"]   int 
  ["any","of",["int*",["array","of","int"]]]   16000/s                                          --                             -34%                  -54%  -86% 
  ["array","of|",["int","float"]]              25000/s                                         52%                               --                  -30%  -79% 
  ["array","of","int"]                         35000/s                                        117%                              42%                    --  -70% 
  int                                         121000/s                                        640%                             385%                  239%    -- 
 
 Legends:
   ["any","of",["int*",["array","of","int"]]]: dataset=["any","of",["int*",["array","of","int"]]]
   ["array","of","int"]: dataset=["array","of","int"]
   ["array","of|",["int","float"]]: dataset=["array","of|",["int","float"]]
   int: dataset=int

Benchmark module startup overhead (C<< bencher -m Data::Sah::extract_subschemas --module-startup >>):

 #table2#
 +----------------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | participant                | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +----------------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | Data::Sah::Util::Subschema |      12   |               4.9 |                 0.00% |                68.05% | 6.7e-05 |      21 |
 | perl -e1 (baseline)        |       7.1 |               0   |                68.05% |                 0.00% | 3.1e-05 |      21 |
 +----------------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+


Formatted as L<Benchmark.pm|Benchmark> result:

                          Rate  DSU:S  perl -e1 (baseline) 
  DSU:S                 83.3/s     --                 -40% 
  perl -e1 (baseline)  140.8/s    69%                   -- 
 
 Legends:
   DSU:S: mod_overhead_time=4.9 participant=Data::Sah::Util::Subschema
   perl -e1 (baseline): mod_overhead_time=0 participant=perl -e1 (baseline)

To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-Data-Sah>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-Data-Sah>.

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023, 2017, 2016, 2015 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-Data-Sah>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
