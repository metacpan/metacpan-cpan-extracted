package Bencher::Scenario::SPVM::Sum;

our $DATE = '2017-06-21'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

use SPVM 'Examples::Sum';

our $scenario = {
    summary => 'Benchmark SPVM (sum two numbers)',
    modules => {
        'SPVM' => {},
        'SPVM::Examples' => {}, # to pull SPVM/Examples/Sum.spvm
    },
    participants => [
        { name => 'SPVM', code => sub { SPVM::Examples::Sum::sum(SPVM::int(3), SPVM::int(5))->value } },
        { name => 'Perl', code => sub { My::Sum::sum(3, 5) } },
    ],
};

package My::Sum;

sub sum { $_[0] + $_[1] }

1;
# ABSTRACT: Benchmark SPVM (sum two numbers)

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::SPVM::Sum - Benchmark SPVM (sum two numbers)

=head1 VERSION

This document describes version 0.001 of Bencher::Scenario::SPVM::Sum (from Perl distribution Bencher-Scenarios-SPVM), released on 2017-06-21.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m SPVM::Sum

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<SPVM> 0.0201

L<SPVM::Examples> 0.001

=head1 BENCHMARK PARTICIPANTS

=over

=item * SPVM (perl_code)



=item * Perl (perl_code)



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.26.0 >>, CPU: I<< Intel(R) Core(TM) i5-2400 CPU @ 3.10GHz (4 cores) >>, OS: I<< GNU/Linux Debian version 8.0 >>, OS kernel: I<< Linux version 3.16.0-4-amd64 >>.

Benchmark with default options (C<< bencher -m SPVM::Sum >>):

 #table1#
 +-------------+-----------+-----------+------------+---------+---------+
 | participant | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +-------------+-----------+-----------+------------+---------+---------+
 | SPVM        |    330000 |     3     |          1 | 3.3e-09 |      20 |
 | Perl        |  10000000 |     0.099 |         31 | 8.4e-10 |      20 |
 +-------------+-----------+-----------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 BENCHMARK NOTES

Because SPVM needs to run code at CHECK phase, we need to run with e.g.:

 % PERL5OPT=-MSPVM=Examples::Sum bencher ...

And building this dist also needs similar workaround.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-SPVM>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-SPVM>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-SPVM>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
