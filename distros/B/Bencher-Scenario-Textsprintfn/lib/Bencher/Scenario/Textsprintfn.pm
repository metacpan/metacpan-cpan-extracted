package Bencher::Scenario::Textsprintfn;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.003'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark Text::sprintfn vs sprintf()',
    participants => [
        {
            fcall_template => 'Text::sprintfn::sprintfn(<format>, @{<data>})',
            tags => ['sprintfn'],
        },
        {
            name => 'sprintf',
            code_template => 'sprintf(<format>, @{<data>})',
            tags => ['sprintf'],
        },
    ],
    datasets => [
        {
            args => {format => '%s', data => [1]},
        },
        {
            args => {format => '%s%d%f', data => [1,2,3]},
        },
        {
            args => {format => '%(a)s', data => [{a=>1}]},
            exclude_participant_tags => ['sprintf'],
        },
        {
            args => {format => '%(a)s%(b)d%(c)f', data => [{a=>1,b=>2,c=>3}]},
            exclude_participant_tags => ['sprintf'],
        },
    ],
};

1;
# ABSTRACT: Benchmark Text::sprintfn vs sprintf()

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::Textsprintfn - Benchmark Text::sprintfn vs sprintf()

=head1 VERSION

This document describes version 0.003 of Bencher::Scenario::Textsprintfn (from Perl distribution Bencher-Scenario-Textsprintfn), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m Textsprintfn

To run module startup overhead benchmark:

 % bencher --module-startup -m Textsprintfn

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Text::sprintfn> 0.08

=head1 BENCHMARK PARTICIPANTS

=over

=item * Text::sprintfn::sprintfn (perl_code) [sprintfn]

Function call template:

 Text::sprintfn::sprintfn(<format>, @{<data>})



=item * sprintf (perl_code) [sprintf]

Code template:

 sprintf(<format>, @{<data>})



=back

=head1 BENCHMARK DATASETS

=over

=item * {data=>[1],format=>"%s"}

=item * {data=>[1,2,3],format=>"%s%d%f"}

=item * {data=>[{a=>1}],format=>"%(a)s"}

=item * {data=>[{a=>1,b=>2,c=>3}],format=>"%(a)s%(b)d%(c)f"}

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m Textsprintfn >>):

 #table1#
 +--------------------------+------------------------------------------------------+-----------+-----------+------------+---------+---------+
 | participant              | dataset                                              | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +--------------------------+------------------------------------------------------+-----------+-----------+------------+---------+---------+
 | Text::sprintfn::sprintfn | {data=>[{a=>1,b=>2,c=>3}],format=>"%(a)s%(b)d%(c)f"} |     76300 |    13.1   |       1    | 6.7e-09 |      20 |
 | Text::sprintfn::sprintfn | {data=>[{a=>1}],format=>"%(a)s"}                     |    194000 |     5.15  |       2.55 | 4.9e-09 |      21 |
 | Text::sprintfn::sprintfn | {data=>[1,2,3],format=>"%s%d%f"}                     |    902000 |     1.11  |      11.8  | 5.8e-10 |      20 |
 | sprintf                  | {data=>[1,2,3],format=>"%s%d%f"}                     |   1200000 |     0.82  |      16    | 1.7e-09 |      20 |
 | Text::sprintfn::sprintfn | {data=>[1],format=>"%s"}                             |   1700000 |     0.57  |      23    |   8e-10 |      34 |
 | sprintf                  | {data=>[1],format=>"%s"}                             |   3820000 |     0.262 |      50.1  | 4.6e-11 |      21 |
 +--------------------------+------------------------------------------------------+-----------+-----------+------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m Textsprintfn --module-startup >>):

 #table2#
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | participant         | proc_private_dirty_size (kB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | Text::sprintfn      | 840                          | 4.1                | 16             |       9.2 |                    3.8 |        1   | 5.9e-05 |      20 |
 | perl -e1 (baseline) | 992                          | 4.2                | 16             |       5.4 |                    0   |        1.7 | 2.4e-05 |      20 |
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-Textsprintfn>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-Textsprintfn>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-Textsprintfn>

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
