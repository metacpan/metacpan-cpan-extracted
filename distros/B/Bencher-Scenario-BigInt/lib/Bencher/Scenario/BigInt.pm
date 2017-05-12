package Bencher::Scenario::BigInt;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.03'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark arbitrary size integer arithmetics',
    participants => [
        {
            name => '1k-Math::BigInt',
            module=>'Math::BigInt',
            code_template => 'my $val; for (1..1000) { $val = Math::BigInt->new(<num1>)+Math::BigInt->new(<num2>) + Math::BigInt->new(<num1>) * Math::BigInt->new(<num2>) } "$val"'
        },
        {
            name => '1k-Math::GMP',
            module=>'Math::GMP',
            code_template => 'my $val; for (1..1000) { $val = Math::GMP->new(<num1>)+Math::GMP->new(<num2>) + Math::GMP->new(<num1>) * Math::GMP->new(<num2>) } "$val"'
        },
        {
            name => '1k-native',
            tags => ['no-big'],
            code_template => 'my $val; for (1..1000) { $val = <num1>+<num2> + <num1> * <num2> } $val'
        },
    ],
    datasets => [
        {name=>'1e1', args=>{num1=>"10", num2=>"20"}, result=>"230" },
        {name=>'1e100', args=>{num1=>"1".("0"x100), num2=>"2".("0"x100)}, result=>("2".("0"x99)."3".("0"x100)), exclude_participant_tags=>['no-big'] },
    ],
};

1;
# ABSTRACT: Benchmark arbitrary size integer arithmetics

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::BigInt - Benchmark arbitrary size integer arithmetics

=head1 VERSION

This document describes version 0.03 of Bencher::Scenario::BigInt (from Perl distribution Bencher-Scenario-BigInt), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m BigInt

To run module startup overhead benchmark:

 % bencher --module-startup -m BigInt

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Math::BigInt> 1.999808

L<Math::GMP> 2.13

=head1 BENCHMARK PARTICIPANTS

=over

=item * 1k-Math::BigInt (perl_code)

Code template:

 my $val; for (1..1000) { $val = Math::BigInt->new(<num1>)+Math::BigInt->new(<num2>) + Math::BigInt->new(<num1>) * Math::BigInt->new(<num2>) } "$val"



=item * 1k-Math::GMP (perl_code)

Code template:

 my $val; for (1..1000) { $val = Math::GMP->new(<num1>)+Math::GMP->new(<num2>) + Math::GMP->new(<num1>) * Math::GMP->new(<num2>) } "$val"



=item * 1k-native (perl_code) [no-big]

Code template:

 my $val; for (1..1000) { $val = <num1>+<num2> + <num1> * <num2> } $val



=back

=head1 BENCHMARK DATASETS

=over

=item * 1e1

=item * 1e100

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m BigInt >>):

 #table1#
 +-----------------+---------+-----------+-----------+------------+---------+---------+
 | participant     | dataset | rate (/s) | time (ms) | vs_slowest |  errors | samples |
 +-----------------+---------+-----------+-----------+------------+---------+---------+
 | 1k-Math::BigInt | 1e100   |      14.3 |  70.2     |        1   |   4e-05 |      20 |
 | 1k-Math::BigInt | 1e1     |      26   |  38       |        1.8 | 5.3e-05 |      20 |
 | 1k-Math::GMP    | 1e100   |     110   |   9       |        7.8 | 1.2e-05 |      20 |
 | 1k-Math::GMP    | 1e1     |     160   |   6.2     |       11   | 7.8e-06 |      20 |
 | 1k-native       | 1e1     |   28827   |   0.03469 |     2022.3 | 4.6e-11 |      20 |
 +-----------------+---------+-----------+-----------+------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m BigInt --module-startup >>):

 #table2#
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | participant         | proc_private_dirty_size (MB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | Math::BigInt        | 1.8                          | 5.2                | 21             |      33   |                   27.3 |        1   | 6.7e-05 |      20 |
 | Math::GMP           | 0.82                         | 4.1                | 16             |      15   |                    9.3 |        2.2 | 1.7e-05 |      21 |
 | perl -e1 (baseline) | 3.7                          | 7                  | 19             |       5.7 |                    0   |        5.7 | 1.4e-05 |      20 |
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-BigInt>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-BigInt>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-BigInt>

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
