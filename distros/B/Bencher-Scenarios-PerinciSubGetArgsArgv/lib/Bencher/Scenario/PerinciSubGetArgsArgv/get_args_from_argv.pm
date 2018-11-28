package Bencher::Scenario::PerinciSubGetArgsArgv::get_args_from_argv;

our $DATE = '2018-11-22'; # DATE
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;

my $meta0 = {
    v=>1.1,
    args=>{
    },
};

my $meta2 = {
    v=>1.1,
    args=>{
        a1=>{schema=>'int*', req=>1, pos=>0},
        a2=>{schema=>'str*', req=>1, pos=>1},
    },
};

my $meta2n = {
    v=>1.1,
    args=>{
        a1=>{schema=>[int=>{req=>1},{}], req=>1, pos=>0},
        a2=>{schema=>[str=>{req=>1},{}], req=>1, pos=>1},
    },
};

our $scenario = {
    summary => 'Benchmark get_args_from_argv()',
    participants => [
        {
            fcall_template => 'Perinci::Sub::GetArgs::Argv::get_args_from_argv(%{<args>})',
        },
    ],
    datasets => [
        {
            name => '0 known args + 0 args',
            args => {
                args => {
                    common_opts => {},
                    meta => $meta0,
                    argv => [],
                },
            },
        },
        {
            name => 'meta norm + 0 known args + 0 args',
            args => {
                args => {
                    common_opts => {},
                    meta => $meta0,
                    argv => [],
                    meta_is_normalized => 1,
                },
            },
        },
        {
            name => '2 known args + 0 args',
            args => {
                args => {
                    common_opts => {},
                    meta => $meta2,
                    argv => [],
                },
            },
        },
        {
            name => 'meta norm + 2 known args + 0 args',
            args => {
                args => {
                    common_opts => {},
                    meta => $meta2n,
                    argv => [],
                    meta_is_normalized => 1,
                },
            },
        },
        {
            name => '2 known args + 2 args positional',
            args => {
                args => {
                    common_opts => {},
                    meta => $meta2,
                    argv => ["123", "abc"],
                },
            },
        },
        {
            name => '2 known args + 2 args named',
            args => {
                args => {
                    common_opts => {},
                    meta => $meta2,
                    argv => [qw/--a2 abc --a1 123/],
                },
            },
        },
        {
            name => 'meta norm + 2 known args + 2 args positional',
            args => {
                args => {
                    common_opts => {},
                    meta => $meta2n,
                    argv => ["123", "abc"],
                    meta_is_normalized => 1,
                },
            },
        },
        {
            name => 'meta norm + 2 known args + 2 args named',
            args => {
                args => {
                    common_opts => {},
                    meta => $meta2n,
                    argv => [qw/--a2 abc --a1 123/],
                    meta_is_normalized => 1,
                },
            },
        },
    ],
};

1;
# ABSTRACT: Benchmark get_args_from_argv()

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::PerinciSubGetArgsArgv::get_args_from_argv - Benchmark get_args_from_argv()

=head1 VERSION

This document describes version 0.002 of Bencher::Scenario::PerinciSubGetArgsArgv::get_args_from_argv (from Perl distribution Bencher-Scenarios-PerinciSubGetArgsArgv), released on 2018-11-22.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m PerinciSubGetArgsArgv::get_args_from_argv

To run module startup overhead benchmark:

 % bencher --module-startup -m PerinciSubGetArgsArgv::get_args_from_argv

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Perinci::Sub::GetArgs::Argv> 0.840

=head1 BENCHMARK PARTICIPANTS

=over

=item * Perinci::Sub::GetArgs::Argv::get_args_from_argv (perl_code)

Function call template:

 Perinci::Sub::GetArgs::Argv::get_args_from_argv(%{<args>})



=back

=head1 BENCHMARK DATASETS

=over

=item * 0 known args + 0 args

=item * meta norm + 0 known args + 0 args

=item * 2 known args + 0 args

=item * meta norm + 2 known args + 0 args

=item * 2 known args + 2 args positional

=item * 2 known args + 2 args named

=item * meta norm + 2 known args + 2 args positional

=item * meta norm + 2 known args + 2 args named

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.26.0 >>, CPU: I<< Intel(R) Core(TM) i5-2400 CPU @ 3.10GHz (4 cores) >>, OS: I<< GNU/Linux LinuxMint version 18.2 >>, OS kernel: I<< Linux version 4.8.0-53-generic >>.

Benchmark with default options (C<< bencher -m PerinciSubGetArgsArgv::get_args_from_argv >>):

 #table1#
 +----------------------------------------------+-----------+-----------+------------+---------+---------+
 | dataset                                      | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +----------------------------------------------+-----------+-----------+------------+---------+---------+
 | 2 known args + 2 args named                  |      3920 |   255     |     1      | 2.1e-07 |      20 |
 | 2 known args + 2 args positional             |      4600 |   220     |     1.2    | 2.5e-07 |      23 |
 | meta norm + 2 known args + 2 args named      |      5000 |   200     |     1.3    | 2.7e-07 |      20 |
 | 2 known args + 0 args                        |      5300 |   190     |     1.3    | 4.3e-07 |      20 |
 | meta norm + 2 known args + 2 args positional |      6000 |   170     |     1.5    | 2.1e-07 |      20 |
 | meta norm + 2 known args + 0 args            |      7400 |   140     |     1.9    | 2.1e-07 |      20 |
 | 0 known args + 0 args                        |     20000 |    50     |     5.1    | 1.1e-07 |      20 |
 | meta norm + 0 known args + 0 args            |     28815 |    34.705 |     7.3581 | 4.5e-11 |      20 |
 +----------------------------------------------+-----------+-----------+------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m PerinciSubGetArgsArgv::get_args_from_argv --module-startup >>):

 #table2#
 +-----------------------------+-----------+------------------------+------------+---------+---------+
 | participant                 | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +-----------------------------+-----------+------------------------+------------+---------+---------+
 | Perinci::Sub::GetArgs::Argv |      20   |                   13.9 |        1   | 0.00037 |      20 |
 | perl -e1 (baseline)         |       6.1 |                    0   |        3.5 | 6e-05   |      20 |
 +-----------------------------+-----------+------------------------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-PerinciSubGetArgsArgv>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-PerinciSubGetArgsArgv>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-PerinciSubGetArgsArgv>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
