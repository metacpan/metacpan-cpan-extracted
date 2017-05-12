package Bencher::Scenario::DigestSHA::SHA512;

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
    summary => 'Benchmark Digest::SHA against sha512sum',
    participants => [
        {
            name   => 'sha512sum',
            modules => ['String::ShellQuote'],
            code_template => 'my $cmd = "sha512sum ".String::ShellQuote::shell_quote(<filename>); my $res = `$cmd`; $res =~ s/\s.+//s; $res',
        },
        {
            name   => 'Digest::SHA',
            module => 'Digest::SHA',
            code_template => 'my $ctx = Digest::SHA->new(512); open my $fh, "<", <filename>; $ctx->addfile($fh); $ctx->hexdigest',
        },
    ],
    precision => 6,

    datasets => [
        {name=>'30M_file', _size=>30*1024*1024, args=>{filename=>undef}, result=>'5422caad13dfa4441aa9f8463ae576120782f8a6a0c83418172b3f80cf31f4ff53fe436dc05663d6e6e20a8e936427920ba68ed07d5555964c76bac9ab0a8c8e'},
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
# ABSTRACT: Benchmark Digest::SHA against sha512sum

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::DigestSHA::SHA512 - Benchmark Digest::SHA against sha512sum

=head1 VERSION

This document describes version 0.002 of Bencher::Scenario::DigestSHA::SHA512 (from Perl distribution Bencher-Scenarios-DigestSHA), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m DigestSHA::SHA512

To run module startup overhead benchmark:

 % bencher --module-startup -m DigestSHA::SHA512

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<String::ShellQuote> 1.04

L<Digest::SHA> 5.95

=head1 BENCHMARK PARTICIPANTS

=over

=item * sha512sum (perl_code)

Code template:

 my $cmd = "sha512sum ".String::ShellQuote::shell_quote(<filename>); my $res = `$cmd`; $res =~ s/\s.+//s; $res



=item * Digest::SHA (perl_code)

Code template:

 my $ctx = Digest::SHA->new(512); open my $fh, "<", <filename>; $ctx->addfile($fh); $ctx->hexdigest



=back

=head1 BENCHMARK DATASETS

=over

=item * 30M_file

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m DigestSHA::SHA512 >>):

 #table1#
 +-------------+-----------+-----------+------------+---------+---------+
 | participant | rate (/s) | time (ms) | vs_slowest |  errors | samples |
 +-------------+-----------+-----------+------------+---------+---------+
 | Digest::SHA |       7.1 |       140 |          1 | 0.00075 |       7 |
 | sha512sum   |       8   |       100 |          1 | 0.0015  |       6 |
 +-------------+-----------+-----------+------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m DigestSHA::SHA512 --module-startup >>):

 #table2#
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+-----------+---------+
 | participant         | proc_private_dirty_size (MB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors   | samples |
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+-----------+---------+
 | Digest::SHA         | 0.82                         | 4.1                | 16             |        13 |                      8 |        1   | 5.7e-05   |       7 |
 | String::ShellQuote  | 2                            | 5                  | 20             |         9 |                      4 |        1   |   0.00023 |       7 |
 | perl -e1 (baseline) | 1                            | 4.3                | 16             |         5 |                      0 |        2.6 | 1.8e-05   |       6 |
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+-----------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 BENCHMARK NOTES

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-DigestSHA>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-DigestSHA>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-DigestSHA>

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
