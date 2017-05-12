package Bencher::Scenario::DataSahVSTypeTiny::Validate;

use 5.010001;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.002'; # VERSION

eval "package main; use Types::Standard qw(ArrayRef Int)";

our $scenario = {
    summary => 'Benchmark validation',
    modules => {
        'Data::Sah' => {version=>'0.84'},
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
            code_template => 'state $v = <type:raw>; $v->check(<data>)',
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

This document describes version 0.002 of Bencher::Scenario::DataSahVSTypeTiny::Validate (from Perl distribution Bencher-Scenarios-DataSahVSTypeTiny), released on 2017-01-25.

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

L<Data::Sah> 0.87

=head1 BENCHMARK PARTICIPANTS

=over

=item * dsah (perl_code) [dsah]

Code template:

 state $v = Data::Sah::gen_validator(<schema>); $v->(<data>)



=item * tt (perl_code) [tt]

Code template:

 state $v = <type:raw>; $v->check(<data>)



=back

=head1 BENCHMARK DATASETS

=over

=item * int(dsah)

=item * int(tt)

=item * array10(dsah)

=item * array10(tt)

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m DataSahVSTypeTiny::Validate >>):

 #table1#
 +-------------+---------------+----------+-----------+-----------+------------+---------+---------+
 | participant | dataset       | arg_data | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +-------------+---------------+----------+-----------+-----------+------------+---------+---------+
 | dsah        | array10(dsah) |          |    274614 |   3.64147 |       1    |   0     |      20 |
 | tt          | array10(tt)   |          |   1500000 |   0.68    |       5.4  | 8.3e-10 |      20 |
 | dsah        | int(dsah)     | a        |   3600000 |   0.28    |      13    | 4.2e-10 |      20 |
 | tt          | int(tt)       |          |   3752000 |   0.2665  |      13.66 | 1.1e-11 |      20 |
 | tt          | int(tt)       | a        |   3755000 |   0.2663  |      13.67 | 9.7e-12 |      20 |
 | tt          | int(tt)       | 1        |   3800000 |   0.26    |      14    | 4.2e-10 |      20 |
 | dsah        | int(dsah)     | 1        |   3900000 |   0.257   |      14.2  | 9.1e-11 |      26 |
 | dsah        | int(dsah)     |          |   5940000 |   0.168   |      21.6  |   1e-10 |      20 |
 +-------------+---------------+----------+-----------+-----------+------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m DataSahVSTypeTiny::Validate --module-startup >>):

 #table2#
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | participant         | proc_private_dirty_size (MB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | Data::Sah           | 0.82                         | 4.2                | 16             |      12   |                    6.4 |        1   | 5.3e-05 |      20 |
 | perl -e1 (baseline) | 1.3                          | 4.7                | 16             |       5.6 |                    0   |        2.2 | 1.1e-05 |      21 |
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+


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

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
