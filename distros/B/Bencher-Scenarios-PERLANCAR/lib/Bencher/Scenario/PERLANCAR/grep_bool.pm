package Bencher::Scenario::PERLANCAR::grep_bool;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.06'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark grep() in a bool context',
    description => <<'_',

Finding a nice solution for a shortcutting grep like first.

_
    participants => [
        {
            name=>'grep',
            code_template=>'state $haystack = <haystack>; if (grep {$_ == <needle>} @$haystack) { 1 } else { 0 }',
        },
        {
            name=>'grep+die',
            summary => 'use grep + die to simulate shortcutting',
            code_template=>'state $haystack = <haystack>; if (eval { grep {$_ == <needle> && die} @$haystack }, $@) { 1 } else { 0 }',
            description => <<'_',

Not a very good idiom. It kind of abuses die(), and has to suffer the overhead
of eval(). Most important of all, it's less clear.

_
        },
        {
            name=>'foreach+last+do',
            code_template=>'state $haystack = <haystack>; if (do { my $found; $_ == <needle> and $found = 1 and last for @$haystack; $found }) { 1 } else { 0 }',
            description => <<'_',

This is a nicer idiom, courtesy of tybalt89 in http://perlmonks.org/?node_id=1178871.

_
        },
        {
            name=>'sub+foreach+return',
            code_template=>'state $haystack = <haystack>; if (sub { $_ == <needle> and return 1 for @$haystack; 0 }->()) { 1 } else { 0 }',
        },
        {
            module => 'List::Util',
            function=>'first',
            code_template=>'state $haystack = <haystack>; if (List::Util::first(sub {$_ == <needle>}, @$haystack)) { 1 } else { 0 }',
        },
        {
            module => 'List::MoreUtils',
            function=>'firstval',
            code_template=>'state $haystack = <haystack>; if (List::MoreUtils::firstval(sub {$_ == <needle>}, @$haystack)) { 1 } else { 0 }',
        },
        {
            module => 'Array::AllUtils',
            function=>'first',
            code_template=>'state $haystack = <haystack>; if (Array::AllUtils::first(sub {$_ == <needle>}, $haystack)) { 1 } else { 0 }',
        },
    ],

    datasets => [
        {name=>  'first'   , include_by_default=>1, args=>{haystack => [1..  10000], needle =>      1}},
        {name=>  'last'    , include_by_default=>1, args=>{haystack => [1..  10000], needle =>  10000}},
        {name=>  'notfound', include_by_default=>1, args=>{haystack => [1..  10000], needle =>  10001}},
    ],
};

1;
# ABSTRACT: Benchmark grep() in a bool context

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::PERLANCAR::grep_bool - Benchmark grep() in a bool context

=head1 VERSION

This document describes version 0.06 of Bencher::Scenario::PERLANCAR::grep_bool (from Perl distribution Bencher-Scenarios-PERLANCAR), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m PERLANCAR::grep_bool

To run module startup overhead benchmark:

 % bencher --module-startup -m PERLANCAR::grep_bool

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Finding a nice solution for a shortcutting grep like first.


Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<List::Util> 1.45

L<List::MoreUtils> 0.416

L<Array::AllUtils> 0.002

=head1 BENCHMARK PARTICIPANTS

=over

=item * grep (perl_code)

Code template:

 state $haystack = <haystack>; if (grep {$_ == <needle>} @$haystack) { 1 } else { 0 }



=item * grep+die (perl_code)

use grep + die to simulate shortcutting.

Code template:

 state $haystack = <haystack>; if (eval { grep {$_ == <needle> && die} @$haystack }, $@) { 1 } else { 0 }



=item * foreach+last+do (perl_code)

Code template:

 state $haystack = <haystack>; if (do { my $found; $_ == <needle> and $found = 1 and last for @$haystack; $found }) { 1 } else { 0 }



=item * sub+foreach+return (perl_code)

Code template:

 state $haystack = <haystack>; if (sub { $_ == <needle> and return 1 for @$haystack; 0 }->()) { 1 } else { 0 }



=item * List::Util::first (perl_code)

Code template:

 state $haystack = <haystack>; if (List::Util::first(sub {$_ == <needle>}, @$haystack)) { 1 } else { 0 }



=item * List::MoreUtils::firstval (perl_code)

Code template:

 state $haystack = <haystack>; if (List::MoreUtils::firstval(sub {$_ == <needle>}, @$haystack)) { 1 } else { 0 }



=item * Array::AllUtils::first (perl_code)

Code template:

 state $haystack = <haystack>; if (Array::AllUtils::first(sub {$_ == <needle>}, $haystack)) { 1 } else { 0 }



=back

=head1 BENCHMARK DATASETS

=over

=item * first

=item * last

=item * notfound

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m PERLANCAR::grep_bool >>):

 #table1#
 +---------------------------+----------+------------+-------------+-------------+---------+---------+
 | participant               | dataset  | rate (/s)  |   time (ms) | vs_slowest  |  errors | samples |
 +---------------------------+----------+------------+-------------+-------------+---------+---------+
 | Array::AllUtils::first    | notfound |     520    | 1.9         |     1       | 1.9e-05 |      39 |
 | Array::AllUtils::first    | last     |     546    | 1.83        |     1.05    |   4e-07 |      23 |
 | grep+die                  | notfound |     660    | 1.5         |     1.3     | 2.5e-06 |      20 |
 | grep+die                  | last     |     667    | 1.5         |     1.29    | 4.2e-07 |      21 |
 | sub+foreach+return        | notfound |    2910    | 0.344       |     5.6     | 2.7e-07 |      20 |
 | sub+foreach+return        | last     |    3100    | 0.322       |     5.98    | 5.3e-08 |      20 |
 | foreach+last+do           | last     |    3126    | 0.319898    |     6.02396 |   0     |      20 |
 | foreach+last+do           | notfound |    3126.03 | 0.319894    |     6.02403 |   4e-11 |      20 |
 | List::MoreUtils::firstval | last     |    3380    | 0.295       |     6.52    | 5.1e-08 |      22 |
 | grep                      | first    |    3472.82 | 0.28795     |     6.69232 |   0     |      20 |
 | grep                      | last     |    3472.9  | 0.28795     |     6.6924  | 5.4e-10 |      20 |
 | grep                      | notfound |    3475.2  | 0.287753    |     6.69689 | 1.4e-10 |      26 |
 | List::MoreUtils::firstval | notfound |    3770    | 0.265       |     7.27    | 5.3e-08 |      20 |
 | List::Util::first         | notfound |    3803.5  | 0.262916    |     7.32955 | 4.6e-11 |      20 |
 | List::Util::first         | last     |    3803.55 | 0.262912    |     7.32965 | 2.1e-10 |      20 |
 | List::Util::first         | first    |   47900    | 0.0209      |    92.2     | 6.1e-09 |      24 |
 | List::MoreUtils::firstval | first    |   48914.1  | 0.020444    |    94.2601  | 1.2e-11 |      20 |
 | grep+die                  | first    |  134230    | 0.0074496   |   258.68    | 1.1e-11 |      22 |
 | sub+foreach+return        | first    | 1480000    | 0.000678    |  2840       | 2.1e-10 |      20 |
 | Array::AllUtils::first    | first    | 2168850    | 0.000461073 |  4179.5     |   0     |      20 |
 | foreach+last+do           | first    | 5422410    | 0.00018442  | 10449.3     |   0     |      20 |
 +---------------------------+----------+------------+-------------+-------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m PERLANCAR::grep_bool --module-startup >>):

 #table2#
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | participant         | proc_private_dirty_size (kB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | List::MoreUtils     | 848                          | 4.1                | 16             |      17   |                    8.1 |        1   | 6.2e-05 |      20 |
 | List::Util          | 844                          | 4.1                | 16             |      13   |                    4.1 |        1.3 |   5e-05 |      22 |
 | Array::AllUtils     | 844                          | 4.1                | 16             |       9.8 |                    0.9 |        1.7 | 2.5e-05 |      22 |
 | perl -e1 (baseline) | 848                          | 4.1                | 16             |       8.9 |                    0   |        1.9 | 4.7e-05 |      20 |
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 BENCHMARK NOTES

I'll settle with foreach+last+do for larger lists, and plain grep in other
cases.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-PERLANCAR>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-PERLANCAR>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-PERLANCAR>

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
