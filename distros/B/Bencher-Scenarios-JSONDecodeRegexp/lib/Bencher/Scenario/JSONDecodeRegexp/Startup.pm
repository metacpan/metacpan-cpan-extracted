package Bencher::Scenario::JSONDecodeRegexp::Startup;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.003'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark startup overhead of JSON::Decode::Regexp vs some other modules',
    module_startup => 1,
    participants => [
        {module=>'JSON::Decode::Regexp'},

        {module=>'Regexp::Grammars'},
    ],
    #datasets => [
    #],
};

1;
# ABSTRACT: Benchmark startup overhead of JSON::Decode::Regexp vs some other modules

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::JSONDecodeRegexp::Startup - Benchmark startup overhead of JSON::Decode::Regexp vs some other modules

=head1 VERSION

This document describes version 0.003 of Bencher::Scenario::JSONDecodeRegexp::Startup (from Perl distribution Bencher-Scenarios-JSONDecodeRegexp), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m JSONDecodeRegexp::Startup

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<JSON::Decode::Regexp> 0.09

L<Regexp::Grammars> 1.045

=head1 BENCHMARK PARTICIPANTS

=over

=item * JSON::Decode::Regexp (perl_code)

L<JSON::Decode::Regexp>



=item * Regexp::Grammars (perl_code)

L<Regexp::Grammars>



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with C<< bencher -m JSONDecodeRegexp::Startup --include-path archive/JSON-Decode-Regexp-0.03/lib --include-path archive/JSON-Decode-Regexp-0.04/lib --include-path archive/JSON-Decode-Regexp-0.06/lib --include-path archive/JSON-Decode-Regexp-0.07/lib --include-path archive/JSON-Decode-Regexp-0.09/lib --multimodver JSON::Decode::Regexp >>:

 #table1#
 {dataset=>undef}
 +-------------------------+---------------+-----------+----------------------+--------+-----------+------------------------+------------+---------+---------+
 | proc_private_dirty_size | proc_rss_size | proc_size | participant          | modver | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +-------------------------+---------------+-----------+----------------------+--------+-----------+------------------------+------------+---------+---------+
 | 0.82                    | 4.2           | 16        | Regexp::Grammars     |        |      25   |                   23.1 |        1   | 5.5e-05 |      20 |
 | 3.7                     | 7.3           | 29        | JSON::Decode::Regexp | 0.09   |       5.3 |                    3.4 |        4.8 | 1.9e-05 |      20 |
 | 3.7                     | 7.4           | 29        | JSON::Decode::Regexp | 0.07   |       5.2 |                    3.3 |        4.8 | 2.6e-05 |      20 |
 | 3.7                     | 7.3           | 29        | JSON::Decode::Regexp | 0.06   |       5.2 |                    3.3 |        4.8 | 3.9e-05 |      20 |
 | 3.7                     | 7.5           | 29        | JSON::Decode::Regexp | 0.03   |       5.1 |                    3.2 |        4.9 | 2.4e-05 |      20 |
 | 3.7                     | 7.4           | 29        | JSON::Decode::Regexp | 0.04   |       5   |                    3.1 |        5   | 2.4e-05 |      20 |
 | 0.99                    | 4.3           | 16        | perl -e1 (baseline)  |        |       1.9 |                    0   |       13   | 6.5e-06 |      20 |
 +-------------------------+---------------+-----------+----------------------+--------+-----------+------------------------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-JSONDecodeRegexp>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-JSONDecodeRegexp>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-JSONDecodeRegexp>

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
