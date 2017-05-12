package Bencher::Scenario::IPManipulation::ValidateIPv4;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.002'; # VERSION

our $scenario = {
    summary => 'Benchmark validation of IPv4 address string',
    participants => [
        {
            module => 'NetAddr::IP',
            code_template => 'NetAddr::IP->new(<str>) ? 1:0',
        },
        {
            module => 'NetObj::IPv4Address',
            code_template => 'NetObj::IPv4Address::is_valid(<str>)',
        },
        {
            module => 'Net::CIDR',
            code_template => 'Net::CIDR::cidrvalidate(<str>) ? 1:0',
        },
    ],
    datasets => [
        {args=>{str=>'x'}},
        {args=>{str=>'300.0.0.0'}},
        {args=>{str=>'127.0.0.2'}},
    ],
};

1;
# ABSTRACT: Benchmark validation of IPv4 address string

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::IPManipulation::ValidateIPv4 - Benchmark validation of IPv4 address string

=head1 VERSION

This document describes version 0.002 of Bencher::Scenario::IPManipulation::ValidateIPv4 (from Perl distribution Bencher-Scenarios-IPManipulation), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m IPManipulation::ValidateIPv4

To run module startup overhead benchmark:

 % bencher --module-startup -m IPManipulation::ValidateIPv4

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<NetAddr::IP>  4.079

L<NetObj::IPv4Address> 1.0

L<Net::CIDR> 0.18

=head1 BENCHMARK PARTICIPANTS

=over

=item * NetAddr::IP (perl_code)

Code template:

 NetAddr::IP->new(<str>) ? 1:0



=item * NetObj::IPv4Address (perl_code)

Code template:

 NetObj::IPv4Address::is_valid(<str>)



=item * Net::CIDR (perl_code)

Code template:

 Net::CIDR::cidrvalidate(<str>) ? 1:0



=back

=head1 BENCHMARK DATASETS

=over

=item * x

=item * 300.0.0.0

=item * 127.0.0.2

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m IPManipulation::ValidateIPv4 >>):

 #table1#
 {dataset=>"127.0.0.2"}
 +---------------------+-----------+-----------+------------+---------+---------+
 | participant         | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +---------------------+-----------+-----------+------------+---------+---------+
 | Net::CIDR           |     16000 |     63    |        1   |   1e-07 |      21 |
 | NetAddr::IP         |     42000 |     24    |        2.6 | 2.5e-08 |      22 |
 | NetObj::IPv4Address |    331000 |      3.02 |       20.9 | 7.9e-10 |      22 |
 +---------------------+-----------+-----------+------------+---------+---------+

 #table2#
 {dataset=>"300.0.0.0"}
 +---------------------+-----------+-----------+------------+---------+---------+
 | participant         | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +---------------------+-----------+-----------+------------+---------+---------+
 | NetAddr::IP         |    160000 |       6.4 |        1   | 1.5e-08 |      20 |
 | NetObj::IPv4Address |    520000 |       1.9 |        3.3 | 3.3e-09 |      20 |
 | Net::CIDR           |    550000 |       1.8 |        3.5 | 3.3e-09 |      20 |
 +---------------------+-----------+-----------+------------+---------+---------+

 #table3#
 {dataset=>"x"}
 +---------------------+-----------+-----------+------------+---------+---------+
 | participant         | rate (/s) | time (ms) | vs_slowest |  errors | samples |
 +---------------------+-----------+-----------+------------+---------+---------+
 | NetAddr::IP         |       280 |   3.5     |          1 | 1.6e-05 |      20 |
 | NetObj::IPv4Address |    913000 |   0.0011  |       3230 | 4.2e-10 |      20 |
 | Net::CIDR           |   1850000 |   0.00054 |       6540 | 1.7e-10 |      30 |
 +---------------------+-----------+-----------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-IPManipulation>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-IPManipulation>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-IPManipulation>

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
