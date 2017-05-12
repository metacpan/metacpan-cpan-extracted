package Bencher::Scenario::Allocations;

our $DATE = '2016-06-26'; # DATE
our $VERSION = '0.03'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark allocations',

    descriptions => <<'_',

This scenario tries to give a picture on how long it takes to allocate arrays
and hashes of various size take.

_
    participants => [
        {name=>'1k-array0'  , summary => 'Allocating empty array 1000 times'      , code_template=>'my $val; for (1..1000) { $val = [] }'},
        {name=>'1k-hash0'   , summary => 'Allocating empty hash 1000 times'       , code_template=>'my $val; for (1..1000) { $val = {} }'},
        {name=>'1k-array1'  , summary => 'Allocating 1-element array 1000 times'  , code_template=>'my $val; for (1..1000) { $val = [1] }'},
        {name=>'1k-hash1'   , summary => 'Allocating 1-key hash 1000 times'       , code_template=>'my $val; for (1..1000) { $val = {a=>1} }'},
        {name=>'1k-array5'  , summary => 'Allocating 5-element array 1000 times'  , code_template=>'my $val; for (1..1000) { $val = [1..5] }'},
        {name=>'1k-hash5'   , summary => 'Allocating 5-key hash 1000 times'       , code_template=>'my $val; for (1..1000) { $val = {a=>1, b=>2, c=>3, d=>4, e=>5} }'},
        {name=>'1k-array10' , summary => 'Allocating 10-element array 1000 times' , code_template=>'my $val; for (1..1000) { $val = [1..10] }'},
        {name=>'1k-hash10'  , summary => 'Allocating 10-key hash 1000 times'      , code_template=>'my $val; for (1..1000) { $val = {1..20} }'},
        {name=>'1k-array100', summary => 'Allocating 100-element array 1000 times', code_template=>'my $val; for (1..1000) { $val = [1..100] }'},
        {name=>'1k-hash100' , summary => 'Allocating 100-key hash 1000 times'     , code_template=>'my $val; for (1..1000) { $val = {1..200} }'},
    ],
};

1;
# ABSTRACT: Benchmark allocations

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::Allocations - Benchmark allocations

=head1 VERSION

This document describes version 0.03 of Bencher::Scenario::Allocations (from Perl distribution Bencher-Scenario-Allocations), released on 2016-06-26.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m Allocations

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 BENCHMARK PARTICIPANTS

=over

=item * 1k-array0 (perl_code)

Allocating empty array 1000 times.

Code template:

 my $val; for (1..1000) { $val = [] }



=item * 1k-hash0 (perl_code)

Allocating empty hash 1000 times.

Code template:

 my $val; for (1..1000) { $val = {} }



=item * 1k-array1 (perl_code)

Allocating 1-element array 1000 times.

Code template:

 my $val; for (1..1000) { $val = [1] }



=item * 1k-hash1 (perl_code)

Allocating 1-key hash 1000 times.

Code template:

 my $val; for (1..1000) { $val = {a=>1} }



=item * 1k-array5 (perl_code)

Allocating 5-element array 1000 times.

Code template:

 my $val; for (1..1000) { $val = [1..5] }



=item * 1k-hash5 (perl_code)

Allocating 5-key hash 1000 times.

Code template:

 my $val; for (1..1000) { $val = {a=>1, b=>2, c=>3, d=>4, e=>5} }



=item * 1k-array10 (perl_code)

Allocating 10-element array 1000 times.

Code template:

 my $val; for (1..1000) { $val = [1..10] }



=item * 1k-hash10 (perl_code)

Allocating 10-key hash 1000 times.

Code template:

 my $val; for (1..1000) { $val = {1..20} }



=item * 1k-array100 (perl_code)

Allocating 100-element array 1000 times.

Code template:

 my $val; for (1..1000) { $val = [1..100] }



=item * 1k-hash100 (perl_code)

Allocating 100-key hash 1000 times.

Code template:

 my $val; for (1..1000) { $val = {1..200} }



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.22.2 >>, CPU: I<< Intel(R) Core(TM) i7-4770 CPU @ 3.40GHz (4 cores) >>, OS: I<< GNU/Linux Debian version 8.0 >>, OS kernel: I<< Linux version 3.16.0-4-amd64 >>.

Benchmark with default options (C<< bencher -m Allocations >>):

 +-------------+-----------+-----------+------------+---------+---------+
 | participant | rate (/s) | time (ms) | vs_slowest |  errors | samples |
 +-------------+-----------+-----------+------------+---------+---------+
 | 1k-hash100  |    150    | 6.7       |     1      | 2.1e-05 |      20 |
 | 1k-array100 |    672    | 1.49      |     4.53   | 2.3e-07 |      26 |
 | 1k-hash10   |   1320    | 0.76      |     8.86   | 2.1e-07 |      20 |
 | 1k-hash5    |   2260    | 0.442     |    15.2    | 5.3e-08 |      20 |
 | 1k-array10  |   3534.38 | 0.282935  |    23.8105 | 4.5e-11 |      20 |
 | 1k-array5   |   4750    | 0.211     |    32      | 5.1e-08 |      22 |
 | 1k-hash1    |   4856.11 | 0.205926  |    32.7148 | 3.5e-11 |      20 |
 | 1k-array1   |   6800    | 0.15      |    46      | 3.4e-07 |      31 |
 | 1k-hash0    |   9957.38 | 0.100428  |    67.0812 |   0     |      20 |
 | 1k-array0   |  11305.6  | 0.0884515 |    76.1641 |   0     |      20 |
 +-------------+-----------+-----------+------------+---------+---------+

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-Allocations>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-Allocations>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-Allocations>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
