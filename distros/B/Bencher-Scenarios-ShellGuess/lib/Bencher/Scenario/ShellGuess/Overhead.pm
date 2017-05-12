package Bencher::Scenario::ShellGuess::Overhead;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark the startup overhead of guessing shell',
    participants => [
        {
            name => 'load Shell::Guess',
            perl_cmdline => ['-MShell::Guess', '-e1'],
        },
        {
            name => 'load Shell::Guess + running_shell',
            perl_cmdline => ['-MShell::Guess', '-e', '$sh = Shell::Guess->running_shell'],
        },
        {
            name => 'perl (baseline)',
            perl_cmdline => ['-e1'],
        },
    ],
};

1;
# ABSTRACT: Benchmark the startup overhead of guessing shell

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::ShellGuess::Overhead - Benchmark the startup overhead of guessing shell

=head1 VERSION

This document describes version 0.002 of Bencher::Scenario::ShellGuess::Overhead (from Perl distribution Bencher-Scenarios-ShellGuess), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m ShellGuess::Overhead

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARK PARTICIPANTS

=over

=item * load Shell::Guess (command)



=item * load Shell::Guess + running_shell (command)



=item * perl (baseline) (command)



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) i5-2400 CPU @ 3.10GHz (4 cores) >>, OS: I<< GNU/Linux Debian version 8.0 >>, OS kernel: I<< Linux version 3.16.0-4-amd64 >>.

Under bash:

 #table1#
 +-----------------------------------+-----------+-----------+------------+---------+---------+
 | participant                       | rate (/s) | time (ms) | vs_slowest |  errors | samples |
 +-----------------------------------+-----------+-----------+------------+---------+---------+
 | load Shell::Guess + running_shell |        98 |      10   |        1   | 3.8e-05 |      21 |
 | load Shell::Guess                 |       100 |       9.7 |        1.1 |   3e-05 |      20 |
 | perl (baseline)                   |       460 |       2.2 |        4.7 | 1.1e-05 |      20 |
 +-----------------------------------+-----------+-----------+------------+---------+---------+


Under fish:

 #table2#
 +-----------------------------------+-----------+-----------+------------+---------+---------+
 | participant                       | rate (/s) | time (ms) | vs_slowest |  errors | samples |
 +-----------------------------------+-----------+-----------+------------+---------+---------+
 | load Shell::Guess + running_shell |        99 |      10   |        1   | 4.6e-05 |      21 |
 | load Shell::Guess                 |       100 |       9.7 |        1   | 3.4e-05 |      20 |
 | perl (baseline)                   |       550 |       1.8 |        5.5 | 6.6e-06 |      21 |
 +-----------------------------------+-----------+-----------+------------+---------+---------+


Under tcsh ('c'):

 #table3#
 +-----------------------------------+-----------+-----------+------------+---------+---------+
 | participant                       | rate (/s) | time (ms) | vs_slowest |  errors | samples |
 +-----------------------------------+-----------+-----------+------------+---------+---------+
 | load Shell::Guess + running_shell |       100 |      10   |          1 | 4.6e-05 |      20 |
 | load Shell::Guess                 |       100 |       9.7 |          1 | 4.7e-05 |      20 |
 | perl (baseline)                   |       500 |       2   |          5 | 4.7e-05 |      20 |
 +-----------------------------------+-----------+-----------+------------+---------+---------+


Under zsh ('z'):

 #table4#
 +-----------------------------------+-----------+-----------+------------+-----------+---------+
 | participant                       | rate (/s) | time (ms) | vs_slowest |  errors   | samples |
 +-----------------------------------+-----------+-----------+------------+-----------+---------+
 | load Shell::Guess                 |       100 |        10 |          1 |   0.00011 |      20 |
 | load Shell::Guess + running_shell |        99 |        10 |          1 |   5e-05   |      20 |
 | perl (baseline)                   |       500 |         2 |          5 | 2.6e-05   |      20 |
 +-----------------------------------+-----------+-----------+------------+-----------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-ShellGuess>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-ShellGuess>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-ShellGuess>

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
