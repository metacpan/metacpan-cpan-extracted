package Bencher::Scenario::ParamsSah::Compile;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-05-08'; # DATE
our $DIST = 'Bencher-Scenarios-ParamsSah'; # DIST
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Measure compilation speed',
    participants => [
        {
            name => 'Params::Sah',
            fcall_template => q(Params::Sah::gen_validator("int*", ["array*",of=>"int*"])),
        },
        {
            name => 'Type::Params',
            module => 'Type::Params',
            code_template => q(use Type::Params qw(compile); use Types::Standard qw(Int ArrayRef); compile(Int, ArrayRef[Int])),
        },
        {
            name => 'Params::ValidationCompiler',
            module => 'Params::ValidationCompiler',
            code_template => q(use Params::ValidationCompiler qw(validation_for); use Types::Standard qw(Int ArrayRef); validation_for(params => [{type=>Int}, {type=>ArrayRef[Int]}])),
        },
    ],
};

1;
# ABSTRACT: Measure compilation speed

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::ParamsSah::Compile - Measure compilation speed

=head1 VERSION

This document describes version 0.001 of Bencher::Scenario::ParamsSah::Compile (from Perl distribution Bencher-Scenarios-ParamsSah), released on 2020-05-08.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m ParamsSah::Compile

To run module startup overhead benchmark:

 % bencher --module-startup -m ParamsSah::Compile

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

=item * Params::Sah (perl_code)

Function call template:

 Params::Sah::gen_validator("int*", ["array*",of=>"int*"])



=item * Type::Params (perl_code)

Code template:

 use Type::Params qw(compile); use Types::Standard qw(Int ArrayRef); compile(Int, ArrayRef[Int])



=item * Params::ValidationCompiler (perl_code)

Code template:

 use Params::ValidationCompiler qw(validation_for); use Types::Standard qw(Int ArrayRef); validation_for(params => [{type=>Int}, {type=>ArrayRef[Int]}])



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.30.2 >>, CPU: I<< Intel(R) Core(TM) i7-4770 CPU @ 3.40GHz (4 cores) >>, OS: I<< GNU/Linux LinuxMint version 19 >>, OS kernel: I<< Linux version 4.15.0-91-generic >>.

Benchmark with default options (C<< bencher -m ParamsSah::Compile >>):

 #table1#
 +----------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                | rate (/s) | time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +----------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | Params::Sah                |       566 |      1.77 |                 0.00% |               871.27% | 6.9e-07 |      20 |
 | Params::ValidationCompiler |      3800 |      0.27 |               566.09% |                45.82% | 3.7e-07 |      20 |
 | Type::Params               |      5500 |      0.18 |               871.27% |                 0.00% | 1.9e-07 |      24 |
 +----------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m ParamsSah::Compile --module-startup >>):

 #table2#
 +----------------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | participant                | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +----------------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | Type::Params               |        38 |                33 |                 0.00% |               671.59% | 0.00018 |      20 |
 | Params::ValidationCompiler |        25 |                20 |                54.11% |               400.69% | 0.00016 |      20 |
 | Params::Sah                |         9 |                 4 |               342.67% |                74.30% | 0.00018 |      20 |
 | perl -e1 (baseline)        |         5 |                 0 |               671.59% |                 0.00% | 0.00021 |      20 |
 +----------------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 BENCHMARK NOTES

Compilation of L<Sah> schemas by L<Data::Sah> (which is used by L<Params::Sah>)
is slower due to doing more stuffs like normalizing schema and other
preparations. If needed, future version of Params::Sah or Data::Sah can cache
compilation result particularly for commonly encountered simple schemas like
C<'int'>, C<< ['array*', of=>'str*'] >>, etc.

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
