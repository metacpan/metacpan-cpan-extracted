package Bencher::Scenario::ModulePathMore;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;

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

Bencher::Scenario::ModulePathMore - Benchmark Module::Path::More vs Module::Path

=head1 VERSION

This document describes version 0.002 of Bencher::Scenario::ModulePathMore (from Perl distribution Bencher-Scenario-ModulePathMore), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m ModulePathMore

To run module startup overhead benchmark:

 % bencher --module-startup -m ModulePathMore

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Module::Path> 0.13

L<Module::Path::More> 0.31

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

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m ModulePathMore >>):

 #table1#
 +-------------+----------+-----------+-----------+------------+---------+---------+
 | participant | dataset  | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +-------------+----------+-----------+-----------+------------+---------+---------+
 | MPM(abs=1)  | strict   |     31000 |      32   |       1    | 5.2e-08 |      21 |
 | MPM(abs=1)  | Foo::Bar |     42900 |      23.3 |       1.39 |   2e-08 |      20 |
 | MPM         | Foo::Bar |     43000 |      23   |       1.4  | 2.7e-08 |      20 |
 | MP          | Foo::Bar |     44000 |      23   |       1.4  | 3.3e-08 |      20 |
 | MP          | strict   |     48000 |      21   |       1.6  | 3.3e-08 |      20 |
 | MPM         | strict   |     48000 |      21   |       1.6  | 4.5e-08 |      28 |
 +-------------+----------+-----------+-----------+------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m ModulePathMore --module-startup >>):

 #table2#
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+-----------+---------+
 | participant         | proc_private_dirty_size (kB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors   | samples |
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+-----------+---------+
 | Module::Path::More  | 1004                         | 4                  | 20             |      10   |                    4.7 |        1   |   0.00018 |      20 |
 | Module::Path        | 1004                         | 4.4                | 16             |       8.7 |                    3.4 |        1.2 | 4.1e-05   |      21 |
 | perl -e1 (baseline) | 980                          | 4.3                | 16             |       5.3 |                    0   |        2   | 2.4e-05   |      20 |
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+-----------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-ModulePathMore>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-ModulePathMore>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-ModulePathMore>

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
