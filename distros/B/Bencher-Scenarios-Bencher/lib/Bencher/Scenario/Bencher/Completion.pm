package Bencher::Scenario::Bencher::Completion;

our $DATE = '2016-01-06'; # DATE
our $VERSION = '0.01'; # VERSION

use 5.010001;
use strict;
use warnings;

use Bencher::ScenarioUtil::Completion qw(make_completion_participant);

our $scenario = {
    summary => 'Benchmark completion response time, to monitor regression',
    modules => {
    },
    participants => [
        make_completion_participant(
            name=>'optname_common_help',
            cmdline=>"bencher --hel^",
        ),
        make_completion_participant(
            name=>'optname_common_version',
            cmdline=>"bencher --vers^",
        ),
        make_completion_participant(
            name=>'optname_action',
            cmdline=>"bencher --acti^",
        ),
        make_completion_participant(
            name=>'optval_action',
            cmdline=>"bencher --action ^",
        ),
    ],
};

1;
# ABSTRACT: Benchmark completion response time, to monitor regression

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::Bencher::Completion - Benchmark completion response time, to monitor regression

=head1 VERSION

This document describes version 0.01 of Bencher::Scenario::Bencher::Completion (from Perl distribution Bencher-Scenarios-Bencher), released on 2016-01-06.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m Bencher::Completion

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 BENCHMARK PARTICIPANTS

=over

=item * optname_common_help (perl_code)

Run command (with COMP_LINE & COMP_POINT set, "^" marks COMP_POINT): bencher --hel^.



=item * optname_common_version (perl_code)

Run command (with COMP_LINE & COMP_POINT set, "^" marks COMP_POINT): bencher --vers^.



=item * optname_action (perl_code)

Run command (with COMP_LINE & COMP_POINT set, "^" marks COMP_POINT): bencher --acti^.



=item * optval_action (perl_code)

Run command (with COMP_LINE & COMP_POINT set, "^" marks COMP_POINT): bencher --action ^.



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.22.0 >>, CPU: I<< Intel(R) Core(TM) i5-2400 CPU @ 3.10GHz (4 cores) >>, OS: I<< GNU/Linux Debian version 8.0 >>, OS kernel: I<< Linux version 3.16.0-4-amd64 >>.

Benchmark with default option:

 +-----+------------------------+------+--------+---------+---------+
 | seq | name                   | rate | time   | errors  | samples |
 +-----+------------------------+------+--------+---------+---------+
 | 3   | optval_action          | 13   | 79ms   | 0.00036 | 20      |
 | 2   | optname_action         | 12.7 | 78.9ms | 0.00024 | 20      |
 | 0   | optname_common_help    | 12.7 | 78.9ms | 0.00025 | 20      |
 | 1   | optname_common_version | 12.8 | 78.3ms | 0.00015 | 21      |
 +-----+------------------------+------+--------+---------+---------+

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-Bencher>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-Bencher>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-Bencher>

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
