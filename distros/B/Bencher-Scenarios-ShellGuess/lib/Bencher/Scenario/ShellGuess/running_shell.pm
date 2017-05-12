package Bencher::Scenario::ShellGuess::running_shell;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark running_shell()',
    participants => [
        {
            module => 'Shell::Guess',
            function => 'running_shell',
            code_template=>'my $s = Shell::Guess->running_shell; $s->name',
        },
    ],
};

1;
# ABSTRACT: Benchmark running_shell()

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::ShellGuess::running_shell - Benchmark running_shell()

=head1 VERSION

This document describes version 0.002 of Bencher::Scenario::ShellGuess::running_shell (from Perl distribution Bencher-Scenarios-ShellGuess), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m ShellGuess::running_shell

To run module startup overhead benchmark:

 % bencher --module-startup -m ShellGuess::running_shell

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Shell::Guess> 0.06

=head1 BENCHMARK PARTICIPANTS

=over

=item * Shell::Guess::running_shell (perl_code)

Code template:

 my $s = Shell::Guess->running_shell; $s->name



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) i5-2400 CPU @ 3.10GHz (4 cores) >>, OS: I<< GNU/Linux Debian version 8.0 >>, OS kernel: I<< Linux version 3.16.0-4-amd64 >>.

Under bash:

 #table1#
 +-----------------------------+------+-----------+-----------+------------+---------+---------+
 | participant                 | perl | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +-----------------------------+------+-----------+-----------+------------+---------+---------+
 | Shell::Guess::running_shell | perl |     50000 |        20 |          1 | 2.7e-08 |      20 |
 +-----------------------------+------+-----------+-----------+------------+---------+---------+


Under fish:

 #table2#
 +-----------------------------+------+-----------+-----------+------------+---------+---------+
 | participant                 | perl | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +-----------------------------+------+-----------+-----------+------------+---------+---------+
 | Shell::Guess::running_shell | perl |     50000 |        20 |          1 | 2.6e-08 |      21 |
 +-----------------------------+------+-----------+-----------+------------+---------+---------+


Under tcsh ('c'):

 #table3#
 +-----------------------------+------+-----------+-----------+------------+---------+---------+
 | participant                 | perl | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +-----------------------------+------+-----------+-----------+------------+---------+---------+
 | Shell::Guess::running_shell | perl |     45000 |        22 |          1 | 2.7e-08 |      20 |
 +-----------------------------+------+-----------+-----------+------------+---------+---------+


Under zsh ('z'):

 #table4#
 +-----------------------------+------+-----------+-----------+------------+--------+---------+
 | participant                 | perl | rate (/s) | time (μs) | vs_slowest | errors | samples |
 +-----------------------------+------+-----------+-----------+------------+--------+---------+
 | Shell::Guess::running_shell | perl |     49100 |      20.4 |          1 |  2e-08 |      20 |
 +-----------------------------+------+-----------+-----------+------------+--------+---------+


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
