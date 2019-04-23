package Bencher::Scenario::RangeIterators::Startup;

our $DATE = '2019-04-23'; # DATE
our $VERSION = '0.003'; # VERSION

our $scenario = {
    summary => 'Benchmark startup overhead',
    module_startup => 1,
    participants => [
        {module=>'Range::Iterator'},
        {module=>'Range::Iter'},
        {module=>'Range::ArrayIter'},
    ],
};

1;
# ABSTRACT: Benchmark startup overhead

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::RangeIterators::Startup - Benchmark startup overhead

=head1 VERSION

This document describes version 0.003 of Bencher::Scenario::RangeIterators::Startup (from Perl distribution Bencher-Scenarios-RangeIterators), released on 2019-04-23.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m RangeIterators::Startup

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Range::Iterator> 0.002

L<Range::Iter> 0.002

L<Range::ArrayIter> 0.002

=head1 BENCHMARK PARTICIPANTS

=over

=item * Range::Iterator (perl_code)

L<Range::Iterator>



=item * Range::Iter (perl_code)

L<Range::Iter>



=item * Range::ArrayIter (perl_code)

L<Range::ArrayIter>



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.26.0 >>, CPU: I<< Intel(R) Core(TM) i5-2400 CPU @ 3.10GHz (4 cores) >>, OS: I<< GNU/Linux LinuxMint version 18.2 >>, OS kernel: I<< Linux version 4.8.0-53-generic >>.

Benchmark with default options (C<< bencher -m RangeIterators::Startup >>):

 #table1#
 +---------------------+-----------+------------------------+------------+---------+---------+
 | participant         | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +---------------------+-----------+------------------------+------------+---------+---------+
 | Range::ArrayIter    |      10.4 |                    4.6 |       1    | 8.5e-06 |      20 |
 | Range::Iterator     |      10.4 |                    4.6 |       1.01 | 8.7e-06 |      21 |
 | Range::Iter         |      10   |                    4.2 |       1    | 1.8e-05 |      21 |
 | perl -e1 (baseline) |       5.8 |                    0   |       1.8  | 1.2e-05 |      20 |
 +---------------------+-----------+------------------------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-RangeIterators>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-RangeIterators>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-RangeIterators>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
