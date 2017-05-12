package Bencher::Scenario::DigestSHA1;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::Any::IfLOG '$log';

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
            $log->infof("Creating temporary file with size of %.1fMB ...", $ds->{_size}/1024/1024);
            my $filename = _create_file($ds->{_size});
            $log->infof("Created file %s", $filename);
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
            $log->infof("Unlinking %s", $filename);
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

Bencher::Scenario::DigestSHA1 - Benchmark Digest::SHA1 against Digest::SHA

=head1 VERSION

This document describes version 0.002 of Bencher::Scenario::DigestSHA1 (from Perl distribution Bencher-Scenario-DigestSHA1), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m DigestSHA1

To run module startup overhead benchmark:

 % bencher --module-startup -m DigestSHA1

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Digest::SHA1> 2.13

L<Digest::SHA> 5.95

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

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m DigestSHA1 >>):

 #table1#
 +--------------+-----------+-----------+------------+-----------+---------+
 | participant  | rate (/s) | time (ms) | vs_slowest |  errors   | samples |
 +--------------+-----------+-----------+------------+-----------+---------+
 | Digest::SHA1 |       6.6 |     150   |       1    |   0.00049 |       6 |
 | Digest::SHA  |      10   |      99.9 |       1.51 | 4.7e-05   |       6 |
 +--------------+-----------+-----------+------------+-----------+---------+


Benchmark module startup overhead (C<< bencher -m DigestSHA1 --module-startup >>):

 #table2#
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | participant         | proc_private_dirty_size (MB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | Digest::SHA         | 0.82                         | 4.2                | 16             |        13 |                      8 |        1   | 2.6e-05 |       6 |
 | Digest::SHA1        | 1.5                          | 5                  | 21             |        10 |                      5 |        1.2 | 5.7e-05 |       7 |
 | perl -e1 (baseline) | 1.2                          | 4.5                | 18             |         5 |                      0 |        2.5 | 2.7e-05 |       7 |
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 BENCHMARK NOTES

L<Digest::SHA> is faster than L<Digest::SHA1>, so in general there is no reason
to use Digest::SHA1 over Digest::SHA (core module, more up-to-date, support more
algorithms).

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-DigestSHA1>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-DigestSHA1>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-DigestSHA1>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

See L<Bencher::Scenarios::DigestSHA> for more SHA-related benchmarks.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
