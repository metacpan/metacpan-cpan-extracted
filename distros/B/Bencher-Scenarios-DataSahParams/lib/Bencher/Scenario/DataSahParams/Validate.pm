package Bencher::Scenario::DataSahParams::Validate;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Measure validation speed',
    participants => [
        {
            name => 'dsp_int',
            module => 'Data::Sah::Params',
            code_template => q(state $check = Data::Sah::Params::compile("int*"); $check->(@{<args>})),
            tags => ['int'],
        },
        {
            name => 'tp_int',
            module => 'Type::Params',
            code_template => q(use Type::Params qw(compile); use Types::Standard qw(Int); state $check = compile(Int); $check->(@{<args>})),
            tags => ['int'],
        },

        {
            name => 'dsp_int_int[]',
            module => 'Data::Sah::Params',
            code_template => q(state $check = Data::Sah::Params::compile("int*", ["array*",of=>"int*"]); $check->(@{<args>})),
            tags => ['int_int[]'],
        },
        {
            name => 'tp_int_int[]',
            module => 'Type::Params',
            code_template => q(use Type::Params qw(compile); use Types::Standard qw(Int ArrayRef); state $check = compile(Int, ArrayRef[Int]); $check->(@{<args>})),
            tags => ['int_int[]'],
        },
    ],
    datasets => [
        {
            name => '1',
            args => { args => [1] },
            include_participant_tags => ['int'],
        },
        {
            name => '1,[]',
            args => { args => [1,[]] },
            include_participant_tags => ['int_int[]'],
        },
        {
            name => '1,[1..10]',
            args => { args => [1,[1..10]] },
            include_participant_tags => ['int_int[]'],
        },
        {
            name => '1,[1..100]',
            args => { args => [1,[1..100]] },
            include_participant_tags => ['int_int[]'],
        },
    ],
};

1;
# ABSTRACT: Measure validation speed

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::DataSahParams::Validate - Measure validation speed

=head1 VERSION

This document describes version 0.002 of Bencher::Scenario::DataSahParams::Validate (from Perl distribution Bencher-Scenarios-DataSahParams), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m DataSahParams::Validate

To run module startup overhead benchmark:

 % bencher --module-startup -m DataSahParams::Validate

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Data::Sah::Params> 0.003

L<Type::Params> 1.000005

=head1 BENCHMARK PARTICIPANTS

=over

=item * dsp_int (perl_code) [int]

Code template:

 state $check = Data::Sah::Params::compile("int*"); $check->(@{<args>})



=item * tp_int (perl_code) [int]

Code template:

 use Type::Params qw(compile); use Types::Standard qw(Int); state $check = compile(Int); $check->(@{<args>})



=item * dsp_int_int[] (perl_code) [int_int[]]

Code template:

 state $check = Data::Sah::Params::compile("int*", ["array*",of=>"int*"]); $check->(@{<args>})



=item * tp_int_int[] (perl_code) [int_int[]]

Code template:

 use Type::Params qw(compile); use Types::Standard qw(Int ArrayRef); state $check = compile(Int, ArrayRef[Int]); $check->(@{<args>})



=back

=head1 BENCHMARK DATASETS

=over

=item * 1

=item * 1,[]

=item * 1,[1..10]

=item * 1,[1..100]

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m DataSahParams::Validate >>):

 #table1#
 +---------------+------------+-----------+-----------+------------+---------+---------+
 | participant   | dataset    | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +---------------+------------+-----------+-----------+------------+---------+---------+
 | dsp_int_int[] | 1,[1..100] |     24800 |  40.4     |    1       | 3.8e-08 |      22 |
 | dsp_int_int[] | 1,[1..10]  |    130000 |   7.5     |    5.4     | 1.7e-08 |      20 |
 | tp_int_int[]  | 1,[1..100] |    231807 |   4.31393 |    9.35713 |   0     |      20 |
 | dsp_int_int[] | 1,[]       |    330000 |   3.1     |   13       | 3.3e-09 |      20 |
 | tp_int_int[]  | 1,[1..10]  |    703000 |   1.42    |   28.4     | 3.6e-10 |      27 |
 | tp_int_int[]  | 1,[]       |    990000 |   1       |   40       | 1.2e-09 |      22 |
 | dsp_int       | 1          |   1420000 |   0.702   |   57.5     | 2.1e-10 |      20 |
 | tp_int        | 1          |   1472000 |   0.6795  |   59.4     | 1.2e-11 |      20 |
 +---------------+------------+-----------+-----------+------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m DataSahParams::Validate --module-startup >>):

 #table2#
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+----------+---------+
 | participant         | proc_private_dirty_size (MB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors  | samples |
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+----------+---------+
 | Type::Params        | 0.96                         | 4.4                | 16             |      43   |                   37.3 |        1   |   0.0002 |      20 |
 | Data::Sah::Params   | 5.4                          | 9.2                | 31             |       9.2 |                    3.5 |        4.7 | 4.4e-05  |      20 |
 | perl -e1 (baseline) | 0.96                         | 4.4                | 16             |       5.7 |                    0   |        7.5 | 1.7e-05  |      20 |
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+----------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 BENCHMARK NOTES

In this benchmark case, code generated by Data::Sah performs significantly more
slowly because it is not particularly optimized. Future releases of Data::Sah
will add some optimizations.

To see the source code generated by Data::Sah::Params, pass C<< want_source => 1
>> option to C<compile()>, e.g.:

 compile({want_source=>1}, "int*", ...)

Or you can try on the command-line (the CLI utility is part of
L<App::SahUtils>):

 % validate-with-sah '"int*"' -c

To see the source code generated by Type::Params, pass C<< want_source => 1 >>
option to C<compile()> like in Data::Sah::Params, e.g.:

 compile({want_source=>1}, Int, ...)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-DataSahParams>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-DataSahParams>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-DataSahParams>

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
