package Bencher::Scenario::PERLANCARModuleList::ReturnPathOption;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.02'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark the benefit of return_path option',

    description => <<'_',

When we want to get the paths of all installed modules, PERLANCAR::Module::List
can do this in one step using the `return_path` option.

With Module::List, we need to get the paths in an extra step.

_
    participants => [
        {
            module => 'PERLANCAR::Module::List',
            code_template => q!
                PERLANCAR::Module::List::list_modules(<prefix>, {list_modules=>1, recurse=><recurse>, return_path=>1});
            !,
        },
        {
            module => 'Module::List',
            code_template => q!
                require Module::Path;
                my $mods = Module::List::list_modules(<prefix>, {list_modules=>1, recurse=><recurse>});
                for my $mod (keys %$mods) {
                    $mods->{$mod} = Module::Path::module_path($mod);
                }
                $mods;
            !,
        },
    ],

    datasets => [
        {name=>"IPC", args=>{prefix=>"IPC::", recurse=>0}},
        {name=>"Module", args=>{prefix=>"Module::", recurse=>1}},
        {name=>"all", args=>{prefix=>"", recurse=>1}, include_by_default=>0},
    ],
};

1;
# ABSTRACT: Benchmark the benefit of return_path option

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::PERLANCARModuleList::ReturnPathOption - Benchmark the benefit of return_path option

=head1 VERSION

This document describes version 0.02 of Bencher::Scenario::PERLANCARModuleList::ReturnPathOption (from Perl distribution Bencher-Scenarios-PERLANCARModuleList), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m PERLANCARModuleList::ReturnPathOption

To run module startup overhead benchmark:

 % bencher --module-startup -m PERLANCARModuleList::ReturnPathOption

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

When we want to get the paths of all installed modules, PERLANCAR::Module::List
can do this in one step using the C<return_path> option.

With Module::List, we need to get the paths in an extra step.


Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<PERLANCAR::Module::List> 0.003005

L<Module::List> 0.003

=head1 BENCHMARK PARTICIPANTS

=over

=item * PERLANCAR::Module::List (perl_code)

Code template:

 
                 PERLANCAR::Module::List::list_modules(<prefix>, {list_modules=>1, recurse=><recurse>, return_path=>1});
             



=item * Module::List (perl_code)

Code template:

 
                 require Module::Path;
                 my $mods = Module::List::list_modules(<prefix>, {list_modules=>1, recurse=><recurse>});
                 for my $mod (keys %$mods) {
                     $mods->{$mod} = Module::Path::module_path($mod);
                 }
                 $mods;
             



=back

=head1 BENCHMARK DATASETS

=over

=item * IPC

=item * Module

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m PERLANCARModuleList::ReturnPathOption >>):

 #table1#
 +-------------------------+---------+-----------+-----------+------------+---------+---------+
 | participant             | dataset | rate (/s) | time (ms) | vs_slowest |  errors | samples |
 +-------------------------+---------+-----------+-----------+------------+---------+---------+
 | Module::List            | Module  |       160 |      6.1  |        1   | 5.4e-05 |      21 |
 | PERLANCAR::Module::List | Module  |       300 |      3.3  |        1.9 | 6.8e-06 |      21 |
 | Module::List            | IPC     |      1600 |      0.63 |        9.6 | 4.1e-06 |      20 |
 | PERLANCAR::Module::List | IPC     |      3100 |      0.33 |       19   |   2e-06 |      20 |
 +-------------------------+---------+-----------+-----------+------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m PERLANCARModuleList::ReturnPathOption --module-startup >>):

 #table2#
 +-------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+-----------+---------+
 | participant             | proc_private_dirty_size (MB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors   | samples |
 +-------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+-----------+---------+
 | Module::List            | 0.82                         | 4.1                | 16             |      27   |                   21.3 |        1   |   0.00012 |      20 |
 | PERLANCAR::Module::List | 3                            | 6.4                | 24             |       6.4 |                    0.7 |        4.2 | 1.9e-05   |      20 |
 | perl -e1 (baseline)     | 0.88                         | 4.2                | 16             |       5.7 |                    0   |        4.8 | 2.2e-05   |      20 |
 +-------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+-----------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-PERLANCARModuleList>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-PERLANCARModuleList>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-PERLANCARModuleList>

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
