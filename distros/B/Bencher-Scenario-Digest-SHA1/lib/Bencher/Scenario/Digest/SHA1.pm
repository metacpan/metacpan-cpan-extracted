package Bencher::Scenario::Digest::SHA1;

use 5.010001;
use strict;
use warnings;
use Log::ger;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-03-19'; # DATE
our $DIST = 'Bencher-Scenario-Digest-SHA1'; # DIST
our $VERSION = '0.004'; # VERSION

sub _create_file {
    my ($size) = @_;

    require File::Temp;
    my ($fh, $filename) = File::Temp::tempfile();
    my $d1k = substr("1234567890" x 103, 0, 1024);
    for (1..int($size/1024)) {
        print $fh $d1k;
    }
    $filename;
}

our $scenario = {
    summary => 'Benchmark Digest::SHA1 against Digest::SHA',
    participants => [
        {
            name   => 'Digest::SHA1',
            module => 'Digest::SHA1',
            code_template => 'my $ctx = Digest::SHA1->new; open my $fh, "<", <filename>; $ctx->addfile($fh); $ctx->hexdigest',
        },
        {
            name   => 'Digest::SHA',
            module => 'Digest::SHA',
            code_template => 'my $ctx = Digest::SHA->new(1); open my $fh, "<", <filename>; $ctx->addfile($fh); $ctx->hexdigest',
        },
    ],
    precision => 6,

    datasets => [
        {name=>'30M_file', _size=>30*1024*1024, args=>{filename=>undef}, result=>'cb5c810c8b3c29b8941f8d2ce9d281220b5d1552'},
    ],

    before_gen_items => sub {
        my %args = @_;
        my $sc    = $args{scenario};

        my $dss = $sc->{datasets};
        for my $ds (@$dss) {
            log_info("Creating temporary file with size of %.1fMB ...", $ds->{_size}/1024/1024);
            my $filename = _create_file($ds->{_size});
            log_info("Created file %s", $filename);
            $ds->{args}{filename} = $filename;
        }
    },

    before_return => sub {
        my %args = @_;
        my $sc    = $args{scenario};

        my $dss = $sc->{datasets};
        for my $ds (@$dss) {
            my $filename = $ds->{args}{filename};
            next unless $filename;
            log_info("Unlinking %s", $filename);
            unlink $filename;
        }
    },
};

1;
# ABSTRACT: Benchmark Digest::SHA1 against Digest::SHA

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::Digest::SHA1 - Benchmark Digest::SHA1 against Digest::SHA

=head1 VERSION

This document describes version 0.004 of Bencher::Scenario::Digest::SHA1 (from Perl distribution Bencher-Scenario-Digest-SHA1), released on 2022-03-19.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m Digest::SHA1

To run module startup overhead benchmark:

 % bencher --module-startup -m Digest::SHA1

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Digest::SHA1> 2.13

L<Digest::SHA> 6.02

=head1 BENCHMARK PARTICIPANTS

=over

=item * Digest::SHA1 (perl_code)

Code template:

 my $ctx = Digest::SHA1->new; open my $fh, "<", <filename>; $ctx->addfile($fh); $ctx->hexdigest



=item * Digest::SHA (perl_code)

Code template:

 my $ctx = Digest::SHA->new(1); open my $fh, "<", <filename>; $ctx->addfile($fh); $ctx->hexdigest



=back

=head1 BENCHMARK DATASETS

=over

=item * 30M_file

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.34.0 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 20.04 >>, OS kernel: I<< Linux version 5.4.0-91-generic >>.

Benchmark with default options (C<< bencher -m Digest::SHA1 >>):

 #table1#
 +--------------+-----------+-----------+-----------------------+-----------------------+-----------+---------+
 | participant  | rate (/s) | time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors   | samples |
 +--------------+-----------+-----------+-----------------------+-----------------------+-----------+---------+
 | Digest::SHA1 |       7.3 |       140 |                 0.00% |                87.55% |   0.00018 |       6 |
 | Digest::SHA  |      14   |        73 |                87.55% |                 0.00% | 9.6e-05   |       6 |
 +--------------+-----------+-----------+-----------------------+-----------------------+-----------+---------+


Formatted as L<Benchmark.pm|Benchmark> result:

                 Rate  Digest::SHA1  Digest::SHA 
  Digest::SHA1  7.3/s            --         -47% 
  Digest::SHA    14/s           91%           -- 
 
 Legends:
   Digest::SHA: participant=Digest::SHA
   Digest::SHA1: participant=Digest::SHA1

Benchmark module startup overhead (C<< bencher -m Digest::SHA1 --module-startup >>):

 #table2#
 +---------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | participant         | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +---------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | Digest::SHA         |      11   |               4.9 |                 0.00% |                85.09% | 1.2e-05 |       6 |
 | Digest::SHA1        |      10.9 |               4.8 |                 3.65% |                78.57% | 6.1e-06 |       6 |
 | perl -e1 (baseline) |       6.1 |               0   |                85.09% |                 0.00% | 6.1e-06 |       6 |
 +---------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+


Formatted as L<Benchmark.pm|Benchmark> result:

                          Rate  Digest::SHA  Digest::SHA1  perl -e1 (baseline) 
  Digest::SHA           90.9/s           --            0%                 -44% 
  Digest::SHA1          91.7/s           0%            --                 -44% 
  perl -e1 (baseline)  163.9/s          80%           78%                   -- 
 
 Legends:
   Digest::SHA: mod_overhead_time=4.9 participant=Digest::SHA
   Digest::SHA1: mod_overhead_time=4.8 participant=Digest::SHA1
   perl -e1 (baseline): mod_overhead_time=0 participant=perl -e1 (baseline)

To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 BENCHMARK NOTES

L<Digest::SHA> is faster than L<Digest::SHA1>, so in general there is no reason
to use Digest::SHA1 over Digest::SHA (core module, more up-to-date, support more
algorithms).

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-Digest-SHA1>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-Digest-SHA1>.

=head1 SEE ALSO

See L<Bencher::Scenarios::DigestSHA> for more SHA-related benchmarks.

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022, 2017 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-Digest-SHA1>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
