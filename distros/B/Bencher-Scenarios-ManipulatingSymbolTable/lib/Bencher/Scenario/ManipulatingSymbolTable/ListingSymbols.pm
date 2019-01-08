package Bencher::Scenario::ManipulatingSymbolTable::ListingSymbols;

our $DATE = '2019-01-06'; # DATE
our $VERSION = '0.001'; # VERSION

use strict;

our $scenario = {
    summary => 'Benchmark listing symbols of a package',
    participants => [
        {name => 'PS:XS::list_all_symbols'  , module => 'Package::Stash::XS', code_template => 'Package::Stash::XS->new("strict")->list_all_symbols', result_is_list=>1},
        {name => 'PS:PP::list_all_symbols'  , module => 'Package::Stash::PP', code_template => 'Package::Stash::PP->new("strict")->list_all_symbols', result_is_list=>1},
        {name => 'PS:XS::get_all_symbols'   , module => 'Package::Stash::XS', code_template => 'Package::Stash::XS->new("strict")->get_all_symbols'},
        {name => 'PS:PP::get_all_symbols'   , module => 'Package::Stash::PP', code_template => 'Package::Stash::PP->new("strict")->get_all_symbols'},
        {fcall_template => 'Package::MoreUtil::list_package_contents("strict")', result_is_list=>1},
    ],
};

1;
# ABSTRACT: Benchmark listing symbols of a package

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::ManipulatingSymbolTable::ListingSymbols - Benchmark listing symbols of a package

=head1 VERSION

This document describes version 0.001 of Bencher::Scenario::ManipulatingSymbolTable::ListingSymbols (from Perl distribution Bencher-Scenarios-ManipulatingSymbolTable), released on 2019-01-06.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m ManipulatingSymbolTable::ListingSymbols

To run module startup overhead benchmark:

 % bencher --module-startup -m ManipulatingSymbolTable::ListingSymbols

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Package::Stash::XS> 0.28

L<Package::Stash::PP> 0.37

L<Package::MoreUtil> 0.591

=head1 BENCHMARK PARTICIPANTS

=over

=item * PS:XS::list_all_symbols (perl_code)

Code template:

 Package::Stash::XS->new("strict")->list_all_symbols



=item * PS:PP::list_all_symbols (perl_code)

Code template:

 Package::Stash::PP->new("strict")->list_all_symbols



=item * PS:XS::get_all_symbols (perl_code)

Code template:

 Package::Stash::XS->new("strict")->get_all_symbols



=item * PS:PP::get_all_symbols (perl_code)

Code template:

 Package::Stash::PP->new("strict")->get_all_symbols



=item * Package::MoreUtil::list_package_contents (perl_code)

Function call template:

 Package::MoreUtil::list_package_contents("strict")



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.26.1 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 18.3 >>, OS kernel: I<< Linux version 4.10.0-38-generic >>.

Benchmark with default options (C<< bencher -m ManipulatingSymbolTable::ListingSymbols >>):

 #table1#
 +------------------------------------------+-----------+-----------+------------+---------+---------+
 | participant                              | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +------------------------------------------+-----------+-----------+------------+---------+---------+
 | Package::MoreUtil::list_package_contents |     44600 |     22.4  |        1   | 5.4e-09 |      31 |
 | PS:PP::get_all_symbols                   |    170000 |      5.9  |        3.8 | 1.1e-08 |      27 |
 | PS:PP::list_all_symbols                  |    330000 |      3    |        7.5 | 6.5e-09 |      21 |
 | PS:XS::get_all_symbols                   |    420000 |      2.4  |        9.4 | 3.3e-09 |      20 |
 | PS:XS::list_all_symbols                  |    506000 |      1.97 |       11.3 | 7.5e-10 |      25 |
 +------------------------------------------+-----------+-----------+------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m ManipulatingSymbolTable::ListingSymbols --module-startup >>):

 #table2#
 +---------------------+-----------+------------------------+------------+---------+---------+
 | participant         | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +---------------------+-----------+------------------------+------------+---------+---------+
 | Package::Stash::PP  |      15   |                   10.1 |        1   | 4.2e-05 |      20 |
 | Package::MoreUtil   |       7.6 |                    2.7 |        1.9 | 1.6e-05 |      20 |
 | Package::Stash::XS  |       7.6 |                    2.7 |        1.9 | 2.7e-05 |      20 |
 | perl -e1 (baseline) |       4.9 |                    0   |        3   | 2.8e-05 |      21 |
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
