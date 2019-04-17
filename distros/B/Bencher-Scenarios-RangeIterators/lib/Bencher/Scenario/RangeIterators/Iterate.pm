package Bencher::Scenario::RangeIterators::Iterate;

our $DATE = '2019-04-17'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark iteration',
    participants => [
        {module=>'Range::Iterator', code_template=>'state $iter = Range::Iterator->new(<start>, <end>); $iter->next for 1..<n>'},
        {module=>'Range::Iter', code_template=>'state $iter = Range::Iter::range_iter(<start>, <end>); $iter->() for 1..<n>'},
        {module=>'Range::ArrayIter', code_template=>'$iter = Range::ArrayIter::range_arrayiter(<start>, <end>); for (@$iter) {}'},
    ],
    datasets => [
        {name=>'100k', args=>{start=>1, end=>100_000, n=>100_000}},
    ],
};

1;
# ABSTRACT: Benchmark iteration

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::RangeIterators::Iterate - Benchmark iteration

=head1 VERSION

This document describes version 0.001 of Bencher::Scenario::RangeIterators::Iterate (from Perl distribution Bencher-Scenarios-RangeIterators), released on 2019-04-17.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m RangeIterators::Iterate

To run module startup overhead benchmark:

 % bencher --module-startup -m RangeIterators::Iterate

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Range::Iterator> 0.001

L<Range::Iter> 0.001

L<Range::ArrayIter> 0.001

=head1 BENCHMARK PARTICIPANTS

=over

=item * Range::Iterator (perl_code)

Code template:

 state $iter = Range::Iterator->new(<start>, <end>); $iter->next for 1..<n>



=item * Range::Iter (perl_code)

Code template:

 state $iter = Range::Iter::range_iter(<start>, <end>); $iter->() for 1..<n>



=item * Range::ArrayIter (perl_code)

Code template:

 $iter = Range::ArrayIter::range_arrayiter(<start>, <end>); for (@$iter) {}



=back

=head1 BENCHMARK DATASETS

=over

=item * 100k

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.26.1 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 18.3 >>, OS kernel: I<< Linux version 4.10.0-38-generic >>.

Benchmark with default options (C<< bencher -m RangeIterators::Iterate >>):

 #table1#
 +------------------+-----------+-----------+------------+-----------+---------+
 | participant      | rate (/s) | time (ms) | vs_slowest |  errors   | samples |
 +------------------+-----------+-----------+------------+-----------+---------+
 | Range::ArrayIter |       8.1 |     120   |       1    |   0.00015 |      20 |
 | Range::Iterator  |      22.8 |      43.8 |       2.83 | 2.6e-05   |      20 |
 | Range::Iter      |      90.8 |      11   |      11.3  |   4e-06   |      20 |
 +------------------+-----------+-----------+------------+-----------+---------+


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
