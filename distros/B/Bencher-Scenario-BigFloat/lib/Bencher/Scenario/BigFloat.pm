package Bencher::Scenario::BigFloat;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.03'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark arbitrary size floating point arithmetics',
    participants => [
        {
            name => '1k-Math::BigFloat',
            module=>'Math::BigFloat',
            code_template => 'my $val; for (1..1000) { $val = Math::BigFloat->new(<num1>)+Math::BigFloat->new(<num2>) + Math::BigFloat->new(<num1>) * Math::BigFloat->new(<num2>) } "$val"'
        },
        {
            name => '1k-native',
            tags => ['no-big'],
            code_template => 'my $val; for (1..1000) { $val = <num1>+<num2> + <num1> * <num2> } $val'
        },
    ],
    datasets => [
        {name=>'0dec_digits', args=>{num1=>"10", num2=>"20"}, result=>"230" },
        {name=>'100dec_digits', args=>{num1=>"1.".("12"x50),num2=>"2"}, result=>"5.".("36"x50), exclude_participant_tags=>['no-big'] },
    ],
};

1;
# ABSTRACT: Benchmark arbitrary size floating point arithmetics

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::BigFloat - Benchmark arbitrary size floating point arithmetics

=head1 VERSION

This document describes version 0.03 of Bencher::Scenario::BigFloat (from Perl distribution Bencher-Scenario-BigFloat), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m BigFloat

To run module startup overhead benchmark:

 % bencher --module-startup -m BigFloat

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Math::BigFloat> 1.999808

=head1 BENCHMARK PARTICIPANTS

=over

=item * 1k-Math::BigFloat (perl_code)

Code template:

 my $val; for (1..1000) { $val = Math::BigFloat->new(<num1>)+Math::BigFloat->new(<num2>) + Math::BigFloat->new(<num1>) * Math::BigFloat->new(<num2>) } "$val"



=item * 1k-native (perl_code) [no-big]

Code template:

 my $val; for (1..1000) { $val = <num1>+<num2> + <num1> * <num2> } $val



=back

=head1 BENCHMARK DATASETS

=over

=item * 0dec_digits

=item * 100dec_digits

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m BigFloat >>):

 #table1#
 +-------------------+---------------+-----------+-------------+------------+-----------+---------+
 | participant       | dataset       | rate (/s) | time (ms)   | vs_slowest |  errors   | samples |
 +-------------------+---------------+-----------+-------------+------------+-----------+---------+
 | 1k-Math::BigFloat | 100dec_digits |      5.6  | 180         |       1    |   0.00028 |      21 |
 | 1k-Math::BigFloat | 0dec_digits   |      6.54 | 153         |       1.17 |   0.00011 |      21 |
 | 1k-native         | 0dec_digits   |  28828.2  |   0.0346883 |    5145.26 | 1.1e-11   |      20 |
 +-------------------+---------------+-----------+-------------+------------+-----------+---------+


Benchmark module startup overhead (C<< bencher -m BigFloat --module-startup >>):

 #table2#
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+-----------+---------+
 | participant         | proc_private_dirty_size (MB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors   | samples |
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+-----------+---------+
 | Math::BigFloat      | 0.82                         | 4.1                | 16             |      46   |                   40.3 |          1 |   0.00012 |      21 |
 | perl -e1 (baseline) | 6.3                          | 9.9                | 21             |       5.7 |                    0   |          8 | 1.3e-05   |      20 |
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+-----------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-BigFloat>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-BigFloat>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-BigFloat>

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
