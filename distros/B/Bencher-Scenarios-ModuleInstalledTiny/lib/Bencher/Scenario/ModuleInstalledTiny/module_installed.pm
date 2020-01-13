package Bencher::Scenario::ModuleInstalledTiny::module_installed;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-01-09'; # DATE
our $DIST = 'Bencher-Scenarios-ModuleInstalledTiny'; # DIST
our $VERSION = '0.003'; # VERSION

use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark module_installed() vs some others',
    description => <<'_',

This scenario benchmarks `module_installed()` vs some others for the task of
checking whether a module "is available locally". There are several approaches
(also described in <pm:Module::Installed::Tiny> documentation):

1. require() it (executes module source code, security and resource concern).

2. find module path in filesystem using Module::Path (cannot handle
hooks/references in @INC; on the other hand does not quickly check %INC first).

3. <pm:Module::Load::Conditional>'s `check_install()`. Like `require()`, it
first checks %INC, then scan @INC (hooks/references in @INC are supported).
Additionally, you can specify a version number, in which case it will also use
<pm:Module::Metadata> to extract version from module source code.

4. <pm:Module::Installed::Tiny>'s `module_installed()`, which also does things
like Perl's `require()` except actually evaluating the module source code.

_
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
        {args=>{module=>'Bencher::Scenario::ModuleInstalledTiny::module_installed::Test'}}, # an example of module that does not exist
    ],
};

1;
# ABSTRACT: Benchmark module_installed() vs some others

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::ModuleInstalledTiny::module_installed - Benchmark module_installed() vs some others

=head1 VERSION

This document describes version 0.003 of Bencher::Scenario::ModuleInstalledTiny::module_installed (from Perl distribution Bencher-Scenarios-ModuleInstalledTiny), released on 2020-01-09.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m ModuleInstalledTiny::module_installed

To run module startup overhead benchmark:

 % bencher --module-startup -m ModuleInstalledTiny::module_installed

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

This scenario benchmarks C<module_installed()> vs some others for the task of
checking whether a module "is available locally". There are several approaches
(also described in L<Module::Installed::Tiny> documentation):

=over

=item 1. require() it (executes module source code, security and resource concern).

=item 2. find module path in filesystem using Module::Path (cannot handle
hooks/references in @INC; on the other hand does not quickly check %INC first).

=item 3. L<Module::Load::Conditional>'s C<check_install()>. Like C<require()>, it
first checks %INC, then scan @INC (hooks/references in @INC are supported).
Additionally, you can specify a version number, in which case it will also use
L<Module::Metadata> to extract version from module source code.

=item 4. L<Module::Installed::Tiny>'s C<module_installed()>, which also does things
like Perl's C<require()> except actually evaluating the module source code.

=back


Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Module::Installed::Tiny> 0.004

L<Module::Path::More> 0.33

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

=item * Bencher::Scenario::ModuleInstalledTiny::module_installed::Test

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.30.0 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 19.04 >>, OS kernel: I<< Linux version 5.0.0-37-generic >>.

Benchmark with default options (C<< bencher -m ModuleInstalledTiny::module_installed >>):

 #table1#
 +-------------------------------------------+----------------------------------------------------------------+-----------+-----------+------------+---------+---------+
 | participant                               | dataset                                                        | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +-------------------------------------------+----------------------------------------------------------------+-----------+-----------+------------+---------+---------+
 | Module::Load::Conditional::check_install  | strict                                                         |      2400 |  420      |          1 | 6.9e-07 |      20 |
 | Module::Load::Conditional::check_install  | Bencher::Scenario::ModuleInstalledTiny::module_installed::Test |     28000 |   36      |         12 | 3.1e-07 |      21 |
 | Module::Path::More::module_path           | strict                                                         |     44000 |   23      |         18 | 5.3e-08 |      20 |
 | Module::Path::More::module_path           | Bencher::Scenario::ModuleInstalledTiny::module_installed::Test |     44000 |   23      |         18 | 1.4e-07 |      20 |
 | require                                   | Bencher::Scenario::ModuleInstalledTiny::module_installed::Test |     50000 |   20      |         21 | 2.7e-08 |      20 |
 | Module::Installed::Tiny::module_installed | Bencher::Scenario::ModuleInstalledTiny::module_installed::Test |     62300 |   16      |         26 | 6.7e-09 |      20 |
 | Module::Installed::Tiny::module_installed | strict                                                         |   1410000 |    0.708  |        590 | 2.1e-10 |      20 |
 | require                                   | strict                                                         |   3736000 |    0.2677 |       1561 | 1.2e-11 |      20 |
 +-------------------------------------------+----------------------------------------------------------------+-----------+-----------+------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m ModuleInstalledTiny::module_installed --module-startup >>):

 #table2#
 +---------------------------+-----------+------------------------+------------+---------+---------+
 | participant               | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +---------------------------+-----------+------------------------+------------+---------+---------+
 | Module::Load::Conditional |      40.1 |                   33.7 |       1    | 2.4e-05 |      20 |
 | Module::Path::More        |      10   |                    3.6 |       3.8  | 1.8e-05 |      20 |
 | Module::Installed::Tiny   |      10.2 |                    3.8 |       3.92 | 8.7e-06 |      23 |
 | perl -e1 (baseline)       |       6.4 |                    0   |       6.3  | 1.4e-05 |      21 |
 +---------------------------+-----------+------------------------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-ModuleInstalledTiny>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-ModuleInstalledTiny>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-ModuleInstalledTiny>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2017, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
