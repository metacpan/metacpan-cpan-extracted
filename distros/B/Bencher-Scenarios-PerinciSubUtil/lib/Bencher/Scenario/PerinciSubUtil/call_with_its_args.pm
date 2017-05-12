package Bencher::Scenario::PerinciSubUtil::call_with_its_args;

our $DATE = '2017-01-31'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

sub main::foo {}

our $scenario = {
    summary => 'Benchmark call_with_its_args() vs direct call',
    participants => [
        {
            name => 'direct',
            code_template => 'main::foo(a1=>1, a2=>2, a3=>3)',
        },
        {
            name => 'call_with_its_args',
            module => 'Perinci::Sub::Util::Args',
            code_template => 'Perinci::Sub::Util::Args::call_with_its_args("main::foo", {a1=>1, a2=>2, a3=>3, a6=>4})',
        },
    ],
    before_bench => sub {
        my %args = @_;
        $main::SPEC{foo} = {
            v => 1.1,
            args => {
                a1 => {tags=>["t1","t2"]},
                a2 => {tags=>["t2","t3"]},
                a3 => {tags=>["t3","t4"]},
                a4 => {},
                a5 => {},
            },
        };
    },
    after_bench => sub {
        undef $main::SPEC{foo};
    },
};

1;
# ABSTRACT: Benchmark call_with_its_args() vs direct call

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::PerinciSubUtil::call_with_its_args - Benchmark call_with_its_args() vs direct call

=head1 VERSION

This document describes version 0.001 of Bencher::Scenario::PerinciSubUtil::call_with_its_args (from Perl distribution Bencher-Scenarios-PerinciSubUtil), released on 2017-01-31.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m PerinciSubUtil::call_with_its_args

To run module startup overhead benchmark:

 % bencher --module-startup -m PerinciSubUtil::call_with_its_args

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Perinci::Sub::Util::Args> 0.46

=head1 BENCHMARK PARTICIPANTS

=over

=item * direct (perl_code)

Code template:

 main::foo(a1=>1, a2=>2, a3=>3)



=item * call_with_its_args (perl_code)

Code template:

 Perinci::Sub::Util::Args::call_with_its_args("main::foo", {a1=>1, a2=>2, a3=>3, a6=>4})



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m PerinciSubUtil::call_with_its_args >>):

 #table1#
 +--------------------+-----------+-----------+------------+---------+---------+
 | participant        | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +--------------------+-----------+-----------+------------+---------+---------+
 | call_with_its_args |    340000 |      3    |          1 | 3.3e-09 |      20 |
 | direct             |  14000000 |      0.07 |         43 | 6.7e-10 |      23 |
 +--------------------+-----------+-----------+------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m PerinciSubUtil::call_with_its_args --module-startup >>):

 #table2#
 +--------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | participant              | proc_private_dirty_size (kB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +--------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | Perinci::Sub::Util::Args | 996                          | 4.4                | 16             |       7.2 |                    3.3 |        1   | 1.3e-05 |      20 |
 | perl -e1 (baseline)      | 840                          | 4                  | 16             |       3.9 |                    0   |        1.9 | 6.1e-06 |      20 |
 +--------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-PerinciSubUtil>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-PerinciSubUtil>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-PerinciSubUtil>

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
