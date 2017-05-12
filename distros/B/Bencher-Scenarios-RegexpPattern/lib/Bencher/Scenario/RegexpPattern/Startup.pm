package Bencher::Scenario::RegexpPattern::Startup;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.003'; # VERSION

use 5.010001;
use strict;
use warnings;

#our @modules = do { require App::lcpan::Call; @{ App::lcpan::Call::call_lcpan_script(argv=>["modules", "--namespace", "Regexp::Pattern"])->[2] } }; # PRECOMPUTE
our @modules = qw(
                     Regexp::Pattern
                     Regexp::Pattern::RegexpCommon
                     Regexp::Pattern::YouTube
             );

our $scenario = {
    summary => 'Benchmark module startup overhead of Regexp::Pattern modules',

    module_startup => 1,

    participants => [
        map { +{module=>$_} } @modules,
    ],
};

1;
# ABSTRACT: Benchmark module startup overhead of Regexp::Pattern modules

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::RegexpPattern::Startup - Benchmark module startup overhead of Regexp::Pattern modules

=head1 VERSION

This document describes version 0.003 of Bencher::Scenario::RegexpPattern::Startup (from Perl distribution Bencher-Scenarios-RegexpPattern), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m RegexpPattern::Startup

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Regexp::Pattern> 0.1.4

L<Regexp::Pattern::RegexpCommon> 0.002

L<Regexp::Pattern::YouTube> 0.002

=head1 BENCHMARK PARTICIPANTS

=over

=item * Regexp::Pattern (perl_code)

L<Regexp::Pattern>



=item * Regexp::Pattern::RegexpCommon (perl_code)

L<Regexp::Pattern::RegexpCommon>



=item * Regexp::Pattern::YouTube (perl_code)

L<Regexp::Pattern::YouTube>



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m RegexpPattern::Startup >>):

 #table1#
 +-------------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | participant                   | proc_private_dirty_size (kB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +-------------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | Regexp::Pattern::RegexpCommon | 844                          | 4.1                | 16             |       7.2 |      2.5               |        1   | 2.8e-05 |      20 |
 | Regexp::Pattern               | 864                          | 4.2                | 16             |       6.3 |      1.6               |        1.1 | 9.8e-06 |      20 |
 | Regexp::Pattern::YouTube      | 844                          | 4.1                | 16             |       5.1 |      0.399999999999999 |        1.4 |   1e-05 |      20 |
 | perl -e1 (baseline)           | 952                          | 4.2                | 16             |       4.7 |      0                 |        1.5 | 2.2e-05 |      20 |
 +-------------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-RegexpPattern>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-RegexpPattern>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-RegexpPattern>

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
