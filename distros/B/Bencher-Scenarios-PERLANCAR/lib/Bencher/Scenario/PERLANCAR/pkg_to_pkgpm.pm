package Bencher::Scenario::PERLANCAR::pkg_to_pkgpm;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.06'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark some ways to convert Foo::Bar::Baz to Foo/Bar/Baz.pm',
    participants => [
        {
            name=>'method1',
            code_template=>'state $pkg = "Foo::Bar::Baz"; my $pkg_pm = $pkg; $pkg_pm =~ s!::!/!g; $pkg_pm .= ".pm"; $pkg_pm',
        },
        {
            name=>'method2',
            code_template=>'state $pkg = "Foo::Bar::Baz"; (my $pkg_pm = "$pkg.pm") =~ s!::!/!g; $pkg_pm',
        },
    ],
};

1;
# ABSTRACT: Benchmark some ways to convert Foo::Bar::Baz to Foo/Bar/Baz.pm

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::PERLANCAR::pkg_to_pkgpm - Benchmark some ways to convert Foo::Bar::Baz to Foo/Bar/Baz.pm

=head1 VERSION

This document describes version 0.06 of Bencher::Scenario::PERLANCAR::pkg_to_pkgpm (from Perl distribution Bencher-Scenarios-PERLANCAR), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m PERLANCAR::pkg_to_pkgpm

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARK PARTICIPANTS

=over

=item * method1 (perl_code)

Code template:

 state $pkg = "Foo::Bar::Baz"; my $pkg_pm = $pkg; $pkg_pm =~ s!::!/!g; $pkg_pm .= ".pm"; $pkg_pm



=item * method2 (perl_code)

Code template:

 state $pkg = "Foo::Bar::Baz"; (my $pkg_pm = "$pkg.pm") =~ s!::!/!g; $pkg_pm



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m PERLANCAR::pkg_to_pkgpm >>):

 #table1#
 +-------------+-----------+-----------+------------+---------+---------+
 | participant | rate (/s) | time (ns) | vs_slowest |  errors | samples |
 +-------------+-----------+-----------+------------+---------+---------+
 | method2     |   2100000 |       490 |          1 | 8.1e-10 |      21 |
 | method1     |   2100000 |       480 |          1 | 6.1e-10 |      24 |
 +-------------+-----------+-----------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 BENCHMARK NOTES

Practically indistinguishable performance-wise, so just pick the
shortest/clearest according to you.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-PERLANCAR>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-PERLANCAR>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-PERLANCAR>

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
