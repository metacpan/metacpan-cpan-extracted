package Bencher::Scenario::HTTPTinyPlugin::request_overhead;

our $DATE = '2019-05-04'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => "Benchmark overhead of request()",
    participants => [
        {
            name => 'HTTP::Tiny',
            module => 'HTTP::Tiny',
            code_template => 'state $http = HTTP::Tiny->new; $http->request(GET=>"x",{})',
        },
        {
            name => 'HTTP::Tiny::Plugin',
            module => 'HTTP::Tiny::Plugin',
            code_template => 'state $http = HTTP::Tiny::Plugin->new; $http->request(GET=>"x",{})',
        },
    ],
};

1;
# ABSTRACT: Benchmark overhead of request()

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::HTTPTinyPlugin::request_overhead - Benchmark overhead of request()

=head1 VERSION

This document describes version 0.001 of Bencher::Scenario::HTTPTinyPlugin::request_overhead (from Perl distribution Bencher-Scenarios-HTTPTinyPlugin), released on 2019-05-04.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m HTTPTinyPlugin::request_overhead

To run module startup overhead benchmark:

 % bencher --module-startup -m HTTPTinyPlugin::request_overhead

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<HTTP::Tiny> 0.070

L<HTTP::Tiny::Plugin> 0.002

=head1 BENCHMARK PARTICIPANTS

=over

=item * HTTP::Tiny (perl_code)

Code template:

 state $http = HTTP::Tiny->new; $http->request(GET=>"x",{})



=item * HTTP::Tiny::Plugin (perl_code)

Code template:

 state $http = HTTP::Tiny::Plugin->new; $http->request(GET=>"x",{})



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.26.1 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 18.3 >>, OS kernel: I<< Linux version 4.10.0-38-generic >>.

Benchmark with default options (C<< bencher -m HTTPTinyPlugin::request_overhead >>):

 #table1#
 +--------------------+-----------+-----------+------------+---------+---------+
 | participant        | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +--------------------+-----------+-----------+------------+---------+---------+
 | HTTP::Tiny::Plugin |    167000 |      5.99 |        1   | 4.6e-09 |      24 |
 | HTTP::Tiny         |    270000 |      3.7  |        1.6 |   5e-09 |      20 |
 +--------------------+-----------+-----------+------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m HTTPTinyPlugin::request_overhead --module-startup >>):

 #table2#
 +---------------------+-----------+------------------------+------------+-----------+---------+
 | participant         | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors   | samples |
 +---------------------+-----------+------------------------+------------+-----------+---------+
 | HTTP::Tiny::Plugin  |      36   |                   29.8 |        1   | 8.5e-05   |      20 |
 | HTTP::Tiny          |      36   |                   29.8 |        1   |   0.00016 |      20 |
 | perl -e1 (baseline) |       6.2 |                    0   |        5.9 | 2.9e-05   |      20 |
 +---------------------+-----------+------------------------+------------+-----------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-HTTPTinyPlugin>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-HTTPTinyPlugin>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-HTTPTinyPlugin>

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
