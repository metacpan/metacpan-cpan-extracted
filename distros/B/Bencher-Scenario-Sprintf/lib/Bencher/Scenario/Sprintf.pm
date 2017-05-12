package Bencher::Scenario::Sprintf;

our $DATE = '2016-01-10'; # DATE
our $VERSION = '0.01'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Measure sprintf() performance',
    participants => [
        {name=>'1k-concat2'  , tags=>['2elem' ], summary => 'Concatenating 2 strings together using "."'       , code_template=>'my $val; for (1..1000) { $val = <s1>.<s2> } $val'},
        {name=>'1k-concat5'  , tags=>['5elem' ], summary => 'Concatenating 5 strings together using "."'       , code_template=>'my $val; for (1..1000) { $val = <s1>.<s2>.<s3>.<s4>.<s5> } $val'},
        {name=>'1k-concat10' , tags=>['10elem'], summary => 'Concatenating 10 strings together using "."'      , code_template=>'my $val; for (1..1000) { $val = <s1>.<s2>.<s3>.<s4>.<s5>.<s6>.<s7>.<s8>.<s9>.<s10> } $val'},

        {name=>'1k-join2'    , tags=>['2elem' ], summary => 'Concatenating 2 strings together using join()'    , code_template=>'my $val; for (1..1000) { $val = join("",<s1>,<s2>) } $val'},
        {name=>'1k-join5'    , tags=>['5elem' ], summary => 'Concatenating 5 strings together using join()'    , code_template=>'my $val; for (1..1000) { $val = join("",<s1>,<s2>,<s3>,<s4>,<s5>) } $val'},
        {name=>'1k-join10'   , tags=>['10elem'], summary => 'Concatenating 10 strings together using join()'   , code_template=>'my $val; for (1..1000) { $val = join("",<s1>,<s2>,<s3>,<s4>,<s5>,<s6>,<s7>,<s8>,<s9>,<s10>) } $val'},

        {name=>'1k-sprintf2' , tags=>['2elem' ], summary => 'Concatenating 2 strings together using sprintf()' , code_template=>'my $val; for (1..1000) { $val = sprintf("%s%s", <s1>,<s2>) } $val'},
        {name=>'1k-sprintf5' , tags=>['5elem' ], summary => 'Concatenating 5 strings together using sprintf()' , code_template=>'my $val; for (1..1000) { $val = sprintf("%s%s%s%s%s", <s1>,<s2>,<s3>,<s4>,<s5>) } $val'},
        {name=>'1k-sprintf10', tags=>['10elem'], summary => 'Concatenating 10 strings together using sprinff()', code_template=>'my $val; for (1..1000) { $val = sprintf("%s%s%s%s%s%s%s%s%s%s", <s1>,<s2>,<s3>,<s4>,<s5>,<s6>,<s7>,<s8>,<s9>,<s10>) } $val'},
    ],
    datasets => [
        map {
            +{name=>"${_}char", args=>{s1=>"a"x$_, s2=>"b"x$_, s3=>"c"x$_,
                                     s4=>"d"x$_, s5=>"e"x$_, s6=>"f"x$_,
                                     s7=>"g"x$_, s8=>"h"x$_, s9=>"i"x$_,
                                     s10=>"j"x$_,
                                 }},
        } (1, 5, 10, 100),
    ],
};

1;
# ABSTRACT: Measure sprintf() performance

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::Sprintf - Measure sprintf() performance

=head1 VERSION

This document describes version 0.01 of Bencher::Scenario::Sprintf (from Perl distribution Bencher-Scenario-Sprintf), released on 2016-01-10.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m Sprintf

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 BENCHMARK PARTICIPANTS

=over

=item * 1k-concat2 (perl_code)

Concatenating 2 strings together using ".".

Code template:

 my $val; for (1..1000) { $val = <s1>.<s2> } $val



=item * 1k-concat5 (perl_code)

Concatenating 5 strings together using ".".

Code template:

 my $val; for (1..1000) { $val = <s1>.<s2>.<s3>.<s4>.<s5> } $val



=item * 1k-concat10 (perl_code)

Concatenating 10 strings together using ".".

Code template:

 my $val; for (1..1000) { $val = <s1>.<s2>.<s3>.<s4>.<s5>.<s6>.<s7>.<s8>.<s9>.<s10> } $val



=item * 1k-join2 (perl_code)

Concatenating 2 strings together using join().

Code template:

 my $val; for (1..1000) { $val = join("",<s1>,<s2>) } $val



=item * 1k-join5 (perl_code)

Concatenating 5 strings together using join().

Code template:

 my $val; for (1..1000) { $val = join("",<s1>,<s2>,<s3>,<s4>,<s5>) } $val



=item * 1k-join10 (perl_code)

Concatenating 10 strings together using join().

Code template:

 my $val; for (1..1000) { $val = join("",<s1>,<s2>,<s3>,<s4>,<s5>,<s6>,<s7>,<s8>,<s9>,<s10>) } $val



=item * 1k-sprintf2 (perl_code)

Concatenating 2 strings together using sprintf().

Code template:

 my $val; for (1..1000) { $val = sprintf("%s%s", <s1>,<s2>) } $val



=item * 1k-sprintf5 (perl_code)

Concatenating 5 strings together using sprintf().

Code template:

 my $val; for (1..1000) { $val = sprintf("%s%s%s%s%s", <s1>,<s2>,<s3>,<s4>,<s5>) } $val



=item * 1k-sprintf10 (perl_code)

Concatenating 10 strings together using sprinff().

Code template:

 my $val; for (1..1000) { $val = sprintf("%s%s%s%s%s%s%s%s%s%s", <s1>,<s2>,<s3>,<s4>,<s5>,<s6>,<s7>,<s8>,<s9>,<s10>) } $val



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.22.0 >>, CPU: I<< Intel(R) Core(TM) i7-4770 CPU @ 3.40GHz (4 cores) >>, OS: I<< GNU/Linux Debian version 8.0 >>, OS kernel: I<< Linux version 3.16.0-4-amd64 >>.

Benchmark with default option:

 +-----+--------------------------------------------------+-----------+-----------+---------+---------+
 | seq | name                                             | rate      | time      | errors  | samples |
 +-----+--------------------------------------------------+-----------+-----------+---------+---------+
 | 23  | {dataset=>"100char",participant=>"1k-join10"}    | 1.82e+04  | 54.9μs    | 2.3e-08 | 26      |
 | 11  | {dataset=>"100char",participant=>"1k-concat10"}  | 1.82e+04  | 54.8μs    | 1.2e-07 | 23      |
 | 35  | {dataset=>"100char",participant=>"1k-sprintf10"} | 19344.5   | 51.6942μs | 0       | 26      |
 | 31  | {dataset=>"100char",participant=>"1k-sprintf5"}  | 2.133e+04 | 46.89μs   | 1.3e-08 | 20      |
 | 19  | {dataset=>"100char",participant=>"1k-join5"}     | 2.244e+04 | 44.56μs   | 1.1e-08 | 27      |
 | 7   | {dataset=>"100char",participant=>"1k-concat5"}   | 2.25e+04  | 44.5μs    | 4e-08   | 20      |
 | 3   | {dataset=>"100char",participant=>"1k-concat2"}   | 2.52e+04  | 39.7μs    | 4.8e-08 | 25      |
 | 15  | {dataset=>"100char",participant=>"1k-join2"}     | 2.54e+04  | 39.4μs    | 1.3e-08 | 22      |
 | 10  | {dataset=>"10char",participant=>"1k-concat10"}   | 2.55e+04  | 39.2μs    | 1.2e-07 | 21      |
 | 27  | {dataset=>"100char",participant=>"1k-sprintf2"}  | 2.557e+04 | 39.11μs   | 1.1e-08 | 29      |
 | 30  | {dataset=>"10char",participant=>"1k-sprintf5"}   | 25854.9   | 38.6773μs | 0       | 20      |
 | 18  | {dataset=>"10char",participant=>"1k-join5"}      | 2.59e+04  | 38.7μs    | 5.1e-08 | 22      |
 | 9   | {dataset=>"5char",participant=>"1k-concat10"}    | 2.625e+04 | 38.09μs   | 1.1e-08 | 30      |
 | 2   | {dataset=>"10char",participant=>"1k-concat2"}    | 2.63e+04  | 38μs      | 1.3e-08 | 20      |
 | 25  | {dataset=>"5char",participant=>"1k-sprintf2"}    | 26677.1   | 37.4854μs | 0       | 22      |
 | 14  | {dataset=>"10char",participant=>"1k-join2"}      | 2.67e+04  | 37.4μs    | 5.3e-08 | 20      |
 | 12  | {dataset=>"1char",participant=>"1k-join2"}       | 26898.2   | 37.1773μs | 0       | 24      |
 | 17  | {dataset=>"5char",participant=>"1k-join5"}       | 26958.6   | 37.0939μs | 4.6e-11 | 25      |
 | 16  | {dataset=>"1char",participant=>"1k-join5"}       | 2.7e+04   | 37.1μs    | 5.3e-08 | 20      |
 | 21  | {dataset=>"5char",participant=>"1k-join10"}      | 26995.6   | 37.0431μs | 0       | 31      |
 | 22  | {dataset=>"10char",participant=>"1k-join10"}     | 27008.8   | 37.025μs  | 0       | 29      |
 | 29  | {dataset=>"5char",participant=>"1k-sprintf5"}    | 2.7e+04   | 37μs      | 4.6e-08 | 27      |
 | 13  | {dataset=>"5char",participant=>"1k-join2"}       | 2.7e+04   | 37μs      | 1.1e-07 | 20      |
 | 34  | {dataset=>"10char",participant=>"1k-sprintf10"}  | 2.716e+04 | 36.82μs   | 1.1e-08 | 31      |
 | 32  | {dataset=>"1char",participant=>"1k-sprintf10"}   | 2.72e+04  | 36.8μs    | 1.3e-08 | 20      |
 | 33  | {dataset=>"5char",participant=>"1k-sprintf10"}   | 2.73e+04  | 36.7μs    | 5.3e-08 | 20      |
 | 28  | {dataset=>"1char",participant=>"1k-sprintf5"}    | 2.73e+04  | 36.6μs    | 5e-08   | 23      |
 | 6   | {dataset=>"10char",participant=>"1k-concat5"}    | 2.75e+04  | 36.3μs    | 3.4e-08 | 27      |
 | 26  | {dataset=>"10char",participant=>"1k-sprintf2"}   | 2.774e+04 | 36.05μs   | 1.1e-08 | 29      |
 | 24  | {dataset=>"1char",participant=>"1k-sprintf2"}    | 2.77e+04  | 36μs      | 1.2e-08 | 23      |
 | 5   | {dataset=>"5char",participant=>"1k-concat5"}     | 2.78e+04  | 36μs      | 1.3e-08 | 20      |
 | 8   | {dataset=>"1char",participant=>"1k-concat10"}    | 2.78e+04  | 36μs      | 5.1e-08 | 22      |
 | 0   | {dataset=>"1char",participant=>"1k-concat2"}     | 2.78e+04  | 36μs      | 5e-08   | 23      |
 | 20  | {dataset=>"1char",participant=>"1k-join10"}      | 2.78e+04  | 36μs      | 4.3e-08 | 31      |
 | 1   | {dataset=>"5char",participant=>"1k-concat2"}     | 2.78e+04  | 36μs      | 5.3e-08 | 20      |
 | 4   | {dataset=>"1char",participant=>"1k-concat5"}     | 2.78e+04  | 36μs      | 4.2e-08 | 32      |
 +-----+--------------------------------------------------+-----------+-----------+---------+---------+

=head1 DESCRIPTION

This casual benchmarking shows no significant difference between the two, which
suggests the bottleneck is in another place (e.g. string memory allocation).

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-Sprintf>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-Sprintf>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-Sprintf>

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
