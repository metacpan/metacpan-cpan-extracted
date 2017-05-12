package Bencher::Scenario::CBlocks::Numeric;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark numeric performance of C::Blocks',
    description => <<'_',

Each code generates random number (the `perl` participant using pure-perl code.

_
    precision => 6,
    participants => [
        {
            name => 'perl',
            code_template => <<'_',
my $a = 698769069;
my ($x, $y, $z, $c) = (123456789, 362436000, 521288629, 7654321);
my $rand;
for (1 .. <N>) {
    my $t;
    $x = 69069*$x+12345;
    $y ^= ($y<<13); $y ^= ($y>>17); $y ^= ($y<<5);
    $t = $a*$z+$c; $c = ($t>>32);
    $z = $t;
    $rand = $x+$y+$z;
}
return $rand;
_
        },
        {
            name => 'C::Blocks',
            module => 'C::Blocks',
            code_template => <<'_',
use C::Blocks;
use C::Blocks::Types qw(uint);
clex {
    /* Note: y must never be set to zero;
     * z and c must not be simultaneously zero */
    unsigned int x = 123456789,y = 362436000,
        z = 521288629,c = 7654321; /* State variables */

    unsigned int KISS() {
        unsigned long long t, a = 698769069ULL;
        x = 69069*x+12345;
        y ^= (y<<13); y ^= (y>>17); y ^= (y<<5);
        t = a*z+c; c = (t>>32);
        return x+y+(z=t);
    }
}

my uint $to_return = 0;
cblock {
    for (int i = 0; i < <N>; i++) $to_return = KISS();
}
return $to_return;

_
        },
    ],

    datasets => [
        {args=>{N=>int(10**1)}},
        {args=>{N=>int(10**1.5)}},
        {args=>{N=>int(10**2)}},
        {args=>{N=>int(10**2.5)}},
        {args=>{N=>int(10**3)}},
        {args=>{N=>int(10**3.51)}},
        {args=>{N=>int(10**4)}},
        {args=>{N=>int(10**4.5)}},
        {args=>{N=>int(10**5)}},
        {args=>{N=>int(10**5.5)}},
    ],
};

1;
# ABSTRACT: Benchmark numeric performance of C::Blocks

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::CBlocks::Numeric - Benchmark numeric performance of C::Blocks

=head1 VERSION

This document describes version 0.002 of Bencher::Scenario::CBlocks::Numeric (from Perl distribution Bencher-Scenarios-CBlocks), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m CBlocks::Numeric

To run module startup overhead benchmark:

 % bencher --module-startup -m CBlocks::Numeric

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Each code generates random number (the C<perl> participant using pure-perl code.


Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<C::Blocks> 0.41

=head1 BENCHMARK PARTICIPANTS

=over

=item * perl (perl_code)

Code template:

 my $a = 698769069;
 my ($x, $y, $z, $c) = (123456789, 362436000, 521288629, 7654321);
 my $rand;
 for (1 .. <N>) {
     my $t;
     $x = 69069*$x+12345;
     $y ^= ($y<<13); $y ^= ($y>>17); $y ^= ($y<<5);
     $t = $a*$z+$c; $c = ($t>>32);
     $z = $t;
     $rand = $x+$y+$z;
 }
 return $rand;




=item * C::Blocks (perl_code)

Code template:

 use C::Blocks;
 use C::Blocks::Types qw(uint);
 clex {
     /* Note: y must never be set to zero;
      * z and c must not be simultaneously zero */
     unsigned int x = 123456789,y = 362436000,
         z = 521288629,c = 7654321; /* State variables */
 
     unsigned int KISS() {
         unsigned long long t, a = 698769069ULL;
         x = 69069*x+12345;
         y ^= (y<<13); y ^= (y>>17); y ^= (y<<5);
         t = a*z+c; c = (t>>32);
         return x+y+(z=t);
     }
 }
 
 my uint $to_return = 0;
 cblock {
     for (int i = 0; i < <N>; i++) $to_return = KISS();
 }
 return $to_return;
 




=back

=head1 BENCHMARK DATASETS

=over

=item * 10

=item * 31

=item * 100

=item * 316

=item * 1000

=item * 3235

=item * 10000

=item * 31622

=item * 100000

=item * 316227

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m CBlocks::Numeric >>):

 #table1#
 +-------------+---------+-----------+------------+------------+-----------+---------+
 | participant | dataset | rate (/s) | time (ms)  | vs_slowest |  errors   | samples |
 +-------------+---------+-----------+------------+------------+-----------+---------+
 | C::Blocks   | 316227  |       6.1 | 160        |        1   |   0.00028 |       7 |
 | perl        | 316227  |       6.8 | 150        |        1.1 |   0.00075 |       6 |
 | C::Blocks   | 100000  |      20   |  50        |        3   |   0.00089 |       7 |
 | perl        | 100000  |      20   |  50        |        3   |   0.00069 |       6 |
 | perl        | 31622   |      70   |  10        |       10   |   0.00023 |       6 |
 | C::Blocks   | 10000   |     100   |   7        |       20   |   0.00036 |      10 |
 | perl        | 10000   |     219   |   4.57     |       35.9 | 2.4e-06   |       6 |
 | C::Blocks   | 3235    |     400   |   2.5      |       66   |   2e-05   |       9 |
 | perl        | 3235    |     654   |   1.53     |      107   | 2.9e-07   |       6 |
 | C::Blocks   | 1000    |    1000   |   0.9      |      200   | 1.4e-05   |       7 |
 | perl        | 1000    |    2290   |   0.436    |      376   | 3.9e-07   |       6 |
 | C::Blocks   | 31622   |    2900   |   0.34     |      480   | 4.9e-07   |       6 |
 | C::Blocks   | 316     |    5800   |   0.17     |      950   | 8.8e-07   |       6 |
 | perl        | 316     |    7200   |   0.14     |     1200   | 2.9e-07   |      11 |
 | C::Blocks   | 100     |   18539   |   0.053939 |     3043.9 | 6.7e-11   |       6 |
 | perl        | 100     |   23000   |   0.044    |     3700   | 6.8e-08   |       7 |
 | C::Blocks   | 31      |   30000   |   0.03     |     5000   | 6.2e-07   |       9 |
 | perl        | 31      |   65330   |   0.01531  |    10730   |   5e-10   |       6 |
 | C::Blocks   | 10      |  100000   |   0.0096   |    17000   | 2.4e-08   |       6 |
 | perl        | 10      |  190000   |   0.0053   |    31000   | 1.5e-08   |       6 |
 +-------------+---------+-----------+------------+------------+-----------+---------+


Benchmark module startup overhead (C<< bencher -m CBlocks::Numeric --module-startup >>):

 #table2#
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+-----------+---------+
 | participant         | proc_private_dirty_size (MB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors   | samples |
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+-----------+---------+
 | C::Blocks           | 2.4                          | 6                  | 22             |        23 |                     17 |          1 |   0.00011 |       6 |
 | perl -e1 (baseline) | 0.8                          | 4                  | 20             |         6 |                      0 |          4 | 6.3e-05   |       7 |
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+-----------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-CBlocks>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-CBlocks>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-CBlocks>

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
