package Bencher::Scenario::PerinciSubValidateArgs::Overhead;

our $DATE = '2016-05-25'; # DATE
our $VERSION = '0.004'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Measure validation overhead',
    participants => [
        {
            name => 'none',
            fcall_template => 'Bencher::ScenarioUtil::PerinciSubValidateArgs::NoValidate::foo(a1=><a1>, a2=><a2>)',
        },
        {
            name => 'manual',
            fcall_template => 'Bencher::ScenarioUtil::PerinciSubValidateArgs::ValidateManually::foo(a1=><a1>, a2=><a2>)',
        },
        {
            name => 'manual+dsah',
            fcall_template => 'Bencher::ScenarioUtil::PerinciSubValidateArgs::ValidateManualDataSah::foo(a1=><a1>, a2=><a2>)',
        },
        {
            name => 'DZPRV',
            fcall_template => 'Bencher::ScenarioUtil::PerinciSubValidateArgs::ValidateUsingDZPRV::foo(a1=><a1>, a2=><a2>)',
            include_by_default => 0,
        },
        {
            name => 'DZPRW',
            fcall_template => 'Bencher::ScenarioUtil::PerinciSubValidateArgs::ValidateUsingDZPRW::foo_dzprw(a1=><a1>, a2=><a2>)',
            include_by_default => 0,
        },
        {
            name => 'PSW',
            fcall_template => 'Bencher::ScenarioUtil::PerinciSubValidateArgs::ValidateUsingPSW::foo(a1=><a1>, a2=><a2>)',
        },
        {
            name => 'PSV',
            fcall_template => 'Bencher::ScenarioUtil::PerinciSubValidateArgs::ValidateUsingPSV::foo(a1=><a1>, a2=><a2>)',
        },
        {
            name => 'Type::Tiny',
            fcall_template => 'Bencher::ScenarioUtil::PerinciSubValidateArgs::ValidateUsingTypeTiny::foo(a1=><a1>, a2=><a2>)',
        },
    ],
    datasets => [
        {args => {a1=>1, a2=>[1]}},
    ],
};

1;
# ABSTRACT: Measure validation overhead

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::PerinciSubValidateArgs::Overhead - Measure validation overhead

=head1 VERSION

This document describes version 0.004 of Bencher::Scenario::PerinciSubValidateArgs::Overhead (from Perl distribution Bencher-Scenarios-PerinciSubValidateArgs), released on 2016-05-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m PerinciSubValidateArgs::Overhead

To run module startup overhead benchmark:

 % bencher --module-startup -m PerinciSubValidateArgs::Overhead

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Bencher::ScenarioUtil::PerinciSubValidateArgs::NoValidate>

L<Bencher::ScenarioUtil::PerinciSubValidateArgs::ValidateManually>

L<Bencher::ScenarioUtil::PerinciSubValidateArgs::ValidateManualDataSah>

L<Bencher::ScenarioUtil::PerinciSubValidateArgs::ValidateUsingPSW>

L<Bencher::ScenarioUtil::PerinciSubValidateArgs::ValidateUsingPSV>

L<Bencher::ScenarioUtil::PerinciSubValidateArgs::ValidateUsingTypeTiny>

=head1 BENCHMARK PARTICIPANTS

=over

=item * none (perl_code)

Function call template:

 Bencher::ScenarioUtil::PerinciSubValidateArgs::NoValidate::foo(a1=><a1>, a2=><a2>)



=item * manual (perl_code)

Function call template:

 Bencher::ScenarioUtil::PerinciSubValidateArgs::ValidateManually::foo(a1=><a1>, a2=><a2>)



=item * manual+dsah (perl_code)

Function call template:

 Bencher::ScenarioUtil::PerinciSubValidateArgs::ValidateManualDataSah::foo(a1=><a1>, a2=><a2>)



=item * DZPRV (perl_code) (not included by default)

Function call template:

 Bencher::ScenarioUtil::PerinciSubValidateArgs::ValidateUsingPSW::foo(a1=><a1>, a2=><a2>)



=item * DZPRW (perl_code) (not included by default)

Function call template:

 Bencher::ScenarioUtil::PerinciSubValidateArgs::ValidateUsingPSV::foo(a1=><a1>, a2=><a2>)



=item * PSW (perl_code)

Function call template:

 Bencher::ScenarioUtil::PerinciSubValidateArgs::ValidateUsingTypeTiny::foo(a1=><a1>, a2=><a2>)



=item * PSV (perl_code)

L<Bencher::ScenarioUtil::PerinciSubValidateArgs::ValidateUsingPSV>::foo



=item * Type::Tiny (perl_code)

L<Bencher::ScenarioUtil::PerinciSubValidateArgs::ValidateUsingTypeTiny>::foo



=back

=head1 BENCHMARK DATASETS

=over

=item * {a1=>1,a2=>[1]}

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.22.1 >>, CPU: I<< Intel(R) Core(TM) i5-2400 CPU @ 3.10GHz (4 cores) >>, OS: I<< GNU/Linux Debian version 8.0 >>, OS kernel: I<< Linux version 3.16.0-4-amd64 >>.

Benchmark with default options (C<< bencher -m PerinciSubValidateArgs::Overhead >>):

 +-------------+------------+-----------+------------+---------+---------+
 | participant | rate (/s)  | time (μs) | vs_slowest | errors  | samples |
 +-------------+------------+-----------+------------+---------+---------+
 | PSW         | 7.6e+04    | 13        | 1          | 2.2e-08 | 30      |
 | PSV         | 1.0787e+05 | 9.2703    | 1.4252     | 5.7e-11 | 20      |
 | manual+dsah | 1.18e+05   | 8.5       | 1.55       | 3.3e-09 | 20      |
 | Type::Tiny  | 1.3e+05    | 8         | 1.7        | 1.2e-08 | 23      |
 | manual      | 2.4e+05    | 4.2       | 3.1        | 5e-09   | 20      |
 | none        | 1.969e+06  | 0.508     | 26.01      | 4.7e-11 | 21      |
 +-------------+------------+-----------+------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m PerinciSubValidateArgs::Overhead --module-startup >>):

 +----------------------------------------------------------------------+-----------+------------------------+------------+---------+---------+
 | participant                                                          | time (ms) | mod_overhead_time (ms) | vs_slowest | errors  | samples |
 +----------------------------------------------------------------------+-----------+------------------------+------------+---------+---------+
 | Bencher::ScenarioUtil::PerinciSubValidateArgs::ValidateUsingPSW      | 78        | 73                     | 1          | 0.00014 | 20      |
 | Bencher::ScenarioUtil::PerinciSubValidateArgs::ValidateManualDataSah | 68        | 63                     | 1.1        | 0.00015 | 20      |
 | Bencher::ScenarioUtil::PerinciSubValidateArgs::ValidateUsingTypeTiny | 47        | 42                     | 1.7        | 9.7e-05 | 20      |
 | Bencher::ScenarioUtil::PerinciSubValidateArgs::ValidateUsingPSV      | 11        | 6                      | 6.8        | 4.1e-05 | 21      |
 | Bencher::ScenarioUtil::PerinciSubValidateArgs::ValidateManually      | 8.3       | 3.3                    | 9.3        | 2.5e-05 | 20      |
 | Bencher::ScenarioUtil::PerinciSubValidateArgs::NoValidate            | 8.1       | 3.1                    | 9.7        | 5.5e-05 | 20      |
 | perl -e1 (baseline)                                                  | 5         | 0                      | 2e+01      | 5.1e-05 | 20      |
 +----------------------------------------------------------------------+-----------+------------------------+------------+---------+---------+

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARK NOTES

The Type::Tiny, Data::Sah, Perinci::Sub::ValidateArgs participants (except
C<none>, obviously) all should be in the same order of magnitude because both
L<Data::Sah> and L<Type::Tiny> work by generating Perl code validator and then
compiling (C<eval()>) them then execute the compiled result. The differences are
in the details: how the generated Perl code is structured, what the code for the
type checks are (e.g. checking for number can be done with a regex or
L<Scalar::Util>'s C<looks_like_number()> or L<Scalar::Util::Numeric>, and so
on).

Perinci::Sub::Wrapper (PSW) and Dist::Zilla::Plugin::Rinci::Wrap is slower
because it does more.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-PerinciSubValidateArgs>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-PerinciSubValidateArgs>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-PerinciSubValidateArgs>

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
