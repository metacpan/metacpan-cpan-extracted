package Bencher::Scenario::StringFunctions::CommonPrefix;

our $DATE = '2018-09-16'; # DATE
our $VERSION = '0.001'; # VERSION

use strict;
use warnings;

our $scenario = {
    summary => "Benchmark calculating common prefix",
    participants => [
        {fcall_template=>'String::CommonPrefix::common_prefix(@{<strings>})'},
    ],
    datasets => [
        {name=>'elems0'          , args=>{strings=>[]}},
        {name=>'elems1'          , args=>{strings=>['x']}},
        {name=>'elems10prefix0'  , args=>{strings=>[map{sprintf "%02d", $_} 1..10]}},
        {name=>'elems10prefix1'  , args=>{strings=>[map{sprintf "%02d", $_} 0..9]}},
        {name=>'elems100prefix0' , args=>{strings=>[map{sprintf "%03d", $_} 1..100]}},
        {name=>'elems100prefix1' , args=>{strings=>[map{sprintf "%03d", $_} 0..99]}},
        {name=>'elems1000prefix0', args=>{strings=>[map{sprintf "%04d", $_} 1..1000]}},
        {name=>'elems1000prefix1', args=>{strings=>[map{sprintf "%04d", $_} 0..999]}},
    ],
};

1;
# ABSTRACT: Benchmark calculating common prefix

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::StringFunctions::CommonPrefix - Benchmark calculating common prefix

=head1 VERSION

This document describes version 0.001 of Bencher::Scenario::StringFunctions::CommonPrefix (from Perl distribution Bencher-Scenarios-StringFunctions), released on 2018-09-16.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m StringFunctions::CommonPrefix

To run module startup overhead benchmark:

 % bencher --module-startup -m StringFunctions::CommonPrefix

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<String::CommonPrefix> 0.01

=head1 BENCHMARK PARTICIPANTS

=over

=item * String::CommonPrefix::common_prefix (perl_code)

Function call template:

 String::CommonPrefix::common_prefix(@{<strings>})



=back

=head1 BENCHMARK DATASETS

=over

=item * elems0

=item * elems1

=item * elems10prefix0

=item * elems10prefix1

=item * elems100prefix0

=item * elems100prefix1

=item * elems1000prefix0

=item * elems1000prefix1

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.26.1 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 18.3 >>, OS kernel: I<< Linux version 4.10.0-38-generic >>.

Benchmark with default options (C<< bencher -m StringFunctions::CommonPrefix >>):

 #table1#
 +------------------+------------+-----------+------------+---------+---------+
 | dataset          | rate (/s)  | time (μs) | vs_slowest |  errors | samples |
 +------------------+------------+-----------+------------+---------+---------+
 | elems1000prefix1 |    3060    |   327     |    1       | 5.2e-08 |      21 |
 | elems1000prefix0 |    3508.57 |   285.016 |    1.14835 |   1e-10 |      22 |
 | elems100prefix1  |   30000    |    34     |    9.7     | 5.3e-08 |      20 |
 | elems100prefix0  |   34300    |    29.1   |   11.2     | 1.3e-08 |      20 |
 | elems10prefix1   |  200000    |     5     |   70       |   1e-07 |      20 |
 | elems10prefix0   |  270000    |     3.7   |   90       | 6.7e-09 |      20 |
 | elems1           | 1600000    |     0.64  |  510       | 1.3e-09 |      32 |
 | elems0           | 5800000    |     0.17  | 1900       | 3.2e-10 |      20 |
 +------------------+------------+-----------+------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m StringFunctions::CommonPrefix --module-startup >>):

 #table2#
 +----------------------+-----------+------------------------+------------+---------+---------+
 | participant          | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +----------------------+-----------+------------------------+------------+---------+---------+
 | String::CommonPrefix |       8   |                    2.6 |        1   | 3.1e-05 |      21 |
 | perl -e1 (baseline)  |       5.4 |                    0   |        1.5 | 1.5e-05 |      20 |
 +----------------------+-----------+------------------------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-StringFunctions>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-StringFunctions>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-StringFunctions>

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
