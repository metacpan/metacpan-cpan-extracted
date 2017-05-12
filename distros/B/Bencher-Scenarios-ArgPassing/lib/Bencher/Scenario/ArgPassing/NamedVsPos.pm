package Bencher::Scenario::ArgPassing::NamedVsPos;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.003'; # VERSION

use 5.010001;
use strict;
use warnings;

sub named {
    my %args = @_;
}

sub positional {
    #my @args = @_;
}

our $scenario = {
    summary => 'Benchmark named vs positional argument passing',
    modules => {
    },
    participants => [
        {
            name => 'named',
            fcall_template => __PACKAGE__ . '::named(@{<named>})',
        },
        {
            name => 'positional',
            fcall_template => __PACKAGE__ . '::positional(@{<pos>})',
        },
    ],
    datasets => [
        {name => 'args=1' , args=>{named=>[a=>1], pos=>[1]}},
        {name => 'args=5' , args=>{named=>[a=>1,b=>2,c=>3,d=>4,e=>5], pos=>[1,2,3,4,5]}},
        {name => 'args=10', args=>{named=>[a=>1,b=>2,c=>3,d=>4,e=>5,f=>6,g=>7,h=>8,i=>9,j=>10], pos=>[1,2,3,4,5,6,7,8,9,10]}},
    ],
};

1;
# ABSTRACT: Benchmark named vs positional argument passing

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::ArgPassing::NamedVsPos - Benchmark named vs positional argument passing

=head1 VERSION

This document describes version 0.003 of Bencher::Scenario::ArgPassing::NamedVsPos (from Perl distribution Bencher-Scenarios-ArgPassing), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m ArgPassing::NamedVsPos

To run module startup overhead benchmark:

 % bencher --module-startup -m ArgPassing::NamedVsPos

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Bencher::Scenario::ArgPassing::NamedVsPos>

=head1 BENCHMARK PARTICIPANTS

=over

=item * named (perl_code)

Function call template:

 Bencher::Scenario::ArgPassing::NamedVsPos::named(@{<named>})



=item * positional (perl_code)

Function call template:

 Bencher::Scenario::ArgPassing::NamedVsPos::positional(@{<pos>})



=back

=head1 BENCHMARK DATASETS

=over

=item * args=1

=item * args=5

=item * args=10

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m ArgPassing::NamedVsPos >>):

 #table1#
 +-------------+---------+-----------+-----------+------------+---------+---------+
 | participant | dataset | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +-------------+---------+-----------+-----------+------------+---------+---------+
 | named       | args=10 |    554247 |  1.80425  |    1       |   0     |      20 |
 | named       | args=5  |    978110 |  1.0224   |    1.7647  |   1e-11 |      20 |
 | named       | args=1  |   2300000 |  0.44     |    4.1     | 8.3e-10 |      20 |
 | positional  | args=10 |   2705570 |  0.369609 |    4.88152 |   0     |      20 |
 | positional  | args=5  |   3700000 |  0.27     |    6.7     | 4.2e-10 |      20 |
 | positional  | args=1  |   5300000 |  0.19     |    9.6     | 3.1e-10 |      20 |
 +-------------+---------+-----------+-----------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-ArgPassing>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-ArgPassing>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-ArgPassing>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
