package Bencher::Scenario::Digest;

our $DATE = '2017-03-07'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

$main::data1M = join("", map {chr(256*rand)} 1..(1024*1024));

our $scenario = {
    summary => 'Benchmark various digest algorithms',
    participants => [
        {
            name   => 'md5',
            module => 'Digest::MD5',
            code_template => 'my $ctx = Digest::MD5->new; $ctx->add($main::data1M) for 1..<size>; $ctx->hexdigest',
        },
        {
            name   => 'sha1',
            module => 'Digest::SHA',
            code_template => 'my $ctx = Digest::SHA->new(1); $ctx->add($main::data1M) for 1..<size>; $ctx->hexdigest',
        },
        {
            name   => 'sha256',
            module => 'Digest::SHA',
            code_template => 'my $ctx = Digest::SHA->new(256); $ctx->add($main::data1M) for 1..<size>; $ctx->hexdigest',
        },
        {
            name   => 'sha512',
            module => 'Digest::SHA',
            code_template => 'my $ctx = Digest::SHA->new(512); $ctx->add($main::data1M) for 1..<size>; $ctx->hexdigest',
        },
    ],
    precision => 6,

    datasets => [
        {name=>'10M', args=>{size=>10}},
    ],
};

1;
# ABSTRACT: Benchmark various digest algorithms

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::Digest - Benchmark various digest algorithms

=head1 VERSION

This document describes version 0.001 of Bencher::Scenario::Digest (from Perl distribution Bencher-Scenario-Digest), released on 2017-03-07.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m Digest

To run module startup overhead benchmark:

 % bencher --module-startup -m Digest

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Digest::MD5> 2.54

L<Digest::SHA> 5.95

=head1 BENCHMARK PARTICIPANTS

=over

=item * md5 (perl_code)

Code template:

 my $ctx = Digest::MD5->new; $ctx->add($main::data1M) for 1..<size>; $ctx->hexdigest



=item * sha1 (perl_code)

Code template:

 my $ctx = Digest::SHA->new(1); $ctx->add($main::data1M) for 1..<size>; $ctx->hexdigest



=item * sha256 (perl_code)

Code template:

 my $ctx = Digest::SHA->new(256); $ctx->add($main::data1M) for 1..<size>; $ctx->hexdigest



=item * sha512 (perl_code)

Code template:

 my $ctx = Digest::SHA->new(512); $ctx->add($main::data1M) for 1..<size>; $ctx->hexdigest



=back

=head1 BENCHMARK DATASETS

=over

=item * 10M

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m Digest >>):

 #table1#
 +-------------+-----------+-----------+------------+-----------+---------+
 | participant | rate (/s) | time (ms) | vs_slowest |  errors   | samples |
 +-------------+-----------+-----------+------------+-----------+---------+
 | sha256      |      14.3 |      69.7 |        1   | 1.3e-05   |       6 |
 | sha512      |      20   |      50   |        1.4 |   0.0001  |       6 |
 | sha1        |      26   |      39   |        1.8 | 7.6e-05   |       6 |
 | md5         |      40   |      30   |        3   |   0.00027 |       7 |
 +-------------+-----------+-----------+------------+-----------+---------+


Benchmark module startup overhead (C<< bencher -m Digest --module-startup >>):

 #table2#
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | participant         | proc_private_dirty_size (MB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | Digest::SHA         | 1.5                          | 4.9                | 21             |      18   |                    8.8 |        1   | 8.6e-05 |       6 |
 | Digest::MD5         | 1.51                         | 4.88               | 20.7           |      13.7 |                    4.5 |        1.3 | 2.9e-06 |       6 |
 | perl -e1 (baseline) | 1.1                          | 4.4                | 18             |       9.2 |                    0   |        1.9 |   2e-05 |       6 |
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 BENCHMARK NOTES

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-Digest>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-Digest>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-Digest>

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
