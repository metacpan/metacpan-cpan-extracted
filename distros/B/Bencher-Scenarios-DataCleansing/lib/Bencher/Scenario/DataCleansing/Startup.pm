package Bencher::Scenario::DataCleansing::Startup;

our $DATE = '2019-09-11'; # DATE
our $VERSION = '0.005'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark startup of various data cleansing modules',
    module_startup => 1,
    modules => {
    },
    participants => [
        {module=>'Data::Clean'},
        {module=>'Data::Clean::ForJSON'},

        {module=>'JSON::MaybeXS'},
        {module=>'JSON::PP'},
        {module=>'JSON::XS'},
        {module=>'Cpanel::JSON::XS'},

        {module=>'Data::Rmap'},
        {module=>'Data::Abridge'},
        {module=>'Data::Visitor::Callback'},
        {module=>'Data::Tersify'},
    ],
};

1;
# ABSTRACT: Benchmark startup of various data cleansing modules

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::DataCleansing::Startup - Benchmark startup of various data cleansing modules

=head1 VERSION

This document describes version 0.005 of Bencher::Scenario::DataCleansing::Startup (from Perl distribution Bencher-Scenarios-DataCleansing), released on 2019-09-11.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m DataCleansing::Startup

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Cpanel::JSON::XS> 3.0239

L<Data::Abridge> 0.03.01

L<Data::Clean> 0.505

L<Data::Clean::ForJSON> 0.394

L<Data::Rmap> 0.65

L<Data::Tersify> 0.001

L<Data::Visitor::Callback> 0.30

L<JSON::MaybeXS> 1.004

L<JSON::PP> 2.27400_02

L<JSON::XS> 3.04

=head1 BENCHMARK PARTICIPANTS

=over

=item * Data::Clean (perl_code)

L<Data::Clean>



=item * Data::Clean::ForJSON (perl_code)

L<Data::Clean::ForJSON>



=item * JSON::MaybeXS (perl_code)

L<JSON::MaybeXS>



=item * JSON::PP (perl_code)

L<JSON::PP>



=item * JSON::XS (perl_code)

L<JSON::XS>



=item * Cpanel::JSON::XS (perl_code)

L<Cpanel::JSON::XS>



=item * Data::Rmap (perl_code)

L<Data::Rmap>



=item * Data::Abridge (perl_code)

L<Data::Abridge>



=item * Data::Visitor::Callback (perl_code)

L<Data::Visitor::Callback>



=item * Data::Tersify (perl_code)

L<Data::Tersify>



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.26.1 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 18.3 >>, OS kernel: I<< Linux version 4.10.0-38-generic >>.

Benchmark with default options (C<< bencher -m DataCleansing::Startup >>):

 #table1#
 +-------------------------+-----------+------------------------+------------+----------+---------+
 | participant             | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors  | samples |
 +-------------------------+-----------+------------------------+------------+----------+---------+
 | Data::Visitor::Callback |     190   |                  181.3 |       1    |   0.0004 |      20 |
 | Data::Tersify           |      32   |                   23.3 |       6    | 3.5e-05  |      23 |
 | JSON::PP                |      28.8 |                   20.1 |       6.75 | 2.5e-05  |      22 |
 | JSON::MaybeXS           |      21   |                   12.3 |       9.28 | 1.7e-05  |      20 |
 | Data::Abridge           |      19.1 |                   10.4 |      10.2  | 1.7e-05  |      21 |
 | Data::Rmap              |      16   |                    7.3 |      12    | 3.3e-05  |      21 |
 | JSON::XS                |      16   |                    7.3 |      12    | 2.7e-05  |      20 |
 | Cpanel::JSON::XS        |      15   |                    6.3 |      13    | 1.7e-05  |      20 |
 | Data::Clean::ForJSON    |      15   |                    6.3 |      13    | 3.8e-05  |      20 |
 | Data::Clean             |      13   |                    4.3 |      15    | 3.4e-05  |      20 |
 | perl -e1 (baseline)     |       8.7 |                    0   |      22    |   3e-05  |      20 |
 +-------------------------+-----------+------------------------+------------+----------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-DataCleansing>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-DataCleansing>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-DataCleansing>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2017, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
