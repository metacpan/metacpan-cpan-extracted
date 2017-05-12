package Bencher::Scenario::AppHr::Completion;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.02'; # VERSION

use 5.010001;
use strict;
use warnings;

use Bencher::ScenarioUtil::Completion qw(make_completion_participant);

our $scenario = {
    summary => 'Benchmark completion response time, to monitor regression',
    modules => {
        'App::hr' => {version=>0},
    },
    participants => [
        make_completion_participant(
            name=>'optname_common_help',
            cmdline=>"_hr --hel^",
        ),
        make_completion_participant(
            name=>'optname_common_version',
            cmdline=>"_hr --vers^",
        ),
        make_completion_participant(
            name=>'optname_random_color',
            cmdline=>"_hr --random^",
        ),
        make_completion_participant(
            name=>'optval_height',
            cmdline=>"_hr --height ^",
        ),
    ],
};

1;
# ABSTRACT: Benchmark completion response time, to monitor regression

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::AppHr::Completion - Benchmark completion response time, to monitor regression

=head1 VERSION

This document describes version 0.02 of Bencher::Scenario::AppHr::Completion (from Perl distribution Bencher-Scenarios-AppHr), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m AppHr::Completion

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<App::hr> 0.25

=head1 BENCHMARK PARTICIPANTS

=over

=item * optname_common_help (perl_code)

Run command (with COMP_LINE & COMP_POINT set, "^" marks COMP_POINT): _hr --hel^.



=item * optname_common_version (perl_code)

Run command (with COMP_LINE & COMP_POINT set, "^" marks COMP_POINT): _hr --vers^.



=item * optname_random_color (perl_code)

Run command (with COMP_LINE & COMP_POINT set, "^" marks COMP_POINT): _hr --random^.



=item * optval_height (perl_code)

Run command (with COMP_LINE & COMP_POINT set, "^" marks COMP_POINT): _hr --height ^.



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m AppHr::Completion >>):

 #table1#
 +------------------------+-----------+-----------+------------+-----------+---------+
 | participant            | rate (/s) | time (ms) | vs_slowest |  errors   | samples |
 +------------------------+-----------+-----------+------------+-----------+---------+
 | optval_height          |        19 |        52 |          1 |   0.00012 |      20 |
 | optname_random_color   |        19 |        51 |          1 |   0.00016 |      21 |
 | optname_common_help    |        20 |        51 |          1 |   0.00012 |      21 |
 | optname_common_version |        20 |        51 |          1 | 8.9e-05   |      20 |
 +------------------------+-----------+-----------+------------+-----------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-AppHr>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-AppHr>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-AppHr>

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
