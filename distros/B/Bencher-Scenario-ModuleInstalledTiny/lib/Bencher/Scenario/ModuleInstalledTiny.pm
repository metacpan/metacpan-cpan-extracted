package Bencher::Scenario::ModuleInstalledTiny;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark Module::Installed::Tiny',
    participants => [
        {
            fcall_template => 'Module::Installed::Tiny::module_installed(<module>)',
        },
        {
            fcall_template => 'Module::Path::More::module_path(module => <module>)',
        },
        {
            fcall_template => 'Module::Load::Conditional::check_install(module => <module>)',
        },
        {
            name => 'require',
            code_template => 'eval { (my $pm = <module> . ".pm") =~ s!::!/!g; require $pm; 1 } ? 1:0',
        },
    ],
    datasets => [
        {args=>{module=>'strict'}},
        #{args=>{module=>'App::Cpan'}}, # an example of a relatively heavy core module to load
        {args=>{module=>'Foo::Bar'}},
    ],
};

1;
# ABSTRACT: Benchmark Module::Installed::Tiny

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::ModuleInstalledTiny - Benchmark Module::Installed::Tiny

=head1 VERSION

This document describes version 0.002 of Bencher::Scenario::ModuleInstalledTiny (from Perl distribution Bencher-Scenario-ModuleInstalledTiny), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m ModuleInstalledTiny

To run module startup overhead benchmark:

 % bencher --module-startup -m ModuleInstalledTiny

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Module::Installed::Tiny> 0.003

L<Module::Path::More> 0.31

L<Module::Load::Conditional> 0.68

=head1 BENCHMARK PARTICIPANTS

=over

=item * Module::Installed::Tiny::module_installed (perl_code)

Function call template:

 Module::Installed::Tiny::module_installed(<module>)



=item * Module::Path::More::module_path (perl_code)

Function call template:

 Module::Path::More::module_path(module => <module>)



=item * Module::Load::Conditional::check_install (perl_code)

Function call template:

 Module::Load::Conditional::check_install(module => <module>)



=item * require (perl_code)

Code template:

 eval { (my $pm = <module> . ".pm") =~ s!::!/!g; require $pm; 1 } ? 1:0



=back

=head1 BENCHMARK DATASETS

=over

=item * strict

=item * Foo::Bar

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m ModuleInstalledTiny >>):

 #table1#
 +-------------------------------------------+----------+-----------+-----------+------------+---------+---------+
 | participant                               | dataset  | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +-------------------------------------------+----------+-----------+-----------+------------+---------+---------+
 | Module::Load::Conditional::check_install  | strict   |      2200 |   460     |      1     | 4.5e-06 |      20 |
 | Module::Load::Conditional::check_install  | Foo::Bar |     33000 |    31     |     15     | 6.7e-08 |      20 |
 | Module::Path::More::module_path           | Foo::Bar |     43000 |    23     |     20     | 5.9e-08 |      21 |
 | Module::Path::More::module_path           | strict   |     45000 |    22     |     21     | 2.7e-08 |      20 |
 | require                                   | Foo::Bar |     59000 |    17     |     27     |   2e-08 |      20 |
 | Module::Installed::Tiny::module_installed | Foo::Bar |     60200 |    16.611 |     27.756 | 4.4e-11 |      20 |
 | Module::Installed::Tiny::module_installed | strict   |   1850000 |     0.54  |    853     | 1.7e-10 |      31 |
 | require                                   | strict   |   4060000 |     0.246 |   1870     | 9.9e-11 |      22 |
 +-------------------------------------------+----------+-----------+-----------+------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m ModuleInstalledTiny --module-startup >>):

 #table2#
 +---------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | participant               | proc_private_dirty_size (MB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +---------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | Module::Load::Conditional | 0.82                         | 4                  | 16             |      35   |                   29.4 |        1   | 8.2e-05 |      20 |
 | Module::Path::More        | 4                            | 7.6                | 27             |       9.2 |                    3.6 |        3.8 | 4.1e-05 |      20 |
 | Module::Installed::Tiny   | 0.98                         | 4.3                | 16             |       9.1 |                    3.5 |        3.9 | 3.3e-05 |      21 |
 | perl -e1 (baseline)       | 1                            | 4.3                | 16             |       5.6 |                    0   |        6.3 | 3.5e-05 |      20 |
 +---------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-ModuleInstalledTiny>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-ModuleInstalledTiny>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-ModuleInstalledTiny>

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
