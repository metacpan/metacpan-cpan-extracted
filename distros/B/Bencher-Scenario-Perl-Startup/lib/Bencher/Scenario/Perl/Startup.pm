package Bencher::Scenario::Perl::Startup;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-07-23'; # DATE
our $DIST = 'Bencher-Scenario-Perl-Startup'; # DIST
our $VERSION = '0.053'; # VERSION

use 5.010001;
use strict;
use warnings;

use App::perlbrew;
use File::Which;

my $participants = [];

my $pb = App::perlbrew->new;
for my $perl ($pb->installed_perls) {
    push @$participants, {
        name => "$perl->{name} -e1",
        cmdline => [$perl->{executable}, "-e1"],
    };
    if (version->parse($perl->{version}) >= version->parse("5.10.0")) {
        push @$participants, {
            name => "$perl->{name} -E1",
            cmdline => [$perl->{executable}, "-E1"],
        };
    }
}

our $scenario = {
    summary => 'Benchmark startup time of perls',
    default_precision => 0.005,
    participants => $participants,
};

1;
# ABSTRACT: Benchmark startup time of perls

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::Perl::Startup - Benchmark startup time of perls

=head1 VERSION

This document describes version 0.053 of Bencher::Scenario::Perl::Startup (from Perl distribution Bencher-Scenario-Perl-Startup), released on 2021-07-23.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m Perl::Startup

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Conclusion: in general newer versions of perl has larger startup overhead than
previous ones. If startup overhead is important to you, use C<-e> instead of
C<-E> unless necessary.

=head1 BENCHMARK PARTICIPANTS

=over

=item * perl-5.34.0 -e1 (command)

Command line:

 /home/u1/perl5/perlbrew/perls/perl-5.34.0/bin/perl -e1



=item * perl-5.34.0 -E1 (command)

Command line:

 /home/u1/perl5/perlbrew/perls/perl-5.34.0/bin/perl -E1



=item * perl-5.32.1 -e1 (command)

Command line:

 /home/u1/perl5/perlbrew/perls/perl-5.32.1/bin/perl -e1



=item * perl-5.32.1 -E1 (command)

Command line:

 /home/u1/perl5/perlbrew/perls/perl-5.32.1/bin/perl -E1



=item * perl-5.30.3 -e1 (command)

Command line:

 /home/u1/perl5/perlbrew/perls/perl-5.30.3/bin/perl -e1



=item * perl-5.30.3 -E1 (command)

Command line:

 /home/u1/perl5/perlbrew/perls/perl-5.30.3/bin/perl -E1



=item * perl-5.30.0 -e1 (command)

Command line:

 /home/u1/perl5/perlbrew/perls/perl-5.30.0/bin/perl -e1



=item * perl-5.30.0 -E1 (command)

Command line:

 /home/u1/perl5/perlbrew/perls/perl-5.30.0/bin/perl -E1



=item * perl-5.28.3 -e1 (command)

Command line:

 /home/u1/perl5/perlbrew/perls/perl-5.28.3/bin/perl -e1



=item * perl-5.28.3 -E1 (command)

Command line:

 /home/u1/perl5/perlbrew/perls/perl-5.28.3/bin/perl -E1



=item * perl-5.26.3 -e1 (command)

Command line:

 /home/u1/perl5/perlbrew/perls/perl-5.26.3/bin/perl -e1



=item * perl-5.26.3 -E1 (command)

Command line:

 /home/u1/perl5/perlbrew/perls/perl-5.26.3/bin/perl -E1



=item * perl-5.24.4 -e1 (command)

Command line:

 /home/u1/perl5/perlbrew/perls/perl-5.24.4/bin/perl -e1



=item * perl-5.24.4 -E1 (command)

Command line:

 /home/u1/perl5/perlbrew/perls/perl-5.24.4/bin/perl -E1



=item * perl-5.22.4 -e1 (command)

Command line:

 /home/u1/perl5/perlbrew/perls/perl-5.22.4/bin/perl -e1



=item * perl-5.22.4 -E1 (command)

Command line:

 /home/u1/perl5/perlbrew/perls/perl-5.22.4/bin/perl -E1



=item * perl-5.20.3 -e1 (command)

Command line:

 /home/u1/perl5/perlbrew/perls/perl-5.20.3/bin/perl -e1



=item * perl-5.20.3 -E1 (command)

Command line:

 /home/u1/perl5/perlbrew/perls/perl-5.20.3/bin/perl -E1



=item * perl-5.18.4 -e1 (command)

Command line:

 /home/u1/perl5/perlbrew/perls/perl-5.18.4/bin/perl -e1



=item * perl-5.18.4 -E1 (command)

Command line:

 /home/u1/perl5/perlbrew/perls/perl-5.18.4/bin/perl -E1



=item * perl-5.16.3 -e1 (command)

Command line:

 /home/u1/perl5/perlbrew/perls/perl-5.16.3/bin/perl -e1



=item * perl-5.16.3 -E1 (command)

Command line:

 /home/u1/perl5/perlbrew/perls/perl-5.16.3/bin/perl -E1



=item * perl-5.14.4 -e1 (command)

Command line:

 /home/u1/perl5/perlbrew/perls/perl-5.14.4/bin/perl -e1



=item * perl-5.14.4 -E1 (command)

Command line:

 /home/u1/perl5/perlbrew/perls/perl-5.14.4/bin/perl -E1



=item * perl-5.12.5 -e1 (command)

Command line:

 /home/u1/perl5/perlbrew/perls/perl-5.12.5/bin/perl -e1



=item * perl-5.12.5 -E1 (command)

Command line:

 /home/u1/perl5/perlbrew/perls/perl-5.12.5/bin/perl -E1



=item * perl-5.10.1 -e1 (command)

Command line:

 /home/u1/perl5/perlbrew/perls/perl-5.10.1/bin/perl -e1



=item * perl-5.10.1 -E1 (command)

Command line:

 /home/u1/perl5/perlbrew/perls/perl-5.10.1/bin/perl -E1



=item * perl-5.8.9 -e1 (command)

Command line:

 /home/u1/perl5/perlbrew/perls/perl-5.8.9/bin/perl -e1



=item * perl-5.6.2 -e1 (command)

Command line:

 /home/u1/perl5/perlbrew/perls/perl-5.6.2/bin/perl -e1



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.34.0 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 20.04 >>, OS kernel: I<< Linux version 5.3.0-64-generic >>.

Benchmark with default options (C<< bencher -m Perl::Startup >>):

 #table1#
 +-----------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant     | rate (/s) | time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-----------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | perl-5.28.3 -E1 |       130 |       7.4 |                 0.00% |                19.97% | 3.4e-05 |      27 |
 | perl-5.32.1 -E1 |       140 |       7.2 |                 3.80% |                15.58% | 7.8e-06 |      20 |
 | perl-5.34.0 -E1 |       140 |       7.1 |                 4.09% |                15.26% | 1.4e-05 |      20 |
 | perl-5.30.3 -E1 |       140 |       7.1 |                 4.57% |                14.74% | 1.5e-05 |      20 |
 | perl-5.30.0 -E1 |       140 |       7.1 |                 4.98% |                14.28% | 2.1e-05 |      20 |
 | perl-5.18.4 -E1 |       140 |       7.1 |                 5.25% |                13.99% | 3.3e-05 |      63 |
 | perl-5.26.3 -E1 |       140 |       7   |                 5.63% |                13.58% | 3.1e-05 |      26 |
 | perl-5.14.4 -E1 |       140 |       7   |                 6.68% |                12.47% | 3.4e-05 |      56 |
 | perl-5.16.3 -E1 |       140 |       6.9 |                 7.34% |                11.77% | 3.4e-05 |      31 |
 | perl-5.22.4 -E1 |       140 |       6.9 |                 7.41% |                11.69% | 3.2e-05 |      20 |
 | perl-5.20.3 -E1 |       150 |       6.9 |                 7.85% |                11.24% | 1.9e-05 |      20 |
 | perl-5.30.3 -e1 |       150 |       6.8 |                 8.64% |                10.43% | 3.4e-05 |      30 |
 | perl-5.24.4 -E1 |       150 |       6.8 |                 8.80% |                10.27% | 2.3e-05 |      20 |
 | perl-5.34.0 -e1 |       150 |       6.8 |                 8.88% |                10.19% | 3.4e-05 |      25 |
 | perl-5.32.1 -e1 |       150 |       6.7 |                10.15% |                 8.92% | 3.1e-05 |      46 |
 | perl-5.22.4 -e1 |       150 |       6.7 |                10.84% |                 8.24% | 3.1e-05 |      32 |
 | perl-5.10.1 -E1 |       150 |       6.6 |                11.64% |                 7.47% | 2.3e-05 |      20 |
 | perl-5.20.3 -e1 |       150 |       6.6 |                12.15% |                 6.98% | 3.1e-05 |      30 |
 | perl-5.12.5 -E1 |       150 |       6.6 |                12.29% |                 6.84% | 2.3e-05 |      20 |
 | perl-5.26.3 -e1 |       150 |       6.6 |                12.72% |                 6.44% | 3.3e-05 |      37 |
 | perl-5.30.0 -e1 |       150 |       6.6 |                12.86% |                 6.30% | 3.2e-05 |      20 |
 | perl-5.24.4 -e1 |       150 |       6.6 |                13.17% |                 6.01% | 2.9e-05 |      35 |
 | perl-5.10.1 -e1 |       150 |       6.5 |                13.43% |                 5.77% | 2.9e-05 |      20 |
 | perl-5.18.4 -e1 |       150 |       6.5 |                13.45% |                 5.75% | 2.9e-05 |      38 |
 | perl-5.12.5 -e1 |       150 |       6.5 |                14.22% |                 5.04% |   3e-05 |      32 |
 | perl-5.28.3 -e1 |       160 |       6.4 |                15.70% |                 3.70% | 1.7e-05 |      21 |
 | perl-5.16.3 -e1 |       160 |       6.4 |                16.79% |                 2.72% | 3.1e-05 |      22 |
 | perl-5.6.2 -e1  |       160 |       6.3 |                17.51% |                 2.10% | 2.9e-05 |      35 |
 | perl-5.8.9 -e1  |       160 |       6.2 |                19.67% |                 0.25% | 1.9e-05 |      20 |
 | perl-5.14.4 -e1 |       160 |       6.2 |                19.97% |                 0.00% | 8.1e-06 |      21 |
 +-----------------+-----------+-----------+-----------------------+-----------------------+---------+---------+


Formatted as L<Benchmark.pm|Benchmark> result:

                    Rate  perl-5.28.3 -E1  perl-5.32.1 -E1  perl-5.34.0 -E1  perl-5.30.3 -E1  perl-5.30.0 -E1  perl-5.18.4 -E1  perl-5.26.3 -E1  perl-5.14.4 -E1  perl-5.16.3 -E1  perl-5.22.4 -E1  perl-5.20.3 -E1  perl-5.30.3 -e1  perl-5.24.4 -E1  perl-5.34.0 -e1  perl-5.32.1 -e1  perl-5.22.4 -e1  perl-5.10.1 -E1  perl-5.20.3 -e1  perl-5.12.5 -E1  perl-5.26.3 -e1  perl-5.30.0 -e1  perl-5.24.4 -e1  perl-5.10.1 -e1  perl-5.18.4 -e1  perl-5.12.5 -e1  perl-5.28.3 -e1  perl-5.16.3 -e1  perl-5.6.2 -e1  perl-5.8.9 -e1  perl-5.14.4 -e1 
  perl-5.28.3 -E1  130/s               --              -2%              -4%              -4%              -4%              -4%              -5%              -5%              -6%              -6%              -6%              -8%              -8%              -8%              -9%              -9%             -10%             -10%             -10%             -10%             -10%             -10%             -12%             -12%             -12%             -13%             -13%            -14%            -16%             -16% 
  perl-5.32.1 -E1  140/s               2%               --              -1%              -1%              -1%              -1%              -2%              -2%              -4%              -4%              -4%              -5%              -5%              -5%              -6%              -6%              -8%              -8%              -8%              -8%              -8%              -8%              -9%              -9%              -9%             -11%             -11%            -12%            -13%             -13% 
  perl-5.34.0 -E1  140/s               4%               1%               --               0%               0%               0%              -1%              -1%              -2%              -2%              -2%              -4%              -4%              -4%              -5%              -5%              -7%              -7%              -7%              -7%              -7%              -7%              -8%              -8%              -8%              -9%              -9%            -11%            -12%             -12% 
  perl-5.30.3 -E1  140/s               4%               1%               0%               --               0%               0%              -1%              -1%              -2%              -2%              -2%              -4%              -4%              -4%              -5%              -5%              -7%              -7%              -7%              -7%              -7%              -7%              -8%              -8%              -8%              -9%              -9%            -11%            -12%             -12% 
  perl-5.30.0 -E1  140/s               4%               1%               0%               0%               --               0%              -1%              -1%              -2%              -2%              -2%              -4%              -4%              -4%              -5%              -5%              -7%              -7%              -7%              -7%              -7%              -7%              -8%              -8%              -8%              -9%              -9%            -11%            -12%             -12% 
  perl-5.18.4 -E1  140/s               4%               1%               0%               0%               0%               --              -1%              -1%              -2%              -2%              -2%              -4%              -4%              -4%              -5%              -5%              -7%              -7%              -7%              -7%              -7%              -7%              -8%              -8%              -8%              -9%              -9%            -11%            -12%             -12% 
  perl-5.26.3 -E1  140/s               5%               2%               1%               1%               1%               1%               --               0%              -1%              -1%              -1%              -2%              -2%              -2%              -4%              -4%              -5%              -5%              -5%              -5%              -5%              -5%              -7%              -7%              -7%              -8%              -8%             -9%            -11%             -11% 
  perl-5.14.4 -E1  140/s               5%               2%               1%               1%               1%               1%               0%               --              -1%              -1%              -1%              -2%              -2%              -2%              -4%              -4%              -5%              -5%              -5%              -5%              -5%              -5%              -7%              -7%              -7%              -8%              -8%             -9%            -11%             -11% 
  perl-5.16.3 -E1  140/s               7%               4%               2%               2%               2%               2%               1%               1%               --               0%               0%              -1%              -1%              -1%              -2%              -2%              -4%              -4%              -4%              -4%              -4%              -4%              -5%              -5%              -5%              -7%              -7%             -8%            -10%             -10% 
  perl-5.22.4 -E1  140/s               7%               4%               2%               2%               2%               2%               1%               1%               0%               --               0%              -1%              -1%              -1%              -2%              -2%              -4%              -4%              -4%              -4%              -4%              -4%              -5%              -5%              -5%              -7%              -7%             -8%            -10%             -10% 
  perl-5.20.3 -E1  150/s               7%               4%               2%               2%               2%               2%               1%               1%               0%               0%               --              -1%              -1%              -1%              -2%              -2%              -4%              -4%              -4%              -4%              -4%              -4%              -5%              -5%              -5%              -7%              -7%             -8%            -10%             -10% 
  perl-5.30.3 -e1  150/s               8%               5%               4%               4%               4%               4%               2%               2%               1%               1%               1%               --               0%               0%              -1%              -1%              -2%              -2%              -2%              -2%              -2%              -2%              -4%              -4%              -4%              -5%              -5%             -7%             -8%              -8% 
  perl-5.24.4 -E1  150/s               8%               5%               4%               4%               4%               4%               2%               2%               1%               1%               1%               0%               --               0%              -1%              -1%              -2%              -2%              -2%              -2%              -2%              -2%              -4%              -4%              -4%              -5%              -5%             -7%             -8%              -8% 
  perl-5.34.0 -e1  150/s               8%               5%               4%               4%               4%               4%               2%               2%               1%               1%               1%               0%               0%               --              -1%              -1%              -2%              -2%              -2%              -2%              -2%              -2%              -4%              -4%              -4%              -5%              -5%             -7%             -8%              -8% 
  perl-5.32.1 -e1  150/s              10%               7%               5%               5%               5%               5%               4%               4%               2%               2%               2%               1%               1%               1%               --               0%              -1%              -1%              -1%              -1%              -1%              -1%              -2%              -2%              -2%              -4%              -4%             -5%             -7%              -7% 
  perl-5.22.4 -e1  150/s              10%               7%               5%               5%               5%               5%               4%               4%               2%               2%               2%               1%               1%               1%               0%               --              -1%              -1%              -1%              -1%              -1%              -1%              -2%              -2%              -2%              -4%              -4%             -5%             -7%              -7% 
  perl-5.10.1 -E1  150/s              12%               9%               7%               7%               7%               7%               6%               6%               4%               4%               4%               3%               3%               3%               1%               1%               --               0%               0%               0%               0%               0%              -1%              -1%              -1%              -3%              -3%             -4%             -6%              -6% 
  perl-5.20.3 -e1  150/s              12%               9%               7%               7%               7%               7%               6%               6%               4%               4%               4%               3%               3%               3%               1%               1%               0%               --               0%               0%               0%               0%              -1%              -1%              -1%              -3%              -3%             -4%             -6%              -6% 
  perl-5.12.5 -E1  150/s              12%               9%               7%               7%               7%               7%               6%               6%               4%               4%               4%               3%               3%               3%               1%               1%               0%               0%               --               0%               0%               0%              -1%              -1%              -1%              -3%              -3%             -4%             -6%              -6% 
  perl-5.26.3 -e1  150/s              12%               9%               7%               7%               7%               7%               6%               6%               4%               4%               4%               3%               3%               3%               1%               1%               0%               0%               0%               --               0%               0%              -1%              -1%              -1%              -3%              -3%             -4%             -6%              -6% 
  perl-5.30.0 -e1  150/s              12%               9%               7%               7%               7%               7%               6%               6%               4%               4%               4%               3%               3%               3%               1%               1%               0%               0%               0%               0%               --               0%              -1%              -1%              -1%              -3%              -3%             -4%             -6%              -6% 
  perl-5.24.4 -e1  150/s              12%               9%               7%               7%               7%               7%               6%               6%               4%               4%               4%               3%               3%               3%               1%               1%               0%               0%               0%               0%               0%               --              -1%              -1%              -1%              -3%              -3%             -4%             -6%              -6% 
  perl-5.10.1 -e1  150/s              13%              10%               9%               9%               9%               9%               7%               7%               6%               6%               6%               4%               4%               4%               3%               3%               1%               1%               1%               1%               1%               1%               --               0%               0%              -1%              -1%             -3%             -4%              -4% 
  perl-5.18.4 -e1  150/s              13%              10%               9%               9%               9%               9%               7%               7%               6%               6%               6%               4%               4%               4%               3%               3%               1%               1%               1%               1%               1%               1%               0%               --               0%              -1%              -1%             -3%             -4%              -4% 
  perl-5.12.5 -e1  150/s              13%              10%               9%               9%               9%               9%               7%               7%               6%               6%               6%               4%               4%               4%               3%               3%               1%               1%               1%               1%               1%               1%               0%               0%               --              -1%              -1%             -3%             -4%              -4% 
  perl-5.28.3 -e1  160/s              15%              12%              10%              10%              10%              10%               9%               9%               7%               7%               7%               6%               6%               6%               4%               4%               3%               3%               3%               3%               3%               3%               1%               1%               1%               --               0%             -1%             -3%              -3% 
  perl-5.16.3 -e1  160/s              15%              12%              10%              10%              10%              10%               9%               9%               7%               7%               7%               6%               6%               6%               4%               4%               3%               3%               3%               3%               3%               3%               1%               1%               1%               0%               --             -1%             -3%              -3% 
  perl-5.6.2 -e1   160/s              17%              14%              12%              12%              12%              12%              11%              11%               9%               9%               9%               7%               7%               7%               6%               6%               4%               4%               4%               4%               4%               4%               3%               3%               3%               1%               1%              --             -1%              -1% 
  perl-5.8.9 -e1   160/s              19%              16%              14%              14%              14%              14%              12%              12%              11%              11%              11%               9%               9%               9%               8%               8%               6%               6%               6%               6%               6%               6%               4%               4%               4%               3%               3%              1%              --               0% 
  perl-5.14.4 -e1  160/s              19%              16%              14%              14%              14%              14%              12%              12%              11%              11%              11%               9%               9%               9%               8%               8%               6%               6%               6%               6%               6%               6%               4%               4%               4%               3%               3%              1%              0%               -- 
 
 Legends:
   perl-5.10.1 -E1: participant=perl-5.10.1 -E1
   perl-5.10.1 -e1: participant=perl-5.10.1 -e1
   perl-5.12.5 -E1: participant=perl-5.12.5 -E1
   perl-5.12.5 -e1: participant=perl-5.12.5 -e1
   perl-5.14.4 -E1: participant=perl-5.14.4 -E1
   perl-5.14.4 -e1: participant=perl-5.14.4 -e1
   perl-5.16.3 -E1: participant=perl-5.16.3 -E1
   perl-5.16.3 -e1: participant=perl-5.16.3 -e1
   perl-5.18.4 -E1: participant=perl-5.18.4 -E1
   perl-5.18.4 -e1: participant=perl-5.18.4 -e1
   perl-5.20.3 -E1: participant=perl-5.20.3 -E1
   perl-5.20.3 -e1: participant=perl-5.20.3 -e1
   perl-5.22.4 -E1: participant=perl-5.22.4 -E1
   perl-5.22.4 -e1: participant=perl-5.22.4 -e1
   perl-5.24.4 -E1: participant=perl-5.24.4 -E1
   perl-5.24.4 -e1: participant=perl-5.24.4 -e1
   perl-5.26.3 -E1: participant=perl-5.26.3 -E1
   perl-5.26.3 -e1: participant=perl-5.26.3 -e1
   perl-5.28.3 -E1: participant=perl-5.28.3 -E1
   perl-5.28.3 -e1: participant=perl-5.28.3 -e1
   perl-5.30.0 -E1: participant=perl-5.30.0 -E1
   perl-5.30.0 -e1: participant=perl-5.30.0 -e1
   perl-5.30.3 -E1: participant=perl-5.30.3 -E1
   perl-5.30.3 -e1: participant=perl-5.30.3 -e1
   perl-5.32.1 -E1: participant=perl-5.32.1 -E1
   perl-5.32.1 -e1: participant=perl-5.32.1 -e1
   perl-5.34.0 -E1: participant=perl-5.34.0 -E1
   perl-5.34.0 -e1: participant=perl-5.34.0 -e1
   perl-5.6.2 -e1: participant=perl-5.6.2 -e1
   perl-5.8.9 -e1: participant=perl-5.8.9 -e1

=for html <img src="data:image/png;base64,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" />


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-Perl-Startup>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-Perl-Startup>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-Perl-Startup>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Bencher::Scenario::Interpreters>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
