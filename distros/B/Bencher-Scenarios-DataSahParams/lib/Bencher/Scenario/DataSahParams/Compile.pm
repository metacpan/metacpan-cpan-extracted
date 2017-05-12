package Bencher::Scenario::DataSahParams::Compile;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Measure compilation speed',
    participants => [
        {
            name => 'dsp',
            fcall_template => q(Data::Sah::Params::compile("int*", ["array*",of=>"int*"])),
        },
        {
            name => 'tp',
            module => 'Type::Params',
            code_template => q(use Type::Params qw(compile); use Types::Standard qw(Int ArrayRef); compile(Int, ArrayRef[Int])),
        },
    ],
};

1;
# ABSTRACT: Measure compilation speed

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::DataSahParams::Compile - Measure compilation speed

=head1 VERSION

This document describes version 0.002 of Bencher::Scenario::DataSahParams::Compile (from Perl distribution Bencher-Scenarios-DataSahParams), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m DataSahParams::Compile

To run module startup overhead benchmark:

 % bencher --module-startup -m DataSahParams::Compile

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Data::Sah::Params> 0.003

L<Type::Params> 1.000005

=head1 BENCHMARK PARTICIPANTS

=over

=item * dsp (perl_code)

Function call template:

 Data::Sah::Params::compile("int*", ["array*",of=>"int*"])



=item * tp (perl_code)

Code template:

 use Type::Params qw(compile); use Types::Standard qw(Int ArrayRef); compile(Int, ArrayRef[Int])



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m DataSahParams::Compile >>):

 #table1#
 +-------------+-----------+-----------+------------+---------+---------+
 | participant | rate (/s) | time (ms) | vs_slowest |  errors | samples |
 +-------------+-----------+-----------+------------+---------+---------+
 | dsp         |       370 |      2.7  |        1   | 2.1e-05 |      20 |
 | tp          |      3600 |      0.28 |        9.7 | 3.7e-07 |      20 |
 +-------------+-----------+-----------+------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m DataSahParams::Compile --module-startup >>):

 #table2#
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | participant         | proc_private_dirty_size (MB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | Type::Params        | 0.82                         | 4                  | 16             |      42   |                   36.3 |        1   | 5.7e-05 |      20 |
 | Data::Sah::Params   | 5.4                          | 9.1                | 31             |       9   |                    3.3 |        4.6 | 2.2e-05 |      20 |
 | perl -e1 (baseline) | 0.96                         | 4.4                | 16             |       5.7 |                    0   |        7.3 | 1.3e-05 |      20 |
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 BENCHMARK NOTES

Data::Sah compilation is slower due to doing more stuffs (normalizing schema,
other preparations). If needed, future version of Data::Sah (or
Data::Sah::Params) should cache compilation result so common schemas that are
ecountered several times can be compiled more quickly.

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
