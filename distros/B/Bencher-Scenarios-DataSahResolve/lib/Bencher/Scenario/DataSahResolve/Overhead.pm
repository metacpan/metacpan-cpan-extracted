package Bencher::Scenario::DataSahResolve::Overhead;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-08-01'; # DATE
our $DIST = 'Bencher-Scenarios-DataSahResolve'; # DIST
our $VERSION = '0.004'; # VERSION

use 5.010001;
use strict;
use warnings;

use Sah::Schema::perl::distname; # to pull dependency
use Sah::Schema::perl::modname;  # to pull dependency
use Sah::Schema::poseven;        # to pull dependency
use Sah::Schema::posint;         # to pull dependency

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

This document describes version 0.004 of Bencher::Scenario::DataSahResolve::Overhead (from Perl distribution Bencher-Scenarios-DataSahResolve), released on 2021-08-01.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m DataSahResolve::Overhead

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Data::Sah> 0.909

L<Data::Sah::Normalize> 0.051

L<Data::Sah::Resolve> 0.011

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

=head1 BENCHMARK SAMPLE RESULTS

=head2 Sample benchmark #1

Run on: perl: I<< v5.34.0 >>, CPU: I<< Intel(R) Core(TM) i7-4770 CPU @ 3.40GHz (4 cores) >>, OS: I<< GNU/Linux LinuxMint version 19 >>, OS kernel: I<< Linux version 5.3.0-68-generic >>.

Benchmark command (default options):

 % bencher -m DataSahResolve::Overhead

Result formatted as table:

 #table1#
 +------------------+---------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant      | dataset       | rate (/s) | time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +------------------+---------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | gen_validator    | 5-schemas     |        19 |        53 |                 0.00% |               609.35% | 0.00015 |      20 |
 | gen_validator    | perl::modname |        23 |        44 |                20.69% |               487.72% | 0.00014 |      20 |
 | gen_validator    | int           |        24 |        41 |                27.73% |               455.34% | 0.00023 |      20 |
 | resolve_schema   | 5-schemas     |        60 |        17 |               214.27% |               125.71% | 0.00013 |      20 |
 | resolve_schema   | perl::modname |        70 |        20 |               250.89% |               102.16% | 0.00015 |      20 |
 | resolve_schema   | int           |        71 |        14 |               275.44% |                88.94% | 0.00012 |      20 |
 | normalize_schema | int           |       100 |         8 |               559.28% |                 7.59% | 0.00018 |      20 |
 | normalize_schema | 5-schemas     |       100 |         8 |               577.87% |                 4.64% | 0.00011 |      20 |
 | normalize_schema | perl::modname |       100 |         7 |               609.35% |                 0.00% | 0.00016 |      20 |
 +------------------+---------------+-----------+-----------+-----------------------+-----------------------+---------+---------+


The above result formatted in L<Benchmark.pm|Benchmark> style:

                      Rate  g_v 5-schemas  g_v perl::modname  g_v int  r_s perl::modname  r_s 5-schemas  r_s int  n_s int  n_s 5-schemas  n_s perl::modname 
  g_v 5-schemas       19/s             --               -16%     -22%               -62%           -67%     -73%     -84%           -84%               -86% 
  g_v perl::modname   23/s            20%                 --      -6%               -54%           -61%     -68%     -81%           -81%               -84% 
  g_v int             24/s            29%                 7%       --               -51%           -58%     -65%     -80%           -80%               -82% 
  r_s perl::modname   70/s           165%               120%     104%                 --           -15%     -30%     -60%           -60%               -65% 
  r_s 5-schemas       60/s           211%               158%     141%                17%             --     -17%     -52%           -52%               -58% 
  r_s int             71/s           278%               214%     192%                42%            21%       --     -42%           -42%               -50% 
  n_s int            100/s           562%               450%     412%               150%           112%      75%       --             0%               -12% 
  n_s 5-schemas      100/s           562%               450%     412%               150%           112%      75%       0%             --               -12% 
  n_s perl::modname  100/s           657%               528%     485%               185%           142%     100%      14%            14%                 -- 
 
 Legends:
   g_v 5-schemas: dataset=5-schemas participant=gen_validator
   g_v int: dataset=int participant=gen_validator
   g_v perl::modname: dataset=perl::modname participant=gen_validator
   n_s 5-schemas: dataset=5-schemas participant=normalize_schema
   n_s int: dataset=int participant=normalize_schema
   n_s perl::modname: dataset=perl::modname participant=normalize_schema
   r_s 5-schemas: dataset=5-schemas participant=resolve_schema
   r_s int: dataset=int participant=resolve_schema
   r_s perl::modname: dataset=perl::modname participant=resolve_schema

The above result presented as chart:

=begin html

<img src="data:image/png;base64,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" />

=end html


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

This software is copyright (c) 2021, 2017, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
