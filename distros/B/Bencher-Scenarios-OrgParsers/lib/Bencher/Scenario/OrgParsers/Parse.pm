package Bencher::Scenario::OrgParsers::Parse;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2019-12-30'; # DATE
our $DIST = 'Bencher-Scenarios-OrgParsers'; # DIST
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

use File::ShareDir::Tarball qw(dist_dir);

my $dist_dir = dist_dir("Org-Examples");

our $scenario = {
    summary => 'Benchmark parsing',
    participants => [
        {module=>'Org::Parser'      , code_template=>'Org::Parser      ->new->parse_file(<path>)'},
        {module=>'Org::Parser::Tiny', code_template=>'Org::Parser::Tiny->new->parse_file(<path>)'},
    ],
    datasets => [
        {name=>'various.org'      , args=>{path=>"$dist_dir/examples/various.org"}},
        {name=>'1000headlines.org', args=>{path=>"$dist_dir/examples/1000headlines.org"}},
    ],
};

1;
# ABSTRACT: Benchmark parsing

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::OrgParsers::Parse - Benchmark parsing

=head1 VERSION

This document describes version 0.001 of Bencher::Scenario::OrgParsers::Parse (from Perl distribution Bencher-Scenarios-OrgParsers), released on 2020-12-30.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m OrgParsers::Parse

To run module startup overhead benchmark:

 % bencher --module-startup -m OrgParsers::Parse

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

Code template:

 Org::Parser      ->new->parse_file(<path>)



=item * Org::Parser::Tiny (perl_code)

Code template:

 Org::Parser::Tiny->new->parse_file(<path>)



=back

=head1 BENCHMARK DATASETS

=over

=item * various.org

=item * 1000headlines.org

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) i7-4770 CPU @ 3.40GHz (4 cores) >>, OS: I<< GNU/Linux LinuxMint version 18.2 >>, OS kernel: I<< Linux version 4.8.0-53-generic >>.

Benchmark with default options (C<< bencher -m OrgParsers::Parse >>):

 #table1#
 +-------------------+-------------------+-----------+-----------+------------+----------+---------+
 | participant       | dataset           | rate (/s) | time (ms) | vs_slowest |  errors  | samples |
 +-------------------+-------------------+-----------+-----------+------------+----------+---------+
 | Org::Parser       | 1000headlines.org |      11   |    89     |        1   |   0.0001 |      20 |
 | Org::Parser::Tiny | 1000headlines.org |      16.9 |    59.1   |        1.5 | 3.2e-05  |      20 |
 | Org::Parser       | various.org       |     589   |     1.7   |       52.2 | 1.3e-06  |      20 |
 | Org::Parser::Tiny | various.org       |   12000   |     0.083 |     1100   | 2.1e-07  |      21 |
 +-------------------+-------------------+-----------+-----------+------------+----------+---------+


Benchmark module startup overhead (C<< bencher -m OrgParsers::Parse --module-startup >>):

 #table2#
 +---------------------+-----------+------------------------+------------+---------+---------+
 | participant         | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +---------------------+-----------+------------------------+------------+---------+---------+
 | Org::Parser         |      31.1 |                     27 |        1   | 2.9e-05 |      20 |
 | Org::Parser::Tiny   |       6.1 |                      2 |        5.1 |   1e-05 |      20 |
 | perl -e1 (baseline) |       4.1 |                      0 |        7.5 | 8.1e-06 |      20 |
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

=head1 SEE ALSO

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
