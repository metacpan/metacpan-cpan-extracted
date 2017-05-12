package Bencher::Scenario::PerinciSubNormalize;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.05'; # VERSION

our $scenario = {
    summary => 'Benchmark normalizing Rinci function metadata',
    modules => {
        'Perinci::Sub::Normalize' => {version=>0.19},
    },
    participants => [
        {
            fcall_template => 'Perinci::Sub::Normalize::normalize_function_metadata(<meta>)'
        },
    ],
    datasets => [

        {
            name    => 'minimal',
            summary => 'Only contains v=>1.1',
            args    => {
                meta => {
                    v => 1.1,
                },
            },
        },

        {
            name => '0args',
            args => {
                meta => {
                    v => 1.1,
                    summary => 'Some summary',
                    description => <<'_',

Some description. Some description. Some description. Some description. Some
description. Some description. Some description. Some description. Some
description.

_
                    args => {},
                },
            },
        },

        {
            name => '1arg',
            args => {
                meta => {
                    v => 1.1,
                    summary => 'Some summary',
                    description => <<'_',

Some description. Some description. Some description. Some description. Some
description. Some description. Some description. Some description. Some
description.

_
                    args => {
                        arg1 => {
                            summary => 'Some summary',
                            schema => 'str*',
                            req => 1,
                            pos => 0,
                        },
                    },
                },
            },
        },

        {
            name => 'typical',
            summary => '5 arguments',
            args => {
                meta => {
                    v => 1.1,
                    summary => 'Some summary',
                    description => <<'_',

Some description. Some description. Some description. Some description. Some
description. Some description. Some description. Some description. Some
description.

_
                    args => {
                        arg1 => {
                            summary => 'Some summary',
                            schema => 'str*',
                            req => 1,
                            pos => 0,
                        },
                        arg2 => {
                            summary => 'Some summary',
                            schema => ['array*' => of => 'str*', min_len=>1],
                            req => 1,
                            pos => 1,
                            greedy => 1,
                        },
                        arg3 => {
                            summary => 'Some summary',
                            schema => ['int*', min=>1, max=>100],
                            req => 1,
                        },
                        arg4 => {
                            summary => 'Some summary',
                            schema => [bool => is=>1],
                            cmdline_aliases => {f=>{is_flag=>1}},
                        },
                        arg5 => {
                            summary => 'Some summary',
                            schema => 'hash*',
                        },
                    },
                },
            },
        },

    ],
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::PerinciSubNormalize

=head1 VERSION

This document describes version 0.05 of Bencher::Scenario::PerinciSubNormalize (from Perl distribution Bencher-Scenarios-Perinci), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m PerinciSubNormalize

To run module startup overhead benchmark:

 % bencher --module-startup -m PerinciSubNormalize

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Perinci::Sub::Normalize> 0.19

=head1 BENCHMARK PARTICIPANTS

=over

=item * Perinci::Sub::Normalize::normalize_function_metadata (perl_code)

Function call template:

 Perinci::Sub::Normalize::normalize_function_metadata(<meta>)



=back

=head1 BENCHMARK DATASETS

=over

=item * minimal

Only contains v=>1.1

=item * 0args

=item * 1arg

=item * typical

5 arguments

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m PerinciSubNormalize >>):

 #table1#
 +---------+-----------+-----------+------------+---------+---------+
 | dataset | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +---------+-----------+-----------+------------+---------+---------+
 | typical |      8200 |   120     |       1    | 2.7e-07 |      20 |
 | 1arg    |     35000 |    29     |       4.3  | 5.3e-08 |      20 |
 | 0args   |     77000 |    13     |       9.4  | 3.3e-08 |      20 |
 | minimal |    180400 |     5.542 |      22.13 | 3.5e-10 |      20 |
 +---------+-----------+-----------+------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m PerinciSubNormalize --module-startup >>):

 #table2#
 +-------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | participant             | proc_private_dirty_size (kB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +-------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | Perinci::Sub::Normalize | 844                          | 4                  | 16             |       9.4 |                    3.6 |        1   | 5.5e-05 |      20 |
 | perl -e1 (baseline)     | 1044                         | 4.4                | 16             |       5.8 |                    0   |        1.6 | 9.6e-06 |      20 |
 +-------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-Perinci>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-Perinci>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-Perinci>

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
