package Bencher::Scenario::PerinciSubGetArgsWebForm::get_args_from_webform;

our $DATE = '2018-11-22'; # DATE
our $VERSION = '0.001'; # VERSION

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
    summary => 'Benchmark get_args_from_webform()',
    participants => [
        {
            fcall_template => 'Perinci::Sub::GetArgs::WebForm::get_args_from_webform(<meta>, <form>, <meta_is_normalized>)',
        },
    ],
    datasets => [
        {
            name => '0 known args + 0 args',
            args => {
                meta => $meta0,
                form => {},
                meta_is_normalized => 0,
            },
        },
        {
            name => 'meta norm + 0 known args + 0 args',
            args => {
                meta => $meta0,
                form => {},
                meta_is_normalized => 1,
            },
        },

        {
            name => '2 known args + 0 args',
            args => {
                meta => $meta2,
                form => {},
                meta_is_normalized => 0,
            },
        },
        {
            name => 'meta norm + 2 known args + 0 args',
            args => {
                meta => $meta2n,
                form => {},
                meta_is_normalized => 1,
            },
        },

        {
            name => '2 known args + 2 args',
            args => {
                meta => $meta2,
                form => {a1=>"123", a2=>"abc"},
                meta_is_normalized => 0,
            },
        },
        {
            name => 'meta norm + 2 known args + 2 args',
            args => {
                meta => $meta2n,
                form => {a1=>"123", a2=>"abc"},
                meta_is_normalized => 1,
            },
        },
    ],
};

1;
# ABSTRACT: Benchmark get_args_from_webform()

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::PerinciSubGetArgsWebForm::get_args_from_webform - Benchmark get_args_from_webform()

=head1 VERSION

This document describes version 0.001 of Bencher::Scenario::PerinciSubGetArgsWebForm::get_args_from_webform (from Perl distribution Bencher-Scenarios-PerinciSubGetArgsWebForm), released on 2018-11-22.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m PerinciSubGetArgsWebForm::get_args_from_webform

To run module startup overhead benchmark:

 % bencher --module-startup -m PerinciSubGetArgsWebForm::get_args_from_webform

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Perinci::Sub::GetArgs::WebForm> 0.02

=head1 BENCHMARK PARTICIPANTS

=over

=item * Perinci::Sub::GetArgs::WebForm::get_args_from_webform (perl_code)

Function call template:

 Perinci::Sub::GetArgs::WebForm::get_args_from_webform(<meta>, <form>, <meta_is_normalized>)



=back

=head1 BENCHMARK DATASETS

=over

=item * 0 known args + 0 args

=item * meta norm + 0 known args + 0 args

=item * 2 known args + 0 args

=item * meta norm + 2 known args + 0 args

=item * 2 known args + 2 args

=item * meta norm + 2 known args + 2 args

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.26.0 >>, CPU: I<< Intel(R) Core(TM) i5-2400 CPU @ 3.10GHz (4 cores) >>, OS: I<< GNU/Linux LinuxMint version 18.2 >>, OS kernel: I<< Linux version 4.8.0-53-generic >>.

Benchmark with default options (C<< bencher -m PerinciSubGetArgsWebForm::get_args_from_webform >>):

 #table1#
 +-----------------------------------+-----------+-----------+------------+---------+---------+
 | dataset                           | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +-----------------------------------+-----------+-----------+------------+---------+---------+
 | meta norm + 2 known args + 2 args |    228000 |     4.39  |      1     | 1.7e-09 |      20 |
 | meta norm + 2 known args + 0 args |    240000 |     4.1   |      1.1   | 6.7e-09 |      20 |
 | 2 known args + 2 args             |    302200 |     3.309 |      1.325 | 5.1e-11 |      23 |
 | 2 known args + 0 args             |    320000 |     3.1   |      1.4   | 1.7e-08 |      20 |
 | meta norm + 0 known args + 0 args |    541000 |     1.85  |      2.37  | 7.6e-10 |      24 |
 | 0 known args + 0 args             |    550000 |     1.8   |      2.4   | 4.1e-09 |      21 |
 +-----------------------------------+-----------+-----------+------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m PerinciSubGetArgsWebForm::get_args_from_webform --module-startup >>):

 #table2#
 +--------------------------------+-----------+------------------------+------------+----------+---------+
 | participant                    | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors  | samples |
 +--------------------------------+-----------+------------------------+------------+----------+---------+
 | Perinci::Sub::GetArgs::WebForm |         9 |                      3 |          1 | 8.6e-05  |      20 |
 | perl -e1 (baseline)            |         6 |                      0 |          1 |   0.0001 |      20 |
 +--------------------------------+-----------+------------------------+------------+----------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-PerinciSubGetArgsWebForm>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-PerinciSubGetArgsWebForm>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-PerinciSubGetArgsWebForm>

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
