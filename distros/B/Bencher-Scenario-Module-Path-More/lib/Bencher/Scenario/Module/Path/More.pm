package Bencher::Scenario::Module::Path::More;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-05-07'; # DATE
our $DIST = 'Bencher-Scenario-Module-Path-More'; # DIST
our $VERSION = '0.003'; # VERSION

our $scenario = {
    summary => 'Benchmark Module::Path::More vs Module::Path',
    participants => [
        {
            name => 'MP',
            fcall_template => 'Module::Path::module_path(<module>)',
        },
        {
            name => 'MPM',
            fcall_template => 'Module::Path::More::module_path(module => <module>)',
        },
        {
            name => 'MPM(abs=1)',
            fcall_template => 'Module::Path::More::module_path(module => <module>, abs=>1)',
        },
    ],
    datasets => [
        {args=>{module=>'strict'}},
        {args=>{module=>'Foo::Bar'}},
    ],
};

1;
# ABSTRACT: Benchmark Module::Path::More vs Module::Path

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::Module::Path::More - Benchmark Module::Path::More vs Module::Path

=head1 VERSION

This document describes version 0.003 of Bencher::Scenario::Module::Path::More (from Perl distribution Bencher-Scenario-Module-Path-More), released on 2022-05-07.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m Module::Path::More

To run module startup overhead benchmark:

 % bencher --module-startup -m Module::Path::More

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Module::Path> 0.13

L<Module::Path::More> 0.340

=head1 BENCHMARK PARTICIPANTS

=over

=item * MP (perl_code)

Function call template:

 Module::Path::module_path(<module>)



=item * MPM (perl_code)

Function call template:

 Module::Path::More::module_path(module => <module>)



=item * MPM(abs=1) (perl_code)

Function call template:

 Module::Path::More::module_path(module => <module>, abs=>1)



=back

=head1 BENCHMARK DATASETS

=over

=item * strict

=item * Foo::Bar

=back

=head1 BENCHMARK SAMPLE RESULTS

=head2 Sample benchmark #1

Run on: perl: I<< v5.34.0 >>, CPU: I<< Intel(R) Core(TM) i7-4770 CPU @ 3.40GHz (4 cores) >>, OS: I<< GNU/Linux LinuxMint version 19 >>, OS kernel: I<< Linux version 5.3.0-68-generic >>.

Benchmark command (default options):

 % bencher -m Module::Path::More

Result formatted as table:

 #table1#
 +-------------+----------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant | dataset  | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------+----------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | MPM(abs=1)  | Foo::Bar |   25200   |   39.7    |                 0.00% |               223.59% | 1.3e-08 |      22 |
 | MPM(abs=1)  | strict   |   27600   |   36.2    |                 9.67% |               195.06% | 1.3e-08 |      22 |
 | MPM         | Foo::Bar |   49700   |   20.1    |                97.17% |                64.11% | 6.4e-09 |      22 |
 | MPM         | strict   |   50000   |   20      |               100.49% |                61.40% | 2.7e-08 |      20 |
 | MP          | strict   |   51561.2 |   19.3944 |               104.74% |                58.05% |   0     |      20 |
 | MP          | Foo::Bar |   81500   |   12.3    |               223.59% |                 0.00% | 3.3e-09 |      21 |
 +-------------+----------+-----------+-----------+-----------------------+-----------------------+---------+---------+


The above result formatted in L<Benchmark.pm|Benchmark> style:

                            Rate  MPM(abs=1) Foo::Bar  MPM(abs=1) strict  MPM Foo::Bar  MPM strict  MP strict  MP Foo::Bar 
  MPM(abs=1) Foo::Bar    25200/s                   --                -8%          -49%        -49%       -51%         -69% 
  MPM(abs=1) strict      27600/s                   9%                 --          -44%        -44%       -46%         -66% 
  MPM Foo::Bar           49700/s                  97%                80%            --          0%        -3%         -38% 
  MPM strict             50000/s                  98%                81%            0%          --        -3%         -38% 
  MP strict            51561.2/s                 104%                86%            3%          3%         --         -36% 
  MP Foo::Bar            81500/s                 222%               194%           63%         62%        57%           -- 
 
 Legends:
   MP Foo::Bar: dataset=Foo::Bar participant=MP
   MP strict: dataset=strict participant=MP
   MPM Foo::Bar: dataset=Foo::Bar participant=MPM
   MPM strict: dataset=strict participant=MPM
   MPM(abs=1) Foo::Bar: dataset=Foo::Bar participant=MPM(abs=1)
   MPM(abs=1) strict: dataset=strict participant=MPM(abs=1)

=head2 Sample benchmark #2

Benchmark command (benchmarking module startup overhead):

 % bencher -m Module::Path::More --module-startup

Result formatted as table:

 #table2#
 +---------------------+-----------+-------------------+-----------------------+-----------------------+-----------+---------+
 | participant         | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors   | samples |
 +---------------------+-----------+-------------------+-----------------------+-----------------------+-----------+---------+
 | Module::Path::More  |       8   |               3.6 |                 0.00% |                78.53% |   0.00011 |      20 |
 | Module::Path        |       8   |               3.6 |                 1.95% |                75.12% |   0.0002  |      20 |
 | perl -e1 (baseline) |       4.4 |               0   |                78.53% |                 0.00% | 3.7e-05   |      20 |
 +---------------------+-----------+-------------------+-----------------------+-----------------------+-----------+---------+


The above result formatted in L<Benchmark.pm|Benchmark> style:

                          Rate  MP:M  M:P  perl -e1 (baseline) 
  MP:M                 125.0/s    --   0%                 -44% 
  M:P                  125.0/s    0%   --                 -44% 
  perl -e1 (baseline)  227.3/s   81%  81%                   -- 
 
 Legends:
   M:P: mod_overhead_time=3.6 participant=Module::Path
   MP:M: mod_overhead_time=3.6 participant=Module::Path::More
   perl -e1 (baseline): mod_overhead_time=0 participant=perl -e1 (baseline)

To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-Module-Path-More>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-Module-Path-More>.

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

This software is copyright (c) 2022, 2017, 2016 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-Module-Path-More>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
