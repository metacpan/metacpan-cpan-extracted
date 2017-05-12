package Bencher::Scenario::DataSahResolve::Overhead;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.003'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark the overhead of resolving schemas',
    modules => {
        'Data::Sah' => {},
        'Data::Sah::Normalize' => {},
        'Data::Sah::Resolve' => {},
    },
    participants => [
        {
            name => 'resolve_schema',
            perl_cmdline_template => ["-MData::Sah::Resolve=resolve_schema", "-e", 'for (@{ <schemas> }) { resolve_schema($_) }'],
        },
        {
            name => 'normalize_schema',
            perl_cmdline_template => ["-MData::Sah::Normalize=normalize_schema", "-e", 'for (@{ <schemas> }) { normalize_schema($_) }'],
        },
        {
            name => 'gen_validator',
            perl_cmdline_template => ["-MData::Sah=gen_validator", "-e", 'for (@{ <schemas> }) { gen_validator($_, {return_type=>q(str)}) }'],
        },
    ],

    datasets => [
        {name=>"int"           , args=>{schemas=>'[q(int)]'}},
        {name=>"perl::modname" , args=>{schemas=>'[q(perl::modname)]'}},
        {name=>"5-schemas"     , args=>{schemas=>'[q(int),q(perl::distname),q(perl::modname),q(posint),q(poseven)]'}},
    ],
};

1;
# ABSTRACT: Benchmark the overhead of resolving schemas

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::DataSahResolve::Overhead - Benchmark the overhead of resolving schemas

=head1 VERSION

This document describes version 0.003 of Bencher::Scenario::DataSahResolve::Overhead (from Perl distribution Bencher-Scenarios-DataSahResolve), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m DataSahResolve::Overhead

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Data::Sah> 0.87

L<Data::Sah::Normalize> 0.04

L<Data::Sah::Resolve> 0.004

=head1 BENCHMARK PARTICIPANTS

=over

=item * resolve_schema (command)

Command line:

 #TEMPLATE: #perl -MData::Sah::Resolve=resolve_schema -e for (@{ <schemas> }) { resolve_schema($_) }



=item * normalize_schema (command)

Command line:

 #TEMPLATE: #perl -MData::Sah::Normalize=normalize_schema -e for (@{ <schemas> }) { normalize_schema($_) }



=item * gen_validator (command)

Command line:

 #TEMPLATE: #perl -MData::Sah=gen_validator -e for (@{ <schemas> }) { gen_validator($_, {return_type=>q(str)}) }



=back

=head1 BENCHMARK DATASETS

=over

=item * int

=item * perl::modname

=item * 5-schemas

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m DataSahResolve::Overhead >>):

 #table1#
 +------------------+---------------+-----------+-----------+------------+-----------+---------+
 | participant      | dataset       | rate (/s) | time (ms) | vs_slowest |  errors   | samples |
 +------------------+---------------+-----------+-----------+------------+-----------+---------+
 | gen_validator    | 5-schemas     |        15 |      69   |        1   | 9.5e-05   |      21 |
 | gen_validator    | perl::modname |        18 |      57   |        1.2 |   8e-05   |      20 |
 | gen_validator    | int           |        18 |      54   |        1.3 |   0.00018 |      20 |
 | resolve_schema   | 5-schemas     |        57 |      18   |        3.9 |   0.00011 |      20 |
 | resolve_schema   | perl::modname |        61 |      16   |        4.2 | 5.6e-05   |      20 |
 | resolve_schema   | int           |        64 |      16   |        4.4 | 7.1e-05   |      20 |
 | normalize_schema | 5-schemas     |       110 |       9.3 |        7.4 | 4.8e-05   |      20 |
 | normalize_schema | perl::modname |       110 |       9.2 |        7.5 | 3.4e-05   |      20 |
 | normalize_schema | int           |       110 |       9.2 |        7.5 | 4.5e-05   |      20 |
 +------------------+---------------+-----------+-----------+------------+-----------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-DataSahResolve>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-DataSahResolve>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-DataSahResolve>

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
