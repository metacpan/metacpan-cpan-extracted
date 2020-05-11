package Bencher::Scenario::ParamsSah::Startup;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-05-08'; # DATE
our $DIST = 'Bencher-Scenarios-ParamsSah'; # DIST
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark startup',
    module_startup => 1,
    participants => [
        {module=>'Params::Sah'},
        {module=>'Type::Params'},
        {module=>'Params::ValidationCompiler'},
    ],
};

1;
# ABSTRACT: Benchmark startup

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::ParamsSah::Startup - Benchmark startup

=head1 VERSION

This document describes version 0.001 of Bencher::Scenario::ParamsSah::Startup (from Perl distribution Bencher-Scenarios-ParamsSah), released on 2020-05-08.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m ParamsSah::Startup

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

L<Params::Sah>



=item * Type::Params (perl_code)

L<Type::Params>



=item * Params::ValidationCompiler (perl_code)

L<Params::ValidationCompiler>



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.30.2 >>, CPU: I<< Intel(R) Core(TM) i7-4770 CPU @ 3.40GHz (4 cores) >>, OS: I<< GNU/Linux LinuxMint version 19 >>, OS kernel: I<< Linux version 4.15.0-91-generic >>.

Benchmark with default options (C<< bencher -m ParamsSah::Startup >>):

 #table1#
 +----------------------------+-----------+-------------------+-----------------------+-----------------------+-----------+---------+
 | participant                | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors   | samples |
 +----------------------------+-----------+-------------------+-----------------------+-----------------------+-----------+---------+
 | Type::Params               |        38 |                33 |                 0.00% |               653.18% |   0.00016 |      20 |
 | Params::ValidationCompiler |        24 |                19 |                58.69% |               374.62% | 7.5e-05   |      20 |
 | Params::Sah                |        10 |                 5 |               288.09% |                94.07% |   0.00019 |      21 |
 | perl -e1 (baseline)        |         5 |                 0 |               653.18% |                 0.00% |   0.00015 |      20 |
 +----------------------------+-----------+-------------------+-----------------------+-----------------------+-----------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

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
