package Bencher::Scenario::Perl::Hash;

our $DATE = '2021-07-03'; # DATE
our $VERSION = '0.051'; # VERSION

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

This document describes version 0.051 of Bencher::Scenario::Perl::Hash (from Perl distribution Bencher-Scenarios-Perl), released on 2021-07-03.

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

A 100-key ("001".."100") hash.

=item * h1k

A 1k-key ("0001".."1000") hash.

=back

=over

=item * h100

A 100-key ("001".."100") hash.

=item * h1k

A 1k-key ("0001".."1000") hash.

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.30.2 >>, CPU: I<< Intel(R) Core(TM) i7-4770 CPU @ 3.40GHz (4 cores) >>, OS: I<< GNU/Linux LinuxMint version 19 >>, OS kernel: I<< Linux version 5.3.0-68-generic >>.

Benchmark with default options (C<< bencher -m Perl::Hash >>):

 #table1#
 +-------------+---------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant | dataset | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------+---------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | insert      | h1k     |   5950    | 168       |                 0.00% |              2912.22% | 7.4e-08 |     167 |
 | delete      | h1k     |   6450    | 155       |                 8.40% |              2678.69% | 1.5e-07 |      38 |
 | access      | h1k     |  17615.61 |  56.76784 |               196.29% |               916.65% | 5.5e-12 |      20 |
 | delete      | h100    |  78500    |  12.7     |              1221.03% |               128.02% | 1.3e-08 |      89 |
 | insert      | h100    |  83300    |  12       |              1300.55% |               115.07% |   1e-08 |      20 |
 | access      | h100    | 179090    |   5.5838  |              2912.22% |                 0.00% | 4.7e-12 |      20 |
 +-------------+---------+-----------+-----------+-----------------------+-----------------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

Run on: perl: I<< v5.30.2 >>, CPU: I<< Intel(R) Core(TM) i7-4770 CPU @ 3.40GHz (4 cores) >>, OS: I<< GNU/Linux LinuxMint version 19 >>, OS kernel: I<< Linux version 5.3.0-68-generic >>.

Benchmark with C<< bencher -m Perl::Hash --multiperl >>:

 #table1#
 +-------------+---------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant | dataset | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------+---------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | insert      | h1k     |      6260 |    160    |                 0.00% |              3254.25% | 1.4e-07 |     179 |
 | delete      | h1k     |      6980 |    143    |                11.56% |              2906.68% | 1.4e-07 |      46 |
 | access      | h1k     |     21000 |     47.5  |               236.38% |               897.16% | 1.3e-08 |      20 |
 | insert      | h100    |     60500 |     16.5  |               867.26% |               246.78% | 1.4e-08 |      40 |
 | delete      | h100    |     81900 |     12.2  |              1208.90% |               156.27% | 1.2e-08 |      24 |
 | access      | h100    |    210000 |      4.77 |              3254.25% |                 0.00% | 1.7e-09 |      20 |
 +-------------+---------+-----------+-----------+-----------------------+-----------------------+---------+---------+


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

This software is copyright (c) 2021, 2019, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
