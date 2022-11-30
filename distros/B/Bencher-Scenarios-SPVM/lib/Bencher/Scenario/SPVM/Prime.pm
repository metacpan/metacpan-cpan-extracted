package Bencher::Scenario::SPVM::Prime;

use 5.010001;
use strict;
use warnings;

use SPVM 'Examples::Prime';
# trap exception when SPVM_BUILD_DIR is not defined
BEGIN { if (defined $ENV{SPVM_BUILD_DIR}) { eval "use SPVM 'Examples::Prime_precompile'"; die if $@ } } ## no critic: BuiltinFunctions::ProhibitStringyEval

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-11-24'; # DATE
our $DIST = 'Bencher-Scenarios-SPVM'; # DIST
our $VERSION = '0.008'; # VERSION

our $scenario = {
    summary => 'Benchmark SPVM (check if number is prime)',
    modules => {
        'SPVM' => {version => '0.9662'},
        'SPVM::Examples' => {version=>'0.002'}, # to pull dependency
    },
    participants => [
        { name => 'Inline::C', code => sub { My::Prime::InlineC::is_prime(1_000_003) } },
        { name => 'Perl',      code => sub { My::Prime::Perl->is_prime(1_000_003) } },
        { name => 'SPVM',            code => sub { SPVM::Examples::Prime->is_prime(1_000_003) } },
        (defined $ENV{SPVM_BUILD_DIR} ? ({ name => 'SPVM_precompile', code => sub { SPVM::Examples::Prime_precompile->is_prime(1_000_003) } }) : ()),
    ],
};

package
    My::Prime::Perl;

sub is_prime {
    my $self = shift;
    my $num = shift;

    my $limit = $num - 1; # naive algorithm
    for my $i (2 .. $limit) {
        return 0 if $num % $i == 0;
    }
    1;
}

package
    My::Prime::InlineC;

use Inline C => <<'_';
int is_prime(int num) {
  int limit = num - 1; /* a naive algorithm */
  int i;
  for (i=2; i<=limit; i++) {
    if (num % i == 0) return 0;
  }
  return 1;
}
_

1;
# ABSTRACT: Benchmark SPVM (check if number is prime)

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::SPVM::Prime - Benchmark SPVM (check if number is prime)

=head1 VERSION

This document describes version 0.008 of Bencher::Scenario::SPVM::Prime (from Perl distribution Bencher-Scenarios-SPVM), released on 2022-11-24.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m SPVM::Prime

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<SPVM> 0.9662

L<SPVM::Examples> 0.004

=head1 BENCHMARK PARTICIPANTS

=over

=item * Inline::C (perl_code)



=item * Perl (perl_code)



=item * SPVM (perl_code)



=item * SPVM_precompile (perl_code)



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.34.0 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 20.04 >>, OS kernel: I<< Linux version 5.4.0-91-generic >>.

Benchmark with default options (C<< bencher -m SPVM::Prime >>):

 #table1#
 +-----------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant     | rate (/s) | time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-----------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | Perl            |      22.7 |    44.1   |                 0.00% |              1604.41% | 1.4e-05 |      20 |
 | SPVM            |      43.5 |    23     |                91.93% |               788.05% | 2.7e-06 |      20 |
 | SPVM_precompile |     343.2 |     2.914 |              1414.12% |                12.57% | 2.1e-07 |      20 |
 | Inline::C       |     386.3 |     2.589 |              1604.41% |                 0.00% | 2.1e-07 |      20 |
 +-----------------+-----------+-----------+-----------------------+-----------------------+---------+---------+


Formatted as L<Benchmark.pm|Benchmark> result:

          Rate      P     S   S_p   I:C 
  P     22.7/s     --  -47%  -93%  -94% 
  S     43.5/s    91%    --  -87%  -88% 
  S_p  343.2/s  1413%  689%    --  -11% 
  I:C  386.3/s  1603%  788%   12%    -- 
 
 Legends:
   I:C: participant=Inline::C
   P: participant=Perl
   S: participant=SPVM
   S_p: participant=SPVM_precompile

To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 BENCHMARK NOTES

In this case, SPVM offers ~2x speed-up and near the performance of C code with
precompilation.

My general impression on SPVM (Nov 2022, v0.9662): the parser is currently still
buggy (e.g. insignificant whitespace causing syntax error). The significant
speed-up and native compilation are nice features. If the language proves to be
convenient enough for Perl programmers, it might become a useful addition to
their toolbox.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-SPVM>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-SPVM>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022, 2017 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-SPVM>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
