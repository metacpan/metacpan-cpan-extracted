package Bencher::Scenario::ArgPassing::Mixed;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.003'; # VERSION

use 5.010001;
use strict;
use warnings;

sub hashref_at_the_front {
    my $named = shift;
    my ($pos1, $pos2, $pos3) = @_;
}

sub opt_hashref_at_the_front {
    my $named = ref($_[0]) eq 'HASH' ? shift : {};
    my ($pos1, $pos2, $pos3) = @_;
}

sub list_then_hash {
    my $pos0 = shift;
    my $pos1 = shift;
    my $pos2 = shift;
    my %named = @_;
}

our $scenario = {
    summary => 'Benchmark argument passing (mixed positional and named)',
    description => <<'_',

This scenario compares three style of passing mixed positional and named
arguments:

    # hashref at the front
    func({named1=>1, named2=>2}, 'pos0', 'pos1', 'pos2');

    # optional hashref at the front. like the above but when there are no named
    # arguments, the hashref can be omitted
    func({named1=>1, named2=>2}, 'pos0', 'pos1', 'pos2');

    # positional then named as hash
    func('pos1', 'pos2', 'pos3', named1=>1, named2=>2);

_
    modules => {
    },
    participants => [
        {
            name => 'hashref_at_the_front',
            fcall_template => __PACKAGE__ . '::hashref_at_the_front(<named>, <pos1>, <pos2>, <pos3>)',
        },
        {
            name => 'opt_hashref_at_the_front',
            fcall_template => __PACKAGE__ . '::opt_hashref_at_the_front(<named>, <pos1>, <pos2>, <pos3>)',
        },
        {
            name => 'list_then_hash',
            fcall_template => __PACKAGE__ . '::list_then_hash(<pos1>, <pos2>, <pos3>, %{<named>})',
        },
    ],
    datasets => [
        {name => 'pos=3 named=1', args=>{pos1=>1, pos2=>2, pos3=>3, named=>{a=>1}}},
        {name => 'pos=3 named=5', args=>{pos1=>1, pos2=>2, pos3=>3, named=>{a=>1, b=>2, c=>3, d=>4, e=>5}}},
    ],
};

1;
# ABSTRACT: Benchmark argument passing (mixed positional and named)

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::ArgPassing::Mixed - Benchmark argument passing (mixed positional and named)

=head1 VERSION

This document describes version 0.003 of Bencher::Scenario::ArgPassing::Mixed (from Perl distribution Bencher-Scenarios-ArgPassing), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m ArgPassing::Mixed

To run module startup overhead benchmark:

 % bencher --module-startup -m ArgPassing::Mixed

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

This scenario compares three style of passing mixed positional and named
arguments:

 # hashref at the front
 func({named1=>1, named2=>2}, 'pos0', 'pos1', 'pos2');
 
 # optional hashref at the front. like the above but when there are no named
 # arguments, the hashref can be omitted
 func({named1=>1, named2=>2}, 'pos0', 'pos1', 'pos2');
 
 # positional then named as hash
 func('pos1', 'pos2', 'pos3', named1=>1, named2=>2);


Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Bencher::Scenario::ArgPassing::Mixed>

=head1 BENCHMARK PARTICIPANTS

=over

=item * hashref_at_the_front (perl_code)

Function call template:

 Bencher::Scenario::ArgPassing::Mixed::hashref_at_the_front(<named>, <pos1>, <pos2>, <pos3>)



=item * opt_hashref_at_the_front (perl_code)

Function call template:

 Bencher::Scenario::ArgPassing::Mixed::opt_hashref_at_the_front(<named>, <pos1>, <pos2>, <pos3>)



=item * list_then_hash (perl_code)

Function call template:

 Bencher::Scenario::ArgPassing::Mixed::list_then_hash(<pos1>, <pos2>, <pos3>, %{<named>})



=back

=head1 BENCHMARK DATASETS

=over

=item * pos=3 named=1

=item * pos=3 named=5

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m ArgPassing::Mixed >>):

 #table1#
 +--------------------------+---------------+-----------+-----------+------------+---------+---------+
 | participant              | dataset       | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +--------------------------+---------------+-----------+-----------+------------+---------+---------+
 | list_then_hash           | pos=3 named=5 |    650000 |   1.5     |    1       | 2.9e-09 |      27 |
 | list_then_hash           | pos=3 named=1 |   1350000 |   0.742   |    2.08    | 3.2e-10 |      34 |
 | opt_hashref_at_the_front | pos=3 named=5 |   1376000 |   0.727   |    2.125   | 3.1e-11 |      20 |
 | hashref_at_the_front     | pos=3 named=5 |   1465000 |   0.6824  |    2.264   |   1e-11 |      20 |
 | opt_hashref_at_the_front | pos=3 named=1 |   2272470 |   0.44005 |    3.51039 |   0     |      20 |
 | hashref_at_the_front     | pos=3 named=1 |   2567000 |   0.3895  |    3.966   | 1.1e-11 |      21 |
 +--------------------------+---------------+-----------+-----------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-ArgPassing>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-ArgPassing>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-ArgPassing>

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
