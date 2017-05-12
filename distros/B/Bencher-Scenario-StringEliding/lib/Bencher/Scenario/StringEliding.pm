package Bencher::Scenario::StringEliding;

our $DATE = '2017-01-28'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark string eliding',
    participants => [
        {fcall_template => 'String::Elide::Parts::elide(<str>, <len>)'},
        {fcall_template => 'String::Truncate::elide(<str>, <len>)'},
        {fcall_template => 'Text::Elide::elide(<str>, <len>)'},
    ],
    datasets => [
        {name=>'strlen=80,len=60', args=>{str=>'a'x80, len=>60}},
    ],
};

1;
# ABSTRACT: Benchmark string eliding

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::StringEliding - Benchmark string eliding

=head1 VERSION

This document describes version 0.001 of Bencher::Scenario::StringEliding (from Perl distribution Bencher-Scenario-StringEliding), released on 2017-01-28.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m StringEliding

To run module startup overhead benchmark:

 % bencher --module-startup -m StringEliding

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<String::Elide::Parts> 0.03

L<String::Truncate> 1.100602

L<Text::Elide> 0.0.3

=head1 BENCHMARK PARTICIPANTS

=over

=item * String::Elide::Parts::elide (perl_code)

Function call template:

 String::Elide::Parts::elide(<str>, <len>)



=item * String::Truncate::elide (perl_code)

Function call template:

 String::Truncate::elide(<str>, <len>)



=item * Text::Elide::elide (perl_code)

Function call template:

 Text::Elide::elide(<str>, <len>)



=back

=head1 BENCHMARK DATASETS

=over

=item * strlen=80,len=60

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) i7-4770 CPU @ 3.40GHz (4 cores) >>, OS: I<< GNU/Linux Debian version 8.5 >>, OS kernel: I<< Linux version 3.16.0-4-amd64 >>.

Benchmark with C<< bencher -m StringEliding --include-path archive/String-Elide-Parts-0.01/lib --include-path archive/String-Elide-Parts-0.03/lib --multimodver String::Elide::Parts >>:

 #table1#
 +-----------------------------+--------+-----------+-----------+------------+---------+---------+
 | participant                 | modver | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +-----------------------------+--------+-----------+-----------+------------+---------+---------+
 | String::Elide::Parts::elide | 0.03   |    200000 |    5      |     1      | 6.7e-09 |      20 |
 | String::Elide::Parts::elide | 0.01   |    260000 |    3.8    |     1.3    | 6.7e-09 |      20 |
 | Text::Elide::elide          |        |    269820 |    3.7062 |     1.3381 | 5.1e-12 |      21 |
 | String::Truncate::elide     |        |   1031600 |    0.9694 |     5.1159 | 5.2e-12 |      25 |
 +-----------------------------+--------+-----------+-----------+------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m StringEliding --module-startup >>):

 #table2#
 +----------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | participant          | proc_private_dirty_size (MB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +----------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | String::Truncate     | 1.8                          | 5.3                | 23             |     14    |                  11.39 |       1    | 4.4e-05 |      20 |
 | Text::Elide          | 0.82                         | 4.1                | 20             |     11    |                   8.39 |       1.4  | 3.1e-05 |      20 |
 | String::Elide::Parts | 2.5                          | 6                  | 26             |      5.1  |                   2.49 |       2.9  | 1.3e-05 |      20 |
 | perl -e1 (baseline)  | 0.98                         | 4.37               | 20.1           |      2.61 |                   0    |       5.55 | 2.2e-06 |      20 |
 +----------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-StringEliding>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-StringEliding>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-StringEliding>

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
