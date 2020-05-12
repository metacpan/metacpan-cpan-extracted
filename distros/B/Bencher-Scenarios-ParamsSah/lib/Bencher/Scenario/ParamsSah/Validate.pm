package Bencher::Scenario::ParamsSah::Validate;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-05-10'; # DATE
our $DIST = 'Bencher-Scenarios-ParamsSah'; # DIST
our $VERSION = '0.002'; # VERSION

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

This document describes version 0.002 of Bencher::Scenario::ParamsSah::Validate (from Perl distribution Bencher-Scenarios-ParamsSah), released on 2020-05-10.

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

L<Params::Sah> 0.072

L<Type::Params> 1.004004

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



=item * Type::Params-int_int[] (perl_code) [int_int[]]

Code template:

 use Type::Params qw(compile); use Types::Standard qw(Int ArrayRef); state $validator = compile(Int, ArrayRef[Int]); $validator->(@{<args>})



=item * Params::ValidationCompiler-int_int[] (perl_code) [int_int[]]

Code template:

 use Params::ValidationCompiler qw(validation_for); use Types::Standard qw(Int ArrayRef); state $validator = validation_for(params => [{type=>Int},{type=>ArrayRef[Int]}]); $validator->(@{<args>})



=item * Params::Sah-str[] (perl_code) [str[]]

Code template:

 state $validator = Params::Sah::gen_validator(["array*",of=>"str*"]); $validator->(<args>)



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

Run on: perl: I<< v5.30.0 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 19.10 >>, OS kernel: I<< Linux version 5.3.0-46-generic >>.

Benchmark with default options (C<< bencher -m ParamsSah::Validate >>):

 #table1#
 +--------------------------------------+----------------+--------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                          | dataset        | p_tags       | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +--------------------------------------+----------------+--------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | Params::Sah-int_int[]                | 1,[1..100]     | int_int[]    |     16000 |   64      |                 0.00% |             17031.73% | 2.1e-07 |      20 |
 | Params::Sah-strwithlen[]             | [(foobar)x100] | strwithlen[] |     20000 |   50      |                27.42% |             13345.08% | 3.9e-07 |      20 |
 | Type::Params-strwithlen[]            | [(foobar)x100] | strwithlen[] |     30000 |   33      |                90.68% |              8884.44% | 5.3e-08 |      20 |
 | Params::Sah-str[]                    | [("a")x100]    | str[]        |     45000 |   22      |               185.94% |              5891.35% | 2.7e-08 |      20 |
 | Params::Sah-int_int[]                | 1,[1..10]      | int_int[]    |    110000 |    9.4    |               580.88% |              2416.12% |   2e-08 |      20 |
 | Params::Sah-strwithlen[]             | [(foobar)x10]  | strwithlen[] |    100000 |    8      |               720.27% |              1988.55% |   3e-07 |      29 |
 | Params::ValidationCompiler-str[]     | [("a")x100]    | str[]        |    140000 |    7.2    |               785.67% |              1834.33% | 1.3e-08 |      20 |
 | Type::Params-int_int[]               | 1,[1..100]     | int_int[]    |    150000 |    6.9    |               831.03% |              1740.07% | 1.7e-08 |      20 |
 | Type::Params-str[]                   | [("a")x100]    | str[]        |    160000 |    6.3    |               912.17% |              1592.57% | 9.8e-09 |      21 |
 | Type::Params-strwithlen[]            | [(foobar)x10]  | strwithlen[] |    259000 |    3.86   |              1551.87% |               937.11% | 1.4e-09 |      29 |
 | Params::ValidationCompiler-int_int[] | 1,[1..100]     | int_int[]    |    276980 |    3.6104 |              1666.82% |               869.63% | 2.3e-11 |      20 |
 | Params::Sah-str[]                    | [("a") x 10]   | str[]        |    290000 |    3.5    |              1736.57% |               832.81% | 6.7e-09 |      20 |
 | Params::Sah-int_int[]                | 1,[]           | int_int[]    |    400000 |    2      |              2544.54% |               547.81% | 1.1e-07 |      24 |
 | Type::Params-int_int[]               | 1,[1..10]      | int_int[]    |    450000 |    2.2    |              2766.24% |               497.71% | 6.7e-09 |      20 |
 | Params::ValidationCompiler-int_int[] | 1,[]           | int_int[]    |    610000 |    1.6    |              3771.30% |               342.53% |   5e-09 |      20 |
 | Type::Params-int_int[]               | 1,[]           | int_int[]    |    620000 |    1.6    |              3867.86% |               331.76% | 3.3e-09 |      20 |
 | Params::Sah-str[]                    | []             | str[]        |    831800 |    1.202  |              5206.17% |               222.86% | 2.3e-11 |      20 |
 | Params::ValidationCompiler-int_int[] | 1,[1..10]      | int_int[]    |    881000 |    1.14   |              5517.24% |               204.98% | 3.6e-10 |      27 |
 | Params::ValidationCompiler-str[]     | [("a") x 10]   | str[]        |    997100 |    1.003  |              6260.44% |               169.35% | 2.3e-11 |      24 |
 | Type::Params-str[]                   | [("a") x 10]   | str[]        |   1010000 |    0.993  |              6323.35% |               166.71% | 3.7e-10 |      26 |
 | Params::Sah-strwithlen               | str-foobar     | str          |   1000000 |    0.7    |              8528.76% |                98.54% | 2.7e-08 |      20 |
 | Params::ValidationCompiler-int       | 1              | int          |   1550000 |    0.643  |              9818.60% |                72.72% | 2.1e-10 |      20 |
 | Type::Params-int                     | 1              | int          |   1570000 |    0.639  |              9888.10% |                71.52% | 2.1e-10 |      20 |
 | Type::Params-strwithlen              | str-foobar     | str          |   1800000 |    0.57   |             11070.04% |                53.37% | 8.3e-10 |      20 |
 | Params::Sah-int                      | 1              | int          |   1912000 |    0.523  |             12096.43% |                40.47% | 2.3e-11 |      20 |
 | Params::ValidationCompiler-str[]     | []             | str[]        |   2600000 |    0.39   |             16376.44% |                 3.98% | 6.3e-10 |      20 |
 | Type::Params-str[]                   | []             | str[]        |   2690000 |    0.372  |             17031.73% |                 0.00% | 1.6e-10 |      36 |
 +--------------------------------------+----------------+--------------+-----------+-----------+-----------------------+-----------------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m ParamsSah::Validate --module-startup >>):

 #table2#
 +----------------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | participant                | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +----------------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | Type::Params               |      41.2 |              33.9 |                 0.00% |               467.20% | 3.9e-05 |      20 |
 | Params::ValidationCompiler |      30   |              22.7 |                37.20% |               313.41% | 1.9e-05 |      20 |
 | Params::Sah                |      11.1 |               3.8 |               272.43% |                52.30% | 6.2e-06 |      20 |
 | perl -e1 (baseline)        |       7.3 |               0   |               467.20% |                 0.00% | 1.9e-05 |      20 |
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
