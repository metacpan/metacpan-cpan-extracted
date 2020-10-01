package Bencher::Scenario::DataSahVSTypeTiny::Validate;

use 5.010001;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-10-01'; # DATE
our $DIST = 'Bencher-Scenarios-DataSahVSTypeTiny'; # DIST
our $VERSION = '0.003'; # VERSION

eval "package main; use Types::Standard qw(ArrayRef Int)";

our $scenario = {
    summary => 'Benchmark validation',
    modules => {
        'Data::Sah' => {version=>'0.907'},
    },
    participants => [
        {
            name => 'dsah',
            module => 'Data::Sah',
            code_template => 'state $v = Data::Sah::gen_validator(<schema>); $v->(<data>)',
            tags => ['dsah'],
        },
        {
            name => 'tt',
            #module => 'Types::Standard',
            code_template => 'state $v = (<type:raw>)->compiled_check; $v->(<data>)',
            tags => ['tt'],
        },
    ],
    datasets => [
        {
            name => 'int(dsah)',
            include_participant_tags => ['dsah'],
            args => {
                schema => 'int*',
                'data@' => [undef, 1, "a"],
            },
        },
        {
            name => 'int(tt)',
            include_participant_tags => ['tt'],
            args => {
                type => 'Int',
                'data@' => [undef, 1, "a"],
            },
        },

        {
            name => 'array10(dsah)',
            include_participant_tags => ['dsah'],
            args => {
                schema => ['array', of=>'int*'],
                'data' => [1..10],
            },
        },
        {
            name => 'array10(tt)',
            include_participant_tags => ['tt'],
            args => {
                type => 'ArrayRef[Int]',
                'data' => [1..10],
            },
        },
    ],
};

1;
# ABSTRACT: Benchmark validation

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::DataSahVSTypeTiny::Validate - Benchmark validation

=head1 VERSION

This document describes version 0.003 of Bencher::Scenario::DataSahVSTypeTiny::Validate (from Perl distribution Bencher-Scenarios-DataSahVSTypeTiny), released on 2020-10-01.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m DataSahVSTypeTiny::Validate

To run module startup overhead benchmark:

 % bencher --module-startup -m DataSahVSTypeTiny::Validate

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Data::Sah> 0.908

=head1 BENCHMARK PARTICIPANTS

=over

=item * dsah (perl_code) [dsah]

Code template:

 state $v = Data::Sah::gen_validator(<schema>); $v->(<data>)



=item * tt (perl_code) [tt]

Code template:

 state $v = (<type:raw>)->compiled_check; $v->(<data>)



=back

=head1 BENCHMARK DATASETS

=over

=item * int(dsah)

=item * int(tt)

=item * array10(dsah)

=item * array10(tt)

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.30.0 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 19.10 >>, OS kernel: I<< Linux version 5.3.0-64-generic >>.

Benchmark with default options (C<< bencher -m DataSahVSTypeTiny::Validate >>):

 #table1#
 +-------------+---------------+----------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant | dataset       | arg_data | p_tags | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------+---------------+----------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | dsah        | array10(dsah) |          | dsah   |    186000 |    5.3764 |                 0.00% |              8107.42% | 4.6e-11 |      20 |
 | tt          | array10(tt)   |          | tt     |   1500000 |    0.65   |               726.42% |               893.13% | 8.3e-10 |      20 |
 | dsah        | int(dsah)     | a        | dsah   |   2740000 |    0.365  |              1372.19% |               457.50% | 5.7e-11 |      20 |
 | dsah        | int(dsah)     | 1        | dsah   |   3100000 |    0.32   |              1558.12% |               394.98% | 4.2e-10 |      20 |
 | dsah        | int(dsah)     |          | dsah   |   4500000 |    0.22   |              2338.71% |               236.55% | 6.5e-10 |      21 |
 | tt          | int(tt)       | 1        | tt     |  12000000 |    0.085  |              6254.67% |                29.16% | 4.6e-10 |      21 |
 | tt          | int(tt)       |          | tt     |  10000000 |    0.08   |              6601.07% |                22.48% | 8.7e-10 |      20 |
 | tt          | int(tt)       | a        | tt     |  20000000 |    0.07   |              8107.42% |                 0.00% | 1.3e-09 |      21 |
 +-------------+---------------+----------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m DataSahVSTypeTiny::Validate --module-startup >>):

 #table2#
 +---------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | participant         | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +---------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | Data::Sah           |        23 |                 9 |                 0.00% |                67.02% | 0.00022 |      20 |
 | perl -e1 (baseline) |        14 |                 0 |                67.02% |                 0.00% | 0.00011 |      21 |
 +---------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-DataSahVSTypeTiny>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-DataSahVSTypeTiny>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-DataSahVSTypeTiny>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2017, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
