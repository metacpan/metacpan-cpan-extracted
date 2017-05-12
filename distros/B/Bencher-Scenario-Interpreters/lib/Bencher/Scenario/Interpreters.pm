package Bencher::Scenario::Interpreters;

our $DATE = '2016-06-26'; # DATE
our $VERSION = '0.03'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark startup time of various interpreters',
    participants => [
        {name=>'perl'  , cmdline=>[qw/perl -e1/]},
        {name=>'bash'  , cmdline=>[qw/bash --norc -c true/]},
        {name=>'ruby'  , cmdline=>[qw/ruby -e1/]},
        {name=>'python', cmdline=>[qw/python -c1/]},
        {name=>'nodejs', cmdline=>[qw/nodejs -e 1/]},
    ],
    on_failure => 'skip',
};

1;
# ABSTRACT: Benchmark startup time of various interpreters

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::Interpreters - Benchmark startup time of various interpreters

=head1 VERSION

This document describes version 0.03 of Bencher::Scenario::Interpreters (from Perl distribution Bencher-Scenario-Interpreters), released on 2016-06-26.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m Interpreters

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 BENCHMARK PARTICIPANTS

=over

=item * perl (command)

Command line:

 perl -e1



=item * bash (command)

Command line:

 bash --norc -c true



=item * ruby (command)

Command line:

 ruby -e1



=item * python (command)

Command line:

 python -c1



=item * nodejs (command)

Command line:

 nodejs -e 1



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.22.2 >>, CPU: I<< Intel(R) Core(TM) i7-4770 CPU @ 3.40GHz (4 cores) >>, OS: I<< GNU/Linux Debian version 8.0 >>, OS kernel: I<< Linux version 3.16.0-4-amd64 >>.

Benchmark with default options (C<< bencher -m Interpreters >>):

 +-------------+-----------+-----------+------------+---------+---------+
 | participant | rate (/s) | time (ms) | vs_slowest |  errors | samples |
 +-------------+-----------+-----------+------------+---------+---------+
 | nodejs      |        50 |      20   |        1   | 6.1e-05 |      20 |
 | ruby        |       110 |       9.1 |        2.2 | 6.3e-05 |      20 |
 | python      |       110 |       8.8 |        2.3 | 3.2e-05 |      20 |
 | perl        |       390 |       2.5 |        7.9 | 6.7e-06 |      20 |
 | bash        |       400 |       2.5 |        8   | 1.7e-05 |      20 |
 +-------------+-----------+-----------+------------+---------+---------+

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-Interpreters>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-Interpreters>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-Interpreters>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
