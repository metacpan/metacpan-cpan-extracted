package Bencher::Scenario::ParamsSah::Validate;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-05-08'; # DATE
our $DIST = 'Bencher-Scenarios-ParamsSah'; # DIST
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Measure validation speed',
    participants => [
        {
            name => 'Params::Sah-int',
            module => 'Params::Sah',
            code_template => q(state $validator = Params::Sah::gen_validator("int*"); $validator->(<args>)),
            tags => ['int'],
        },
        {
            name => 'Type::Params-int',
            module => 'Type::Params',
            code_template => q(use Type::Params qw(compile); use Types::Standard qw(Int); state $validator = compile(Int); $validator->(@{<args>})),
            tags => ['int'],
        },
        {
            name => 'Params::ValidationCompiler-int',
            module => 'Params::ValidationCompiler',
            code_template => q(use Params::ValidationCompiler qw(validation_for); use Types::Standard qw(Int); state $validator = validation_for(params => [{type=>Int}]); $validator->(@{<args>})),
            tags => ['int'],
        },

        {
            name => 'Params::Sah-int_int[]',
            module => 'Params::Sah',
            code_template => q(state $validator = Params::Sah::gen_validator("int*", ["array*",of=>"int*"]); $validator->(<args>)),
            tags => ['int_int[]'],
        },
        {
            name => 'Params::Sah(on_invalid-bool)-int_int[]',
            module => 'Params::Sah',
            code_template => q(state $validator = Params::Sah::gen_validator({on_invalid=>"bool"}, "int*", ["array*",of=>"int*"]); $validator->(<args>)),
            tags => ['int_int[]'],
        },
        {
            name => 'Type::Params-int_int[]',
            module => 'Type::Params',
            code_template => q(use Type::Params qw(compile); use Types::Standard qw(Int ArrayRef); state $validator = compile(Int, ArrayRef[Int]); $validator->(@{<args>})),
            tags => ['int_int[]'],
        },
        {
            name => 'Params::ValidationCompiler-int_int[]',
            module => 'Params::ValidationCompiler',
            code_template => q(use Params::ValidationCompiler qw(validation_for); use Types::Standard qw(Int ArrayRef); state $validator = validation_for(params => [{type=>Int},{type=>ArrayRef[Int]}]); $validator->(@{<args>})),
            tags => ['int_int[]'],
        },

        {
            name => 'Params::Sah-str[]',
            module => 'Params::Sah',
            code_template => q(state $validator = Params::Sah::gen_validator(["array*",of=>"str*"]); $validator->(<args>)),
            tags => ['str[]'],
        },
        {
            name => 'Params::Sah(on_invalid-bool)-str[]',
            module => 'Params::Sah',
            code_template => q(state $validator = Params::Sah::gen_validator({on_invalid=>"bool"}, ["array*",of=>"str*"]); $validator->(<args>)),
            tags => ['str[]'],
        },
        {
            name => 'Type::Params-str[]',
            module => 'Type::Params',
            code_template => q(use Type::Params qw(compile); use Types::Standard qw(Str ArrayRef); state $validator = compile(ArrayRef[Str]); $validator->(@{<args>})),
            tags => ['str[]'],
        },
        {
            name => 'Params::ValidationCompiler-str[]',
            module => 'Params::ValidationCompiler',
            code_template => q(use Params::ValidationCompiler qw(validation_for); use Types::Standard qw(Str ArrayRef); state $validator = validation_for(params => [{type=>ArrayRef[Str]}]); $validator->(@{<args>})),
            tags => ['str[]'],
        },

        {
            name => 'Params::Sah-strwithlen',
            module => 'Params::Sah',
            code_template => q(state $validator = Params::Sah::gen_validator(["str*",min_len=>4, max_len=>8]); $validator->(<args>)),
            tags => ['str'],
        },
        {
            name => 'Type::Params-strwithlen',
            module => 'Type::Params',
            code_template => q(use Type::Params qw(compile); use Types::Standard qw(Str); state $validator = compile(Str->where('length($_) >= 4 && length($_) <= 8')); $validator->(@{<args>})),
            tags => ['str'],
        },

        {
            name => 'Params::Sah-strwithlen[]',
            module => 'Params::Sah',
            code_template => q(state $validator = Params::Sah::gen_validator(['array*', of=>["str*",min_len=>4, max_len=>8]]); $validator->(<args>)),
            tags => ['strwithlen[]'],
        },
        {
            name => 'Type::Params-strwithlen[]',
            module => 'Type::Params',
            code_template => q(use Type::Params qw(compile); use Types::Standard qw(Str ArrayRef); state $validator = compile(ArrayRef[Str->where('length($_) >= 4 && length($_) <= 8')]); $validator->(@{<args>})),
            tags => ['strwithlen[]'],
        },
    ],
    datasets => [
        {
            name => '1',
            args => { args => [1] },
            include_participant_tags => ['int'],
        },
        {
            name => '1,[]',
            args => { args => [1,[]] },
            include_participant_tags => ['int_int[]'],
        },
        {
            name => '1,[1..10]',
            args => { args => [1,[1..10]] },
            include_participant_tags => ['int_int[]'],
        },
        {
            name => '1,[1..100]',
            args => { args => [1,[1..100]] },
            include_participant_tags => ['int_int[]'],
        },

        {
            name => '[]',
            args => { args => [[]] },
            include_participant_tags => ['str[]'],
        },
        {
            name => '[("a") x 10]',
            args => { args => [[('a')x10]] },
            include_participant_tags => ['str[]'],
        },
        {
            name => '[("a")x100]',
            args => { args => [[('a')x100]] },
            include_participant_tags => ['str[]'],
        },
        {
            name => 'str-foobar',
            args => { args => ['foobar'] },
            include_participant_tags => ['str'],
        },
        {
            name => '[(foobar)x10]',
            args => { args => [[('foobar')x10]] },
            include_participant_tags => ['strwithlen[]'],
        },
        {
            name => '[(foobar)x100]',
            args => { args => [[('foobar')x100]] },
            include_participant_tags => ['strwithlen[]'],
        },
    ],
};

1;
# ABSTRACT: Measure validation speed

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::ParamsSah::Validate - Measure validation speed

=head1 VERSION

This document describes version 0.001 of Bencher::Scenario::ParamsSah::Validate (from Perl distribution Bencher-Scenarios-ParamsSah), released on 2020-05-08.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m ParamsSah::Validate

To run module startup overhead benchmark:

 % bencher --module-startup -m ParamsSah::Validate

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Params::Sah> 0.070

L<Type::Params> 1.010001

L<Params::ValidationCompiler> 0.30

=head1 BENCHMARK PARTICIPANTS

=over

=item * Params::Sah-int (perl_code) [int]

Code template:

 state $validator = Params::Sah::gen_validator("int*"); $validator->(<args>)



=item * Type::Params-int (perl_code) [int]

Code template:

 use Type::Params qw(compile); use Types::Standard qw(Int); state $validator = compile(Int); $validator->(@{<args>})



=item * Params::ValidationCompiler-int (perl_code) [int]

Code template:

 use Params::ValidationCompiler qw(validation_for); use Types::Standard qw(Int); state $validator = validation_for(params => [{type=>Int}]); $validator->(@{<args>})



=item * Params::Sah-int_int[] (perl_code) [int_int[]]

Code template:

 state $validator = Params::Sah::gen_validator("int*", ["array*",of=>"int*"]); $validator->(<args>)



=item * Params::Sah(on_invalid-bool)-int_int[] (perl_code) [int_int[]]

Code template:

 state $validator = Params::Sah::gen_validator({on_invalid=>"bool"}, "int*", ["array*",of=>"int*"]); $validator->(<args>)



=item * Type::Params-int_int[] (perl_code) [int_int[]]

Code template:

 use Type::Params qw(compile); use Types::Standard qw(Int ArrayRef); state $validator = compile(Int, ArrayRef[Int]); $validator->(@{<args>})



=item * Params::ValidationCompiler-int_int[] (perl_code) [int_int[]]

Code template:

 use Params::ValidationCompiler qw(validation_for); use Types::Standard qw(Int ArrayRef); state $validator = validation_for(params => [{type=>Int},{type=>ArrayRef[Int]}]); $validator->(@{<args>})



=item * Params::Sah-str[] (perl_code) [str[]]

Code template:

 state $validator = Params::Sah::gen_validator(["array*",of=>"str*"]); $validator->(<args>)



=item * Params::Sah(on_invalid-bool)-str[] (perl_code) [str[]]

Code template:

 state $validator = Params::Sah::gen_validator({on_invalid=>"bool"}, ["array*",of=>"str*"]); $validator->(<args>)



=item * Type::Params-str[] (perl_code) [str[]]

Code template:

 use Type::Params qw(compile); use Types::Standard qw(Str ArrayRef); state $validator = compile(ArrayRef[Str]); $validator->(@{<args>})



=item * Params::ValidationCompiler-str[] (perl_code) [str[]]

Code template:

 use Params::ValidationCompiler qw(validation_for); use Types::Standard qw(Str ArrayRef); state $validator = validation_for(params => [{type=>ArrayRef[Str]}]); $validator->(@{<args>})



=item * Params::Sah-strwithlen (perl_code) [str]

Code template:

 state $validator = Params::Sah::gen_validator(["str*",min_len=>4, max_len=>8]); $validator->(<args>)



=item * Type::Params-strwithlen (perl_code) [str]

Code template:

 use Type::Params qw(compile); use Types::Standard qw(Str); state $validator = compile(Str->where('length($_) >= 4 && length($_) <= 8')); $validator->(@{<args>})



=item * Params::Sah-strwithlen[] (perl_code) [strwithlen[]]

Code template:

 state $validator = Params::Sah::gen_validator(['array*', of=>["str*",min_len=>4, max_len=>8]]); $validator->(<args>)



=item * Type::Params-strwithlen[] (perl_code) [strwithlen[]]

Code template:

 use Type::Params qw(compile); use Types::Standard qw(Str ArrayRef); state $validator = compile(ArrayRef[Str->where('length($_) >= 4 && length($_) <= 8')]); $validator->(@{<args>})



=back

=head1 BENCHMARK DATASETS

=over

=item * 1

=item * 1,[]

=item * 1,[1..10]

=item * 1,[1..100]

=item * []

=item * [("a") x 10]

=item * [("a")x100]

=item * str-foobar

=item * [(foobar)x10]

=item * [(foobar)x100]

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.30.2 >>, CPU: I<< Intel(R) Core(TM) i7-4770 CPU @ 3.40GHz (4 cores) >>, OS: I<< GNU/Linux LinuxMint version 19 >>, OS kernel: I<< Linux version 4.15.0-91-generic >>.

Benchmark with default options (C<< bencher -m ParamsSah::Validate >>):

 #table1#
 +----------------------------------------+----------------+--------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                            | dataset        | p_tags       | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +----------------------------------------+----------------+--------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | Params::Sah-strwithlen[]               | [(foobar)x100] | strwithlen[] |     26200 | 38.1      |                 0.00% |             12397.17% | 1.3e-08 |      22 |
 | Params::Sah-int_int[]                  | 1,[1..100]     | int_int[]    |     31100 | 32.1      |                18.67% |             10430.78% | 1.3e-08 |      21 |
 | Type::Params-strwithlen[]              | [(foobar)x100] | strwithlen[] |     35000 | 28        |                34.94% |              9160.96% | 5.2e-08 |      21 |
 | Params::Sah(on_invalid-bool)-int_int[] | 1,[1..100]     | int_int[]    |     38700 | 25.9      |                47.39% |              8379.14% | 1.3e-08 |      20 |
 | Params::Sah-str[]                      | [("a")x100]    | str[]        |     42600 | 23.5      |                62.46% |              7592.45% | 6.7e-09 |      20 |
 | Params::Sah(on_invalid-bool)-str[]     | [("a")x100]    | str[]        |     56400 | 17.7      |               115.12% |              5709.47% | 6.4e-09 |      22 |
 | Params::Sah-strwithlen[]               | [(foobar)x10]  | strwithlen[] |    157842 |  6.33545  |               501.58% |              1977.39% |   0     |      20 |
 | Params::Sah-int_int[]                  | 1,[1..10]      | int_int[]    |    184250 |  5.4273   |               602.24% |              1679.61% | 5.8e-12 |      26 |
 | Params::ValidationCompiler-str[]       | [("a")x100]    | str[]        |    201379 |  4.96577  |               667.51% |              1528.27% |   0     |      30 |
 | Type::Params-str[]                     | [("a")x100]    | str[]        |    201731 |  4.95709  |               668.85% |              1525.43% |   0     |      20 |
 | Params::Sah-str[]                      | [("a") x 10]   | str[]        |    230000 |  4.3      |               789.98% |              1304.21% | 6.7e-09 |      20 |
 | Params::Sah(on_invalid-bool)-int_int[] | 1,[1..10]      | int_int[]    |    254000 |  3.94     |               866.49% |              1193.05% | 1.7e-09 |      20 |
 | Type::Params-strwithlen[]              | [(foobar)x10]  | strwithlen[] |    308500 |  3.2415   |              1075.77% |               962.89% | 5.8e-12 |      20 |
 | Params::ValidationCompiler-int_int[]   | 1,[1..100]     | int_int[]    |    350000 |  2.86     |              1232.51% |               837.87% | 2.7e-09 |      31 |
 | Params::Sah(on_invalid-bool)-str[]     | [("a") x 10]   | str[]        |    350000 |  2.8      |              1239.71% |               832.82% |   4e-09 |      22 |
 | Type::Params-int_int[]                 | 1,[1..100]     | int_int[]    |    358000 |  2.8      |              1263.50% |               816.55% | 8.1e-10 |      21 |
 | Params::Sah-int_int[]                  | 1,[]           | int_int[]    |    440000 |  2.3      |              1583.81% |               642.20% | 2.5e-09 |      20 |
 | Params::Sah-str[]                      | []             | str[]        |    530000 |  1.9      |              1903.66% |               523.72% | 3.3e-09 |      20 |
 | Params::Sah(on_invalid-bool)-int_int[] | 1,[]           | int_int[]    |    754760 |  1.3249   |              2776.61% |               334.44% | 5.7e-12 |      20 |
 | Params::Sah(on_invalid-bool)-str[]     | []             | str[]        |   1002900 |  0.997107 |              3722.34% |               226.95% |   0     |      20 |
 | Params::ValidationCompiler-int_int[]   | 1,[1..10]      | int_int[]    |   1000000 |  0.98     |              3775.49% |               222.47% | 1.1e-09 |      26 |
 | Type::Params-int_int[]                 | 1,[1..10]      | int_int[]    |   1060000 |  0.945    |              3931.47% |               209.99% | 4.3e-10 |      20 |
 | Params::ValidationCompiler-str[]       | [("a") x 10]   | str[]        |   1212670 |  0.824625 |              4521.83% |               170.39% |   0     |      20 |
 | Type::Params-str[]                     | [("a") x 10]   | str[]        |   1232800 |  0.81119  |              4598.38% |               165.99% | 5.5e-12 |      25 |
 | Params::ValidationCompiler-int_int[]   | 1,[]           | int_int[]    |   1382840 |  0.723152 |              5170.37% |               137.12% |   0     |      20 |
 | Type::Params-int_int[]                 | 1,[]           | int_int[]    |   1510330 |  0.662106 |              5656.29% |               117.10% |   0     |      24 |
 | Type::Params-int                       | 1              | int          |   1700000 |  0.57     |              6564.73% |                87.51% | 6.3e-10 |      20 |
 | Params::ValidationCompiler-int         | 1              | int          |   1800000 |  0.54     |              6914.35% |                78.17% | 8.3e-10 |      20 |
 | Type::Params-strwithlen                | str-foobar     | str          |   2090000 |  0.477    |              7884.62% |                56.52% | 2.1e-10 |      20 |
 | Params::Sah-int                        | 1              | int          |   2207000 |  0.4532   |              8309.78% |                48.60% | 2.8e-11 |      20 |
 | Params::Sah-strwithlen                 | str-foobar     | str          |   2300000 |  0.44     |              8625.78% |                43.22% | 7.5e-10 |      25 |
 | Params::ValidationCompiler-str[]       | []             | str[]        |   3080000 |  0.325    |             11639.02% |                 6.46% |   1e-10 |      20 |
 | Type::Params-str[]                     | []             | str[]        |   3300000 |  0.3      |             12397.17% |                 0.00% | 3.1e-10 |      20 |
 +----------------------------------------+----------------+--------------+-----------+-----------+-----------------------+-----------------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m ParamsSah::Validate --module-startup >>):

 #table2#
 +----------------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | participant                | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +----------------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | Type::Params               |        38 |                32 |                 0.00% |               552.54% | 0.00013 |      20 |
 | Params::ValidationCompiler |        24 |                18 |                58.61% |               311.42% | 0.00017 |      20 |
 | Params::Sah                |         8 |                 2 |               356.85% |                42.83% | 0.00012 |      20 |
 | perl -e1 (baseline)        |         6 |                 0 |               552.54% |                 0.00% | 0.00023 |      21 |
 +----------------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 BENCHMARK NOTES

=head2 Seeing generated source code

To see the source code generated by Params:Sah, set $Params::Sah::DEBUG to 1. Or
you can try on the command-line (the CLI utility is part of L<App::SahUtils>):

 % validate-with-sah '"int*"' -c

To see the source code generated by Type::Params, pass C<< want_source => 1 >>
option to C<compile()>, e.g.:

 compile({want_source=>1}, Int, ...)

To see the source code generated by Params::ValidationCompiler, pass C<<
debug => 1 >> parameter to C<validation_for()>, e.g.:

 validation_for(params => ..., debug=>1)

=head2 Performance of Params::Sah-generated validation code

Data::Sah has not been optimized to check for simple types like C<int> or <str>
and arrays of those simple types. Compare the generated source code for Sah
schema C<< ['array*',of=>'int*'] >> with Type::Params' code for ArrayRef[Int],
for example.

However, Params::Sah is comparable with Types::Params and
Params::ValidationCompiler once you add clauses like length, etc.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-ParamsSah>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-ParamsSah>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-ParamsSah>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
