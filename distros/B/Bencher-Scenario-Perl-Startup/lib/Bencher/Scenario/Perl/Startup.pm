package Bencher::Scenario::Perl::Startup;

use 5.010001;
use strict;
use warnings;

use App::perlbrew;
use File::Which;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-07-08'; # DATE
our $DIST = 'Bencher-Scenario-Perl-Startup'; # DIST
our $VERSION = '0.054'; # VERSION

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

This document describes version 0.054 of Bencher::Scenario::Perl::Startup (from Perl distribution Bencher-Scenario-Perl-Startup), released on 2023-07-08.

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

=item * perl-5.38.0 -e1 (command)

Command line:

 /home/u1/perl5/perlbrew/perls/perl-5.38.0/bin/perl -e1



=item * perl-5.38.0 -E1 (command)

Command line:

 /home/u1/perl5/perlbrew/perls/perl-5.38.0/bin/perl -E1



=item * perl-5.36.1 -e1 (command)

Command line:

 /home/u1/perl5/perlbrew/perls/perl-5.36.1/bin/perl -e1



=item * perl-5.36.1 -E1 (command)

Command line:

 /home/u1/perl5/perlbrew/perls/perl-5.36.1/bin/perl -E1



=item * perl-5.34.1 -e1 (command)

Command line:

 /home/u1/perl5/perlbrew/perls/perl-5.34.1/bin/perl -e1



=item * perl-5.34.1 -E1 (command)

Command line:

 /home/u1/perl5/perlbrew/perls/perl-5.34.1/bin/perl -E1



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

Run on: perl: I<< v5.34.0 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 20.04 >>, OS kernel: I<< Linux version 5.4.0-91-generic >>.

Benchmark with default options (C<< bencher -m Perl::Startup >>):

 #table1#
 +-----------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant     | rate (/s) | time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-----------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | perl-5.38.0 -E1 |       143 |      7.01 |                 0.00% |                26.34% | 3.5e-06 |      21 |
 | perl-5.36.1 -E1 |       143 |      7.01 |                 0.04% |                26.29% | 2.9e-06 |      20 |
 | perl-5.34.0 -E1 |       149 |      6.73 |                 4.16% |                21.29% | 3.3e-06 |      23 |
 | perl-5.32.1 -E1 |       149 |      6.73 |                 4.20% |                21.25% |   3e-06 |      20 |
 | perl-5.34.1 -E1 |       149 |      6.72 |                 4.30% |                21.13% | 4.6e-06 |      21 |
 | perl-5.30.3 -E1 |       150 |      6.68 |                 5.02% |                20.30% | 3.1e-06 |      20 |
 | perl-5.24.4 -E1 |       152 |      6.59 |                 6.43% |                18.71% | 3.4e-06 |      20 |
 | perl-5.28.3 -E1 |       152 |      6.58 |                 6.59% |                18.53% | 3.8e-06 |      20 |
 | perl-5.26.3 -E1 |       154 |      6.5  |                 7.89% |                17.10% |   2e-06 |      21 |
 | perl-5.20.3 -E1 |       157 |      6.38 |                 9.89% |                14.97% | 2.2e-06 |      20 |
 | perl-5.18.4 -E1 |       159 |      6.27 |                11.78% |                13.03% | 3.1e-06 |      20 |
 | perl-5.16.3 -E1 |       160 |      6.24 |                12.43% |                12.37% |   4e-06 |      23 |
 | perl-5.12.5 -E1 |       163 |      6.13 |                14.37% |                10.47% | 5.2e-06 |      20 |
 | perl-5.14.4 -E1 |       164 |      6.11 |                14.69% |                10.16% | 5.1e-06 |      20 |
 | perl-5.10.1 -E1 |       166 |      6.02 |                16.53% |                 8.42% | 3.9e-06 |      21 |
 | perl-5.32.1 -e1 |       166 |      6.01 |                16.63% |                 8.33% | 4.1e-06 |      22 |
 | perl-5.30.3 -e1 |       170 |      6    |                16.69% |                 8.27% |   1e-05 |      20 |
 | perl-5.34.1 -e1 |       170 |      6    |                16.83% |                 8.14% | 6.3e-06 |      20 |
 | perl-5.36.1 -e1 |       167 |      5.99 |                16.95% |                 8.03% | 3.1e-06 |      21 |
 | perl-5.38.0 -e1 |       167 |      5.98 |                17.22% |                 7.78% | 4.2e-06 |      20 |
 | perl-5.34.0 -e1 |       167 |      5.97 |                17.41% |                 7.61% |   4e-06 |      20 |
 | perl-5.28.3 -e1 |       170 |      5.9  |                18.23% |                 6.86% | 7.2e-06 |      21 |
 | perl-5.20.3 -e1 |       169 |      5.92 |                18.39% |                 6.71% | 5.3e-06 |      20 |
 | perl-5.26.3 -e1 |       170 |      5.9  |                19.02% |                 6.15% |   1e-05 |      20 |
 | perl-5.24.4 -e1 |       170 |      5.9  |                19.08% |                 6.10% | 1.5e-05 |      20 |
 | perl-5.18.4 -e1 |       172 |      5.82 |                20.55% |                 4.80% | 4.1e-06 |      20 |
 | perl-5.12.5 -e1 |       170 |      5.8  |                21.35% |                 4.11% |   1e-05 |      21 |
 | perl-5.14.4 -e1 |       173 |      5.77 |                21.42% |                 4.05% | 4.7e-06 |      20 |
 | perl-5.16.3 -e1 |       170 |      5.8  |                21.47% |                 4.01% | 8.3e-06 |      20 |
 | perl-5.10.1 -e1 |       180 |      5.7  |                22.72% |                 2.95% | 6.2e-06 |      20 |
 | perl-5.8.9 -e1  |       180 |      5.7  |                23.96% |                 1.92% | 9.6e-06 |      20 |
 | perl-5.6.2 -e1  |       180 |      5.5  |                26.34% |                 0.00% | 9.1e-06 |      20 |
 +-----------------+-----------+-----------+-----------------------+-----------------------+---------+---------+


Formatted as L<Benchmark.pm|Benchmark> result:

                    Rate  perl-5.38.0 -E1  perl-5.36.1 -E1  perl-5.34.0 -E1  perl-5.32.1 -E1  perl-5.34.1 -E1  perl-5.30.3 -E1  perl-5.24.4 -E1  perl-5.28.3 -E1  perl-5.26.3 -E1  perl-5.20.3 -E1  perl-5.18.4 -E1  perl-5.16.3 -E1  perl-5.12.5 -E1  perl-5.14.4 -E1  perl-5.10.1 -E1  perl-5.32.1 -e1  perl-5.30.3 -e1  perl-5.34.1 -e1  perl-5.36.1 -e1  perl-5.38.0 -e1  perl-5.34.0 -e1  perl-5.20.3 -e1  perl-5.28.3 -e1  perl-5.26.3 -e1  perl-5.24.4 -e1  perl-5.18.4 -e1  perl-5.12.5 -e1  perl-5.16.3 -e1  perl-5.14.4 -e1  perl-5.10.1 -e1  perl-5.8.9 -e1  perl-5.6.2 -e1 
  perl-5.38.0 -E1  143/s               --               0%              -3%              -3%              -4%              -4%              -5%              -6%              -7%              -8%             -10%             -10%             -12%             -12%             -14%             -14%             -14%             -14%             -14%             -14%             -14%             -15%             -15%             -15%             -15%             -16%             -17%             -17%             -17%             -18%            -18%            -21% 
  perl-5.36.1 -E1  143/s               0%               --              -3%              -3%              -4%              -4%              -5%              -6%              -7%              -8%             -10%             -10%             -12%             -12%             -14%             -14%             -14%             -14%             -14%             -14%             -14%             -15%             -15%             -15%             -15%             -16%             -17%             -17%             -17%             -18%            -18%            -21% 
  perl-5.34.0 -E1  149/s               4%               4%               --               0%               0%               0%              -2%              -2%              -3%              -5%              -6%              -7%              -8%              -9%             -10%             -10%             -10%             -10%             -10%             -11%             -11%             -12%             -12%             -12%             -12%             -13%             -13%             -13%             -14%             -15%            -15%            -18% 
  perl-5.32.1 -E1  149/s               4%               4%               0%               --               0%               0%              -2%              -2%              -3%              -5%              -6%              -7%              -8%              -9%             -10%             -10%             -10%             -10%             -10%             -11%             -11%             -12%             -12%             -12%             -12%             -13%             -13%             -13%             -14%             -15%            -15%            -18% 
  perl-5.34.1 -E1  149/s               4%               4%               0%               0%               --               0%              -1%              -2%              -3%              -5%              -6%              -7%              -8%              -9%             -10%             -10%             -10%             -10%             -10%             -11%             -11%             -11%             -12%             -12%             -12%             -13%             -13%             -13%             -14%             -15%            -15%            -18% 
  perl-5.30.3 -E1  150/s               4%               4%               0%               0%               0%               --              -1%              -1%              -2%              -4%              -6%              -6%              -8%              -8%              -9%             -10%             -10%             -10%             -10%             -10%             -10%             -11%             -11%             -11%             -11%             -12%             -13%             -13%             -13%             -14%            -14%            -17% 
  perl-5.24.4 -E1  152/s               6%               6%               2%               2%               1%               1%               --               0%              -1%              -3%              -4%              -5%              -6%              -7%              -8%              -8%              -8%              -8%              -9%              -9%              -9%             -10%             -10%             -10%             -10%             -11%             -11%             -11%             -12%             -13%            -13%            -16% 
  perl-5.28.3 -E1  152/s               6%               6%               2%               2%               2%               1%               0%               --              -1%              -3%              -4%              -5%              -6%              -7%              -8%              -8%              -8%              -8%              -8%              -9%              -9%             -10%             -10%             -10%             -10%             -11%             -11%             -11%             -12%             -13%            -13%            -16% 
  perl-5.26.3 -E1  154/s               7%               7%               3%               3%               3%               2%               1%               1%               --              -1%              -3%              -3%              -5%              -5%              -7%              -7%              -7%              -7%              -7%              -7%              -8%              -8%              -9%              -9%              -9%             -10%             -10%             -10%             -11%             -12%            -12%            -15% 
  perl-5.20.3 -E1  157/s               9%               9%               5%               5%               5%               4%               3%               3%               1%               --              -1%              -2%              -3%              -4%              -5%              -5%              -5%              -5%              -6%              -6%              -6%              -7%              -7%              -7%              -7%              -8%              -9%              -9%              -9%             -10%            -10%            -13% 
  perl-5.18.4 -E1  159/s              11%              11%               7%               7%               7%               6%               5%               4%               3%               1%               --               0%              -2%              -2%              -3%              -4%              -4%              -4%              -4%              -4%              -4%              -5%              -5%              -5%              -5%              -7%              -7%              -7%              -7%              -9%             -9%            -12% 
  perl-5.16.3 -E1  160/s              12%              12%               7%               7%               7%               7%               5%               5%               4%               2%               0%               --              -1%              -2%              -3%              -3%              -3%              -3%              -4%              -4%              -4%              -5%              -5%              -5%              -5%              -6%              -7%              -7%              -7%              -8%             -8%            -11% 
  perl-5.12.5 -E1  163/s              14%              14%               9%               9%               9%               8%               7%               7%               6%               4%               2%               1%               --               0%              -1%              -1%              -2%              -2%              -2%              -2%              -2%              -3%              -3%              -3%              -3%              -5%              -5%              -5%              -5%              -7%             -7%            -10% 
  perl-5.14.4 -E1  164/s              14%              14%              10%              10%               9%               9%               7%               7%               6%               4%               2%               2%               0%               --              -1%              -1%              -1%              -1%              -1%              -2%              -2%              -3%              -3%              -3%              -3%              -4%              -5%              -5%              -5%              -6%             -6%             -9% 
  perl-5.10.1 -E1  166/s              16%              16%              11%              11%              11%              10%               9%               9%               7%               5%               4%               3%               1%               1%               --               0%               0%               0%               0%               0%               0%              -1%              -1%              -1%              -1%              -3%              -3%              -3%              -4%              -5%             -5%             -8% 
  perl-5.32.1 -e1  166/s              16%              16%              11%              11%              11%              11%               9%               9%               8%               6%               4%               3%               1%               1%               0%               --               0%               0%               0%               0%               0%              -1%              -1%              -1%              -1%              -3%              -3%              -3%              -3%              -5%             -5%             -8% 
  perl-5.30.3 -e1  170/s              16%              16%              12%              12%              11%              11%               9%               9%               8%               6%               4%               4%               2%               1%               0%               0%               --               0%               0%               0%               0%              -1%              -1%              -1%              -1%              -2%              -3%              -3%              -3%              -4%             -4%             -8% 
  perl-5.34.1 -e1  170/s              16%              16%              12%              12%              11%              11%               9%               9%               8%               6%               4%               4%               2%               1%               0%               0%               0%               --               0%               0%               0%              -1%              -1%              -1%              -1%              -2%              -3%              -3%              -3%              -4%             -4%             -8% 
  perl-5.36.1 -e1  167/s              17%              17%              12%              12%              12%              11%              10%               9%               8%               6%               4%               4%               2%               2%               0%               0%               0%               0%               --               0%               0%              -1%              -1%              -1%              -1%              -2%              -3%              -3%              -3%              -4%             -4%             -8% 
  perl-5.38.0 -e1  167/s              17%              17%              12%              12%              12%              11%              10%              10%               8%               6%               4%               4%               2%               2%               0%               0%               0%               0%               0%               --               0%              -1%              -1%              -1%              -1%              -2%              -3%              -3%              -3%              -4%             -4%             -8% 
  perl-5.34.0 -e1  167/s              17%              17%              12%              12%              12%              11%              10%              10%               8%               6%               5%               4%               2%               2%               0%               0%               0%               0%               0%               0%               --               0%              -1%              -1%              -1%              -2%              -2%              -2%              -3%              -4%             -4%             -7% 
  perl-5.20.3 -e1  169/s              18%              18%              13%              13%              13%              12%              11%              11%               9%               7%               5%               5%               3%               3%               1%               1%               1%               1%               1%               1%               0%               --               0%               0%               0%              -1%              -2%              -2%              -2%              -3%             -3%             -7% 
  perl-5.28.3 -e1  170/s              18%              18%              14%              14%              13%              13%              11%              11%              10%               8%               6%               5%               3%               3%               2%               1%               1%               1%               1%               1%               1%               0%               --               0%               0%              -1%              -1%              -1%              -2%              -3%             -3%             -6% 
  perl-5.26.3 -e1  170/s              18%              18%              14%              14%              13%              13%              11%              11%              10%               8%               6%               5%               3%               3%               2%               1%               1%               1%               1%               1%               1%               0%               0%               --               0%              -1%              -1%              -1%              -2%              -3%             -3%             -6% 
  perl-5.24.4 -e1  170/s              18%              18%              14%              14%              13%              13%              11%              11%              10%               8%               6%               5%               3%               3%               2%               1%               1%               1%               1%               1%               1%               0%               0%               0%               --              -1%              -1%              -1%              -2%              -3%             -3%             -6% 
  perl-5.18.4 -e1  172/s              20%              20%              15%              15%              15%              14%              13%              13%              11%               9%               7%               7%               5%               4%               3%               3%               3%               3%               2%               2%               2%               1%               1%               1%               1%               --               0%               0%               0%              -2%             -2%             -5% 
  perl-5.12.5 -e1  170/s              20%              20%              16%              16%              15%              15%              13%              13%              12%              10%               8%               7%               5%               5%               3%               3%               3%               3%               3%               3%               2%               2%               1%               1%               1%               0%               --               0%               0%              -1%             -1%             -5% 
  perl-5.16.3 -e1  170/s              20%              20%              16%              16%              15%              15%              13%              13%              12%              10%               8%               7%               5%               5%               3%               3%               3%               3%               3%               3%               2%               2%               1%               1%               1%               0%               0%               --               0%              -1%             -1%             -5% 
  perl-5.14.4 -e1  173/s              21%              21%              16%              16%              16%              15%              14%              14%              12%              10%               8%               8%               6%               5%               4%               4%               3%               3%               3%               3%               3%               2%               2%               2%               2%               0%               0%               0%               --              -1%             -1%             -4% 
  perl-5.10.1 -e1  180/s              22%              22%              18%              18%              17%              17%              15%              15%              14%              11%               9%               9%               7%               7%               5%               5%               5%               5%               5%               4%               4%               3%               3%               3%               3%               2%               1%               1%               1%               --              0%             -3% 
  perl-5.8.9 -e1   180/s              22%              22%              18%              18%              17%              17%              15%              15%              14%              11%               9%               9%               7%               7%               5%               5%               5%               5%               5%               4%               4%               3%               3%               3%               3%               2%               1%               1%               1%               0%              --             -3% 
  perl-5.6.2 -e1   180/s              27%              27%              22%              22%              22%              21%              19%              19%              18%              15%              13%              13%              11%              11%               9%               9%               9%               9%               8%               8%               8%               7%               7%               7%               7%               5%               5%               5%               4%               3%              3%              -- 
 
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
   perl-5.24.4 -E1: participant=perl-5.24.4 -E1
   perl-5.24.4 -e1: participant=perl-5.24.4 -e1
   perl-5.26.3 -E1: participant=perl-5.26.3 -E1
   perl-5.26.3 -e1: participant=perl-5.26.3 -e1
   perl-5.28.3 -E1: participant=perl-5.28.3 -E1
   perl-5.28.3 -e1: participant=perl-5.28.3 -e1
   perl-5.30.3 -E1: participant=perl-5.30.3 -E1
   perl-5.30.3 -e1: participant=perl-5.30.3 -e1
   perl-5.32.1 -E1: participant=perl-5.32.1 -E1
   perl-5.32.1 -e1: participant=perl-5.32.1 -e1
   perl-5.34.0 -E1: participant=perl-5.34.0 -E1
   perl-5.34.0 -e1: participant=perl-5.34.0 -e1
   perl-5.34.1 -E1: participant=perl-5.34.1 -E1
   perl-5.34.1 -e1: participant=perl-5.34.1 -e1
   perl-5.36.1 -E1: participant=perl-5.36.1 -E1
   perl-5.36.1 -e1: participant=perl-5.36.1 -e1
   perl-5.38.0 -E1: participant=perl-5.38.0 -E1
   perl-5.38.0 -e1: participant=perl-5.38.0 -e1
   perl-5.6.2 -e1: participant=perl-5.6.2 -e1
   perl-5.8.9 -e1: participant=perl-5.8.9 -e1

=for html <img src="data:image/png;base64,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" />


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-Perl-Startup>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-Perl-Startup>.

=head1 SEE ALSO

L<Bencher::Scenario::Interpreters>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023, 2021 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-Perl-Startup>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
