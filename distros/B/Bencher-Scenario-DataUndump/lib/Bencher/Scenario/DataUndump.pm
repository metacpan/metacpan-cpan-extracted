package Bencher::Scenario::DataUndump;

our $DATE = '2019-09-07'; # DATE
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;

use Data::Dumper;

my $array10mixed = [
    undef,
    1,
    1.1,
    "",
    "string",

    "string with some control characters: \n, \b",
    [],
    [1,2,3],
    {},
    {a=>1,b=>2,c=>3},
];

our $scenario = {
    summary => 'Benchmark Data::Undump against eval() for loading a Data::Dumper output',
    participants => [
        {
            fcall_template=>'Data::Undump::undump(<dump>)',
        },
        {
            name=>'eval',
            code_template=>'eval(<dump>)',
        },
    ],
    datasets => [
        {
            name => 'array100i',
            summary => 'Array of 100 integers',
            args => {dump=> Data::Dumper->new([[1..100]])->Terse(1)->Dump },
            result => [1..100],
        },
        {
            name => 'array1000i',
            summary => 'Array of 1000 integers',
            args => {dump=> Data::Dumper->new([[1..1000]])->Terse(1)->Dump },
            result => [1..1000],
        },
        {
            name => 'array10mixed',
            summary => 'A 10-element array containing a mix of various Perl data items',
            args => {dump=> Data::Dumper->new([$array10mixed])->Terse(1)->Dump },
            result => $array10mixed,
        },
    ],
};

1;
# ABSTRACT: Benchmark Data::Undump against eval() for loading a Data::Dumper output

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::DataUndump - Benchmark Data::Undump against eval() for loading a Data::Dumper output

=head1 VERSION

This document describes version 0.002 of Bencher::Scenario::DataUndump (from Perl distribution Bencher-Scenario-DataUndump), released on 2019-09-07.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m DataUndump

To run module startup overhead benchmark:

 % bencher --module-startup -m DataUndump

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Data::Undump> 0.15

=head1 BENCHMARK PARTICIPANTS

=over

=item * Data::Undump::undump (perl_code)

Function call template:

 Data::Undump::undump(<dump>)



=item * eval (perl_code)

Code template:

 eval(<dump>)



=back

=head1 BENCHMARK DATASETS

=over

=item * array100i

Array of 100 integers

=item * array1000i

Array of 1000 integers

=item * array10mixed

A 10-element array containing a mix of various Perl data items

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.26.1 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 18.3 >>, OS kernel: I<< Linux version 4.10.0-38-generic >>.

Benchmark with default options (C<< bencher -m DataUndump >>):

 #table1#
 {dataset=>"array1000i"}
 +----------------------+-----------+-----------+------------+---------+---------+
 | participant          | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +----------------------+-----------+-----------+------------+---------+---------+
 | eval                 |    4849.8 |   206.194 |       1    |   0     |      21 |
 | Data::Undump::undump |   28100   |    35.6   |       5.79 | 3.4e-08 |      27 |
 +----------------------+-----------+-----------+------------+---------+---------+

 #table2#
 {dataset=>"array100i"}
 +----------------------+-----------+-----------+------------+---------+---------+
 | participant          | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +----------------------+-----------+-----------+------------+---------+---------+
 | eval                 |     42000 |     24    |       1    | 2.7e-08 |      20 |
 | Data::Undump::undump |    229000 |      4.36 |       5.43 | 1.7e-09 |      20 |
 +----------------------+-----------+-----------+------------+---------+---------+

 #table3#
 {dataset=>"array10mixed"}
 +----------------------+-----------+-----------+------------+---------+---------+
 | participant          | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +----------------------+-----------+-----------+------------+---------+---------+
 | eval                 |     71900 |      13.9 |        1   | 6.7e-09 |      20 |
 | Data::Undump::undump |    500000 |       2   |        6.9 | 2.5e-09 |      20 |
 +----------------------+-----------+-----------+------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m DataUndump --module-startup >>):

 #table4#
 +---------------------+-----------+------------------------+------------+---------+---------+
 | participant         | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +---------------------+-----------+------------------------+------------+---------+---------+
 | Data::Undump        |       8.6 |                    2.8 |        1   | 2.8e-05 |      20 |
 | perl -e1 (baseline) |       5.8 |                    0   |        1.5 | 1.9e-05 |      20 |
 +---------------------+-----------+------------------------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-DataUndump>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-DataUndump>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-DataUndump>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<https://www.reddit.com/r/perl/comments/czhwe6/syntax_differences_from_data_dumper_to_json/ez95r7c?utm_source=share&utm_medium=web2x>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
