package Bencher::Scenario::ManipulatingSymbolTable::CheckingSymbolExists;

our $DATE = '2019-01-06'; # DATE
our $VERSION = '0.001'; # VERSION

our $scenario = {
    summary => 'Benchmark checking symbol exists',
    participants => [
        {name => 'PS:XS not exists', module => 'Package::Stash::XS', code_template => 'Package::Stash::XS->new("main")->has_symbol(q[$should_not_exist])'},
        {name => 'PS:PP not exists', module => 'Package::Stash::PP', code_template => 'Package::Stash::PP->new("main")->has_symbol(q[$should_not_exist])'},
        {name => 'PS:XS exists'    , module => 'Package::Stash::XS', code_template => 'Package::Stash::XS->new("main")->has_symbol(q[$should_exist])'},
        {name => 'PS:PP exists'    , module => 'Package::Stash::PP', code_template => 'Package::Stash::PP->new("main")->has_symbol(q[$should_exist])'},
    ],
};

package
    main;
our $should_exist = 0;

1;
# ABSTRACT: Benchmark checking symbol exists

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::ManipulatingSymbolTable::CheckingSymbolExists - Benchmark checking symbol exists

=head1 VERSION

This document describes version 0.001 of Bencher::Scenario::ManipulatingSymbolTable::CheckingSymbolExists (from Perl distribution Bencher-Scenarios-ManipulatingSymbolTable), released on 2019-01-06.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m ManipulatingSymbolTable::CheckingSymbolExists

To run module startup overhead benchmark:

 % bencher --module-startup -m ManipulatingSymbolTable::CheckingSymbolExists

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Package::Stash::XS> 0.28

L<Package::Stash::PP> 0.37

=head1 BENCHMARK PARTICIPANTS

=over

=item * PS:XS not exists (perl_code)

Code template:

 Package::Stash::XS->new("main")->has_symbol(q[$should_not_exist])



=item * PS:PP not exists (perl_code)

Code template:

 Package::Stash::PP->new("main")->has_symbol(q[$should_not_exist])



=item * PS:XS exists (perl_code)

Code template:

 Package::Stash::XS->new("main")->has_symbol(q[$should_exist])



=item * PS:PP exists (perl_code)

Code template:

 Package::Stash::PP->new("main")->has_symbol(q[$should_exist])



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.26.1 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 18.3 >>, OS kernel: I<< Linux version 4.10.0-38-generic >>.

Benchmark with default options (C<< bencher -m ManipulatingSymbolTable::CheckingSymbolExists >>):

 #table1#
 +------------------+-----------+-----------+------------+---------+---------+
 | participant      | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +------------------+-----------+-----------+------------+---------+---------+
 | PS:PP exists     |    177000 |     5.64  |      1     | 1.7e-09 |      20 |
 | PS:PP not exists |    210000 |     4.7   |      1.2   | 6.7e-09 |      20 |
 | PS:XS not exists |    602000 |     1.66  |      3.4   | 8.3e-10 |      20 |
 | PS:XS exists     |    634300 |     1.577 |      3.578 | 8.2e-11 |      20 |
 +------------------+-----------+-----------+------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m ManipulatingSymbolTable::CheckingSymbolExists --module-startup >>):

 #table2#
 +---------------------+-----------+------------------------+------------+---------+---------+
 | participant         | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +---------------------+-----------+------------------------+------------+---------+---------+
 | Package::Stash::PP  |      15   |                   10.2 |        1   | 2.7e-05 |      21 |
 | Package::Stash::XS  |       7.5 |                    2.7 |        2   | 2.2e-05 |      20 |
 | perl -e1 (baseline) |       4.8 |                    0   |        3.1 | 1.7e-05 |      20 |
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
