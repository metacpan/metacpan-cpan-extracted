package Bencher::Scenario::ArrayVsHashBuilding;

our $DATE = '2016-09-03'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark building array vs hash',
    participants => [
        {
            name=>'array',
            code_template=>'state $elems=<elems>; my $ary = []; for my $elem (@$elems) { push @$ary, $elems }; $ary',
        },
        {
            name=>'hash',
            code_template=>'state $elems=<elems>; my $hash = {}; for my $elem (@$elems) { $hash->{$elem} = 1 }; $hash',
        },
    ],
    datasets => [
        {name=>'elems=1'    , args=>{elems=>[1]}},
        {name=>'elems=10'   , args=>{elems=>[1..10]}},
        {name=>'elems=100'  , args=>{elems=>[1..100]}},
        {name=>'elems=1000' , args=>{elems=>[1..1000]}},
        {name=>'elems=10000', args=>{elems=>[1..10000]}},
    ],
};

1;
# ABSTRACT: Benchmark building array vs hash

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::ArrayVsHashBuilding - Benchmark building array vs hash

=head1 VERSION

This document describes version 0.001 of Bencher::Scenario::ArrayVsHashBuilding (from Perl distribution Bencher-Scenario-ArrayVsHashBuilding), released on 2016-09-03.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m ArrayVsHashBuilding

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 BENCHMARK PARTICIPANTS

=over

=item * array (perl_code)

Code template:

 state $elems=<elems>; my $ary = []; for my $elem (@$elems) { push @$ary, $elems }; $ary



=item * hash (perl_code)

Code template:

 state $elems=<elems>; my $hash = {}; for my $elem (@$elems) { $hash->{$elem} = 1 }; $hash



=back

=head1 BENCHMARK DATASETS

=over

=item * elems=1

=item * elems=10

=item * elems=100

=item * elems=1000

=item * elems=10000

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.22.1 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m ArrayVsHashBuilding >>):

 #table1#
 +-------------+-------------+-----------+-------------+------------+---------+---------+
 | participant | dataset     | rate (/s) |   time (ms) | vs_slowest |  errors | samples |
 +-------------+-------------+-----------+-------------+------------+---------+---------+
 | hash        | elems=10000 |       504 | 1.98        |       1    | 6.1e-07 |      22 |
 | array       | elems=10000 |      1310 | 0.764       |       2.6  | 2.1e-07 |      20 |
 | hash        | elems=1000  |      5800 | 0.17        |      12    | 2.1e-07 |      20 |
 | array       | elems=1000  |     12700 | 0.0786      |      25.2  | 2.6e-08 |      21 |
 | hash        | elems=100   |     69900 | 0.0143      |     139    | 5.6e-09 |      28 |
 | array       | elems=100   |    110000 | 0.009       |     220    |   1e-08 |      20 |
 | hash        | elems=10    |    636229 | 0.00157176  |    1262.73 |   0     |      22 |
 | array       | elems=10    |    744000 | 0.00134     |    1480    | 4.2e-10 |      20 |
 | hash        | elems=1     |   2510000 | 0.000398    |    4990    | 5.1e-11 |      20 |
 | array       | elems=1     |   2872660 | 0.000348109 |    5701.41 |   0     |      28 |
 +-------------+-------------+-----------+-------------+------------+---------+---------+

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-ArrayVsHashBuilding>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-ArrayVsHashBuilding>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-ArrayVsHashBuilding>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Bencher::Scenario::HashBuilding>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
