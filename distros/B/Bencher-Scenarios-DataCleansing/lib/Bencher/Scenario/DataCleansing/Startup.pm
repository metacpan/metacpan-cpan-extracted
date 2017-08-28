package Bencher::Scenario::DataCleansing::Startup;

our $DATE = '2017-08-25'; # DATE
our $VERSION = '0.004'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark startup of various data cleansing modules',
    module_startup => 1,
    modules => {
        # specify minimum version
        'Data::Clean::JSON' => {version=>'0.38'},
    },
    participants => [
        {module=>'Data::Clean'},
        {module=>'Data::Clean::JSON'},

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

This document describes version 0.004 of Bencher::Scenario::DataCleansing::Startup (from Perl distribution Bencher-Scenarios-DataCleansing), released on 2017-08-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m DataCleansing::Startup

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Cpanel::JSON::XS> 3.0217

L<Data::Abridge> 0.03.01

L<Data::Clean> 0.49

L<Data::Clean::JSON> 0.38

L<Data::Rmap> 0.64

L<Data::Tersify> 0.001

L<Data::Visitor::Callback> 0.30

L<JSON::MaybeXS> 1.003005

L<JSON::PP> 2.27300

L<JSON::XS> 3.02

=head1 BENCHMARK PARTICIPANTS

=over

=item * Data::Clean (perl_code)

L<Data::Clean>



=item * Data::Clean::JSON (perl_code)

L<Data::Clean::JSON>



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

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m DataCleansing::Startup >>):

 #table1#
 +-------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+-----------+---------+
 | participant             | proc_private_dirty_size (MB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors   | samples |
 +-------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+-----------+---------+
 | Data::Visitor::Callback | 3.1                          | 6.5                | 22             |     210   |                  202.4 |        1   |   0.00045 |      20 |
 | Data::Tersify           | 0.82                         | 4.2                | 16             |      34   |                   26.4 |        6   |   0.00013 |      20 |
 | JSON::PP                | 1.3                          | 4.8                | 20             |      29   |                   21.4 |        7.2 |   9e-05   |      20 |
 | JSON::MaybeXS           | 3.12                         | 6.68               | 22.3           |      20.5 |                   12.9 |       10   | 1.9e-05   |      20 |
 | Data::Abridge           | 16                           | 19                 | 55             |      19   |                   11.4 |       11   | 4.7e-05   |      20 |
 | JSON::XS                | 1.3                          | 4.8                | 20             |      16   |                    8.4 |       13   | 6.5e-05   |      20 |
 | Data::Rmap              | 1.7                          | 5.1                | 19             |      16   |                    8.4 |       13   | 5.7e-05   |      21 |
 | Cpanel::JSON::XS        | 1.4                          | 4.8                | 19             |      15   |                    7.4 |       14   | 4.5e-05   |      22 |
 | Data::Clean::JSON       | 1.9                          | 5.4                | 23             |      15   |                    7.4 |       14   | 4.3e-05   |      20 |
 | Data::Clean             | 1.3                          | 4.7                | 16             |      12   |                    4.4 |       16   | 3.7e-05   |      20 |
 | perl -e1 (baseline)     | 1.1                          | 4.5                | 16             |       7.6 |                    0   |       27   | 1.6e-05   |      20 |
 +-------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+-----------+---------+


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

This software is copyright (c) 2017, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
