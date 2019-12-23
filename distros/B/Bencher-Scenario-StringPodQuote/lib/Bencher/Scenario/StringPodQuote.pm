package Bencher::Scenario::StringPodQuote;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2019-12-17'; # DATE
our $DIST = 'Bencher-Scenario-StringPodQuote'; # DIST
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark String::PodQuote',
    participants => [
        {
            fcall_template => 'String::PodQuote::pod_escape(<text>)',
        },
    ],
    datasets => [
        {

            name => 'short', args => {text=>'This is <, >, C<=>, =, /, and |.'},
        },
        {
            name => 'long', args => {text=><<'_',},
Normally you will only need to do this in an application, not in modules. One
piece of advice is to allow user to change the level without her having to
modify the source code, for example via environment variable and/or < command-line
option. An application framework like L<Perinci::CmdLine> will already take care
of this for you, so you don't need to do C<set_level> manually at all.
_

        },
    ],
};

1;
# ABSTRACT: Benchmark String::PodQuote

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::StringPodQuote - Benchmark String::PodQuote

=head1 VERSION

This document describes version 0.001 of Bencher::Scenario::StringPodQuote (from Perl distribution Bencher-Scenario-StringPodQuote), released on 2019-12-17.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m StringPodQuote

To run module startup overhead benchmark:

 % bencher --module-startup -m StringPodQuote

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<String::PodQuote> 0.003

=head1 BENCHMARK PARTICIPANTS

=over

=item * String::PodQuote::pod_escape (perl_code)

Function call template:

 String::PodQuote::pod_escape(<text>)



=back

=head1 BENCHMARK DATASETS

=over

=item * short

=item * long

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.30.0 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 19.04 >>, OS kernel: I<< Linux version 5.0.0-37-generic >>.

Benchmark with C<< bencher -m StringPodQuote --env-hashes-json '[{"PERL5OPT":"-Iarchive/String-PodQuote-0.002/lib"},{"PERL5OPT":"-Iarchive/String-PodQuote-0.003/lib"}]' >>:

 #table1#
 +---------+----------------------------------------------+-----------+-----------+------------+---------+---------+
 | dataset | env                                          | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +---------+----------------------------------------------+-----------+-----------+------------+---------+---------+
 | long    | PERL5OPT=-Iarchive/String-PodQuote-0.002/lib |   25183.9 |    39.708 |       1    | 1.7e-11 |      20 |
 | long    | PERL5OPT=-Iarchive/String-PodQuote-0.003/lib |   25300   |    39.6   |       1    | 1.1e-08 |      30 |
 | short   | PERL5OPT=-Iarchive/String-PodQuote-0.003/lib |   85000   |    12     |       3.4  | 1.3e-08 |      20 |
 | short   | PERL5OPT=-Iarchive/String-PodQuote-0.002/lib |   88500   |    11.3   |       3.52 | 3.3e-09 |      20 |
 +---------+----------------------------------------------+-----------+-----------+------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m StringPodQuote --module-startup >>):

 #table2#
 +---------------------+----------------------------------------------+-----------+------------------------+------------+---------+---------+
 | participant         | env                                          | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +---------------------+----------------------------------------------+-----------+------------------------+------------+---------+---------+
 | String::PodQuote    | PERL5OPT=-Iarchive/String-PodQuote-0.002/lib |       9.2 |                    2.3 |        1   | 2.1e-05 |      20 |
 | String::PodQuote    | PERL5OPT=-Iarchive/String-PodQuote-0.003/lib |       9.2 |                    2.3 |        1   | 2.1e-05 |      20 |
 | perl -e1 (baseline) | PERL5OPT=-Iarchive/String-PodQuote-0.003/lib |       6.9 |                    0   |        1.3 | 3.6e-05 |      20 |
 | perl -e1 (baseline) | PERL5OPT=-Iarchive/String-PodQuote-0.002/lib |       6.7 |                   -0.2 |        1.4 | 4.3e-05 |      20 |
 +---------------------+----------------------------------------------+-----------+------------------------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-StringPodQuote>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-StringPodQuote>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-StringPodQuote>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
