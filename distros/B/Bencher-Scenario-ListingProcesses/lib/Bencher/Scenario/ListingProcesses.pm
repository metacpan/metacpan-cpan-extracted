package Bencher::Scenario::ListingProcesses;

our $DATE = '2017-11-19'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark listing OS processes',

    participants => [
        {name => 'Proc::ProcessTable', module => 'Proc::ProcessTable', code_template => 'Proc::ProcessTable->new->table'},
        {name => 'Proc::ProcessTable+cache_ttys', module => 'Proc::ProcessTable', code_template => 'Proc::ProcessTable->new(cache_ttys=>1)->table'},
        {name => 'ps auwx', code_template => '`ps auwx`'},
        {name => 'Proc::ProcessTableLight', fcall_template => 'Proc::ProcessTableLight::process_table()'},
        {name => 'Linux::Info::Processes', module => 'Linux::Info::Processes', code_template => 'my $lip = Linux::Info::Processes->new; $lip->init; $lip->get'},
        {name => 'Linux::Info::Processes+cache-init', module => 'Linux::Info::Processes', code_template => 'state $lip = do { my $lip = Linux::Info::Processes->new; $lip->init; $lip }; $lip->get'},
    ],
};

1;
# ABSTRACT: Benchmark listing OS processes

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::ListingProcesses - Benchmark listing OS processes

=head1 VERSION

This document describes version 0.001 of Bencher::Scenario::ListingProcesses (from Perl distribution Bencher-Scenario-ListingProcesses), released on 2017-11-19.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m ListingProcesses

To run module startup overhead benchmark:

 % bencher --module-startup -m ListingProcesses

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Proc::ProcessTable> 0.53

L<Proc::ProcessTableLight> 0.01

L<Linux::Info::Processes> 1.3

=head1 BENCHMARK PARTICIPANTS

=over

=item * Proc::ProcessTable (perl_code)

Code template:

 Proc::ProcessTable->new->table



=item * Proc::ProcessTable+cache_ttys (perl_code)

Code template:

 Proc::ProcessTable->new(cache_ttys=>1)->table



=item * ps auwx (perl_code)

Code template:

 `ps auwx`



=item * Proc::ProcessTableLight (perl_code)

Function call template:

 Proc::ProcessTableLight::process_table()



=item * Linux::Info::Processes (perl_code)

Code template:

 my $lip = Linux::Info::Processes->new; $lip->init; $lip->get



=item * Linux::Info::Processes+cache-init (perl_code)

Code template:

 state $lip = do { my $lip = Linux::Info::Processes->new; $lip->init; $lip }; $lip->get



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 18.2 >>, OS kernel: I<< Linux version 4.8.0-53-generic >>.

Benchmark with default options (C<< bencher -m ListingProcesses >>):

 #table1#
 +-----------------------------------+-----------+-----------+------------+-----------+---------+
 | participant                       | rate (/s) | time (ms) | vs_slowest |  errors   | samples |
 +-----------------------------------+-----------+-----------+------------+-----------+---------+
 | Linux::Info::Processes            |        10 |      70   |        1   |   0.00093 |      22 |
 | Linux::Info::Processes+cache-init |        14 |      69   |        1.1 |   0.00025 |      20 |
 | Proc::ProcessTableLight           |        65 |      15   |        4.8 | 8.1e-05   |      21 |
 | ps auwx                           |        80 |      13   |        5.9 | 5.8e-05   |      20 |
 | Proc::ProcessTable                |        85 |      12   |        6.3 | 2.1e-05   |      20 |
 | Proc::ProcessTable+cache_ttys     |       110 |       9.4 |        7.9 | 2.8e-05   |      20 |
 +-----------------------------------+-----------+-----------+------------+-----------+---------+


Benchmark module startup overhead (C<< bencher -m ListingProcesses --module-startup >>):

 #table2#
 +-------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+-----------+---------+
 | participant             | proc_private_dirty_size (MB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors   | samples |
 +-------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+-----------+---------+
 | Proc::ProcessTable      | 3.2                          | 6.8                | 27             |      33   |                   27.1 |        1   |   0.00032 |      20 |
 | Linux::Info::Processes  | 0.92                         | 4.5                | 16             |      18   |                   12.1 |        1.9 | 5.8e-05   |      20 |
 | Proc::ProcessTableLight | 0.83                         | 4.2                | 16             |       7.7 |                    1.8 |        4.3 | 7.2e-05   |      20 |
 | perl -e1 (baseline)     | 3.2                          | 6.9                | 27             |       5.9 |                    0   |        5.7 | 1.7e-05   |      20 |
 +-------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+-----------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-ListingProcesses>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-ListingProcesses>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-ListingProcesses>

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
