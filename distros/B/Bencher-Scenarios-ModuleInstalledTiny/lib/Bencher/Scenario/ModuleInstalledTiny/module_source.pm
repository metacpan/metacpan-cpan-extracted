package Bencher::Scenario::ModuleInstalledTiny::module_source;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-01-09'; # DATE
our $DIST = 'Bencher-Scenarios-ModuleInstalledTiny'; # DIST
our $VERSION = '0.003'; # VERSION

use strict;
use warnings;

use File::Path qw(make_path);
use File::Slurper qw(write_text);
use File::Temp qw(tempdir);

my $dir = tempdir(CLEANUP => !$ENV{DEBUG});
@INC = ($dir, @INC);
make_path ("$dir/Bencher/Scenario/ModuleInstalledTiny/module_source");
write_text("$dir/Bencher/Scenario/ModuleInstalledTiny/module_source/Test.pm", "1;");

our $scenario = {
    summary => "Benchmark Module::Installed::Tiny's module_source()",
    participants => [
        # cached version doesn't make any sense for require() because it only
        # checks %INC

        #{
        #    name => 'Module::Installed::Tiny, cached',
        #    module => 'Module::Installed::Tiny',
        #    code_template => 'BEGIN {<begin_code:raw>} Module::Installed::Tiny::module_source(<module>)',
        #    tags => ['cached'],
        #},
        {
            name => 'Module::Installed::Tiny, uncached',
            module => 'Module::Installed::Tiny',
            code_template => 'BEGIN {<begin_code:raw>} delete $INC{<module_pm>}; Module::Installed::Tiny::module_source(<module>)',
            tags => ['uncached'],
        },

        #{
        #    name => 'require, cached',
        #    code_template => 'BEGIN {<begin_code:raw>} require <module_pm>;',
        #    tags => ['cached'],
        #},
        {
            name => 'require, cached',
            code_template => 'BEGIN {<begin_code:raw>} delete $INC{<module_pm>}; require <module_pm>;',
            tags => ['uncached'],
        },
    ],
    datasets => [
        {args=>{module=>'strict', module_pm=>'strict.pm'}, exclude_participant_tags=>['uncached']},
        {args=>{
            module=>'Bencher::Scenario::ModuleInstalledTiny::module_source::Test',
            module_pm=>'Bencher/Scenario/ModuleInstalledTiny/module_source/Test.pm',
            begin_code => "\@INC = ('$dir', \@INC)",
        }, exclude_participant_tags=>['cached']},
    ],
};

1;
# ABSTRACT: Benchmark Module::Installed::Tiny's module_source()

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::ModuleInstalledTiny::module_source - Benchmark Module::Installed::Tiny's module_source()

=head1 VERSION

This document describes version 0.003 of Bencher::Scenario::ModuleInstalledTiny::module_source (from Perl distribution Bencher-Scenarios-ModuleInstalledTiny), released on 2020-01-09.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m ModuleInstalledTiny::module_source

To run module startup overhead benchmark:

 % bencher --module-startup -m ModuleInstalledTiny::module_source

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Module::Installed::Tiny> 0.004

=head1 BENCHMARK PARTICIPANTS

=over

=item * Module::Installed::Tiny, uncached (perl_code) [uncached]

Code template:

 BEGIN {<begin_code:raw>} delete $INC{<module_pm>}; Module::Installed::Tiny::module_source(<module>)



=item * require, cached (perl_code) [uncached]

Code template:

 BEGIN {<begin_code:raw>} delete $INC{<module_pm>}; require <module_pm>;



=back

=head1 BENCHMARK DATASETS

=over

=item * {module=>"strict",module_pm=>"strict.pm"}

=item * {module=>"Bencher::Scenario::ModuleInstalledTiny::module_source::Test",module_pm=>"Bencher/Scenario/ModuleInstalledTiny/module_source/Test.pm"}

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.30.0 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 19.04 >>, OS kernel: I<< Linux version 5.0.0-37-generic >>.

Benchmark with default options (C<< bencher -m ModuleInstalledTiny::module_source >>):

 #table1#
 +-----------------------------------+-----------+-----------+------------+---------+---------+
 | participant                       | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +-----------------------------------+-----------+-----------+------------+---------+---------+
 | Module::Installed::Tiny, uncached |     51000 |        20 |        1   | 3.3e-08 |      21 |
 | require, cached                   |     61000 |        16 |        1.2 | 2.7e-08 |      20 |
 +-----------------------------------+-----------+-----------+------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m ModuleInstalledTiny::module_source --module-startup >>):

 #table2#
 +-------------------------+-----------+------------------------+------------+---------+---------+
 | participant             | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +-------------------------+-----------+------------------------+------------+---------+---------+
 | Module::Installed::Tiny |      10.3 |                    3.9 |        1   |   1e-05 |      20 |
 | perl -e1 (baseline)     |       6.4 |                    0   |        1.6 | 1.6e-05 |      20 |
 +-------------------------+-----------+------------------------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 BENCHMARK NOTES

`module_source()` is slower than `require()` by about 15%.

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
