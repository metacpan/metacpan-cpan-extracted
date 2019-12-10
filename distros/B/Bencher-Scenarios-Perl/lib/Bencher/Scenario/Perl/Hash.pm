package Bencher::Scenario::Perl::Hash;

our $DATE = '2019-10-20'; # DATE
our $VERSION = '0.050'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    precision => 0.001,
    participants => [
        {name => 'access', code_template => 'no warnings "void"; state $hash = <hash>; for (<firstkey>..<lastkey>) { $hash->{$_} }'},
        {name => 'delete', code_template => 'my $hash = <hash>; for (<firstkey>..<lastkey>) { delete $hash->{$_} }'},
        {name => 'insert', code_template => 'my $hash = {}; for (<firstkey>..<lastkey>) { $hash->{$_} = 0 }'},
    ],
    datasets => [
        {
            name => 'h100',
            summary => 'A 100-key ("001".."100") hash',
            args => {firstkey => "001", lastkey => "100", hash=>{ map {$_=>0} "001".."100" }},
        },
        {
            name => 'h1k',
            summary => 'A 1k-key ("0001".."1000") hash',
            args => {firstkey => "0001", lastkey => "1000", hash=>{ map {$_=>0} "0001".."1000" }},
        },
    ],
};

1;
# ABSTRACT:

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::Perl::Hash

=head1 VERSION

This document describes version 0.050 of Bencher::Scenario::Perl::Hash (from Perl distribution Bencher-Scenarios-Perl), released on 2019-10-20.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m Perl::Hash

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARK PARTICIPANTS

=over

=item * access (perl_code)

Code template:

 no warnings "void"; state $hash = <hash>; for (<firstkey>..<lastkey>) { $hash->{$_} }



=item * delete (perl_code)

Code template:

 my $hash = <hash>; for (<firstkey>..<lastkey>) { delete $hash->{$_} }



=item * insert (perl_code)

Code template:

 my $hash = {}; for (<firstkey>..<lastkey>) { $hash->{$_} = 0 }



=back

=over

=item * access (perl_code)

Code template:

 no warnings "void"; state $hash = <hash>; for (<firstkey>..<lastkey>) { $hash->{$_} }



=item * delete (perl_code)

Code template:

 my $hash = <hash>; for (<firstkey>..<lastkey>) { delete $hash->{$_} }



=item * insert (perl_code)

Code template:

 my $hash = {}; for (<firstkey>..<lastkey>) { $hash->{$_} = 0 }



=back

=head1 BENCHMARK DATASETS

=over

=item * h100

A 100-key ("001".."100") hash

=item * h1k

A 1k-key ("0001".."1000") hash

=back

=over

=item * h100

A 100-key ("001".."100") hash

=item * h1k

A 1k-key ("0001".."1000") hash

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) i7-4770 CPU @ 3.40GHz (4 cores) >>, OS: I<< GNU/Linux LinuxMint version 18.2 >>, OS kernel: I<< Linux version 4.8.0-53-generic >>.

Benchmark with default options (C<< bencher -m Perl::Hash >>):

 #table1#
 +-------------+---------+-----------+-----------+------------+---------+---------+
 | participant | dataset | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +-------------+---------+-----------+-----------+------------+---------+---------+
 | insert      | h1k     |    5530   |  181      |    1       | 1.5e-07 |     171 |
 | delete      | h1k     |    6010   |  166      |    1.09    | 1.7e-07 |      33 |
 | access      | h1k     |   13839.3 |   72.2581 |    2.50172 | 2.1e-11 |      29 |
 | delete      | h100    |   72800   |   13.7    |   13.2     | 5.6e-09 |      28 |
 | insert      | h100    |   73500   |   13.6    |   13.3     | 6.5e-09 |      21 |
 | access      | h100    |  144000   |    6.94   |   26.1     | 3.3e-09 |      20 |
 +-------------+---------+-----------+-----------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) i7-4770 CPU @ 3.40GHz (4 cores) >>, OS: I<< GNU/Linux LinuxMint version 18.2 >>, OS kernel: I<< Linux version 4.8.0-53-generic >>.

Benchmark with C<< bencher -m Perl::Hash --multiperl >>:

 #table1#
 +-------------+---------+-------------------+-----------+-----------+------------+---------+---------+---------+--------+
 | participant | dataset | perl              | rate (/s) | time (μs) | vs_slowest |  errors | samples | ds_tags | p_tags |
 +-------------+---------+-------------------+-----------+-----------+------------+---------+---------+---------+--------+
 | insert      | h1k     | perl-5.22.2       |      5530 | 181       |     1      | 1.8e-07 |      28 |         |        |
 | insert      | h1k     | perl-5.24.0       |      5610 | 178       |     1.01   | 1.6e-07 |      20 |         |        |
 | insert      | h1k     | perl-5.10.1       |      5710 | 175       |     1.03   | 1.5e-07 |      39 |         |        |
 | delete      | h1k     | perl-5.22.2       |      6090 | 164       |     1.1    | 1.6e-07 |      34 |         |        |
 | delete      | h1k     | perl-5.24.0       |      6280 | 159       |     1.14   |   5e-08 |      23 |         |        |
 | delete      | h1k     | perl-5.10.1       |      6500 | 154       |     1.18   | 1.5e-07 |      39 |         |        |
 | insert      | h1k     | stableperl-5.22.0 |      6540 | 153       |     1.18   | 8.2e-08 |     136 |         |        |
 | insert      | h1k     | cperl-5.22.1      |      6580 | 152       |     1.19   |   7e-08 |     105 |         |        |
 | delete      | h1k     | stableperl-5.22.0 |      7380 | 136       |     1.33   | 1.3e-07 |      50 |         |        |
 | delete      | h1k     | cperl-5.22.1      |      7400 | 135       |     1.34   | 4.9e-08 |      24 |         |        |
 | access      | h1k     | perl-5.24.0       |     15100 |  66.2     |     2.73   | 2.2e-08 |      30 |         |        |
 | access      | h1k     | perl-5.10.1       |     15200 |  65.9     |     2.74   | 5.3e-08 |      46 |         |        |
 | access      | h1k     | perl-5.22.2       |     15300 |  65.6     |     2.76   | 2.3e-08 |      26 |         |        |
 | access      | h1k     | stableperl-5.22.0 |     17900 |  55.8     |     3.24   | 2.7e-08 |      20 |         |        |
 | access      | h1k     | cperl-5.22.1      |     19100 |  52.2     |     3.46   | 2.5e-08 |      22 |         |        |
 | insert      | h100    | perl-5.22.2       |     61000 |  16.4     |    11      | 1.6e-08 |      54 |         |        |
 | insert      | h100    | perl-5.10.1       |     61100 |  16.4     |    11.1    | 6.1e-09 |      24 |         |        |
 | insert      | h100    | perl-5.24.0       |     67800 |  14.7     |    12.3    | 6.7e-09 |      20 |         |        |
 | delete      | h100    | perl-5.24.0       |     71500 |  14       |    12.9    | 1.4e-08 |      75 |         |        |
 | delete      | h100    | perl-5.22.2       |     73500 |  13.6     |    13.3    | 1.3e-08 |      44 |         |        |
 | delete      | h100    | perl-5.10.1       |     75000 |  13       |    14      | 1.3e-08 |      79 |         |        |
 | insert      | h100    | cperl-5.22.1      |     75600 |  13.2     |    13.7    | 6.1e-09 |      24 |         |        |
 | insert      | h100    | stableperl-5.22.0 |     79500 |  12.6     |    14.4    | 1.2e-08 |      36 |         |        |
 | delete      | h100    | cperl-5.22.1      |     86400 |  11.6     |    15.6    | 3.3e-09 |      20 |         |        |
 | delete      | h100    | stableperl-5.22.0 |     87000 |  11.5     |    15.7    | 1.1e-08 |      27 |         |        |
 | access      | h100    | perl-5.10.1       |    154060 |   6.491   |    27.862  | 3.4e-11 |      20 |         |        |
 | access      | h100    | perl-5.22.2       |    164569 |   6.07646 |    29.7627 |   0     |      20 |         |        |
 | access      | h100    | perl-5.24.0       |    168570 |   5.93227 |    30.4861 | 5.7e-12 |      21 |         |        |
 | access      | h100    | cperl-5.22.1      |    197000 |   5.08    |    35.6    | 1.4e-09 |      29 |         |        |
 | access      | h100    | stableperl-5.22.0 |    210600 |   4.7483  |    38.088  | 1.2e-11 |      20 |         |        |
 +-------------+---------+-------------------+-----------+-----------+------------+---------+---------+---------+--------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 BENCHMARK NOTES

cperl (tested version: 5.22.1) and stableperl (tested version: 5.22.0) is around
15-20% faster than perl 5.22.1.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-Perl>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-Perl>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-Perl>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
