package Bencher::Scenario::OrgParsers::Startup;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2019-12-30'; # DATE
our $DIST = 'Bencher-Scenarios-OrgParsers'; # DIST
our $VERSION = '0.001'; # VERSION

our $scenario = {
    summary => 'Benchmark startup overhead',
    module_startup => 1,
    participants => [
        {module=>'Org::Parser'},
        {module=>'Org::Parser::Tiny'},
    ],
};

1;
# ABSTRACT: Benchmark startup overhead

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::OrgParsers::Startup - Benchmark startup overhead

=head1 VERSION

This document describes version 0.001 of Bencher::Scenario::OrgParsers::Startup (from Perl distribution Bencher-Scenarios-OrgParsers), released on 2020-12-30.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m OrgParsers::Startup

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Org::Parser> 0.550

L<Org::Parser::Tiny> 0.001

=head1 BENCHMARK PARTICIPANTS

=over

=item * Org::Parser (perl_code)

L<Org::Parser>



=item * Org::Parser::Tiny (perl_code)

L<Org::Parser::Tiny>



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) i7-4770 CPU @ 3.40GHz (4 cores) >>, OS: I<< GNU/Linux LinuxMint version 18.2 >>, OS kernel: I<< Linux version 4.8.0-53-generic >>.

Benchmark with default options (C<< bencher -m OrgParsers::Startup >>):

 #table1#
 +---------------------+-----------+------------------------+------------+---------+---------+
 | participant         | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +---------------------+-----------+------------------------+------------+---------+---------+
 | Org::Parser         |      31.4 |                   27.3 |        1   | 2.9e-05 |      20 |
 | Org::Parser::Tiny   |       6.1 |                    2   |        5.1 | 1.3e-05 |      20 |
 | perl -e1 (baseline) |       4.1 |                    0   |        7.6 |   6e-06 |      20 |
 +---------------------+-----------+------------------------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-OrgParsers>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-OrgParsers>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-OrgParsers>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
