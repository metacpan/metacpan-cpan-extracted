package Bencher::Scenario::MonkeyPatchAction::patch_package;

our $DATE = '2018-10-08'; # DATE
our $VERSION = '0.001'; # VERSION

use strict;
use warnings;

sub _delete1 {}
sub _replace1 {}
sub _wrap1 {}

our $scenario = {
    summary => 'Benchmark patch_package()',
    participants => [
        #{name=>'add'                     , fcall_template=>'Monkey::Patch::Action::patch_package("Bencher::Scenario::MonkeyPatchAction::patch_package", "_add1"    , "add", sub{})'},
        {name=>'add_or_replace (add)'    , fcall_template=>'Monkey::Patch::Action::patch_package("Bencher::Scenario::MonkeyPatchAction::patch_package", "_add1"    , "add_or_replace", sub{})'},
        {name=>'add_or_replace (replace)', fcall_template=>'Monkey::Patch::Action::patch_package("Bencher::Scenario::MonkeyPatchAction::patch_package", "_replace1", "add_or_replace", sub{})'},
        {name=>'delete'                  , fcall_template=>'Monkey::Patch::Action::patch_package("Bencher::Scenario::MonkeyPatchAction::patch_package", "_delete1" , "delete")'},
        {name=>'replace'                 , fcall_template=>'Monkey::Patch::Action::patch_package("Bencher::Scenario::MonkeyPatchAction::patch_package", "_replace1", "replace", sub{})'},
        {name=>'wrap'                    , fcall_template=>'Monkey::Patch::Action::patch_package("Bencher::Scenario::MonkeyPatchAction::patch_package", "_wrap1"   , "wrap", sub{})'},
    ],
};

1;
# ABSTRACT: Benchmark patch_package()

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::MonkeyPatchAction::patch_package - Benchmark patch_package()

=head1 VERSION

This document describes version 0.001 of Bencher::Scenario::MonkeyPatchAction::patch_package (from Perl distribution Bencher-Scenarios-MonkeyPatchAction), released on 2018-10-08.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m MonkeyPatchAction::patch_package

To run module startup overhead benchmark:

 % bencher --module-startup -m MonkeyPatchAction::patch_package

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Monkey::Patch::Action> 0.061

=head1 BENCHMARK PARTICIPANTS

=over

=item * add_or_replace (add) (perl_code)

Function call template:

 Monkey::Patch::Action::patch_package("Bencher::Scenario::MonkeyPatchAction::patch_package", "_add1"    , "add_or_replace", sub{})



=item * add_or_replace (replace) (perl_code)

Function call template:

 Monkey::Patch::Action::patch_package("Bencher::Scenario::MonkeyPatchAction::patch_package", "_replace1", "add_or_replace", sub{})



=item * delete (perl_code)

Function call template:

 Monkey::Patch::Action::patch_package("Bencher::Scenario::MonkeyPatchAction::patch_package", "_delete1" , "delete")



=item * replace (perl_code)

Function call template:

 Monkey::Patch::Action::patch_package("Bencher::Scenario::MonkeyPatchAction::patch_package", "_replace1", "replace", sub{})



=item * wrap (perl_code)

Function call template:

 Monkey::Patch::Action::patch_package("Bencher::Scenario::MonkeyPatchAction::patch_package", "_wrap1"   , "wrap", sub{})



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.26.1 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 18.3 >>, OS kernel: I<< Linux version 4.10.0-38-generic >>.

Benchmark with default options (C<< bencher -m MonkeyPatchAction::patch_package >>):

 #table1#
 +--------------------------+-----------+-----------+------------+---------+---------+
 | participant              | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +--------------------------+-----------+-----------+------------+---------+---------+
 | delete                   |    110000 |    9.5    |     1      | 1.3e-08 |      20 |
 | wrap                     |    110000 |    9.1    |     1      | 1.5e-08 |      26 |
 | replace                  |    135000 |    7.4    |     1.29   | 3.3e-09 |      20 |
 | add_or_replace (replace) |    138000 |    7.26   |     1.31   |   3e-09 |      24 |
 | add_or_replace (add)     |    141700 |    7.0571 |     1.3479 | 1.1e-11 |      20 |
 +--------------------------+-----------+-----------+------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m MonkeyPatchAction::patch_package --module-startup >>):

 #table2#
 +-----------------------+-----------+------------------------+------------+---------+---------+
 | participant           | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +-----------------------+-----------+------------------------+------------+---------+---------+
 | Monkey::Patch::Action |      11   |                    5.6 |        1   | 5.3e-05 |      20 |
 | perl -e1 (baseline)   |       5.4 |                    0   |        2.1 | 2.5e-05 |      20 |
 +-----------------------+-----------+------------------------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-MonkeyPatchAction>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-MonkeyPatchAction>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-MonkeyPatchAction>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
