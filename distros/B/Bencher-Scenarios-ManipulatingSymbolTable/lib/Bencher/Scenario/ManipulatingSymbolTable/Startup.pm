package Bencher::Scenario::ManipulatingSymbolTable::Startup;

our $DATE = '2019-01-06'; # DATE
our $VERSION = '0.001'; # VERSION

use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark startup of modules',
    module_startup => 1,
    participants => [
        {module => 'Package::MoreUtil'},
        {module => 'Package::Util::Lite'},
        {module => 'Package::Stash'},
        {module => 'Package::Stash::PP'},
        {module => 'Package::Stash::XS'},
    ],
};

1;
# ABSTRACT: Benchmark startup of modules

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::ManipulatingSymbolTable::Startup - Benchmark startup of modules

=head1 VERSION

This document describes version 0.001 of Bencher::Scenario::ManipulatingSymbolTable::Startup (from Perl distribution Bencher-Scenarios-ManipulatingSymbolTable), released on 2019-01-06.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m ManipulatingSymbolTable::Startup

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Package::MoreUtil> 0.591

L<Package::Util::Lite> 0.001

L<Package::Stash> 0.37

L<Package::Stash::PP> 0.37

L<Package::Stash::XS> 0.28

=head1 BENCHMARK PARTICIPANTS

=over

=item * Package::MoreUtil (perl_code)

L<Package::MoreUtil>



=item * Package::Util::Lite (perl_code)

L<Package::Util::Lite>



=item * Package::Stash (perl_code)

L<Package::Stash>



=item * Package::Stash::PP (perl_code)

L<Package::Stash::PP>



=item * Package::Stash::XS (perl_code)

L<Package::Stash::XS>



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.26.1 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 18.3 >>, OS kernel: I<< Linux version 4.10.0-38-generic >>.

Benchmark with default options (C<< bencher -m ManipulatingSymbolTable::Startup >>):

 #table1#
 +---------------------+-----------+------------------------+------------+---------+---------+
 | participant         | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +---------------------+-----------+------------------------+------------+---------+---------+
 | Package::Stash::PP  |      15   |                   10   |        1   | 2.7e-05 |      20 |
 | Package::Stash      |      14   |                    9   |        1.1 | 1.5e-05 |      21 |
 | Package::MoreUtil   |       7.7 |                    2.7 |        1.9 | 2.7e-05 |      21 |
 | Package::Util::Lite |       7.5 |                    2.5 |        2   | 2.9e-05 |      21 |
 | Package::Stash::XS  |       7.3 |                    2.3 |        2   | 3.8e-05 |      20 |
 | perl -e1 (baseline) |       5   |                    0   |        2.9 | 2.1e-05 |      20 |
 +---------------------+-----------+------------------------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-ManipulatingSymbolTable>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-ManipulatingSymbolTable>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-ManipulatingSymbolTable>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
