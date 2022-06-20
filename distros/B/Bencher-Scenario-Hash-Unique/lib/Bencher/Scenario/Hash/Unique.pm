package Bencher::Scenario::Hash::Unique;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-05-07'; # DATE
our $DIST = 'Bencher-Scenario-Hash-Unique'; # DIST
our $VERSION = '0.002'; # VERSION

our $scenario = {
    summary => 'Benchmark Hash::Unique',
    modules => {
        'Hash::Unique' => { version=>"0.06" },
    },
    participants => [
        {
            name => 'Hash::Unique',
            module => 'Hash::Unique',
            code_template => '[ Hash::Unique->get_unique_hash(<array>, <key>) ]',
        },
        {
            name => 'ad-hoc',
            code_template => 'my @res; my %seen; for (@{ <array> }) { push @res, $_ unless $seen{ $_->{ <key> } }++ }; \@res',
        },
    ],
    datasets => [
        {
            name=>'2elems-1key',
            args=>{
                array=>[
                    {a=>1},
                    {a=>1},
                ],
                key => 'a',
            },
            result=>[
                {a=>1},
            ],
        },
        {
            name=>'10elems-3keys',
            args=>{
                array=>[
                    {a=>1, b=>1, c=>1}, #0
                    {a=>1, b=>1, c=>1}, #1
                    {a=>1, b=>1, c=>2}, #2
                    {a=>1, b=>2, c=>1}, #3
                    {a=>1, b=>1, c=>1}, #4
                    {a=>1, b=>2, c=>1}, #5
                    {a=>1, b=>1, c=>3}, #6
                    {a=>1, b=>1, c=>4}, #7
                    {a=>1, b=>2, c=>1}, #8
                    {a=>2, b=>1, c=>2}, #9
                ],
                key => 'c',
            },
            result=>[
                {a=>1, b=>1, c=>1}, #0
                {a=>1, b=>1, c=>2}, #2
                {a=>1, b=>1, c=>3}, #6
                {a=>1, b=>1, c=>4}, #7
            ],
        },
    ],
};

1;
# ABSTRACT: Benchmark Hash::Unique

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::Hash::Unique - Benchmark Hash::Unique

=head1 VERSION

This document describes version 0.002 of Bencher::Scenario::Hash::Unique (from Perl distribution Bencher-Scenario-Hash-Unique), released on 2022-05-07.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m Hash::Unique

To run module startup overhead benchmark:

 % bencher --module-startup -m Hash::Unique

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Hash::Unique> 0.06

=head1 BENCHMARK PARTICIPANTS

=over

=item * Hash::Unique (perl_code)

Code template:

 [ Hash::Unique->get_unique_hash(<array>, <key>) ]



=item * ad-hoc (perl_code)

Code template:

 my @res; my %seen; for (@{ <array> }) { push @res, $_ unless $seen{ $_->{ <key> } }++ }; \@res



=back

=head1 BENCHMARK DATASETS

=over

=item * 2elems-1key

=item * 10elems-3keys

=back

=head1 BENCHMARK SAMPLE RESULTS

=head2 Sample benchmark #1

Run on: perl: I<< v5.34.0 >>, CPU: I<< Intel(R) Core(TM) i7-4770 CPU @ 3.40GHz (4 cores) >>, OS: I<< GNU/Linux LinuxMint version 19 >>, OS kernel: I<< Linux version 5.3.0-68-generic >>.

Benchmark command (default options):

 % bencher -m Hash::Unique

Result formatted as table:

 #table1#
 +--------------+---------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant  | dataset       | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +--------------+---------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | Hash::Unique | 10elems-3keys |    147825 |   6.76475 |                 0.00% |               596.87% | 4.9e-12 |      20 |
 | ad-hoc       | 10elems-3keys |    222976 |   4.48479 |                50.84% |               362.00% |   0     |      20 |
 | Hash::Unique | 2elems-1key   |    632840 |   1.58018 |               328.10% |                62.78% |   0     |      20 |
 | ad-hoc       | 2elems-1key   |   1030100 |   0.97073 |               596.87% |                 0.00% | 5.8e-12 |      20 |
 +--------------+---------------+-----------+-----------+-----------------------+-----------------------+---------+---------+


The above result formatted in L<Benchmark.pm|Benchmark> style:

                                   Rate  Hash::Unique 10elems-3keys  ad-hoc 10elems-3keys  Hash::Unique 2elems-1key  ad-hoc 2elems-1key 
  Hash::Unique 10elems-3keys   147825/s                          --                  -33%                      -76%                -85% 
  ad-hoc 10elems-3keys         222976/s                         50%                    --                      -64%                -78% 
  Hash::Unique 2elems-1key     632840/s                        328%                  183%                        --                -38% 
  ad-hoc 2elems-1key          1030100/s                        596%                  362%                       62%                  -- 
 
 Legends:
   Hash::Unique 10elems-3keys: dataset=10elems-3keys participant=Hash::Unique
   Hash::Unique 2elems-1key: dataset=2elems-1key participant=Hash::Unique
   ad-hoc 10elems-3keys: dataset=10elems-3keys participant=ad-hoc
   ad-hoc 2elems-1key: dataset=2elems-1key participant=ad-hoc

=head2 Sample benchmark #2

Benchmark command (benchmarking module startup overhead):

 % bencher -m Hash::Unique --module-startup

Result formatted as table:

 #table2#
 +---------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | participant         | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +---------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | Hash::Unique        |      7    |              2.38 |                 0.00% |                59.30% | 9.8e-05 |      22 |
 | perl -e1 (baseline) |      4.62 |              0    |                59.30% |                 0.00% | 1.8e-06 |      20 |
 +---------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+


The above result formatted in L<Benchmark.pm|Benchmark> style:

                          Rate  H:U  perl -e1 (baseline) 
  H:U                  142.9/s   --                 -34% 
  perl -e1 (baseline)  216.5/s  51%                   -- 
 
 Legends:
   H:U: mod_overhead_time=2.38 participant=Hash::Unique
   perl -e1 (baseline): mod_overhead_time=0 participant=perl -e1 (baseline)

To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-Hash-Unique>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-Hash-Unique>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022, 2017 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-Hash-Unique>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
